---
description: Rebase the current branch onto the latest base, resolve the conflicts, verify the build, then push
argument-hint: [base branch]
allowed-tools: Bash(git:*), Bash(gh:*), Read, Edit, Glob, Grep
---

Rebase the current branch onto the latest base branch, verify it, and push it.

Base branch the user asked for (a branch name, or empty): $ARGUMENTS

## 1. Find the base

Run these together:

- `git rev-parse --abbrev-ref HEAD`
- `git status --short`
- `gh pr view --json number,baseRefName,url` to get the base of an open pull request
- `git symbolic-ref --quiet --short refs/remotes/origin/HEAD`

Pick `$BASE` in this order: the user's argument, the open pull request's `baseRefName`, `origin/HEAD`, `main`, `master`.

- HEAD is `$BASE`: run `git pull --ff-only` and stop.
- A rebase, a merge, or a cherry-pick is already in progress: report the state and stop. Do not start a second one.

Then `git fetch origin` and get the work you move:

- `git log --oneline "origin/$BASE"..HEAD` — the commits to replay
- `git log --oneline HEAD.."origin/$BASE"` — the new work you land on

Nothing new on `origin/$BASE`: say that the branch is up to date and stop.

## 2. Rebase

`git rebase --autostash "origin/$BASE"`

Keep the commits as they are. Do not squash, reword, drop, or reorder a commit unless the user asks for it.

## 3. Resolve the conflicts

For each conflicted file:

- Read the file and the commits on each side. Understand the intent of the two changes before you write anything.
- Keep both intents. A rebase conflict is almost always two changes to the same area, not a choice between them.
- Do not take a whole side with `git checkout --ours` or `--theirs`.
- Remake a generated file instead of merging it by hand: a lock file, a snapshot, a schema dump, a bundled type. Run the tool that makes it.
- When the two sides make different decisions about the same behaviour, keep the base's behaviour and apply the branch's change on top of it where possible. Record the choice for the report.
- Stage the file with `git add` when it is correct.

Continue with `GIT_EDITOR=true git rebase --continue`. Git opens an editor without this and the command hangs.

Never run `git rebase --skip`. It removes a commit.

When you cannot make a resolution that keeps the branch's intent, run `git rebase --abort`, report the conflict and both sides, and stop.

## 4. Verify

Find the repo's own check command in `package.json` scripts, a `Makefile`, a `justfile`, or `CLAUDE.md`. Prefer a typecheck plus the tests for the packages the branch touches.

Fix a failure that the rebase made — a moved import, a renamed symbol, a signature that changed under you — and amend it into the commit that it belongs to. Do not fix a failure that the branch already had; report it.

## 5. Push

When the branch has an upstream, run `git push --force-with-lease`. Never use `--force`. Do not push when the check from step 4 fails because of the rebase.

## 6. Report

- the base, and how many commits came in from it
- every file you resolved, and the choice you made for it
- the check command and its result
- the push result
- an untracked file or a stash entry left over
