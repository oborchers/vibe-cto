# Pattern Consistency

Multi-language examples showing pattern drift vs pattern discipline. For each category of problem -- configuration, error handling, validation -- the codebase must solve it exactly one way. These examples show what drift looks like and how to enforce discipline.

## Python -- Configuration Drift vs Discipline

### BAD -- Four ways to read config in one project

```python
# --- File 1: settings.py (Pydantic BaseSettings) ---
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    database_url: str
    redis_url: str

    model_config = {"env_file": ".env"}

settings = Settings()


# --- File 2: worker.py (raw os.getenv) ---
import os

QUEUE_URL = os.getenv("QUEUE_URL", "sqs://localhost")
WORKER_CONCURRENCY = int(os.getenv("WORKER_CONCURRENCY", "4"))


# --- File 3: billing.py (dotenv + os.environ) ---
from dotenv import load_dotenv
import os

load_dotenv()
STRIPE_API_KEY = os.environ["STRIPE_API_KEY"]
STRIPE_WEBHOOK_SECRET = os.environ["STRIPE_WEBHOOK_SECRET"]


# --- File 4: notifications.py (YAML config file) ---
import yaml

with open("config.yaml") as f:
    _config = yaml.safe_load(f)

SMTP_HOST = _config["smtp"]["host"]
SMTP_PORT = _config["smtp"]["port"]
```

Four modules, four config patterns. A developer reading `billing.py` has no idea that `settings.py` exists. They see `os.environ` and conclude that is the project convention.

### GOOD -- One config pattern, every value in one place

```python
# --- settings.py (the ONLY config file) ---
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # Database
    database_url: str
    redis_url: str

    # Worker
    queue_url: str = "sqs://localhost"
    worker_concurrency: int = 4

    # Billing
    stripe_api_key: str
    stripe_webhook_secret: str

    # Notifications
    smtp_host: str
    smtp_port: int = 587

    model_config = {"env_file": ".env"}


settings = Settings()


# --- worker.py ---
from app.settings import settings

async def run_worker():
    queue = connect(settings.queue_url)
    pool = WorkerPool(concurrency=settings.worker_concurrency)
    # ...


# --- billing.py ---
from app.settings import settings

stripe.api_key = settings.stripe_api_key

async def handle_webhook(payload: bytes, signature: str):
    event = stripe.Webhook.construct_event(
        payload, signature, settings.stripe_webhook_secret,
    )
    # ...


# --- notifications.py ---
from app.settings import settings

async def send_email(to: str, subject: str, body: str):
    async with SMTP(settings.smtp_host, settings.smtp_port) as smtp:
        # ...
```

One import. One object. Every module reads from the same source. If a value is missing from the environment, Pydantic raises a validation error at startup -- not at runtime when `billing.py` first tries to read `STRIPE_API_KEY`.

## TypeScript -- Error Handling Drift vs Discipline

### BAD -- Three error patterns in one project

```typescript
// --- users.ts (throws typed errors) ---
export async function getUser(id: string): Promise<User> {
  const user = await db.users.findUnique({ where: { id } });
  if (!user) {
    throw new NotFoundError(`User ${id} not found`);
  }
  return user;
}

// --- products.ts (returns null) ---
export async function getProduct(id: string): Promise<Product | null> {
  return db.products.findUnique({ where: { id } });
  // Caller must check for null. No error context.
}

// --- orders.ts (returns result tuple) ---
type Result<T> = { data: T; error: null } | { data: null; error: string };

export async function getOrder(id: string): Promise<Result<Order>> {
  const order = await db.orders.findUnique({ where: { id } });
  if (!order) {
    return { data: null, error: `Order ${id} not found` };
  }
  return { data: order, error: null };
}
```

A developer calling these three functions must use three different error handling approaches: try/catch for users, null check for products, result destructuring for orders.

### GOOD -- One error pattern, every service

```typescript
// --- errors.ts (one error hierarchy) ---
export class AppError extends Error {
  constructor(
    message: string,
    public readonly code: string,
    public readonly statusCode: number,
  ) {
    super(message);
    this.name = this.constructor.name;
  }
}

export class NotFoundError extends AppError {
  constructor(resource: string, id: string) {
    super(`${resource} ${id} not found`, "NOT_FOUND", 404);
  }
}

export class ValidationError extends AppError {
  constructor(message: string) {
    super(message, "VALIDATION_ERROR", 422);
  }
}

export class ConflictError extends AppError {
  constructor(message: string) {
    super(message, "CONFLICT", 409);
  }
}

// --- users.ts ---
export async function getUser(id: string): Promise<User> {
  const user = await db.users.findUnique({ where: { id } });
  if (!user) {
    throw new NotFoundError("User", id);
  }
  return user;
}

// --- products.ts (same pattern) ---
export async function getProduct(id: string): Promise<Product> {
  const product = await db.products.findUnique({ where: { id } });
  if (!product) {
    throw new NotFoundError("Product", id);
  }
  return product;
}

// --- orders.ts (same pattern) ---
export async function getOrder(id: string): Promise<Order> {
  const order = await db.orders.findUnique({ where: { id } });
  if (!order) {
    throw new NotFoundError("Order", id);
  }
  return order;
}

// --- Boundary layer catches everything uniformly ---
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      error: { code: err.code, message: err.message },
    });
  }
  return res.status(500).json({
    error: { code: "INTERNAL_ERROR", message: "An unexpected error occurred" },
  });
});
```

