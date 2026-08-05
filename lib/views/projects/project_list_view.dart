import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../models/project.dart';
import '../../services/api_service.dart';
import 'project_detail_view.dart';
import 'project_form_view.dart';

class ProjectListView extends StatefulWidget {
  const ProjectListView({super.key});

  @override
  State<ProjectListView> createState() => _ProjectListViewState();
}

class _ProjectListViewState extends State<ProjectListView> {
  String _selectedPriority = '';
  String _selectedStatus = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final api = Provider.of<ApiService>(context);
    final user = api.currentUser;

    if (user == null) return const SizedBox();

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Filter Panel
          Container(
            padding: const EdgeInsets.all(24.0),
            color: isDark ? Colors.transparent : Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Projects registry',
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(
                            'Manage and monitor corporate itineraries and bookings',
                            style: theme.textTheme.bodyMedium),
                      ],
                    ),
                    if (user.role == 'manager')
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ProjectFormView()),
                          );
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('New Project'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AspireColors.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                // Filters Row
                Row(
                  children: [
                    // Status filter dropdown
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: isDark
                                ? AspireColors.darkBorder
                                : AspireColors.lightBorder),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value:
                              _selectedStatus.isEmpty ? null : _selectedStatus,
                          hint: const Text('Filter Status',
                              style: TextStyle(fontSize: 13)),
                          items: const [
                            DropdownMenuItem(
                                value: '', child: Text('All Statuses')),
                            DropdownMenuItem(
                                value: 'not_started',
                                child: Text('Not Started')),
                            DropdownMenuItem(
                                value: 'in_progress',
                                child: Text('In Progress')),
                            DropdownMenuItem(
                                value: 'under_review',
                                child: Text('Under Review')),
                            DropdownMenuItem(
                                value: 'completed', child: Text('Completed')),
                            DropdownMenuItem(
                                value: 'on_hold', child: Text('On Hold')),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedStatus = val ?? '';
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Priority filter dropdown
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: isDark
                                ? AspireColors.darkBorder
                                : AspireColors.lightBorder),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPriority.isEmpty
                              ? null
                              : _selectedPriority,
                          hint: const Text('Filter Priority',
                              style: TextStyle(fontSize: 13)),
                          items: const [
                            DropdownMenuItem(
                                value: '', child: Text('All Priorities')),
                            DropdownMenuItem(value: 'low', child: Text('Low')),
                            DropdownMenuItem(
                                value: 'medium', child: Text('Medium')),
                            DropdownMenuItem(
                                value: 'high', child: Text('High')),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedPriority = val ?? '';
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Projects Grid
          Expanded(
            child: FutureBuilder<List<Project>>(
              future: api.fetchProjects(
                status: _selectedStatus,
                priority: _selectedPriority,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final projects = snapshot.data ?? [];
                if (projects.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_outlined,
                            size: 64, color: Colors.grey.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text('No projects found matching filter settings.',
                            style: theme.textTheme.bodyLarge),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(24.0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width >= 1100
                        ? 3
                        : MediaQuery.of(context).size.width >= 700
                            ? 2
                            : 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.45,
                  ),
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    return _buildProjectCard(context, project);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, Project project) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = AspireColors.getStatusColor(project.status);
    final priorityColor = AspireColors.getPriorityColor(project.priority);

    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProjectDetailView(projectId: project.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ID, Status & Priority Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    project.projectId,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary,
                        fontSize: 13),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          project.priority.toUpperCase(),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: priorityColor,
                              fontSize: 9),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          project.status.replaceFirst('_', ' ').toUpperCase(),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                              fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Name & Client
              Text(
                project.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Client: ${project.clientName}',
                style: theme.textTheme.bodySmall,
              ),
              const Spacer(),
              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Progress',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500)),
                      Text('${project.progressPercentage}%',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: project.progressPercentage / 100,
                      backgroundColor:
                          isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AspireColors.accent),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              // Team (Department) & Due date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people_outline,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        project.assignedTeamName ?? 'General Operations',
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        project.dueDate.substring(0, 10),
                        style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
