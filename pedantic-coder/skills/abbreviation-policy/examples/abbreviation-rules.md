# Abbreviation Rules

Multi-language examples showing consistent vs inconsistent abbreviation usage. Every "inconsistent" example contains real patterns found in production codebases. Every "consistent" example demonstrates the discipline required.

## Python: Consistent vs Inconsistent

### Inconsistent (Real-World Anti-Patterns)

```python
# file: user_svc.py -- abbreviated file name

class UsrAccountMgr:
    """Manages user accounts."""                    # Mgr: not approved

    def __init__(self, db_conn, cache_svc):
        self.db_conn = db_conn                      # conn: not approved
        self.cache_svc = cache_svc                   # svc: not approved

    def get_usr_acct(self, acct_id: str):           # usr, acct: not approved
        """Fetch user account by ID."""
        cached_val = self.cache_svc.get(acct_id)    # val: not approved
        if cached_val:
            return cached_val
        return self.db_conn.query(acct_id)

    def upd_usr_info(self, acct_id, new_info):      # upd: not approved
        """Update user information."""
        self.db_conn.update(acct_id, new_info)
        self.cache_svc.invalidate(acct_id)

    def calc_acct_age(self, acct_id):               # calc: not approved
        """Calculate account age in days."""
        acct = self.get_usr_acct(acct_id)
        return (datetime.now() - acct.reg_dt).days   # reg_dt: not approved


# Inconsistency across files:
# In user_svc.py:  "message"
# In notif_svc.py: "msg"
# In email_svc.py: "message"
# In chat_svc.py:  "msg"
def send_notification(user_id: str, message: str) -> None:
    log.info(f"Sending msg to user {user_id}")       # msg vs message
    queue.publish(msg=message)                        # msg parameter
    track_event("message_sent", {"usr_id": user_id})  # usr vs user
```

### Consistent (Corrected)

```python
# file: user_account_service.py -- full words in file name

class UserAccountService:
    """Manages user accounts."""

    def __init__(
        self,
        database_connection: DatabaseConnection,
        cache_service: CacheService,
    ):
        self.database_connection = database_connection
        self.cache_service = cache_service

    def get_user_account(self, account_id: str) -> UserAccount:
        """Fetch user account by ID."""
        cached_account = self.cache_service.get(account_id)
        if cached_account:
            return cached_account
        return self.database_connection.query(account_id)

    def update_user_account(
        self, account_id: str, updated_fields: UserAccountUpdate
    ) -> None:
        """Update user account fields."""
        self.database_connection.update(account_id, updated_fields)
        self.cache_service.invalidate(account_id)

    def calculate_account_age_days(self, account_id: str) -> int:
        """Calculate account age in days."""
        account = self.get_user_account(account_id)
        return (datetime.now() - account.registration_date).days


# Consistent across ALL files:
def send_notification(user_id: str, message: str) -> None:
    log.info(f"Sending message to user {user_id}")
    queue.publish(message=message)
    track_event("message_sent", {"user_id": user_id})
```

### Approved Abbreviations in Python

```python
# These abbreviations are universally understood and approved:

# id -- always
user_id = "usr_abc123"
order_id = "ord_xyz789"

# config -- always
database_config = load_config("database.yaml")
app_config = load_config("application.yaml")

# auth -- always
auth_token = generate_auth_token(user)
auth_middleware = AuthMiddleware(secret_key=AUTH_SECRET)

# db -- always
db_connection = create_db_connection(database_config)

# url -- always
callback_url = f"{base_url}/webhooks/payment"
avatar_url = user.profile.avatar_url

# err -- acceptable (especially in Go-influenced Python)
validation_err = validate_input(payload)

# ctx -- acceptable
request_ctx = build_request_context(request)

# req/res -- in handler functions only
def handle_webhook(req: Request) -> Response:
    payload = parse_webhook_payload(req)
    return Response(status_code=200)

# args/params -- always
query_params = parse_query_params(request.url)
function_args = inspect.getfullargspec(target_function)

# max/min/len/num -- always
max_retries = 5
min_password_length = 8
num_active_users = count_active_users()

# msg -- in messaging contexts
msg_queue = MessageQueue(config=queue_config)
incoming_msg = msg_queue.receive()

# env -- always
env_name = os.environ.get("ENVIRONMENT", "development")
```

