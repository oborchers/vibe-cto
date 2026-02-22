# Whitespace as Punctuation

Multi-language examples showing well-paced vs poorly-paced code. The visual structure of code communicates as much as the logic. These examples demonstrate the same functionality with different whitespace approaches -- only the well-paced version is acceptable.

## Python: Configuration Loader

### Poorly Paced -- The Wall

```python
class ConfigLoader:
    def __init__(self, config_path: str):
        self.config_path = config_path
        self.config: dict[str, Any] = {}
        self.validators: list[Callable] = []
        self.is_loaded = False
    def register_validator(self, validator: Callable) -> None:
        self.validators.append(validator)
    def load(self) -> dict[str, Any]:
        if self.is_loaded:
            return self.config
        raw = self._read_file()
        parsed = self._parse(raw)
        for validator in self.validators:
            errors = validator(parsed)
            if errors:
                raise ConfigValidationError(errors)
        self.config = parsed
        self.is_loaded = True
        return self.config
    def _read_file(self) -> str:
        with open(self.config_path) as f:
            return f.read()
    def _parse(self, raw: str) -> dict[str, Any]:
        if self.config_path.endswith(".json"):
            return json.loads(raw)
        elif self.config_path.endswith(".yaml"):
            return yaml.safe_load(raw)
        else:
            raise UnsupportedFormatError(self.config_path)
    def reload(self) -> dict[str, Any]:
        self.is_loaded = False
        self.config = {}
        return self.load()
```

### Well Paced -- Sections Breathe

```python
class ConfigLoader:
    def __init__(self, config_path: str):
        self.config_path = config_path
        self.config: dict[str, Any] = {}
        self.validators: list[Callable] = []
        self.is_loaded = False

    def register_validator(self, validator: Callable) -> None:
        self.validators.append(validator)

    def load(self) -> dict[str, Any]:
        if self.is_loaded:
            return self.config

        raw = self._read_file()
        parsed = self._parse(raw)

        for validator in self.validators:
            errors = validator(parsed)
            if errors:
                raise ConfigValidationError(errors)

        self.config = parsed
        self.is_loaded = True

        return self.config

    def _read_file(self) -> str:
        with open(self.config_path) as f:
            return f.read()

    def _parse(self, raw: str) -> dict[str, Any]:
        if self.config_path.endswith(".json"):
            return json.loads(raw)
        elif self.config_path.endswith(".yaml"):
            return yaml.safe_load(raw)
        else:
            raise UnsupportedFormatError(self.config_path)

    def reload(self) -> dict[str, Any]:
        self.is_loaded = False
        self.config = {}
        return self.load()
```

**What changed:** One blank line between methods. One blank line between logical sections inside `load()` (early return, parsing, validation, assignment). The file now has a scannable shape.

## TypeScript: API Client with Retry Logic

### Poorly Paced -- Random Spacing

```typescript
import { z } from "zod";


import type { Logger } from "./logger";
import type { Config } from "./config";



const DEFAULT_RETRIES = 3;
const DEFAULT_TIMEOUT_MS = 5000;
const BACKOFF_MULTIPLIER = 2;

interface RequestOptions {
  method: "GET" | "POST" | "PUT" | "DELETE";
  path: string;

  body?: unknown;
  headers?: Record<string, string>;
  retries?: number;

}
export class ApiClient {

  private baseUrl: string;
  private logger: Logger;

  private defaultHeaders: Record<string, string>;

  constructor(config: Config, logger: Logger) {

    this.baseUrl = config.apiBaseUrl;
    this.logger = logger;
    this.defaultHeaders = {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${config.apiKey}`,
    };
  }

  async request<T>(options: RequestOptions, schema: z.ZodType<T>): Promise<T> {
    const maxRetries = options.retries ?? DEFAULT_RETRIES;

    let lastError: Error | null = null;
    for (let attempt = 0; attempt <= maxRetries; attempt++) {

      try {

        const response = await this.executeRequest(options);
        const data = await response.json();
        return schema.parse(data);

      } catch (error) {

        lastError = error as Error;
        this.logger.warn(`Request failed (attempt ${attempt + 1}/${maxRetries + 1})`, { error });

        if (attempt < maxRetries) {

          const delay = DEFAULT_TIMEOUT_MS * Math.pow(BACKOFF_MULTIPLIER, attempt);
          await this.sleep(delay);

        }
      }

    }

    throw lastError;
  }


  private async executeRequest(options: RequestOptions): Promise<Response> {
    const url = `${this.baseUrl}${options.path}`;

    return fetch(url, {

      method: options.method,
      headers: { ...this.defaultHeaders, ...options.headers },
      body: options.body ? JSON.stringify(options.body) : undefined,

    });
  }

  private sleep(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

}
```

### Well Paced -- Deliberate Rhythm

```typescript
import { z } from "zod";
import type { Logger } from "./logger";
import type { Config } from "./config";

const DEFAULT_RETRIES = 3;
const DEFAULT_TIMEOUT_MS = 5000;
const BACKOFF_MULTIPLIER = 2;

