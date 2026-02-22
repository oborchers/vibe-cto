---
name: guidelines-compliance
description: "This skill should be used when the user asks to check code against CLAUDE.md guidelines, review compliance with project conventions, audit a repository's own rules, verify CLAUDE.md inheritance, or when performing a comprehensive pedantic audit that should include project-specific rules. Covers the CLAUDE.md inheritance model, directory walk-up algorithm, parsing guidelines vs informational content, and systematic compliance checking."
version: 1.0.0
---

# Your Rules, Enforced

Pedantic principles are universal. But every project also has its own rules — captured in CLAUDE.md files scattered across the repository. These files form an inheritance hierarchy, and every line of code must comply with every applicable guideline in its ancestor chain.

A pristine codebase follows both universal principles AND its own documented rules. This skill teaches you how to find, parse, and enforce project-specific guidelines.

## The CLAUDE.md Inheritance Model

CLAUDE.md files follow a directory-scoped inheritance model:

- **Root `CLAUDE.md`** applies to every file in the repository
- **Nested `CLAUDE.md`** (e.g., `src/CLAUDE.md`) adds rules on top of its parent — it does NOT replace them
- **Deeper nesting** (e.g., `src/features/auth/CLAUDE.md`) adds more rules on top of both ancestors

Rules are **additive**. A file at `src/features/auth/LoginForm.tsx` must follow:
1. Root `CLAUDE.md` (project-wide conventions)
2. `src/CLAUDE.md` (source code conventions, if it exists)
3. `src/features/auth/CLAUDE.md` (auth-specific conventions, if it exists)

There is no override mechanism. If the root says "use snake_case" and a nested file says "use PascalCase for components," both rules apply in their respective contexts. If they genuinely conflict, that is a bug in the CLAUDE.md hierarchy — flag it.

## The Directory Walk-Up Algorithm

To find all applicable CLAUDE.md files for a given source file:

1. Start at the file's directory
2. Check if a `CLAUDE.md` exists in that directory
3. Move one directory up
4. Repeat until you reach the repository root
5. Always include the root `CLAUDE.md` if it exists
6. Deduplicate and order from root (broadest) to deepest (most specific)

For a file at `src/features/auth/components/LoginForm.tsx`, the walk produces:

```
CLAUDE.md                              ← root (project-wide)
src/CLAUDE.md                          ← source conventions (if exists)
src/features/CLAUDE.md                 ← feature conventions (if exists)
src/features/auth/CLAUDE.md            ← auth conventions (if exists)
src/features/auth/components/CLAUDE.md ← component conventions (if exists)
```

Most repositories will have 1-3 CLAUDE.md files. Some well-structured monorepos may have more.

## Discovering CLAUDE.md Files

When auditing a repository, find all CLAUDE.md files first:

```
# Find all CLAUDE.md files in the repo
Glob pattern: **/CLAUDE.md
```

Map the hierarchy. Common patterns:

| Location | Typical Content |
|----------|----------------|
| `CLAUDE.md` (root) | Build commands, test commands, project structure, global conventions, architecture overview |
| `src/CLAUDE.md` | Source code conventions, import rules, naming patterns, component patterns |
| `src/features/*/CLAUDE.md` | Feature-specific patterns, data models, API contracts |
| `tests/CLAUDE.md` | Test conventions, mocking patterns, fixture rules |
| `scripts/CLAUDE.md` | Script conventions, deployment rules |
| `docs/CLAUDE.md` | Documentation conventions, formatting rules |

## Parsing Guidelines vs Information

Not everything in a CLAUDE.md is an enforceable rule. Distinguish:

**Enforceable guidelines** — statements that prescribe HOW code should be written:
- "Use snake_case for all Python files"
- "Every component must have a corresponding test file"
- "Import order: stdlib, third-party, internal"
- "Never use `any` in TypeScript"
- "All API endpoints must return the standard error envelope"
- Sections titled "Conventions", "Rules", "Standards", "Guidelines", "Style"

**Informational content** — context that helps you understand the project but doesn't prescribe behavior:
- "This project uses React 18 with TypeScript"
- "The database is PostgreSQL hosted on Supabase"
- "CI runs on GitHub Actions"
- Architecture overviews, directory descriptions, build commands
- Sections titled "Overview", "Architecture", "Getting Started", "Commands"

