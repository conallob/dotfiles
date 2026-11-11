# Chrysalis_Keyboardio-Model-100_layout.json — schema notes

This file is a **Chrysalis** layout export for a Keyboardio Model 100
(Kaleidoscope firmware). It's imported/exported verbatim through the
Chrysalis app — do not hand-edit the JSON casually, and never add JSON
comments to it (JSON has none; Chrysalis will fail to parse the file).
This document is the annotation layer that lives *alongside* it.

The only customization from stock is: right-hand top-left "Any" key →
`code 18846` (`platform_apple` category, "Lock Screen").

## Top-level keys

| Key | Purpose |
|---|---|
| `keymaps` | Human-readable view of all 8 layers, one array of 64 key objects per layer. Rendered by Chrysalis's UI; kept in sync with `deviceConfiguration.keymap.custom` (the flat form the firmware actually consumes). |
| `colormaps` | Per-key LED color, one array of 64 palette *indices* per layer (parallels `keymaps` structurally). |
| `palette` | Flat array of `{r,g,b,rgb}` — the color table `colormaps` indexes into. |
| `deviceConfiguration` | Raw Focus-protocol settings pushed to the device (the ground truth for what actually gets flashed). |

There are **8 layers** (`#0`–`#7`, see `deviceConfiguration.layernames.names`).
Layers 0–2 are populated (base, numpad/Fn, and a media/mouse-keys layer);
**layers 3–7 are entirely `Transparent` (code `65535`) — unused key
real estate available for new layers/bindings.**

## `keymaps[layer][i]` key object

Each of the 64 entries (one per physical key position, row-major) is:

```jsonc
{
  "code": 30,                 // HID usage code, or a Kaleidoscope synthetic code (see below)
  "label": {
    "base": "1",               // string, or {"full": "...", "1u": "...", "short": "..."} for narrow keycaps
    "shifted": "!",             // optional: what Shift produces (display only)
    "hint": "LockTo"            // optional: small secondary label (e.g. layer/macro slot markers)
  },
  "location": "left",          // optional: disambiguates left/right twin keys (modifiers, numpad)
  "categories": ["modifier"],  // optional: tags Chrysalis uses for UI grouping/coloring
  "target": 1,                 // present on layer keys: the layer index this key acts on
  "rangeStart": 17408,         // present on layer/macro keys: base offset of the code's range
  "baseCode": 47               // present on synthetic "with-modifiers" keys: the underlying unmodified key
}
```

### `code` ranges (Kaleidoscope key space)

