import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Model for a single stroke in the notes canvas
class NoteStroke {
  final List<Offset> points;
  final Color color;
  final double width;

  NoteStroke({
    required this.points,
    required this.color,
    this.width = 2.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
      'color': color.toARGB32(),
      'width': width,
    };
  }

  factory NoteStroke.fromJson(Map<String, dynamic> json) {
    return NoteStroke(
      points: (json['points'] as List)
          .map((p) => Offset(p['dx'] as double, p['dy'] as double))
          .toList(),
      color: Color(json['color'] as int),
      width: json['width'] as double,
    );
  }
}

/// Handwritten notes canvas widget
class NotesCanvas extends StatefulWidget {
  // A4 proportions in points: 595 x 842
  static const Size logicalSize = Size(595, 842);

  final String? initialNotes; // JSON string of strokes
  final Function(String) onNotesChanged; // Callback when notes change
  final VoidCallback? onToggleCollapse; // Optional callback to collapse section
  final bool showCollapseButton; // Whether to show collapse button

  const NotesCanvas({
    super.key,
    this.initialNotes,
    required this.onNotesChanged,
    this.onToggleCollapse,
    this.showCollapseButton = false,
  });

  @override
  State<NotesCanvas> createState() => _NotesCanvasState();
}

class _NotesCanvasState extends State<NotesCanvas> {
  List<NoteStroke> strokes = [];
  NoteStroke? currentStroke;
  Color selectedColor = Colors.black;
  double strokeWidth = 2.0;

  @override
  void initState() {
    super.initState();
    _loadInitialNotes();
  }

  void _loadInitialNotes() {
    if (widget.initialNotes != null && widget.initialNotes!.isNotEmpty) {
      try {
        final List<dynamic> jsonList = json.decode(widget.initialNotes!);
        setState(() {
          strokes = jsonList.map((e) => NoteStroke.fromJson(e)).toList();
        });
      } catch (e) {
        // Invalid JSON, start with empty strokes
        strokes = [];
      }
    }
  }

  void _saveNotes() {
    final jsonList = strokes.map((s) => s.toJson()).toList();
    final jsonString = json.encode(jsonList);
    widget.onNotesChanged(jsonString);
  }

  // Convert screen coordinates to logical coordinates
  Offset _screenToLogical(Offset screenPoint, Size screenSize) {
    final scaleX = NotesCanvas.logicalSize.width / screenSize.width;
    final scaleY = NotesCanvas.logicalSize.height / screenSize.height;
    return Offset(
      screenPoint.dx * scaleX,
      screenPoint.dy * scaleY,
    );
  }


  void _onPanEnd(DragEndDetails details) {
    if (currentStroke != null) {
      currentStroke = null;
      _saveNotes();
    }
  }

  void _undo() {
    if (strokes.isNotEmpty) {
      setState(() {
        strokes.removeLast();
      });
      _saveNotes();
    }
  }

