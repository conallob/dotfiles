---
name: stl
description: |
  Design objects for fabrication on the Snapmaker 2 A350T — a 3-in-1 machine with
  3D printing (dual extrusion, official enclosure), laser cutting/engraving (1.6 W
  and 10 W heads), and CNC carving. Also supports 4-axis work via the rotary module
  (assembled, not yet configured). Outputs OpenSCAD for 3D printing/CNC, SVG/DXF
  for laser work. Use for: functional parts, enclosures, brackets, laser-cut panels,
  engraved pieces, and CNC-carved stock.
user-invocable: true
---

# /stl — Design for the Snapmaker 2 A350T

Design an object for fabrication on the Snapmaker 2 A350T. The machine is a
**3-in-1** platform; the first step is always confirming which modality to use.

## Machine Overview

The A350T is equipped with:
- **Official enclosure** — enables ABS/ASA printing, required for laser safety
- **Quick Release toolhead set** — faster head swaps; adds a slight margin to usable build area beyond the base dimensions
- **Dual Extrusion 2-in-1 Pro Module** — two filaments through a single nozzle
- **1.6 W laser module** (original)
- **10 W laser module** (high-power upgrade, thicker material cutting)
- **CNC carving module**
- **Rotary module** — assembled; 4th-axis (A-axis) capability for laser and CNC; **not yet calibrated/configured**

---

## Modality Constraints

### 3D Printing

| Property | Value |
|---|---|
| Base build volume | 320 × 350 × 330 mm (X × Y × Z) |
| Build volume with Quick Release | slightly larger — verify with a test print at limits |
| Nozzle diameter | 0.4 mm default; 0.2 / 0.6 / 0.8 mm available |
| Layer height | 0.05 – 0.35 mm; optimal 0.1 – 0.2 mm |
| Extruder temp | up to 275 °C |
| Bed temp | up to 80 °C |
| Filament | 1.75 mm; dual filament (2-in-1 Pro Module) |
| Bed levelling | Automatic 11×11 grid |

**Filament guide:**
| Material | Nozzle °C | Bed °C | Notes |
|---|---|---|---|
| PLA | 190 – 220 | 45 – 60 | Easy, enclosure optional |
| PETG | 230 – 250 | 70 – 80 | Good strength, slight stringing |
| TPU | 220 – 240 | 30 – 45 | Flexible; slow print speed |
| ABS | 230 – 250 | 80 | **Enclosure required** |
| ASA | 240 – 260 | 80 – 100 | UV resistant; **enclosure required** |

**FDM design rules:**
- Wall thickness: 1.2 mm minimum (3× nozzle), 2.4 mm for structural parts
- Overhangs: ≤ 45° without supports; note any feature needing supports
- Bridging: reliable up to ~60 mm; flag longer spans
- Tolerances: +0.2 mm clearance on mating faces; +0.3 mm for sliding fits
- Holes: design 0.2 mm oversized (printer shrinks them); exact size for press-fits
- Minimum feature: 0.8 mm (2× nozzle); smaller will not resolve
- Internal corners: fillet r ≥ 0.4 mm to reduce stress
- Layer adhesion is weakest along Z; orient load paths in X/Y

**Dual extrusion use cases:** dissolvable supports (PVA + PLA), two-colour parts, rigid+flexible combinations. Note in design which bodies use which extruder.

---

### Laser Cutting / Engraving

| Property | 1.6 W Module | 10 W Module |
|---|---|---|
| Working area (flat) | 320 × 350 mm | 320 × 350 mm |
| Typical cut depth (wood) | ~3 mm ply | ~8 mm ply |
| Typical engrave materials | wood, leather, acrylic (light) | wood, leather, acrylic, anodised Al |
| Enclosure | Required for safe operation | Required for safe operation |

