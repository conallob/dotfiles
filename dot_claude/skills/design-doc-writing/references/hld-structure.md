# Default HLD structure

Use the user's template when there is one. Otherwise use this order. Each section is short.

## Document Metadata
Author, created date, last edited, status (for example "Draft for review").

## Objective
One or two sentences on what the design achieves.

### Goals
4-7 bullets. Combine closely related goals. Include non-functional goals (auth, availability) when they constrain the choice.

### Non Goals
4-6 bullets. Include deliberate deferrals ("deferred to v1.x, but the model must not block it") and adjacent systems this one will not replace.

## Background
One paragraph: current situation and the category of solution. Do not repeat the problem statement.

## Problem Statement
The problem in the user's words, then the numbered requirements the solution must meet, tagged with phase (v1, v1.x) and kind (functional, non-functional, nice to have).

## Design Thoughts
- **Proposed direction:** one paragraph. Name the leading candidate, the runners-up, and what a proof of concept must still prove. Mention decisions that depend on open questions.
- **Architecture:** 4-6 bullets, one component each.
- **Data model:** a sentence on the starting point, then 3-4 bullets for what is added.
- **Delivery phases:** one bullet per phase.
- **Open questions:** about six bullets. Include decisions the user must make (not only facts to look up), and merge related questions.

## Alternatives Considered
Short intro (and what was not evaluated in depth), the comparison table, then one section per alternative with Pros and Cons as nested bullets. Typical set: the leading product (as separate entries per edition if relevant), one or two peers, a platform-native approach, and a custom build.

## Length budget
About 1,600-2,000 words plus the table. Rough allocation: goals through problem statement 25%, design thoughts 30%, alternatives 45%.
