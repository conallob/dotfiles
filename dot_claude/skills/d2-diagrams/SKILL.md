---
name: d2-diagrams
description: |
  Author, generate, and maintain diagrams in D2 (d2lang.com): architecture
  diagrams, flowcharts, org charts, data-pipeline diagrams. Covers generating
  diagrams from source data (parse → model → render), shape and style
  conventions, splitting a map from detail diagrams with `link`, fixing
  unreadable or over-wide layouts with `grid-columns`, the dagre spacing CLI
  flags, CI drift/render checks, and a verification checklist. Use when asked to
  create, update, or review a `.d2` file or D2 diagram, an "architecture
  diagram" where D2 is named or already used in the repo, or to debug a D2
  diagram that is unreadable, too big to export, or won't link correctly.
user-invocable: true
---

# /d2-diagrams — Author and Maintain D2 Diagrams

## Quick Reference

| Want | Use |
|---|---|
| Spread out a grid container's own cells | `grid-gap` / `horizontal-gap` / `vertical-gap` (D2 source) |
| Spread out everything else (containers, edges) | `--pad`, `--dagre-nodesep`, `--dagre-edgesep` (`d2` CLI flags) |
| Avoid one container's children in a single huge row/column | `grid-columns` / `grid-rows` (D2 source) once child count crosses ~4–5 |
| Link one diagram's node to another diagram | `link: "./other.svg"` on the node — SVG only, not PNG |
| Highlight a non-standard/transitional edge | `style.stroke-dash` + `style.stroke` |
| List an engine's own layout flags | `d2 layout <engine-name>` |
| Change theme/pad/layout-engine/center from D2 source | `vars.d2-config { ... }` block (NOT node/edge spacing — that's CLI-only) |

## Core Principle

Prefer generating diagrams from real source data (config files, API responses,
code) over hand-drawing them, whenever a reliable source exists. A generated
diagram can't drift from the thing it describes; a hand-drawn one always
eventually does. D2 suits this because it is plain text — diffable in review —
and a renderer is just "data structure in, text out", so adding fields later
doesn't mean redrawing anything.

## Architecture for Anything Non-Trivial

Use three layers, even for a single-shot generator:

1. **Parse** — read the raw source(s) into typed, raw findings. Independent of
   what the diagram will look like.
2. **Model** — a diagram-agnostic typed graph:
   `Node{ID, Type, Label, Container, Metadata, SourceRef}` and
   `Edge{From, To, Type, Relationship, Metadata}`.
   - `Container` is the parent node's ID, for nesting.
   - `SourceRef` (file+line) points back at what produced a node — useful for
     warnings and cross-referencing.
   - `Relationship` (e.g. steady-state vs. stop-gap/provisional) lets the
     renderer style an edge without knowing *why* it is provisional.
3. **Render** — graph → D2 text. Deterministic (sort nodes/edges by ID) so
   unrelated regenerations diff cleanly and a CI check isn't flaky.

Separation means a new diagram type is "write a new parser, reuse the model and
renderer". For a true one-off you can collapse the layers, but still keep
rendering logic separate from data-gathering.

## Shape and Style Conventions

Pick one meaning per D2 shape and hold it for the whole diagram (ideally across
all diagrams in a project):

- `rectangle` — a concrete thing (a cluster, a service, a box in a flow).
- `cloud` — a grouping/container that isn't itself a concrete thing (a
  provider's clusters, a category of apps).
- `hexagon` / other distinct shapes — reserve for one specific kind of "special"
  node that should visually pop (an instance, an entry point).
- `diamond` — a leaf item inside a grouping (an app, a decision).

A consistent vocabulary makes a diagram scannable without a legend.

Put secondary detail in `tooltip` (a single `"key=val; key2=val2"` string), not
extra nodes/edges — the graph stays clean and the detail stays available on
hover. Style a provisional/non-standard edge with `style.stroke-dash` plus a
distinct `style.stroke` color, not a label alone, so it reads as different at a
glance.

## Readability: Split Before It Gets Unreadable

A diagram serving two audiences — "the whole map" and "the fine detail of one
part" — should be two diagrams. Signs you've crossed the line: dozens-plus nodes
with deep per-node tooltips in one view, or a diagram so wide/tall it is
unreadable zoomed out and unnavigable zoomed in.

Split into one high-level "map" diagram and one or more "detail" diagrams, and
connect them with `link` on a node:

```d2
app-clouds: "Provider Clusters" {
  shape: cloud
  link: "./provider-internals.svg"
}
```

**`link` only survives as a clickable `<a>` in compiled SVG, not PNG.** Treat
SVG as the primary human-facing artifact; PNG is a best-effort preview (D2
appends a numbered tooltip/link appendix below a PNG export instead, since PNG
can't be interactive).

## The 32768px PNG Limit, and Grid Layout as the Fix

The default `dagre` layout puts every child of a container in a single row (or
column). Past roughly a dozen children the result can exceed D2's PNG exporter's
hard 32768px-per-dimension limit. SVG has no such limit, but a long strip is
unreadable either way.

Fix: on any container whose child count crosses a threshold (~4–5), emit
`grid-columns` so D2 lays it out as a roughly square grid:

```d2
cluster: "Clusters" {
  shape: cloud
  grid-columns: 6          # ceil(sqrt(n * 1.3)) is a reasonable formula
  grid-gap: 100            # default is 60 (CONTAINER_PADDING); widen it
  ...
}
```

In a generator, compute this in the renderer from the child count; don't set it
by hand per diagram.

## Spacing: Two Different Knobs

- **Inside a grid container**: `grid-gap` / `horizontal-gap` / `vertical-gap`
  are D2 *source* properties — they travel with the `.d2` file and apply at
  every compile.
- **Everywhere else** (gaps between top-level containers and along connecting
  edges in the dagre-laid-out graph): these are **`d2` CLI flags, not source
  properties** — `--pad` (outer margin, default 100), `--dagre-nodesep`
  (default 60), `--dagre-edgesep` (default 20). Discover engine-specific flags
  with `d2 layout dagre` (or the engine in use) and `d2 --help`.

Because these are invocation-time flags, **every place that compiles the file
must pass the same flags**: a README's documented manual command, a CI "does the
compiled SVG match" check, and a CI "render a preview" step. A byte-diff of
compiled output reads a flag mismatch between call sites as false drift. Keep
the flag string in one place (an env var, a Makefile variable) and reference it
everywhere.

## Surface Data Problems in the Diagram Itself

If the source data is internally inconsistent (two inputs disagree, a reference
doesn't resolve), render it as a `#` comment block at the top of the generated
`.d2` file, not just a log line elsewhere. The diagram becomes its own audit
trail, and reviewers see the problem in the diff.

## If the Diagram Is Generated in CI: Three Complementary Checks

1. **Drift check** — regenerate from live source, diff against the checked-in
   `.d2`. Catches "data changed, nobody regenerated."
2. **Render check** — recompile the checked-in `.d2` to SVG, diff against the
   checked-in `.svg`. Catches "someone hand-edited the `.d2`, or the renderer,
   CLI version, or flags changed, without recompiling." Independent of #1; needs
   only the `d2` CLI, not the generator.
3. **Generate-on-demand** — run both; only if either finds drift, upload the
   freshly regenerated file as a downloadable CI artifact. A clean PR costs no
   extra CI time; a stale one comes with a ready-to-commit fix instead of just a
   red X.

Keep all three advisory (non-blocking) at first, with a written-down, explicit
trigger for when to flip to blocking — not a vague "we'll revisit this later".
Any optional enrichment source (e.g. a second repo/API consulted only to improve
the diagram) must degrade gracefully — skip cleanly and say so — rather than
fail the pipeline, and the docs should state plainly what needs to exist for the
checked-in file to be exactly reproducible.

## Deriving a Grouping/Category with No First-Class Field

When you need to group/color/classify nodes by something the source doesn't
label explicitly:

1. Look for an authoritative secondary source before resorting to a naming
   heuristic (e.g. another system's config that already encodes the real
   answer).
2. If two sources use different identifiers for the same thing, join on a
   stable, structural key (an endpoint, an ID), not fuzzy name matching —
   naming conventions diverge, identifiers usually don't.
3. Always have a fallback for items the preferred source doesn't cover, and
   leave genuinely unmatched items ungrouped rather than guess.
4. Label provenance on the node itself (tooltip note: "grouped by X") and in the
   docs. Never present a heuristic as a stated fact.

## Testing

Unit test parse→model and model→render separately, against small hand-written
fixtures (a few lines of source data, not real production data). Assert on
specific node/edge/metadata values, not byte-identical "golden" rendered output,
which is brittle against unrelated renderer changes. A build/vet/lint pass plus
these assertions is enough; pixel-level SVG comparison tests aren't needed.

## Verification Checklist Before Calling a Diagram Done

- [ ] Actually compile it (`d2 file.d2 file.svg`, with the project's standard
      flags) — don't eyeball D2 source and assume it's right.
- [ ] Check the compiled SVG's `viewBox`. If it's enormous, look for a container
      that needs `grid-columns`, or layout flags that need widening.
- [ ] If there are `link` properties, grep the compiled SVG for `xlink:href` to
      confirm they resolved. Compile the PNG too if one is wanted, to confirm it
      isn't silently over D2's raster limit.
- [ ] Render a PNG (or view the SVG) and actually look at it before telling the
      user it's done. "Compiles without error" is not "readable".
