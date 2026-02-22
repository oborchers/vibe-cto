---
name: declaration-order
description: "This skill should be used when the user is organizing code within a file, ordering class members, structuring module exports, or when a file has constants mixed with functions mixed with classes in no predictable order. Covers file-level ordering, class member ordering, and the rule that every file should have the same shape."
version: 1.0.0
---

# Every File Has the Same Shape

A developer opening any file in your project should know where to look without searching. Constants at the top. Types next. Then classes. Then functions. Then the entry point. Every file. Every time. No exceptions.

When a codebase has no consistent declaration order, every file is a treasure hunt. The reader ctrl-F's for the class definition, scrolls past a helper function wedged between two constants, finds a type alias buried after the main function, and wonders if the person who wrote this was shuffling a deck of cards. This is not an organizational preference — it is a readability debt that compounds with every file added to the project.

The rules below establish a universal shape for files and classes. The specific language idioms vary; the principle does not.

## File-Level Ordering

Every file follows this top-to-bottom sequence. Items that do not apply to a given file are simply absent — the order of what remains does not change.

```
1. Module docstring / file header comment
2. Imports (per the import-discipline skill)
3. Constants / module-level configuration
4. Type definitions / interfaces / type aliases
5. Classes
6. Module-level functions
7. Main / entry point (if applicable)
```

**Why this order:**
- **Docstring first** because the reader needs context before seeing code
- **Imports second** because they are the table of contents (see import-discipline)
- **Constants third** because they are referenced by everything below — defining them after the code that uses them forces the reader to jump upward
- **Types fourth** because classes and functions depend on them — a function signature referencing a type that is defined 200 lines later is a navigation failure
- **Classes fifth** because they are structural, self-contained units
- **Functions sixth** because they are the primary operations that use the types and constants above
- **Entry point last** because it is the culmination — it calls everything above, so it belongs at the bottom where the reader has already seen all dependencies

## Class Member Ordering

Inside every class, struct, or object, members follow this sequence:

```
1. Class-level constants / static properties
2. Constructor / __init__ / New
3. Public methods (grouped logically, not alphabetically)
4. Private / internal methods
5. Static methods / class methods
6. Special / dunder methods (Python: __str__, __repr__, __eq__)
```

**Logical grouping within public methods:** Group related methods together. If `create` exists alongside `update` and `delete`, they sit together in CRUD order, not scattered across the class. If a method has a helper, the helper follows it immediately.

**Why not alphabetical?** Alphabetical ordering breaks logical grouping. `close()` and `connect()` end up next to each other by accident; `disconnect()` is 50 lines away. CRUD methods get scrambled into `create`, `delete`, `read`, `update`. Logical grouping preserves the reader's mental model of how the class works.

## Export Ordering

When a module explicitly exports names (`__all__` in Python, `export` statements in TypeScript, exported functions in Go), those exports are alphabetized.

**Why alphabetical for exports but not methods?** Exports are a lookup table — the reader scans them to find a specific name. Alphabetical order makes that scan O(log n) instead of O(n). Methods are read in sequence to understand behavior, so logical order serves better.

```python
__all__ = [
    "CreateUserRequest",
    "DeleteUserRequest",
    "UpdateUserRequest",
    "User",
    "UserResponse",
    "UserService",
]
```

```typescript
export { CreateUserRequest } from "./requests";
export { DeleteUserRequest } from "./requests";
export { UpdateUserRequest } from "./requests";
export { User } from "./models";
export { UserResponse } from "./responses";
export { UserService } from "./service";
```

## Related Things Stay Together

A helper function belongs next to the function that calls it, not at the bottom of the file in a "helpers" section.

```python
# GOOD — helper is directly below its caller
def process_payment(order: Order) -> PaymentResult:
    validated = _validate_payment_details(order)
    ...

def _validate_payment_details(order: Order) -> bool:
    """Validate payment details before processing."""
    ...


def send_notification(user: User, message: str) -> None:
    formatted = _format_notification(message)
    ...

def _format_notification(message: str) -> str:
    """Format a notification message with standard template."""
    ...
```

