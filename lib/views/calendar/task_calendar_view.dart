import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../models/task.dart';
import '../../models/user.dart';
import '../../config/colors.dart';
import '../tasks/task_detail_view.dart';

class TaskCalendarView extends StatefulWidget {
  const TaskCalendarView({super.key});

  @override
  State<TaskCalendarView> createState() => _TaskCalendarViewState();
}

class _TaskCalendarViewState extends State<TaskCalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Task>> _tasksByDate = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadMonthTasks(_focusedDay);
  }

  DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime? parseTaskDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  Future<void> _loadMonthTasks(DateTime month) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final firstDay = DateTime(month.year, month.month, 1);
      final lastDay = DateTime(month.year, month.month + 1, 0);

      final startDateStr = DateFormat('yyyy-MM-dd').format(firstDay);
      final endDateStr = DateFormat('yyyy-MM-dd').format(lastDay);

      final tasks = await apiService.fetchCalendarTasks(
        startDate: startDateStr,
        endDate: endDateStr,
      );

      final Map<DateTime, List<Task>> tasksMap = {};
      for (var task in tasks) {
        final dueDate = parseTaskDate(task.dueDate);
        if (dueDate != null) {
          final normalized = normalizeDate(dueDate);
          if (tasksMap[normalized] == null) {
            tasksMap[normalized] = [];
          }
          tasksMap[normalized]!.add(task);
        }
      }

      if (mounted) {
        setState(() {
          _tasksByDate = tasksMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Unable to load calendar tasks';
          _isLoading = false;
        });
      }
    }
  }

  List<Task> _getEventsForDay(DateTime day) {
    final key = normalizeDate(day);
    return _tasksByDate[key] ?? [];
  }

  Color taskCalendarColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_review':
        return Colors.orange;
      case 'pending':
      case 'in_progress':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildMarker(DateTime day, List<Task> events, User user) {
    if (events.isEmpty) return const SizedBox();

    if (user.role == 'manager') {
      return Positioned(
        bottom: 1,
        child: Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
        ),
      );
    } else {
      bool hasPending = false;
      bool hasReview = false;
      bool hasCompleted = false;

      for (var task in events) {
        final color = taskCalendarColor(task.status);
        if (color == Colors.red) hasPending = true;
        if (color == Colors.orange) hasReview = true;
        if (color == Colors.green) hasCompleted = true;
      }

      Color markerColor = Colors.grey;
      if (hasPending) {
        markerColor = Colors.red;
      } else if (hasReview) {
        markerColor = Colors.orange;
      } else if (hasCompleted) {
        markerColor = Colors.green;
      }

      return Positioned(
        bottom: 1,
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: markerColor,
            shape: BoxShape.circle,
          ),
        ),
      );
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  void _onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
    _loadMonthTasks(focusedDay);
  }

  Future<void> _openTaskDetails(Task task) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailView(taskId: task.id),
      ),
    );
    // Refresh calendar after returning in case of updates
    _loadMonthTasks(_focusedDay);
  }

  Widget _buildTaskCard(Task task, User user) {
    final statusColor = taskCalendarColor(task.status);
    final dueDate = parseTaskDate(task.dueDate);
    final isOverdue = dueDate != null &&
        normalizeDate(dueDate).isBefore(normalizeDate(DateTime.now())) &&
        task.status.toLowerCase() != 'completed';

    String statusText = task.status;
    if (statusText.toLowerCase() == 'completed') {
      statusText = 'Completed';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () => _openTaskDetails(task),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (isOverdue &&
                      (user.role == 'staff' || user.role == 'team_leader'))
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red[900],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Overdue',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: statusColor),
                      ),
                      child: Text(
                        statusText.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (user.role == 'manager') ...[
                Text('Assigned To: ${task.assignedToName ?? 'Unassigned'}',
                    style: const TextStyle(color: Colors.black54)),
                Text('Department: ${task.departmentName ?? 'N/A'}',
                    style: const TextStyle(color: Colors.black54)),
              ] else if (user.role == 'team_leader') ...[
                Text(
                    'Assigned Employee: ${task.assignedToName ?? 'Unassigned'}',
                    style: const TextStyle(color: Colors.black54)),
              ] else if (user.role == 'staff') ...[
                Text(
                    'Due Date: ${dueDate != null ? DateFormat('d MMM yyyy').format(dueDate) : 'N/A'}',
                    style: const TextStyle(color: Colors.black54)),
              ],
              const SizedBox(height: 4),
              Text('Priority: ${task.priority.toUpperCase()}',
                  style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context);
    final user = apiService.currentUser;

    if (user == null) {
      return const Center(child: Text('User not found'));
    }

    final selectedTasks =
        _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        backgroundColor: AspireColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadMonthTasks(_focusedDay),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.red.shade100,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_error!,
                            style: const TextStyle(color: Colors.red)),
                        TextButton(
                          onPressed: () => _loadMonthTasks(_focusedDay),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                TableCalendar<Task>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: _onDaySelected,
                  onPageChanged: _onPageChanged,
                  eventLoader: _getEventsForDay,
                  calendarFormat: CalendarFormat.month,
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Month',
                    CalendarFormat.twoWeeks: '2 Weeks',
                    CalendarFormat.week: 'Week',
                  },
                  headerStyle: const HeaderStyle(
                    titleCentered: true,
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      return _buildMarker(date, events, user);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else ...[
                  if (_selectedDay != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tasks for ${DateFormat('d MMMM yyyy').format(_selectedDay!)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${selectedTasks.length} Tasks',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (selectedTasks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          _tasksByDate.isEmpty
                              ? 'No tasks scheduled for this month.'
                              : 'No tasks scheduled for this date.',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: selectedTasks.length,
                      itemBuilder: (context, index) {
                        return _buildTaskCard(selectedTasks[index], user);
                      },
                    ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
