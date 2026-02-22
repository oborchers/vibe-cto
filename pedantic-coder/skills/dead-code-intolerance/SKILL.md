---
name: dead-code-intolerance
description: "This skill should be used when the user's code contains commented-out code blocks, unused imports, unreachable branches, TODO/FIXME comments that have been sitting for more than a day, or comments referencing removed functionality. Covers the elimination of dead code and the rule that version control remembers so you don't have to."
version: 1.0.0
---

# If It Is Not Executing, It Is Not Code -- It Is Noise

Dead code is not harmless. It is actively harmful. It confuses new developers who do not know whether it is intentional. It gets updated during refactors by people who do not realize it is unused. It triggers false positives in grep and IDE searches. It creates the illusion of complexity where none exists. And it tells every reader: "The author of this codebase does not clean up after themselves."

Version control exists. Git remembers everything. You do not need to.

Delete it.

## Commented-Out Code: Never

Commented-out code is not "kept for reference." It is not "just in case." It is not "might need later." It is dead weight that tells the reader nothing useful and everything bad. If you need the old implementation, `git log` has it. If you need to compare approaches, create a branch. If you think you might need it tomorrow, you will not. And if you do, `git log` still has it.

**Zero exceptions.** Not even one line. Not even "temporarily." The moment code is commented out, it starts rotting -- the surrounding code evolves, the commented code does not, and within a week it no longer works anyway.

```python
# BAD -- every one of these must be deleted
# user = get_user(user_id)
# if user.is_admin:
#     return admin_dashboard()

# Old implementation (keeping for reference)
# def calculate_tax(amount):
#     return amount * 0.08

# Commented out until we fix the race condition
# await sync_inventory()
```

```python
# GOOD -- the code that exists is the code that runs. Nothing else.
user = get_user(user_id)
if user.is_admin:
    return admin_dashboard()
```

## Unused Imports: Delete Immediately

An unused import is a lie. It tells the reader "this module is used here" when it is not. It increases startup time. It creates false dependency graphs. And "but I might need it later" is what autocomplete is for.

```typescript
// BAD -- three of these imports are unused
import { useState, useEffect, useCallback, useMemo, useRef } from "react";
import { format } from "date-fns";
import { clsx } from "clsx";

function Counter() {
  const [count, setCount] = useState(0);  // only useState is used
  return <button onClick={() => setCount(count + 1)}>{count}</button>;
}
```

```typescript
// GOOD -- import exactly what you use
import { useState } from "react";

function Counter() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(count + 1)}>{count}</button>;
}
```

```python
# BAD -- os and sys are unused
import os
import sys
from datetime import datetime, timedelta

def days_until(target: datetime) -> int:
    return (target - datetime.now()).days
```

```python
# GOOD
from datetime import datetime

def days_until(target: datetime) -> int:
    return (target - datetime.now()).days
```

## Unreachable Branches: Delete

Code that can never execute is not a safety net. It is a hallucination. `if (false)`, debug flags that are never set, catch blocks for exceptions that cannot be thrown, default cases in exhaustive switches -- if the runtime will never reach it, the reader should never see it.

```go
// BAD -- DEBUG is a compile-time constant set to false
const DEBUG = false

func processRequest(req *Request) {
    if DEBUG {
        log.Printf("Processing: %+v", req)  // unreachable
    }
    // ...
}
```

```go
// GOOD -- if you need debug logging, use a proper logging framework with levels
func processRequest(req *Request) {
    slog.Debug("processing request", "request_id", req.ID)
    // ...
}
```

```typescript
// BAD -- the type system guarantees status is "active" | "inactive"
function handleStatus(status: "active" | "inactive") {
  switch (status) {
    case "active":
      return activate();
    case "inactive":
      return deactivate();
    default:
      // This can never execute. TypeScript knows it. You know it. Delete it.
      throw new Error("Unknown status");
  }
}
```

```typescript
// GOOD -- exhaustive switch, no dead default
function handleStatus(status: "active" | "inactive") {
  switch (status) {
    case "active":
      return activate();
    case "inactive":
      return deactivate();
  }
  // TypeScript's exhaustiveness checking handles the rest
  const _exhaustive: never = status;
}
```

## TODO/FIXME: Do It Now or Create an Issue and Delete the Comment

TODO comments are where good intentions go to die. They sit in the codebase for months. Years. They reference tickets that were closed long ago. They describe bugs that were fixed in a different way. They accumulate until searching for TODO returns 400 results and nobody reads any of them.

The rule is simple: either fix it right now, or create a tracked issue in your project management tool and delete the comment. A TODO without a linked ticket is an untracked bug. An untracked bug is a bug that will never be fixed.

```python
# BAD -- these TODOs are never getting done
# TODO: optimize this query
results = db.query("SELECT * FROM users")

# FIXME: handle edge case where amount is negative
total = sum(amounts)

# TODO(john): refactor this when we migrate to v2
# (John left the company 8 months ago)
```

