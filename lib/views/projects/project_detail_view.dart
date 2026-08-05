import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../models/project.dart';
import '../../services/api_service.dart';
import 'project_form_view.dart';
import '../tasks/task_form_view.dart';
import '../tasks/task_detail_view.dart';

class ProjectDetailView extends StatefulWidget {
  final String projectId;
  const ProjectDetailView({super.key, required this.projectId});

  @override
  State<ProjectDetailView> createState() => _ProjectDetailViewState();
}

class _ProjectDetailViewState extends State<ProjectDetailView> {
  @override
  Widget build(BuildContext context) {
    final api = Provider.of<ApiService>(context);
    final user = api.currentUser;

    if (user == null) return const SizedBox();

    return FutureBuilder<Project?>(
      future: api.fetchProjectById(widget.projectId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Project details')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final project = snapshot.data;
        if (project == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Project details')),
            body: const Center(child: Text('Failed to load project details.')),
          );
        }

        final isDesktop = MediaQuery.of(context).size.width >= 900;
        final statusColor = AspireColors.getStatusColor(project.status);
        final priorityColor = AspireColors.getPriorityColor(project.priority);

        return Scaffold(
          appBar: AppBar(
            title: Text(project.name),
            actions: [
              if (user.role == 'manager') ...[
                // Project Status Dropdown
                Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: project.status,
                      iconEnabledColor: statusColor,
                      items: const [
                        DropdownMenuItem(
                            value: 'not_started', child: Text('Not Started')),
                        DropdownMenuItem(
                            value: 'in_progress', child: Text('In Progress')),
                        DropdownMenuItem(
                            value: 'under_review', child: Text('Under Review')),
                        DropdownMenuItem(
                            value: 'completed', child: Text('Completed')),
                        DropdownMenuItem(
                            value: 'on_hold', child: Text('On Hold')),
                      ],
                      onChanged: (val) async {
                        if (val != null) {
                          await api.updateProject(project.id, {'status': val});
                          setState(() {});
                        }
                      },
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                  tooltip: 'Edit Project details',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProjectFormView(project: project),
                      ),
                    ).then((_) => setState(() {}));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Delete Project',
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Project'),
                        content: const Text(
                            'Are you sure you want to delete this project and all its tasks?'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel')),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await api.deleteProject(project.id);
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                ),
              ],
            ],
          ),
          body: isDesktop
              ? Row(
                  children: [
                    // Left Panel: Project details
                    Expanded(
                      flex: 2,
                      child: _buildDetailsPanel(
                          context, project, statusColor, priorityColor),
                    ),
                    const VerticalDivider(width: 1),
                    // Right Panel: Project Tasks
                    Expanded(
                      flex: 3,
                      child: _buildTasksPanel(context, project, user.role),
                    ),
                  ],
                )
              : ListView(
                  children: [
                    _buildDetailsPanel(
                        context, project, statusColor, priorityColor),
                    const Divider(height: 1),
                    SizedBox(
                      height: 500,
                      child: _buildTasksPanel(context, project, user.role),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildDetailsPanel(BuildContext context, Project project,
      Color statusColor, Color priorityColor) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      project.projectId,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.secondary),
                    ),
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
                            fontSize: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(project.name, style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Client: ${project.clientName}',
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.people_outline, 'Assigned Team',
                    project.assignedTeamName ?? 'General Operations'),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.calendar_today_outlined, 'Start Schedule',
                    project.startDate.substring(0, 10)),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.event_available_outlined, 'Target Schedule',
                    project.dueDate.substring(0, 10)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Timeline Card
        _buildVisualTimeline(project),
        const SizedBox(height: 16),
        // Leaders & Staff Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Leaders & Staff Assigned',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.supervisor_account, 'Project Manager',
                    project.managerName ?? 'Unassigned'),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.person_pin, 'Team Leader',
                    project.teamLeaderName ?? 'Unassigned'),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                const Text('Staff Members Assigned:',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                project.assignedEmployees.isEmpty
                    ? const Text('No staff members assigned.',
                        style: TextStyle(color: Colors.grey, fontSize: 11))
                    : Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: project.assignedEmployees.map((e) {
                          return Chip(
                            backgroundColor: Colors.purple.withOpacity(0.08),
                            avatar: CircleAvatar(
                              backgroundColor: Colors.purple,
                              child: Text(
                                e.name.isNotEmpty
                                    ? e.name[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 9),
                              ),
                            ),
                            label: Text(e.name,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.purple)),
                          );
                        }).toList(),
                      ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Progress Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Project Progress',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${project.progressPercentage}%',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: project.progressPercentage / 100,
                    backgroundColor:
                        isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AspireColors.accent),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w500))),
        Text(value,
            style: const TextStyle(
                color: Colors.grey, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildTasksPanel(BuildContext context, Project project, String role) {
    final theme = Theme.of(context);
    final tasks = project.tasks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Project tasks', style: theme.textTheme.titleMedium),
              if (role == 'manager' || role == 'team_leader')
                TextButton.icon(
                  onPressed: () {
                    // Navigate to task form pre-filled with project
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            TaskFormView(prefilledProjectId: project.id),
                      ),
                    ).then((_) => setState(() {}));
                  },
                  icon: const Icon(Icons.add_task),
                  label: const Text('Add Task'),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: tasks.isEmpty
              ? const Center(
                  child: Text('No tasks created under this project yet.'))
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final statusColor =
                        AspireColors.getStatusColor(task.status);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    TaskDetailView(taskId: task.id)),
                          ).then((_) => setState(() {}));
                        },
                        title: Text(task.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            'Assignee: ${task.assignedToName ?? "Unassigned"}'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            task.status.replaceFirst('_', ' ').toUpperCase(),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                                fontSize: 10),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildVisualTimeline(Project project) {
    final start = DateTime.tryParse(project.startDate) ?? DateTime.now();
    final due = DateTime.tryParse(project.dueDate) ??
        DateTime.now().add(const Duration(days: 1));
    final now = DateTime.now();

    final totalDays = due.difference(start).inDays;
    final elapsedDays = now.difference(start).inDays;

    double progress = 0.0;
    if (totalDays > 0) {
      progress = (elapsedDays / totalDays).clamp(0.0, 1.0);
    }

    final startFmt = '${start.day}/${start.month}/${start.year}';
    final dueFmt = '${due.day}/${due.month}/${due.year}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Project Schedule Timeline',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.indigo),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Start: $startFmt',
                    style: const TextStyle(fontSize: 10, color: Colors.grey)),
                if (now.isAfter(start) && now.isBefore(due))
                  Text(
                      'Active (${elapsedDays}d elapsed / ${totalDays - elapsedDays}d remaining)',
                      style: const TextStyle(
                          fontSize: 10,
                          color: Colors.indigo,
                          fontWeight: FontWeight.bold))
                else if (now.isBefore(start))
                  const Text('Not started yet',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold))
                else
                  const Text('Deadline passed',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.red,
                          fontWeight: FontWeight.bold)),
                Text('Due: $dueFmt',
                    style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
