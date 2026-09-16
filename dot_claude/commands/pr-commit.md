---
description: Commit the pending work, then open a draft PR whose description fills the repo's PR template
argument-hint: [domain or extra context]
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git commit:*), Bash(git rev-parse:*), Bash(git merge-base:*), Bash(git symbolic-ref:*), Bash(git config:*), Bash(git branch:*), Bash(git ls-files:*), Bash(git show:*), Bash(git push:*), Bash(gh pr:*), Bash(gh repo:*), Read, Glob
---

Commit the work in progress, then open a draft pull request that fills the repo's PR template.

Extra context from the user (a domain hint, notes, or empty): $ARGUMENTS

## 1. Read the state

Run these together:

- `git status --short`
- `git rev-parse --abbrev-ref HEAD`
- `git symbolic-ref --quiet --short refs/remotes/origin/HEAD` (fall back to `main`, then `master`) — this is `$BASE`
- `git log --oneline "$BASE"..`
- `gh pr view --json number,url,isDraft,title` to find a pull request that is already open for the branch

Then read the full branch diff against the merge base: `git diff --stat "$(git merge-base HEAD "$BASE")"` and the patch for the files that matter. The PR description must cover the whole branch, not only the newest changes.

Stop and ask the user for a branch name if HEAD is `$BASE`. Do not open a pull request from the base branch.

## 2. Commit the pending work

Do this step only when something is staged — `git status --short` shows a mark in the first column.

- Commit exactly what is staged, and nothing else.
- Never run `git add`, and never stage a file. The user stages the work they want in the commit. An unstaged change and an untracked file are deliberate: leave them in the working tree and list them for the user.
- Nothing staged: make no commit. Say that the branch was already committed and go to step 3.
- Message: one subject line only, no body. The PR description holds the prose.

## 3. Write the PR title and description

Title: `<domain>: <what was done>`

- `domain` is the area of the product the change belongs to, in lower case words: `activity logs`, `session api`, `terraform provider`. Get it from the changed paths, the module name, or the user's hint. Do not use a commit type like `feat` or `fix`.
- Keep the title under 72 characters. Use the past tense of what the branch did.
- Use the same form for the commit subject in step 2. The commit subject describes only the commit; the PR title describes the branch.

Find the PR template, in this order:

1. `.github/pull_request_template.md` (any case)
2. `.github/PULL_REQUEST_TEMPLATE.md`
3. `PULL_REQUEST_TEMPLATE.md` or `docs/pull_request_template.md`
4. `.github/PULL_REQUEST_TEMPLATE/*.md` — more than one template. Pick the one that fits the change. Ask the user if two fit equally.

If the repo has no template, write a short description with a `## What` and a `## Why` section, and tell the user that no template was found.

Fill the template:

- Keep the template's headings, their order, and their exact text.
- Remove the template's HTML comments and its placeholder text after you obey them.
- Fill only what the diff proves. Leave a section empty when you cannot verify it from the diff — test steps, screenshots, rollout plans, ticket links.
- Tick the boxes the diff proves: the type of change (bug fix, feature, refactor, docs, chore, breaking change) and the parts the change touches (an area, a service, a package, a platform, a schema or API change). Keep the template's own marker style, `- [x]`. Tick one box only when the template asks for one.
- Keep a box unticked when it is a promise about your own work that the diff cannot show: tests added, docs updated, change tested by hand, reviewer found, ticket linked. Never tick these.
- Keep the whole description under about 200 words. One or two sentences for each section is normal. A bullet list is better than a paragraph when the section lists changes.

Style, same as the comment rules in CLAUDE.md:

- Write in ASD-STE100 Simplified Technical English. Prefer simple verbs: use, make, get, put, remove, start, stop, keep, find, send.
- Say what the change does and what a reviewer must know: a constraint, a needed order, a migration, a deliberate deviation.
- Do not restate the diff file by file. Do not add a summary of the summary, a "Notes" section the template does not ask for, or praise of the change.

## 4. Open the draft pull request

Write the description to a temporary file and give it to `gh` with `--body-file`. Do not put the description in a shell argument. Remove the file at the end.

- Push the branch first: `git push -u origin HEAD`.
- No pull request open yet: `gh pr create --draft --base "$BASE" --title "<title>" --body-file <file>`.
- A pull request is already open: keep it, and update it with `gh pr edit --title "<title>" --body-file <file>`. Tell the user the pull request number. Do not make a second one, and do not change its draft state.

Print the commit subject, the pull request URL, and the sections you left for the user to fill.

## Rules

Never stage a file. `git add` is not yours to run; the staged set is the user's choice of what the commit holds.

The user is the only author of the commit and the only author of the pull request. Do not add a `Co-Authored-By` trailer, a `Generated with` line, a footer, or any other trailer to the commit message or to the pull request description, even if a global rule asks for one.
