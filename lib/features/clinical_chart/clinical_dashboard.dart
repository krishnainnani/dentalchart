import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../features/patient_intake/patient_model.dart';
import '../../core/canvas_screen.dart';
import '../../data/database.dart';
import 'notes_canvas.dart';

class ClinicalDashboard extends StatefulWidget {
  final Patient patient;

  const ClinicalDashboard({
    super.key,
    required this.patient,
  });

  @override
  State<ClinicalDashboard> createState() => _ClinicalDashboardState();
}

class _ClinicalDashboardState extends State<ClinicalDashboard> {
  bool _showFullInfo = true;
  bool _showTeethChart = true;
  bool _showPrescription = true;
  final AppDatabase _database = AppDatabase();
  late Patient _currentPatient;

  @override
  void initState() {
    super.initState();
    _currentPatient = widget.patient;
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  Future<void> _saveNotes(String notesJson) async {
    try {
      final updatedPatient = _currentPatient.copyWith(clinicalNotes: notesJson);
      await _database.updatePatient(updatedPatient);
      setState(() {
        _currentPatient = updatedPatient;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving notes: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patient.name),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showFullInfo ? Icons.expand_less : Icons.expand_more),
            onPressed: () {
              setState(() {
                _showFullInfo = !_showFullInfo;
              });
            },
            tooltip: _showFullInfo ? 'Collapse Info' : 'Expand Info',
          ),
        ],
      ),
      body: Column(
        children: [
          // Patient Summary Card (compact only to save space)
          _buildCompactInfo(),
          const Divider(height: 1),
          // Clinical Notes Canvas
          Expanded(
            child: NotesCanvas(
              initialNotes: _currentPatient.clinicalNotes,
              onNotesChanged: _saveNotes,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInfo() {
    return Container(
      width: double.infinity,
      color: Colors.blue.shade50,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            radius: 20,
            child: Text(
              _currentPatient.name[0].toUpperCase(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentPatient.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_currentPatient.age}y • ${_currentPatient.sex}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          if (_currentPatient.allergies.isNotEmpty)
            const Chip(
              label: Text('⚠ Allergies', style: TextStyle(fontSize: 11)),
              backgroundColor: Colors.red,
              labelStyle: TextStyle(color: Colors.white),
              padding: EdgeInsets.symmetric(horizontal: 4),
            ),
        ],
      ),
    );
  }

  Widget _buildFullPatientInfo() {
    return Container(
      width: double.infinity,
      color: Colors.blue.shade50,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with avatar
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  radius: 28,
                  child: Text(
                    _currentPatient.name[0].toUpperCase(),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentPatient.name,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildInfoChip('${_currentPatient.age} years', Icons.calendar_today),
                          const SizedBox(width: 8),
                          _buildInfoChip(_currentPatient.sex, Icons.wc),
                          if (_currentPatient.isPregnant) ...[
                            const SizedBox(width: 8),
                            _buildInfoChip('Pregnant', Icons.pregnant_woman, Colors.pink),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),

            // Medical Information Grid
            _buildMedicalSection(),

            const SizedBox(height: 8),
            Text(
              'Registered: ${DateFormat('MMMM d, yyyy').format(_currentPatient.createdAt)}',
              style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalSection() {
    return Column(
      children: [
        if (_currentPatient.allergies.isNotEmpty)
          _buildInfoCard(
            'Allergies',
            _currentPatient.allergies,
            Icons.warning_amber,
            Colors.red.shade50,
            Colors.red,
          ),
        if (_currentPatient.currentMedications.isNotEmpty)
          _buildInfoCard(
            'Current Medications',
            _currentPatient.currentMedications,
            Icons.medication,
            Colors.green.shade50,
            Colors.green,
          ),
        if (_currentPatient.medicalHistory.isNotEmpty)
          _buildInfoCard(
            'Medical History',
            _currentPatient.medicalHistory,
            Icons.medical_services,
            Colors.blue.shade50,
            Colors.blue,
          ),
        if (_currentPatient.habits.isNotEmpty)
          _buildInfoCard(
            'Habits & Lifestyle',
            _currentPatient.habits,
            Icons.local_cafe,
            Colors.orange.shade50,
            Colors.orange,
          ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String content, IconData icon, Color bgColor, Color iconColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: iconColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(fontSize: 12, color: Colors.grey[800]),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, [Color? color]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Colors.blue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (color ?? Colors.blue).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? Colors.blue),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color ?? Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isExpanded, VoidCallback onToggle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFD6E0F8),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF393C4D),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
            onPressed: onToggle,
            tooltip: isExpanded ? 'Collapse' : 'Expand',
            color: const Color(0xFF3164DE),
          ),
        ],
      ),
    );
  }
}
