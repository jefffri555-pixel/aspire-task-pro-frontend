import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../config/colors.dart';
import '../../config/constants.dart';
import '../../models/attendance.dart';
import '../../services/api_service.dart';
import '../../widgets/premium_card.dart';

class AdminAttendanceDashboard extends StatefulWidget {
  const AdminAttendanceDashboard({super.key});

  @override
  State<AdminAttendanceDashboard> createState() => _AdminAttendanceDashboardState();
}

class _AdminAttendanceDashboardState extends State<AdminAttendanceDashboard> {
  bool _isLoading = true;
  AttendanceDashboardData? _dashboardData;
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDashboard();
    });
  }

  Future<void> _fetchDashboard() async {
    setState(() => _isLoading = true);
    final api = Provider.of<ApiService>(context, listen: false);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final data = await api.fetchAttendanceDashboard(date: dateStr);
    
    if (mounted) {
      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    }
  }

  List<Attendance> get _filteredList {
    if (_dashboardData == null) return [];
    var list = _dashboardData!.attendanceList;

    if (_selectedStatus != 'All') {
      if (_selectedStatus == 'Not Marked Yet') {
        list = list.where((a) => a.status == null || a.status!.isEmpty).toList();
      } else {
        list = list.where((a) => a.status?.toLowerCase() == _selectedStatus.toLowerCase()).toList();
      }
    }

    if (_searchQuery.isNotEmpty) {
      list = list.where((a) => (a.employeeName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) || 
                               (a.employeeId?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)).toList();
    }

    return list;
  }

  Widget _buildSummaryCard(String title, dynamic value, Color color) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showEmployeeDetails(Attendance att) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  att.employeeName ?? 'Unknown Employee',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${att.employeeId ?? 'N/A'} • ${att.departmentName ?? 'No Dept'}',
                  style: theme.textTheme.titleMedium?.copyWith(color: AspireColors.textSecondary),
                ),
                const SizedBox(height: 24),
                
                _DetailRow(label: 'Status', value: att.status?.toUpperCase() ?? 'NOT MARKED'),
                _DetailRow(label: 'Date', value: att.date ?? '--'),
                _DetailRow(label: 'Punch In', value: _formatTime(att.checkInTime)),
                _DetailRow(label: 'Punch Out', value: _formatTime(att.checkOutTime)),
                _DetailRow(label: 'Total Hours', value: _calculateHours(att.checkInTime, att.checkOutTime)),
                if (att.productiveWorkingHours != null) _DetailRow(label: 'Prod. Hours', value: '${att.productiveWorkingHours}h'),
                if (att.totalBreakMinutes != null && att.totalBreakMinutes! > 0) _DetailRow(label: 'Total Break', value: '${att.totalBreakMinutes}m'),
                if (att.reason != null) _DetailRow(label: 'Reason', value: att.reason!),
                
                const SizedBox(height: 24),
                Text('Verification', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Punch In Selfie'),
                          const SizedBox(height: 8),
                          if (att.punchInSelfie != null)
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: NetworkImage('${AppConstants.apiBaseUrl.replaceAll('/api', '')}${att.punchInSelfie}'),
                            )
                          else
                            const Icon(Icons.person_off, size: 40),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Punch Out Selfie'),
                          const SizedBox(height: 8),
                          if (att.punchOutSelfie != null)
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: NetworkImage('${AppConstants.apiBaseUrl.replaceAll('/api', '')}${att.punchOutSelfie}'),
                            )
                          else
                            const Icon(Icons.person_off, size: 40),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _DetailRow(label: 'Punch In GPS', value: (att.punchInLat != null) ? '${att.punchInLat}, ${att.punchInLng}' : 'N/A'),
                _DetailRow(label: 'Punch Out GPS', value: (att.punchOutLat != null) ? '${att.punchOutLat}, ${att.punchOutLng}' : 'N/A'),
              ],
            ),
          ),
        );
      }
    );
  }

  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return '--:--';
    try {
      final dt = DateTime.parse(time).toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return '--:--';
    }
  }

  String _calculateHours(String? checkIn, String? checkOut) {
    if (checkIn == null) return '--';
    if (checkOut == null) return 'In Progress';
    try {
      final start = DateTime.parse(checkIn);
      final end = DateTime.parse(checkOut);
      final diff = end.difference(start);
      final hours = diff.inHours;
      final mins = diff.inMinutes % 60;
      return '${hours}h ${mins}m';
    } catch (_) {
      return '--';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'present': return AspireColors.success;
      case 'late': return AspireColors.warning;
      case 'half day': return Colors.orange;
      case 'absent': return AspireColors.error;
      case 'leave':
      case 'work from home':
      case 'on duty': return AspireColors.primary;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Date Picker
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Team Attendance',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                        });
                        _fetchDashboard();
                      }
                    },
                  )
                ],
              ),
              const SizedBox(height: 16),
              
              if (_isLoading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (_dashboardData != null) ...[
                // Summaries
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildSummaryCard('Total', _dashboardData!.summary['totalEmployees'] ?? 0, AspireColors.primary),
                      _buildSummaryCard('Present', _dashboardData!.summary['present'] ?? 0, AspireColors.success),
                      _buildSummaryCard('Late', _dashboardData!.summary['late'] ?? 0, AspireColors.warning),
                      _buildSummaryCard('Half Day', _dashboardData!.summary['halfDay'] ?? 0, Colors.orange),
                      _buildSummaryCard('Absent', _dashboardData!.summary['absent'] ?? 0, AspireColors.error),
                      _buildSummaryCard('Not Marked', _dashboardData!.summary['notMarkedYet'] ?? 0, Colors.grey),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Filters
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search employee...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: theme.cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppConstants.inputRadius),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (val) {
                          setState(() => _searchQuery = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(AppConstants.inputRadius),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedStatus,
                          items: ['All', 'Present', 'Late', 'Half Day', 'Absent', 'Not Marked Yet']
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedStatus = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // List
                Expanded(
                  child: _filteredList.isEmpty
                    ? const Center(child: Text('No attendance records found.'))
                    : ListView.builder(
                        itemCount: _filteredList.length,
                        itemBuilder: (context, index) {
                          final att = _filteredList[index];
                          final statusStr = att.status ?? 'Not Marked';
                          return PremiumCard(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            onTap: () => _showEmployeeDetails(att),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AspireColors.primary.withOpacity(0.1),
                                  child: Text(
                                    att.employeeName?.substring(0, 1).toUpperCase() ?? '?',
                                    style: const TextStyle(color: AspireColors.primary, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        att.employeeName ?? '',
                                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '${att.employeeId} • ${att.departmentName}',
                                        style: theme.textTheme.bodySmall?.copyWith(color: AspireColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(statusStr).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        statusStr.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: _getStatusColor(statusStr),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatTime(att.checkInTime),
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  
  const _DetailRow({required this.label, required this.value});
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: AspireColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
