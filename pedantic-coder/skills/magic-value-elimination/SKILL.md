---
name: magic-value-elimination
description: "This skill should be used when the user's code contains inline string literals, unexplained numbers, hardcoded timeout values, status strings, or any value that should be a named constant or enum. Covers the elimination of magic values and the rule that every literal should have a name."
version: 1.0.0
---

# Every Literal Deserves a Name

If a value appears in code without a name explaining what it means, it is a magic value. Magic values are not "minor style issues." They are comprehension failures. When a reader sees `86400`, they must stop, count zeros, divide by 60 twice, and conclude "oh, seconds per day." When they see `SECONDS_PER_DAY`, they keep reading. That interruption -- multiplied by every developer, every review, every debugging session -- is the cost of a magic value.

Eliminate them. All of them.

## The Rule

**If a value appears in code without a name explaining what it means, it is a magic value and it must be eliminated.**

No exceptions for "obvious" values. No exceptions for "it is only used once." No exceptions for "everyone knows what 200 means." Name it. The name is documentation that never goes stale, a grep target that always works, and a single point of change when the value evolves.

## Magic Numbers

Every number that is not 0, 1, or -1 in an obvious context needs a name.

**GOOD:**

```python
SECONDS_PER_DAY = 86400
MAX_BATCH_SIZE = 1000
RELEVANCE_THRESHOLD = 0.5
MAX_RETRY_ATTEMPTS = 3
DEFAULT_PAGE_SIZE = 20
BCRYPT_ROUNDS = 12
HTTP_TIMEOUT_SECONDS = 30
CACHE_TTL_MINUTES = 15
MAX_FILE_SIZE_BYTES = 10 * 1024 * 1024  # 10 MB
```

**BAD:**

```python
if elapsed > 86400:
    expire_session()

results = results[:1000]

if score < 0.5:
    discard(item)

for attempt in range(3):
    try:
        response = client.post(url, timeout=30)
        break
    except Timeout:
        time.sleep(2 ** attempt)
```

The reader of the bad code must reverse-engineer the meaning of every number. `86400` -- is that seconds? Milliseconds? Why that specific value? `1000` -- is that a page size? A rate limit? An arbitrary cap? `0.5` -- half of what? `3` -- why three? `30` -- thirty what?

## Magic Strings

String literals that represent categories, statuses, types, roles, or any value from a finite set must be enums or named constants. No inline strings.

**GOOD -- Python:**

```python
from enum import StrEnum


class OrderStatus(StrEnum):
    PENDING = "pending"
    PROCESSING = "processing"
    SHIPPED = "shipped"
    DELIVERED = "delivered"
    CANCELLED = "cancelled"


class UserRole(StrEnum):
    ADMIN = "admin"
    MEMBER = "member"
    VIEWER = "viewer"


CONTENT_TYPE_JSON = "application/json"
CONTENT_TYPE_FORM = "application/x-www-form-urlencoded"
AUTH_HEADER = "Authorization"
BEARER_PREFIX = "Bearer "
```

**BAD -- Python:**

```python
if order.status == "pending":
    order.status = "processing"

if user.role == "admin":
    allow_action()

headers = {"Content-Type": "application/json"}
headers["Authorization"] = "Bearer " + token
```

`"pending"`, `"processing"`, `"admin"`, `"application/json"`, `"Bearer "` -- every one of these is a typo waiting to happen. `"penidng"` compiles. `OrderStatus.PENIDNG` does not.

**GOOD -- TypeScript:**

```typescript
const ORDER_STATUS = {
  PENDING: "pending",
  PROCESSING: "processing",
  SHIPPED: "shipped",
  DELIVERED: "delivered",
  CANCELLED: "cancelled",
} as const;

type OrderStatus = (typeof ORDER_STATUS)[keyof typeof ORDER_STATUS];

const USER_ROLE = {
  ADMIN: "admin",
  MEMBER: "member",
  VIEWER: "viewer",
} as const;

type UserRole = (typeof USER_ROLE)[keyof typeof USER_ROLE];

const CONTENT_TYPE_JSON = "application/json";
const AUTH_HEADER = "Authorization";
```

