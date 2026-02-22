# Naming Before/After Transformations

Multi-language examples showing bad naming transformed into precise, self-documenting names. Every "before" example compiles and runs. Every "after" example communicates without requiring the reader to inspect the implementation.

## Python

### Variables

```python
# BEFORE: Vague, forces the reader to trace the data flow

data = db.query("SELECT * FROM users WHERE is_active = true")
result = [d for d in data if d.last_login > cutoff]
temp = {r.email: r for r in result}
info = calculate_stats(temp)

# AFTER: Every name declares its content

active_users = db.query("SELECT * FROM users WHERE is_active = true")
recently_logged_in = [user for user in active_users if user.last_login > cutoff]
users_by_email = {user.email: user for user in recently_logged_in}
login_frequency_stats = calculate_stats(users_by_email)
```

### Functions

```python
# BEFORE: Bare verbs and generic names

def process(records):
    """Handle the records."""
    checked = check(records)
    updated = update(checked)
    return updated

def get(id):
    return db.find(id)

def do_stuff(config):
    setup(config)
    run(config)

# AFTER: Verb + noun, precise actions

def validate_and_enrich_invoices(raw_invoices: list[RawInvoice]) -> list[Invoice]:
    """Validate invoice fields and attach computed tax amounts."""
    validated_invoices = validate_invoice_fields(raw_invoices)
    enriched_invoices = attach_tax_calculations(validated_invoices)
    return enriched_invoices

def fetch_patient_by_id(patient_id: str) -> Patient | None:
    return patient_repository.find_by_id(patient_id)

def initialize_monitoring_pipeline(pipeline_config: MonitoringConfig) -> None:
    configure_log_exporters(pipeline_config)
    start_metric_collectors(pipeline_config)
```

### Classes and Files

```python
# BEFORE: manager.py
class Manager:
    def __init__(self):
        self.items = []

    def process(self, item):
        self.items.append(item)

    def handle(self):
        for item in self.items:
            do_something(item)


# AFTER: order_fulfillment_queue.py
class OrderFulfillmentQueue:
    def __init__(self):
        self.pending_orders: list[Order] = []

    def enqueue_order(self, order: Order) -> None:
        self.pending_orders.append(order)

    def dispatch_all_pending(self) -> list[ShipmentConfirmation]:
        confirmations = []
        for order in self.pending_orders:
            confirmation = ship_order(order)
            confirmations.append(confirmation)
        return confirmations
```

### Scope-Aware Naming

```python
# OK: Tight scope, short names are fine
squares = [x ** 2 for x in range(10)]

total = sum(price * qty for price, qty in line_items)

filtered = [u for u in users if u.is_active]  # one-liner, "u" is fine

# NOT OK: Wide scope, short names cause confusion
# This variable is referenced 150 lines later in the same module
d = load_config("production.yaml")  # BAD: what is "d"?

deployment_config = load_config("production.yaml")  # GOOD
```

## TypeScript

### Variables

```typescript
// BEFORE: Generic names that require scrolling to understand

const data = await fetch("/api/orders").then((r) => r.json());
const items = data.filter((d: any) => d.status === "pending");
const result = items.reduce((acc: number, item: any) => acc + item.total, 0);
const info = { count: items.length, total: result };

// AFTER: Self-documenting at every step

const allOrders = await fetch("/api/orders").then((res) => res.json());
const pendingOrders = allOrders.filter((order: Order) => order.status === "pending");
const pendingOrderTotal = pendingOrders.reduce(
  (sum: number, order: Order) => sum + order.totalCents,
  0
);
const pendingSummary = { orderCount: pendingOrders.length, totalCents: pendingOrderTotal };
```

### Functions

