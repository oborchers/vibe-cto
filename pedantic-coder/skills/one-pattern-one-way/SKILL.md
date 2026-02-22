---
name: one-pattern-one-way
description: "This skill should be used when the user's codebase has multiple approaches to the same problem, mixes paradigms (callbacks and promises, classes and functions for the same purpose), or when someone introduces a 'local shortcut' that differs from the established convention. Covers pattern consistency and the rule that a codebase should solve each category of problem exactly one way."
version: 1.0.0
---

# One Problem, One Pattern, One Way

For each category of problem in a codebase, there is one pattern. One. Not "usually" one. Not "preferably" one. Not "one, except when it is more convenient to do something else." ONE.

Configuration loading? One way. Error handling? One way. Data validation? One way. HTTP requests? One way. Logging? One way. String constants? One way. The moment a second approach appears, you have two problems: the original problem and the problem of not knowing which solution to use. By the third approach, the codebase is a museum of abandoned conventions.

This is the most violated principle in software engineering. Not because developers do not understand it, but because every individual shortcut feels harmless. "It is just one place." "This module is different." "I will refactor it later." None of these excuses survive contact with a team.

## The Categories

Every codebase faces the same categories of cross-cutting problems. For each one, pick a pattern and enforce it everywhere. The specific pattern matters less than the fact that there is exactly one.

### Configuration

One settings pattern. Everywhere.

**Python:** Pydantic `BaseSettings` with `.env` file loading.
**TypeScript:** Zod schema validating `process.env`.
**Go:** Struct with `envconfig` tags.

Pick one. If the project uses Pydantic `BaseSettings`, then every module that needs a config value gets it from that settings object. No `os.getenv()` calls scattered in business logic. No `dotenv.load()` in random files. No `config.yaml` alongside the `.env`. One source of truth, one loading mechanism, one validation step.

**GOOD:**

```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    database_url: str
    redis_url: str
    stripe_api_key: str
    max_retry_attempts: int = 3

    model_config = {"env_file": ".env"}

settings = Settings()
```

**BAD -- three config patterns in one project:**

```python
# settings.py -- Pydantic (pattern 1)
class Settings(BaseSettings):
    database_url: str

# worker.py -- raw os.getenv (pattern 2)
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost")

# billing.py -- dotenv + os.environ (pattern 3)
load_dotenv()
STRIPE_KEY = os.environ["STRIPE_API_KEY"]
```

Three modules, three config patterns. Which one is "correct"? All of them. None of them. The developer reading `billing.py` has no way to know that the project's convention is Pydantic settings. They see `os.environ` and assume that is the pattern.

### Error Handling

One error type hierarchy. One wrapping strategy. One escalation pattern.

**Python:** Custom exception classes inheriting from a base `ServiceError`, using `raise ... from exc` for chaining.
**TypeScript:** Typed error classes extending a base `AppError`, caught at the boundary layer.
**Go:** Error wrapping with `fmt.Errorf("%w", err)`, sentinel errors for known cases.

**GOOD -- Python, one exception hierarchy:**

```python
class ServiceError(Exception):
    """Base error for all service-layer exceptions."""

class NotFoundError(ServiceError):
    """Raised when a requested resource does not exist."""

class ValidationError(ServiceError):
    """Raised when input fails validation."""

class ConflictError(ServiceError):
    """Raised when an operation conflicts with current state."""

# Every service uses the same pattern:
def get_user(user_id: str) -> User:
    user = repo.find_by_id(user_id)
    if user is None:
        raise NotFoundError(f"User {user_id} not found")
    return user
```

**BAD -- three error patterns in one project:**

```python
# users.py -- custom exceptions (pattern 1)
raise NotFoundError(f"User {user_id} not found")

# products.py -- returns None (pattern 2)
def get_product(product_id: str) -> Product | None:
    return repo.find_by_id(product_id)  # caller must check

# orders.py -- returns tuple (pattern 3)
def get_order(order_id: str) -> tuple[Order | None, str | None]:
    order = repo.find_by_id(order_id)
    if order is None:
        return None, "Order not found"
    return order, None
```