**BAD -- TypeScript:**

```typescript
if (order.status === "pending") {
  order.status = "processing";
}

if (user.role === "admin") {
  allowAction();
}

const headers = { "Content-Type": "application/json" };
```

**GOOD -- Go:**

```go
type OrderStatus string

const (
    OrderStatusPending    OrderStatus = "pending"
    OrderStatusProcessing OrderStatus = "processing"
    OrderStatusShipped    OrderStatus = "shipped"
    OrderStatusDelivered  OrderStatus = "delivered"
    OrderStatusCancelled  OrderStatus = "cancelled"
)

type UserRole string

const (
    UserRoleAdmin  UserRole = "admin"
    UserRoleMember UserRole = "member"
    UserRoleViewer UserRole = "viewer"
)

const (
    ContentTypeJSON = "application/json"
    AuthHeader      = "Authorization"
    BearerPrefix    = "Bearer "
)
```

**BAD -- Go:**

```go
if order.Status == "pending" {
    order.Status = "processing"
}

if user.Role == "admin" {
    allowAction()
}

req.Header.Set("Content-Type", "application/json")
req.Header.Set("Authorization", "Bearer " + token)
```

## Magic Booleans

A boolean parameter whose meaning is not self-evident from the call site must be replaced with a named parameter or an enum.

**BAD:**

```python
process_order(order, True)         # True what? Skip validation? Rush shipping?
send_email(user, False, True)      # False what? True what?
create_report(data, True, False)   # Impossible to read at the call site
```

**GOOD:**

```python
process_order(order, skip_validation=True)
send_email(user, include_attachments=False, track_opens=True)
create_report(data, include_charts=True, send_immediately=False)
```

In TypeScript, use options objects instead of boolean parameters:

**BAD:**

```typescript
processOrder(order, true, false);
```

**GOOD:**

```typescript
processOrder(order, { skipValidation: true, rushShipping: false });
```

In Go, use option types or explicit parameters:

**BAD:**

```go
ProcessOrder(order, true, false)
```

**GOOD:**

```go
ProcessOrder(order, ProcessOptions{SkipValidation: true, RushShipping: false})
```

## Where Constants Live

Constants must live where they are used. Scattering them randomly makes them impossible to find. Centralizing everything into one massive `constants.go` makes them impossible to maintain. The rule:

- **Module-specific constants:** defined at the top of the module that uses them. If `MAX_BATCH_SIZE` is only used in `batch_processor.py`, it lives in `batch_processor.py`.
- **Shared constants:** defined in a dedicated constants module (`constants.py`, `constants.ts`, `constants.go`) when used across two or more modules.
- **Enums for finite sets:** always in a dedicated types or enums module (`types.py`, `types.ts`), even if only used in one module. Enums define domain concepts, not implementation details.

```
project/
  constants.py       # Shared: SECONDS_PER_DAY, MAX_FILE_SIZE_BYTES, CONTENT_TYPE_JSON
  types.py           # Enums: OrderStatus, UserRole, PaymentMethod
  batch_processor.py # Module-specific: MAX_BATCH_SIZE (used only here)
  cache.py           # Module-specific: DEFAULT_TTL_SECONDS (used only here)
```

## String Enums Over Raw Strings

For every finite set of values, use a string enum. Not a list of string constants. Not inline strings. A string enum gives you:

1. **Autocompletion** -- the IDE shows all valid values
2. **Compile-time checking** -- `OrderStatus.PENIDNG` is a typo that fails at compile time; `"penidng"` is a typo that fails in production
3. **Exhaustiveness checking** -- a switch/match on an enum warns when a case is missing
4. **Single source of truth** -- adding a new status requires updating one enum, not grep-and-praying across the codebase

**Python:** `StrEnum` (Python 3.11+)

