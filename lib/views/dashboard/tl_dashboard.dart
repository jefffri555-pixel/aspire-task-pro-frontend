import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../models/dashboard_stats.dart';
import '../../models/task.dart';
import '../../widgets/dashboard_components.dart';
import '../../widgets/premium_card.dart';

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

class TLDashboard extends StatefulWidget {
  final ValueChanged<int>? onNavigate;

  const TLDashboard({
    super.key,
    this.onNavigate,
  });

  @override
  State<TLDashboard> createState() => _TLDashboardState();
}

class _TLDashboardState extends State<TLDashboard> {
  Future<void> _reloadDashboard() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('BUILDING TEAM LEADER DASHBOARD');
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
                debugPrint('TL Dashboard load error: ${snapshot.error}');
                return AspireDashboardErrorState(
                  message: snapshot.error.toString(),
                  onRetry: _reloadDashboard,
                );
              }

              final stats = snapshot.data;
              if (stats == null || stats.tlSummary == null) {
                return const AspireDashboardEmptyState(
                    message: 'TL dashboard data unavailable');
              }

              final summary = stats.tlSummary!;
              final workload = stats.tlStaffWorkload ?? [];
              final totalTeam = _parseInt(summary['totalTeamTasks']);
              final completedTeam = _parseInt(summary['completedTeamTasks']);
              final completionRate =
                  _parseInt(summary['teamCompletionPercentage']);
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
                      role: 'Team Leader Dashboard',
                    ),
                    const SizedBox(height: 24),
                    AspireDashboardGrid(
                      cards: [
                        AspireSummaryCard(
                          title: 'Tasks Assigned',
                          value: stats.tlAssignedToStaff.toString(),
                          icon: Icons.assignment_turned_in,
                          color: AspireDashboardColors.blue,
                          onTap: () => widget.onNavigate?.call(1),
                        ),
                        AspireSummaryCard(
                          title: 'Pending Review',
                          value:
                              _parseInt(summary['pendingTeamTasks']).toString(),
                          icon: Icons.hourglass_empty,
                          color: AspireDashboardColors.orange,
                          onTap: () => widget.onNavigate?.call(1),
                        ),
                        AspireSummaryCard(
                          title: 'Completed',
                          value: completedTeam.toString(),
                          icon: Icons.check_circle,
                          color: AspireDashboardColors.green,
                          onTap: () => widget.onNavigate?.call(1),
                        ),
                        AspireSummaryCard(
                          title: 'Team Pending',
                          value: (totalTeam - completedTeam).toString(),
                          icon: Icons.group_work,
                          color: AspireDashboardColors.orange,
                          onTap: () => widget.onNavigate?.call(1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildTeamProgressCard(
                        context, totalTeam, completedTeam, completionRate),
                    const SizedBox(height: 24),
                    _buildStaffWorkloadCard(context, workload),
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

  Widget _buildTeamProgressCard(
      BuildContext context, int total, int completed, int rate) {
    return AspireDashboardSection(
      title: 'Team Goals Completion',
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            SizedBox(
              height: 110,
              width: 110,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: total > 0 ? (completed / total) : 0.0,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey[200],
                    color: AspireDashboardColors.blue,
                  ),
                  Text(
                    '$rate%',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: AspireDashboardColors.textPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Total Team Tasks',
                          style: TextStyle(
                              color: AspireDashboardColors.textSecondary)),
                      trailing: Text(total.toString(),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AspireDashboardColors.textPrimary,
                              fontSize: 16))),
                  ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Approved Completed',
                          style: TextStyle(
                              color: AspireDashboardColors.textSecondary)),
                      trailing: Text(completed.toString(),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AspireDashboardColors.textPrimary,
                              fontSize: 16))),
                  ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Pending Team Review',
                          style: TextStyle(
                              color: AspireDashboardColors.textSecondary)),
                      trailing: Text((total - completed).toString(),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AspireDashboardColors.textPrimary,
                              fontSize: 16))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffWorkloadCard(BuildContext context, List<dynamic> workload) {
    if (workload.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Staff Task Workloads',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AspireDashboardColors.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          AspireDashboardEmptyState(
              message: 'No staff workload data available.'),
        ],
      );
    }

    final cards = workload.map((item) {
      final taskCount = _parseInt(item['task_count']);
      return PremiumCard(
        padding: const EdgeInsets.all(20),
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item['name'] ?? '',
                    style: const TextStyle(
                      color: AspireDashboardColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AspireDashboardColors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person,
                      color: AspireDashboardColors.blue, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Active Tasks',
                  style: TextStyle(
                    color: AspireDashboardColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  taskCount.toString(),
                  style: const TextStyle(
                    color: AspireDashboardColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Staff Task Workloads',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AspireDashboardColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        AspireDashboardGrid(cards: cards),
      ],
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
          debugPrint('TL pending tasks error: ${snapshot.error}');
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
          title: 'Pending Tasks',
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
