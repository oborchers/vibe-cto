---
description: "Walk through open questions one by one — from a master plan, a scope report, or questions already in the conversation. For each question, print a fixed short block (Why it matters / Where it matters), then capture the user's choice via a dedicated AskUserQuestion call per question (exactly one question per call — never batched). If the source is a master plan, batch-apply the answers by moving them from Open to Resolved. Any other source gets a printed summary and no file write. Runs entirely in the main conversation; no subagent dispatch."
argument-hint: "[path] [question-number]"
---

You are **walking the user through a set of open questions**. For each question you (a) ground the analysis in whatever evidence exists, (b) print a fixed short block, (c) make **one** `AskUserQuestion` call carrying **exactly that one question** with 2–4 alternatives, and (d) record the user's choice. Questions are walked **strictly sequentially** — you finish presenting, asking, and capturing one question before you touch the next. After all questions are walked you print a summary, and — only when the source is a master plan file — apply the answers to it.

**Never batch.** `AskUserQuestion` accepts up to 4 questions in a single call. Never use that to ask several open questions at once. One open question = one `AskUserQuestion` call. The user resolves each question in isolation.

**This command runs entirely in the main conversation.** Do not dispatch a subagent. All reading, analysis, and alternative-generation happens here.

**Everything you print follows `planning-tools:plain-language`.** Short sentences. One idea each. Every ticket, ADR, and PR carries its human name, not just its ID.

**Input:** `$ARGUMENTS`

Parse arguments:
- First positional path → explicit source file (skips the rest of the ladder).
- First or second positional integer → single-question targeting (walks only that Q-number).
- No args → resolve the source via the ladder in Step 1, walk all open questions.

---

## Step 1 — Resolve the question source

Open questions do not only live in master plans. Work down this ladder and stop at the first rung that yields questions. **Do not hard-fail at any rung** — fall through to the next one.

### Rung 1 — Explicit path argument

If the user supplied a path, Read it. If the Read fails, report the failed path and go to Rung 4 (do not silently fall through to branch matching — the user named a file and deserves to know it was not there).

### Rung 2 — Already in this conversation

Before touching the filesystem, check what is already in context. Use it if you find any of:

- A plan or report file **read or written earlier in this session** — reuse it directly. Do not re-glob, do not branch-match, do not re-Read it if the content is still in context.
- A `/planning-tools:plan-context` scope report printed in the conversation — its `## Open questions blocking …` section is a valid source.
- **Findings returned by a worker agent** (`plan-context-worker` or any other subagent) that contain open questions.
- **Questions the user typed** into the conversation.

If several candidates exist, prefer the most recent. If the most recent is ambiguous, name what you found in one line and let the user redirect you — do not guess silently.

This rung is the common case. Reaching for git and glob when the questions are already on screen is the bug this ladder fixes.

### Rung 3 — Branch-matched master plan

Only attempted when a git repo is available. Probe first, and **skip this rung silently** if the probe fails:

```bash
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
ROOT="$(git rev-parse --show-toplevel)"
BRANCH="$(git branch --show-current)"
[ -z "$BRANCH" ] && exit 0   # detached HEAD — skip this rung, do not error
BASE="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')"
[ -z "$BASE" ] && git rev-parse --verify --quiet origin/main >/dev/null && BASE=main
[ -z "$BASE" ] && git rev-parse --verify --quiet origin/master >/dev/null && BASE=master
[ -z "$BASE" ] && BASE=main
echo "ROOT=$ROOT"; echo "BRANCH=$BRANCH"; echo "BASE=$BASE"
```

Not a git repo, or detached HEAD → skip to Rung 4. This is **not** an error condition.

With a branch in hand, lift the plan match from `/planning-tools:plan-tick` Step 2:

1. Glob `*.md` under `$ROOT/context/tickets/`, `$ROOT/docs/plans/`, `$ROOT/.claude/plans/master/`. Filter to files containing `## Implementation Phases`.
2. **1 candidate:** use it.
3. **2+ candidates — branch-match:** normalize branch + plan basenames the same way as `/planning-tools:plan-tick`; pick the substring match; on ties, most-recently-modified.
4. **0 candidates:** fall through to Rung 4.

### Rung 4 — Ask, do not error

Nothing resolved. Print one short line naming what you checked, then call `AskUserQuestion` with exactly three options:

```
No open questions found. I checked: the arguments, this conversation, and <the globbed directories, or "no git repo here">.
```

