---
name: visual-rhythm
description: "This skill should be used when the user's code has inconsistent whitespace, missing blank lines between logical sections, cramped or overly spaced code, or when the visual structure does not match the logical structure. Covers whitespace as punctuation and the rule that code is prose and must be formatted like prose."
version: 1.0.0
---

# Code Is Prose -- Format It Like Prose

Blank lines are paragraph breaks. They separate ideas. Use them deliberately, not randomly. A function with no blank lines is a wall of text. A function with blank lines after every single statement is a ransom note. The visual structure of your code must match the logical structure. When the eye scans the file, it should immediately see the shape of the logic -- groups, transitions, and boundaries -- without reading a single word.

This is not aesthetic preference. This is readability engineering. Studies on code comprehension consistently show that well-spaced code is understood faster and with fewer errors than dense or randomly spaced code. Whitespace is punctuation. Use it like a writer, not like a toddler with a space bar.

## Blank Line Rules

### One Blank Line: Between Related Things

One blank line separates related but distinct thoughts. Use it between functions in the same logical group, between logical sections within a function, and between a block of declarations and the first statement that uses them.

```python
# GOOD -- one blank line between logical sections within a function
def process_order(order: Order) -> Receipt:
    # Validate
    validate_order(order)
    validate_inventory(order.items)

    # Calculate
    subtotal = calculate_subtotal(order.items)
    tax = calculate_tax(subtotal, order.shipping_address)
    total = subtotal + tax

    # Persist
    receipt = create_receipt(order, total)
    db.save(receipt)

    return receipt
```

### Two Blank Lines: Between Top-Level Definitions

Two blank lines separate top-level definitions: classes, major function groups, and module-level boundaries. This is Python's PEP 8 standard, but it is good practice in every language. Two blank lines say "this is a new section of the file."

```python
# GOOD -- two blank lines between top-level definitions
class OrderValidator:
    def validate(self, order: Order) -> list[str]:
        errors = []
        errors.extend(self._validate_items(order.items))
        errors.extend(self._validate_address(order.shipping_address))
        return errors

    def _validate_items(self, items: list[Item]) -> list[str]:
        ...

    def _validate_address(self, address: Address) -> list[str]:
        ...


class OrderProcessor:
    def process(self, order: Order) -> Receipt:
        ...
```

```typescript
// GOOD -- clear visual separation between major sections
interface OrderItem {
  productId: string;
  quantity: number;
  unitPrice: number;
}


interface Order {
  id: string;
  items: OrderItem[];
  shippingAddress: Address;
}


function validateOrder(order: Order): ValidationResult {
  // ...
}


function processOrder(order: Order): Receipt {
  // ...
}
```

### Zero Blank Lines: Tightly Coupled Statements

Do not put a blank line between statements that form a single thought. A variable declaration immediately followed by its use, a condition immediately followed by its single consequence -- these are one idea, not two.

```go
// GOOD -- tightly coupled statements stay together
name := req.FormValue("name")
sanitizedName := strings.TrimSpace(name)

age, err := strconv.Atoi(req.FormValue("age"))
if err != nil {
    return fmt.Errorf("invalid age: %w", err)
}

// BAD -- blank lines break the thought
name := req.FormValue("name")

sanitizedName := strings.TrimSpace(name)

age, err := strconv.Atoi(req.FormValue("age"))

if err != nil {

    return fmt.Errorf("invalid age: %w", err)
}
```

## Anti-Patterns

### The "Gasp" -- Too Many Blank Lines

Four or five blank lines in a row is not "breathing room." It is hyperventilating. The reader's eye loses its place. The logical connection between sections is severed. Maximum two blank lines anywhere in the file.

```python
# BAD -- the "gasp"
class UserService:
    def get_user(self, user_id: int) -> User:
        return self.db.fetch(user_id)




    # What happened here? Did someone delete a function? Is this intentional?




    def update_user(self, user_id: int, data: dict) -> User:
        return self.db.update(user_id, data)
```

```python
# GOOD -- consistent single blank line between methods
class UserService:
    def get_user(self, user_id: int) -> User:
        return self.db.fetch(user_id)

    def update_user(self, user_id: int, data: dict) -> User:
        return self.db.update(user_id, data)
```

### The "Wall" -- No Blank Lines

200 lines with no blank lines is a wall of text, not code. The reader cannot find logical boundaries. Everything blurs together. Functions run into functions. Setup runs into logic runs into cleanup.

