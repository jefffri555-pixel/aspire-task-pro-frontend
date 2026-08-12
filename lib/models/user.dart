class User {
  final String id;
  final String employeeId;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String designation;
  final String? departmentId;
  final String? departmentName;
  final String? joiningDate;
  final String? reportingManagerId;
  final String? reportingManagerName;
  final String? teamLeaderId;
  final String? teamLeaderName;
  final double performanceScore;
  final String status;
  final String? profileImage;

  User({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.designation,
    this.departmentId,
    this.departmentName,
    this.joiningDate,
    this.reportingManagerId,
    this.reportingManagerName,
    this.teamLeaderId,
    this.teamLeaderName,
    required this.performanceScore,
    this.status = 'active',
    this.profileImage,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      employeeId: json['employee_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'staff',
      designation: json['designation'] ?? '',
      departmentId: json['department_id'],
      departmentName: json['department_name'],
      joiningDate: json['joining_date'],
      reportingManagerId: json['reporting_manager_id'],
      reportingManagerName: json['reporting_manager_name'],
      teamLeaderId: json['team_leader_id'],
      teamLeaderName: json['team_leader_name'],
      performanceScore:
          double.tryParse(json['performance_score']?.toString() ?? '100.0') ??
              100.0,
      status: json['status'] ?? 'active',
      profileImage: json['profile_image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'designation': designation,
      'department_id': departmentId,
      'department_name': departmentName,
      'joining_date': joiningDate,
      'reporting_manager_id': reportingManagerId,
      'reporting_manager_name': reportingManagerName,
      'team_leader_id': teamLeaderId,
      'team_leader_name': teamLeaderName,
      'performance_score': performanceScore,
      'status': status,
      'profile_image': profileImage,
    };
  }

  bool get isManager => role == 'manager' || role == 'managing_director';
  bool get isTL => role == 'team_leader';
  bool get isStaff => role == 'staff';
  bool get isAdmin => role == 'admin';
}

String formatRoleLabel(String role) {
  switch (role) {
    case 'super_admin':
    case 'admin':
      return 'Super Admin';
    case 'manager':
      return 'Manager';
    case 'managing_director':
      return 'Managing Director';
    case 'team_leader':
      return 'Team Leader';
    case 'staff':
      return 'Staff';
    default:
      return role;
  }
}
