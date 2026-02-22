# File Structure Patterns

Multi-language examples showing well-ordered file structures. Every file has the same shape: docstring, imports, constants, types, classes, functions, entry point. Every class has the same shape: constants, constructor, public methods, private methods, static methods, special methods.

## Python

### BAD — Chaotic File Structure

```python
from myapp.models import User
import logging
from .schemas import UserCreate

logger = logging.getLogger(__name__)

def _hash_password(password: str) -> str:
    """Hash a password with bcrypt."""
    import bcrypt  # inline import with no explanation
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()

MAX_PAGE_SIZE = 100

class UserService:
    def delete(self, user_id: str) -> None:
        ...

    def _validate_email(self, email: str) -> bool:
        ...

    ALLOWED_ROLES = frozenset({"admin", "editor", "viewer"})

    def create(self, data: UserCreate) -> User:
        ...

    def __init__(self, session):
        self.session = session

    def __repr__(self) -> str:
        return f"UserService(session={self.session!r})"

    def get(self, user_id: str) -> User:
        ...

    def update(self, user_id: str, data: UserCreate) -> User:
        ...

from datetime import datetime  # import after class definition

DEFAULT_PAGE_SIZE = 20  # constant after class definition

type UserId = str  # type after class and functions

def create_user_service(session) -> UserService:
    return UserService(session)

def list_users(service: UserService) -> list[User]:
    ...
```

Problems:
- Imports are not at the top (one after the class)
- Constants scattered: `MAX_PAGE_SIZE` between a function and a class, `DEFAULT_PAGE_SIZE` after the class
- Type alias after the class that should use it
- Helper `_hash_password` before the class instead of near its caller
- Class members in random order: `delete` before `create`, class constant after a private method, constructor in the middle
- `__repr__` between public methods

### GOOD — Structured File

```python
"""User service module.

Handles user creation, retrieval, updates, and deletion.
"""

from __future__ import annotations

import logging
from datetime import datetime, timezone
from uuid import uuid4

import bcrypt
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from myapp.models import User

from .schemas import UserCreate, UserResponse

# --- Constants ---

DEFAULT_PAGE_SIZE = 20
MAX_PAGE_SIZE = 100

# --- Types ---

type UserId = str

# --- Classes ---

class UserService:
    """Service for user-related CRUD operations."""

    # Class constants
    ALLOWED_ROLES = frozenset({"admin", "editor", "viewer"})

    # Constructor
    def __init__(self, session: AsyncSession) -> None:
        self._session = session
        self._logger = logging.getLogger(__name__)

    # Public methods — CRUD order
    async def create(self, data: UserCreate) -> User:
        hashed = self._hash_password(data.password)
        ...

    async def get(self, user_id: UserId) -> User:
        ...

    async def list(self, page: int = 1, size: int = DEFAULT_PAGE_SIZE) -> list[User]:
        ...

    async def update(self, user_id: UserId, data: UserCreate) -> User:
        self._validate_email(data.email)
        ...

    async def delete(self, user_id: UserId) -> None:
        ...

    # Private methods — each near its caller
    def _hash_password(self, password: str) -> str:
        """Hash a password with bcrypt."""
        return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()

    def _validate_email(self, email: str) -> bool:
        """Validate email format."""
        ...

    # Special methods
    def __repr__(self) -> str:
        return f"UserService(session={self._session!r})"


# --- Module-level functions ---

def create_user_service(session: AsyncSession) -> UserService:
    """Factory function for UserService."""
    return UserService(session)
```

### BAD — Inconsistent CRUD Order Across Services

```python
# user_service.py
class UserService:
    def create(self, ...): ...
    def get(self, ...): ...
    def update(self, ...): ...
    def delete(self, ...): ...

# order_service.py — different order!
class OrderService:
    def delete(self, ...): ...    # delete first?
    def list(self, ...): ...
    def create(self, ...): ...    # create third?
    def get(self, ...): ...

# product_service.py — yet another order!
class ProductService:
    def get(self, ...): ...       # get first?
    def create(self, ...): ...
    def delete(self, ...): ...
    def update(self, ...): ...
```

### GOOD — Consistent CRUD Order Across Services

```python
# user_service.py
class UserService:
    def create(self, ...): ...
    def get(self, ...): ...
    def list(self, ...): ...
    def update(self, ...): ...
    def delete(self, ...): ...

# order_service.py — same order
class OrderService:
    def create(self, ...): ...
    def get(self, ...): ...
    def list(self, ...): ...
    def update(self, ...): ...
    def delete(self, ...): ...

# product_service.py — same order
class ProductService:
    def create(self, ...): ...
    def get(self, ...): ...
    def list(self, ...): ...
    def update(self, ...): ...
    def delete(self, ...): ...
```