### Data Validation

One validation library. One place where validation happens.

**Python:** Pydantic models at the API boundary.
**TypeScript:** Zod schemas at the API boundary.
**Go:** `go-playground/validator` struct tags.

**GOOD -- TypeScript, Zod everywhere:**

```typescript
import { z } from "zod";

const CreateUserSchema = z.object({
  name: z.string().min(1).max(255),
  email: z.string().email(),
  role: z.enum(["admin", "member", "viewer"]),
});

const UpdateUserSchema = CreateUserSchema.partial();

const CreateProductSchema = z.object({
  name: z.string().min(1).max(255),
  price: z.number().positive(),
  category: z.enum(["electronics", "clothing", "food"]),
});

// Every route handler: parse input with Zod, then proceed
app.post("/users", (req, res) => {
  const input = CreateUserSchema.parse(req.body);
  // ...
});
```

**BAD -- three validation patterns in one project:**

```typescript
// users.ts -- Zod (pattern 1)
const input = CreateUserSchema.parse(req.body);

// products.ts -- manual checks (pattern 2)
if (!req.body.name || typeof req.body.name !== "string") {
  return res.status(400).json({ error: "name is required" });
}
if (!req.body.price || req.body.price <= 0) {
  return res.status(400).json({ error: "price must be positive" });
}

// orders.ts -- Joi (pattern 3)
const schema = Joi.object({
  customer_id: Joi.string().required(),
  items: Joi.array().min(1).required(),
});
const { error, value } = schema.validate(req.body);
```

### HTTP Clients

One HTTP wrapper. One retry strategy. One timeout configuration.

```typescript
// GOOD -- one HTTP client pattern
import { httpClient } from "@/lib/http";

// Every external call goes through the same client:
const user = await httpClient.get("/users/123");
const payment = await httpClient.post("/payments", { amount: 1000 });

// BAD -- three HTTP patterns in one project
import axios from "axios";                        // pattern 1
const user = await axios.get("https://api.example.com/users/123");

const resp = await fetch("https://api.example.com/payments", {  // pattern 2
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ amount: 1000 }),
});

import got from "got";                            // pattern 3
const order = await got("https://api.example.com/orders/456").json();
```

### Logging

One structured logger. One format. One way to add context.

**GOOD -- Go, one logger everywhere:**

```go
// All modules use the same slog pattern:
func (s *UserService) CreateUser(ctx context.Context, input CreateUserInput) (*User, error) {
    slog.InfoContext(ctx, "creating user", "email", input.Email)
    // ...
    slog.ErrorContext(ctx, "failed to create user", "error", err)
}

func (s *ProductService) CreateProduct(ctx context.Context, input CreateProductInput) (*Product, error) {
    slog.InfoContext(ctx, "creating product", "name", input.Name)
    // ...
    slog.ErrorContext(ctx, "failed to create product", "error", err)
}
```

**BAD -- three logging patterns in one project:**

```go
// user_service.go -- slog (pattern 1)
slog.Info("creating user", "email", input.Email)

// product_service.go -- log (pattern 2)
log.Printf("Creating product: %s", input.Name)

// order_service.go -- fmt (pattern 3)
fmt.Fprintf(os.Stderr, "creating order for customer %s\n", input.CustomerID)
```

### String Constants

One approach to defining fixed sets of values.

**Python:** `StrEnum` for finite sets, module-level `UPPER_SNAKE` constants for standalone values.
**TypeScript:** `as const` objects or string literal unions. Never bare inline strings.
**Go:** `const` block with typed string constants.

**GOOD -- Python, StrEnum for every finite set:**

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
```

**BAD -- three constant patterns in one project:**

```python
# orders.py -- inline strings (pattern 1)
if order.status == "pending":
    order.status = "processing"

