---
name: monitoring-dashboards
description: |
  Design, build, and review effective monitoring dashboards ("consoles") in Grafana
  or similar tools. Covers design principles (one theme per console, visibility in
  proportion to importance, graphs over raw data, graceful degradation), layout
  (one wide graph per row, text column on the right), drilldown variables, power-user
  variables such as num_items, and tooltips for new hires. Use when creating,
  restructuring, or critiquing a dashboard, or generating Grafana dashboard JSON/
  Jsonnet/Terraform.
user-invocable: true
---

# /monitoring-dashboards — Build Dashboards People Can Actually Use

Apply these rules when creating or reviewing a dashboard. When reviewing, report
each violated rule with the panel or row it applies to and a concrete fix.

These rules come with reasons. Follow them, but not blindly: if the reason
doesn't apply in a particular case, prefer the best behavior over slavish
attention to the rules. If a deviation seems warranted, ask for a human
judgement call instead of deciding alone, and record the outcome and why in the
panel description or the review.

Terminology: "console" and "dashboard" are interchangeable. In Grafana, a
"drilldown control" is a dashboard **variable**.

## Rationale

Every dashboard balances two audiences. System experts want the data they need
as quickly and cleanly as possible. Everyone else is not familiar with every
aspect of the system and needs some way to work out what is going on. A common
style relieves that tension: experts and casual viewers alike know where to look,
and a well-defined style can improve the expert view without taking affordances
away from newcomers. That doesn't mean every dashboard is identical; different
data is best explored in different ways.

## Before You Start

Answer these first; if the user hasn't said, ask:

1. **What is the one theme?** (e.g. "Frontend request health", "Database
   replication", "Batch pipeline freshness"). If the answer is a list joined by
   "and", it is several dashboards.
2. **Who is the audience?** A new hire with no context must be able to use it as
   easily as an experienced engineer.
3. **What question does it answer?** (Is it broken? Where is it broken? Why?)

## Design Principles

### 1. One Theme Per Console

"All the things" is not a valid theme. A console covers one service, one
subsystem, or one user journey. If it needs a second theme, split it and link the
two with dashboard links that carry the time range and variables across.

Mandate a theme, not a number of graphs. A fixed "N graphs per page" limit works
only because it forces prioritisation, which pushes the author back to the
theme; the theme is the rule. Every added panel and query still slows rendering,
so each graph has to earn its place.

### 2. Visibility in Proportion with Importance

The most important signals are the most prominent: top of the page, largest, and
first in reading order. Typically that means user-facing symptoms (error ratio,
latency, saturation, freshness) above causes (CPU, queue depth, GC), and causes
above diagnostics. Don't give a debug counter the same real estate as the SLI.

### 3. Graphs Over Raw Data

Humans (SREs especially) are pattern-matching machines. Prefer time series,
heatmaps, and histograms to tables and single numbers. A number without history
can't show a trend, a cliff, a periodic spike, or a before/after.

- Latency distributions: heatmap of the histogram buckets, or p50/p90/p99 lines,
  never only an average.
- Use a stat panel only for a value that is meaningful without history (e.g. SLO
  budget remaining), and give it a sparkline.
- Distribution data (e.g. version counts, requests by status class) is best as a
  stacked graph with stacked fill: almost a histogram over time, showing both
  the total and how the mix shifts.
- Avoid Grafana gauges. They show no history, so they are raw data that takes
  up a large amount of dashboard real estate. Use a time series with a threshold
  line instead.
- Tables belong in the text column (see Layout) or behind a drilldown.

### 4. One Theme Per Graph

Each graph answers one question. Don't plot unrelated series together because
they share a unit.

- Keep series on one panel on one axis, in one unit, with comparable magnitude.
- One grouping per graph. A graph with a lot of lines usually conflates two
  groupings, such as errors by both location and error code. Make two graphs, one
  by location and one by error code, and use drilldown for further refinement.
- No dual-axis graphs. If two series need different axes, they are two graphs.
- Cap series count to what's readable (roughly <= 10 lines). Use `topk` with the
  `num_items` variable and aggregate the rest into "other".
- Exception: many lines are appropriate when the point is spotting outliers, where
  a few lines standing out from many is the signal. There is still only one
  grouping.
- Put thresholds (SLO, capacity limit) on the graph as a constant
  line or threshold region so the reader sees "bad" without knowing the number.

### 5. Consistent Layout

Same thing in the same place, on every console, so muscle memory transfers.

- Same order of rows across consoles (e.g. Traffic -> Errors -> Latency ->
  Saturation -> Dependencies).
- Same colors for the same meaning everywhere: green/red reserved for good/bad,
  one fixed color per well-known series (e.g. 5xx always red).
- Same units, same time-axis alignment, same naming convention for panels.
- Define dashboards as code, never hand-clicked panels, so consistency is
  enforced by the source.

**Ideal: layout is templates plus CSS.** Preferably the layout (row order, the
right-hand text column, one full-width graph per row, spacing, colors, typography) is
controlled by Jinja2 templates and CSS, with panels as reusable template
macros/includes and the stylesheet as the single place that decides how things
look. A layout change is then one edit in one place.

**Reality: bludgeon the JSON.** Grafana has no native Jinja2 or CSS layout
engine. Layout is positional JSON (`gridPos` with `x`/`y`/`w`/`h` on a 24-column
grid), and styling is per-panel options. In an imperfect world, get as close to
the ideal as the tooling allows:

- Render Jinja2 (or Jsonnet/Grafonnet, grafanalib, Terraform) to dashboard JSON
  in CI, and load it via file provisioning or the HTTP API. Never commit the
  rendered JSON as the thing people edit.
- Compute `gridPos` in the template, not by hand. For one wide graph per row,
  every graph is `w: 24` (or the full width beside the text column) and `y`
  accumulates by the previous panel's `h`.
- Put the shared look (colors, units, thresholds, legend and tooltip options)
  in one template macro/defaults block applied to every panel, as the stand-in
  for a stylesheet.
- Where Grafana can't express something, fall back to a text/HTML panel with
  inline CSS, and keep that snippet in one shared include.
- Grafana's `{{label}}` legend syntax collides with Jinja2's default
  delimiters, so wrap those in `{% raw %}...{% endraw %}` or configure custom
  delimiters (e.g. `variable_start_string="[["`).

### 6. Graceful Degradation

The dashboard must remain useful when the system is on fire or the data is
missing.

- A dead or slow backend must not blank the page. Make panels independent; avoid
  queries that fail entirely when one label value is absent.
- Distinguish "zero" from "no data". Set "no value" text explicitly and, where it
  matters, graph `absent()`/`up` so missing data is visible as a problem.
- Cheap queries first: prefer recording rules over raw `rate()` across huge
  cardinality, so the dashboard still loads during an incident when everyone has
  it open.
- Row-collapse expensive or diagnostic sections by default.
- Handle label-set changes (new/removed pods, regions) without editing the
  dashboard: use regex/`=~` on variables rather than hard-coded label values.
- Dynamic features must fail soft. If a variable query errors, a data link
  breaks, a plugin is missing, or an HTML/CSS text panel is stripped by
  sanitisation, the page must still render a usable display, even an ungainly
  one. Give variables a static fallback (e.g. a constant or custom option) and
  never put the only copy of a signal behind a dynamic feature. Ugly data is
  far preferred to no data.

## Layout and UX

### One Wide Graph Per Row

Lay graphs out **one per row, full width**, stacked vertically. The point is
vertical correlation: with every graph sharing the same x-axis, the eye drops
straight down from a spike in error rate to the latency, saturation, and
dependency graphs at the same instant.

- Do not tile graphs side by side in a grid.
- Share the crosshair/tooltip across panels (Grafana: Dashboard settings ->
  Graph tooltip -> *Shared crosshair* or *Shared tooltip*).
- Same x-axis range on every panel; no per-panel time overrides.

### Text Column on the Right

Auxiliary text-based data (current values, version/build info, top-N tables,
links to runbooks, owners) goes in a **single vertical column on
the right-hand side**, plumbed into the same time controls as the graphs, so the
text reflects the selected time range rather than "now".

- Narrow fixed width; graphs take the rest.
- Query the same variables as the graphs. Anything in the column that ignores the
  time range or variables is a bug.
- Order the column by importance, like the graphs.
- Don't display alerts (firing state, alert lists) on the dashboard. Alerts link
  *to* dashboards, not the other way around.

### Drilldown Controls (Dashboard Variables)

Every console has drilldown variables, each defaulting to **All**, so that it
works with zero configuration and narrows on demand.

- Typical drilldowns: `cluster`, `namespace`, `service`, `region`, `instance`.
- Chain them so each narrows the next (`namespace` options depend on `cluster`).
- Enable multi-select with "Include All"; use `=~"$var"` in queries so All works.
- Clicking a series or table row should set the matching variable where the
  tool supports data links.
- Variables must be in the URL so a filtered view can be shared in an incident.

### Power-User Variables

Add extra controls for advanced users with **sensible defaults**, hidden from the
main control bar if they clutter it but always settable through URL GET
arguments (`...&var-num_items=20&...` in Grafana; the URL parameter is
`var-<name>`).

| Variable | Default | Purpose |
|----------|---------|---------|
| `num_items` | `10` | N for `topk(N, ...)` panels |
| `rate_interval` | `5m` | window for `rate()`/`increase()`; or prefer `$__rate_interval` |
| `quantile` | `0.99` | which latency quantile to plot |
| `min_threshold` | `0` | hide series below a value |

Example:

```promql
topk($num_items, sum by (service) (rate(http_requests_total{cluster=~"$cluster", namespace=~"$namespace"}[$__rate_interval])))
```

A novice never needs to touch these; an experienced engineer can change them in
the URL during an incident without editing the dashboard.

### Audience: New Hire to Veteran

Assume zero context. Make the dashboard self-explanatory.

- **Tooltips / panel descriptions on every graph** explaining, in a sentence or
  two, how to read it: what the axes are, what "bad" looks like, what the
  threshold line means, and what to look at next. Example: *"Fraction of requests
  returning 5xx. Healthy is under 0.1%. The red line is the SLO. If it is above
  the line, check Latency below, then the Dependencies row."*
- Title panels with what they show in plain words, with the unit
  ("Request error ratio (%)"), not metric names.
- Put a short text panel at the top: purpose, owner, runbook link, and the
  escalation path.
- Link to the runbook where one exists. Alerts should link to this dashboard;
  the dashboard doesn't show or link back to alerts.
- Avoid jargon or abbreviations unless defined in the tooltip.

## Checklist

Use when reviewing or before declaring done.

- [ ] One theme; title states it
- [ ] Most important signal is top and most prominent
- [ ] Graphs, not raw numbers or tables, for anything with a time dimension
- [ ] One theme, one unit, one axis per graph; thresholds drawn
- [ ] One wide graph per row; shared crosshair; same x-axis everywhere
- [ ] Text column on the right, wired to time range and variables
- [ ] Drilldown variables default to All, chained, in the URL
- [ ] Power-user variables (`num_items` etc.) with sensible defaults
- [ ] No alerts displayed; alerts link to the dashboard instead
- [ ] Every panel has a tooltip/description on how to read it
- [ ] Layout, colors, units match other consoles
- [ ] Still useful with missing data / dead backend; "no data" is explicit
- [ ] Defined as code (Jsonnet/Jinja2/Terraform/JSON in git), not hand-edited

## Related Skills

- `promql-fmt` — format and lint the PromQL inside panel queries
- `label-check` — verify queries carry required labels
- `autogen-promql-tests` / `alert-hysteresis` — for the alerts that link to this
  dashboard; keep them separate from the dashboard itself
