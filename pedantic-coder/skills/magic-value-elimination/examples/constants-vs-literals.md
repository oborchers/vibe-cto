# Constants vs Literals

Multi-language examples showing magic values replaced with named constants and enums. Every inline literal that carries meaning must have a name. These examples show the transformation from magic-ridden code to clean, greppable, maintainable constants.

## Python -- Before and After

### BAD -- Magic values everywhere

```python
import time
import httpx


def process_batch(items: list[dict]) -> list[dict]:
    results = []
    for i in range(0, len(items), 1000):
        batch = items[i:i + 1000]
        response = httpx.post(
            "https://api.example.com/v1/process",
            json={"items": batch},
            headers={"Content-Type": "application/json"},
            timeout=30,
        )
        if response.status_code == 200:
            results.extend(response.json()["results"])
        elif response.status_code == 429:
            time.sleep(60)
            continue
        else:
            raise Exception(f"API error: {response.status_code}")

    return results


def score_results(results: list[dict]) -> list[dict]:
    return [r for r in results if r["score"] >= 0.75]


def classify_user(user: dict) -> str:
    if user["login_count"] > 100:
        return "power_user"
    elif user["login_count"] > 10:
        return "regular"
    else:
        return "new"


def create_session(user_id: str) -> dict:
    return {
        "user_id": user_id,
        "expires_in": 86400,
        "max_requests": 10000,
        "token_type": "Bearer",
    }
```

Problems:
- `1000` -- batch size? Rate limit? Arbitrary cap?
- `30` -- seconds? Milliseconds?
- `200`, `429` -- not everyone memorizes HTTP codes
- `60` -- retry delay? Why sixty?
- `0.75` -- relevance threshold? Confidence score? Magic.
- `100`, `10` -- what makes these the boundaries?
- `"power_user"`, `"regular"`, `"new"` -- inline strings for a finite set
- `86400` -- classic: seconds per day, but you have to count zeros to verify
- `10000` -- max requests per what?
- `"Bearer"` -- protocol constant scattered as a string

### GOOD -- Named constants and enums

```python
import time
from enum import StrEnum

import httpx


# --- Constants ---
MAX_BATCH_SIZE = 1000
API_BASE_URL = "https://api.example.com/v1"
CONTENT_TYPE_JSON = "application/json"
HTTP_TIMEOUT_SECONDS = 30
RATE_LIMIT_RETRY_DELAY_SECONDS = 60
RELEVANCE_THRESHOLD = 0.75
POWER_USER_LOGIN_THRESHOLD = 100
REGULAR_USER_LOGIN_THRESHOLD = 10
SESSION_TTL_SECONDS = 86400  # 24 hours
MAX_REQUESTS_PER_SESSION = 10000
BEARER_TOKEN_TYPE = "Bearer"


# --- Enums ---
class UserTier(StrEnum):
    POWER_USER = "power_user"
    REGULAR = "regular"
    NEW = "new"


class HttpStatus(StrEnum):
    OK = "200"
    RATE_LIMITED = "429"


# --- Functions ---
def process_batch(items: list[dict]) -> list[dict]:
    results = []
    for i in range(0, len(items), MAX_BATCH_SIZE):
        batch = items[i:i + MAX_BATCH_SIZE]
        response = httpx.post(
            f"{API_BASE_URL}/process",
            json={"items": batch},
            headers={"Content-Type": CONTENT_TYPE_JSON},
            timeout=HTTP_TIMEOUT_SECONDS,
        )
        if response.status_code == int(HttpStatus.OK):
            results.extend(response.json()["results"])
        elif response.status_code == int(HttpStatus.RATE_LIMITED):
            time.sleep(RATE_LIMIT_RETRY_DELAY_SECONDS)
            continue
        else:
            raise Exception(f"API error: {response.status_code}")

    return results


def score_results(results: list[dict]) -> list[dict]:
    return [r for r in results if r["score"] >= RELEVANCE_THRESHOLD]


def classify_user(user: dict) -> UserTier:
    if user["login_count"] > POWER_USER_LOGIN_THRESHOLD:
        return UserTier.POWER_USER
    elif user["login_count"] > REGULAR_USER_LOGIN_THRESHOLD:
        return UserTier.REGULAR
    else:
        return UserTier.NEW


def create_session(user_id: str) -> dict:
    return {
        "user_id": user_id,
        "expires_in": SESSION_TTL_SECONDS,
        "max_requests": MAX_REQUESTS_PER_SESSION,
        "token_type": BEARER_TOKEN_TYPE,
    }
```

