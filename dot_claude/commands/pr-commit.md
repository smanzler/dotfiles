---
description: Commit the pending work, then open a PR whose description fills the repo's PR template
argument-hint: [domain or extra context]
allowed-tools: Bash(git:*), Bash(gh:*), Read, Glob
---

Commit the work in progress, then open a pull request that fills the repo's PR template.

Extra context from the user (a domain hint, notes, or empty): $ARGUMENTS

## 1. Read the state

Run these together:

- `git status --short`
- `git rev-parse --abbrev-ref HEAD`
- `git symbolic-ref --quiet --short refs/remotes/origin/HEAD` (fall back to `main`, then `master`) — this is `$BASE`
- `gh pr view --json number,url,title` to find a pull request that is already open for the branch

Then read the full branch diff against the merge base: `git diff --stat "$(git merge-base HEAD "$BASE")"` and the patch for the files that matter. The PR description must cover the whole branch, not only the newest changes.

HEAD is `$BASE`: make a branch with `git switch -c <name>`. Make the name from the title in step 3, in kebab case, under 40 characters.

## 2. Commit the pending work

- Commit all changes in the working tree, untracked files included: `git add -A`, then `git commit`.
- No changes: make no commit and go to step 3.
- Message: one subject line only, no body. The PR description holds the prose.

## 3. Write the PR title and description

Title: `<domain>: <what was done>`

- `domain` is the area of the product the change belongs to, in lower case words: `activity logs`, `session api`, `terraform provider`. Get it from the changed paths, the module name, or the user's hint. Do not use a commit type like `feat` or `fix`.
- Keep the title under 72 characters. Use the past tense.
- Use the same form for the commit subject. The commit subject describes only the commit; the PR title describes the branch.

Find the PR template, in this order:

1. `.github/pull_request_template.md` (any case)
2. `PULL_REQUEST_TEMPLATE.md` or `docs/pull_request_template.md`
3. `.github/PULL_REQUEST_TEMPLATE/*.md` — pick the one that fits the change best

No template: write a short description with a `## What` and a `## Why` section.

Fill the template:

- Keep the template's headings, their order, and their exact text.
- Remove the template's HTML comments and its placeholder text after you obey them.
- Fill only what the diff proves. Leave a section empty when you cannot verify it from the diff — test steps, screenshots, rollout plans, ticket links.
- Tick the boxes the diff proves: the type of change and the parts the change touches. Keep the template's marker style, `- [x]`.
- Never tick a box that promises work the diff cannot show: tests added, docs updated, tested by hand, ticket linked.
- Keep the description under about 200 words. A bullet list is better than a paragraph when the section lists changes.

Style:

- Write in ASD-STE100 Simplified Technical English. Prefer simple verbs: use, make, get, put, remove, start, stop, keep, find, send.
- Say what the change does and what a reviewer must know: a constraint, a needed order, a migration, a deliberate deviation.
- Do not restate the diff file by file, add a "Notes" section the template does not ask for, or praise the change.

## 4. Open the pull request

Write the description to a temporary file and give it to `gh` with `--body-file`. Remove the file at the end.

- Push the branch: `git push -u origin HEAD`.
- No pull request open: `gh pr create --base "$BASE" --title "<title>" --body-file <file>`.
- A pull request is already open: update it with `gh pr edit --title "<title>" --body-file <file>`. Do not change its draft state.

Print the commit subject, the pull request URL, and the sections left empty.