When in doubt, treat it as a guideline. Better to flag a potential violation than to miss one.

## Compliance Checking Process

### For a targeted review (specific files):

1. Identify the files being reviewed
2. For each file, walk up the directory tree to collect all applicable CLAUDE.md files
3. Read each CLAUDE.md from root to deepest
4. Extract enforceable guidelines
5. Check the code against each guideline
6. Report violations with the specific CLAUDE.md file and rule referenced

### For a repository audit:

1. Find all CLAUDE.md files in the repo (`**/CLAUDE.md`)
2. Read each one and extract enforceable guidelines
3. Map which guidelines apply to which directories
4. Sample representative files from each directory scope
5. Check sampled files against their applicable guidelines
6. Identify systemic violations (rules that are widely ignored)
7. Identify guideline conflicts (nested CLAUDE.md files that contradict parents)
8. Report findings organized by CLAUDE.md scope

## What to Check

### Convention compliance
- Naming conventions specified in CLAUDE.md — are they followed everywhere?
- Import ordering rules — does every file follow them?
- File structure rules — do new files follow the documented patterns?
- Architecture boundaries — do imports respect the documented module boundaries?

### Pattern consistency
- If CLAUDE.md says "use pattern X for Y," search for all instances of Y and verify they use pattern X
- If CLAUDE.md documents a standard error handling approach, check that all error handling matches
- If CLAUDE.md specifies test patterns, check that all tests follow them

### Structural compliance
- File placement: do new files live where CLAUDE.md says they should?
- Module boundaries: do imports cross boundaries that CLAUDE.md says should be isolated?
- Export patterns: do modules export according to CLAUDE.md conventions?

### Staleness detection
- Are there guidelines that reference patterns no longer in the codebase?
- Are there directories documented in CLAUDE.md that no longer exist?
- Are there build commands in CLAUDE.md that no longer work?
- Flag stale guidelines — they erode trust in the documentation

## Report Format

```
### Guidelines Compliance Report

**CLAUDE.md files found**: [list with paths]

#### [CLAUDE.md path] — [X violations, Y files checked]

**Guideline**: "[quoted rule from CLAUDE.md]"
**Status**: Violated in N files / Followed in M files
**Examples**:
- `path/to/file.py:42` — [specific violation]
- `path/to/other.py:17` — [specific violation]
**Fix**: [what to change]

#### Guideline Conflicts
- [Root CLAUDE.md says X, src/CLAUDE.md says Y — which applies?]

#### Stale Guidelines
- [CLAUDE.md references pattern/directory/command that no longer exists]

#### Summary
- Total guidelines checked: N
- Fully compliant: X
- Partially compliant: Y (followed in some files, violated in others)
- Widely violated: Z
- Stale/outdated: W
```

## Good vs Bad Compliance Reviews

**Bad — vague and unjustified:**
```
The code doesn't follow project conventions in some places.
Consider reviewing the CLAUDE.md for guidance.
```

**Good — specific, traced to source:**
```
CLAUDE.md (root) states: "All Python files use Google-style docstrings."
Violated in 4 of 12 sampled files:
- src/services/auth.py:23 — missing docstring on public function `verify_token`
- src/services/auth.py:45 — NumPy-style docstring instead of Google-style
- src/models/user.py:12 — missing Args section in `create_user` docstring
- src/utils/crypto.py:8 — no docstring on module-level function `hash_password`
```

## Examples

Working examples in `examples/`:
- **`examples/claude-md-inheritance.md`** — Multi-level CLAUDE.md hierarchy showing how rules accumulate and how to check files at different depths

## Review Checklist

When checking guidelines compliance:

- [ ] All CLAUDE.md files in the repo have been discovered (use `**/CLAUDE.md` glob)
- [ ] CLAUDE.md files are read in inheritance order (root first, deepest last)
- [ ] Enforceable guidelines are distinguished from informational content
- [ ] Each guideline is checked against representative files in its scope
- [ ] Violations reference the specific CLAUDE.md file and quoted rule
- [ ] Systemic violations (widely ignored rules) are called out separately from isolated ones
- [ ] Conflicting guidelines between CLAUDE.md levels are flagged
- [ ] Stale guidelines (referencing nonexistent patterns/files/commands) are flagged
- [ ] The report shows both violations and compliance (acknowledge what's right)
- [ ] Fixes are specific and actionable — not "review the guidelines"
