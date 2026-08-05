import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../models/dashboard_stats.dart';
import '../../models/task.dart';
import '../../widgets/dashboard_components.dart';

class StaffDashboard extends StatefulWidget {
  final ValueChanged<int>? onNavigate;

  const StaffDashboard({
    super.key,
    this.onNavigate,
  });

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  Future<void> _reloadDashboard() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('BUILDING STAFF DASHBOARD');
    final api = Provider.of<ApiService>(context, listen: false);

    return Scaffold(
      backgroundColor: AspireDashboardColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reloadDashboard,
          child: FutureBuilder<DashboardStats?>(
            future: api.fetchDashboardStats(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                debugPrint('Dashboard load error: ${snapshot.error}');
                return AspireDashboardErrorState(
                  message: snapshot.error.toString(),
                  onRetry: _reloadDashboard,
                );
              }

              final stats = snapshot.data;
              if (stats == null || stats.staffSummary == null) {
                return const AspireDashboardEmptyState(
                    message: 'Dashboard data unavailable');
              }

              final summary = stats.staffSummary!;
              final myTasksCount = summary['myTasksCount'] ?? 0;
              final dueTodayCount = summary['dueTodayCount'] ?? 0;
              final overdueCount = summary['overdueCount'] ?? 0;
              final completedCount = summary['completedCount'] ?? 0;
              final productivity = summary['personalProductivity'] ?? 100.0;
              final currentUser = api.currentUser;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspireWelcomeBanner(
                      greeting: 'Welcome back',
                      userName: currentUser?.name ?? 'User',
                      role: 'Staff Dashboard',
                    ),
                    const SizedBox(height: 24),
                    AspireDashboardGrid(
                      cards: [
                        AspireSummaryCard(
                          title: 'My Tasks',
                          value: myTasksCount.toString(),
                          icon: Icons.assignment,
                          color: AspireDashboardColors.blue,
                          onTap: () => widget.onNavigate?.call(1),
                        ),
                        AspireSummaryCard(
                          title: 'Due Today',
                          value: dueTodayCount.toString(),
                          icon: Icons.access_time,
                          color: dueTodayCount > 0
                              ? AspireDashboardColors.orange
                              : AspireDashboardColors.blue,
                          onTap: () => widget.onNavigate?.call(1),
                        ),
                        AspireSummaryCard(
                          title: 'Overdue',
                          value: overdueCount.toString(),
                          icon: Icons.warning_rounded,
                          color: overdueCount > 0
                              ? AspireDashboardColors.red
                              : AspireDashboardColors.blue,
                          onTap: () => widget.onNavigate?.call(1),
                        ),
                        AspireSummaryCard(
                          title: 'Completed',
                          value: completedCount.toString(),
                          icon: Icons.check_circle,
                          color: AspireDashboardColors.green,
                          onTap: () => widget.onNavigate?.call(1),
                        ),
                      ],
                    ),
                    if (overdueCount > 0 || dueTodayCount > 0) ...[
                      const SizedBox(height: 24),
                      AspireAlertCard(
                        title: 'Action Required',
                        message:
                            'You have $dueTodayCount task(s) due today and $overdueCount task(s) overdue.',
                      ),
                    ],
                    const SizedBox(height: 24),
                    _buildPendingTasksSection(context),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPendingTasksSection(BuildContext context) {
    return FutureBuilder<List<Task>>(
      future: Provider.of<ApiService>(context, listen: false).fetchTasks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          debugPrint('Dashboard pending tasks error: ${snapshot.error}');
          return AspireDashboardErrorState(
            message: snapshot.error.toString(),
            onRetry: _reloadDashboard,
          );
        }

        final allTasks = snapshot.data ?? [];
        final currentUser =
            Provider.of<ApiService>(context, listen: false).currentUser;

        final pendingTasks = allTasks.where((task) {
          if (task.assignedTo != currentUser?.id) return false;
          final status = task.status.toLowerCase();
          return status == 'pending' ||
              status == 'in_progress' ||
              status == 'in_review';
        }).toList();

        // Sort by nearest Due Date first
        pendingTasks.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          final dateA = DateTime.tryParse(a.dueDate!) ?? DateTime(2099);
          final dateB = DateTime.tryParse(b.dueDate!) ?? DateTime(2099);
          return dateA.compareTo(dateB);
        });

        final displayTasks = pendingTasks.take(5).toList();

        return AspireDashboardSection(
          title: 'Pending Works',
          child: displayTasks.isEmpty
              ? const AspireDashboardEmptyState(message: 'No pending tasks.')
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayTasks.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final task = displayTasks[index];
                    String dateStr = 'N/A';
                    if (task.dueDate != null) {
                      final parsed = DateTime.tryParse(task.dueDate!);
                      if (parsed != null) {
                        dateStr =
                            '${parsed.day.toString().padLeft(2, '0')} ${_getMonth(parsed.month)} ${parsed.year}';
                      }
                    }
                    Color statusColor = AspireDashboardColors.blue;
                    if (task.status.toLowerCase() == 'in_review')
                      statusColor = AspireDashboardColors.orange;

                    return AspirePendingTaskTile(
                      title: task.title,
                      dateStr: 'Due: $dateStr',
                      priority:
                          '${task.priority[0].toUpperCase()}${task.priority.substring(1)}',
                      status: _formatStatus(task.status),
                      statusColor: statusColor,
                    );
                  },
                ),
        );
      },
    );
  }

  String _getMonth(int m) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    if (m >= 1 && m <= 12) return months[m - 1];
    return '';
  }

  String _formatStatus(String status) {
    if (status.toLowerCase() == 'in_progress') return 'In Progress';
    if (status.toLowerCase() == 'in_review') return 'In Review';
    if (status.toLowerCase() == 'pending') return 'Pending';
    return status;
  }
}
