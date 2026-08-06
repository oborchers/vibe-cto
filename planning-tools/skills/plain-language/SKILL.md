---
name: plain-language
description: "This skill should be used whenever a planning-tools command prints something back to the user — the /plan-open-questions walkthrough, the /plan-master hand-off, the /plan-context scope report, the /plan-verify findings presentation, the /plan-progress chat summary, or any apply-gate summary. Single owner of two rules: (1) plain-language chat output, written for a reader who is skimming with low concentration; (2) the ID + name rule, which requires every external reference (ticket, ADR, PR) to carry its human name alongside its ID, everywhere including inside plan documents. Explicitly does NOT apply to the body of a master plan .md file (which stays detailed) or to progress entries posted to Linear / GitHub (which keep the dense style owned by progress-methodology)."
version: 0.1.0
---

# Plain Language

Planning documents are dense on purpose. **What gets printed into the conversation is not.**

This skill is the single owner of how `planning-tools` talks to the user. Every command references it; no command restates it.

## Two rules, two different scopes

| Rule | Applies to |
|---|---|
| **Plain language** | Chat output only — anything a `/plan-*` command prints into the conversation |
| **ID + name** | Everywhere — chat output *and* the body of plan documents |

---

## Rule 1 — Plain language (chat output only)

### Where it applies

Everything a `/plan-*` command prints into the conversation:

- The per-question blocks in `/planning-tools:plan-open-questions`
- The hand-off summary at the end of `/planning-tools:plan-master`
- The scope report from `/planning-tools:plan-context`
- The presentation of verifier findings in `/planning-tools:plan-verify`
- The chat summary around `/planning-tools:plan-progress`
- Every apply-gate summary and every `AskUserQuestion` option label and description

### Where it does NOT apply

- **The body of a master plan `.md` file.** Plans stay detailed, precise, and citation-heavy. `master-plan-methodology` owns that format. Do not shorten a plan to satisfy this skill.
- **Progress entries posted to Linear or GitHub.** These keep the dense-paragraph style owned by `progress-methodology`. Only the chat summary wrapped around them follows this skill.

### The writing rules

Assume the reader is skimming with low concentration. They will read the first sentence of each block and stop if it does not land.

1. **One idea per sentence.** If a sentence has an "and" joining two ideas, split it.
2. **Short sentences.** Aim for under 20 words. A long sentence is a rewrite, not a style choice.
3. **Everyday words over jargon.** Say "runs first" not "is evaluated eagerly". Say "we cannot tell yet" not "the verdict is indeterminate".
4. **Expand an acronym the first time it appears in a block.** Not once per document — once per block, because the reader may only read that block.
5. **Lead with the point, then the detail.** The first sentence answers the question. The rest supports it.
6. **No nested clauses, no stacked qualifiers.** Strip "generally", "typically", "in most cases" unless the exception is real and named.
7. **Each block stands alone.** A reader who skipped the block above must still understand this one.
8. **Concrete over abstract.** Name the file, the phase, the ticket, the person. "The auth helper" is worse than "`_shared/auth.ts`".

### Good / bad

**Bad** — one long sentence, three ideas, jargon, no anchor:

> Given that the existing discriminator is effectively the bare HTTP status, which conflates auth-gate failures with upstream-relayed rejections, resolving this question determines whether downstream consumers can reliably differentiate genuine session expiry, which in turn gates the modal-vs-toast decision.

**Good** — short sentences, one idea each, concrete:

> Right now we only look at the HTTP status code. That means a real session expiry and an upstream error look identical. Until we can tell them apart, the app cannot decide whether to show the modal or a toast.

---

**Bad** — hedged and abstract:

> This may potentially impact a number of components, generally in the frontend layer, and could conceivably require some follow-up work.

**Good** — names the thing, states the cost:

> This changes two files: `src/features/session/modal.tsx` and `src/lib/session-errors.ts`. Phase 4 has to be rewritten if we pick option 2.

---

**Bad** — a wall with no entry point:

> Resolved 4 open questions in context/tickets/CI-21-PLAN.md, 2 remain, of which 1 was deferred and 1 was added during the walkthrough, and the Resolved Questions section now contains 9 entries total.

**Good** — the point first, the detail after:

> Answered 4 questions. 2 are still open — Q3 (deferred) and Q7 (new).
> Written to `context/tickets/CI-21-PLAN.md`.

---

## Rule 2 — ID + name (everywhere, including plan documents)

Every external reference carries its **ID and its human name** on first mention in a block. An ID alone forces the reader to go look it up. That is exactly the cost this rule removes.

### Formats

| Reference type | Shape | Example |
|---|---|---|
| Ticket (Linear, Jira, GitHub issue) | `<ID> — <title>` | `CI-21 — Add keyboard navigation` |
| ADR | `ADR-<NN>: <title>` | `ADR-28: Session error taxonomy` |
| Pull request | `PR #<N> — <title>` | `PR #412 — Fix locale fallback` |
| Phase inside a plan | `Phase <N> — <phase name>` | `Phase 3 — Wire MutationCache.onError` |

Markdown links keep the same content: `[CI-21 — Add keyboard navigation](../CI-21-PLAN.md)`.

### When the name is not available

**Never emit a bare ID silently.** If the title cannot be fetched — the Linear MCP is not loaded, `gh` is unavailable, the ticket is in another workspace — say so:

```
CI-21 — (title unavailable)
```

The reader then knows the name is missing, rather than assuming there never was one.

### First mention per block

The rule is per block, not per document. A reader who jumps straight to Phase 5 must still see the name there. Repeating `CI-21 — Add keyboard navigation` in three different sections is correct, not redundant.

### Good / bad

- ❌ `Depends on: CI-22`
- ✅ `Depends on: CI-22 — Salesforce link helpers (`src/features/cases/lib/sf-links.ts`, i18n key, ADR-28: Session error taxonomy amendment)`

- ❌ `Blocked by ADR-15 and ADR-34.`
- ✅ `Blocked by ADR-15: Edge function boundaries and ADR-34: Locale fallback order.`

- ❌ `Ships in #412.`
- ✅ `Ships in PR #412 — Fix locale fallback.`

### Where it is checked

`/planning-tools:plan-verify` audits plan documents for this rule. A reference with no human name is a **Suggestion** — never Important, never Critical. It never blocks a PASS verdict. See `planning-tools:plan-verification-checklist` dimension 13.

Chat output is not audited. Follow the rule anyway.

---

## Single-owner note

Other skills and commands **reference** this skill; they do not restate its rules.

- `planning-tools:master-plan-methodology` points here for reference naming, and keeps full ownership of the plan document format.
- `planning-tools:plan-verification-checklist` points here for the definition of the rule it audits.
- `planning-tools:progress-methodology` keeps full ownership of the dense progress-entry style. This skill does not override it.
