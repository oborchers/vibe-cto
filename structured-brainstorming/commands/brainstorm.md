---
description: "Brainstorm solutions for a problem using structured thinking methods — auto-selects effort tier (light/medium/heavy) based on complexity"
argument-hint: "<problem statement>"
---

Apply structured brainstorming to the given problem using the `structured-brainstorming` skill.

Follow this process:

1. **Restate the problem** to confirm understanding. If no problem statement was provided as an argument, ask the user to describe the problem.

2. **Assess complexity and auto-select a tier:**
   - **Light** (2-3 methods, inline): Clear scope, limited options, low stakes, or time-sensitive
   - **Medium** (4-5 methods, sequential): Multiple valid approaches, moderate-to-high stakes, unclear trade-offs
   - **Heavy** (parallel subagents, full exploration): Ambiguous, high-stakes, greenfield, touches multiple systems

3. **Present the tier selection** to the user: "I'd suggest **[tier]** for this problem because [reason]. Want to proceed, or prefer a different tier?"

4. **Execute the selected tier** following the process defined in the structured-brainstorming skill:
   - Light: Apply 2-3 methods inline, synthesize into a recommendation
   - Medium: Apply 4-5 methods sequentially with distinct sections, then converge
   - Heavy: Spawn `brainstorm-explorer` subagents in parallel with different method assignments, then synthesize

5. **Deliver results** in the standard output structure:
   - Problem restatement
   - Method application (labeled sections)
   - Convergence (agreement, disagreement, surprises)
   - Recommendation with trade-offs
   - Open questions

Consult the reference files in the structured-brainstorming skill for detailed method descriptions when applying each method.
