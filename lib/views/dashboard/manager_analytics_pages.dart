import 'package:flutter/material.dart';
import '../../config/colors.dart';

// --- Overall Tasks Completion Page ---
class OverallTasksCompletionPage extends StatelessWidget {
  final Map<String, dynamic> summary;

  const OverallTasksCompletionPage({super.key, required this.summary});

  Widget _buildIndicator(String label, String value, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: color)),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completionPct =
        (summary['completionPercentage'] as num?)?.toInt() ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Overall Tasks Completion')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Overall Tasks Completion',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 32),
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 200,
                            width: 200,
                            child: CircularProgressIndicator(
                              value: completionPct / 100,
                              strokeWidth: 14,
                              backgroundColor:
                                  theme.brightness == Brightness.dark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade100,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AspireColors.accent),
                            ),
                          ),
                          Text(
                            '$completionPct%',
                            style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold, fontSize: 32),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildIndicator(
                            'Pending',
                            (summary['pendingTasks'] ?? 0).toString(),
                            Colors.blue),
                        _buildIndicator(
                            'In Progress',
                            (summary['inProgressTasks'] ?? 0).toString(),
                            Colors.orange),
                        _buildIndicator(
                            'Completed',
                            (summary['completedTasks'] ?? 0).toString(),
                            Colors.green),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Productivity History Page ---
class ProductivityHistoryPage extends StatelessWidget {
  final List<dynamic> monthly;

  const ProductivityHistoryPage({super.key, required this.monthly});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxCount = monthly.isNotEmpty
        ? monthly
            .map((m) => (m['count'] as num?)?.toInt() ?? 0)
            .reduce((a, b) => a > b ? a : b)
        : 1;

    return Scaffold(
      appBar: AppBar(title: const Text('Productivity History')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Productivity History',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 250,
                      child: monthly.isEmpty
                          ? const Center(
                              child: Text('No historical data available.'))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: monthly.map((item) {
                                final count =
                                    (item['count'] as num?)?.toInt() ?? 0;
                                final double pct =
                                    maxCount > 0 ? (count / maxCount) : 0.0;

                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(count.toString(),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Container(
                                      width: 48,
                                      height: 180 * pct,
                                      decoration: BoxDecoration(
                                        color: AspireColors.secondary
                                            .withOpacity(0.8),
                                        borderRadius:
                                            const BorderRadius.vertical(
                                                top: Radius.circular(8)),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(item['month'] ?? '',
                                        style: const TextStyle(
                                            fontSize: 13, color: Colors.grey)),
                                  ],
                                );
                              }).toList(),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Team Progress & Performance Page ---
class TeamProgressPerformancePage extends StatelessWidget {
  final List<dynamic> teamPerformanceList;

  const TeamProgressPerformancePage(
      {super.key, required this.teamPerformanceList});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Team Progress & Performance')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Team Progress & Performance',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Average project completion rate per department',
                        style: theme.textTheme.bodySmall),
                    const SizedBox(height: 24),
                    Divider(
                        color: isDark
                            ? AspireColors.darkBorder
                            : AspireColors.lightBorder),
                    const SizedBox(height: 16),
                    if (teamPerformanceList.isEmpty)
                      const SizedBox(
                          height: 150,
                          child: Center(
                              child: Text('No team analytics registered.')))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: teamPerformanceList.length,
                        itemBuilder: (context, index) {
                          final team = teamPerformanceList[index];
                          final progress =
                              (team['avg_progress'] as num?)?.toDouble() ?? 0.0;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      team['team_name'] ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    ),
                                    Text(
                                      '${progress.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AspireColors.secondary,
                                          fontSize: 15),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: progress / 100,
                                    backgroundColor: isDark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade100,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        AspireColors.secondary),
                                    minHeight: 10,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Staff Productivity Rankings Page ---
class StaffProductivityRankingsPage extends StatelessWidget {
  final List<dynamic> performers;

  const StaffProductivityRankingsPage({super.key, required this.performers});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Staff Productivity Rankings')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Staff Productivity Rankings',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                        'Rankings by closed travel packages & ticket SLA rates',
                        style: theme.textTheme.bodySmall),
                    const SizedBox(height: 24),
                    Divider(
                        color: isDark
                            ? AspireColors.darkBorder
                            : AspireColors.lightBorder),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: performers.length,
                      itemBuilder: (context, index) {
                        final perf = performers[index];
                        final score = double.tryParse(
                                perf['performance_score']?.toString() ??
                                    '100') ??
                            100.0;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor:
                                    AspireColors.primary.withOpacity(0.1),
                                child: Text('#${index + 1}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AspireColors.primary)),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(perf['name'] ?? '',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text(perf['designation'] ?? '',
                                        style: theme.textTheme.bodyMedium),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: score >= 90
                                      ? Colors.green.shade50.withOpacity(0.2)
                                      : Colors.amber.shade50.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$score%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: score >= 90
                                        ? Colors.green
                                        : Colors.amber.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