```python
# BAD — helpers banished to the bottom, far from context
def process_payment(order: Order) -> PaymentResult:
    validated = _validate_payment_details(order)
    ...

def send_notification(user: User, message: str) -> None:
    formatted = _format_notification(message)
    ...

# ... 200 lines later ...

def _validate_payment_details(order: Order) -> bool:
    ...

def _format_notification(message: str) -> str:
    ...
```

The exception: truly shared utilities used by many functions. These belong in a separate utility module, not at the bottom of a file that happens to contain one of their callers.

## Consistency Across Files

If `UserService` orders its methods as `create`, `get`, `list`, `update`, `delete`, then `ProductService`, `OrderService`, and every other service in the project uses the same order. The reader learns the pattern once and applies it everywhere.

This extends to file structure. If every service module follows the pattern:

```
docstring → imports → constants → schemas → service class → factory function
```

Then deviating in one file — say, putting the factory function before the class — breaks the reader's autopilot and forces conscious navigation.

**Enforcement:** Document the ordering convention once in a project style guide or `CLAUDE.md`. Then follow it without exception. If someone new joins and asks "where do I put this?", the answer should be immediately obvious from any existing file.

## Python — Complete File Shape

```python
"""User service module.

Handles user CRUD operations and permission checks.
"""

from __future__ import annotations

import logging
from datetime import datetime, timezone
from uuid import uuid4

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from myapp.config import settings
from myapp.models import User

from .schemas import UserCreate, UserResponse

# --- Constants ---

DEFAULT_PAGE_SIZE = 20
MAX_PAGE_SIZE = 100
USER_CACHE_TTL_SECONDS = 300

# --- Types ---

type UserId = str

# --- Classes ---

class UserService:
    """Service for user-related operations."""

    # Class constants
    ALLOWED_ROLES = frozenset({"admin", "editor", "viewer"})
    MAX_LOGIN_ATTEMPTS = 5

    # Constructor
    def __init__(self, session: AsyncSession) -> None:
        self._session = session
        self._logger = logging.getLogger(__name__)

    # Public methods — CRUD order
    async def create(self, data: UserCreate) -> User:
        ...

    async def get(self, user_id: UserId) -> User:
        ...

    async def list(self, page: int = 1, size: int = DEFAULT_PAGE_SIZE) -> list[User]:
        ...

    async def update(self, user_id: UserId, data: UserCreate) -> User:
        ...

    async def delete(self, user_id: UserId) -> None:
        ...

    # Public methods — domain-specific
    async def change_role(self, user_id: UserId, role: str) -> User:
        self._validate_role(role)
        ...

    # Private methods
    def _validate_role(self, role: str) -> None:
        if role not in self.ALLOWED_ROLES:
            raise ValueError(f"Invalid role: {role}")

    def _generate_id(self) -> UserId:
        return f"usr_{uuid4().hex[:24]}"

    # Special methods
    def __repr__(self) -> str:
        return f"UserService(session={self._session!r})"


# --- Module-level functions ---

def create_user_service(session: AsyncSession) -> UserService:
    """Factory function for UserService."""
    return UserService(session)
```

## TypeScript — Complete File Shape

```typescript
/**
 * User service module.
 * Handles user CRUD operations and permission checks.
 */

import crypto from "node:crypto";

import { z } from "zod";

import { db } from "@/database";
import { logger } from "@/logger";

import type { UserRow } from "./types";

// --- Constants ---

const DEFAULT_PAGE_SIZE = 20;
const MAX_PAGE_SIZE = 100;
const USER_CACHE_TTL_SECONDS = 300;

const ALLOWED_ROLES = ["admin", "editor", "viewer"] as const;
type Role = (typeof ALLOWED_ROLES)[number];

// --- Types / Schemas ---

const createUserSchema = z.object({
  name: z.string().min(1),
  email: z.string().email(),
  role: z.enum(ALLOWED_ROLES),
});

type CreateUserInput = z.infer<typeof createUserSchema>;

interface User {
  id: string;
  name: string;
  email: string;
  role: Role;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

// --- Classes ---

class UserService {
  // Class constants
  static readonly MAX_LOGIN_ATTEMPTS = 5;

  // Constructor
  constructor(private readonly database: typeof db) {}

  // Public methods — CRUD order
  async create(input: CreateUserInput): Promise<User> {
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

  // Public methods — domain-specific
  async changeRole(userId: string, role: Role): Promise<User> {
    this.validateRole(role);
    ...
  }

  // Private methods
  private validateRole(role: string): asserts role is Role {
    if (!ALLOWED_ROLES.includes(role as Role)) {
      throw new Error(`Invalid role: ${role}`);
    }
  }

  private generateId(): string {
    return `usr_${crypto.randomBytes(12).toString("base64url")}`;
  }
}

// --- Module-level functions ---

export function createUserService(): UserService {
  return new UserService(db);
}
```