Every value has a name. Every name carries intent. Changing `MAX_BATCH_SIZE` from 1000 to 500 is one line. Searching for all timeout-related constants is a grep for `_SECONDS`.

## TypeScript -- Before and After

### BAD -- Inline literals in a service layer

```typescript
async function syncInventory(products: Product[]): Promise<SyncResult> {
  const results: SyncResult = { synced: 0, failed: 0, skipped: 0 };

  for (let i = 0; i < products.length; i += 50) {
    const batch = products.slice(i, i + 50);

    for (const product of batch) {
      if (product.stock < 0) {
        results.skipped++;
        continue;
      }

      for (let attempt = 0; attempt < 3; attempt++) {
        try {
          const response = await fetch("https://warehouse.example.com/api/sync", {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              "X-Api-Key": process.env.WAREHOUSE_API_KEY!,
            },
            body: JSON.stringify({
              sku: product.sku,
              quantity: product.stock,
              warehouse: "us-east-1",
            }),
            signal: AbortSignal.timeout(5000),
          });

          if (response.status === 200) {
            results.synced++;
            break;
          } else if (response.status === 409) {
            results.skipped++;
            break;
          } else if (response.status === 503) {
            await new Promise((r) => setTimeout(r, 1000 * Math.pow(2, attempt)));
            continue;
          } else {
            throw new Error(`Unexpected status: ${response.status}`);
          }
        } catch (err) {
          if (attempt === 2) {
            results.failed++;
          }
        }
      }
    }
  }

  return results;
}
```

### GOOD -- Named constants, typed enums

```typescript
// --- Constants ---
const SYNC_BATCH_SIZE = 50;
const MAX_SYNC_RETRIES = 3;
const SYNC_TIMEOUT_MS = 5000;
const RETRY_BASE_DELAY_MS = 1000;
const WAREHOUSE_API_URL = "https://warehouse.example.com/api/sync";
const DEFAULT_WAREHOUSE_ID = "us-east-1";
const MIN_VALID_STOCK = 0;

const CONTENT_TYPE_JSON = "application/json";
const API_KEY_HEADER = "X-Api-Key";

const HTTP_STATUS = {
  OK: 200,
  CONFLICT: 409,
  SERVICE_UNAVAILABLE: 503,
} as const;

// --- Function ---
async function syncInventory(products: Product[]): Promise<SyncResult> {
  const results: SyncResult = { synced: 0, failed: 0, skipped: 0 };

  for (let i = 0; i < products.length; i += SYNC_BATCH_SIZE) {
    const batch = products.slice(i, i + SYNC_BATCH_SIZE);

    for (const product of batch) {
      if (product.stock < MIN_VALID_STOCK) {
        results.skipped++;
        continue;
      }

      const lastAttemptIndex = MAX_SYNC_RETRIES - 1;

      for (let attempt = 0; attempt < MAX_SYNC_RETRIES; attempt++) {
        try {
          const response = await fetch(WAREHOUSE_API_URL, {
            method: "POST",
            headers: {
              "Content-Type": CONTENT_TYPE_JSON,
              [API_KEY_HEADER]: process.env.WAREHOUSE_API_KEY!,
            },
            body: JSON.stringify({
              sku: product.sku,
              quantity: product.stock,
              warehouse: DEFAULT_WAREHOUSE_ID,
            }),
            signal: AbortSignal.timeout(SYNC_TIMEOUT_MS),
          });

          if (response.status === HTTP_STATUS.OK) {
            results.synced++;
            break;
          } else if (response.status === HTTP_STATUS.CONFLICT) {
            results.skipped++;
            break;
          } else if (response.status === HTTP_STATUS.SERVICE_UNAVAILABLE) {
            const delay = RETRY_BASE_DELAY_MS * Math.pow(2, attempt);
            await new Promise((r) => setTimeout(r, delay));
            continue;
          } else {
            throw new Error(`Unexpected status: ${response.status}`);
          }
        } catch (err) {
          if (attempt === lastAttemptIndex) {
            results.failed++;
          }
        }
      }
    }
  }

  return results;
}
```

