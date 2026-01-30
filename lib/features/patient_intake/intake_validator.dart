class IntakeValidator {
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  static String? validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Age is required';
    }

    final age = int.tryParse(value.trim());
    if (age == null) {
      return 'Age must be a number';
    }

    if (age <= 0 || age > 150) {
      return 'Age must be between 1 and 150';
    }

    return null;
  }

  static String? validateSex(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Sex is required';
    }
    return null;
  }

  static String? validateMedicalHistory(String? value) {
    // Medical history is optional, so no validation required
    return null;
  }

  static bool isValidPatientData({
    required String? name,
    required String? age,
    required String? sex,
  }) {
    return validateName(name) == null &&
        validateAge(age) == null &&
        validateSex(sex) == null;
  }
}
