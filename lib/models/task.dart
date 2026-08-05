class TaskComment {
  final String id;
  final String taskId;
  final String userId;
  final String userName;
  final String userRole;
  final String designation;
  final String comment;
  final String messageType;
  final String? audioUrl;
  final String? audioFileName;
  final String? audioMimeType;
  final int? audioDurationSeconds;
  final String createdAt;

  TaskComment({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.designation,
    required this.comment,
    this.messageType = 'text',
    this.audioUrl,
    this.audioFileName,
    this.audioMimeType,
    this.audioDurationSeconds,
    required this.createdAt,
  });

  factory TaskComment.fromJson(Map<String, dynamic> json) {
    return TaskComment(
      id: json['id'] ?? '',
      taskId: json['task_id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? 'System',
      userRole: json['user_role'] ?? 'staff',
      designation: json['designation'] ?? '',
      comment: json['comment']?.toString() ?? '',
      messageType: json['message_type']?.toString() ?? 'text',
      audioUrl: json['audio_url']?.toString(),
      audioFileName: json['audio_file_name']?.toString(),
      audioMimeType: json['audio_mime_type']?.toString(),
      audioDurationSeconds: json['audio_duration_seconds'] != null
          ? int.tryParse(json['audio_duration_seconds'].toString())
          : null,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class TaskAttachment {
  final String id;
  final String taskId;
  final String fileUrl;
  final String fileName;
  final String originalName;
  final String mimeType;
  final String uploadedBy;
  final String uploadedByName;
  final String createdAt;

  TaskAttachment({
    required this.id,
    required this.taskId,
    required this.fileUrl,
    required this.fileName,
    required this.originalName,
    required this.mimeType,
    required this.uploadedBy,
    required this.uploadedByName,
    required this.createdAt,
  });

  factory TaskAttachment.fromJson(Map<String, dynamic> data) {
    return TaskAttachment(
      id: data['id']?.toString() ?? '',
      taskId: data['task_id']?.toString() ?? '',
      fileUrl: data['file_url']?.toString() ?? '',
      fileName: data['file_name']?.toString() ?? '',
      originalName: data['original_name']?.toString() ??
          data['originalName']?.toString() ??
          data['file_name']?.toString() ??
          data['fileName']?.toString() ??
          'attachment',
      mimeType:
          data['mime_type']?.toString() ?? data['mimeType']?.toString() ?? '',
      uploadedBy: data['uploaded_by']?.toString() ??
          data['uploadedBy']?.toString() ??
          '',
      uploadedByName: data['uploaded_by_name']?.toString() ?? 'System',
      createdAt: data['created_at']?.toString() ?? '',
    );
  }
}

class Task {
  final String id;
  final String taskId;
  final String title;
  final String description;
  final String? departmentId;
  final String? departmentName;
  final String priority;
  final String status;
  final String startDate;
  final String dueDate;
  final String assignedBy;
  final String assignedByName;
  final String? assignedTo;
  final String? assignedToName;
  final int progressPercentage;
  final String? completionNotes;
  final String? projectId;
  final String? projectName;
  final String? titleAudioUrl;
  final String? titleAudioFileName;
  final String? titleAudioMimeType;
  final int? titleAudioDurationSeconds;
  final String? descriptionAudioUrl;
  final String? descriptionAudioFileName;
  final String? descriptionAudioMimeType;
  final int? descriptionAudioDurationSeconds;
  final String createdAt;
  final String updatedAt;
  final List<TaskComment> comments;
  final List<TaskAttachment> attachments;

  Task({
    required this.id,
    required this.taskId,
    required this.title,
    required this.description,
    this.departmentId,
    this.departmentName,
    required this.priority,
    required this.status,
    required this.startDate,
    required this.dueDate,
    required this.assignedBy,
    required this.assignedByName,
    this.assignedTo,
    this.assignedToName,
    required this.progressPercentage,
    this.completionNotes,
    this.projectId,
    this.projectName,
    this.titleAudioUrl,
    this.titleAudioFileName,
    this.titleAudioMimeType,
    this.titleAudioDurationSeconds,
    this.descriptionAudioUrl,
    this.descriptionAudioFileName,
    this.descriptionAudioMimeType,
    this.descriptionAudioDurationSeconds,
    required this.createdAt,
    required this.updatedAt,
    this.comments = const [],
    this.attachments = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'title': title,
      'description': description,
      'department_id': departmentId,
      'department_name': departmentName,
      'priority': priority,
      'status': status,
      'start_date': startDate,
      'due_date': dueDate,
      'assigned_by': assignedBy,
      'assigned_by_name': assignedByName,
      'assigned_to': assignedTo,
      'assigned_to_name': assignedToName,
      'progress_percentage': progressPercentage,
      'completion_notes': completionNotes,
      'project_id': projectId,
      'project_name': projectName,
      'title_audio_url': titleAudioUrl,
      'title_audio_file_name': titleAudioFileName,
      'title_audio_mime_type': titleAudioMimeType,
      'title_audio_duration_seconds': titleAudioDurationSeconds,
      'description_audio_url': descriptionAudioUrl,
      'description_audio_file_name': descriptionAudioFileName,
      'description_audio_mime_type': descriptionAudioMimeType,
      'description_audio_duration_seconds': descriptionAudioDurationSeconds,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    var commentsList = <TaskComment>[];
    if (json['comments'] != null) {
      commentsList = (json['comments'] as List)
          .map((i) => TaskComment.fromJson(i))
          .toList();
    }

    var attachmentsList = <TaskAttachment>[];
    if (json['attachments'] != null) {
      attachmentsList = (json['attachments'] as List)
          .map((i) => TaskAttachment.fromJson(i))
          .toList();
    }

    return Task(
      id: json['id'] ?? '',
      taskId: json['task_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      departmentId: json['department_id'],
      departmentName: json['department_name'],
      priority: json['priority'] ?? 'medium',
      status: json['status']?.toString() ?? 'pending',
      startDate: json['start_date'] ?? '',
      dueDate: json['due_date'] ?? '',
      assignedBy: json['assigned_by'] ?? '',
      assignedByName: json['assigned_by_name'] ?? 'System',
      assignedTo: json['assigned_to'],
      assignedToName: json['assigned_to_name'],
      progressPercentage: json['progress_percentage'] ?? 0,
      completionNotes: json['completion_notes'],
      projectId: json['project_id'],
      projectName: json['project_name'],
      titleAudioUrl: json['title_audio_url']?.toString(),
      titleAudioFileName: json['title_audio_file_name']?.toString(),
      titleAudioMimeType: json['title_audio_mime_type']?.toString(),
      titleAudioDurationSeconds: json['title_audio_duration_seconds'] != null
          ? int.tryParse(json['title_audio_duration_seconds'].toString())
          : null,
      descriptionAudioUrl: json['description_audio_url']?.toString(),
      descriptionAudioFileName: json['description_audio_file_name']?.toString(),
      descriptionAudioMimeType: json['description_audio_mime_type']?.toString(),
      descriptionAudioDurationSeconds:
          json['description_audio_duration_seconds'] != null
              ? int.tryParse(
                  json['description_audio_duration_seconds'].toString())
              : null,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      comments: commentsList,
      attachments: attachmentsList,
    );
  }
}

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

String getTaskStatusLabel(String status) {
  switch (status.trim().toLowerCase()) {
    case 'pending':
      return 'Pending';
    case 'in_progress':
      return 'In Progress';
    case 'in_review':
      return 'In Review';
    case 'completed':
      return 'Completed';
    default:
      return status;
  }
}

bool isManagerRole(String role) {
  final value = role.trim().toLowerCase();
  return value == 'manager' ||
      value == 'admin' ||
      value == 'super_admin' ||
      value == 'superadmin';
}

bool isTeamLeaderRole(String role) {
  final value = role.trim().toLowerCase();
  return value == 'team_leader' || value == 'teamleader' || value == 'tl';
}

String completionButtonLabel({
  required String role,
  required String status,
}) {
  final normalizedStatus = status.trim().toLowerCase();

  if (normalizedStatus == 'completed') {
    return 'Completed';
  }

  if (isManagerRole(role)) {
    if (normalizedStatus == 'in_review') {
      return 'Approve & Complete';
    }
    return 'Waiting for Staff Submission';
  }

  if (normalizedStatus == 'in_review') {
    return 'Submitted for Review';
  }

  return 'Mark as Completed';
}

bool canUpdateCompletionStatus({
  required String role,
  required String status,
}) {
  final normalizedStatus = status.trim().toLowerCase();

  if (normalizedStatus == 'completed') {
    return false;
  }

  if (isManagerRole(role)) {
    return normalizedStatus == 'in_review';
  }

  return normalizedStatus == 'pending' || normalizedStatus == 'in_progress';
}