## TypeScript: Consistent vs Inconsistent

### Inconsistent (Real-World Anti-Patterns)

```typescript
// Mixed abbreviation forms across the codebase

// file: UserSvc.ts -- abbreviated
interface UsrProfile {                           // usr: not approved
  acctId: string;                                // acct: not approved
  dispName: string;                              // disp: not approved
  emailAddr: string;                             // addr: not approved in this context
  regDate: Date;                                 // reg: not approved
  numOrders: number;                             // OK: num is approved
  lstLogin: Date;                                // lst: not approved
}

// file: notification-service.ts -- full words
interface NotificationPayload {
  recipientId: string;                           // full word: recipient
  message: string;                               // full word: message
  notificationType: string;                      // full word: notification
}

// file: ChatMessageHandler.ts -- mixed
interface ChatMsg {                              // msg vs message inconsistency
  senderId: string;
  recipId: string;                               // recipId vs recipientId inconsistency
  msgBody: string;                               // msgBody vs message inconsistency
  sentTs: number;                                // ts: not approved
}

// Three different patterns for the same concept across three files:
// UserSvc.ts:              getUserAcct(acctId)
// notification-service.ts: getNotificationForUser(userId)
// ChatMessageHandler.ts:   getChatMsgs(usrId)
```

### Consistent (Corrected)

```typescript
// file: user-profile.ts -- full words, kebab-case file
interface UserProfile {
  accountId: string;
  displayName: string;
  emailAddress: string;
  registrationDate: Date;
  orderCount: number;
  lastLoginAt: Date;
}

// file: notification-service.ts -- same conventions
interface NotificationPayload {
  recipientId: string;
  message: string;
  notificationType: string;
}

// file: chat-message-handler.ts -- same conventions
interface ChatMessage {
  senderId: string;
  recipientId: string;                           // matches notification-service.ts
  messageBody: string;                           // full word, matches convention
  sentAt: Date;                                  // consistent timestamp naming
}

// One pattern everywhere:
// user-profile.ts:          getUserProfile(userId)
// notification-service.ts:  getNotificationsForUser(userId)
// chat-message-handler.ts:  getChatMessages(userId)
```

### React UI Components: Where `btn` Is Acceptable

```tsx
// file: ButtonGroup.tsx -- UI context, btn abbreviation is acceptable

// ACCEPTABLE in UI layer:
interface ButtonGroupProps {
  primaryButtonText: string;        // full word in props (public API)
  secondaryButtonText: string;
  onPrimaryButtonClick: () => void;
  onSecondaryButtonClick: () => void;
}

// ALSO ACCEPTABLE in internal UI utility:
const btnVariants = {
  primary: "bg-blue-600 text-white",
  secondary: "bg-gray-200 text-gray-800",
  danger: "bg-red-600 text-white",
} as const;

// NOT ACCEPTABLE in backend service:
// interface PaymentRequest {
//   btnAction: string;      // btn has no place in a payment service
//   btnLabel: string;       // this is not UI code
// }
```

## Go: Consistent vs Inconsistent

### Inconsistent (Real-World Anti-Patterns)

```go
// Mixed abbreviation forms

// file: user_svc.go -- abbreviated
type UsrAcctSvc struct {                         // usr, acct, svc: over-abbreviated
    dbConn *sql.DB                               // conn: not approved
    cacheSvc *CacheSvc                           // svc: not approved
}

func (s *UsrAcctSvc) GetUsrAcct(acctID string) (*UsrAcct, error) {
    // ...
}

// file: notification_handler.go -- full words
type NotificationHandler struct {
    notificationService *NotificationService     // full word: service
    messageQueue        *MessageQueue            // full word: message
}

func (h *NotificationHandler) SendNotification(recipientID string, message string) error {
    // ...
}

// file: chat.go -- mixed
type ChatMsgProcessor struct {                   // msg: mixing with notification's "message"
    svc    ChatSvc                               // svc: not approved
    msgRepo MsgRepo                              // msg vs message, repo: borderline
}

func (p *ChatMsgProcessor) ProcMsg(ctx context.Context, msg *ChatMsg) error {
    // ProcMsg: over-abbreviated, unclear
    // ...
}
```