- **Option 1 (recommended):** `"Point me at a file"` — description: "Tell me the path and I'll read the open questions from it."
- **Option 2:** `"I'll paste the questions"` — description: "Paste them into the chat and re-run. Any list of questions works."
- **Option 3:** `"Cancel"` — description: "Stop here. Nothing is read or written."

Then stop. Do not exit with an error code.

### Record the source kind

Whatever rung resolved, record which of these you have. It decides what happens at the end of the walk.

| Source kind | How to detect it | What happens at apply time |
|---|---|---|
| `plan-file` | The file has **both** `## Open Questions` and `## Implementation Phases` | Write back — answered questions move from Open to Resolved |
| `report-file` | A file with an open-questions section but **no** `## Implementation Phases` (e.g. a `/plan-context` scope report) | Printed summary only. Nothing is written. |
| `conversation` | Questions in context with no file behind them | Printed summary only. Nothing is written. |

---

## Step 2 — Parse the questions

Normalize every source into the same shape: `{ n, questionText, contextProse, originalBullet }`. `originalBullet` is only meaningful for `plan-file` sources — it is what gets removed on apply.

Accept all four shapes:

**(a) Canonical plan list shape (v0.3.0+)** — under `## Open Questions`:

- Each `- **Q<N> — <question text>:**` line starts one question. Capture `<N>`, the text between the em-dash and the colon, the inline prose after the colon, and any indented continuation lines up to the next `- **Q` bullet or the next `## ` heading.

**(b) Legacy plan table shape (v0.2.x)** — a markdown table with a `| Q | Blocking? |` header under `## Open Questions`:

- Each row's first cell carries the question, usually `Q<N> — <question text>`. Parse out `<N>` and the text; the other cells become `contextProse`.
- Print one line: `This plan uses the old table shape for Open Questions. It still works. Consider moving to the list shape — see planning-tools:master-plan-methodology.`

**(c) Scope-report shape** — a heading matching `## Open questions…` (as emitted by `/planning-tools:plan-context`), followed by plain `- ` bullets or a numbered list with no `Q<N>` prefix:

- Take each bullet or numbered line as one question. **Auto-number them `Q1..QN`** in document order. `originalBullet` is recorded but unused, because report files are never written to.

**(d) Free-form conversation shape** — a list of questions the user typed, or questions inside a worker agent's returned findings:

- Take each question as one entry. **Auto-number `Q1..QN`** in the order they appear. There is no `originalBullet`.

**Nothing parses:** report what you found and what you expected in one short line, then offer the Rung 4 `AskUserQuestion`. Do not error out.

**Empty-state placeholders** like `_(All N resolved YYYY-MM-DD — see Resolved Questions below.)_` count as **zero questions**.

---

## Step 3 — Handle the empty case

Zero questions parsed → say so in one line and **stop**:

```
No open questions in <source>. Nothing to do.
```

---

## Step 4 — Optional single-question targeting

If a `<question-number>` argument was supplied, filter to that Q-number. This works for every source kind, including auto-numbered ones.

If the number does not exist, list the numbers that do:

```
No Q<N> here. Open questions: Q1, Q3, Q5. Re-run with one of those.
```

Otherwise walk all parsed questions.

---

## Step 5 — Per-question walkthrough (main conversation)

For each question, do all of the following **in the main conversation**. Do not dispatch any agent.

**Walk strictly one question at a time.** Fully present, ask, and capture question *i* before reading any evidence for question *i+1*. Never prepare a single `AskUserQuestion` call that covers several questions — even if they look related or trivial. Each question is its own round-trip so the user can consider it alone.

### (a) Gather evidence

Scan the question text, its `contextProse`, and the surrounding source for concrete anchors:

- File paths (`src/foo/bar.ts`) with or without line ranges.
- ADR references (`ADR-NN`, `context/adrs/NN-<slug>.md`).
- Ticket IDs (`CI-21`, `AIA-1234`).
- Named symbols (functions, types, SQL identifiers) you can grep for.

Read the most question-adjacent anchors — **cap at ~5 reads per question** to keep context bounded. If more than 5 are cited, pick the ones the question's own prose mentions.

**For `conversation` sources there may be no anchors at all.** That is normal. Skip the reads and compose from what is already in context. Do not go hunting the codebase for anchors the question never named.

