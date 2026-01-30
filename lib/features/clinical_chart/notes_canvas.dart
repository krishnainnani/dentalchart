import 'dart:convert';
import 'package:flutter/material.dart';

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
  final String? initialNotes; // JSON string of strokes
  final Function(String) onNotesChanged; // Callback when notes change

  const NotesCanvas({
    super.key,
    this.initialNotes,
    required this.onNotesChanged,
  });

  @override
  State<NotesCanvas> createState() => _NotesCanvasState();
}

class _NotesCanvasState extends State<NotesCanvas> {
  List<NoteStroke> strokes = [];
  List<Offset> currentStroke = [];
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

  void _onPanStart(DragStartDetails details) {
    setState(() {
      currentStroke = [details.localPosition];
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      currentStroke.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (currentStroke.isNotEmpty) {
      setState(() {
        strokes.add(NoteStroke(
          points: List.from(currentStroke),
          color: selectedColor,
          width: strokeWidth,
        ));
        currentStroke = [];
      });
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
      currentStroke = [];
    });
    _saveNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFD6E0F8), // Light background panel from design doc
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            children: [
              const Text(
                'Clinical Notes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF393C4D), // Text primary from design doc
                ),
              ),
              const Spacer(),
              // Color picker
              _buildColorButton(Colors.black),
              const SizedBox(width: 8),
              _buildColorButton(const Color(0xFF3164DE)), // Primary blue
              const SizedBox(width: 8),
              _buildColorButton(const Color(0xFF19A14E)), // Success green
              const SizedBox(width: 16),
              // Undo button
              IconButton(
                icon: const Icon(Icons.undo),
                onPressed: strokes.isEmpty ? null : _undo,
                tooltip: 'Undo',
                color: const Color(0xFF3164DE),
              ),
              // Clear button
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: strokes.isEmpty ? null : _clear,
                tooltip: 'Clear All',
                color: const Color(0xFFEF6161),
              ),
            ],
          ),
        ),
        // Canvas area
        Expanded(
          child: Container(
            color: Colors.white,
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: CustomPaint(
                painter: NotesPainter(
                  strokes: strokes,
                  currentStroke: currentStroke,
                  currentColor: selectedColor,
                  currentWidth: strokeWidth,
                ),
                size: Size.infinite,
              ),
            ),
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

/// Custom painter for rendering note strokes
class NotesPainter extends CustomPainter {
  final List<NoteStroke> strokes;
  final List<Offset> currentStroke;
  final Color currentColor;
  final double currentWidth;

  NotesPainter({
    required this.strokes,
    required this.currentStroke,
    required this.currentColor,
    required this.currentWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw completed strokes
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    }

    // Draw current stroke being drawn
    if (currentStroke.length > 1) {
      final paint = Paint()
        ..color = currentColor
        ..strokeWidth = currentWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < currentStroke.length - 1; i++) {
        canvas.drawLine(currentStroke[i], currentStroke[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(NotesPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.currentStroke != currentStroke ||
        oldDelegate.currentColor != currentColor ||
        oldDelegate.currentWidth != currentWidth;
  }
}
