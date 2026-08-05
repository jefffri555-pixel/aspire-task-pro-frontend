class Department {
  final String id;
  final String name;
  final int userCount;
  final int projectCount;
  final bool isActive;
  final String? createdAt;

  Department({
    required this.id,
    required this.name,
    this.userCount = 0,
    this.projectCount = 0,
    this.isActive = true,
    this.createdAt,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      userCount: int.tryParse(json['user_count']?.toString() ?? '0') ?? 0,
      projectCount: int.tryParse(json['project_count']?.toString() ?? '0') ?? 0,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'],
    );
  }
}
