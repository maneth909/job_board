class Job {
  final String id;
  final String employerId;
  final String title;
  final String description;
  final List<String> skillsRequired;
  final String category;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? location;
  final String? salaryRange;
  final String? telegramContact;
  final String? companyName;
  final String? companyLogo;

  Job({
    required this.id,
    required this.employerId,
    required this.title,
    required this.description,
    required this.skillsRequired,
    required this.category,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.location,
    this.salaryRange,
    this.telegramContact,
    this.companyName,
    this.companyLogo,
  });

  factory Job.fromMap(Map<String, dynamic> map) {
    final profilesData = map['profiles'];
    String? parsedCompanyName;
    String? parsedCompanyLogo;

    if (profilesData != null) {
      parsedCompanyLogo = profilesData['avatar_url'] as String?;
      
      final empData = profilesData['employer_profiles'];
      if (empData != null) {
        if (empData is List && empData.isNotEmpty) {
          parsedCompanyName = empData[0]['company_name'] as String?;
        } else if (empData is Map) {
          parsedCompanyName = empData['company_name'] as String?;
        }
      }
    }

    return Job(
      id: map['id'] as String,
      employerId: map['employer_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      skillsRequired: List<String>.from(map['skills_required'] ?? []),
      category: map['category'] as String,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] ?? map['created_at'] as String),
      location: map['location'] as String?,
      salaryRange: map['salary_range'] as String?,
      telegramContact: map['telegram_contact'] as String?,
      companyName: parsedCompanyName,
      companyLogo: parsedCompanyLogo,
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
      'updated_at': updatedAt.toIso8601String(),
      'location': location,
      'salary_range': salaryRange,
      'telegram_contact': telegramContact,
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
    DateTime? updatedAt,
    String? location,
    String? salaryRange,
    String? telegramContact,
    String? companyName,
    String? companyLogo,
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
      updatedAt: updatedAt ?? this.updatedAt,
      location: location ?? this.location,
      salaryRange: salaryRange ?? this.salaryRange,
      telegramContact: telegramContact ?? this.telegramContact,
      companyName: companyName ?? this.companyName,
      companyLogo: companyLogo ?? this.companyLogo,
    );
  }
}