```typescript
// BEFORE: What does "handle" do? What is "process"?

function handleClick(e: Event) {
  const value = getData();
  process(value);
  update();
}

async function getData() {
  return await api.get("/stuff");
}

function process(data: any) {
  return data.map((item: any) => transform(item));
}

// AFTER: Every function declares its action and target

function submitContactForm(event: SubmitEvent): void {
  const formFields = extractContactFormFields(event);
  validateAndSendInquiry(formFields);
  resetContactForm();
}

async function fetchOpenSupportTickets(): Promise<SupportTicket[]> {
  return await supportApi.getTickets({ status: "open" });
}

function formatTicketsForDashboard(tickets: SupportTicket[]): DashboardRow[] {
  return tickets.map((ticket) => convertTicketToDashboardRow(ticket));
}
```

### Interfaces and Types

```typescript
// BEFORE: Generic type names

interface Data {
  items: Thing[];
  info: Record<string, any>;
  value: number;
}

type Result = {
  status: string;
  data: any;
};

// AFTER: Domain-specific, self-describing types

interface InventorySnapshot {
  warehouseProducts: WarehouseProduct[];
  stockLevelsByWarehouse: Record<string, StockLevel>;
  totalValuationCents: number;
}

type PaymentAuthorizationResult = {
  authorizationStatus: "approved" | "declined" | "pending_review";
  transactionId: string;
};
```

## Go

### Variables

```go
// BEFORE: Cryptic abbreviations and generic names

func process(d []byte) (interface{}, error) {
    var result map[string]interface{}
    err := json.Unmarshal(d, &result)
    if err != nil {
        return nil, err
    }
    val := result["items"]
    return val, nil
}

// AFTER: Clear, typed, self-documenting

func ParseCatalogResponse(responseBody []byte) ([]CatalogItem, error) {
    var catalog CatalogResponse
    err := json.Unmarshal(responseBody, &catalog)
    if err != nil {
        return nil, fmt.Errorf("unmarshal catalog response: %w", err)
    }
    return catalog.Items, nil
}
```

### Functions

```go
// BEFORE: Generic verbs

func Handle(r *http.Request) (*http.Response, error) { ... }
func Do(ctx context.Context, input string) error { ... }
func Run(cfg Config) { ... }

// AFTER: Precise verb + noun

func AuthorizeIncomingRequest(r *http.Request) (*AuthResult, error) { ... }
func PublishMetricEvent(ctx context.Context, metricPayload string) error { ... }
func StartHealthCheckServer(serverConfig HealthCheckConfig) { ... }
```

### Structs

```go
// BEFORE: Names that tell you nothing about the domain

type Manager struct {
    pool   []interface{}
    config map[string]string
}

type Handler struct {
    svc Service
}

type Service struct {
    repo Repository
}

// AFTER: Names that declare their domain role

type ConnectionPool struct {
    availableConnections []*DatabaseConnection
    maxIdleTimeout       time.Duration
}

type InvoiceGenerationHandler struct {
    billingService BillingService
}

type BillingService struct {
    invoiceRepository InvoiceRepository
}
```

### File Naming

```
BEFORE (Go project):
  handlers.go       -- handlers for what?
  utils.go          -- the junk drawer
  models.go         -- 47 unrelated structs
  helpers.go        -- helping with what?
  service.go        -- which service?

AFTER (Go project):
  invoice_handler.go
  currency_conversion.go
  invoice.go, payment.go, subscription.go  -- one model per file
  retry.go                                  -- one clear responsibility
  billing_service.go
```

## Key Points

- **Banned names are non-negotiable.** `data`, `result`, `temp`, `info`, `handle`, `process`, `manager`, `helper`, `utils`, `misc` -- reject on sight.
- **Climb the specificity ladder.** `data` becomes `userData` becomes `activeUserProfiles`. Stop when a new reader would understand the name without context.
- **Short scopes earn short names.** `i` in a 3-line loop is fine. `i` referenced 50 lines later is not.
- **Domain language over programmer jargon.** If the business says "invoice," the code says `invoice` -- not `record` or `entity`.
- **Verb + noun for every function.** `process()` is not a function name. `validatePaymentMethod()` is.
- **Files match their contents.** `user_profile_service.py` contains `UserProfileService`. No file named `helpers` or `utils`.