One hierarchy. One pattern. Every caller uses try/catch. The boundary middleware handles everything.

## Go -- Validation Drift vs Discipline

### BAD -- Three validation approaches in one project

```go
// --- users.go (manual validation) ---
func (h *UserHandler) CreateUser(w http.ResponseWriter, r *http.Request) {
    var input CreateUserInput
    json.NewDecoder(r.Body).Decode(&input)

    if input.Name == "" {
        http.Error(w, "name is required", http.StatusBadRequest)
        return
    }
    if input.Email == "" {
        http.Error(w, "email is required", http.StatusBadRequest)
        return
    }
    // ...
}

// --- products.go (go-playground/validator) ---
func (h *ProductHandler) CreateProduct(w http.ResponseWriter, r *http.Request) {
    var input CreateProductInput
    json.NewDecoder(r.Body).Decode(&input)

    validate := validator.New()
    if err := validate.Struct(input); err != nil {
        http.Error(w, err.Error(), http.StatusBadRequest)
        return
    }
    // ...
}

// --- orders.go (custom Validate() method) ---
func (h *OrderHandler) CreateOrder(w http.ResponseWriter, r *http.Request) {
    var input CreateOrderInput
    json.NewDecoder(r.Body).Decode(&input)

    if errs := input.Validate(); len(errs) > 0 {
        writeJSON(w, http.StatusBadRequest, map[string]interface{}{
            "errors": errs,
        })
        return
    }
    // ...
}
```

### GOOD -- One validation pattern across all handlers

```go
// --- validate.go (one validator, one error format) ---
package handler

import (
    "github.com/go-playground/validator/v10"
)

var validate = validator.New()

type ValidationError struct {
    Field   string `json:"field"`
    Message string `json:"message"`
}

func validateInput(input interface{}) []ValidationError {
    err := validate.Struct(input)
    if err == nil {
        return nil
    }

    var errors []ValidationError
    for _, e := range err.(validator.ValidationErrors) {
        errors = append(errors, ValidationError{
            Field:   e.Field(),
            Message: formatValidationMessage(e),
        })
    }
    return errors
}


// --- users.go ---
type CreateUserInput struct {
    Name  string `json:"name" validate:"required,min=1,max=255"`
    Email string `json:"email" validate:"required,email"`
    Role  string `json:"role" validate:"required,oneof=admin member viewer"`
}

func (h *UserHandler) CreateUser(w http.ResponseWriter, r *http.Request) {
    var input CreateUserInput
    if err := decodeJSON(r, &input); err != nil {
        writeError(w, http.StatusBadRequest, "INVALID_JSON", err.Error())
        return
    }
    if errs := validateInput(input); errs != nil {
        writeValidationErrors(w, errs)
        return
    }
    // ...
}


// --- products.go (same pattern) ---
type CreateProductInput struct {
    Name     string `json:"name" validate:"required,min=1,max=255"`
    Price    int    `json:"price" validate:"required,gt=0"`
    Category string `json:"category" validate:"required,oneof=electronics clothing food"`
}

func (h *ProductHandler) CreateProduct(w http.ResponseWriter, r *http.Request) {
    var input CreateProductInput
    if err := decodeJSON(r, &input); err != nil {
        writeError(w, http.StatusBadRequest, "INVALID_JSON", err.Error())
        return
    }
    if errs := validateInput(input); errs != nil {
        writeValidationErrors(w, errs)
        return
    }
    // ...
}


// --- orders.go (same pattern) ---
type CreateOrderInput struct {
    CustomerID string          `json:"customer_id" validate:"required"`
    Items      []OrderItemInput `json:"items" validate:"required,min=1,dive"`
}

type OrderItemInput struct {
    ProductID string `json:"product_id" validate:"required"`
    Quantity  int    `json:"quantity" validate:"required,gt=0"`
}

func (h *OrderHandler) CreateOrder(w http.ResponseWriter, r *http.Request) {
    var input CreateOrderInput
    if err := decodeJSON(r, &input); err != nil {
        writeError(w, http.StatusBadRequest, "INVALID_JSON", err.Error())
        return
    }
    if errs := validateInput(input); errs != nil {
        writeValidationErrors(w, errs)
        return
    }
    // ...
}
```

One `validateInput` function. One `validator` instance. Struct tags for rules. Every handler follows the same three steps: decode, validate, proceed. A developer who reads one handler can write the next one from memory.

## The Refactoring Rule

When the existing codebase has 12 modules using `os.getenv` and 3 modules using Pydantic `BaseSettings`, the dominant pattern (`os.getenv`) wins -- unless you refactor all 15 modules in a single PR. There is no migration period. There is no "we will gradually move to the new pattern." Either everything switches at once, or the existing pattern stays.

```
WRONG:
  PR #1: Add Pydantic settings for new module
  PR #2: Migrate auth module to Pydantic settings
  PR #3: Migrate billing module to Pydantic settings
  (12 modules still using os.getenv 6 months later)

RIGHT:
  PR #1: Migrate all 15 modules to Pydantic settings in one commit
```

## Key Points

- Every cross-cutting concern (config, errors, validation, HTTP, logging, constants, defaults) has ONE pattern in the codebase
- The specific pattern matters less than having exactly one
- "Local shortcuts" are pattern violations -- revert them immediately
- The dominant pattern wins in conflicts, unless you refactor everything at once
- A new pattern must replace the old one completely in a single PR; coexistence is never acceptable
- When reviewing, reject any PR that introduces a second way to solve an already-solved category of problem
