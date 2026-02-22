---
name: python-pedantry
description: "This skill should be used when the user is writing Python code and needs guidance on Python-specific pedantry: modern type syntax (str | None vs Optional), Pydantic BaseSettings for configuration centralization, StrEnum for string constants, exception chaining (raise X from e), Google-style docstrings, ruff rules, and Python-specific patterns that go beyond universal principles."
version: 1.0.0
---

# Python Has Opinions -- Follow Them

Python is not a language that tolerates sloppiness gracefully. It has a style guide (PEP 8). It has type hints (PEP 484, 604, 612). It has modern syntax that makes legacy patterns inexcusable. If you are writing Python in 2024+ and your code looks like it was written in 2018, you are not being "compatible" -- you are being lazy. Modern Python is expressive, precise, and strict. Write it that way.

## Modern Type Syntax: No Legacy Imports

Python 3.10+ supports union types with `|` and builtin generics. There is zero reason to import `Optional`, `List`, `Dict`, `Tuple`, `Set`, or `Union` from `typing` for type annotations. These legacy forms are visual clutter that signal the author has not updated their knowledge.

| Legacy (Do Not Use) | Modern (Use This) |
|---------------------|-------------------|
| `Optional[str]` | `str \| None` |
| `Union[str, int]` | `str \| int` |
| `List[str]` | `list[str]` |
| `Dict[str, Any]` | `dict[str, Any]` |
| `Tuple[int, ...]` | `tuple[int, ...]` |
| `Set[str]` | `set[str]` |
| `FrozenSet[int]` | `frozenset[int]` |
| `Type[MyClass]` | `type[MyClass]` |

```python
# BAD -- legacy typing imports
from typing import Optional, List, Dict, Tuple, Union

def fetch_users(
    org_id: str,
    limit: Optional[int] = None,
) -> List[Dict[str, Union[str, int]]]:
    ...
```

```python
# GOOD -- modern syntax, no unnecessary imports
def fetch_users(
    org_id: str,
    limit: int | None = None,
) -> list[dict[str, str | int]]:
    ...
```

The `typing` module is still needed for advanced types: `TypeVar`, `Generic`, `Protocol`, `Literal`, `TypedDict`, `Annotated`, `ClassVar`, `Final`, `ParamSpec`. Only these warrant a `typing` import. Ruff rule `UP006` and `UP007` enforce this automatically.

## ClassVar for Class-Level Attributes

Class attributes that belong to the class itself (not instances) must be annotated with `ClassVar`. This makes the intent explicit and prevents accidental instance-level shadowing.

```python
# BAD -- ambiguous: is this a class attribute or instance attribute?
class PaymentProcessor:
    MAX_RETRIES = 3
    SUPPORTED_CURRENCIES = ["USD", "EUR", "GBP"]
```

```python
# GOOD -- ClassVar makes the intent explicit
from typing import ClassVar

class PaymentProcessor:
    MAX_RETRIES: ClassVar[int] = 3
    SUPPORTED_CURRENCIES: ClassVar[list[str]] = ["USD", "EUR", "GBP"]
```

## Configuration Centralization with Pydantic BaseSettings

Scattered `os.getenv()` calls are the configuration equivalent of global variables. They are untestable, unvalidated, and invisible. Configuration belongs in one place: a Pydantic `BaseSettings` class that reads from environment variables, validates every value, and provides a single importable instance.

```python
# BAD -- configuration scattered across files
# In database.py
db_url = os.getenv("DATABASE_URL", "postgresql://localhost/myapp")
pool_size = int(os.getenv("DB_POOL_SIZE", "5"))

# In email.py
smtp_host = os.getenv("SMTP_HOST")  # None if missing -- crashes at runtime
smtp_port = os.getenv("SMTP_PORT", "587")  # It's a string, not an int

# In auth.py
secret_key = os.environ["SECRET_KEY"]  # KeyError if missing -- no context
token_ttl = int(os.getenv("TOKEN_TTL_SECONDS", "3600"))
```

```python
# GOOD -- one file, one class, one instance, fully validated
from pydantic import Field, field_validator
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}

    # Database
    database_url: str = Field(
        default="postgresql://localhost/myapp",
        description="PostgreSQL connection string",
    )
    db_pool_size: int = Field(default=5, ge=1, le=50)

    # Email
    smtp_host: str = Field(description="SMTP server hostname")
    smtp_port: int = Field(default=587, ge=1, le=65535)

    # Auth
    secret_key: str = Field(min_length=32, description="JWT signing key")
    token_ttl_seconds: int = Field(default=3600, ge=60, le=86400)

    @field_validator("database_url")
    @classmethod
    def validate_database_url(cls, v: str) -> str:
        if not v.startswith(("postgresql://", "postgres://")):
            raise ValueError("Only PostgreSQL URLs are supported")
        return v


# Global singleton -- import this, never call os.getenv()
settings = Settings()
```

