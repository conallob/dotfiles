---
name: stl
description: |
  Design 3D printable objects as OpenSCAD source files, validated against the
  Snapmaker A350T printer constraints (320×350×330 mm build volume, 0.4 mm nozzle,
  dual extrusion). Use for: designing new parts, adapters, enclosures, functional
  brackets, and any physical object to be printed on the Snapmaker A350T.
user-invocable: true
---

# /stl — Design 3D Printable Objects for Snapmaker A350T

Design a 3D printable object based on the user's description. Output an OpenSCAD
`.scad` source file that respects the Snapmaker A350T's hardware constraints.

## Snapmaker A350T Constraints

| Property | Value |
|---|---|
| Build volume | 320 × 350 × 330 mm (X × Y × Z) |
| Nozzle diameter | 0.4 mm (default), 0.2 mm / 0.6 mm / 0.8 mm available |
| Layer height | 0.05 – 0.35 mm (optimal: 0.1 – 0.2 mm) |
| Extruder temp | up to 275 °C |
| Bed temp | up to 80 °C |
| Filament diameter | 1.75 mm |
| Dual extrusion | 2-in-1 Pro Module (two filaments, single nozzle) |
| Bed levelling | Automatic (11×11 grid) |

Common filaments: PLA (190–220 °C / bed 45–60 °C), PETG (230–250 °C / bed 70–80 °C),
TPU (220–240 °C / bed 30–45 °C, flexible), ABS (230–250 °C / bed 80 °C, requires enclosure).

## Design Process

### 1. Clarify requirements
Before designing, confirm:
- **Function**: what does the part do?
- **Fit**: does it mate with an existing object? (measure in mm)
- **Material**: rigidity, flexibility, heat resistance, aesthetics needed?
- **Quantity**: one-off or repeated print?

If requirements are ambiguous, ask rather than guess.

### 2. Orient and size for printing
- Keep the tallest dimension along Z only when unavoidable; wider/flatter parts are stronger and faster.
- Never exceed 320 × 350 × 330 mm. Add a `// Build volume check` assertion in the SCAD.
- Standard wall thickness: 1.2 mm (3× nozzle width) minimum, 2.4 mm for structural parts.
- Layer-adhesion is weakest along Z; orient so load paths run in X/Y.

### 3. FDM design rules
- **Overhangs**: design ≤ 45° without supports; call out any feature that needs supports.
- **Bridging**: up to ~60 mm bridging is usually reliable; flag longer spans.
- **Tolerances**: add 0.2 mm clearance on mating faces; 0.3 mm for sliding fits.
- **Holes**: design 0.2 mm oversized (printer shrinks them). For press-fit: exact size.
- **Minimum feature size**: 0.8 mm (2× nozzle); smaller features print poorly.
- **Avoid sharp internal corners**: fillet with r ≥ 0.4 mm to reduce stress concentration.

### 4. Write the OpenSCAD file
Use parametric values — put all tuneable dimensions as variables at the top. Structure:

```openscad
// === Parameters ===
wall   = 1.6;   // mm
// ...

// === Build volume assertion ===
assert(part_x <= 320, "Exceeds X build volume");
assert(part_y <= 350, "Exceeds Y build volume");
assert(part_z <= 330, "Exceeds Z build volume");

// === Modules ===
module body() { ... }

// === Main ===
body();
```

- Use `$fn = 64;` (or higher for cosmetic circles) at the top.
- Prefer `hull()`, `minkowski()`, and `offset()` for rounded shapes over raw spheres.
- Comment every non-obvious dimension with its purpose.

### 5. Validate the design
After writing the SCAD, mentally trace through:
- [ ] Fits in build volume?
- [ ] Worst overhang angle called out?
- [ ] Clearances applied to mating faces?
- [ ] Minimum wall ≥ 1.2 mm everywhere?
- [ ] All holes sized with +0.2 mm tolerance?

### 6. Provide slicing recommendations
Finish with a `## Slicer Settings` section in your response:
- Recommended material and temperatures
- Layer height suggestion
- Infill % and pattern (e.g. gyroid for functional parts)
- Support needed? (yes/no, and where)
- Print orientation note
- Estimated print time if obvious (rough guess only)

## Output Format

1. **Brief design rationale** (2–4 sentences): key decisions and trade-offs.
2. **OpenSCAD source** in a fenced `openscad` code block, saved to a `.scad` file in the current directory.
3. **Slicer Settings** as a compact markdown table or bullet list.
4. **Known limitations** — anything the design can't do or assumptions made.

Save the file as `<descriptive-name>.scad` in the current working directory using the Write tool.
