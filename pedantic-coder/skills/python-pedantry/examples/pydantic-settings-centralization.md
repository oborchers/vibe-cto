# Pydantic Settings Centralization

Complete example showing centralized configuration with Pydantic BaseSettings versus the scattered `os.getenv()` anti-pattern. The centralized approach validates every value at startup, provides type safety, and gives the entire codebase a single source of truth for configuration.

## The Problem: Scattered os.getenv()

```python
# database.py -- config is here
import os

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://localhost/myapp")
DB_POOL_SIZE = int(os.getenv("DB_POOL_SIZE", "5"))  # crashes on "abc"
DB_POOL_TIMEOUT = int(os.getenv("DB_POOL_TIMEOUT", "30"))

engine = create_engine(DATABASE_URL, pool_size=DB_POOL_SIZE)


# email.py -- config is also here
import os

SMTP_HOST = os.getenv("SMTP_HOST")  # None if missing, crashes later
SMTP_PORT = os.getenv("SMTP_PORT", "587")  # it's a string, not an int
SMTP_USER = os.getenv("SMTP_USER", "")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD", "")  # empty string default is wrong


# auth.py -- config is also here
import os

SECRET_KEY = os.environ["SECRET_KEY"]  # KeyError at import time, no context
TOKEN_TTL = int(os.getenv("TOKEN_TTL_SECONDS", "3600"))
REFRESH_TTL = int(os.getenv("REFRESH_TTL_SECONDS", "604800"))
ALLOWED_ORIGINS = os.getenv("ALLOWED_ORIGINS", "http://localhost:3000").split(",")


# cache.py -- config is also here too
import os

REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")
CACHE_TTL = int(os.getenv("CACHE_TTL_SECONDS", "300"))
```

**What is wrong with this:**
- Config is scattered across 4+ files -- no single place to see all required variables
- No validation -- `DB_POOL_SIZE=abc` crashes at runtime, not at startup
- No type safety -- `SMTP_PORT` is a string, not an int
- Missing variables surface as `None` deep in the call stack, not at startup
- No documentation of what environment variables exist or what they accept
- Testing requires monkeypatching `os.environ` in every test file
- Duplicated patterns (`int(os.getenv(..., "..."))`) that are easy to get wrong

## The Solution: Pydantic BaseSettings

```python
# myapp/config.py -- the ONE place configuration lives
from pydantic import Field, field_validator
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings loaded from environment variables.

    All configuration is validated at startup. Missing required variables
    cause an immediate, clear error. Invalid values are rejected with
    descriptive messages.
    """

    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8",
        "env_prefix": "",
        "case_sensitive": False,
    }

    # --- Database ---

    database_url: str = Field(
        default="postgresql://localhost/myapp",
        description="PostgreSQL connection string",
    )
    db_pool_size: int = Field(default=5, ge=1, le=50)
    db_pool_timeout: int = Field(default=30, ge=5, le=300)

    @field_validator("database_url")
    @classmethod
    def validate_database_url(cls, v: str) -> str:
        if not v.startswith(("postgresql://", "postgres://")):
            raise ValueError("Only PostgreSQL connection strings are supported")
        return v

    # --- Email ---

    smtp_host: str = Field(description="SMTP server hostname")
    smtp_port: int = Field(default=587, ge=1, le=65535)
    smtp_user: str = Field(default="", description="SMTP auth username")
    smtp_password: str = Field(default="", description="SMTP auth password")

    # --- Auth ---

    secret_key: str = Field(
        min_length=32,
        description="JWT signing key -- must be at least 32 characters",
    )
    token_ttl_seconds: int = Field(default=3600, ge=60, le=86400)
    refresh_ttl_seconds: int = Field(default=604800, ge=3600, le=2592000)
    allowed_origins: list[str] = Field(
        default=["http://localhost:3000"],
        description="CORS allowed origins",
    )

    @field_validator("allowed_origins", mode="before")
    @classmethod
    def parse_allowed_origins(cls, v: str | list[str]) -> list[str]:
        if isinstance(v, str):
            return [origin.strip() for origin in v.split(",") if origin.strip()]
        return v

    # --- Cache ---

    redis_url: str = Field(
        default="redis://localhost:6379/0",
        description="Redis connection string",
    )
    cache_ttl_seconds: int = Field(default=300, ge=0, le=86400)


# Global singleton -- import this everywhere
settings = Settings()
```

## Usage Across the Codebase

```python
# database.py -- clean, no os.getenv
from myapp.config import settings

engine = create_engine(
    settings.database_url,
    pool_size=settings.db_pool_size,
    pool_timeout=settings.db_pool_timeout,
)


# email.py -- clean, typed values
from myapp.config import settings

def create_smtp_client() -> SMTPClient:
    return SMTPClient(
        host=settings.smtp_host,
        port=settings.smtp_port,  # already an int
        username=settings.smtp_user,
        password=settings.smtp_password,
    )


# auth.py -- clean, validated at startup
from myapp.config import settings

def create_token(user_id: str) -> str:
    return jwt.encode(
        {"sub": user_id, "exp": datetime.now() + timedelta(seconds=settings.token_ttl_seconds)},
        settings.secret_key,
        algorithm="HS256",
    )
```

## Testing with Settings Override

```python
# tests/conftest.py
import pytest
from myapp.config import Settings


@pytest.fixture
def test_settings() -> Settings:
    """Provide test settings without touching environment variables."""
    return Settings(
        database_url="postgresql://localhost/myapp_test",
        smtp_host="localhost",
        secret_key="test-secret-key-that-is-at-least-32-chars",
        redis_url="redis://localhost:6379/1",
    )


@pytest.fixture(autouse=True)
def override_settings(test_settings: Settings, monkeypatch: pytest.MonkeyPatch) -> None:
    """Replace the global settings instance for all tests."""
    monkeypatch.setattr("myapp.config.settings", test_settings)
```

## Startup Error Messages

When the application starts with invalid or missing configuration, Pydantic provides clear, actionable error messages:

```
pydantic_core._pydantic_core.ValidationError: 2 validation errors for Settings
smtp_host
  Field required [type=missing, input_value={...}, input_type=dict]
secret_key
  String should have at least 32 characters [type=string_too_short,
  input_value='short', input_type=str]
```

This fails immediately at startup, not 3 hours into production when the email service is first called.

## Key Points

- Configuration lives in exactly one file and one class -- `Settings` in `config.py`
- Every value is typed and validated with constraints (`ge`, `le`, `min_length`, `pattern`)
- Missing required variables fail at startup with clear error messages, not at runtime with `NoneType has no attribute`
- `os.getenv()` and `os.environ` never appear outside the settings file
- The global `settings = Settings()` instance is imported everywhere -- no function calls, no re-reading env vars
- Testing overrides the singleton, not the environment -- clean, fast, explicit
- Field validators handle parsing (comma-separated strings to lists) and business rules (only PostgreSQL URLs)