## Go — Complete File Shape

```go
// Package users handles user-related HTTP handlers and business logic.
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
	DefaultPageSize      = 20
	MaxPageSize          = 100
	UserCacheTTLSeconds  = 300
)

// --- Errors ---

var (
	ErrUserNotFound = errors.New("user not found")
	ErrInvalidRole  = errors.New("invalid role")
)

// --- Types ---

type UserID = string

type CreateUserInput struct {
	Name  string
	Email string
	Role  string
}

// --- Structs ---

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

// Public methods — CRUD order

// Create creates a new user.
func (s *Service) Create(ctx context.Context, input CreateUserInput) (*models.User, error) {
	...
}

// Get retrieves a user by ID.
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

// Public methods — domain-specific

// ChangeRole changes a user's role after validation.
func (s *Service) ChangeRole(ctx context.Context, id UserID, role string) (*models.User, error) {
	if err := validateRole(role); err != nil {
		return nil, err
	}
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

## Common Violations

**Constants scattered throughout the file.** A constant defined on line 150, between two functions, because "that's where I needed it." Constants go at the top, after imports. All of them.

**Types defined after the functions that use them.** A function signature references `UserResponse` but the type definition is 300 lines below. The reader must jump down, read the type, jump back up. Types go before functions.

**Class methods in random order.** `delete()` before `create()`, a private helper between two public methods, the constructor buried in the middle. The reader cannot predict where anything is. Follow the ordering convention.

**Helpers dumped at the bottom.** A `_validate()` function at line 500 that is only called by `create()` at line 50. The reader has to scroll 450 lines to find the implementation. Put it directly after `create()`.

**Inconsistent order across files.** `UserService` has `create, get, update, delete`. `OrderService` has `delete, list, create, get`. The reader's muscle memory is useless. Pick one CRUD order and use it everywhere.

**Exports not alphabetized.** `__all__ = ["User", "CreateUserRequest", "UserService", "UserResponse"]` — is `DeleteUserRequest` missing, or did the author just not alphabetize? You cannot tell without reading the entire module. Alphabetize exports.

## Examples

Working implementations in `examples/`:
- **`examples/file-structure.md`** — Multi-language examples (Python, TypeScript, Go) showing complete file structures with correct declaration ordering, class member ordering, and consistent patterns across service modules.

## Review Checklist

When organizing or reviewing code structure:

- [ ] File follows the universal order: docstring, imports, constants, types, classes, functions, entry point
- [ ] Constants are at the top of the file, after imports — not scattered between functions
- [ ] Type definitions appear before the classes and functions that use them
- [ ] Class members follow the order: constants, constructor, public methods, private methods, static methods, special methods
- [ ] Public methods are grouped logically (CRUD together, domain actions together) — not alphabetically
- [ ] Private helpers are placed directly after the public method that calls them
- [ ] Exports (`__all__`, `export` statements) are alphabetized
- [ ] CRUD method order is consistent across all service classes in the project
- [ ] File shape is consistent — opening any two files of the same type reveals the same structure
- [ ] No type is referenced before it is defined (types above functions, not below)
- [ ] Entry point / main function is at the bottom of the file
- [ ] Shared utilities live in utility modules, not at the bottom of unrelated files