# users.py -- module-level strings (pattern 2)
ROLE_ADMIN = "admin"
ROLE_MEMBER = "member"

# billing.py -- Enum (pattern 3)
class PaymentStatus(Enum):
    PENDING = "pending"
    COMPLETED = "completed"
```

### Default Values

One pattern for supplying defaults.

**Python:** `Field(default=...)` in Pydantic models, parameter defaults in function signatures.
**TypeScript:** `??` (nullish coalescing) for runtime defaults, default parameters for function signatures.
**Go:** Zero values by design, explicit `WithOption` pattern for configuration.

## The "Local Shortcut" Problem

This is how every pattern violation begins. A developer needs a config value. The project uses Pydantic `BaseSettings`. But adding a field to the settings class requires updating the `.env.example`, the test fixtures, and the deployment config. So they write:

```python
# "It's just one place."
db_url = os.getenv("DB_URL")
```

Now there are two config patterns. The next developer sees `os.getenv` and thinks it is acceptable. They add another. Within three months:

```python
# settings.py
class Settings(BaseSettings):
    database_url: str
    redis_url: str

# worker.py
QUEUE_URL = os.getenv("QUEUE_URL")

# billing.py
load_dotenv()
STRIPE_KEY = os.environ["STRIPE_API_KEY"]

# notifications.py
import yaml
with open("config.yaml") as f:
    config = yaml.safe_load(f)
SMTP_HOST = config["smtp"]["host"]
```

Four config patterns. One settings class that nobody trusts because it is visibly incomplete. The fix is not "add a comment saying to use Settings." The fix is to revert the shortcut, add the field to `Settings`, and update all three downstream files. The shortcut was cheaper for the author and more expensive for every subsequent reader.

## How to Establish a Pattern

1. **Use it in the first module.** The first service, the first route handler, the first test file sets the convention.
2. **Document it once.** A one-line comment or a section in the contributing guide: "Configuration: Pydantic BaseSettings. No os.getenv."
3. **Enforce it in every subsequent module.** When reviewing a PR that introduces a second pattern, reject it. Not "consider using the existing pattern" -- reject it.
4. **When someone proposes a better pattern:** Agree. Then refactor ALL usages in a single PR. The new pattern replaces the old one completely. There is never a migration period where both coexist.

## When Patterns Conflict

If the codebase already has `os.getenv` in 15 places and Pydantic `BaseSettings` in 3 places, the existing dominant pattern wins -- even if the minority pattern is "better." Consistency across 18 files matters more than using the ideal tool in 3 of them.

The only exception: you refactor all 18 files in a single, focused PR. Then the new pattern wins because the old one no longer exists.

## Examples

Working implementations in `examples/`:
- **`examples/pattern-consistency.md`** -- Multi-language examples showing pattern drift vs pattern discipline for configuration, error handling, and validation in Python, TypeScript, and Go

## Review Checklist

When reviewing code for pattern consistency:

- [ ] Configuration is loaded through one mechanism -- no raw `os.getenv`, `process.env`, or `os.Environ` calls outside the config module
- [ ] Error handling uses one pattern -- no mix of exceptions, return tuples, and None returns in the same codebase
- [ ] Data validation uses one library -- no Zod in one module and Joi or manual checks in another
- [ ] HTTP calls go through one client wrapper -- no mix of axios, fetch, and got
- [ ] Logging uses one structured logger -- no mix of `slog`, `log`, and `fmt.Println`
- [ ] String constants use one approach -- all enums, or all `as const`, or all `const` blocks. Never inline strings for values that belong to a finite set
- [ ] Default values follow one pattern -- `??` everywhere or `||` everywhere, not a mix
- [ ] No "local shortcut" introduces a second way of doing something the codebase already has a pattern for
- [ ] When a new pattern is proposed, the PR migrates ALL existing usages -- no coexistence period
- [ ] The dominant pattern wins in disputes -- consistency over perfection
