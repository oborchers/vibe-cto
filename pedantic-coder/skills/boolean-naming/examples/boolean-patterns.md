# Boolean Naming Patterns

Multi-language examples showing bad-to-good boolean naming transformations. Every boolean must read as a yes/no question, use a proper prefix, and be named in the positive.

## Python

### BAD — Variables

```python
class UserAccount:
    def __init__(self, username: str):
        self.username = username
        self.active = True           # bool? str? no prefix
        self.admin = False           # bool? str? object?
        self.logged_in = False       # missing prefix
        self.email_verified = False  # missing prefix
        self.not_banned = True       # negative name
        self.flag = False            # meaningless
        self.status = True           # ambiguous type
        self.subscription = False    # bool? object?

    def check_permission(self, resource: str) -> bool:  # "check" is not a question
        ...

    def validate(self) -> bool:  # validate what? implies side effects
        ...

    def get_active(self) -> bool:  # "get" implies returning data
        ...
```

### GOOD — Variables

```python
class UserAccount:
    def __init__(self, username: str):
        self.username = username
        self.is_active = True
        self.is_admin = False
        self.is_logged_in = False
        self.is_email_verified = False
        self.is_banned = False             # positive name; check `if self.is_banned`
        self.is_debug_mode_enabled = False # specific, prefixed
        self.has_subscription = False      # has = possession

    def has_permission(self, resource: str) -> bool:
        """Check whether this user has access to the given resource."""
        ...

    def is_valid(self) -> bool:
        """Return True if the account passes all validation rules."""
        ...

    def is_active_subscriber(self) -> bool:
        """Return True if the user has an active, non-expired subscription."""
        ...
```

### BAD — Function Parameters

```python
def send_email(
    to: str,
    subject: str,
    body: str,
    html: bool = False,       # html what? is html? has html? sends html?
    urgent: bool = False,     # adjective without prefix
    retry: bool = True,       # verb without prefix
    log: bool = True,         # verb without prefix
):
    ...

# Call site is unreadable:
send_email("user@example.com", "Hello", "Body", True, False, True, True)
```

### GOOD — Function Parameters

```python
def send_email(
    to: str,
    subject: str,
    body: str,
    is_html: bool = False,
    is_urgent: bool = False,
    should_retry: bool = True,
    should_log: bool = True,
):
    ...

# Call site reads like English:
send_email(
    to="user@example.com",
    subject="Hello",
    body="Body",
    is_html=True,
    is_urgent=False,
    should_retry=True,
    should_log=True,
)
```

### BAD — Conditionals with Negative Names

```python
is_not_ready = not check_readiness()
is_disabled = get_disabled_state()
has_no_permission = not lookup_permission(user, resource)

# Double negatives — brain damage:
if not is_not_ready:
    proceed()

if not is_disabled:
    enable_feature()

if not has_no_permission:
    grant_access()
```

### GOOD — Conditionals with Positive Names

```python
is_ready = check_readiness()
is_enabled = not get_disabled_state()
has_permission = lookup_permission(user, resource)

# Single negation — clear:
if is_ready:
    proceed()

if not is_enabled:
    show_disabled_message()

if not has_permission:
    deny_access()
```

## TypeScript

### BAD — Interface Properties

```typescript
interface UserProfile {
  name: string;
  email: string;
  active: boolean;          // ambiguous type without prefix
  admin: boolean;           // could be string, object, or ID
  verified: boolean;        // adjective without prefix
  notDeleted: boolean;      // negative name
  subscription: boolean;    // bool or object?
  twoFactor: boolean;       // bool or config object?
}

function checkAuth(token: string): boolean { ... }  // "check" is not a question
function validate(input: unknown): boolean { ... }   // "validate" implies side effects
function getEnabled(): boolean { ... }               // "get" implies returning data
```

### GOOD — Interface Properties

```typescript
interface UserProfile {
  name: string;
  email: string;
  isActive: boolean;
  isAdmin: boolean;
  isVerified: boolean;
  isDeleted: boolean;              // positive name; check `if (profile.isDeleted)`
  hasSubscription: boolean;
  hasTwoFactorEnabled: boolean;
}

function isAuthenticated(token: string): boolean { ... }
function isValidInput(input: unknown): boolean { ... }
function isEnabled(): boolean { ... }
```

### BAD — React Component Props

```tsx
interface ModalProps {
  open: boolean;           // missing prefix
  closable: boolean;       // missing prefix
  loading: boolean;        // missing prefix
  disabled: boolean;       // missing prefix, and a negative concept
  error: boolean;          // could be boolean, string, or Error object
  dark: boolean;           // missing prefix
}

function Modal({ open, closable, loading, disabled, error, dark }: ModalProps) {
  // At the call site: <Modal open closable loading disabled error dark />
  // Every prop is ambiguous — are these booleans? strings? objects?
  ...
}
```

