import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../models/dashboard_stats.dart';
import '../tasks/task_list_view.dart';
import '../employees/employee_list_view.dart';
import '../../widgets/dashboard_components.dart';
import '../../widgets/premium_card.dart';
import '../../config/colors.dart';

class ManagerDashboard extends StatefulWidget {
  final ValueChanged<int>? onNavigate;

  const ManagerDashboard({
    super.key,
    this.onNavigate,
  });

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  Future<void> _reloadDashboard() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('BUILDING MANAGER DASHBOARD');
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
                debugPrint('Manager Dashboard load error: ${snapshot.error}');
                return AspireDashboardErrorState(
                  message: snapshot.error.toString(),
                  onRetry: _reloadDashboard,
                );
              }

              final stats = snapshot.data;
              if (stats == null || stats.managerSummary == null) {
                return const AspireDashboardEmptyState(
                    message: 'Manager dashboard data unavailable');
              }

              final summary = stats.managerSummary!;
              final teamPerformance = stats.teamPerformance ?? [];

              final pendingCount = summary['pendingTasks'] ?? 0;
              final completedCount = summary['completedTasks'] ?? 0;
              final inProgressCount = summary['inProgressTasks'] ?? 0;
              final waitingForReviewCount =
                  summary['waitingForReviewTasks'] ?? 0;
              final currentUser = api.currentUser;

              final totalTasks = pendingCount +
                  inProgressCount +
                  waitingForReviewCount +
                  completedCount;
              final completionRate = totalTasks > 0
                  ? (completedCount / totalTasks * 100).toInt()
                  : 0;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspireWelcomeBanner(
                      greeting: 'Welcome back',
                      userName: currentUser?.name ?? 'Manager',
                      role: 'Executive Dashboard',
                    ),
                    const SizedBox(height: 24),
                    AspireDashboardGrid(
                      cards: [
                        AspireSummaryCard(
                          title: 'Total Tasks',
                          value: totalTasks.toString(),
                          icon: Icons.analytics,
                          color: AspireDashboardColors.blue,
                          onTap: () => widget.onNavigate?.call(1),
                        ),
                        AspireSummaryCard(
                          title: 'Pending',
                          value: pendingCount.toString(),
                          icon: Icons.hourglass_empty,
                          color: AspireDashboardColors.orange,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TaskListView(
                                    initialStatusFilter: 'Pending'),
                              ),
                            );
                          },
                        ),
                        AspireSummaryCard(
                          title: 'In Progress',
                          value: inProgressCount.toString(),
                          icon: Icons.sync,
                          color: AspireDashboardColors.blue,
                          onTap: () => widget.onNavigate?.call(1),
                        ),
                        AspireSummaryCard(
                          title: 'Completed',
                          value: completedCount.toString(),
                          icon: Icons.task_alt,
                          color: AspireDashboardColors.green,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TaskListView(
                                    initialStatusFilter: 'Completed'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildDepartmentDistribution(context, teamPerformance),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDepartmentDistribution(
      BuildContext context, List<dynamic> departments) {
    if (departments.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Department Task Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AspireDashboardColors.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          AspireDashboardEmptyState(message: 'No department data available.'),
        ],
      );
    }

    final cards = departments.map((dept) {
      final deptName =
          dept['department_name'] ?? dept['team_name'] ?? 'Unknown';
      final members = dept['members_count']?.toString() ?? '0';
      final tasks = dept['active_tasks']?.toString() ?? '0';

      return PremiumCard(
        padding: const EdgeInsets.all(20),
        margin: EdgeInsets.zero,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EmployeeListView(
                initialDepartmentId: dept['department_id'],
                initialDepartmentName: deptName,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    deptName,
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
                    color: AspireDashboardColors.navy.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.domain,
                      color: AspireDashboardColors.navy, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Members',
                      style: TextStyle(
                        color: AspireDashboardColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      members,
                      style: const TextStyle(
                        color: AspireDashboardColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Tasks',
                      style: TextStyle(
                        color: AspireDashboardColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      tasks,
                      style: const TextStyle(
                        color: AspireDashboardColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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
          'Department Task Distribution',
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
}