interface RequestOptions {
  method: "GET" | "POST" | "PUT" | "DELETE";
  path: string;
  body?: unknown;
  headers?: Record<string, string>;
  retries?: number;
}


export class ApiClient {
  private baseUrl: string;
  private logger: Logger;
  private defaultHeaders: Record<string, string>;

  constructor(config: Config, logger: Logger) {
    this.baseUrl = config.apiBaseUrl;
    this.logger = logger;
    this.defaultHeaders = {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${config.apiKey}`,
    };
  }

  async request<T>(options: RequestOptions, schema: z.ZodType<T>): Promise<T> {
    const maxRetries = options.retries ?? DEFAULT_RETRIES;
    let lastError: Error | null = null;

    for (let attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        const response = await this.executeRequest(options);
        const data = await response.json();
        return schema.parse(data);
      } catch (error) {
        lastError = error as Error;
        this.logger.warn(`Request failed (attempt ${attempt + 1}/${maxRetries + 1})`, { error });

        if (attempt < maxRetries) {
          const delay = DEFAULT_TIMEOUT_MS * Math.pow(BACKOFF_MULTIPLIER, attempt);
          await this.sleep(delay);
        }
      }
    }

    throw lastError;
  }

  private async executeRequest(options: RequestOptions): Promise<Response> {
    const url = `${this.baseUrl}${options.path}`;

    return fetch(url, {
      method: options.method,
      headers: { ...this.defaultHeaders, ...options.headers },
      body: options.body ? JSON.stringify(options.body) : undefined,
    });
  }

  private sleep(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
}
```

**What changed:** Imports grouped without random extra blank lines. Interface fields not randomly separated. No blank lines inside object literals or between opening braces and first statements. No 3+ consecutive blank lines. Two blank lines before the class (top-level separation). One blank line between methods.

## Go: HTTP Handler with Middleware

### Poorly Paced -- Cramped and Inconsistent

```go
package handler
import (
	"encoding/json"
	"fmt"
	"log/slog"
	"net/http"
	"time"
)
type Handler struct {
	db     *sql.DB
	logger *slog.Logger
	cache  *Cache
}
func NewHandler(db *sql.DB, logger *slog.Logger, cache *Cache) *Handler {
	return &Handler{db: db, logger: logger, cache: cache}
}
func (h *Handler) GetUser(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	userID := r.PathValue("id")
	if userID == "" {
		writeError(w, http.StatusBadRequest, "missing user ID")
		return
	}
	cached, ok := h.cache.Get(userID)
	if ok {
		writeJSON(w, http.StatusOK, cached)
		return
	}
	user, err := h.db.GetUser(ctx, userID)
	if err != nil {
		h.logger.Error("failed to fetch user", "user_id", userID, "error", err)
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}
	if user == nil {
		writeError(w, http.StatusNotFound, "user not found")
		return
	}
	h.cache.Set(userID, user, 5*time.Minute)
	writeJSON(w, http.StatusOK, user)
}
func writeJSON(w http.ResponseWriter, status int, data any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}
func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, map[string]string{"error": message})
}
```

### Well Paced -- Clear Sections

```go
package handler

import (
	"encoding/json"
	"log/slog"
	"net/http"
	"time"
)

type Handler struct {
	db     *sql.DB
	logger *slog.Logger
	cache  *Cache
}

func NewHandler(db *sql.DB, logger *slog.Logger, cache *Cache) *Handler {
	return &Handler{db: db, logger: logger, cache: cache}
}

func (h *Handler) GetUser(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	userID := r.PathValue("id")

	if userID == "" {
		writeError(w, http.StatusBadRequest, "missing user ID")
		return
	}

	cached, ok := h.cache.Get(userID)
	if ok {
		writeJSON(w, http.StatusOK, cached)
		return
	}

	user, err := h.db.GetUser(ctx, userID)
	if err != nil {
		h.logger.Error("failed to fetch user", "user_id", userID, "error", err)
		writeError(w, http.StatusInternalServerError, "internal error")
		return
	}

	if user == nil {
		writeError(w, http.StatusNotFound, "user not found")
		return
	}

	h.cache.Set(userID, user, 5*time.Minute)
	writeJSON(w, http.StatusOK, user)
}

func writeJSON(w http.ResponseWriter, status int, data any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, map[string]string{"error": message})
}
```

**What changed:** Blank line after `package` declaration. Blank line between import block and first type. Blank line between each top-level declaration. Inside `GetUser`, blank lines separate: context extraction, input validation, cache check, database fetch, error handling, not-found check, and the final success path. Each blank line marks a logical transition.

## Key Points

- Blank lines are paragraph breaks -- they separate ideas, not individual statements
- The visual shape of a function should reveal its logical sections at a glance
- One blank line between related things, two blank lines between major sections, zero blank lines within a single thought
- Never more than two consecutive blank lines
- Random spacing (extra blank lines in some places, none in others) is worse than no spacing at all because it adds visual noise without meaning
- Formatters (prettier, black, gofmt) handle indentation and some spacing, but logical section breaks are the developer's responsibility