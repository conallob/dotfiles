# Commit, Push, and Create Pull Request

Create a git commit with all current changes, push to remote branch, and create a pull request.

## Instructions

1. **Git Status**: Run git status to check current state
   - Show untracked files and modifications
   - Determine if working directory is clean

2. **Commit Changes**:
   - If there are uncommitted changes, create a commit following the git commit guidelines from CLAUDE.md:
     - Run git status, git diff, and git log in parallel to understand context
     - Draft a concise commit message (1-2 sentences) focusing on "why" not "what"
     - Add relevant files and create the commit
     - Run git status after commit to verify success
   - If working directory is already clean, skip to push step

3. **Push to Remote**:
   - Check if current branch is tracking a remote branch
   - Push with: `git push -u origin <branch-name>`
   - Retry up to 4 times with exponential backoff (2s, 4s, 8s, 16s) if push fails due to network errors
   - CRITICAL: Verify the branch name starts with 'claude/' and ends with the session ID, otherwise push will fail with 403

4. **Create Pull Request**:
   - Get the full commit history from when the branch diverged from the base branch using `git log` and `git diff [base-branch]...HEAD`
   - Analyze ALL commits that will be included in the PR (not just the latest commit)
   - Draft a PR summary with:
     - ## Summary section with 1-3 bullet points
     - ## Original Prompt section with the primary prompts as markdown code blocks (per CLAUDE.md guidelines)
     - ## Test plan section with a bulleted checklist
   - Create PR using:
     ```bash
     gh pr create --title "descriptive title" --body "$(cat <<'EOF'
     ## Summary
     - Bullet points here

     ## Original Prompt
     ```
     [Include the original prompt from this session as a code block]
     ```

     ## Test plan
     - [ ] Checklist items
     EOF
     )"
     ```
   - Return the PR URL when done

## Notes

- Follow all git safety protocols from CLAUDE.md (never skip hooks, never force push to main/master)
- Only create commits when there are actual changes
- The PR description should include the original prompt from this session for reviewer context
