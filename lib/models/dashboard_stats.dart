class DashboardStats {
  final String role;

  // Manager fields
  final Map<String, int>? managerCards;
  final Map<String, dynamic>? managerSummary;
  final List<Map<String, dynamic>>? monthlyProductivity;
  final List<Map<String, dynamic>>? topPerformers;
  final List<Map<String, dynamic>>? teamPerformance;

  // TL fields
  final int? tlAssignedByManager;
  final int? tlAssignedToStaff;
  final int? tlProjectsAssigned;
  final double? tlTeamProgress;
  final Map<String, dynamic>? tlSummary;
  final List<Map<String, dynamic>>? tlStaffWorkload;

  // Staff fields
  final Map<String, dynamic>? staffSummary;

  DashboardStats({
    required this.role,
    this.managerCards,
    this.managerSummary,
    this.monthlyProductivity,
    this.topPerformers,
    this.teamPerformance,
    this.tlAssignedByManager,
    this.tlAssignedToStaff,
    this.tlProjectsAssigned,
    this.tlTeamProgress,
    this.tlSummary,
    this.tlStaffWorkload,
    this.staffSummary,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final role = json['role'] ?? 'staff';

    if (role == 'manager') {
      final cards = Map<String, int>.from(json['cards'] ?? {});
      final summary = Map<String, dynamic>.from(json['summary'] ?? {});
      final monthly =
          List<Map<String, dynamic>>.from(json['monthlyProductivity'] ?? []);
      final top = List<Map<String, dynamic>>.from(json['topPerformers'] ?? []);
      final teams =
          List<Map<String, dynamic>>.from(json['teamPerformance'] ?? []);
      return DashboardStats(
        role: role,
        managerCards: cards,
        managerSummary: summary,
        monthlyProductivity: monthly,
        topPerformers: top,
        teamPerformance: teams,
      );
    } else if (role == 'team_leader') {
      final summary = Map<String, dynamic>.from(json['summary'] ?? {});
      final workload =
          List<Map<String, dynamic>>.from(json['staffWorkload'] ?? []);
      return DashboardStats(
        role: role,
        tlAssignedByManager: json['assignedByManager'] ?? 0,
        tlAssignedToStaff: json['assignedToStaff'] ?? 0,
        tlProjectsAssigned: json['projectsAssigned'] ?? 0,
        tlTeamProgress: (json['teamProgress'] as num?)?.toDouble() ?? 0.0,
        tlSummary: summary,
        tlStaffWorkload: workload,
      );
    } else {
      final summary = Map<String, dynamic>.from(json['summary'] ?? {});
      return DashboardStats(
        role: role,
        staffSummary: summary,
      );
    }
  }
}
