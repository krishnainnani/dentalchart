import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;

class CanvasScreen extends StatefulWidget {
  final String? initialStrokes;
  final Function(String)? onStrokesChanged;

  const CanvasScreen({
    super.key,
    this.initialStrokes,
    this.onStrokesChanged,
  });

  @override
  State<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends State<CanvasScreen> {
  static const Size logicalSize = Size(1000, 1000);

  List<Stroke> strokes = [];
  Stroke? currentStroke;
  Color selectedColor = Colors.red;

  @override
  void initState() {
    super.initState();
    _loadInitialStrokes();
  }

  void _loadInitialStrokes() {
    if (widget.initialStrokes != null && widget.initialStrokes!.isNotEmpty) {
      try {
        final List<dynamic> jsonList = json.decode(widget.initialStrokes!);
        setState(() {
          strokes = jsonList.map((e) => Stroke.fromJson(e)).toList();
        });
      } catch (e) {
        // Invalid JSON, start with empty strokes
        strokes = [];
      }
    }
  }

  void _saveStrokes() {
    if (widget.onStrokesChanged != null) {
      final jsonList = strokes.map((s) => s.toJson()).toList();
      final jsonString = json.encode(jsonList);
      widget.onStrokesChanged!(jsonString);
    }
  }

  // ================= Drawing =================

  void startStroke(Offset point) {
    setState(() {
      currentStroke = Stroke(color: selectedColor, width: 4, points: [point]);
      strokes.add(currentStroke!);
    });
  }

  void updateStroke(Offset point) {
    setState(() {
      currentStroke?.points.add(point);
    });
  }

  void endStroke() {
    currentStroke = null;
    _saveStrokes();
  }

  // ================= Controls =================

  void undoStroke() {
    if (strokes.isNotEmpty) {
      setState(() {
        strokes.removeLast();
      });
      _saveStrokes();
    }
  }

  void clearCanvas() {
    setState(() {
      strokes.clear();
    });
    _saveStrokes();
  }

  // ================= Coordinate Normalization =================

  Offset screenToLogical(Offset screenPoint, Size size) {
    final scaleX = logicalSize.width / size.width;
    final scaleY = logicalSize.height / size.height;
    return Offset(
      screenPoint.dx * scaleX,
      screenPoint.dy * scaleY,
    );
  }

  // ================= PDF Export =================

  Future<void> exportToPdf() async {
    final doc = pw.Document();
    final svgString = await rootBundle.loadString("assets/teeth_chart.svg");

    doc.addPage(
      pw.Page(
  pageFormat: const PdfPageFormat(1000, 1000),
  build: (context) {
    return pw.Stack(
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

              for (final stroke in strokes) {
                canvas
                  ..setStrokeColor(PdfColor.fromInt(stroke.color.toARGB32()))
                  ..setLineWidth(stroke.width);

                for (int i = 0; i < stroke.points.length - 1; i++) {
                        final p1 = stroke.points[i];
                        final p2 = stroke.points[i + 1];

                        final y1 = logicalSize.height - p1.dy;
                        final y2 = logicalSize.height - p2.dy;

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

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'dental_chart.pdf',
    );

  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dental Canvas"),
        actions: [
          IconButton(icon: const Icon(Icons.undo), onPressed: undoStroke),
          IconButton(icon: const Icon(Icons.delete), onPressed: clearCanvas),
          // PDF export button removed - now centralized in dashboard
        ],
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              colorButton(Colors.red),
              colorButton(Colors.blue),
              colorButton(Colors.green),
              colorButton(Colors.black),
            ],
          ),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: logicalSize.width / logicalSize.height,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (details) {
                        final box =
                            context.findRenderObject() as RenderBox;
                        final logicalPoint = screenToLogical(
                          details.localPosition,
                          box.size,
                        );
                        startStroke(logicalPoint);
                      },
                      onPanUpdate: (details) {
                        final box =
                            context.findRenderObject() as RenderBox;
                        final logicalPoint = screenToLogical(
                          details.localPosition,
                          box.size,
                        );
                        updateStroke(logicalPoint);
                      },
                      onPanEnd: (_) => endStroke(),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: SvgPicture.asset(
                              "assets/teeth_chart.svg",
                              fit: BoxFit.contain,
                            ),
                          ),
                          Positioned.fill(
                            child: CustomPaint(
                              painter: DrawingPainter(strokes),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget colorButton(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedColor = color;
        });
      },
      child: Container(
        margin: const EdgeInsets.all(6),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selectedColor == color ? Colors.white : Colors.black,
            width: 2,
          ),
        ),
      ),
    );
  }
}

// ================= Data Model =================

class Stroke {
  final Color color;
  final double width;
  final List<Offset> points;

  Stroke({
    required this.color,
    required this.width,
    required this.points,
  });

  // JSON serialization for persistence
  Map<String, dynamic> toJson() {
    return {
      'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
      'color': color.toARGB32(),
      'width': width,
    };
  }

  factory Stroke.fromJson(Map<String, dynamic> json) {
    return Stroke(
      points: (json['points'] as List)
          .map((p) => Offset(p['dx'] as double, p['dy'] as double))
          .toList(),
      color: Color(json['color'] as int),
      width: json['width'] as double,
    );
  }
}

// ================= Screen Painter =================

class DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;

  DrawingPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / _CanvasScreenState.logicalSize.width;
    final scaleY = size.height / _CanvasScreenState.logicalSize.height;

    Offset toScreen(Offset logical) {
      return Offset(logical.dx * scaleX, logical.dy * scaleY);
    }

    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

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
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