```typescript
// BAD -- the wall
function processOrder(order: Order): Receipt {
  const items = order.items;
  const subtotal = items.reduce((sum, item) => sum + item.price * item.quantity, 0);
  const taxRate = getTaxRate(order.shippingAddress);
  const tax = subtotal * taxRate;
  const total = subtotal + tax;
  const receipt = new Receipt();
  receipt.orderId = order.id;
  receipt.subtotal = subtotal;
  receipt.tax = tax;
  receipt.total = total;
  receipt.createdAt = new Date();
  db.save(receipt);
  emailService.sendReceipt(order.customerEmail, receipt);
  analytics.trackPurchase(order.id, total);
  return receipt;
}
```

```typescript
// GOOD -- logical sections are visually distinct
function processOrder(order: Order): Receipt {
  const items = order.items;

  const subtotal = items.reduce((sum, item) => sum + item.price * item.quantity, 0);
  const taxRate = getTaxRate(order.shippingAddress);
  const tax = subtotal * taxRate;
  const total = subtotal + tax;

  const receipt = new Receipt();
  receipt.orderId = order.id;
  receipt.subtotal = subtotal;
  receipt.tax = tax;
  receipt.total = total;
  receipt.createdAt = new Date();

  db.save(receipt);
  emailService.sendReceipt(order.customerEmail, receipt);
  analytics.trackPurchase(order.id, total);

  return receipt;
}
```

## Vertical Alignment: Do Not

Do NOT vertically align assignments, values, or comments across lines. It looks tidy for five minutes. Then someone renames a variable and the entire block needs to be re-aligned, creating a diff that changes 15 lines when the actual change was 1. It is pure maintenance cost for zero readability benefit.

```typescript
// BAD -- vertical alignment
const name          = "Alice";
const age           = 30;
const email         = "alice@example.com";
const accountStatus = "active";

// GOOD -- natural spacing
const name = "Alice";
const age = 30;
const email = "alice@example.com";
const accountStatus = "active";
```

```python
# BAD -- vertical alignment in dicts
config = {
    "host":     "localhost",
    "port":     5432,
    "database": "myapp",
    "user":     "admin",
}

# GOOD -- natural spacing
config = {
    "host": "localhost",
    "port": 5432,
    "database": "myapp",
    "user": "admin",
}
```

## Trailing Whitespace: Remove It. Always.

Trailing whitespace is invisible noise. It creates phantom diffs. It triggers linter warnings. It makes `git diff` look like lines changed when nothing changed. Configure your editor to strip trailing whitespace on save. Every editor supports this. There is no excuse.

## End of File: Exactly One Newline

Every file ends with exactly one newline character. Not zero (some tools break). Not two (unnecessary). Not a blank line followed by a newline. Exactly one. POSIX requires it. Git warns about it. Formatters enforce it. Configure your editor.

## Indentation: Pick One, Enforce It, Never Mix

Spaces. Not tabs. The industry has decided, and the formatters have spoken.

| Language | Standard | Enforced By |
|----------|----------|-------------|
| Python | 4 spaces | ruff, black |
| TypeScript/JavaScript | 2 spaces | prettier, eslint |
| Go | tabs (gofmt) | gofmt (non-negotiable) |
| Rust | 4 spaces | rustfmt |

Go is the exception: `gofmt` uses tabs and the community follows `gofmt` without debate. In every other language, use spaces. Never mix tabs and spaces in the same file. Never mix indentation widths in the same project. Configure your formatter and never think about it again.

## Line Length: Set a Limit and Enforce It

Long lines are unreadable in split views, code review tools, and terminal windows. Pick a limit and enforce it with your formatter.

| Limit | When |
|-------|------|
| 80 | Terminal-focused workflows, Python tradition |
| 100 | Good balance for most codebases |
| 120 | Wide monitors, complex type annotations |

The specific number matters less than consistency. A codebase with some files at 80 and others at 200 is a codebase where nobody agreed on anything.

```python
# BAD -- this does not fit in any reasonable view
def send_notification(user_id: int, notification_type: str, message: str, metadata: dict[str, Any], priority: int = 0, retry_count: int = 3) -> NotificationResult:
    ...

# GOOD -- broken at a natural point, within line limit
def send_notification(
    user_id: int,
    notification_type: str,
    message: str,
    metadata: dict[str, Any],
    priority: int = 0,
    retry_count: int = 3,
) -> NotificationResult:
    ...
```