Every number and string has a name. The retry logic is readable: `MAX_SYNC_RETRIES` attempts with `RETRY_BASE_DELAY_MS` exponential backoff. The HTTP status checks read like English: `HTTP_STATUS.SERVICE_UNAVAILABLE` instead of `503`.

## Go -- Before and After

### BAD -- Magic values in a cache wrapper

```go
package cache

import (
    "context"
    "encoding/json"
    "fmt"
    "time"

    "github.com/redis/go-redis/v9"
)

type Cache struct {
    client *redis.Client
}

func (c *Cache) Get(ctx context.Context, key string) ([]byte, error) {
    val, err := c.client.Get(ctx, key).Bytes()
    if err != nil {
        return nil, fmt.Errorf("cache get failed: %w", err)
    }
    return val, nil
}

func (c *Cache) Set(ctx context.Context, key string, value interface{}) error {
    data, err := json.Marshal(value)
    if err != nil {
        return fmt.Errorf("cache marshal failed: %w", err)
    }
    return c.client.Set(ctx, key, data, 900*time.Second).Err()
}

func (c *Cache) SetSession(ctx context.Context, sessionID string, data interface{}) error {
    bytes, _ := json.Marshal(data)
    return c.client.Set(ctx, "sess:"+sessionID, bytes, 86400*time.Second).Err()
}

func (c *Cache) SetRateLimit(ctx context.Context, clientIP string, count int) error {
    key := "rl:" + clientIP
    pipe := c.client.Pipeline()
    pipe.Set(ctx, key, count, 0)
    pipe.Expire(ctx, key, 60*time.Second)
    _, err := pipe.Exec(ctx)
    return err
}

func (c *Cache) IncrementCounter(ctx context.Context, name string) error {
    key := "counter:" + name
    c.client.Incr(ctx, key)
    c.client.Expire(ctx, key, 3600*time.Second)
    return nil
}
```

`900`, `86400`, `60`, `3600` -- four different TTL values as raw numbers. `"sess:"`, `"rl:"`, `"counter:"` -- key prefixes as inline strings.

### GOOD -- Named constants with units

```go
package cache

import (
    "context"
    "encoding/json"
    "fmt"
    "time"

    "github.com/redis/go-redis/v9"
)

const (
    // TTL durations
    DefaultCacheTTL     = 15 * time.Minute  // 900 seconds
    SessionTTL          = 24 * time.Hour     // 86400 seconds
    RateLimitWindowTTL  = 1 * time.Minute    // 60 seconds
    CounterTTL          = 1 * time.Hour      // 3600 seconds

    // Key prefixes
    SessionKeyPrefix    = "sess:"
    RateLimitKeyPrefix  = "rl:"
    CounterKeyPrefix    = "counter:"
)

type Cache struct {
    client *redis.Client
}

func (c *Cache) Get(ctx context.Context, key string) ([]byte, error) {
    val, err := c.client.Get(ctx, key).Bytes()
    if err != nil {
        return nil, fmt.Errorf("cache get failed: %w", err)
    }
    return val, nil
}

func (c *Cache) Set(ctx context.Context, key string, value interface{}) error {
    data, err := json.Marshal(value)
    if err != nil {
        return fmt.Errorf("cache marshal failed: %w", err)
    }
    return c.client.Set(ctx, key, data, DefaultCacheTTL).Err()
}

func (c *Cache) SetSession(ctx context.Context, sessionID string, data interface{}) error {
    bytes, err := json.Marshal(data)
    if err != nil {
        return fmt.Errorf("cache marshal failed: %w", err)
    }
    key := SessionKeyPrefix + sessionID
    return c.client.Set(ctx, key, bytes, SessionTTL).Err()
}

func (c *Cache) SetRateLimit(ctx context.Context, clientIP string, count int) error {
    key := RateLimitKeyPrefix + clientIP
    pipe := c.client.Pipeline()
    pipe.Set(ctx, key, count, 0)
    pipe.Expire(ctx, key, RateLimitWindowTTL)
    _, err := pipe.Exec(ctx)
    return err
}

func (c *Cache) IncrementCounter(ctx context.Context, name string) error {
    key := CounterKeyPrefix + name
    pipe := c.client.Pipeline()
    pipe.Incr(ctx, key)
    pipe.Expire(ctx, key, CounterTTL)
    _, err := pipe.Exec(ctx)
    return err
}
```