| Range | Meaning | Example in this file |
|---|---|---|
| `4`–`231` | Standard HID keyboard usage codes (letters, digits, punctuation, standard modifiers) | `30` = `1`, `224` = left Ctrl |
| `65535` | `Key_Transparent` — falls through to the layer below | all `"blanks"` entries |
| `2048`–~`2100` | Kaleidoscope "key with modifier" synthetic codes — `code` is the synthesized symbol, `baseCode` is the physical key, `categories: ["with-modifiers", "shift"]` | `2095`/`2096`/`2097` = `{`/`}`/\| (Shift+`[`/`]`/`\`) |
| `17152`–~`17400` | LED-effect control keys (`categories: ["ledkeys"]`) | `17152` = cycle to next LED effect |
| `17408`–`17449` | `LockLayer(n)` — toggles a layer on permanently (`categories: ["layer","locktolayer"]`); `target` = layer index, `rangeStart` = base of this range | `17409` = `LockLayer(1)` |
| `17450`–~`17490` | `ShiftToLayer(n)` — momentary layer shift while held (`categories: ["layer","shifttolayer"]`) | `17452` = `ShiftToLayer(2)` |
| `18613`–~`18670` | Consumer-page controls: media transport, volume, mute (`categories: ["consumer"]`) | `18658` = Mute |
| `18846` | Apple-platform special key (`categories: ["platform_apple"]`) — **this is the customized "Any" key → macOS Lock Screen** | top-left key, right half |
| `20481`–`20548` | Mouse keys: cursor movement, warp-to-quadrant, button clicks (`categories: ["mousekeys"]`) | `20481` = mouse up, `20545` = left click |
| `24576`+ | `Macro(n)` — fires user-programmed macro slot n (`categories: ["macros"]`); `rangeStart` = base of the macro range | `24576` = `Macro(0)` — **placed on layer 1 but currently unprogrammed** (see below) |

## `deviceConfiguration` — the fields that matter for editing

| Field | Format | Notes |
|---|---|---|
| `keymap.custom` | Space-separated `code` list, all 8 layers concatenated (64 × 8 = 512 values) | **This is what actually gets flashed.** Must be regenerated/kept in lock-step with `keymaps` if either is edited by hand. |
| `keymap.onlyCustom` | `true` | Firmware uses only `keymap.custom`, ignoring any built-in default layer. |
| `macros.map` | Space-separated byte stream, `255` = unset | Binary encoding of macro step sequences (key down/up/interval actions) for each `Macro(n)` slot. Currently **all `255`** — no macros are programmed, even though `Macro(0)` is already wired to a key on layer 1. |
| `colormap.map` | Space-separated palette-index list, mirrors `colormaps` | LED colors actually flashed. |
| `palette` | Space-separated `r g b` triples, flat | Backing color table for `colormap.map`/`palette` array above. |
| `layernames.names` | Array of 8 strings | Currently just `#0`–`#7`; can be renamed for clarity in Chrysalis's UI. |
| `oneshot.*`, `spacecadet.*`, `escape_oneshot.*`, `mousekeys.*`, `idleleds.*`, `led*` | Plugin tuning knobs | Timeouts/behavior for OneShot modifiers, SpaceCadet (shift-parens), mouse key speed/accel, idle LED dimming. Not layout data. |
| `version`, `plugins`, `eeprom.*`, `settings.*`, `help` | Firmware/device metadata | Read-only info reported by the device; not meant to be hand-edited. |

## Practical constraint for adding new functionality

A `Macro(n)` key can only replay a **fixed sequence of HID keystrokes**
(key down/up + delays) — it cannot run AppleScript, hit a URL scheme, or
otherwise talk to an application directly. Anything beyond "type these
keys" has to be done by pairing a macro (or a plain key combo) with a
host-side listener (macOS Shortcuts/Keyboard Maestro/Automator) that
reacts to that keystroke and performs the actual application logic.

## OmniFocus quick-reschedule layer (layer 3 / `#3` → renamed `OmniFocus`)

Implemented using that pattern:

- **Activator**: `layer0[6]` (physical key previously bound to `LEDEffect
  Next`, code `17152` — a cosmetic, rarely-used key) is now
  `ShiftToLayer(3)` (`code 17453`). Hold it to momentarily shift into the
  OmniFocus layer; release to fall back to whatever layer was active.
- **Actions**: on layer 3, the `1`/`2`/`3` key positions (`layer3[1..3]`)
  are bound to the standalone HID keys `F13`/`F14`/`F15` (codes
  `104`/`105`/`106`) — real, unused-by-macOS keys, not macros. Everything
  else on layer 3 stays `Transparent`, so all other keys behave exactly
  as they do on the base layer while the activator is held.
- **Host side**: `dot_config/skhd/skhdrc` binds `f13`/`f14`/`f15` to
  `osascript` calls against the three scripts in
  `dot_config/omnifocus-shortcuts/`, which set the `due date` of the
  selected OmniFocus item(s) to today / tomorrow / the next working day
  (Mon–Fri), preserving the existing time-of-day. Requires `brew install
  skhd` (added to `Brewfile`) and macOS Accessibility permission for
  `skhd`; start it with `brew services start skhd`.

To revert: restore `layer0[6]` to the `LEDEffect Next` binding and the
`layer3[1..3]` entries to `Transparent` (git history has the exact prior
values), then remove/disable the skhd config.
