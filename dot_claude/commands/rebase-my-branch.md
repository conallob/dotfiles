---
description: Rebase the current branch onto its base and get it ready for PR review
argument-hint: "[base-branch]"
---

Rebase the current branch onto its base branch and leave it ready for PR review.
Work through the steps in order, and stop to ask me if anything below says to.

## 1. Preflight

- Run `git status`, `git branch --show-current` and `git remote -v`.
- Refuse to continue if the current branch is the default branch (`main`/`master`) or is
  detached HEAD.
- If the working tree is dirty, stop and ask whether to commit, stash, or abort. Never
  discard uncommitted work.
- If the branch has an upstream, check that every commit on it is mine
  (`git log --format='%an' @{upstream}` vs `git config user.name`). If someone else has
  pushed to it, stop and ask: don't rewrite history on a branch I don't solely own.
- Record the current tip (`git rev-parse HEAD`) and tell me, so there is an easy way back
  (`git reset --hard <sha>` or `git reflog`).

## 2. Pick the base

- If `$ARGUMENTS` names a branch, use it as the base.
- Otherwise use the open PR's base if there is one, else the remote's default branch
  (`git symbolic-ref refs/remotes/origin/HEAD`).
- `git fetch origin` (fetch the base branch by name) and show how far behind the branch is:
  `git log --oneline HEAD..origin/<base>`.

## 3. Rebase

- Run `git rebase origin/<base>`.
- On conflicts: resolve each one by reading both sides and understanding the intent of my
  commit versus the upstream change, not by blindly taking "ours" or "theirs". Keep going
  with `git add` and `git rebase --continue`.
- If a conflict is ambiguous (both sides changed the same logic in incompatible ways),
  stop and ask me rather than guessing.
- If the rebase goes badly, `git rebase --abort` and report what happened.
- Never skip a commit (`--skip`) without telling me which one and why.

## 4. Tidy the history (only if it helps the reviewer)

- Look at `git log --oneline origin/<base>..HEAD`.
- Propose, but do not do unprompted, squashing fixup/WIP/"address review comments" commits
  into the commits they belong to. Interactive rebase isn't available here, so use
  `git reset --soft` plus recommitting, or `git commit --fixup` with
  `GIT_SEQUENCE_EDITOR=true git rebase --autosquash`, and only after I agree.
- Each remaining commit should be one logical change with a message that explains why.

## 5. Verify

- Run the project's own checks that are relevant to the diff (build, lint, tests; for this
  repo, `chezmoi execute-template` on any changed `.tmpl` files). Find them from the
  README, Makefile, CI config or CLAUDE.md rather than guessing.
- Review `git diff origin/<base>...HEAD` once for leftover debug output, stray files,
  merge-conflict markers, and secrets. Fix or report what you find.
- If checks fail, say so with the output. Don't skip or disable a test to get green.

## 6. Push

- Push with `git push --force-with-lease`, never plain `--force`, and never to the default
  branch. If there is no upstream yet, use `git push -u origin <branch>`.
- If `--force-with-lease` is rejected, someone else updated the remote branch. Stop and
  report; don't override it.

## 7. PR description

- If a PR is open for this branch, re-read the description against the new diff and fix
  anything stale: claims the diff no longer supports, changes it makes that the description
  omits, and details left over from earlier revisions. The description must match the diff.
- If there is no PR yet, say so and offer to open one. If the repo has a PR template,
  mirror its headings. Don't put test plan details in the description.

## 8. Report

Finish with a short summary: base branch and how many commits it was behind, conflicts
resolved (and how), history changes, checks run and their results, whether the push
succeeded, and the pre-rebase SHA for rollback.

$ARGUMENTS
