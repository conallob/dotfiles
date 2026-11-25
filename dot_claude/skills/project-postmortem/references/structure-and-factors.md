# Postmortem structure and contributing-factor prompts

## Sections

| Section | What it must do |
|---|---|
| Summary | State where the project landed in the first sentence, give ticket counts, list the headline factors. |
| Background and scope | The original ask, the starting point, how scope changed, who was involved and in what role. |
| Timeline | One table, newest first: date, what happened, source. |
| Impact | What was delivered and what was not (table with ticket references), business exposure, cost to the owner. |
| Contributing factors | One numbered subsection per factor, each with evidence from the record. |
| Technical gaps and bugs | Table of gap, ticket, status, linked PRs; then root causes; then the limits of the code-host review. |
| What went well | Specific, evidence-backed items, not generic praise. |
| Lessons learned | Each lesson tied to a factor, phrased as a practice to adopt. |
| Action items | Action, what it addresses, proposed owner, target. Group by theme. |
| Sources and open items | Links to every source, what could not be read, and a checklist of things to confirm before sharing. |

## Contributing-factor prompts

Ask the user which of these applied, then look for the evidence in the right
column before including any.

| Category | Where the evidence usually is |
|---|---|
| Onboarding and navigating the organization, including who can see org charts and ownership data | Early channel messages asking who owns something; the dates of access being granted. |
| Priority alignment between the owner, their manager and the stakeholder whose input is needed | Planning or 1:1 notes; ticket priority changes; the gap between ask and answer. |
| External events such as security incidents, and their side effects on access and in-flight work | Incident announcements; access revocations; paused or re-opened tickets. |
| Platform or architecture migrations that change the target mid-project | Announcements and ticket re-parenting; the date the design stopped matching the target. |
| Review latency by repository, and whether ownership and reviewer routing were clear | PR open, first-review and merge timestamps, per repository; ownership files; reviewer-request threads. |
| CI duration and its effect on stacked or rebased changes | CI run times on the PRs; rebases after a base moved. |
| Stakeholder feedback latency, measured in days or weeks | Dates a question was asked and answered; feedback-session notes. |
| Collaboration norms: reliance on calls versus written threads, time-zone overlap windows | Decisions that exist only in call notes; message timestamps against working hours. |
| Tooling gaps exposed by the project, such as secrets management or missing freshness alerts | Workarounds in tickets or PRs; stale-data discoveries. |

## Sources: handling notes

- Count tickets by state yourself from the tracker data, not from a summary.
- For PRs, record opened, first review and merged dates, and the merge state.
  If the code host cannot be reached, say so and mark dependent claims
  unverified; state the limits of any review you could do.
- Direct messages: dates and project facts only. Exclude personal,
  interpersonal and hiring content, and say that in the sources section.