`DefaultCacheTTL = 15 * time.Minute` is self-documenting -- no mental arithmetic needed. `SessionKeyPrefix` is greppable. Changing the session TTL from 24 hours to 12 hours is a one-line change in one place.

## The Enum Advantage -- Exhaustiveness Checking

### Python -- match statement with StrEnum

```python
from enum import StrEnum


class NotificationType(StrEnum):
    EMAIL = "email"
    SMS = "sms"
    PUSH = "push"
    WEBHOOK = "webhook"


def send_notification(type_: NotificationType, recipient: str, message: str) -> None:
    match type_:
        case NotificationType.EMAIL:
            send_email(recipient, message)
        case NotificationType.SMS:
            send_sms(recipient, message)
        case NotificationType.PUSH:
            send_push(recipient, message)
        case NotificationType.WEBHOOK:
            send_webhook(recipient, message)
        # Adding NotificationType.SLACK requires updating this match --
        # linters will warn about the missing case.
```

### TypeScript -- switch with exhaustive check

```typescript
const NOTIFICATION_TYPE = {
  EMAIL: "email",
  SMS: "sms",
  PUSH: "push",
  WEBHOOK: "webhook",
} as const;

type NotificationType = (typeof NOTIFICATION_TYPE)[keyof typeof NOTIFICATION_TYPE];

function sendNotification(type: NotificationType, recipient: string, message: string): void {
  switch (type) {
    case NOTIFICATION_TYPE.EMAIL:
      sendEmail(recipient, message);
      break;
    case NOTIFICATION_TYPE.SMS:
      sendSms(recipient, message);
      break;
    case NOTIFICATION_TYPE.PUSH:
      sendPush(recipient, message);
      break;
    case NOTIFICATION_TYPE.WEBHOOK:
      sendWebhook(recipient, message);
      break;
    default:
      // Exhaustiveness check: TypeScript errors if a case is missing
      const _exhaustive: never = type;
      throw new Error(`Unhandled notification type: ${_exhaustive}`);
  }
}
```

### Go -- typed switch

```go
type NotificationType string

const (
    NotificationTypeEmail   NotificationType = "email"
    NotificationTypeSMS     NotificationType = "sms"
    NotificationTypePush    NotificationType = "push"
    NotificationTypeWebhook NotificationType = "webhook"
)

func SendNotification(t NotificationType, recipient, message string) error {
    switch t {
    case NotificationTypeEmail:
        return sendEmail(recipient, message)
    case NotificationTypeSMS:
        return sendSMS(recipient, message)
    case NotificationTypePush:
        return sendPush(recipient, message)
    case NotificationTypeWebhook:
        return sendWebhook(recipient, message)
    default:
        return fmt.Errorf("unknown notification type: %s", t)
    }
}
```

## Key Points

- Every number that is not 0, 1, or -1 in an obvious context gets a name
- Every string from a finite set becomes an enum member, not an inline literal
- Constant names include units where applicable: `_SECONDS`, `_MS`, `_BYTES`, `_MINUTES`
- Time durations use language-native duration types when available (`time.Minute` in Go, not `60`)
- Enums give you autocompletion, compile-time checking, and exhaustiveness checking -- inline strings give you typos in production
- If you can grep for a constant name and find every usage, you can change it safely. If you grep for `"pending"` you will find comments, documentation, and unrelated strings alongside actual usages
- The cost of naming a value is one line. The cost of not naming it is every reader, every time, forever