If a ticket ID is present and the question genuinely needs the ticket thread, fetch it via the source adapter (`mcp__linear-server__get_issue` + `list_comments`, or `gh issue view --comments`). Fetch the **title** too — the ID + name rule needs it. Do not fetch by default.

### (b) Print the question block

Print this exact shape. It is the same for every question — the user should never have to work out what they are looking at.

```markdown
## Q<N>: <the question, in plain words>

**Why it matters** — <1–3 short sentences. One idea each. What this decision changes.>

**Where it matters**
- `<path>:<line>` — <what lives there>
- Phase <N> — <phase name>
- <TICKET-ID> — <ticket title>

**If we get this wrong** — <one line. Only when the downside is genuinely serious.>

## Your options

### Option 1: <short title> (Recommended)

<Two or three short sentences: what this means, what changes if we pick it.>

### Option 2: <short title>

<Two or three short sentences.>

### Option 3 (always last): Defer — keep open

<One line: leave this question open for now and decide later.>
```

Rules for the block:

- **`Why it matters` and `Where it matters` are always present.** No question skips them. This replaces the old variable "Why X / Why it could matter / Risk profile" analysis, which only fired on some questions and made the walk unpredictable.
- **`If we get this wrong` is optional.** Include it only when the downside is genuinely serious. Most questions do not get it. A risk line on every question trains the reader to ignore it.
- **Never invent a `Where it matters` anchor.** If the question is not tied to any file, phase, or ticket yet — common for `conversation` sources — write exactly:
  ```
  - Not tied to a specific file yet.
  ```
  Guessing a plausible-looking `path:line` is worse than admitting there is none.
- **Cite `path:line` for every concrete claim about code.**
- **Every ticket, ADR, PR, and phase carries its name**, per `planning-tools:plain-language`. `CI-21 — Add keyboard navigation`, not `CI-21`. If the title could not be fetched, write `CI-21 — (title unavailable)`.
- **Plain language throughout.** Short sentences, everyday words, one idea per sentence.

### (c) Hard cap at 4 alternatives

`AskUserQuestion` accepts at most 4 options. If the natural answer set exceeds 4:

- Consolidate near-identical alternatives (e.g. "retry once" and "retry three times" become "retry").
- Push lower-confidence alternatives into the Defer option's prose: "Defer. Also considered: foo, bar." The user can still pick those through the harness's free-text "Other" path.

### (d) Always include a "Defer — keep open" alternative

Defer is always the **last** option. With 3 real answers, Defer is the 4th. With 2, it is the 3rd. With only 1 obvious answer, present that as Option 1 and Defer as Option 2.

### (e) Call `AskUserQuestion`

**This call contains exactly one question — a single entry in the `questions` array.** Make the call only after *this* question's block has been printed, and before you read any evidence for the next one. One round-trip per question, always.

Pass the 2–4 alternatives as options:

- `label` = the alternative's short title (e.g. `"Leave on CreatedDate"`, `"Defer — keep open"`)
- `description` = one short sentence naming the tradeoff
- `multiSelect: false` always — one chosen answer per question.

If one alternative is Recommended, place it first and put `(Recommended)` in its label.

### (f) Capture the choice

Record the selection in an in-memory list:

```
{
  questionId:       "Q<N>",
  questionText:     "<full question text>",
  originalBullet:   "<original line in the source — plan-file sources only>",
  chosenLabel:      "<label of the option picked>",
  chosenDescription:"<description of that option>",
  freeTextOther:    "<text the user typed if they picked 'Other'; else empty>",
  deferred:         <true when the chosen label is the Defer path; else false>
}
```

Loop to the next question. Do not mutate anything yet.

---

## Step 6 — Summary, then a source-aware apply gate

When every question is walked, print the answers as a short plain-text list:

```
Answers for <source>:
  Q1 → Leave on CreatedDate
  Q2 → Also swap to SystemModstamp
  Q3 → Defer — keep open
```

What happens next depends on the source kind recorded in Step 1.

### `plan-file` — offer to write

Call `AskUserQuestion` with these three options:

- **Option 1 (recommended):** `"Apply <K> answers to <plan-path>"` — description: "Move the answered questions into Resolved Questions. Deferred ones stay open."
- **Option 2:** `"Show me the diff first"` — description: "Print the before/after for the two question sections, then ask again."
- **Option 3:** `"Discard"` — description: "Throw the answers away. The plan is untouched."