  void _clear() {
    setState(() {
      strokes.clear();
      currentStroke = null;
    });
    _saveNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Simple toolbar like dental canvas
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildColorButton(Colors.black),
            _buildColorButton(const Color(0xFF3164DE)),
            _buildColorButton(const Color(0xFF19A14E)),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: strokes.isEmpty ? null : _undo,
              tooltip: 'Undo',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: strokes.isEmpty ? null : _clear,
              tooltip: 'Clear',
            ),
          ],
        ),
        // Canvas - same structure as dental canvas
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenSize = Size(constraints.maxWidth, constraints.maxHeight);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (details) {
                  final logicalPoint = _screenToLogical(details.localPosition, screenSize);
                  setState(() {
                    currentStroke = NoteStroke(
                      points: [logicalPoint],
                      color: selectedColor,
                      width: strokeWidth,
                    );
                    strokes.add(currentStroke!);
                  });
                },
                onPanUpdate: (details) {
                  final logicalPoint = _screenToLogical(details.localPosition, screenSize);
                  setState(() {
                    currentStroke?.points.add(logicalPoint);
                  });
                },
                onPanEnd: _onPanEnd,
                child: Stack(
                  children: [
                    // Prescription background (header + lines)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: PrescriptionBackgroundPainter(),
                      ),
                    ),
                    // Strokes
                    Positioned.fill(
                      child: CustomPaint(
                        painter: NotesPainter(strokes: strokes, screenSize: screenSize),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildColorButton(Color color) {
    final isSelected = selectedColor == color;
    return InkWell(
      onTap: () {
        setState(() {
          selectedColor = color;
        });
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? const Color(0xFF3164DE) : Colors.grey.shade400,
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}

/// Painter for prescription background (header + ruled lines)
class PrescriptionBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
    );

    // Draw prescription header
    const headerHeight = 80.0;

    // Clinic name
    textPainter.text = const TextSpan(
      text: '[DENTAL CLINIC NAME]',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF3164DE),
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(16, 8));

    // Date
    final today = DateTime.now();
    final dateStr = '${today.day}/${today.month}/${today.year}';
    textPainter.text = TextSpan(
      text: 'Date: $dateStr',
      style: const TextStyle(fontSize: 12, color: Color(0xFF393C4D)),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(16, 35));

    // Draw separator line after header
    final separatorPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      const Offset(0, headerHeight),
      Offset(size.width, headerHeight),
      separatorPaint,
    );

    // Draw ruled lines below header
    final linePaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 0.5;

    const double lineSpacing = 30.0;
    const double leftMargin = 40.0;

    // Draw margin line
    final marginPaint = Paint()
      ..color = const Color(0xFFEF6161).withAlpha(76)
      ..strokeWidth = 1.0;

    canvas.drawLine(
      const Offset(leftMargin, headerHeight),
      Offset(leftMargin, size.height),
      marginPaint,
    );

    // Draw horizontal lines
    for (double y = headerHeight + lineSpacing; y < size.height; y += lineSpacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(PrescriptionBackgroundPainter oldDelegate) => false;
}

/// Custom painter for rendering note strokes only
class NotesPainter extends CustomPainter {
  final List<NoteStroke> strokes;
  final Size screenSize;

  NotesPainter({required this.strokes, required this.screenSize});

  @override
  void paint(Canvas canvas, Size size) {
    // Convert logical to screen for display
    Offset toScreen(Offset logical) {
      final scaleX = screenSize.width / NotesCanvas.logicalSize.width;
      final scaleY = screenSize.height / NotesCanvas.logicalSize.height;
      return Offset(logical.dx * scaleX, logical.dy * scaleY);
    }

    // Draw all strokes (including current stroke if being drawn)
    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;

      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(
          toScreen(stroke.points[i]),
          toScreen(stroke.points[i + 1]),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(NotesPainter oldDelegate) {
    return oldDelegate.strokes != strokes;
  }
}

/// Builds prescription background (header + ruled lines) for PDF export
pw.Widget buildPrescriptionPdfBackground() {
  return pw.CustomPaint(
    size: const PdfPoint(595, 842), // A4 size
    painter: (PdfGraphics canvas, PdfPoint size) {
      const headerHeight = 80.0;
      const lineSpacing = 30.0;
      const leftMargin = 40.0;

      // Draw separator line after header
      canvas
        ..setStrokeColor(PdfColors.grey300)
        ..setLineWidth(1.0)
        ..moveTo(0, size.y - headerHeight)
        ..lineTo(size.x, size.y - headerHeight)
        ..strokePath();

      // Draw horizontal ruled lines
      canvas
        ..setStrokeColor(PdfColors.grey300)
        ..setLineWidth(0.5);

      for (double y = headerHeight + lineSpacing; y < size.y; y += lineSpacing) {
        canvas
          ..moveTo(0, size.y - y)
          ..lineTo(size.x, size.y - y)
          ..strokePath();
      }

      // Draw left margin line
      canvas
        ..setStrokeColor(PdfColors.red300)
        ..setLineWidth(1.0)
        ..moveTo(leftMargin, size.y - headerHeight)
        ..lineTo(leftMargin, 0)
        ..strokePath();
    },
  );
}
