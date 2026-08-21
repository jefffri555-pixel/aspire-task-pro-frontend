class RegularizationRequest {
  final String id;
  final String userId;
  final String? attendanceId;
  final String date;
  final String correctionType;
  final String? currentValue;
  final String requestedValue;
  final String? reason;
  final String? attachmentUrl;
  final String status;
  final String requestedBy;
  final String requestedAt;
  final String? reviewedBy;
  final String? reviewedAt;
  final String? remarks;
  
  // Joined fields for display
  final String? employeeName;
  final String? employeeId;
  final String? departmentName;
  final String? reviewerName;

  RegularizationRequest({
    required this.id,
    required this.userId,
    this.attendanceId,
    required this.date,
    required this.correctionType,
    this.currentValue,
    required this.requestedValue,
    this.reason,
    this.attachmentUrl,
    required this.status,
    required this.requestedBy,
    required this.requestedAt,
    this.reviewedBy,
    this.reviewedAt,
    this.remarks,
    this.employeeName,
    this.employeeId,
    this.departmentName,
    this.reviewerName,
  });

  factory RegularizationRequest.fromJson(Map<String, dynamic> json) {
    return RegularizationRequest(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      attendanceId: json['attendance_id']?.toString(),
      date: json['date'],
      correctionType: json['correction_type'],
      currentValue: json['current_value'],
      requestedValue: json['requested_value'],
      reason: json['reason'],
      attachmentUrl: json['attachment_url'],
      status: json['status'] ?? 'pending',
      requestedBy: json['requested_by'].toString(),
      requestedAt: json['requested_at'],
      reviewedBy: json['reviewed_by']?.toString(),
      reviewedAt: json['reviewed_at'],
      remarks: json['remarks'],
      employeeName: json['employee_name'],
      employeeId: json['employee_id'],
      departmentName: json['department_name'],
      reviewerName: json['reviewer_name'],
    );
  }
}
