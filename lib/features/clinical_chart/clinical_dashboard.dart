import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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
    _reloadPatient();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _database.close();
    super.dispose();
  }

  Future<void> _reloadPatient() async {
    if (widget.patient.id != null) {
      final freshPatient = await _database.getPatient(widget.patient.id!);
      if (freshPatient != null && mounted) {
        setState(() {
          _currentPatient = freshPatient;
        });
      }
    }
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

  Future<void> _saveDentalStrokes(String strokesJson) async {
    try {
      final updatedPatient = _currentPatient.copyWith(dentalChartStrokes: strokesJson);
      await _database.updatePatient(updatedPatient);
      setState(() {
        _currentPatient = updatedPatient;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving dental chart: $e')),
        );
      }
    }
  }

  Future<void> _exportCombinedPdf() async {
    try {
      final doc = pw.Document();

      // Parse dental strokes
      List<Stroke> parsedDentalStrokes = [];
      if (_currentPatient.dentalChartStrokes.isNotEmpty) {
        try {
          final List<dynamic> jsonList = json.decode(_currentPatient.dentalChartStrokes);
          parsedDentalStrokes = jsonList.map((e) => Stroke.fromJson(e)).toList();
        } catch (e) {
          // Invalid JSON, continue with empty strokes
        }
      }

      // Parse prescription strokes
      List<NoteStroke> parsedPrescriptionStrokes = [];
      if (_currentPatient.clinicalNotes.isNotEmpty) {
        try {
          final List<dynamic> jsonList = json.decode(_currentPatient.clinicalNotes);
          parsedPrescriptionStrokes = jsonList.map((e) => NoteStroke.fromJson(e)).toList();
        } catch (e) {
          // Invalid JSON, continue with empty strokes
        }
      }

      // PAGE 1: Dental Chart
      final svgString = await rootBundle.loadString("assets/teeth_chart.svg");

      doc.addPage(
        pw.Page(
          pageFormat: const PdfPageFormat(1000, 1000),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Patient header
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Patient: ${_currentPatient.name}',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Age: ${_currentPatient.age} | Sex: ${_currentPatient.sex}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.Text(
                        'Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 16),
                // Dental chart with strokes
                pw.Expanded(
                  child: pw.Stack(
                    children: [
                      pw.SizedBox(
                        width: 1000,
                        height: 1000,
                        child: pw.SvgImage(
                          svg: svgString,
                          fit: pw.BoxFit.contain,
                        ),
                      ),
                      pw.SizedBox(
                        width: 1000,
                        height: 1000,
                        child: pw.CustomPaint(
                          painter: (PdfGraphics canvas, PdfPoint size) {
                            // Draw dental strokes with Y-axis inversion
                            for (final stroke in parsedDentalStrokes) {
                              canvas
                                ..setStrokeColor(PdfColor.fromInt(stroke.color.toARGB32()))
                                ..setLineWidth(stroke.width);

                              for (int i = 0; i < stroke.points.length - 1; i++) {
                                final p1 = stroke.points[i];
                                final p2 = stroke.points[i + 1];

                                final y1 = 1000 - p1.dy; // Y-axis inversion
                                final y2 = 1000 - p2.dy;

                                canvas
                                  ..moveTo(p1.dx, y1)
                                  ..lineTo(p2.dx, y2)
                                  ..strokePath();
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      // PAGE 2: Prescription
      doc.addPage(
        pw.Page(
          pageFormat: const PdfPageFormat(1000, 1000),
          build: (context) {
            return pw.Stack(
              children: [
                // Background (header + ruled lines)
                pw.Positioned.fill(
                  child: buildPrescriptionPdfBackground(),
                ),
                // Patient header at top
                pw.Positioned(
                  top: 8,
                  left: 16,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '[DENTAL CLINIC NAME]',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue700,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.Text(
                        'Patient: ${_currentPatient.name}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Strokes
                pw.Positioned.fill(
                  child: pw.CustomPaint(
                    painter: (PdfGraphics canvas, PdfPoint size) {
                      // Draw prescription strokes with Y-axis inversion
                      for (final stroke in parsedPrescriptionStrokes) {
                        canvas
                          ..setStrokeColor(PdfColor.fromInt(stroke.color.toARGB32()))
                          ..setLineWidth(stroke.width);

                        for (int i = 0; i < stroke.points.length - 1; i++) {
                          final p1 = stroke.points[i];
                          final p2 = stroke.points[i + 1];

                          // Y-axis inversion for PDF (PDF origin is bottom-left)
                          final y1 = 1000 - p1.dy; // Same as dental canvas: 1000 points
                          final y2 = 1000 - p2.dy;

                          canvas
                            ..moveTo(p1.dx, y1)
                            ..lineTo(p2.dx, y2)
                            ..strokePath();
                        }
                      }
                    },
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Export PDF
      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: '${_currentPatient.name}_dental_chart_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting PDF: $e')),
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
          // Combined PDF export button
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export to PDF',
            onPressed: _exportCombinedPdf,
          ),
        ],
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
                // Dental Chart Tab with persistence
                CanvasScreen(
                  initialStrokes: _currentPatient.dentalChartStrokes,
                  onStrokesChanged: _saveDentalStrokes,
                ),
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