### Consistent (Corrected)

```go
// file: user_account_service.go -- full words
type UserAccountService struct {
    db           *sql.DB
    cacheService *CacheService
}

func (s *UserAccountService) GetUserAccount(accountID string) (*UserAccount, error) {
    // ...
}

// file: notification_handler.go -- same conventions
type NotificationHandler struct {
    notificationService *NotificationService
    messageQueue        *MessageQueue
}

func (h *NotificationHandler) SendNotification(recipientID string, message string) error {
    // ...
}

// file: chat_message_processor.go -- same conventions
type ChatMessageProcessor struct {
    chatService       ChatService                // consistent: "service" everywhere
    messageRepository MessageRepository          // consistent: "message" everywhere
}

func (p *ChatMessageProcessor) ProcessMessage(ctx context.Context, message *ChatMessage) error {
    // Full verb + noun, matches the pattern everywhere
    // ...
}
```

### Go-Idiomatic Approved Abbreviations

```go
// These are idiomatic in Go and approved everywhere:

// ctx -- always in Go
func ProcessOrder(ctx context.Context, orderID string) error { ... }

// err -- always in Go
result, err := service.Execute(ctx)
if err != nil {
    return fmt.Errorf("execute service: %w", err)
}

// req -- in HTTP handlers
func HandleCreateUser(w http.ResponseWriter, req *http.Request) { ... }

// fmt -- Go package name, idiomatic
import "fmt"
formatted := fmt.Sprintf("user %s created", userID)

// These are NOT idiomatic in Go and should be spelled out:

// BAD                          GOOD
// svc *UserSvc                 service *UserService
// mgr *ConnMgr                 pool *ConnectionPool
// repo *UserRepo               repository *UserRepository (or store *UserStore)
// impl *AuthImpl               authenticator *TokenAuthenticator
// cfg *AppCfg                  config *AppConfig
```

## Sample Abbreviation Registry

For projects that use domain-specific abbreviations beyond the universal list:

```markdown
# Abbreviation Registry
# Last updated: 2024-01-15
# Approved by: Engineering team

## Rules
1. If an abbreviation is not in this list, use the full word
2. If you use the abbreviated form, use it EVERYWHERE
3. If you use the full form, use it EVERYWHERE
4. Adding a new entry requires team review

## Approved Domain Abbreviations

| Abbrev | Full Form          | Context                    | Approved Date |
|--------|--------------------|----------------------------|---------------|
| `txn`  | transaction        | Payment processing, ledger | 2024-01-10    |
| `sku`  | stock keeping unit | Inventory, product catalog | 2024-01-10    |
| `qty`  | quantity           | Orders, inventory counts   | 2024-01-10    |
| `org`  | organization       | Multi-tenancy, team mgmt   | 2024-01-10    |
| `repo` | repository         | Data access layer          | 2024-01-15    |

## Rejected (Use Full Word)

| Rejected | Use Instead    | Reason                              |
|----------|---------------|-------------------------------------|
| `acct`   | `account`     | Not universally recognized          |
| `addr`   | `address`     | Ambiguous (memory addr? street addr?)|
| `amt`    | `amount`      | Too short, saves only 3 characters  |
| `calc`   | `calculate`   | Verb should be fully spelled out    |
| `desc`   | `description` | Ambiguous (descending? description?)|
| `mgr`    | `manager`     | Then rename to something specific   |
| `svc`    | `service`     | 4 characters saved, clarity lost    |
```

## Key Points

- **Full words are the default.** Abbreviations require justification against the universally understood list or the project registry.
- **The new hire test is definitive.** If they would ask what it means, spell it out.
- **Consistency is absolute.** `message` everywhere or `msg` everywhere. Never both. Grep the codebase to verify.
- **Cross-file consistency matters.** `message` in `user_service.py` and `msg` in `notification_service.py` is a defect.
- **UI abbreviations stay in the UI.** `btn` is acceptable in React components, unacceptable in a payment processing service.
- **The abbreviation registry is a file in the repo.** Not a wiki. Not tribal knowledge. A committed, reviewed file.
- **When in doubt, spell it out.** The cost of a longer name is zero. The cost of a confusing abbreviation is paid on every read.