```go
// BAD -- 160 characters of unreadable chain
func (s *Service) ProcessTransaction(ctx context.Context, userID string, amount int64, currency string, metadata map[string]string) (*Transaction, error) {

// GOOD -- parameters on separate lines
func (s *Service) ProcessTransaction(
	ctx context.Context,
	userID string,
	amount int64,
	currency string,
	metadata map[string]string,
) (*Transaction, error) {
```

## Good/Bad Examples

### Python -- Visual Rhythm

```python
# BAD -- no rhythm, no breathing, impossible to scan
class ReportGenerator:
    def __init__(self, db, template_engine, cache):
        self.db = db
        self.template_engine = template_engine
        self.cache = cache
    def generate(self, report_type, date_range):
        cached = self.cache.get(report_type, date_range)
        if cached:
            return cached
        data = self.db.query(report_type, date_range)
        if not data:
            raise EmptyReportError(f"No data for {report_type}")
        rendered = self.template_engine.render(report_type, data)
        self.cache.set(report_type, date_range, rendered)
        return rendered
    def clear_cache(self):
        self.cache.clear()
```

```python
# GOOD -- the shape of the code matches the shape of the logic
class ReportGenerator:
    def __init__(self, db, template_engine, cache):
        self.db = db
        self.template_engine = template_engine
        self.cache = cache

    def generate(self, report_type: str, date_range: DateRange) -> str:
        cached = self.cache.get(report_type, date_range)
        if cached:
            return cached

        data = self.db.query(report_type, date_range)
        if not data:
            raise EmptyReportError(f"No data for {report_type}")

        rendered = self.template_engine.render(report_type, data)
        self.cache.set(report_type, date_range, rendered)

        return rendered

    def clear_cache(self) -> None:
        self.cache.clear()
```

### TypeScript -- Visual Rhythm

```typescript
// BAD -- cramped, no section breaks
export class PaymentService {
  private stripe: Stripe;
  private db: Database;
  constructor(stripe: Stripe, db: Database) {
    this.stripe = stripe;
    this.db = db;
  }
  async charge(customerId: string, amount: number): Promise<Charge> {
    const customer = await this.db.getCustomer(customerId);
    if (!customer) throw new NotFoundError("Customer not found");
    const paymentMethod = await this.stripe.getDefaultPaymentMethod(customer.stripeId);
    if (!paymentMethod) throw new BadRequestError("No payment method on file");
    const charge = await this.stripe.charges.create({amount, currency: "usd", customer: customer.stripeId});
    await this.db.recordCharge(customerId, charge.id, amount);
    return charge;
  }
}
```

```typescript
// GOOD -- sections breathe
export class PaymentService {
  private stripe: Stripe;
  private db: Database;

  constructor(stripe: Stripe, db: Database) {
    this.stripe = stripe;
    this.db = db;
  }

  async charge(customerId: string, amount: number): Promise<Charge> {
    const customer = await this.db.getCustomer(customerId);
    if (!customer) throw new NotFoundError("Customer not found");

    const paymentMethod = await this.stripe.getDefaultPaymentMethod(customer.stripeId);
    if (!paymentMethod) throw new BadRequestError("No payment method on file");

    const charge = await this.stripe.charges.create({
      amount,
      currency: "usd",
      customer: customer.stripeId,
    });

    await this.db.recordCharge(customerId, charge.id, amount);

    return charge;
  }
}
```

## Examples

Working implementations in `examples/`:
- **`examples/whitespace-as-punctuation.md`** -- Multi-language examples showing well-paced vs poorly-paced code across Python, TypeScript, and Go, demonstrating blank line placement, section grouping, and visual structure

## Review Checklist

When reviewing code for visual rhythm:

- [ ] Blank lines separate logical sections within functions (setup, logic, cleanup, return)
- [ ] One blank line between related functions/methods within a class
- [ ] Two blank lines between top-level definitions (classes, standalone function groups)
- [ ] No more than two consecutive blank lines anywhere in the file
- [ ] No wall-of-text functions -- 20+ lines with zero blank lines is a red flag
- [ ] Tightly coupled statements (declaration + immediate use) are not separated by blank lines
- [ ] No vertical alignment of assignments, values, or trailing comments
- [ ] No trailing whitespace on any line
- [ ] File ends with exactly one newline
- [ ] Indentation is consistent: correct width, spaces (or tabs for Go), no mixing
- [ ] Line length stays within the project limit (80, 100, or 120 -- enforced by formatter)
- [ ] Long function signatures and calls are broken across lines at natural points
- [ ] The visual shape of the code matches its logical structure -- a glance reveals the sections