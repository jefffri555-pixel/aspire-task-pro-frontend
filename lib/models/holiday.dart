class Holiday {
  final String id;
  final String name;
  final String date; // YYYY-MM-DD
  final String type;
  final String description;

  Holiday({
    required this.id,
    required this.name,
    required this.date,
    required this.type,
    required this.description,
  });

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      date: json['date'] != null ? json['date'].toString().split('T')[0] : '',
      type: json['type'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'date': date,
      'type': type,
      'description': description,
    };
  }
}
