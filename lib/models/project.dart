import 'task.dart';
import 'user.dart';

class Project {
  final String id;
  final String projectId;
  final String name;
  final String clientName;
  final String startDate;
  final String dueDate;
  final String priority;
  final String status;
  final String? assignedTeamId;
  final String? assignedTeamName;
  final String? managerId;
  final String? managerName;
  final String? teamLeaderId;
  final String? teamLeaderName;
  final int progressPercentage;
  final String createdAt;
  final String updatedAt;
  final List<Task> tasks;
  final List<User> assignedEmployees;

  Project({
    required this.id,
    required this.projectId,
    required this.name,
    required this.clientName,
    required this.startDate,
    required this.dueDate,
    required this.priority,
    required this.status,
    this.assignedTeamId,
    this.assignedTeamName,
    this.managerId,
    this.managerName,
    this.teamLeaderId,
    this.teamLeaderName,
    required this.progressPercentage,
    required this.createdAt,
    required this.updatedAt,
    this.tasks = const [],
    this.assignedEmployees = const [],
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    var tasksList = <Task>[];
    if (json['tasks'] != null) {
      tasksList = (json['tasks'] as List).map((i) => Task.fromJson(i)).toList();
    }

    var employeesList = <User>[];
    if (json['assigned_employees'] != null) {
      employeesList = (json['assigned_employees'] as List)
          .map((i) => User.fromJson(i))
          .toList();
    }

    return Project(
      id: json['id'] ?? '',
      projectId: json['project_id'] ?? '',
      name: json['name'] ?? '',
      clientName: json['client_name'] ?? '',
      startDate: json['start_date'] ?? '',
      dueDate: json['due_date'] ?? '',
      priority: json['priority'] ?? 'medium',
      status: json['status'] ?? 'not_started',
      assignedTeamId: json['assigned_team_id'],
      assignedTeamName: json['team_name'] ?? json['assigned_team_name'],
      managerId: json['manager_id'],
      managerName: json['manager_name'],
      teamLeaderId: json['team_leader_id'],
      teamLeaderName: json['team_leader_name'],
      progressPercentage: json['progress_percentage'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      tasks: tasksList,
      assignedEmployees: employeesList,
    );
  }
}
