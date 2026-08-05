class LeadFollowUp {
  final String id;
  final String leadId;
  final String followUpDate;
  final String notes;
  final String createdAt;

  LeadFollowUp({
    required this.id,
    required this.leadId,
    required this.followUpDate,
    required this.notes,
    required this.createdAt,
  });

  factory LeadFollowUp.fromJson(Map<String, dynamic> json) {
    return LeadFollowUp(
      id: json['id'] ?? '',
      leadId: json['lead_id'] ?? '',
      followUpDate: json['follow_up_date'] ?? '',
      notes: json['notes'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class Lead {
  final String id;
  final String leadName;
  final String mobileNumber;
  final String destination;
  final String packageInterested;
  final double budget;
  final String source;
  final String status;
  final String? assignedStaffId;
  final String? assignedStaffName;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final List<LeadFollowUp> followUps;

  Lead({
    required this.id,
    required this.leadName,
    required this.mobileNumber,
    required this.destination,
    required this.packageInterested,
    required this.budget,
    required this.source,
    required this.status,
    this.assignedStaffId,
    this.assignedStaffName,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.followUps = const [],
  });

  factory Lead.fromJson(Map<String, dynamic> json) {
    var followUpsList = <LeadFollowUp>[];
    if (json['follow_ups'] != null) {
      followUpsList = (json['follow_ups'] as List)
          .map((i) => LeadFollowUp.fromJson(i))
          .toList();
    }

    return Lead(
      id: json['id'] ?? '',
      leadName: json['lead_name'] ?? '',
      mobileNumber: json['mobile_number'] ?? '',
      destination: json['destination'] ?? '',
      packageInterested: json['package_interested'] ?? '',
      budget: double.tryParse(json['budget']?.toString() ?? '0.0') ?? 0.0,
      source: json['source'] ?? 'Direct Enquiry',
      status: json['status'] ?? 'new_lead',
      assignedStaffId: json['assigned_staff_id'],
      assignedStaffName: json['assigned_staff_name'],
      notes: json['notes'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      followUps: followUpsList,
    );
  }
}
