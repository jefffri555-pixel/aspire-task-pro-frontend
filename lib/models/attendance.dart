class BreakRecord {
  final String id;
  final String attendanceId;
  final String breakType;
  final String startTime;
  final String? endTime;
  final int durationMinutes;

  BreakRecord({
    required this.id,
    required this.attendanceId,
    required this.breakType,
    required this.startTime,
    this.endTime,
    this.durationMinutes = 0,
  });

  factory BreakRecord.fromJson(Map<String, dynamic> json) {
    return BreakRecord(
      id: json['id'] ?? '',
      attendanceId: json['attendance_id'] ?? '',
      breakType: json['break_type'] ?? 'Other',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'],
      durationMinutes: json['duration_minutes'] ?? 0,
    );
  }
}

class Attendance {
  final String id;
  final String userId;
  final String? employeeName;
  final String? employeeId;
  final String? departmentName;
  final String date;
  final String status; // 'present', 'absent', 'late', 'half_day', 'Leave', 'Work From Home', 'On Duty'
  final String? reason; // e.g. 'Half Day - Late Punch In'
  final String? checkInTime;
  final String? checkOutTime;
  final String? punchInSelfie;
  final String? punchOutSelfie;
  final double? punchInLat;
  final double? punchInLng;
  final double? punchOutLat;
  final double? punchOutLng;

  // Break Tracking Fields
  final List<BreakRecord> breaks;
  final int totalBreakMinutes;
  final String? activityStatus; // 'Working', 'On Break', 'Punched Out', 'Not Punched In'
  final double? productiveWorkingHours;

  Attendance({
    required this.id,
    required this.userId,
    this.employeeName,
    this.employeeId,
    this.departmentName,
    required this.date,
    required this.status,
    this.reason,
    this.checkInTime,
    this.checkOutTime,
    this.punchInSelfie,
    this.punchOutSelfie,
    this.punchInLat,
    this.punchInLng,
    this.punchOutLat,
    this.punchOutLng,
    this.breaks = const [],
    this.totalBreakMinutes = 0,
    this.activityStatus,
    this.productiveWorkingHours,
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
      reason: json['reason'],
      checkInTime: json['check_in_time'],
      checkOutTime: json['check_out_time'],
      punchInSelfie: json['punch_in_selfie'],
      punchOutSelfie: json['punch_out_selfie'],
      punchInLat: json['punch_in_lat'] != null ? double.tryParse(json['punch_in_lat'].toString()) : null,
      punchInLng: json['punch_in_lng'] != null ? double.tryParse(json['punch_in_lng'].toString()) : null,
      punchOutLat: json['punch_out_lat'] != null ? double.tryParse(json['punch_out_lat'].toString()) : null,
      punchOutLng: json['punch_out_lng'] != null ? double.tryParse(json['punch_out_lng'].toString()) : null,
      breaks: json['breaks'] != null 
          ? (json['breaks'] as List).map((i) => BreakRecord.fromJson(i)).toList()
          : [],
      totalBreakMinutes: json['total_break_minutes'] ?? 0,
      activityStatus: json['activity_status'],
      productiveWorkingHours: json['productive_working_hours'] != null 
          ? double.tryParse(json['productive_working_hours'].toString()) 
          : null,
    );
  }
}

class AttendanceDashboardData {
  final Map<String, dynamic> summary;
  final List<Attendance> attendanceList;

  AttendanceDashboardData({
    required this.summary,
    required this.attendanceList,
  });

  factory AttendanceDashboardData.fromJson(Map<String, dynamic> json) {
    final listRaw = json['attendanceList'] ?? json['history'] ?? json['records'];
    return AttendanceDashboardData(
      summary: json['summary'] ?? {},
      attendanceList: (listRaw as List?)
              ?.map((e) => Attendance.fromJson(e))
              .toList() ??
          [],
    );
  }
}