### BAD — Helpers Banished to Bottom

```python
class PaymentService:
    def charge(self, amount: int, currency: str) -> PaymentResult:
        validated = self._validate_amount(amount)
        converted = self._convert_currency(amount, currency)
        ...

    def refund(self, payment_id: str) -> RefundResult:
        original = self._fetch_original_payment(payment_id)
        ...

    def list_payments(self, user_id: str) -> list[Payment]:
        ...

    # --- 150 lines later, all helpers piled at the bottom ---

    def _validate_amount(self, amount: int) -> int:
        ...

    def _convert_currency(self, amount: int, currency: str) -> int:
        ...

    def _fetch_original_payment(self, payment_id: str) -> Payment:
        ...
```

### GOOD — Helpers Near Their Callers

```python
class PaymentService:
    def charge(self, amount: int, currency: str) -> PaymentResult:
        validated = self._validate_amount(amount)
        converted = self._convert_currency(amount, currency)
        ...

    def _validate_amount(self, amount: int) -> int:
        ...

    def _convert_currency(self, amount: int, currency: str) -> int:
        ...

    def refund(self, payment_id: str) -> RefundResult:
        original = self._fetch_original_payment(payment_id)
        ...

    def _fetch_original_payment(self, payment_id: str) -> Payment:
        ...

    def list_payments(self, user_id: str) -> list[Payment]:
        ...
```

## TypeScript

### BAD — Chaotic File Structure

```typescript
import { db } from "@/database";

const router = Router();  // used at bottom, declared at top before types/classes

interface User {
  id: string;
  name: string;
}

import { Router } from "express";  // import after code

function generateId(): string {
  return crypto.randomUUID();
}

import crypto from "node:crypto";  // import after function

const MAX_PAGE_SIZE = 100;  // constant between function and class

class UserService {
  async delete(userId: string): Promise<void> { ... }

  private validateEmail(email: string): void { ... }

  static readonly MAX_ATTEMPTS = 5;

  constructor(private readonly database: typeof db) {}

  async create(input: CreateUserInput): Promise<User> { ... }

  async get(userId: string): Promise<User> { ... }
}

type CreateUserInput = {   // type defined after the class that uses it
  name: string;
  email: string;
};

const DEFAULT_PAGE_SIZE = 20;  // constant at the bottom
```

### GOOD — Structured File

```typescript
/**
 * User service module.
 * Handles user CRUD operations.
 */

import crypto from "node:crypto";

import { Router } from "express";

import { db } from "@/database";

// --- Constants ---

const DEFAULT_PAGE_SIZE = 20;
const MAX_PAGE_SIZE = 100;

// --- Types ---

type CreateUserInput = {
  name: string;
  email: string;
};

interface User {
  id: string;
  name: string;
  email: string;
  isActive: boolean;
  createdAt: Date;
}

// --- Classes ---

class UserService {
  // Static properties
  static readonly MAX_ATTEMPTS = 5;

  // Constructor
  constructor(private readonly database: typeof db) {}

  // Public methods — CRUD order
  async create(input: CreateUserInput): Promise<User> {
    this.validateEmail(input.email);
    const id = this.generateId();
    ...
  }

  async get(userId: string): Promise<User> {
    ...
  }

  async list(page = 1, size = DEFAULT_PAGE_SIZE): Promise<User[]> {
    ...
  }

  async update(userId: string, input: Partial<CreateUserInput>): Promise<User> {
    ...
  }

  async delete(userId: string): Promise<void> {
    ...
  }

  // Private methods
  private validateEmail(email: string): void {
    ...
  }

  private generateId(): string {
    return `usr_${crypto.randomUUID().replace(/-/g, "").slice(0, 24)}`;
  }
}

// --- Module-level functions ---

export function createRouter(): Router {
  const service = new UserService(db);
  const router = Router();

  router.post("/users", async (req, res) => { ... });
  router.get("/users/:id", async (req, res) => { ... });

  return router;
}
```

### BAD — Export Ordering

```typescript
// models/index.ts
export { UserService } from "./service";
export { CreateUserRequest } from "./requests";
export { User } from "./models";
export { UserResponse } from "./responses";
export { DeleteUserRequest } from "./requests";
export { UpdateUserRequest } from "./requests";
// Is anything missing? Impossible to tell without alphabetical order.
```

### GOOD — Export Ordering

```typescript
// models/index.ts
export { CreateUserRequest } from "./requests";
export { DeleteUserRequest } from "./requests";
export { UpdateUserRequest } from "./requests";
export { User } from "./models";
export { UserResponse } from "./responses";
export { UserService } from "./service";
// Alphabetized. Any gap is immediately visible.
```

## Go

### BAD — Chaotic File Structure

