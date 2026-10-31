---
name: alert-history-audit
description: |
  Historical alerting analysis. Mine an archive of alert firing events (BigQuery)
  plus the alert rules repos to find noisy, flappy, stale, or auto-silenced alerts,
  quantify what a `for:` / `keep_firing_for` change or a silence-manager would have
  prevented, and produce a per-alert recommendation sheet. Complements the
  o11y-analysis-tools CLIs (alert-hysteresis, stale-alerts-analyzer, promql-fmt,
  label-check, autogen-promql-tests, e2e-alertmanager-test). Use for alert-quality
  reviews, on-call load reduction, before/after evaluation of an alerting change, or
  when deciding whether to delete or retune alerts.
user-invocable: true
---

# /alert-history-audit — Learn From What Alerts Actually Did

Answer "which alerts are worth keeping, retuning, silencing or deleting?" from
evidence, and "what would change X have saved us?" by replaying history.

This skill is the method. The per-tool flags live in the o11y-analysis-tools
skills (`alert-hysteresis`, `stale-alerts-analyzer`, ...); load `promql-cody`
first if available, since it decides which tool and mode (interactive vs. CI) to use.
The history gives the quantitative evidence; the `review-alerts` skill (from the
`sre-alerting-guidelines` plugin, https://github.com/conallob/SRE-Alerting-Guidelines)
gives the qualitative judgement of whether each alert is well designed.

The SQL below is a template adapted from queries that worked in a real analysis,
but each snippet is **untested in placeholder form**. Substitute the placeholders,
dry-run (`bq query --dry_run`) and sanity-check row counts before trusting output.

## 0. Placeholders

Define these once at the start and restate them to the user:

| Placeholder | Meaning |
|---|---|
| `{{events}}` | Fully qualified alert-event archive table, one row per firing |
| `{{params}}` | Per-alert what-if settings table (see 3c) |
| `{{rules_repos}}` | Repos holding Prometheus/Alertmanager rule files |
| `{{rules_paths}}` | Paths within those repos to rule files |
| `{{change_date}}` | Date a change under evaluation took effect (before/after studies) |
| `{{baseline_start}}`, `{{baseline_end}}` | Analysis window (half-open: start inclusive, end exclusive) |
| `{{baseline_start_minus_context}}` | `baseline_start` minus 3–4 weeks, so the previous fire is known |

Expected columns of `{{events}}` (map your schema onto these; add a view if needed):

| Column | Type | Notes |
|---|---|---|
| `alert_name` | STRING | Rule name |
| `fired_at` | TIMESTAMP | Start of the firing (already past any existing `for:`) |
| `resolved_at` | TIMESTAMP | NULL if still firing |
| `severity` | STRING | Optional, used for slicing |
| `labels` | JSON/STRING | Optional, used for slicing by team/service |

Fire duration is measured *after* the existing `for:` has elapsed. Raising `for:`
from `old` to `new` suppresses a fire only if its observed duration is
shorter than `new - old`, not shorter than `new`.

## 1. Scope the question

Confirm with the user before querying (these change the answer):

- Window length and whether a change date splits it into before/after.
- Which alerts: all, one team's, or one severity.
- Goal: cut noise, find dead alerts, or evaluate a specific change.
- That alerts will also be judged against the SRE Alerting Guidelines (section 5).
  If the `review-alerts` skill is not installed, install the `sre-alerting-guidelines`
  plugin from `conallob/SRE-Alerting-Guidelines`; if that is not possible, say the
  qualitative pass was skipped rather than improvising guidelines.

## 2. Inventory the rules

Build the list of alerts that *should* exist, so alerts that never fired show up
as zeros rather than missing rows.

1. Fetch rule files from `{{rules_repos}}` at `{{rules_paths}}` (clone read-only).
2. Extract per alert: name, expr, `for`, `keep_firing_for`, severity, owning team,
   runbook. A small script using a YAML parser is enough; walk
   `groups[].rules[]` where `alert` is set. Expand templated/Jsonnet rules first.
3. Run the hermetic checks while you are here (they are cheap and CI-safe):
   - `promql-fmt --check <paths>`: layout/naming problems.
   - `label-check --labels=<required> <paths>`: missing routing/ownership labels,
     which are often the root cause of "nobody owns this noisy alert".
4. Note alerts that exist in the archive but not in the rules (renamed or deleted)
   and the reverse. Do not silently drop either set.

## 3. BigQuery analysis

### 3a. Archive coverage (always run first)

Never interpret zeros without knowing the archive actually covered the period.

```sql
SELECT
  DATE(fired_at) AS day,
  COUNT(*) AS fires,
  COUNT(DISTINCT alert_name) AS distinct_alerts
FROM `{{events}}`
WHERE fired_at >= TIMESTAMP('{{baseline_start_minus_context}}')
  AND fired_at <  TIMESTAMP('{{baseline_end}}')
GROUP BY day
ORDER BY day;
```

Look for missing days, sudden volume steps (ingestion changes), and the first/last day.
Trim the window to the contiguous covered range.

### 3b. Per-alert metrics, optionally split before/after

```sql
WITH fires AS (
  SELECT
    alert_name,
    fired_at,
    TIMESTAMP_DIFF(
      COALESCE(resolved_at, TIMESTAMP('{{baseline_end}}')), fired_at, SECOND) AS dur_s,
    -- Optional split for before/after studies. Use EQUAL-LENGTH windows, e.g.
    -- 14 days before {{change_date}} vs. everything after it.
    IF(fired_at < TIMESTAMP('{{change_date}}'), 'before', 'after') AS period
  FROM `{{events}}`
  WHERE fired_at >= TIMESTAMP('{{baseline_start}}')
    AND fired_at <  TIMESTAMP('{{baseline_end}}')
    -- AND per-period bounds here: set equal-length windows yourself
)
SELECT
  alert_name,
  period,
  COUNT(*)                                         AS fires,
  COUNT(DISTINCT DATE(fired_at))                   AS days_with_fires,
  APPROX_QUANTILES(dur_s, 100)[OFFSET(50)]         AS p50_dur_s,
  APPROX_QUANTILES(dur_s, 100)[OFFSET(90)]         AS p90_dur_s,
  COUNTIF(dur_s < 300) / COUNT(*)                  AS frac_under_5m,
  COUNTIF(dur_s < 900) / COUNT(*)                  AS frac_under_15m
FROM fires
GROUP BY alert_name, period
ORDER BY fires DESC;
```

Read it as: high `fires` with high `frac_under_5m` is a hysteresis candidate; high
`fires` with long durations is a real recurring problem (fix the cause, not the
alert); `days_with_fires` close to the window length means chronic.

### 3c. Replay: fires a settings change would have prevented

`{{params}}` has one row per alert:
`alert_name STRING, old_for_s INT64, new_for_s INT64, keep_firing_for_s INT64`
(use 0 for "no change"; `keep_firing_for_s` is the *proposed* value).

A fire is prevented if either:
- its duration `< new_for_s - old_for_s` (hysteresis), or
- it started within `keep_firing_for_s` of the *previous* fire resolving
  (it would have been merged into the previous firing).

The previous fire may predate `baseline_start`, hence the context window.

```sql
WITH ordered AS (
  SELECT
    e.alert_name,
    e.fired_at,
    TIMESTAMP_DIFF(
      COALESCE(e.resolved_at, TIMESTAMP('{{baseline_end}}')), e.fired_at, SECOND) AS dur_s,
    LAG(e.resolved_at) OVER (PARTITION BY e.alert_name ORDER BY e.fired_at) AS prev_resolved_at
  FROM `{{events}}` e
  WHERE e.fired_at >= TIMESTAMP('{{baseline_start_minus_context}}')
    AND e.fired_at <  TIMESTAMP('{{baseline_end}}')
),
scored AS (
  SELECT
    o.alert_name,
    o.fired_at,
    o.dur_s < GREATEST(p.new_for_s - p.old_for_s, 0)                      AS by_hysteresis,
    o.prev_resolved_at IS NOT NULL
      AND TIMESTAMP_DIFF(o.fired_at, o.prev_resolved_at, SECOND) < p.keep_firing_for_s
                                                                           AS by_keep_firing
  FROM ordered o
  JOIN `{{params}}` p USING (alert_name)
  WHERE o.fired_at >= TIMESTAMP('{{baseline_start}}')
)
SELECT
  alert_name,
  COUNT(*)                                        AS fires,
  COUNTIF(by_hysteresis OR by_keep_firing)        AS prevented,
  COUNTIF(by_hysteresis OR by_keep_firing) / COUNT(*) AS frac_prevented,
  COUNTIF(by_hysteresis)                          AS prevented_by_hysteresis,
  COUNTIF(by_keep_firing AND NOT by_hysteresis)   AS prevented_by_keep_firing_only
FROM scored
GROUP BY alert_name
ORDER BY prevented DESC;
```

Caveat: the replay is an upper bound on prevention when `keep_firing_for` chains
(a merged fire extends the window for the next one) and a lower bound on lost
signal when a suppressed short fire was the first sign of a real incident. Spot-check
the top few alerts against incident records before recommending.

### 3d. Silence-manager episodes and gap sensitivity

An *episode* is a run of fires of one alert separated by less than `gap_hours`.
A silence-manager that silences an alert after its first notification in an episode
would suppress every fire after the first. The right gap is not obvious, so show
the sensitivity.

```sql
WITH fires AS (
  SELECT
    alert_name,
    fired_at,
    COALESCE(resolved_at, TIMESTAMP('{{baseline_end}}')) AS resolved_at
  FROM `{{events}}`
  WHERE fired_at >= TIMESTAMP('{{baseline_start_minus_context}}')
    AND fired_at <  TIMESTAMP('{{baseline_end}}')
),
ordered AS (
  SELECT
    g AS gap_hours,
    f.alert_name,
    f.fired_at,
    LAG(f.resolved_at) OVER (PARTITION BY g, f.alert_name ORDER BY f.fired_at) AS prev_resolved_at
  FROM fires f
  CROSS JOIN UNNEST([1, 6, 24, 72, 168]) AS g
),
ep2 AS (
  SELECT
    gap_hours,
    alert_name,
    fired_at,
    SUM(IF(prev_resolved_at IS NULL
           OR TIMESTAMP_DIFF(fired_at, prev_resolved_at, HOUR) >= gap_hours, 1, 0))
      OVER (PARTITION BY gap_hours, alert_name ORDER BY fired_at) AS episode_id
  FROM ordered
)
SELECT
  gap_hours,
  alert_name,
  COUNT(*)                          AS fires,
  COUNT(DISTINCT episode_id)        AS episodes,
  COUNT(*) - COUNT(DISTINCT episode_id) AS silenceable_fires
FROM ep2
WHERE fired_at >= TIMESTAMP('{{baseline_start}}')
GROUP BY gap_hours, alert_name
ORDER BY gap_hours, silenceable_fires DESC;
```

Note: an episode that straddles `baseline_start` is counted by the fires inside the
window only, so `episodes` is slightly overstated for the first days.

### 3e. Overlap between hysteresis and silence-manager

The two mechanisms do not add: a fire prevented by both is only saved once. Report
`only_hysteresis`, `only_silence`, `both`, and `union`, and quote the union as the
total saving. This snippet is self-contained and fixes `gap_hours` at 24.

```sql
WITH fires AS (
  SELECT
    alert_name,
    fired_at,
    COALESCE(resolved_at, TIMESTAMP('{{baseline_end}}')) AS resolved_at
  FROM `{{events}}`
  WHERE fired_at >= TIMESTAMP('{{baseline_start_minus_context}}')
    AND fired_at <  TIMESTAMP('{{baseline_end}}')
),
ordered AS (
  SELECT
    f.*,
    TIMESTAMP_DIFF(f.resolved_at, f.fired_at, SECOND) AS dur_s,
    LAG(f.resolved_at) OVER (PARTITION BY f.alert_name ORDER BY f.fired_at) AS prev_resolved_at
  FROM fires f
),
ep2 AS (
  SELECT
    *,
    SUM(IF(prev_resolved_at IS NULL
           OR TIMESTAMP_DIFF(fired_at, prev_resolved_at, HOUR) >= 24, 1, 0))
      OVER (PARTITION BY alert_name ORDER BY fired_at) AS episode_id
  FROM ordered
),
flags AS (
  SELECT
    e.alert_name,
    e.dur_s < GREATEST(p.new_for_s - p.old_for_s, 0) AS by_hysteresis,
    ROW_NUMBER() OVER (PARTITION BY e.alert_name, e.episode_id ORDER BY e.fired_at) > 1
                                                      AS by_silence
  FROM ep2 e
  JOIN `{{params}}` p USING (alert_name)
  WHERE e.fired_at >= TIMESTAMP('{{baseline_start}}')
)
SELECT
  alert_name,
  COUNT(*)                                          AS fires,
  COUNTIF(by_hysteresis AND NOT by_silence)         AS only_hysteresis,
  COUNTIF(by_silence AND NOT by_hysteresis)         AS only_silence,
  COUNTIF(by_hysteresis AND by_silence)             AS both,
  COUNTIF(by_hysteresis OR by_silence)              AS union_prevented
FROM flags
GROUP BY alert_name
ORDER BY union_prevented DESC;
```

## 4. Cross-check against live Prometheus (if reachable)

The archive is notification-side; Prometheus `ALERTS` is rule-side. Use the
o11y-analysis-tools CLIs to corroborate, and to cover alerts the archive missed
(interactive only, never a CI gate; they need enough `ALERTS` retention):

```bash
# Dead-code candidates: alerts that have not fired within the horizon
stale-alerts-analyzer --prometheus-url=<url> --rules=<rules.yml> \
  --timehorizon=1y --max-points-per-query=2000 --query-delay=1s \
  --exclude="DeadMansSwitch,Watchdog"

# Statistically recommended `for:` per alert (compare with the 3b/3c numbers)
alert-hysteresis --prometheus-url=<url> --rules=<rules.yml> --timeframe=2160h \
  --max-points-per-query=5000 --query-delay=500ms
```

Disagreements are informative: an alert silent in the archive but firing in
`ALERTS` is being dropped, inhibited or silenced downstream; one firing in the
archive but "stale" in Prometheus has probably been renamed.

## 5. Classify and recommend

First run the `review-alerts` skill over the alerts with the highest volume or
worst metrics from 3b (not all of them; it fetches the live guide each time, so
keep the batch small). Its findings (symptom vs. cause, redundancy, error-budget
thresholds, actionability) explain *why* an alert behaves as the data shows and often
point at a better fix than retuning, such as deleting a redundant cause-based alert.
Cite guideline names exactly as that skill reports them, and keep its findings
separate from the data-driven ones in the sheet.

Then, per alert, assign one primary verdict, with the number that justifies it:

| Verdict | Evidence | Typical action |
|---|---|---|
| Delete | Zero fires over a long, fully covered window; no unique failure mode | Remove rule; keep runbook link in the PR |
| Retune threshold | Fires, but never actioned; durations long and benign | Change `expr` |
| Add hysteresis | High `frac_under_5m`; 3c shows large `frac_prevented` | Raise `for:` and/or add `keep_firing_for` |
| Silence-manager | Many fires collapsing into few episodes (3d) | Enrol in auto-silence; pick gap from sensitivity |
| Fix the cause | Chronic, long, recurring real incidents | Bug / capacity work, not alerting work |
| Redesign | Data looks noisy *and* `review-alerts` finds a design flaw (e.g. cause-based, redundant) | Replace or merge per the guideline, then re-measure |
| Keep | Rare, actionable, short time to ack | No change |

Quote the union saving from 3e, not the sum of 3c and 3d. Prefer the smallest
change that captures most of the benefit; the gap between the 24h and 168h rows
in 3d usually shows where returns diminish.

## 6. Validate proposed rule changes

Before opening a PR against the rules repo, run the hermetic gate in this order
(see `promql-cody`):

1. `promql-fmt --check` and `label-check`.
2. `autogen-promql-tests --rules=<rules.yml> --validate`, to scaffold or check
   `promtool` hysteresis test cases for any `for:` you changed.
3. `e2e-alertmanager-test` against a skeleton config, if routing or grouping changed.

## 7. Deliver

Write results to a spreadsheet (or markdown table if none requested), one tab per
concern; keep raw query output separate from judgement so reruns are mechanical:

- `README`: window, placeholders, archive coverage (3a), caveats.
- `Per-alert`: 3b metrics joined to the rules inventory (owner, severity, `for:`).
- `Hysteresis replay`: 3c.
- `Silence episodes`: 3d, plus 3e overlap.
- `Recommendations`: verdict, proposed change, justification, owner, and the guideline cited (if any).
- `Before/After`: only for change-evaluation studies.

Lead the summary with total fires, the union saving, and the top 5 alerts by
volume; do not make the reader reconstruct this from the tabs.

## Pitfalls

- **Coverage gaps**: a quiet alert in a hole in the archive is not a dead alert. Always do 3a.
- **Duration is post-`for:`**: do not compare observed durations to the *new* `for:` directly; use the difference.
- **Open fires**: NULL `resolved_at` must be capped at the window end, or they vanish from duration stats.
- **Unequal windows** in before/after studies bias counts; use equal-length windows and compare rates, not totals.
- **Duplicate rows**: grouped notifications or re-sends can duplicate a firing in the archive; dedupe on (`alert_name`, labels, `fired_at`) if counts look inflated.
- **Renames**: an alert renamed mid-window splits into two series; map old to new before judging either.
- **Seasonality and deploys**: weekly cycles and one-off incidents dominate small windows; use at least 4 weeks and exclude known incidents when judging noise.
- **Suppressed signal**: short fires are sometimes the earliest sign of a real problem; check incident timelines before cutting.
- **Timezones**: BigQuery `DATE()` is UTC; say so if on-call reasons in local time.
- **Replay is not a forecast**: it assumes behaviour would not have changed under the new settings.
