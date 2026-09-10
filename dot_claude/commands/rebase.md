---
description: Rebase the current branch onto the latest base, resolve the conflicts, then verify the build
argument-hint: [base branch]
allowed-tools: Bash(git status:*), Bash(git fetch:*), Bash(git diff:*), Bash(git log:*), Bash(git rebase:*), Bash(git rev-parse:*), Bash(git merge-base:*), Bash(git symbolic-ref:*), Bash(git branch:*), Bash(git show:*), Bash(git stash:*), Bash(git add:*), Bash(git checkout:*), Bash(git ls-files:*), Bash(gh pr view:*), Read, Edit, Glob, Grep
---

Rebase the current branch onto the latest base branch and leave it ready for the user to push.

Base branch the user asked for (a branch name, or empty): $ARGUMENTS

## 1. Find the base

Run these together:

- `git rev-parse --abbrev-ref HEAD`
- `git status --short`
- `gh pr view --json number,baseRefName,url` to get the base of an open pull request
- `git symbolic-ref --quiet --short refs/remotes/origin/HEAD`

Pick `$BASE` in this order: the user's argument, the open pull request's `baseRefName`, `origin/HEAD`, `main`, `master`. Print which one you picked.

Stop when HEAD is `$BASE`. A rebase does nothing here; tell the user to run `git pull --ff-only`.

Stop when a rebase, a merge, or a cherry-pick is already in progress. Report the state and the way out. Do not start a second one.

Then get the work you are about to move:

- `git fetch origin`
- `git log --oneline "origin/$BASE"..HEAD` — the commits to replay
- `git log --oneline HEAD.."origin/$BASE"` — the new work you are landing on
- `git diff --stat "$(git merge-base HEAD "origin/$BASE")"` — what the branch changes

Say that the branch is up to date and stop when there is nothing to replay onto.

## 2. Rebase

`git rebase --autostash origin/$BASE`

`--autostash` keeps an uncommitted change. It does not touch an untracked file, so list the untracked files for the user and leave them alone.

Keep the commits as they are. Do not squash, reword, drop, or reorder a commit unless the user asks for it.

## 3. Resolve the conflicts

For each conflicted file:

- Read both sides with `git log --oneline -3` on each parent, and read the file. Understand the intent of the two changes before you write anything.
- Keep both intents. A rebase conflict is almost always two changes to the same area, not a choice between them.
- Do not take a whole side. `git checkout --ours` and `git checkout --theirs` throw work away.
- Remake a generated file instead of merging it by hand: a lock file, a snapshot, a schema dump, a bundled type. Run the tool that makes it.
- Stage the file with `git add` when it is correct.

Continue with `GIT_EDITOR=true git rebase --continue`. Git opens an editor without this and the command hangs.

Never run `git rebase --skip`. It removes a commit.

Stop and ask the user when the two sides make different decisions about the same behaviour, when you cannot tell what a side wants, or when the resolution needs a product choice. Leave the rebase in progress, show both sides, show what you would write, and give the user `git rebase --continue` and `git rebase --abort`.

## 4. Verify

Find the repo's own check command. Look in `package.json` scripts, a `Makefile`, a `justfile`, or `CLAUDE.md`. Prefer a typecheck plus the tests for the packages the branch touches. Do not run a whole slow suite when a targeted one covers the diff.

Run it. Report the result as it is.

Fix a failure only when the rebase made it — a moved import, a renamed symbol, a signature that changed under you. Say what you fixed. Report a failure that the branch already had, and do not fix it here.

## 5. Report

Print:

- the base you rebased onto, and how many commits came in from it
- the commits you replayed
- every file you resolved, and the choice you made for it
- the check command you ran and its result
- an untracked file or a stash entry left over
- `git push --force-with-lease` for the user to run

## Rules

Never push. The user pushes. Do not run `git push`, with or without `--force-with-lease` or `--force`.

Do not run `git rebase --abort` on your own. The user decides to throw the rebase away.

Do not commit unrelated work, and do not add a trailer to a commit message.
