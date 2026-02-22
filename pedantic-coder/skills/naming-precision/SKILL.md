---
name: naming-precision
description: "This skill should be used when the user is naming variables, functions, classes, files, or any identifier. Covers semantic accuracy, vague names like data/temp/result/info/handle, domain-specific naming, and the principle that a name should make the reader never need to look at the implementation."
version: 1.0.0
---

# A Name Must Be the Most Precise Word Available

If a reader has to look at the implementation to understand what a variable holds, the name has failed. A precise name eliminates the need for comments, reduces cognitive load during reviews, and prevents an entire category of bugs where the wrong variable is used because two names were too similar or too vague. This is not about taste. This is about whether your code communicates or obfuscates.

## Banned Names

The following names are prohibited in any scope wider than a single expression. They tell the reader nothing. They are placeholders left behind by someone who did not finish thinking.

| Banned | Why | What to Use Instead |
|--------|-----|---------------------|
| `data` | Everything is data | `userProfiles`, `invoiceLineItems`, `sensorReadings` |
| `info` | Synonym for data, equally useless | `accountDetails`, `shippingAddress`, `errorContext` |
| `temp` | What is temporary about it? | `unsavedDraft`, `pendingUpload`, `swapBuffer` |
| `result` | Result of what? | `validationErrors`, `searchMatches`, `parsedConfig` |
| `value` | Value of what? | `discountPercent`, `temperatureCelsius`, `pixelWidth` |
| `item` | Item in what collection? | `cartProduct`, `logEntry`, `notificationPayload` |
| `thing` | Not a word that belongs in code | Name the actual concept |
| `handle` | Verb pretending to be a noun | `fileDescriptor`, `connectionSocket`, `eventCallback` |
| `process` | What does it process? How? | `validatePayment`, `compressImage`, `routeIncomingRequest` |
| `manager` | Manages what? How? | `connectionPool`, `cacheEvictor`, `taskScheduler` |
| `helper` | Helping with what? | Name the actual operation: `formatCurrency`, `retryWithBackoff` |
| `utils` | Junk drawer | Split into specific modules: `dateFormatting`, `stringValidation` |
| `misc` | Admission of organizational failure | Categorize properly or inline the code |

**Zero tolerance.** If you see any of these names in a review, reject the code. No exceptions. No "but it's obvious from context." Context changes. Names stay.

## The Specificity Ladder

Every vague name can be made precise by climbing the specificity ladder. Each rung adds information the reader needs.

```
data                    -- what data?
userData                -- which aspect of user data?
userProfiles            -- what kind of profiles?
activeUserProfiles      -- now the reader knows exactly what this holds
```

```
result                  -- result of what?
queryResult             -- which query?
userSearchResult        -- getting better
matchingUsersByEmail    -- now it is unambiguous
```

```
config                  -- config of what?
appConfig               -- still vague in a large app
databaseConnectionConfig -- precise
```

The right level depends on scope. A tight 3-line lambda can use `user`. A module-level variable that 40 functions reference needs `activeSubscribedUser`.

## Scope-Aware Naming

Short names are acceptable in tiny scopes where the context is immediately visible. Long names are mandatory in wide scopes where the reader may be far from the declaration.

| Scope | Acceptable | Why |
|-------|-----------|-----|
| Loop index (3 lines) | `i`, `j`, `k` | Universal convention, scope is visible in one glance |
| Lambda parameter | `x`, `n`, `user` | Immediately adjacent to usage |
| Local variable (10 lines) | `user`, `order` | Context is visible on the same screen |
| Module-level variable | `activeUserCount`, `pendingOrderQueue` | Reader may be 200 lines away from the declaration |
| Exported/public API | `fetchActiveUserProfiles`, `calculateMonthlyRevenue` | Reader may be in a completely different file or package |

**The rule:** the wider the scope, the more precise the name must be. A name that works in a 3-line block becomes ambiguous in a 300-line file.

## Domain Naming

Use the language of the business domain, not programmer jargon. If the business calls it an invoice, your code calls it an invoice -- not a `record`, not a `document`, not an `entity`.

| Programmer Jargon | Domain Name |
|-------------------|-------------|
| `record` | `invoice`, `patient`, `transaction` |
| `entity` | `customer`, `product`, `warehouse` |
| `object` | `order`, `shipment`, `appointment` |
| `element` | `menuItem`, `dashboardWidget`, `formField` |
| `entry` | `logEvent`, `auditTrail`, `calendarBooking` |
| `payload` | `webhookNotification`, `apiResponse`, `messageBody` |

Domain-driven naming makes the codebase readable to product managers, support engineers, and new developers who understand the business but have not memorized your abstractions. Eric Evans was right: ubiquitous language is not optional.

## Function Naming: Verb + Noun

Every function name must start with a verb that describes its action, followed by a noun that describes its target. Never use a bare verb. Never use a bare noun.

**Pattern:** `verb` + `noun` (+ optional qualifier)

