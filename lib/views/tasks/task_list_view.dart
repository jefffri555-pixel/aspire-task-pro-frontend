import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../services/api_service.dart';
import '../../models/task.dart';
import 'task_detail_view.dart';
import 'task_form_view.dart';

class TaskListView extends StatefulWidget {
  final String? initialStatusFilter;
  const TaskListView({super.key, this.initialStatusFilter});

  @override
  State<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  String _searchQuery = '';
  String _priorityFilter = 'All';
  late List<String> _tabs;

  @override
  void initState() {
    super.initState();
    final api = Provider.of<ApiService>(context, listen: false);
    final role = api.currentUser?.role ?? 'staff';

    if (role == 'admin') {
      _tabs = ['All', 'Pending', 'In Progress', 'Waiting Review', 'Completed'];
    } else {
      _tabs = ['All', 'Pending', 'In Progress', 'Completed'];
    }

    int initialIndex = 0;
    if (widget.initialStatusFilter != null) {
      initialIndex = _tabs.indexOf(widget.initialStatusFilter!);
      if (initialIndex < 0) initialIndex = 0;
    }
    _tabController = TabController(
        length: _tabs.length, vsync: this, initialIndex: initialIndex);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  // Maps tab text to backend status enum values
  String? _getStatusFilter(int tabIndex) {
    if (tabIndex < 0 || tabIndex >= _tabs.length) return null;
    final tabName = _tabs[tabIndex];
    switch (tabName) {
      case 'Pending':
        return 'pending';
      case 'In Progress':
        return 'in_progress';
      case 'Waiting Review':
        return 'waiting_for_review';
      case 'Completed':
        return 'completed';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = Provider.of<ApiService>(context);
    final user = api.currentUser;

    if (user == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks Center',
            style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
        actions: [
          // Managers & TLs can create tasks
          if (user.role == 'manager' || user.role == 'team_leader')
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TaskFormView()),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('New Task'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AspireColors.accent,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search tasks by title, description or ID...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.toLowerCase();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _priorityFilter,
                  items: ['All', 'High', 'Medium', 'Low'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text('$value Priority'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _priorityFilter = val;
                      });
                    }
                  },
                )
              ],
            ),
          ),

          // Task List Body
          Expanded(
            child: AnimatedBuilder(
              animation: _tabController!,
              builder: (context, _) {
                final statusFilter = _getStatusFilter(_tabController!.index);

                return FutureBuilder<List<Task>>(
                  future: api.fetchTasks(status: statusFilter),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    var tasks = snapshot.data ?? [];

                    // Apply local priority & search query filters
                    if (_priorityFilter != 'All') {
                      tasks = tasks
                          .where((t) =>
                              t.priority.toLowerCase() ==
                              _priorityFilter.toLowerCase())
                          .toList();
                    }
                    if (_searchQuery.isNotEmpty) {
                      tasks = tasks.where((t) {
                        return t.title.toLowerCase().contains(_searchQuery) ||
                            t.description
                                .toLowerCase()
                                .contains(_searchQuery) ||
                            t.taskId.toLowerCase().contains(_searchQuery);
                      }).toList();
                    }

                    if (tasks.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.task_alt, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No tasks match the active filters.'),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return _buildTaskCard(context, task);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, Task task) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TaskDetailView(taskId: task.id)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Line 1: Header (Task ID, status chip, priority dot)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    task.taskId,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  Row(
                    children: [
                      // Priority dot
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AspireColors.getPriorityColor(task.priority),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        task.priority.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AspireColors.getPriorityColor(task.priority),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Status chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AspireColors.getStatusColor(task.status)
                              .withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          task.status.replaceValues(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AspireColors.getStatusColor(task.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Line 2: Title
              Text(
                task.title.isNotEmpty
                    ? task.title
                    : (task.titleAudioUrl != null
                        ? "Voice Task"
                        : "Untitled Task"),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (task.titleAudioUrl != null && task.title.isEmpty) ...[
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(Icons.mic, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
                    Text('Voice note attached',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ],
              const SizedBox(height: 4),

              // Line 3: Description
              if (task.description.isNotEmpty)
                Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              const SizedBox(height: 12),

              // Line 4: Progress Bar
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: task.progressPercentage / 100.0,
                      backgroundColor: isDark
                          ? AspireColors.darkBorder
                          : AspireColors.lightBorder,
                      color: AspireColors.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${task.progressPercentage}%',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Line 5: Assigned structures
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'To: ${task.assignedToName ?? "Unassigned"}',
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.event_outlined,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Due: ${task.dueDate.substring(0, 10)}',
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey),
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

// Inline extension mapping raw status formats into clean text
extension CleanStatus on String {
  String replaceValues() {
    return replaceAll('_', ' ').toUpperCase();
  }
}
