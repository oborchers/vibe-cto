# Perspective Forcing

## What It Is

Systematically evaluate a problem from multiple stakeholder viewpoints, forcing analysis beyond the default "helpful assistant" perspective. Adapted from de Bono's Six Thinking Hats and rolestorming, but with perspectives relevant to software engineering.

**Counteracts:** Single perspective. LLMs default to one voice — the knowledgeable, balanced, helpful advisor. This suppresses genuinely critical, creative, or user-empathetic thinking. Perspective forcing makes each viewpoint explicit and gives it space to develop fully.

## The Six Software Perspectives

| Perspective | Role | Asks | Tendency |
|-------------|------|------|----------|
| **End User** | The person using the product | "Is this simple? Does it solve my actual problem?" | Empathy, simplicity, frustration points |
| **Operator** | The person running it in production | "Can I deploy, monitor, debug, and scale this?" | Operability, observability, failure recovery |
| **Critic** | The skeptic, the devil's advocate | "What's wrong with this? Where will it break?" | Risk, fragility, hidden assumptions |
| **Optimist** | The champion, the builder | "What's the best-case outcome? What enables growth?" | Opportunity, velocity, morale |
| **Creative** | The lateral thinker | "What if we approached this completely differently?" | Unconventional approaches, novel combinations |
| **Business** | The stakeholder paying for it | "What's the ROI? What's the opportunity cost?" | Cost, timeline, strategic alignment |

## Step-by-Step Process

1. **State the problem or proposed solution clearly.**
2. **Adopt each perspective in sequence.** Spend at least 3-4 sentences per perspective. Do not hedge or balance — commit fully to the viewpoint.
3. **For each perspective, identify:**
   - What looks good from this viewpoint
   - What looks bad or risky
   - What this perspective would change about the proposal
4. **Note contradictions between perspectives.** Where the End User wants simplicity but the Operator wants configurability. Where the Critic sees risk but the Optimist sees opportunity.
5. **Synthesize.** Which perspectives revealed something the default analysis missed? What design changes address the strongest objections?

## Application Prompts

- **End User:** "Walk me through what the actual user experience is. Where do they get confused? Where do they wait?"
- **Operator:** "It's 3 AM, this is broken, and I just got paged. What do I see? What tools do I have? How long does recovery take?"
- **Critic:** "What's the weakest part of this design? What will we regret in 12 months?"
- **Optimist:** "If everything goes well, what does this enable that wasn't possible before?"
- **Creative:** "Forget everything we've discussed. What's a completely different way to solve the underlying problem?"
- **Business:** "If I'm the CTO and you're asking me to fund this, what's your pitch? What's the alternative and why is this better?"

## Common Pitfalls

- **Doing all perspectives in one paragraph.** Each perspective needs space to develop. A one-sentence "the user might find it confusing" is not perspective forcing — it's a footnote. Commit to each role.
- **Balancing within a perspective.** When wearing the Critic hat, do not add "but on the other hand..." — save that for the synthesis. The value is in committing fully to each viewpoint.
- **Skipping the Creative perspective.** This is the hardest one for LLMs because it requires generating unconventional ideas. It is also the most valuable when the problem is stuck in conventional thinking.
- **Not synthesizing.** Raw perspectives without synthesis are just noise. The value comes from identifying which perspectives revealed blind spots and what to do about them.

## When to Use

- Evaluating a design proposal that "seems fine" but feels incomplete
- Multi-stakeholder decisions where different groups have different priorities
- When the user asks "what am I missing?"
- Before presenting a recommendation (run perspectives first, then recommend)
- Any design review or architecture discussion