| Bad | Good | Why |
|-----|------|-----|
| `process()` | `validatePaymentMethod()` | What does "process" mean? |
| `handle()` | `routeIncomingRequest()` | "Handle" says nothing about how |
| `run()` | `executeScheduledJob()` | What does it run? |
| `do()` | `sendWelcomeEmail()` | Never |
| `check()` | `verifyEmailOwnership()` | Check what? For what? |
| `get()` | `fetchUserProfile()` | Get from where? A cache? A database? An API? |
| `update()` | `applyDiscountToOrder()` | Update what aspect? |
| `manage()` | `rotateExpiredApiKeys()` | Not a real action |

**Verb precision matters.** `get` vs `fetch` vs `find` vs `compute` vs `load` are not synonyms:

| Verb | Meaning |
|------|---------|
| `get` | Retrieve from local/in-memory state (synchronous, cheap) |
| `fetch` | Retrieve from an external source (network call, async) |
| `find` | Search a collection, may return null/empty |
| `compute` / `calculate` | Derive a value through logic or math |
| `load` | Read from disk or initialize from a persistent store |
| `parse` | Convert from a raw format (string, bytes) to a structured type |
| `validate` | Check correctness, return errors or throw |
| `ensure` | Validate and fix/create if missing |
| `build` / `create` | Construct a new instance |
| `format` | Convert a structured type to a display string |
| `serialize` / `deserialize` | Convert to/from a wire format |

## File Naming

A file name must match its primary export or class. If the file contains a `UserProfileService` class, the file is named `user_profile_service.py` or `UserProfileService.ts`. Never name a file `helpers.py`, `utils.ts`, or `misc.go`.

| Bad File Name | Good File Name | Why |
|---------------|----------------|-----|
| `helpers.ts` | `currency-formatter.ts` | Name the actual responsibility |
| `utils.py` | `string_validation.py` | One clear purpose per file |
| `misc.go` | `retry.go` | Name the concept it contains |
| `common.ts` | `error-codes.ts` | "Common" means "I didn't think about it" |
| `index.ts` (with logic) | `user-router.ts` | Index files re-export; they do not contain logic |
| `types.ts` (300 lines) | `order-types.ts`, `payment-types.ts` | Split by domain |

## Good/Bad Examples

### Python

```python
# BAD: Every name here forces the reader to read the implementation
def process(data):
    result = []
    for item in data:
        if item.value > 0:
            result.append(item)
    return result

# GOOD: The reader understands this without seeing the body
def filter_profitable_transactions(transactions: list[Transaction]) -> list[Transaction]:
    profitable = []
    for transaction in transactions:
        if transaction.net_revenue > 0:
            profitable.append(transaction)
    return profitable
```

### TypeScript

```typescript
// BAD: "handle" tells you nothing, "data" tells you less
function handleData(data: any) {
  const result = data.map((item: any) => item.value);
  const temp = result.filter((v: number) => v > 0);
  return temp;
}

// GOOD: Every name carries meaning
function extractPositiveRevenues(salesRecords: SalesRecord[]): number[] {
  const revenues = salesRecords.map((record) => record.monthlyRevenue);
  const positiveRevenues = revenues.filter((revenue) => revenue > 0);
  return positiveRevenues;
}
```

### Go

```go
// BAD: What does "Manager" manage? What is "Process"?
type Manager struct {
    items []interface{}
}

func (m *Manager) Process(data interface{}) interface{} {
    result := doSomething(data)
    return result
}

// GOOD: The struct name declares its purpose, the method its action
type OrderFulfillmentQueue struct {
    pendingOrders []Order
}

func (q *OrderFulfillmentQueue) DispatchNextOrder() (*ShipmentConfirmation, error) {
    order := q.pendingOrders[0]
    confirmation, err := shipOrder(order)
    return confirmation, err
}
```

## Examples

Working implementations in `examples/`:
- **`examples/naming-before-after.md`** -- Multi-language examples showing bad-to-good naming transformations across Python, TypeScript, and Go, covering variables, functions, classes, and file names

## Review Checklist

When reviewing code for naming precision:

- [ ] No identifier uses a banned name (`data`, `info`, `temp`, `result`, `value`, `item`, `thing`, `handle`, `process`, `manager`, `helper`, `utils`, `misc`)
- [ ] Every variable name describes what it holds, not its type or shape
- [ ] Every function name follows verb + noun pattern (`fetchUserProfile`, `calculateTaxRate`, `validateEmailFormat`)
- [ ] Function verbs are precise (`fetch` vs `get` vs `find` vs `compute` -- each used correctly)
- [ ] Scope-appropriate length: short names only in tight scopes (loop indices, lambdas), long names for wide scopes (module-level, exported)
- [ ] Domain language is used instead of programmer jargon (`invoice` not `record`, `customer` not `entity`)
- [ ] File names match their primary export or class
- [ ] No files named `helpers`, `utils`, `misc`, or `common` -- each file has a specific responsibility
- [ ] Boolean variables and functions follow naming conventions (covered in `boolean-naming` skill)
- [ ] Abbreviations follow the abbreviation policy (covered in `abbreviation-policy` skill)
- [ ] A new team member could understand the purpose of every identifier without reading the implementation
- [ ] No two identifiers in the same scope are confusingly similar (e.g., `user` and `userData` holding different things)
