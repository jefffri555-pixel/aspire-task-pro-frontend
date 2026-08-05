class ActivityLogItem {
  final String id;
  final String taskId;
  final String? userId;
  final String userName;
  final String userRole;
  final String action;
  final String? oldValue;
  final String? newValue;
  final DateTime createdAt;

  ActivityLogItem({
    required this.id,
    required this.taskId,
    this.userId,
    required this.userName,
    required this.userRole,
    required this.action,
    this.oldValue,
    this.newValue,
    required this.createdAt,
  });

  factory ActivityLogItem.fromJson(Map<String, dynamic> json) {
    return ActivityLogItem(
      id: json['id']?.toString() ?? '',
      taskId: json['task_id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      userName: json['user_name']?.toString() ?? 'System',
      userRole: json['user_role']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      oldValue: json['old_value']?.toString(),
      newValue: json['new_value']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString()).toLocal()
          : DateTime.now(),
    );
  }
}