```python
# GOOD -- the code is clean, the issue tracker has the work items
results = db.query("SELECT id, email, name FROM users WHERE is_active = true")

total = sum(amount for amount in amounts if amount >= 0)
```

## Historical Comments: These Are Git Commit Messages, Not Code

Comments that describe what the code used to do, what was previously tried, or what was removed are git commit messages that someone pasted into the wrong place. The code describes what it does now. The history of what it used to do belongs in version control.

```typescript
// BAD -- none of this helps the reader understand the current code
// This used to be configurable but we hardcoded it in Q3
const TIMEOUT_MS = 5000;

// We removed the old validation because it was too slow
// (see commit abc123 for the original implementation)
function validateInput(input: string): boolean {
  return input.length > 0 && input.length <= 1000;
}

// Was previously using Redis but switched to in-memory cache
const cache = new Map<string, CacheEntry>();
```

```typescript
// GOOD -- the code says what it does. Git says why it changed.
const TIMEOUT_MS = 5000;

function validateInput(input: string): boolean {
  return input.length > 0 && input.length <= 1000;
}

const cache = new Map<string, CacheEntry>();
```

## Dead Feature Flags: Remove After Rollout

A feature flag that has been at 100% rollout for more than one sprint is dead code in disguise. The flag check, the old code path, and the configuration all need to go. Feature flags are for safe rollouts, not permanent architecture.

```python
# BAD -- this flag has been 100% for six weeks
def get_pricing(user: User) -> PricingPlan:
    if feature_flags.is_enabled("new_pricing_engine", user):
        return new_pricing_engine.calculate(user)
    else:
        # Nobody has hit this branch since November
        return legacy_pricing.calculate(user)
```

```python
# GOOD -- the flag is removed, the old path is deleted
def get_pricing(user: User) -> PricingPlan:
    return pricing_engine.calculate(user)
```

## Unused Functions and Classes: Delete

If nothing calls it and nothing imports it, it does not exist. It just has not been deleted yet. "But someone might need it" is not a reason to keep code. It is a reason to have good git history. Unused code costs you in every refactor, every search, every onboarding.

```go
// BAD -- FormatLegacyDate is not called anywhere in the codebase
func FormatLegacyDate(t time.Time) string {
    return t.Format("01/02/2006")
}

func FormatDate(t time.Time) string {
    return t.Format(time.RFC3339)
}
```

```go
// GOOD -- only the code that is used exists
func FormatDate(t time.Time) string {
    return t.Format(time.RFC3339)
}
```

## The Cost of Dead Code

Dead code is not free. Every line of dead code:

1. **Confuses new developers** who assume it exists for a reason and waste time understanding it
2. **Gets updated in refactors** by conscientious developers who do not realize it is unused, wasting their time and creating noisy diffs
3. **Triggers false positives in searches** when you grep for a function name and find it in dead code, sending you down the wrong path
4. **Creates the illusion of complexity** making the codebase seem larger and more intricate than it actually is
5. **Masks real issues** because the dead code might contain bugs or security vulnerabilities that scanners flag, distracting from actual problems
6. **Increases cognitive load** because the reader must constantly evaluate "is this code live or dead?" instead of just reading

The fix is always the same: delete it. If you were wrong and you need it back, `git log` and `git checkout` are right there.

## Examples

Working implementations in `examples/`:
- **`examples/dead-code-patterns.md`** -- Multi-language examples showing dead code identification and removal across Python, TypeScript, and Go, covering commented-out code, unused imports, unreachable branches, stale TODOs, and dead feature flags

## Review Checklist

When reviewing code for dead code:

- [ ] No commented-out code exists anywhere -- not "for reference," not "temporarily," not "just in case"
- [ ] Every import is used in the file. No unused imports remain after refactoring
- [ ] No unreachable branches: no `if (false)`, no dead defaults in exhaustive switches, no catch blocks for impossible exceptions
- [ ] No TODO/FIXME comments without a linked, open issue in the project tracker. If the issue is closed, the comment is deleted
- [ ] No historical comments describing what the code used to do, what was removed, or what was previously tried
- [ ] No feature flags that have been at 100% rollout for more than one sprint -- the flag, the check, and the old code path are all removed
- [ ] No unused functions, methods, or classes. If nothing calls it and nothing imports it, it is deleted
- [ ] No unused variables or parameters (enforce via linter: ruff F841 for Python, no-unused-vars for TypeScript, unused for Go)
- [ ] No dead CSS classes, unused template blocks, or orphaned configuration entries
- [ ] The codebase grep for the function/class name confirms it is actually used, not just defined
- [ ] Version control is trusted -- no code is kept "because we might need it." Git has it. Delete it.