---
name: boolean-naming
description: "This skill should be used when the user is naming boolean variables, writing predicate functions, using flags or toggles, or when code contains ambiguous boolean names like flag, status, check, active without proper prefixes. Covers is/has/can/should prefixes, positive naming, and the rule that a boolean's name must read as a true/false question."
version: 1.0.0
---

# A Boolean's Name Is a Yes/No Question

Every boolean variable, field, parameter, and return value must read as a question that has exactly two answers: yes or no. If you read the name out loud and it does not form a grammatical yes/no question, the name is wrong. Not "could be better" — wrong.

`active` is not a question. `isActive` is. `permission` is not a question. `hasPermission` is. `retry` is not a question. `shouldRetry` is. This is the entire rule. Everything below is application of it.

## The Prefix Table

Every boolean gets a prefix. No exceptions.

| Prefix | Meaning | Examples |
|--------|---------|----------|
| `is` | State of being — the subject currently exhibits this quality | `isActive`, `isVisible`, `isAuthenticated`, `isEmpty`, `isValid` |
| `has` | Possession or existence — the subject owns or contains something | `hasPermission`, `hasChildren`, `hasError`, `hasSubscription` |
| `can` | Capability or permission — the subject is allowed or able to do this | `canEdit`, `canDelete`, `canAccessAdmin`, `canRetry` |
| `should` | Recommendation or conditional — logic recommends this action | `shouldRetry`, `shouldCache`, `shouldNotify`, `shouldRedirect` |
| `was` / `did` | Past tense — something already happened | `wasProcessed`, `didSucceed`, `wasModified`, `didExpire` |

**The prefix is not optional.** A boolean without a prefix forces the reader to guess whether `enabled` is a boolean, a string, a function, or an adjective modifying something else. The prefix eliminates all ambiguity in a single glance.

## Positive Naming: Always

Name booleans in the positive. Always. The logic can negate; the name must not.

**BAD — negative names create double negatives:**
```
isNotReady       → if (!isNotReady) — unreadable
isDisabled       → if (!isDisabled) — "not disabled" means "enabled"
isInvalid        → if (!isInvalid) — triple cognitive load
hasNoPermission  → if (!hasNoPermission) — brain melts
isNotFound       → if (isNotFound) — why not just check the positive?
```

**GOOD — positive names, inverted in logic when needed:**
```
isReady          → if (!isReady) — clear: "not ready"
isEnabled        → if (!isEnabled) — clear: "not enabled"
isValid          → if (!isValid) — clear: "not valid"
hasPermission    → if (!hasPermission) — clear: "no permission"
isFound          → if (!isFound) — clear: "not found"
```

The reason is mechanical: `if (!isDisabled)` requires the reader to evaluate a negation of a negation. `if (isEnabled)` or `if (!isEnabled)` each require evaluating one thing. This is not pedantry — studies on code comprehension consistently show negative boolean names increase error rates in conditionals.

## Function Predicates

Functions that return booleans follow the same prefix rules. The function name IS the question; the return value IS the answer.

```python
# GOOD — the function name is the question
def is_even(number: int) -> bool: ...
def has_access(user: User, resource: Resource) -> bool: ...
def can_proceed(workflow: Workflow) -> bool: ...
def should_retry(error: Exception, attempt: int) -> bool: ...

# BAD — the function name is not a question
def check_even(number: int) -> bool: ...      # "check" is a verb, not a question
def validate_access(user, resource) -> bool: ... # "validate" implies side effects
def get_status() -> bool: ...                    # "get" implies returning data, not answering
def verify(token: str) -> bool: ...              # verify what? no subject, no question
```

```typescript
// GOOD
function isEven(n: number): boolean { ... }
function hasAccess(user: User, resource: Resource): boolean { ... }
function canProceed(workflow: Workflow): boolean { ... }

// BAD
function checkEven(n: number): boolean { ... }
function getAccess(user: User): boolean { ... }
function processValid(data: unknown): boolean { ... }
```