```python
from enum import StrEnum

class PaymentMethod(StrEnum):
    CREDIT_CARD = "credit_card"
    DEBIT_CARD = "debit_card"
    BANK_TRANSFER = "bank_transfer"
    CRYPTO = "crypto"

# Serializes to string automatically:
# json.dumps({"method": PaymentMethod.CREDIT_CARD})
# -> '{"method": "credit_card"}'
```

**TypeScript:** `as const` with derived type

```typescript
const PAYMENT_METHOD = {
  CREDIT_CARD: "credit_card",
  DEBIT_CARD: "debit_card",
  BANK_TRANSFER: "bank_transfer",
  CRYPTO: "crypto",
} as const;

type PaymentMethod = (typeof PAYMENT_METHOD)[keyof typeof PAYMENT_METHOD];
// "credit_card" | "debit_card" | "bank_transfer" | "crypto"
```

**Go:** typed string constants

```go
type PaymentMethod string

const (
    PaymentMethodCreditCard   PaymentMethod = "credit_card"
    PaymentMethodDebitCard    PaymentMethod = "debit_card"
    PaymentMethodBankTransfer PaymentMethod = "bank_transfer"
    PaymentMethodCrypto       PaymentMethod = "crypto"
)
```

## The DRY Rule for Values

- **Appears more than once:** MUST be a named constant. No discussion.
- **Appears once, meaning not self-evident:** SHOULD be a named constant. `timeout=30` -- thirty what? `timeout=HTTP_TIMEOUT_SECONDS` -- clear.
- **Appears once, meaning is self-evident from context:** MAY remain inline. `range(len(items))` -- `len(items)` is obvious. `users = []` -- empty list is obvious.

## Exceptions

These values can appear inline when their meaning is obvious from immediate context:

- `0` -- loop counter initialization, empty count, origin index
- `1` -- increment, single item, next index
- `-1` -- sentinel "not found" return, decrement
- `""` -- empty string initialization
- `True` / `False` -- boolean return, obvious flag assignment
- `None` / `null` / `nil` -- absence of value

Even these have limits. `sleep(1)` -- one what? Second? Millisecond? Name it: `RETRY_DELAY_SECONDS = 1`.

## Anti-Patterns

**The "obvious number" excuse.** "Everyone knows 200 is HTTP OK." Does everyone know 429 is rate-limited? Does everyone know 507 is insufficient storage? Name them all or name none. `HTTP_STATUS_OK = 200` costs nothing and helps everyone.

**The "only used once" excuse.** A magic value used once is still a magic value. `if retries > 3` -- why 3? What changes if the threshold moves to 5? With `MAX_RETRY_ATTEMPTS = 3`, the answer is obvious and the change is one line.

**The "it is in the config" excuse.** Configuration values need names too. `timeout: 30000` in a YAML file -- 30000 what? Add a comment or use a descriptive key: `http_timeout_ms: 30000`.

**Scattering the same literal.** `"application/json"` appears in 8 files. One of them typos it as `"applicaton/json"`. With `CONTENT_TYPE_JSON`, the typo is caught at import time.

## Examples

Working implementations in `examples/`:
- **`examples/constants-vs-literals.md`** -- Multi-language examples showing magic values replaced with named constants and enums in Python, TypeScript, and Go

## Review Checklist

When reviewing code for magic values:

- [ ] No numeric literals appear in logic except 0, 1, and -1 in obvious contexts
- [ ] No string literals are used for status values, roles, types, or categories -- all are enums
- [ ] No string literals are used for content types, header names, or protocol values -- all are named constants
- [ ] Boolean parameters have names visible at the call site (keyword args, options objects, or explicit types)
- [ ] Every timeout, threshold, limit, and retry count is a named constant with units in the name (`_SECONDS`, `_MS`, `_BYTES`)
- [ ] Constants that are used across modules live in a shared constants module
- [ ] Enums are used for every finite set of values, providing autocompletion and exhaustiveness checking
- [ ] No literal appears more than once -- if it does, it is a named constant
- [ ] Single-use literals whose meaning is not self-evident from context are named constants
- [ ] The `DRY rule for values` is applied: more than once = must name, once but unclear = should name, once and obvious = may inline