**Design rules:**
- Output format: **SVG** (preferred) or **DXF** for cut/engrave paths
- Minimum feature size: ~0.2 mm for engraving; ~0.5 mm for cut paths (kerf ~0.1 – 0.2 mm)
- Add 0.1 mm kerf compensation outward on cut profiles, inward on holes
- Score lines, engrave fills, and cut outlines should be on separate layers/colours
- Material must be flat and secured; warped sheet degrades focus and cut quality

---

### CNC Carving

| Property | Value |
|---|---|
| Working area (flat) | 320 × 350 mm |
| Z travel (approx.) | up to ~275 mm (less than 3D printing due to spindle length) |
| Typical materials | wood, MDF, PCB, soft plastics, wax |
| Enclosure | Recommended (dust containment) |

**Design rules:**
- Output format: **OpenSCAD** (for 3D toolpath geometry) or **DXF/SVG** (for 2.5D profiles)
- Account for tool radius in inside corners — a square internal pocket needs dog-bone fillets
- Minimum inside corner radius = end mill radius + 10% clearance
- Depth of cut per pass: 0.5 – 1.5 mm for wood; shallower for hard materials
- Always specify stock thickness and origin (top-of-stock vs. spoilboard)

---

### Rotary Module (4th Axis — not yet configured)

The rotary module adds an A-axis (rotation around X). **Do not generate production-ready rotary files until it is calibrated.** When it is set up:

| Property | Value |
|---|---|
| Modalities | Laser engraving + CNC (not 3D printing) |
| Workpiece diameter | up to ~80 mm |
| Workpiece length | up to ~400 mm |
| Output format | Luban-compatible toolpaths; rotary SVG for laser |

Flag any rotary design with a `# ROTARY — requires calibration before use` comment at the top of the output file.

---

## Design Process

### 1. Choose modality
Confirm which head will be used: **3D print**, **laser**, **CNC flat**, or **CNC/laser rotary**.
If unclear, ask. Each has different constraints, file formats, and fixturing requirements.

### 2. Clarify requirements
- **Function**: what does the part do / what is being cut or engraved?
- **Fit**: mating dimensions in mm?
- **Material**: which filament, sheet material, or stock?
- **Quantity**: one-off or batch?

Surface ambiguity before proceeding.

### 3. Design to constraints
Apply the relevant rules from the sections above. For 3D printing, orient the part
so the primary load path runs in X/Y, not Z.

### 4. Write the design file

**3D printing / CNC 3D** — OpenSCAD:
```openscad
// === Parameters ===
wall = 1.6;  // mm — 4× nozzle for structural parts

// === Build volume check (3D printing) ===
assert(part_x <= 320, "Exceeds X build volume");
assert(part_y <= 350, "Exceeds Y build volume");
assert(part_z <= 330, "Exceeds Z build volume");

$fn = 64;

// === Modules ===
module body() { ... }

// === Main ===
body();
```

**Laser / CNC 2.5D** — describe SVG/DXF layer structure in comments, then emit
the vector geometry. Separate layers: `engrave-fill`, `engrave-outline`, `score`, `cut`.

### 5. Validate
- [ ] Fits within working area / build volume?
- [ ] Worst overhang or unsupported span identified?
- [ ] Clearances and tolerances applied?
- [ ] Minimum feature size respected?
- [ ] Kerf compensation added (laser)?
- [ ] Dog-bone fillets on internal CNC corners?
- [ ] Rotary files flagged as uncalibrated if applicable?

### 6. Fabrication notes
End the response with a concise **Fabrication Settings** block:
- Modality and head
- Material + temps (3D) or feed/speed (CNC) or power/speed (laser)
- Layer height / pass depth
- Supports or fixturing needed
- Estimated time (rough)

---

## Output Format

1. **Design rationale** (2–4 sentences): key decisions and trade-offs.
2. **Design file** in a fenced code block (`openscad`, `svg`, or `dxf`), saved to disk with the Write tool as `<descriptive-name>.scad` / `.svg` / `.dxf`.
3. **Fabrication Settings** as a compact table or bullet list.
4. **Known limitations** — assumptions made, features not modelled, anything needing manual verification before fabrication.
