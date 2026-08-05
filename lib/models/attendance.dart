class Attendance {
  final String id;
  final String userId;
  final String? employeeName;
  final String? employeeId;
  final String? departmentName;
  final String date;
  final String status; // 'present', 'absent', 'late', 'half_day'
  final String? checkInTime;
  final String? checkOutTime;

  Attendance({
    required this.id,
    required this.userId,
    this.employeeName,
    this.employeeId,
    this.departmentName,
    required this.date,
    required this.status,
    this.checkInTime,
    this.checkOutTime,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      employeeName: json['employee_name'],
      employeeId: json['employee_id'],
      departmentName: json['department_name'],
      date: json['date'] ?? '',
      status: json['status'] ?? 'present',
      checkInTime: json['check_in_time'],
      checkOutTime: json['check_out_time'],
    );
  }
}
