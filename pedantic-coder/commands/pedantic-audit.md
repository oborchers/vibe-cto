---
description: Audit an entire repository for pedantic violations — systematically scans the codebase for naming, casing, symmetry, ordering, consistency, and structural issues
disable-model-invocation: true
argument-hint: "[path-or-scope]"
---

Perform a comprehensive pedantic audit of the entire repository (or the scope provided as argument).

Follow this process:

1. **Discover the codebase**: Use Glob and Read to understand the repository structure:
   - Identify primary language(s) used
   - Map the directory structure and module boundaries
   - Count total source files by language/extension
   - Identify configuration files, entry points, and key modules

2. **Sample strategically**: You cannot read every file. Sample 15-25 representative files:
   - Entry points and main modules (always include)
   - Configuration/settings files (always include)
   - 2-3 files from each major directory/module
   - Any files that define shared patterns (base classes, utilities, constants, types)
   - Prefer files that other files import from — these set conventions

3. **Establish the codebase's conventions**: Before flagging violations, identify what conventions the codebase already uses:
   - What casing convention is dominant?
   - How are imports organized?
   - What patterns are established for config, errors, validation?
   - What naming conventions exist for files, classes, functions?
   - Document these as "established conventions" in your report

4. **For each relevant pedantic principle**, invoke the corresponding pedantic-coder skill and audit the sampled files:
   - Naming Precision — scan for vague identifiers across the codebase
   - Casing Law — check for mixed conventions across files
   - Import Discipline — compare import ordering across multiple files
   - Declaration Order — check if files follow a consistent shape
   - Symmetry — compare parallel modules (services, handlers, models) for structural consistency
   - One Pattern, One Way — identify where multiple patterns exist for the same problem
   - Magic Value Elimination — grep for inline literals that should be constants
   - Dead Code Intolerance — scan for commented-out blocks, unused imports, stale TODOs

5. **Check language-specific pedantry**: Invoke the Python, TypeScript, or Go language pack skill as applicable.

6. **Report findings** in this structure:

   ### Codebase Overview
   - Languages, structure, total files, files sampled

   ### Established Conventions
   - What the codebase does consistently (acknowledge what's right)

   ### Findings by Principle
   For each principle with violations:
   - **[Principle Name]** — X violations across Y files
   - Specific examples with file:line references
   - Whether this is a codebase-wide pattern or isolated incidents
   - The fix (show before/after for representative cases)

   ### Codebase-Wide Patterns
   - Systemic issues that affect multiple files/modules
   - Convention conflicts (where the codebase disagrees with itself)

   ### Summary
   - Severity counts: Critical / Important / Nitpick
   - Top 5 highest-impact improvements (repo-wide, not per-file)
   - Overall pedantry score: pristine / clean / acceptable / messy / catastrophic
   - One-paragraph verdict

Focus on codebase-wide patterns over individual file issues. The goal is to identify systemic inconsistencies and establish a path to a pristine codebase.
