# Dental Drawing App – Project Context

## Purpose
A simple Flutter app for dentists to draw on a teeth SVG chart and export the final annotated chart as a perfectly scaled PDF.

## Roadmap

Phase 1 – Canvas correctness ✅
Phase 2 – Control (Undo / Clear) ✅
Phase 3 – PDF Export ✅
Phase 4 – Canvas Persistence ✅
Phase 5 – UI / Design Polish ⏭
Phase 6 – Refactor & File Structure ⏭  

                                                                

## Core Requirements
- SVG is the background
- Freehand drawing on top
- Works on all screen sizes
- Export to PDF with correct scaling
- PDF output must visually match the app canvas
- Simple, readable, controllable code

## Tech Stack
- Flutter
- flutter_svg (for SVG rendering)
- pdf + printing (for PDF export later)

## Canvas Design
- Logical canvas size: 1000 x 1000 units
- All strokes stored in logical coordinates
- Screen scales logical canvas
- PDF uses same logical coordinates
- One coordinate system everywhere

## Current Status
- PDF export implemented and working
- PDF uses square logical page (1000 × 1000)
- SVG and strokes are correctly aligned in PDF
- Stroke coordinates are correctly flipped for PDF coordinate system
- Canvas persistence complete (dental chart + prescription)
- Auto-save functionality for all drawing operations

## Canvas Persistence (Phase 4 - COMPLETE)

**Status:** ✅ Implemented

Both dental chart and prescription canvases now persist strokes across sessions:

### Features
- Auto-save after each stroke, undo, or clear operation
- Strokes stored as JSON in SQLite database per patient
- Patient data automatically reloaded when opening clinical dashboard
- Tab switching preserves strokes within session
- Cross-session persistence (strokes survive app restart)

### Technical Details
- **Coordinate system:** 1000x1000 logical (resolution independent)
- **Database schema:** v4 with `dental_chart_strokes` column
- **Storage format:** JSON array of stroke objects
- **Serialization:** Stroke.toJson() / Stroke.fromJson()
- **Pattern:** Follows same implementation as prescription notes canvas

### Implementation
```dart
// Stroke serialization
Map<String, dynamic> toJson() {
  return {
    'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
    'color': color.toARGB32(),
    'width': width,
  };
}

// Storage in database per patient
dentalChartStrokes: text().named('dental_chart_strokes')();
```



## Data Models

```dart
class Stroke {
  final Color color;
  final double width;
  final List<Offset> points;
}

## Coordinate System (IMPORTANT)

The app uses a normalized coordinate system:

- Logical canvas size: 1000 x 1000
- All stroke points are stored in logical coordinates
- Screen drawing scales logical → screen
- Touch input converts screen → logical
- PDF export will use logical coordinates directly

This ensures:
- Resolution independence
- Perfect scaling on all devices
- Identical appearance in PDF and app

## Implementation Status
✔ Screen → Logical conversion implemented and tested  
✔ Logical → Screen conversion implemented and tested  
✔ Strokes stored in logical coordinates  
✔ Drawing remains correct on different canvas sizes 

#Upcoming Tasks
## Phase 2 – Control Features (Completed)
✔ Undo last stroke  
✔ Clear entire canvas  
✔ User has control over drawing mistakes  
✔ Drawing workflow is now dentist-friendly  

## Phase 3 – PDF Export (Completed)

✔ PDF is generated using logical canvas size (1000 × 1000)  
✔ SVG background is rendered at exact logical size in PDF  
✔ Strokes are replayed using logical coordinates  
✔ Y-axis inversion handled (Flutter: top-left origin, PDF: bottom-left origin)  
✔ No distortion or scaling mismatch  
✔ PDF output visually matches app canvas  
✔ Resolution independent and print-safe  

Important:
- Flutter coordinate system:
  - Origin: top-left
  - Y increases downward
- PDF coordinate system:
  - Origin: bottom-left
  - Y increases upward

So while exporting:
pdfY = logicalHeight - flutterY
is applied for every point.

## PDF Design Rules

- Logical canvas is always 1000 × 1000
- PDF page format must always be 1000 × 1000
- SVG must be wrapped in a 1000 × 1000 container
- Strokes must be drawn using logical coordinates only
- Never use A4 as the PDF page size for generation (only for printing if needed)


