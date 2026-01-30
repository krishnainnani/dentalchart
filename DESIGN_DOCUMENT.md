# Dental App — Design Document

## Purpose of this Document

This document defines the **visual and interaction design** for the Dental Charting App, based on the approved PRD and selected Behance inspiration.

**Scope**
- UI / UX only
- No functional changes
- Existing canvas + PDF logic must remain untouched

This document is written to be directly consumable by **Cursor / Claude** during implementation.

---

## 1. Design Philosophy

### Core Principles
- Calm and clinical
- Zero visual noise
- Dentist-first usability
- High contrast where needed, otherwise restrained

> If something distracts from the teeth chart, it is wrong.

---

## 2. Typography

### Font Family
**Poppins** (single font across app + PDF)

### Font Weights
- Regular — body text
- Medium — labels
- Semibold — section headers
- Bold — primary titles

### Usage Rules
- No decorative fonts
- No italics for critical information
- Consistent font sizes across screens

---

## 3. Color System

### Base Colors
- Background: #FFFFFF
- Primary UI Accent: #3164DE
- Secondary UI Accent: #B1C5F6
- Light Background Panels: #D6E0F8
- Text Primary: #393C4D
- Text Secondary: #8592AD

### Semantic Colors
- Success: #19A14E
- Error / Warning: #EF6161

### Critical Rule
- **Red is reserved for canvas markings**
- UI must never visually compete with clinical drawings

---

## 4. Layout System

### Global Layout Rules
- No sidebar navigation
- No dashboards
- No analytics cards
- Journey-based screen flow only

### Spacing
- Page padding: 24px
- Card padding: 16–20px
- Section gap: 24px

### Corners & Elevation
- Border radius: 10px
- Subtle shadow only where separation is required

---

## 5. Screen 1 — Patient Intake

### Goal
Collect patient information quickly and calmly.

### Layout Structure
```
--------------------------------
 Patient Registration
--------------------------------
 [Name]
 [Age] [Sex]
 [DOB]
 [Mobile]

 Medical Information
 [ + Add Medication ]
 [ + Add Allergy ]
 [ + Add Treatment ]

 Habits (chips)
 Pregnancy / Feeding (radio)

 [ Continue ]
--------------------------------
```

### Design Rules
- Single-column layout
- Labels above inputs
- Multi-entry fields use "Add +" pattern
- No dense grouping

---

## 6. Screen 2 — Clinical Workspace (Primary Screen)

### Goal
Allow charting and note-taking without distraction.

### High-Level Layout
```
------------------------------------------------------
 Patient Summary Card (read-only)
------------------------------------------------------
 |                                                |
 |  Teeth Chart Canvas (fixed square)               |
 |                                                |
 |----------------------------------------------- |
 |  Clinical Notes Panel                           |
 |  - Handwritten OR structured notes              |
------------------------------------------------------
 Bottom Toolbar
 Undo | Clear | Pen | Color | PDF
------------------------------------------------------
```

### Patient Summary Card
- Compact
- Shows: Name, Age, Sex, Mobile
- Alerts for allergies / pregnancy

### Teeth Chart Canvas
- Existing implementation
- Must remain visually dominant
- No resizing or re-scaling

### Clinical Notes Panel
Two allowed implementations:

**Option A — Notes Canvas**
- Separate drawing canvas
- Pen color + thickness
- Stored as vector strokes

**Option B — Structured Notes**
- Sections: Diagnosis, Findings, Plan
- Optional handwriting overlay

Notes must always render cleanly in PDF.

---

## 7. Screen 3 — PDF Output (Visual Style)

### PDF Visual Rules
- Same typography as app
- Mostly black + grey text
- Minimal blue for headers
- Clean section separation

### PDF Sections Order
1. Header
2. Patient Details
3. Medical History
4. Teeth Chart
5. Clinical Notes
6. Footer

PDF must visually resemble a printed medical report, not an app screen.

---

## 8. Components & Controls

### Buttons
- Primary: Solid blue (#3164DE)
- Secondary: Outline / soft blue
- Destructive: Red (only when required)

### Icons
- Simple line icons
- No filled or decorative icons
- Icons always secondary to text

---

## 9. Accessibility & Usability

- Minimum tap target: 44px
- Clear visual hierarchy
- No hidden critical actions
- All actions reachable within 1–2 taps

---

## 10. Implementation Rules (For Cursor)

- Do not modify canvas logic
- Do not modify PDF mapping logic
- UI must wrap around existing functionality
- Follow spacing, typography, and color rules strictly

---

## 11. Design Success Criteria

- Dentist understands screen in <5 seconds
- No visual competition with chart
- PDF looks professional without adjustments
- App feels calm and predictable

---

## Status
Design approved for implementation.
