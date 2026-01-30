class Patient {
  final int? id;
  final String name;
  final int age;
  final String sex;

  // Medical Information Sections
  final String medicalHistory;
  final String currentMedications;
  final String allergies;
  final String habits;
  final bool isPregnant;

  // Clinical Notes (handwritten notes stored as JSON)
  final String clinicalNotes;

  final DateTime createdAt;

  Patient({
    this.id,
    required this.name,
    required this.age,
    required this.sex,
    this.medicalHistory = '',
    this.currentMedications = '',
    this.allergies = '',
    this.habits = '',
    this.isPregnant = false,
    this.clinicalNotes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Patient copyWith({
    int? id,
    String? name,
    int? age,
    String? sex,
    String? medicalHistory,
    String? currentMedications,
    String? allergies,
    String? habits,
    bool? isPregnant,
    String? clinicalNotes,
    DateTime? createdAt,
  }) {
    return Patient(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      sex: sex ?? this.sex,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      currentMedications: currentMedications ?? this.currentMedications,
      allergies: allergies ?? this.allergies,
      habits: habits ?? this.habits,
      isPregnant: isPregnant ?? this.isPregnant,
      clinicalNotes: clinicalNotes ?? this.clinicalNotes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'sex': sex,
      'medical_history': medicalHistory,
      'current_medications': currentMedications,
      'allergies': allergies,
      'habits': habits,
      'is_pregnant': isPregnant ? 1 : 0,
      'clinical_notes': clinicalNotes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'] as int?,
      name: map['name'] as String,
      age: map['age'] as int,
      sex: map['sex'] as String,
      medicalHistory: map['medical_history'] as String? ?? '',
      currentMedications: map['current_medications'] as String? ?? '',
      allergies: map['allergies'] as String? ?? '',
      habits: map['habits'] as String? ?? '',
      isPregnant: (map['is_pregnant'] as int?) == 1,
      clinicalNotes: map['clinical_notes'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  String toString() {
    return 'Patient(id: $id, name: $name, age: $age, sex: $sex)';
  }
}
