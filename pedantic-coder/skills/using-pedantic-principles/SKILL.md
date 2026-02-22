---
name: using-pedantic-principles
description: This skill should be used when the user asks "which pedantic skill should I use", "show me all code quality principles", "help me pick a code style rule", or at the start of any code review, refactoring, or greenfield project. Provides the index of all principle skills and the three language pack skills.
version: 1.0.0
---

<IMPORTANT>
When writing, reviewing, or refactoring any code — naming identifiers, organizing imports, structuring files, establishing patterns, or cleaning up inconsistencies — invoke the relevant pedantic-coder skill BEFORE proceeding.

These are not suggestions. They are non-negotiable standards for code that respects the reader. Your code works? Great. Now make it right.
</IMPORTANT>

## How to Access Skills

Use the `Skill` tool to invoke any skill by name. When invoked, follow the skill's guidance directly.

## Universal Principles

These apply to every language, every codebase, every commit.

| Skill | Triggers On |
|-------|-------------|
| `pedantic-coder:naming-precision` | Variable names, function names, class names, file names, semantic accuracy, vague identifiers like `data`, `temp`, `result`, `handle` |
| `pedantic-coder:casing-law` | PascalCase, camelCase, snake_case, UPPER_SNAKE — mixed conventions, inconsistent casing across a codebase |
| `pedantic-coder:abbreviation-policy` | Shortened names, acronyms, inconsistent abbreviations (`btn` vs `button`, `msg` vs `message`), abbreviation rules |
| `pedantic-coder:boolean-naming` | Boolean variables, predicate functions, `is/has/can/should` prefixes, negative booleans, flag naming |
| `pedantic-coder:import-discipline` | Import statements, require calls, use declarations, import ordering, grouping, sorting, circular dependencies |
| `pedantic-coder:declaration-order` | File structure, member ordering in classes/structs, constant placement, export ordering, predictable file shape |
| `pedantic-coder:symmetry` | Parallel code paths, matching pairs (create/delete, open/close), consistent function signatures, structural mirroring |
| `pedantic-coder:one-pattern-one-way` | Inconsistent approaches to the same problem, mixed paradigms, local shortcuts that break codebase conventions |
| `pedantic-coder:magic-value-elimination` | Inline string literals, unexplained numbers, hardcoded values that should be named constants or enums |
| `pedantic-coder:dead-code-intolerance` | Commented-out code, unused imports, unreachable branches, TODO/FIXME comments, historical comments about removed code |
| `pedantic-coder:visual-rhythm` | Whitespace usage, blank line placement, consistent spacing between logical sections, code as prose |

## Project Guidelines

Enforce the project's own rules, not just ours.

| Skill | Triggers On |
|-------|-------------|
| `pedantic-coder:guidelines-compliance` | Checking code against CLAUDE.md guidelines, reviewing project convention compliance, auditing a repository's own documented rules, CLAUDE.md inheritance hierarchy |

## Language Packs

For language-specific pedantry that goes beyond universal principles.

| Skill | Triggers On |
|-------|-------------|
| `pedantic-coder:python-pedantry` | Python type hints (`str \| None` vs `Optional`), Pydantic settings, StrEnum, exception chaining, Google docstrings, ruff rules |
| `pedantic-coder:typescript-pedantry` | TypeScript strict mode, discriminated unions, Zod schemas, barrel exports, `as const`, ESLint strict rules |
| `pedantic-coder:go-pedantry` | Go error wrapping, interface design, package naming, struct field ordering, receiver naming, `golangci-lint` rules |

## When to Invoke Skills

Invoke a skill when there is even a small chance the work touches one of these areas:

- Writing any new code (naming, structure, patterns need to be right from the start)
- Reviewing or refactoring existing code (find and fix every inconsistency)
- Establishing project conventions (set the standard before others contribute)
- Onboarding to a new codebase (understand what patterns exist and enforce them)
- Any code that will be read by another human (all code)

## The Three Meta-Principles

All principles rest on three foundations:

1. **Consistency is non-negotiable** — One way. Everywhere. Always. A codebase that mixes conventions is a codebase that nobody trusts.

2. **If it looks wrong, it is wrong** — Visual disorder signals logical disorder. Code that is hard to scan is hard to maintain. The shape of your code communicates as much as the logic.

3. **Every detail is a decision** — Nothing is "just a style choice." Every abbreviation, every import order, every blank line either reinforces or undermines the codebase's integrity.
