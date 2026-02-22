---
description: Review the current code for pedantic violations — naming, casing, symmetry, ordering, consistency, dead code, and every small detail that matters
disable-model-invocation: true
---

Review the code currently being worked on against the pedantic-coder principles.

Follow this process:

1. Identify which pedantic areas are relevant to the current context (naming, casing, imports, structure, etc.)
2. For each relevant area, invoke the corresponding pedantic-coder skill
3. Evaluate the current code against each skill's review checklist
4. If the code is in Python, TypeScript, or Go, also invoke the corresponding language pack skill
5. Report findings organized by principle, using this format for each:

**[Principle Name]**
- Violations found (with specific file/line references)
- What to fix and how
- Items that already comply

6. Provide a summary with:
   - Total violations count by severity (critical / important / nitpick)
   - Top 3 most impactful fixes to make first
   - Overall pedantry score (pristine / clean / acceptable / messy / catastrophic)

Focus on concrete, specific violations. Every finding must reference the exact principle being violated. No vague "consider improving" — state what is wrong and what the fix is.