**Show-diff-first sub-flow:** compute the proposed before/after for both sections, print a unified diff (`diff -u` on two temp files, or a hand-rolled diff if `diff` is unavailable), then re-prompt with a binary `AskUserQuestion`: `"Apply <K> answers"` / `"Discard"`.

**Discard:** stop without writing.

### `report-file` and `conversation` — print and stop

**No apply gate at all.** There is nothing to write, so asking for approval would be noise. Print the summary above, then close with one line stating that nothing was written and where the questions came from:

```
Nothing written — these questions came from <the conversation | <report-path>>, not a master plan.
```

Then stop.

---

## Step 7 — Apply (plan-file sources only)

Only reached when the source kind is `plan-file` and the user approved. For each non-deferred answer:

### Remove from `## Open Questions`

- **List shape (v0.3.0+):** Edit using the question's `originalBullet` as `old_string` — the full `- **Q<N> — ...:**` line including all inline prose after the colon. If the bullet has indented continuation lines, include those in `old_string` so the whole question block is removed at once.
- **Legacy table shape (v0.2.x):** Edit using the question's table row as `old_string`, replacing it with an empty string.

### Append to `## Resolved Questions`

Find the `## Resolved Questions` heading. If it does not exist (it should, per the methodology), abort with a short error rather than inventing the section.

- **List shape:** append a bullet at the **end** of the section — immediately before the next `## ` heading, or at EOF:
  ```
  - **Q<N> — <question text>:** <chosenLabel>. <chosenDescription>. <freeTextOther if present>
  ```
- **Legacy table shape:** append a row with the question in the first cell and the resolution prose in the second.

Preserve all other plan content byte-for-byte. Do not normalize whitespace, do not reformat list markers, do not touch any section other than Open Questions and Resolved Questions.

---

## Step 8 — Report

One short closing summary, in plain language — the point first:

```
Answered <K> questions. <M> still open.
Written to <plan-path>.
```

If any were deferred, add: `Deferred: Q<N>, Q<M>.`

If everything was deferred: `No questions answered — all deferred. The plan is unchanged.`

For `report-file` and `conversation` sources, the closing line from Step 6 is the report. Nothing further.

---

## Mandatory Use of AskUserQuestion

All in the main conversation. Subagents never call it.

- **Step 1 Rung 4** — 3 options (`Point me at a file` / `I'll paste the questions` / `Cancel`), only when nothing resolved.
- **Step 5 per-question** — **one call per question, exactly one question per call**, walked sequentially. 2–4 single-select options, Defer always last. Never bundle multiple questions into one call, even though the tool accepts up to 4 per call.
- **Step 6 apply gate** — 3 options (`Apply` / `Show me the diff first` / `Discard`). **`plan-file` sources only** — never shown for `report-file` or `conversation` sources.
- **Show-diff-first sub-flow** — binary follow-up (`Apply` / `Discard`).

Two orthogonal caps apply: `[[askuserquestion-4option-cap]]` — never exceed 4 **options** per question; and (Step 5) exactly one **question** per call for this sequential walk.

## Strict no-modify rules

- This command **only ever** writes to the `## Open Questions` and `## Resolved Questions` sections of a resolved **master plan**. Every other section is preserved byte-for-byte.
- `report-file` and `conversation` sources are **read-only**. A scope report is never edited, and nothing is written when the questions came from the chat.
- It never modifies any other file (no `gh`, no Linear MCP writes, no commits, no `.gitignore`).
- It is **idempotent on no-op**: re-running on a fully-resolved plan exits cleanly with "No open questions".

## No subagent dispatch

This command calls no agent. All reads, evidence gathering, block composition, and alternative-generation happen in the main conversation. See `[[no-subagents-for-procedural-wrappers]]`.

## Notes

- For the canonical Open Questions / Resolved Questions shape in a master plan, see `planning-tools:master-plan-methodology` v0.3.0+.
- For how everything printed here should read, see `planning-tools:plain-language` — the single owner of the plain-language and ID + name rules.
- For branch + plan matching mechanics (Rung 3), this command lifts directly from `/planning-tools:plan-tick`.
- For the apply-gate UX, this command mirrors `/planning-tools:plan-progress`'s three-option gate.
- **Why the ladder starts in the conversation:** the earlier version required a git repo, a globbed plan file, and an `## Open Questions` heading before it would do anything. That made the command useless in the most common case — questions that a scope report or a worker agent just put on screen. Rung 2 fixes that; the filesystem is now the fallback, not the entry point.
