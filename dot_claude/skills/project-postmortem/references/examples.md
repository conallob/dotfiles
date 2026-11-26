# Worked examples

Both examples use invented data for a fictional "billing export migration".
They show the shape and the standard of evidence, not facts to reuse.

## A good contributing-factor entry

> ### 3. Review wait differed sharply between repositories
>
> Changes to the export service were reviewed within a day; changes to the
> shared scheduler library waited about two weeks for a first review. The
> scheduler repository has no code-ownership file, so the owner asked in the
> project channel who should review, and the question went unanswered for
> five days.
>
> | Repository | PRs | Median days to first review | Source |
> |---|---|---|---|
> | export-service | 6 | 0.8 | PR timelines |
> | scheduler-lib | 3 | 13 | PR timelines |
>
> - 4 Mar: the owner asks in the channel who reviews scheduler-lib changes
>   (channel thread). 9 Mar: a reply names two possible reviewers (same
>   thread).
> - Two of the three scheduler-lib PRs were rebased after the base branch
>   moved while they waited (PR timelines), which restarted a 40-minute CI run
>   each time (CI logs).
>
> The wait is consistent with unclear reviewer routing rather than with
> reviewer availability: the reviewers named on 9 Mar reviewed within a day of
> being tagged (PR timelines). `[confirm]` with the scheduler-lib maintainers whether a
> routing rule existed that the owner could not see.

Why it works: it states a condition (no ownership file) rather than a person,
leads with the point, gives dated and sourced facts, says "consistent with"
where the record only suggests a cause, and marks the one claim it cannot
check.

## A weak entry, rewritten

**Weak**

> ### 3. The scheduler team was slow and didn't prioritise our work
>
> The scheduler team ignored our PRs for weeks because they had other
> priorities and didn't care about the migration.

What is wrong: it blames a team, guesses at motive ("didn't care"), gives no
dates or sources, and states a cause the record cannot show.

**Rewritten**

> ### 3. Reviewer routing for the scheduler library was unclear
>
> Three PRs to the scheduler library waited a median of 13 days for a first
> review, against under a day for the export service (PR timelines). The
> repository has no code-ownership file, and the owner's request for a
> reviewer on 4 Mar was answered on 9 Mar (channel thread). The record does not
> show how scheduler-lib work was prioritised against other commitments, so
> this entry makes no claim about it. `[confirm]` whether the scheduler-lib
> maintainers had a routing rule or a capacity constraint at the time.

What changed: the subject is the missing mechanism, every claim has a date and
a source, motive is dropped, and the unknown is marked instead of asserted.