### GOOD — React Component Props

```tsx
interface ModalProps {
  isOpen: boolean;
  isClosable: boolean;
  isLoading: boolean;
  isEnabled: boolean;          // positive name; negate in logic
  hasError: boolean;
  isDarkTheme: boolean;
}

function Modal({ isOpen, isClosable, isLoading, isEnabled, hasError, isDarkTheme }: ModalProps) {
  // At the call site: <Modal isOpen isClosable isLoading isEnabled={false} hasError isDarkTheme />
  // Every prop is unambiguously a boolean.
  ...
}
```

### BAD — Ternary and Conditional Logic

```typescript
const disabled = !permissions.includes("edit");
const hidden = document.visibility === "hidden";
const invalid = errors.length > 0;

// Double negatives:
if (!disabled) { enableButton(); }
if (!hidden) { showElement(); }
if (!invalid) { submitForm(); }

// Ternary with negation of a negative — unreadable:
const className = !disabled ? "active" : "inactive";
```

### GOOD — Ternary and Conditional Logic

```typescript
const isEnabled = permissions.includes("edit");
const isVisible = document.visibility !== "hidden";
const isValid = errors.length === 0;

// Single, clear checks:
if (isEnabled) { enableButton(); }
if (isVisible) { showElement(); }
if (isValid) { submitForm(); }

// Ternary reads naturally:
const className = isEnabled ? "active" : "inactive";
```

## Go

### BAD — Struct Fields and Functions

```go
type Config struct {
    Debug    bool   // ambiguous — debug what? is it debug mode? has debug info?
    Verbose  bool   // missing prefix
    Ready    bool   // missing prefix
    SSL      bool   // is SSL? has SSL? uses SSL?
    Auth     bool   // is auth? has auth? needs auth?
    Retry    bool   // should retry? can retry? did retry?
}

func CheckPermission(user *User, resource string) bool { ... }  // "Check" is a verb
func ValidateToken(token string) bool { ... }                    // "Validate" implies action
func GetReady() bool { ... }                                      // "Get" implies data retrieval
```

### GOOD — Struct Fields and Functions

```go
type Config struct {
    IsDebugMode bool
    IsVerbose   bool
    IsReady     bool
    IsSSLEnabled bool
    IsAuthRequired bool
    ShouldRetry bool
}

func HasPermission(user *User, resource string) bool { ... }
func IsValidToken(token string) bool { ... }
func IsReady() bool { ... }
```

### BAD — Error Checking Booleans

```go
func processOrder(order *Order) error {
    valid := validateOrder(order)      // "valid" has no prefix
    stock := checkStock(order.Items)   // "stock" — is this a boolean or inventory data?
    fraud := detectFraud(order)        // "fraud" — is this a boolean or fraud details?

    if !valid {
        return fmt.Errorf("invalid order")
    }
    if !stock {
        return fmt.Errorf("out of stock")
    }
    if fraud {
        return fmt.Errorf("fraud detected")
    }

    return nil
}
```

### GOOD — Error Checking Booleans

```go
func processOrder(order *Order) error {
    isValid := isValidOrder(order)
    isInStock := hasStock(order.Items)
    isFraudulent := isFraudulentOrder(order)

    if !isValid {
        return fmt.Errorf("invalid order")
    }
    if !isInStock {
        return fmt.Errorf("out of stock")
    }
    if isFraudulent {
        return fmt.Errorf("fraud detected")
    }

    return nil
}
```

### BAD — Method Receivers

```go
type Cache struct {
    data    map[string]any
    expired map[string]bool
}

// These method names do not form questions
func (c *Cache) Check(key string) bool { ... }
func (c *Cache) Expire(key string) bool { ... }
func (c *Cache) Empty() bool { ... }           // is this a verb (empty the cache) or adjective?
```

### GOOD — Method Receivers

```go
type Cache struct {
    data    map[string]any
    expired map[string]bool
}

// These method names form clear yes/no questions
func (c *Cache) Has(key string) bool { ... }
func (c *Cache) IsExpired(key string) bool { ... }
func (c *Cache) IsEmpty() bool { ... }
```

## Key Points

- **Every boolean reads as a yes/no question.** If you cannot prefix it with "Is the..." or "Does it have..." or "Can it..." and get a grammatical question, rename it.
- **Positive names only.** Negate in the logic (`if (!isReady)`), never in the name (`isNotReady`).
- **Prefixes come first.** `isUserActive`, never `userIsActive` or `activeUser`.
- **Functions that return booleans are named like the booleans they return.** `isValid()` returns a boolean. `validate()` implies a side effect.
- **At the call site, boolean parameters must read clearly.** `send(shouldRetry: true)` is clear. `send(true)` is not.
- **Banned words: `flag`, `status`, `toggle`, `check`, `state`, bare adjectives.** These are not questions. Rename them to specific conditions.