```go
// GOOD — Go convention: Is, Has, Can prefix on exported functions
func IsEven(n int) bool { ... }
func HasAccess(user *User, resource *Resource) bool { ... }
func CanProceed(wf *Workflow) bool { ... }

// BAD
func CheckEven(n int) bool { ... }
func GetStatus() bool { ... }
func Validate(token string) bool { ... }
```

## Multi-Word Booleans

The prefix always comes first. The prefix IS the first word. Not the second, not somewhere in the middle.

**GOOD:**
```
isUserAuthenticated
hasValidSubscription
canEditDocument
shouldRefreshToken
wasPaymentProcessed
```

**BAD:**
```
authenticatedUser       → is this a User object? a string? a boolean?
userIsAuthenticated     → prefix buried after the subject
validSubscription       → no prefix at all
documentCanEdit         → inverted order
paymentWasProcessed     → prefix is not first
```

## Banned Patterns

These names are never acceptable for booleans:

| Banned Name | Why | Fix |
|-------------|-----|-----|
| `flag` | Says nothing about what it controls | Name the specific condition: `isDebugMode`, `shouldLogVerbose` |
| `status` | Is it a boolean? A string? An enum? An object? | Name the specific state: `isActive`, `isPending`, `isApproved` |
| `toggle` | Describes the action, not the state | Name the state being toggled: `isExpanded`, `isVisible` |
| `check` | Describes the action, not the result | Name what is being checked: `isValid`, `hasErrors` |
| `state` | Maximally vague | Name the specific state: `isLoading`, `isConnected` |
| `active` / `enabled` / `visible` | Missing prefix — ambiguous type | `isActive`, `isEnabled`, `isVisible` |
| `b`, `f`, `ok` | Single-letter booleans | Spell it out. Even in a 3-line scope. |

The only exception for single-letter booleans: loop variables in tiny, obvious scopes where the boolean is consumed on the next line. Even then, prefer a name.

## Good vs. Bad Pairs

| Context | BAD | GOOD | Why |
|---------|-----|------|-----|
| User login state | `loggedIn` | `isLoggedIn` | Missing prefix |
| Feature toggle | `darkMode` | `isDarkModeEnabled` | Ambiguous type without prefix |
| Permission check | `admin` | `isAdmin` or `hasAdminRole` | `admin` could be a string, object, or ID |
| Error state | `error` | `hasError` | `error` is typically the error object itself |
| Loading state | `loading` | `isLoading` | Missing prefix |
| Empty collection | `empty` | `isEmpty` | Missing prefix |
| Negated state | `isNotValid` | `isValid` (negate in logic) | Negative name |
| Past event | `processed` | `wasProcessed` | Missing temporal prefix |
| Config flag | `flag` | `isFeatureEnabled` | `flag` means nothing |
| Function | `validate()` | `isValid()` | Verb implies action, not question |

## Examples

Working implementations in `examples/`:
- **`examples/boolean-patterns.md`** — Multi-language examples (Python, TypeScript, Go) showing bad-to-good boolean naming transformations for variables, function predicates, class properties, and function parameters.

## Review Checklist

When naming or reviewing boolean identifiers:

- [ ] Every boolean variable name reads as a yes/no question when spoken aloud
- [ ] Every boolean has a prefix: `is`, `has`, `can`, `should`, `was`, or `did`
- [ ] The prefix is the first word in the name — no `userIsActive`, only `isUserActive`
- [ ] All boolean names are positive — no `isNot`, `isUn`, `isIn`, `hasNo` prefixes
- [ ] Negative conditions use positive names with logical negation: `if (!isValid)` not `if (isInvalid)`
- [ ] Functions returning booleans use the same prefix convention as variables
- [ ] No boolean is named `flag`, `status`, `toggle`, `check`, `state`, or a bare adjective
- [ ] No single-letter boolean variables outside trivial scopes
- [ ] Boolean function parameters are named so the call site reads clearly: `setVisible(isVisible: true)`
- [ ] Boolean names are consistent across the codebase — if one file uses `isActive`, no other file uses `active` for the same concept
