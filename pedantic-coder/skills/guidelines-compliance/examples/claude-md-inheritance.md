# CLAUDE.md Inheritance Model

How guidelines accumulate through the directory hierarchy and how to check files at different depths.

## Example Repository Structure

```
myproject/
├── CLAUDE.md                          ← Level 0: project-wide
├── src/
│   ├── CLAUDE.md                      ← Level 1: source conventions
│   ├── models/
│   │   └── user.py
│   ├── services/
│   │   ├── CLAUDE.md                  ← Level 2: service conventions
│   │   ├── auth_service.py
│   │   └── payment_service.py
│   └── api/
│       └── routes.py
└── tests/
    ├── CLAUDE.md                      ← Level 1: test conventions
    └── test_auth.py
```

## The CLAUDE.md Files

### Root `CLAUDE.md` (applies to everything)

```markdown
# CLAUDE.md

## Build & Test
- Run tests: `pytest tests/`
- Run linter: `ruff check src/`

## Conventions
- Python 3.11+, use modern type syntax (str | None, not Optional[str])
- All functions must have Google-style docstrings
- Use snake_case for files, functions, variables
- Use PascalCase for classes
- Imports: stdlib first, third-party second, internal third
- No wildcard imports
```

### `src/CLAUDE.md` (applies to all source code)

```markdown
# Source Code Conventions

## Architecture
- models/ contains Pydantic models only — no business logic
- services/ contains business logic — no direct database calls
- api/ contains route handlers — thin wrappers around services

## Patterns
- All services accept dependencies via constructor injection
- All services return Result objects, never raise exceptions for expected failures
- Use StrEnum for all string constants, never bare string comparisons
```

### `src/services/CLAUDE.md` (applies to services only)

```markdown
# Service Conventions

## Structure
- One service class per file
- Service files named: {domain}_service.py
- Every service must have a corresponding test file

## Error Handling
- Services return ServiceResult[T] for operations that can fail
- Never catch broad Exception — catch specific types
- Log at WARNING for expected failures, ERROR for unexpected
```

### `tests/CLAUDE.md` (applies to tests only)

```markdown
# Test Conventions

## Structure
- Test files mirror source structure: src/services/auth_service.py → tests/test_auth_service.py
- Use pytest fixtures for shared setup
- Group tests in classes matching the class under test

## Mocking
- Use unittest.mock.AsyncMock for async methods
- Never mock the class under test, only its dependencies
- Patch at the point of use, not at the point of definition
```

## Applying the Inheritance Model

### File: `src/services/auth_service.py`

This file must comply with THREE levels of guidelines:

**Level 0 — Root `CLAUDE.md`:**
- Modern type syntax (str | None)
- Google-style docstrings on all functions
- snake_case naming
- Correct import ordering
- No wildcard imports

**Level 1 — `src/CLAUDE.md`:**
- No direct database calls (it's a service, not a model)
- Constructor injection for dependencies
- Return Result objects, never raise for expected failures
- Use StrEnum for string constants

**Level 2 — `src/services/CLAUDE.md`:**
- One service class per file
- File named {domain}_service.py
- Return ServiceResult[T]
- Catch specific exceptions, not broad Exception
- Log WARNING for expected, ERROR for unexpected

**Compliant example:**

```python
"""Authentication service for user login and token management."""

from enum import StrEnum

from structlog import get_logger

from myproject.models.user import User
from myproject.services.base import ServiceResult

logger = get_logger(__name__)


class AuthError(StrEnum):
    """Authentication error codes."""

    INVALID_CREDENTIALS = "invalid_credentials"
    ACCOUNT_LOCKED = "account_locked"
    TOKEN_EXPIRED = "token_expired"


class AuthService:
    """Handles user authentication and session management."""

    def __init__(self, user_repo: UserRepository, token_service: TokenService) -> None:
        """Initialize with injectable dependencies.

        Args:
            user_repo: Repository for user data access.
            token_service: Service for token generation and validation.
        """
        self.user_repo = user_repo
        self.token_service = token_service

    async def authenticate(self, email: str, password: str) -> ServiceResult[User]:
        """Authenticate a user by email and password.

        Args:
            email: User's email address.
            password: User's plaintext password.

        Returns:
            ServiceResult containing the authenticated User or an error.
        """
        user = await self.user_repo.find_by_email(email)
        if user is None:
            logger.warning("Authentication failed: unknown email", email=email)
            return ServiceResult.failure(AuthError.INVALID_CREDENTIALS)

        if not user.verify_password(password):
            logger.warning("Authentication failed: wrong password", user_id=user.id)
            return ServiceResult.failure(AuthError.INVALID_CREDENTIALS)

        return ServiceResult.success(user)
```

**This file satisfies all three levels:**
- Root: modern types, Google docstrings, snake_case, sorted imports, no wildcards
- src/: constructor injection, returns ServiceResult, StrEnum for error codes, no DB calls
- src/services/: one class per file, named auth_service.py, returns ServiceResult[User], catches nothing broadly, logs at WARNING

### File: `src/models/user.py`

This file must comply with TWO levels (no `src/models/CLAUDE.md` exists):

**Level 0 — Root `CLAUDE.md`:**
- Modern type syntax, docstrings, naming, imports

**Level 1 — `src/CLAUDE.md`:**
- models/ contains Pydantic models only — no business logic

**Violation example:**

```python
class User(BaseModel):
    """User model."""

    id: str
    email: str
    password_hash: str

    def verify_password(self, password: str) -> bool:
        """Check password against hash."""
        return bcrypt.checkpw(password.encode(), self.password_hash.encode())

    async def send_welcome_email(self) -> None:  # ← VIOLATION
        """Send welcome email to user."""
        await email_service.send(self.email, "Welcome!")
```

**Violation**: `src/CLAUDE.md` states "models/ contains Pydantic models only — no business logic." The `send_welcome_email` method is business logic that belongs in a service. The `verify_password` method is borderline — it's data validation tied to the model's own data, which is acceptable.

### File: `tests/test_auth_service.py`

This file must comply with TWO levels:

**Level 0 — Root `CLAUDE.md`:**
- Modern type syntax, docstrings, naming, imports

**Level 1 — `tests/CLAUDE.md`:**
- File mirrors source: test_auth_service.py matches auth_service.py
- Use pytest fixtures
- Group in classes matching class under test
- AsyncMock for async, patch at point of use

## Conflict Detection

If root `CLAUDE.md` says:
```
All functions must have Google-style docstrings
```

And `tests/CLAUDE.md` says:
```
Test functions do not need docstrings — the test name is the documentation
```

This is a **conflict**. Flag it:

```
GUIDELINE CONFLICT:
- CLAUDE.md (root): "All functions must have Google-style docstrings"
- tests/CLAUDE.md: "Test functions do not need docstrings"
Resolution needed: tests/CLAUDE.md should explicitly state it overrides
the root rule for test functions, or the root rule should exclude tests.
```

## Staleness Detection

Check for guidelines that reference things that no longer exist:

```
STALE GUIDELINE:
- src/services/CLAUDE.md states: "Services return ServiceResult[T]"
- But ServiceResult is not defined anywhere in the codebase
- Last reference was removed in commit abc123
- Action: Either implement ServiceResult or update the guideline
```

```
STALE GUIDELINE:
- CLAUDE.md (root) states: "Run linter: ruff check src/"
- But pyproject.toml does not list ruff as a dependency
- Action: Either add ruff to dependencies or update the build command
```