```python
# Usage anywhere in the codebase:
from myapp.config import settings

engine = create_engine(settings.database_url, pool_size=settings.db_pool_size)
```

**The rule:** `os.getenv()` and `os.environ` never appear outside the settings file. Every other module imports `settings` and accesses typed, validated attributes.

## StrEnum for String Constants

Bare string comparisons are bugs waiting to happen. A typo in a string literal is a silent failure. A StrEnum member is a type-checked, autocomplete-friendly, grep-able constant.

```python
# BAD -- bare strings scatter and rot
def apply_discount(order: Order, discount_type: str) -> Order:
    if discount_type == "percentage":  # typo: "percantage" would silently fail
        ...
    elif discount_type == "fixed":
        ...
    elif discount_type == "bogo":
        ...

# Somewhere else in the codebase
order = apply_discount(order, "persentage")  # silent bug
```

```python
# GOOD -- StrEnum catches errors at write time
from enum import StrEnum


class DiscountType(StrEnum):
    PERCENTAGE = "percentage"
    FIXED = "fixed"
    BUY_ONE_GET_ONE = "bogo"


def apply_discount(order: Order, discount_type: DiscountType) -> Order:
    match discount_type:
        case DiscountType.PERCENTAGE:
            ...
        case DiscountType.FIXED:
            ...
        case DiscountType.BUY_ONE_GET_ONE:
            ...

# Usage -- autocomplete guides you, typos are caught by the type checker
order = apply_discount(order, DiscountType.PERCENTAGE)
```

`StrEnum` (Python 3.11+) serializes to its string value automatically, so it works seamlessly with JSON, databases, and APIs. No conversion needed.

## Exception Chaining: Always `raise X from e`

When catching an exception and raising a new one, ALWAYS chain with `from`. This preserves the original traceback, making debugging possible instead of impossible. Dropping the original exception is destroying evidence.

Ruff rule `B904` enforces this. Enable it. Never disable it.

```python
# BAD -- original exception is lost
try:
    user = db.fetch_user(user_id)
except DatabaseError as e:
    raise ServiceError(f"Failed to fetch user {user_id}")  # original traceback gone

# BAD -- swallowing and re-raising without chain
try:
    config = json.loads(raw_config)
except json.JSONDecodeError:
    raise ValueError("Invalid configuration format")  # what was the actual parse error?
```

```python
# GOOD -- exception chain preserves the full story
try:
    user = db.fetch_user(user_id)
except DatabaseError as e:
    raise ServiceError(f"Failed to fetch user {user_id}") from e

# GOOD -- chained, with context
try:
    config = json.loads(raw_config)
except json.JSONDecodeError as e:
    raise ValueError(f"Invalid configuration format at line {e.lineno}") from e
```

If you intentionally want to suppress the original exception (rare, and you better have a good reason), use `raise X from None` to make the suppression explicit.

## Google-Style Docstrings

Every public function, class, and method gets a docstring. Google style. One-line summary, blank line, then `Args`, `Returns`, `Raises` sections. Not NumPy style (too verbose). Not reStructuredText (unreadable). Google style.

```python
# BAD -- no docstring on a public function
def calculate_shipping(
    weight_kg: float,
    destination: str,
    is_expedited: bool = False,
) -> ShippingQuote:
    ...

# BAD -- docstring that repeats the signature
def calculate_shipping(weight_kg, destination, is_expedited=False):
    """Calculate shipping.

    :param weight_kg: The weight in kg.
    :param destination: The destination.
    :param is_expedited: Whether it's expedited.
    :returns: A ShippingQuote.
    """
    ...
```

```python
# GOOD -- Google-style docstring with actual information
def calculate_shipping(
    weight_kg: float,
    destination: str,
    is_expedited: bool = False,
) -> ShippingQuote:
    """Calculate shipping cost based on package weight and destination.

    Uses the carrier rate table for standard shipping. Expedited shipping
    applies a 2.5x multiplier and guarantees 2-day delivery.

    Args:
        weight_kg: Package weight. Must be between 0.1 and 70.0 kg.
        destination: ISO 3166-1 alpha-2 country code (e.g., "US", "DE").
        is_expedited: If True, use expedited carrier rates.

    Returns:
        A ShippingQuote with the calculated cost, estimated delivery date,
        and carrier name.

    Raises:
        WeightExceededError: If weight_kg is outside the allowed range.
        UnsupportedDestinationError: If the destination country is not served.
    """
    ...
```

**The docstring adds information the signature does not.** It explains constraints (0.1-70.0 kg), formats (ISO country codes), business logic (2.5x multiplier), and failure modes. If your docstring only restates the parameter names and types, delete it -- the type hints already do that.

## Ruff Rules to Enforce

Ruff is the Python linter. Not flake8. Not pylint. Not both. Ruff. It is faster, more comprehensive, and replaces all of them. These rule sets are non-negotiable:

| Rule Set | What It Catches |
|----------|----------------|
| `E` | PEP 8 style errors |
| `F` | Pyflakes: unused imports, undefined names, redefined names |
| `UP` | pyupgrade: legacy syntax that has a modern replacement |
| `B` | flake8-bugbear: common bugs (B904 = exception chaining) |
| `SIM` | flake8-simplify: unnecessarily complex code |
| `I` | isort: import ordering |
| `PLC` | pylint convention: naming, format |

```toml
# ruff.toml or pyproject.toml [tool.ruff]
[lint]
select = ["E", "F", "UP", "B", "SIM", "I", "PLC"]

[lint.isort]
known-first-party = ["myapp"]

[format]
line-length = 100
quote-style = "double"
```

## Pre-Commit Hooks

`ruff format` and `ruff check` run on every commit. Not in CI only -- on every commit, before the code leaves the developer's machine. This is non-negotiable.

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.8.0
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
```

## Protocol Over ABC for Interfaces

When you need structural typing (duck typing with type safety), use `Protocol` instead of `ABC`. Protocols do not require inheritance, which means any class that implements the right methods satisfies the protocol without knowing it exists.

```python
# BAD -- ABC forces inheritance, coupling the implementation to the interface
from abc import ABC, abstractmethod

class Repository(ABC):
    @abstractmethod
    def get(self, id: str) -> dict | None: ...

    @abstractmethod
    def save(self, entity: dict) -> None: ...

class UserRepository(Repository):  # must inherit
    def get(self, id: str) -> dict | None:
        ...

    def save(self, entity: dict) -> None:
        ...
```

```python
# GOOD -- Protocol enables structural typing
from typing import Protocol, runtime_checkable

@runtime_checkable
class Repository(Protocol):
    def get(self, id: str) -> dict | None: ...
    def save(self, entity: dict) -> None: ...

# No inheritance needed -- any class with get() and save() satisfies Repository
class UserRepository:
    def get(self, id: str) -> dict | None:
        ...

    def save(self, entity: dict) -> None:
        ...

def process(repo: Repository) -> None:
    # UserRepository satisfies Repository structurally
    ...
```

Use `ABC` when you need shared implementation (concrete methods on the base class). Use `Protocol` when you just need a contract.

## `__all__` Exports

Every `__init__.py` that re-exports symbols must have an explicit, alphabetized `__all__`. This makes the public API visible at a glance, prevents accidental exports, and enables `from mypackage import *` to work correctly (not that you should use star imports, but `__all__` is correct regardless).

```python
# BAD -- no __all__, everything is implicitly exported
# myapp/models/__init__.py
from myapp.models.user import User, UserCreate, UserUpdate
from myapp.models.order import Order, OrderStatus
from myapp.models.product import Product
```

```python
# GOOD -- explicit, alphabetized __all__
# myapp/models/__init__.py
from myapp.models.order import Order, OrderStatus
from myapp.models.product import Product
from myapp.models.user import User, UserCreate, UserUpdate

__all__ = [
    "Order",
    "OrderStatus",
    "Product",
    "User",
    "UserCreate",
    "UserUpdate",
]
```

## Examples

Working implementations in `examples/`:
- **`examples/pydantic-settings-centralization.md`** -- Complete example showing centralized Pydantic BaseSettings vs scattered os.getenv, with validation, environment file loading, and usage patterns
- **`examples/modern-type-syntax.md`** -- Side-by-side comparison of legacy typing imports vs modern Python 3.10+ type syntax, covering every common case

## Review Checklist

When reviewing Python code:

- [ ] No `Optional[X]` -- use `X | None`
- [ ] No `List[X]`, `Dict[K, V]`, `Tuple[X, ...]`, `Set[X]` -- use builtin generics `list[X]`, `dict[K, V]`, `tuple[X, ...]`, `set[X]`
- [ ] No `Union[X, Y]` -- use `X | Y`
- [ ] `ClassVar` is used for all class-level constants and shared attributes
- [ ] No `os.getenv()` or `os.environ` outside the settings module -- all config through Pydantic BaseSettings
- [ ] Pydantic settings has field validators with constraints (`ge`, `le`, `min_length`, `pattern`)
- [ ] String constants use `StrEnum`, not bare string literals
- [ ] Exception chaining: every `raise` inside an `except` block uses `from e` (ruff B904)
- [ ] Every public function has a Google-style docstring with Args/Returns/Raises (when applicable)
- [ ] Docstrings add information beyond what the type hints already convey
- [ ] Ruff is configured with at minimum: E, F, UP, B, SIM, I, PLC
- [ ] Pre-commit hooks run `ruff format` and `ruff check` on staged files
- [ ] `Protocol` is used for interfaces unless shared implementation is needed (then ABC)
- [ ] Every `__init__.py` with re-exports has an explicit, alphabetized `__all__`