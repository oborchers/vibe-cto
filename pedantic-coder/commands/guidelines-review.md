---
description: Scan all CLAUDE.md files in the repository and check code for compliance with project-specific guidelines
disable-model-invocation: true
argument-hint: "[path-or-scope]"
---

Scan the repository for CLAUDE.md files and audit code compliance against the project's own documented guidelines.

Follow this process:

1. **Discover all CLAUDE.md files**: Use Glob with `**/CLAUDE.md` to find every CLAUDE.md file in the repository (or the scope provided as argument).

2. **Map the inheritance hierarchy**: Order the files from root to deepest nesting. Understand which directories each file's guidelines apply to.

3. **Read and parse each CLAUDE.md**: For each file:
   - Read the full content
   - Distinguish enforceable guidelines (naming rules, patterns, conventions, architecture boundaries) from informational content (build commands, project overview, architecture descriptions)
   - Note the scope: what directories and files does this CLAUDE.md govern?

4. **Invoke the guidelines-compliance skill**: Use `Skill("pedantic-coder:guidelines-compliance")` to load the full compliance checking methodology.

5. **For each CLAUDE.md scope, sample and check files**:
   - Select 3-5 representative files within each CLAUDE.md's scope
   - For each file, collect ALL applicable guidelines (walk up the ancestor chain)
   - Check the file against every applicable guideline
   - Record violations with the specific CLAUDE.md file and quoted rule

6. **Check for systemic patterns**:
   - Are there guidelines that are widely ignored? (rule exists but nobody follows it)
   - Are there guidelines that conflict between levels? (parent says X, child says Y)
   - Are there stale guidelines? (reference patterns, files, or commands that no longer exist)

7. **Report findings** in this structure:

   ### CLAUDE.md Hierarchy
   - List all CLAUDE.md files found with their scope

   ### Compliance by Scope
   For each CLAUDE.md:
   - **Guideline**: [quoted rule]
   - **Status**: Compliant / Partially violated / Widely violated
   - **Evidence**: file:line references for violations
   - **Fix**: what to change (in code or in the guideline)

   ### Conflicts
   - Parent/child guideline contradictions

   ### Stale Guidelines
   - Rules that reference nonexistent patterns, files, or commands

   ### Summary
   - Total guidelines found: N
   - Fully compliant: X
   - Violated: Y
   - Stale: Z
   - Verdict: Are the project's own rules being followed?

Focus on substance over style. The goal is to answer: "Does this codebase follow its own rules?" If not, either the code or the rules need to change.
