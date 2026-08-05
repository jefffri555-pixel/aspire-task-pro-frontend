class LeaveRequest {
  final String id;
  final String userId;
  final String? employeeName;
  final String? employeeId;
  final String? departmentName;
  final String leaveType; // 'sick', 'casual', 'annual', 'maternity', 'unpaid'
  final String startDate;
  final String endDate;
  final String status; // 'pending', 'approved', 'rejected'
  final String? reason;
  final String? adminNotes;
  final String? createdAt;

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
    );
  }
}
