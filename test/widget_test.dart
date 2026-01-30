import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  runApp(const DentistApp());
}

class DentistApp extends StatelessWidget {
  const DentistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const CanvasScreen(),
    );
  }
}

class CanvasScreen extends StatelessWidget {
  const CanvasScreen({super.key});

  // Logical size of canvas (used for both screen & PDF later)
  static const Size logicalSize = Size(1000, 1000);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dental Canvas"),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              // PDF export later
            },
          )
        ],
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: logicalSize.width / logicalSize.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // SVG Background
                  Positioned.fill(
                    child: SvgPicture.asset(
                      "assets/teeth_chart.svg",
                      fit: BoxFit.contain,
                    ),
                  ),

                  // Drawing Layer (empty for now)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: DrawingPainter(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Later: draw strokes here
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