```go
package users

import (
	"myapp/internal/database"
	"context"
	"fmt"
	"go.uber.org/zap"
)

func validateRole(role string) error {
	...
}

type Service struct {
	db     *database.Client
	logger *zap.Logger
}

var ErrUserNotFound = errors.New("user not found")

const DefaultPageSize = 20

import "errors"  // This won't compile, but represents the pattern of scattered declarations

type CreateUserInput struct {
	Name  string
	Email string
}

func (s *Service) Delete(ctx context.Context, id string) error { ... }

func New(db *database.Client, logger *zap.Logger) *Service {
	return &Service{db: db, logger: logger}
}

func (s *Service) Create(ctx context.Context, input CreateUserInput) (*User, error) { ... }

const MaxPageSize = 100  // constant between methods

func (s *Service) Get(ctx context.Context, id string) (*User, error) { ... }

type UserID = string  // type after methods
```

### GOOD — Structured File

```go
// Package users handles user-related business logic and persistence.
package users

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"go.uber.org/zap"

	"myapp/internal/database"
	"myapp/internal/models"
)

// --- Constants ---

const (
	DefaultPageSize = 20
	MaxPageSize     = 100
)

// --- Errors ---

var (
	ErrInvalidRole  = errors.New("invalid role")
	ErrUserNotFound = errors.New("user not found")
)

// --- Types ---

type UserID = string

type CreateUserInput struct {
	Name  string
	Email string
	Role  string
}

// --- Service ---

// Service handles user business logic.
type Service struct {
	db     *database.Client
	logger *zap.Logger
}

// New creates a new user Service.
func New(db *database.Client, logger *zap.Logger) *Service {
	return &Service{
		db:     db,
		logger: logger,
	}
}

// Create creates a new user from the given input.
func (s *Service) Create(ctx context.Context, input CreateUserInput) (*models.User, error) {
	if err := validateRole(input.Role); err != nil {
		return nil, err
	}
	id := generateID()
	...
}

// Get retrieves a single user by ID.
func (s *Service) Get(ctx context.Context, id UserID) (*models.User, error) {
	...
}

// List returns a paginated list of users.
func (s *Service) List(ctx context.Context, page, size int) ([]*models.User, error) {
	...
}

// Update updates an existing user.
func (s *Service) Update(ctx context.Context, id UserID, input CreateUserInput) (*models.User, error) {
	...
}

// Delete removes a user by ID.
func (s *Service) Delete(ctx context.Context, id UserID) error {
	...
}

// --- Private functions ---

func validateRole(role string) error {
	switch role {
	case "admin", "editor", "viewer":
		return nil
	default:
		return fmt.Errorf("%w: %s", ErrInvalidRole, role)
	}
}

func generateID() UserID {
	return fmt.Sprintf("usr_%s", uuid.New().String()[:24])
}
```

### BAD — Methods in Random Order Across Files

```go
// users/service.go
func (s *Service) Delete(...) error { ... }
func (s *Service) Create(...) (*User, error) { ... }
func (s *Service) Get(...) (*User, error) { ... }
func (s *Service) List(...) ([]*User, error) { ... }

// orders/service.go — completely different order
func (s *Service) Get(...) (*Order, error) { ... }
func (s *Service) List(...) ([]*Order, error) { ... }
func (s *Service) Delete(...) error { ... }
func (s *Service) Create(...) (*Order, error) { ... }
```

### GOOD — Consistent Method Order Across Files

```go
// users/service.go
func (s *Service) Create(...) (*User, error) { ... }
func (s *Service) Get(...) (*User, error) { ... }
func (s *Service) List(...) ([]*User, error) { ... }
func (s *Service) Update(...) (*User, error) { ... }
func (s *Service) Delete(...) error { ... }

// orders/service.go — same order
func (s *Service) Create(...) (*Order, error) { ... }
func (s *Service) Get(...) (*Order, error) { ... }
func (s *Service) List(...) ([]*Order, error) { ... }
func (s *Service) Update(...) (*Order, error) { ... }
func (s *Service) Delete(...) error { ... }
```

## Key Points

- **Every file has the same shape.** Docstring, imports, constants, types, classes, functions, entry point. Always. In every file.
- **Every class has the same shape.** Constants, constructor, public methods, private methods, static methods, special methods.
- **Public methods are in logical order, not alphabetical.** CRUD methods stay in CRUD order. Domain methods are grouped by feature.
- **Private helpers live next to their callers.** Not at the bottom in a "helpers" pile.
- **CRUD order is consistent across all service classes.** `create, get, list, update, delete` in every service, or a different order — but the same one everywhere.
- **Exports are alphabetized.** They are a lookup table, not a narrative.
- **Constants and types come before the code that uses them.** The reader should never have to scroll down to find a definition and then scroll back up.
