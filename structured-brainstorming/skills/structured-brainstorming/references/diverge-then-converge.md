# Diverge-then-Converge

## What It Is

Explicitly separate idea generation (divergence) from idea evaluation (convergence) into two distinct phases. During divergence, quantity matters more than quality. During convergence, apply criteria systematically.

**Counteracts:** Premature convergence. RLHF training optimizes LLMs to produce "the right answer" immediately. This kills exploration — the model evaluates and filters ideas before they are fully formed. Diverge-then-converge forces generation to happen without the evaluation filter.

## Why LLMs Need This Most

This method addresses one of the strongest biases in RLHF-trained LLMs. The core problem:

1. LLMs are trained to produce high-quality responses (RLHF/Constitutional AI)
2. "High-quality" during training means polished, balanced, and converged
3. This training actively suppresses raw idea generation
4. The result: LLMs generate 5 ideas that are really 1 idea with 5 phrasings

Diverge-then-converge works by making the two phases explicit and sequential, with a hard boundary between them.

## Step-by-Step Process

### Phase 1: Diverge

**Rules during divergence:**
- Generate at least N ideas (set N before starting — minimum 7, ideally 10+)
- No evaluation, no "but," no "however," no ranking
- Deliberately include ideas that seem impractical, naive, or unconventional
- Each idea must be structurally different from the others (not just a parameter change)
- One sentence per idea is enough — detail comes later

**Divergence prompts:**
- "List 10 fundamentally different ways to solve this."
- "Include at least 2 ideas that seem impractical or unconventional."
- "Each idea must use a different core mechanism than the others."
- "What would a [beginner / expert in another field / contrarian] suggest?"

**Quality check for divergence:** If all ideas could be plotted on a single axis (e.g., "more caching" to "less caching"), the ideas are variations, not alternatives. True divergence produces ideas that live in different dimensions.

### Phase 2: Converge

**Rules during convergence:**
- Define evaluation criteria BEFORE evaluating (not after, to prevent post-hoc rationalization)
- Score each idea against each criterion independently
- Do not discard any idea without explicit reasoning

**Convergence process:**
1. Define 3-5 evaluation criteria relevant to the problem (e.g., implementation complexity, time-to-market, scalability, maintainability, risk)
2. Score each idea against each criterion (simple: High/Medium/Low or 1-5)
3. Identify the top 2-3 ideas based on scores
4. For the top ideas, develop them further with more detail
5. Compare the developed ideas and select or combine

**Convergence prompts:**
- "What criteria matter most for this decision?"
- "Score each idea against [criterion] independently."
- "Which 3 ideas score highest overall? Develop those."
- "Can any of the top ideas be combined?"

## The Hard Boundary

The boundary between phases is critical. Techniques to enforce it:

- **Explicit announcement:** "DIVERGENCE PHASE — generating ideas without evaluation." Then later: "CONVERGENCE PHASE — now evaluating."
- **Quantity mandate:** Do not proceed to convergence until N ideas exist.
- **Structural check:** Before converging, verify that ideas are structurally different, not variations.

## Common Pitfalls

- **Evaluating during divergence.** The most common failure. Phrases like "a good option would be..." or "the best approach is..." during divergence indicate premature convergence. During divergence, the only goal is quantity and diversity.
- **Insufficient divergence quantity.** 3-4 ideas is not enough. The first 4-5 ideas are usually conventional. Genuinely creative ideas appear at position 7+, after the obvious ones are exhausted.
- **Converging without criteria.** Evaluating based on "gut feel" reintroduces the biases this method is designed to counteract. Define criteria first.
- **Discarding without reasoning.** Every idea eliminated during convergence needs an explicit reason tied to a criterion. "It doesn't feel right" is not a reason.

## When to Use

- Any "what should we build?" or "how should we approach this?" question
- When the first proposed solution feels "too obvious"
- When multiple stakeholders have different preferences (diverge first, then converge on shared criteria)
- Ideation sessions where creativity matters
- Any problem where the cost of missing a good option exceeds the cost of exploring more options
