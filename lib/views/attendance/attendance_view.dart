import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../config/colors.dart';
import '../../config/constants.dart';
import '../../models/attendance.dart';
import '../../services/api_service.dart';
import '../../widgets/glass_app_bar.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/premium_button.dart';
import 'my_regularization_requests_view.dart';

class AttendanceView extends StatefulWidget {
  const AttendanceView({super.key});

  @override
  State<AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<AttendanceView> {
  DateTime _currentTime = DateTime.now();
  Timer? _timer;
  Attendance? _todayAttendance;
  bool _isLoading = true;
  bool _isActionLoading = false;
  String _breakType = 'Lunch Break';
  final List<String> _breakTypes = ['Lunch Break', 'Tea Break', 'Personal Break', 'Other'];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchTodayAttendance();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchTodayAttendance() async {
    setState(() => _isLoading = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final attendance = await api.getTodayAttendance();
      setState(() {
        _todayAttendance = attendance;
      });
    } catch (e) {
      debugPrint('Error fetching attendance: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _startBreak() async {
    setState(() => _isActionLoading = true);
    final api = Provider.of<ApiService>(context, listen: false);
    final success = await api.startBreak(_breakType);
    if (success) {
      await _fetchTodayAttendance();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Break Started'), backgroundColor: AspireColors.success));
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(api.errorMessage ?? 'Failed to start break'), backgroundColor: AspireColors.error));
    }
    if (mounted) setState(() => _isActionLoading = false);
  }

  Future<void> _endBreak() async {
    setState(() => _isActionLoading = true);
    final api = Provider.of<ApiService>(context, listen: false);
    final success = await api.endBreak();
    if (success) {
      await _fetchTodayAttendance();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Break Ended'), backgroundColor: AspireColors.success));
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(api.errorMessage ?? 'Failed to end break'), backgroundColor: AspireColors.error));
    }
    if (mounted) setState(() => _isActionLoading = false);
  }

  Future<void> _handlePunch(String action) async {
    setState(() => _isActionLoading = true);
    final api = Provider.of<ApiService>(context, listen: false);

    // 1. Fetch Location Settings
    final settings = await api.fetchAttendanceSettings();
    if (settings == null) {
      if (mounted) {
        setState(() => _isActionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load office location settings.'), backgroundColor: AspireColors.error),
        );
      }
      return;
    }

    final double officeLat = settings['office_latitude']?.toDouble() ?? 0.0;
    final double officeLng = settings['office_longitude']?.toDouble() ?? 0.0;
    final double officeRadius = settings['office_radius']?.toDouble() ?? 200.0;

    // 2. Check Location Permissions
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() => _isActionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled. Please enable them.'), backgroundColor: AspireColors.warning),
        );
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() => _isActionLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied.'), backgroundColor: AspireColors.error),
          );
        }
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() => _isActionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.'), backgroundColor: AspireColors.error),
        );
      }
      return;
    }

    // 3. Get Current Position
    Position position;
    try {
      position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      if (mounted) {
        setState(() => _isActionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e'), backgroundColor: AspireColors.error),
        );
      }
      return;
    }

    // 4. Calculate Distance
    final double distanceInMeters = Geolocator.distanceBetween(
      position.latitude, position.longitude, officeLat, officeLng
    );

    // Allow bypass for WFH and On Duty
    final isWfhOrOnDuty = _todayAttendance != null && 
        (_todayAttendance!.status == 'Work From Home' || _todayAttendance!.status == 'On Duty');

    if (distanceInMeters > officeRadius && !isWfhOrOnDuty) {
      if (mounted) {
        setState(() => _isActionLoading = false);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Location Verification Failed'),
            content: Text('You are outside the allowed office location.\n\nCurrent Distance: ${distanceInMeters.toStringAsFixed(0)} m\nAllowed Radius: ${officeRadius.toStringAsFixed(0)} m'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              )
            ],
          ),
        );
      }
      return;
    }

    if (mounted) {
      if (isWfhOrOnDuty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Remote Location Captured (WFH/On Duty)'), backgroundColor: AspireColors.success, duration: Duration(seconds: 2)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Office Location Verified'), backgroundColor: AspireColors.success, duration: Duration(seconds: 2)),
        );
      }
    }

    setState(() => _isActionLoading = false);

    // 5. Selfie Capture
    final ImagePicker picker = ImagePicker();
    XFile? photo;
    
    try {
      photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: $e'),
            backgroundColor: AspireColors.error,
          ),
        );
      }
      return;
    }

    if (photo == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selfie is required to punch in/out.'),
            backgroundColor: AspireColors.warning,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(action == 'clock_in' ? 'Confirm Punch In' : 'Confirm Punch Out'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please review your selfie before confirming.'),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: kIsWeb 
                  ? Image.network(photo!.path, height: 200, width: 200, fit: BoxFit.cover)
                  : Image.file(File(photo!.path), height: 200, width: 200, fit: BoxFit.cover),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Retake'),
            ),
            PremiumButton(
              text: 'Confirm',
              onPressed: () => Navigator.of(context).pop(true),
              width: 100,
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return _handlePunch(action); // Retake selfie
    }

    bool forceEndBreak = false;
    if (action == 'clock_out' && _todayAttendance?.activityStatus == 'On Break') {
      final bool? endBreakConfirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Active Break Warning'),
          content: const Text('You have an active break. Would you like to end it and punch out simultaneously?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            PremiumButton(
              text: 'End Break & Punch Out',
              onPressed: () => Navigator.of(ctx).pop(true),
              width: 200,
            ),
          ],
        ),
      );
      if (endBreakConfirm != true) {
        return;
      }
      forceEndBreak = true;
    }

    setState(() => _isActionLoading = true);
    try {
      final updated = await api.markAttendance(
        action, 
        selfieFile: photo,
        lat: position.latitude,
        lng: position.longitude,
        forceEndBreak: forceEndBreak,
      );
      setState(() {
        _todayAttendance = updated;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(action == 'clock_in' ? 'Punched In Successfully' : 'Punched Out Successfully'),
            backgroundColor: AspireColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AspireColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  String _formatTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '--:--';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return '--:--';
    }
  }

  String _calculateTotalHours(String? checkIn, String? checkOut) {
    if (checkIn == null) return '--';
    if (checkOut == null) return 'In Progress';
    
    try {
      final inTime = DateTime.parse(checkIn);
      final outTime = DateTime.parse(checkOut);
      final diff = outTime.difference(inTime);
      final hours = diff.inHours;
      final minutes = diff.inMinutes.remainder(60);
      return '${hours}h ${minutes}m';
    } catch (_) {
      return '--';
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = Provider.of<ApiService>(context);
    final user = api.currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Status color
    Color statusColor = AspireColors.textSecondary;
    String statusText = 'Not Marked';
    String? reasonText;
    
    if (_todayAttendance != null) {
      final statusStr = _todayAttendance!.status.toLowerCase();
      reasonText = _todayAttendance!.reason;

      if (statusStr == 'present') {
        statusColor = AspireColors.success;
        statusText = 'Present';
      } else if (statusStr == 'late') {
        statusColor = AspireColors.warning;
        statusText = 'Late';
      } else if (statusStr == 'half day') {
        statusColor = AspireColors.warning;
        statusText = 'Half Day';
      } else if (statusStr == 'absent') {
        statusColor = AspireColors.error;
        statusText = 'Absent';
      } else {
        statusColor = AspireColors.primary;
        statusText = _todayAttendance!.status;
      }

      if (_todayAttendance!.activityStatus == 'On Break') {
        statusText = 'On Break';
        statusColor = Colors.orange;
      }
    }

    final bool hasClockedIn = _todayAttendance != null && _todayAttendance!.checkInTime != null;
    final bool hasClockedOut = _todayAttendance != null && _todayAttendance!.checkOutTime != null;
    final bool isOnBreak = _todayAttendance?.activityStatus == 'On Break';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: 'Attendance',
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'regularization') {
                // Navigate to My Regularization Requests
                // Note: Ensure this view is imported, but for now we'll push named route or material page route
                Navigator.push(context, MaterialPageRoute(builder: (ctx) => const MyRegularizationRequestsView()));
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'regularization',
                child: Text('Regularization Requests'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _fetchTodayAttendance,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Employee Info Card
                      PremiumCard(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: isDark ? AspireColors.darkBorder : AspireColors.lightBorder,
                              child: Text(
                                user?.name.substring(0, 1).toUpperCase() ?? 'U',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              user?.name ?? 'Employee Name',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              user?.departmentName ?? 'Department',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AspireColors.textSecondary,
                              ),
                            ),
                            if (user?.id != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'ID: ${user!.id}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AspireColors.textSecondary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Clock Card
                      PremiumCard(
                        color: theme.cardColor,
                        child: Column(
                          children: [
                            Text(
                              DateFormat('EEEE, MMMM d, yyyy').format(_currentTime),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AspireColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat('hh:mm:ss a').format(_currentTime),
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AspireColors.primary,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: statusColor.withOpacity(0.3)),
                              ),
                              child: Text(
                                'Status: $statusText',
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (reasonText != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                reasonText,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: PremiumButton(
                                    text: 'Punch In',
                                    icon: Icons.login_outlined,
                                    isLoading: _isActionLoading,
                                    isPrimary: !hasClockedIn,
                                    onPressed: hasClockedIn ? () {} : () => _handlePunch('clock_in'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: PremiumButton(
                                    text: 'Punch Out',
                                    icon: Icons.logout_outlined,
                                    isLoading: _isActionLoading,
                                    isPrimary: hasClockedIn && !hasClockedOut,
                                    onPressed: (!hasClockedIn || hasClockedOut) ? () {} : () => _handlePunch('clock_out'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                        // Break Tracking Card
                        if (hasClockedIn && !hasClockedOut) ...[
                          PremiumCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Break Management",
                                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                if (isOnBreak) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                    ),
                                    child: Column(
                                      children: [
                                        const Icon(Icons.coffee, color: Colors.orange, size: 32),
                                        const SizedBox(height: 8),
                                        Text('You are currently on break', style: theme.textTheme.titleMedium?.copyWith(color: Colors.orange, fontWeight: FontWeight.bold)),
                                        if (_todayAttendance!.breaks.isNotEmpty && _todayAttendance!.breaks.last.endTime == null)
                                          Text('Started at ${_formatTime(_todayAttendance!.breaks.last.startTime)}', style: const TextStyle(color: Colors.orange)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  PremiumButton(
                                    text: 'End Break',
                                    icon: Icons.stop_circle_outlined,
                                    isLoading: _isActionLoading,
                                    onPressed: _endBreak,
                                  ),
                                ] else ...[
                                  DropdownButtonFormField<String>(
                                    value: _breakType,
                                    decoration: InputDecoration(
                                      labelText: 'Break Type',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      filled: true,
                                      fillColor: theme.cardColor,
                                    ),
                                    items: _breakTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() => _breakType = val);
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  PremiumButton(
                                    text: 'Start Break',
                                    icon: Icons.coffee_outlined,
                                    isLoading: _isActionLoading,
                                    onPressed: _startBreak,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],

                      // Today's Summary
                      PremiumCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Today's Summary",
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _SummaryItem(
                                  title: 'Punch In',
                                  value: _formatTime(_todayAttendance?.checkInTime),
                                  icon: Icons.login,
                                  color: AspireColors.success,
                                  imageUrl: _todayAttendance?.punchInSelfie,
                                ),
                                _SummaryItem(
                                  title: 'Punch Out',
                                  value: _formatTime(_todayAttendance?.checkOutTime),
                                  icon: Icons.logout,
                                  color: AspireColors.error,
                                  imageUrl: _todayAttendance?.punchOutSelfie,
                                ),
                                _SummaryItem(
                                  title: 'Total Hours',
                                  value: _calculateTotalHours(_todayAttendance?.checkInTime, _todayAttendance?.checkOutTime),
                                    icon: Icons.timer_outlined,
                                    color: AspireColors.primary,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _SummaryItem(
                                    title: 'Total Break Time',
                                    value: '${_todayAttendance?.totalBreakMinutes ?? 0}m',
                                    icon: Icons.coffee,
                                    color: Colors.orange,
                                  ),
                                  _SummaryItem(
                                    title: 'Productive Hours',
                                    value: _todayAttendance?.productiveWorkingHours != null 
                                      ? '${_todayAttendance!.productiveWorkingHours}h' 
                                      : _calculateTotalHours(_todayAttendance?.checkInTime, _todayAttendance?.checkOutTime),
                                    icon: Icons.work,
                                    color: AspireColors.success,
                                  ),
                                  _SummaryItem(
                                    title: 'Total Breaks',
                                    value: '${_todayAttendance?.breaks.length ?? 0}',
                                    icon: Icons.list_alt,
                                    color: Colors.purple,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? imageUrl;

  const _SummaryItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: imageUrl != null ? EdgeInsets.zero : const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: imageUrl != null
            ? CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage('${AppConstants.apiBaseUrl.replaceAll('/api', '')}$imageUrl'),
              )
            : Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AspireColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
