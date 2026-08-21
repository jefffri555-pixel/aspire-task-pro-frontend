class LeaveRequestAudit {
  final String id;
  final String leaveRequestId;
  final String? reviewerName;
  final String status;
  final String? remarks;
  final String? createdAt;

  LeaveRequestAudit({
    required this.id,
    required this.leaveRequestId,
    this.reviewerName,
    required this.status,
    this.remarks,
    this.createdAt,
  });

  factory LeaveRequestAudit.fromJson(Map<String, dynamic> json) {
    return LeaveRequestAudit(
      id: json['id'] ?? '',
      leaveRequestId: json['leave_request_id'] ?? '',
      reviewerName: json['reviewer_name'],
      status: json['status'] ?? 'pending',
      remarks: json['remarks'],
      createdAt: json['created_at'],
    );
  }
}

class LeaveRequest {
  final String id;
  final String userId;
  final String? employeeName;
  final String? employeeId;
  final String? departmentName;
  final String leaveType; // 'Sick Leave', 'Casual Leave', 'WFH', 'On Duty', etc.
  final String startDate;
  final String endDate;
  final String status; // 'pending', 'approved', 'rejected', 'cancelled'
  final String? reason;
  final String? adminNotes;
  final String? createdAt;
  
  // New fields
  final String durationType; // 'full_day', 'half_day'
  final String? location;
  final String? purpose;
  final String? attachmentUrl;
  final String? approvedByName;
  final List<LeaveRequestAudit> audits;

  LeaveRequest({
    required this.id,
    required this.userId,
    this.employeeName,
    this.employeeId,
    this.departmentName,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.reason,
    this.adminNotes,
    this.createdAt,
    this.durationType = 'full_day',
    this.location,
    this.purpose,
    this.attachmentUrl,
    this.approvedByName,
    this.audits = const [],
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    return LeaveRequest(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      employeeName: json['employee_name'],
      employeeId: json['employee_id'],
      departmentName: json['department_name'],
      leaveType: json['leave_type'] ?? 'casual',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      status: json['status'] ?? 'pending',
      reason: json['reason'],
      adminNotes: json['admin_notes'],
      createdAt: json['created_at'],
      durationType: json['duration_type'] ?? 'full_day',
      location: json['location'],
      purpose: json['purpose'],
      attachmentUrl: json['attachment_url'],
      approvedByName: json['approved_by_name'],
      audits: json['audits'] != null 
          ? (json['audits'] as List).map((i) => LeaveRequestAudit.fromJson(i)).toList()
          : [],
    );
  }
}
