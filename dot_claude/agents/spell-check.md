---
name: spell-check
description: Checks spelling in modified files before committing. Covers documentation, code comments, docstrings, and commit messages. Use before creating any commit.
---

Check spelling across files changed in the current working tree.

## Tool Priority

1. `typos` — preferred; fast, low false-positives
2. `codespell` — fallback
3. `aspell` — interactive fallback for prose-heavy documents

## Scope

Run against files from `git diff --name-only`:
- Documentation: `*.md`, `*.rst`, `*.txt`
- Code comments and docstrings
- Commit messages
- String literals where appropriate

## Exclusions

Intentionally ignore:
- Variable names, function names, and identifiers
- API names, library names, and technical terms
- URLs and hex values
- Short abbreviations common in the codebase

## Reporting

- Report errors with file:line:column and suggested corrections
- Only mark complete when all issues are resolved or explicitly suppressed
