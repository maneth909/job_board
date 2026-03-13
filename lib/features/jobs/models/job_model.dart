class Job {
  final String id;
  final String employerId;
  final String title;
  final String description;
  final List<String> skillsRequired;
  final String category;
  final bool isActive;
  final DateTime createdAt;

  Job({
    required this.id,
    required this.employerId,
    required this.title,
    required this.description,
    required this.skillsRequired,
    required this.category,
    required this.isActive,
    required this.createdAt,
  });

  factory Job.fromMap(Map<String, dynamic> map) {
    return Job(
      id: map['id'] as String,
      employerId: map['employer_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      skillsRequired: List<String>.from(map['skills_required'] ?? []),
      category: map['category'] as String,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employer_id': employerId,
      'title': title,
      'description': description,
      'skills_required': skillsRequired,
      'category': category,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Job copyWith({
    String? id,
    String? employerId,
    String? title,
    String? description,
    List<String>? skillsRequired,
    String? category,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Job(
      id: id ?? this.id,
      employerId: employerId ?? this.employerId,
      title: title ?? this.title,
      description: description ?? this.description,
      skillsRequired: skillsRequired ?? this.skillsRequired,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
