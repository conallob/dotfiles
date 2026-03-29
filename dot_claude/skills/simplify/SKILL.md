---
name: simplify
description: |
  Review recently changed code for quality, reuse, efficiency, and CLAUDE.md compliance.
  Use after making code changes to shepherd a PR to production quality.
  Runs parallel agents to check: code reuse, quality/clarity, efficiency, and standards.
user-invocable: true
---

# /simplify — Code Quality Review

Run parallel agents to review all code changed in the current session. Each agent focuses on a distinct concern. Fix any issues found before finishing.

## Agents to spawn

Spawn these four agents in parallel using the Agent tool:

### 1. code-simplifier
Use the built-in `code-simplifier` agent (from the code-simplifier plugin). It will:
- Review recently modified code for clarity, consistency, and maintainability
- Apply project standards from CLAUDE.md
- Reduce unnecessary complexity without changing behaviour

### 2. Reuse reviewer
Prompt: "Review the code changed in this session. Identify any logic that duplicates existing utilities, functions, or patterns already present in the codebase. Suggest consolidations. Do not change behaviour."

### 3. Efficiency reviewer
Prompt: "Review the code changed in this session for performance and efficiency. Look for unnecessary allocations, redundant operations, N+1 patterns, or opportunities to use more efficient data structures or algorithms. Suggest specific improvements."

### 4. Standards reviewer
Prompt: "Review the code changed in this session against the project CLAUDE.md and language conventions. Check: naming conventions, error handling patterns, test coverage for new logic, missing comments on non-obvious code. Report violations."

## After agents complete

- Collect findings from all four agents
- Apply fixes for any issues found
- Run the `lint-test` agent to verify nothing is broken
- Summarise what was improved
