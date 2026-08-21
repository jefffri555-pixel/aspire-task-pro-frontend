import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../config/colors.dart';
import '../../config/constants.dart';
import '../../models/attendance.dart';
import '../../services/api_service.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/premium_button.dart';

class AttendanceHistoryView extends StatefulWidget {
  const AttendanceHistoryView({super.key});

  @override
  State<AttendanceHistoryView> createState() => _AttendanceHistoryViewState();
}

class _AttendanceHistoryViewState extends State<AttendanceHistoryView> {
  bool _isLoading = true;
  bool _isExporting = false;
  AttendanceDashboardData? _historyData;
  
  String _dateRangePreset = 'This Month';
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _applyDatePreset('This Month');
  }

  void _applyDatePreset(String preset) {
    final now = DateTime.now();
    setState(() {
      _dateRangePreset = preset;
      if (preset == 'Today') {
        _startDate = now;
        _endDate = now;
      } else if (preset == 'Yesterday') {
        _startDate = now.subtract(const Duration(days: 1));
        _endDate = now.subtract(const Duration(days: 1));
      } else if (preset == 'This Week') {
        _startDate = now.subtract(Duration(days: now.weekday - 1));
        _endDate = now;
      } else if (preset == 'This Month') {
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0);
      } else if (preset == 'Last Month') {
        _startDate = DateTime(now.year, now.month - 1, 1);
        _endDate = DateTime(now.year, now.month, 0);
      }
    });
    if (preset != 'Custom Date Range') {
      _fetchHistory();
    }
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    final api = Provider.of<ApiService>(context, listen: false);
    
    final sDate = _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null;
    final eDate = _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null;

    final data = await api.fetchAttendanceHistory(startDate: sDate, endDate: eDate);
    
    if (mounted) {
      setState(() {
        _historyData = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _export(String format) async {
    setState(() => _isExporting = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final sDate = _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null;
      final eDate = _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null;
      
      final path = await api.downloadAttendanceReport(format, startDate: sDate, endDate: eDate);
      if (mounted) {
        if (path != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Export saved to $path'), backgroundColor: AspireColors.success),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Export failed.'), backgroundColor: AspireColors.error),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  List<Attendance> get _filteredList {
    if (_historyData == null) return [];
    var list = _historyData!.attendanceList;

    if (_searchQuery.isNotEmpty) {
      list = list.where((a) => (a.employeeName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) || 
                               (a.employeeId?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)).toList();
    }

    return list;
  }

  Widget _buildSummaryGrid() {
    final s = _historyData?.summary ?? {};
    
    return GridView.count(
      crossAxisCount: 3,
      childAspectRatio: 1.8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: [
        _buildStatItem('Total Days', s['totalWorkingDays']?.toString() ?? '0', Colors.blue),
        _buildStatItem('Present', s['presentDays']?.toString() ?? '0', AspireColors.success),
        _buildStatItem('Late', s['lateDays']?.toString() ?? '0', AspireColors.warning),
        _buildStatItem('Absent', s['absentDays']?.toString() ?? '0', AspireColors.error),
        _buildStatItem('Prod Hours', '${s['productiveWorkingHours'] ?? s['totalWorkingHours'] ?? 0}h', Colors.purple),
        _buildStatItem('Break Hours', '${s['totalBreakHours'] ?? 0}h', Colors.orange),
      ],
    );
  }

  Widget _buildStatItem(String title, String val, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: c)),
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userRole = Provider.of<ApiService>(context, listen: false).currentUser?.role ?? 'staff';
    final isAdmin = ['admin', 'super_admin', 'manager', 'managing_director'].contains(userRole);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('History', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.download),
                    tooltip: 'Export',
                    onSelected: _export,
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'csv', child: Text('Export CSV')),
                      const PopupMenuItem(value: 'excel', child: Text('Export Excel')),
                      const PopupMenuItem(value: 'pdf', child: Text('Export PDF')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Filters
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _dateRangePreset,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ['Today', 'Yesterday', 'This Week', 'This Month', 'Last Month', 'Custom Date Range']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) {
                        if (v != null) _applyDatePreset(v);
                      },
                    ),
                  ),
                  if (isAdmin) const SizedBox(width: 12),
                  if (isAdmin)
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search Employee',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              
              if (_isLoading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else ...[
                _buildSummaryGrid(),
                const SizedBox(height: 16),
                
                Expanded(
                  child: _filteredList.isEmpty
                      ? const Center(child: Text('No attendance records found in this range.'))
                      : ListView.builder(
                          itemCount: _filteredList.length,
                          itemBuilder: (context, index) {
                            final att = _filteredList[index];
                            final statusStr = att.status ?? 'Not Marked';
                            return InkWell(
                              onTap: () {
                                _showTimelineDialog(context, att);
                              },
                              child: PremiumCard(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AspireColors.primary.withOpacity(0.1),
                                      child: Text(
                                        (att.date ?? '00').substring(8, 10),
                                        style: const TextStyle(color: AspireColors.primary, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isAdmin ? (att.employeeName ?? 'Unknown') : (att.date ?? 'Unknown Date'),
                                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            'In: ${_formatTime(att.checkInTime)} • Out: ${_formatTime(att.checkOutTime)}',
                                            style: theme.textTheme.bodySmall?.copyWith(color: AspireColors.textSecondary),
                                          ),
                                          if (att.productiveWorkingHours != null)
                                            Text(
                                              'Prod Hours: ${att.productiveWorkingHours}h',
                                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.purple, fontWeight: FontWeight.bold),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          statusStr.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: _getStatusColor(statusStr),
                                          ),
                                        ),
                                        if (att.breaks.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4.0),
                                            child: Text(
                                              '${att.totalBreakMinutes}m break',
                                              style: const TextStyle(fontSize: 10, color: Colors.orange),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
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

  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return '--:--';
    try {
      return DateFormat('hh:mm a').format(DateTime.parse(time).toLocal());
    } catch (_) {
      return '--:--';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'present': return AspireColors.success;
      case 'late': return AspireColors.warning;
      case 'half day': return Colors.orange;
      case 'absent': return AspireColors.error;
      default: return Colors.grey;
    }
  }

  void _showTimelineDialog(BuildContext context, Attendance att) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Daily Timeline'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.login, color: AspireColors.success),
                title: const Text('Punch In'),
                subtitle: Text(_formatTime(att.checkInTime)),
              ),
              ...att.breaks.map((b) => ListTile(
                leading: const Icon(Icons.coffee, color: Colors.orange),
                title: Text(b.breakType),
                subtitle: Text('${_formatTime(b.startTime)} - ${_formatTime(b.endTime)}\nDuration: ${b.durationMinutes} mins'),
              )),
              if (att.checkOutTime != null)
                ListTile(
                  leading: const Icon(Icons.logout, color: AspireColors.error),
                  title: const Text('Punch Out'),
                  subtitle: Text(_formatTime(att.checkOutTime)),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
