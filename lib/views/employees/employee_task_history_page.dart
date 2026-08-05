import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../services/api_service.dart';
import '../../models/task.dart';
import '../tasks/task_detail_view.dart';

class EmployeeTaskHistoryPage extends StatefulWidget {
  final String employeeId;
  final String employeeName;
  final String employeeCode;
  final String designation;
  final String? departmentId;
  final String? departmentName;

  const EmployeeTaskHistoryPage({
    super.key,
    required this.employeeId,
    required this.employeeName,
    required this.employeeCode,
    required this.designation,
    this.departmentId,
    this.departmentName,
  });

  @override
  State<EmployeeTaskHistoryPage> createState() =>
      _EmployeeTaskHistoryPageState();
}

class _EmployeeTaskHistoryPageState extends State<EmployeeTaskHistoryPage> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final api = Provider.of<ApiService>(context, listen: false);
    final data = await api.fetchEmployeeTaskHistory(widget.employeeId);

    if (mounted) {
      if (data != null) {
        setState(() {
          _data = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load task history or access denied.';
          _isLoading = false;
        });
      }
    }
  }

  String _formatStatus(String status) {
    return status.replaceAll('_', ' ').toUpperCase();
  }

  Widget _buildSummaryCard(String title, int count, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, Task task) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TaskDetailView(taskId: task.id)),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AspireColors.getStatusColor(task.status)
                              .withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _formatStatus(task.status),
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
              // Title
              Text(
                task.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              // Description
              Text(
                task.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Due: ${task.dueDate.split("T")[0]}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.assignment_ind_outlined,
                          size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'By: ${task.assignedByName ?? "System"}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Task History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final summary = _data!['summary'];
    List<Task> tasks = _data!['tasks'] as List<Task>;

    // Filtering
    if (_selectedFilter != 'All') {
      final statusMap = {
        'Pending': 'pending',
        'In Progress': 'in_progress',
        'Waiting for Review': 'waiting_for_review',
        'Completed': 'completed',
      };
      final targetStatus = statusMap[_selectedFilter];
      tasks = tasks.where((t) => t.status == targetStatus).toList();
    }

    if (_searchQuery.isNotEmpty) {
      tasks = tasks.where((t) {
        return t.title.toLowerCase().contains(_searchQuery) ||
            t.description.toLowerCase().contains(_searchQuery) ||
            t.taskId.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Column(
      children: [
        // Top section: Employee Profile & Summaries
        Container(
          color: Theme.of(context).cardColor,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Employee Profile
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AspireColors.primary.withOpacity(0.1),
                    child: Text(
                      widget.employeeName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.employeeName,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${widget.designation} (${widget.employeeCode})',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        Text(
                          'Dept: ${widget.departmentName ?? "General"}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Summary Cards
              if (isDesktop)
                Row(
                  children: [
                    _buildSummaryCard(
                        'Total Tasks', summary['total'], Colors.blue),
                    const SizedBox(width: 8),
                    _buildSummaryCard(
                        'Completed', summary['completed'], Colors.green),
                    const SizedBox(width: 8),
                    _buildSummaryCard(
                        'In Progress', summary['in_progress'], Colors.purple),
                    const SizedBox(width: 8),
                    _buildSummaryCard(
                        'Pending', summary['pending'], Colors.amber.shade700),
                  ],
                )
              else
                Column(
                  children: [
                    Row(
                      children: [
                        _buildSummaryCard(
                            'Total Tasks', summary['total'], Colors.blue),
                        const SizedBox(width: 8),
                        _buildSummaryCard(
                            'Completed', summary['completed'], Colors.green),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildSummaryCard('In Progress', summary['in_progress'],
                            Colors.purple),
                        const SizedBox(width: 8),
                        _buildSummaryCard('Pending', summary['pending'],
                            Colors.amber.shade700),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Filters and Search
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search tasks by title or ID...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.toLowerCase();
                  });
                },
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    'All',
                    'Pending',
                    'In Progress',
                    'Waiting for Review',
                    'Completed'
                  ].map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedFilter = filter);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Task List
        Expanded(
          child: tasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.task_alt, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('No tasks found for ${widget.employeeName}.'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    return _buildTaskCard(context, tasks[index]);
                  },
                ),
        ),
      ],
    );
  }
}
