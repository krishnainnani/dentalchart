import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'patient_model.dart';
import 'intake_validator.dart';

class PatientIntakeScreen extends StatefulWidget {
  const PatientIntakeScreen({super.key});

  @override
  State<PatientIntakeScreen> createState() => _PatientIntakeScreenState();
}

class _PatientIntakeScreenState extends State<PatientIntakeScreen> {
  final _formKey = GlobalKey<FormState>();

  // Basic Information Controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String _selectedSex = 'Male';

  // Medical Information Controllers
  final _medicalHistoryController = TextEditingController();
  final _currentMedicationsController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _habitsController = TextEditingController();
  bool _isPregnant = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _medicalHistoryController.dispose();
    _currentMedicationsController.dispose();
    _allergiesController.dispose();
    _habitsController.dispose();
    super.dispose();
  }

  void _savePatient() {
    if (_formKey.currentState!.validate()) {
      final patient = Patient(
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        sex: _selectedSex,
        medicalHistory: _medicalHistoryController.text.trim(),
        currentMedications: _currentMedicationsController.text.trim(),
        allergies: _allergiesController.text.trim(),
        habits: _habitsController.text.trim(),
        isPregnant: _isPregnant,
      );

      Navigator.of(context).pop(patient);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Registration'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ========== BASIC INFORMATION SECTION ==========
              _buildSectionHeader('Basic Information', Icons.person),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  hintText: 'Enter patient full name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: IntakeValidator.validateName,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(
                        labelText: 'Age *',
                        hintText: 'Age',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      validator: IntakeValidator.validateAge,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedSex,
                      decoration: const InputDecoration(
                        labelText: 'Sex *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.wc),
                      ),
                      items: ['Male', 'Female', 'Other'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedSex = newValue;
                          });
                        }
                      },
                      validator: IntakeValidator.validateSex,
                    ),
                  ),
                ],
              ),

              // Pregnancy checkbox (only for females)
              if (_selectedSex == 'Female') ...[
                const SizedBox(height: 16),
                Card(
                  color: Colors.pink.shade50,
                  child: CheckboxListTile(
                    title: const Text('Currently Pregnant'),
                    subtitle: const Text('Check if patient is pregnant'),
                    value: _isPregnant,
                    onChanged: (bool? value) {
                      setState(() {
                        _isPregnant = value ?? false;
                      });
                    },
                    secondary: const Icon(Icons.pregnant_woman, color: Colors.pink),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // ========== MEDICAL HISTORY SECTION ==========
              _buildSectionHeader('Medical History', Icons.medical_services),
              const SizedBox(height: 16),

              TextFormField(
                controller: _medicalHistoryController,
                decoration: const InputDecoration(
                  labelText: 'Past Medical Conditions',
                  hintText: 'Previous surgeries, chronic conditions, hospitalizations...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.history),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 32),

              // ========== CURRENT MEDICATIONS SECTION ==========
              _buildSectionHeader('Current Medications', Icons.medication),
              const SizedBox(height: 16),

              TextFormField(
                controller: _currentMedicationsController,
                decoration: const InputDecoration(
                  labelText: 'Medications & Supplements',
                  hintText: 'List all current medications, vitamins, and supplements...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medication_liquid),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 32),

              // ========== ALLERGIES SECTION ==========
              _buildSectionHeader('Allergies', Icons.warning_amber),
              const SizedBox(height: 16),

              TextFormField(
                controller: _allergiesController,
                decoration: const InputDecoration(
                  labelText: 'Known Allergies',
                  hintText: 'Medications, foods, latex, etc...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.warning_amber_outlined),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 32),

              // ========== HABITS SECTION ==========
              _buildSectionHeader('Habits & Lifestyle', Icons.local_cafe),
              const SizedBox(height: 16),

              TextFormField(
                controller: _habitsController,
                decoration: const InputDecoration(
                  labelText: 'Smoking, Alcohol, Diet',
                  hintText: 'Smoking history, alcohol consumption, dietary habits...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.smoking_rooms),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 32),

              // Save button
              ElevatedButton(
                onPressed: _savePatient,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: const Text('Save Patient Record'),
              ),
              const SizedBox(height: 8),

              const Text(
                '* Required fields',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 28),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.blue.shade100],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
