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

class _ClinicalDashboardState extends State<ClinicalDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AppDatabase _database = AppDatabase();
  late Patient _currentPatient;

  @override
  void initState() {
    super.initState();
    _currentPatient = widget.patient;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.medical_services), text: 'Dental Chart'),
            Tab(icon: Icon(Icons.note_add), text: 'Prescription'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Patient Summary Card (compact)
          _buildCompactInfo(),
          const Divider(height: 1),
          // Tabbed Canvas Area
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Dental Chart Tab
                const CanvasScreen(),
                // Prescription Tab
                NotesCanvas(
                  initialNotes: _currentPatient.clinicalNotes,
                  onNotesChanged: _saveNotes,
                ),
              ],
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

}
