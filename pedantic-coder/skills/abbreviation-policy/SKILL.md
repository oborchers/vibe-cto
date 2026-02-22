---
name: abbreviation-policy
description: "This skill should be used when the user is abbreviating identifiers, using acronyms, or when a codebase has inconsistent short forms like btn/button, msg/message, req/request. Covers the abbreviation decision framework, approved short forms, and the rule that consistency beats brevity."
version: 1.0.0
---

# Full Words by Default, Abbreviations by Exception

Every abbreviation is a tax on the reader. The writer saves a few keystrokes; every future reader pays the cost of decoding. Modern editors autocomplete. Modern screens are wide. Modern codebases are searched, not memorized. There is no defensible reason to abbreviate an identifier unless the abbreviation is more widely recognized than the full word. `url` is clearer than `uniformResourceLocator`. `btn` is not clearer than `button`. This is the line, and it is not negotiable.

## The Abbreviation Decision Framework

Before using any abbreviation, apply this test in order:

1. **Is it on the universally understood list?** Use it. `id`, `url`, `http` -- everyone knows these.
2. **Would a new hire need to ask what it means?** Spell it out. `txMgr` for "transaction manager" fails this test.
3. **Is it in your project's abbreviation registry?** Use it, but only if the registry exists and is maintained.
4. **None of the above?** Use the full word. Always.

The burden of proof is on the abbreviation. Full words are correct by default.

## Universally Understood Abbreviations

These abbreviations are approved for use in any codebase without documentation. They are more recognizable than their expanded forms.

| Abbreviation | Meaning | Context |
|-------------|---------|---------|
| `id` | Identifier | Any |
| `url` | Uniform Resource Locator | Any |
| `http` / `https` | Hypertext Transfer Protocol | Any |
| `api` | Application Programming Interface | Any |
| `db` | Database | Any |
| `sql` | Structured Query Language | Any |
| `html` | HyperText Markup Language | Any |
| `css` | Cascading Style Sheets | Any |
| `json` | JavaScript Object Notation | Any |
| `xml` | Extensible Markup Language | Any |
| `config` | Configuration | Any |
| `auth` | Authentication / Authorization | Any |
| `admin` | Administrator | Any |
| `err` | Error | Go (idiomatic), acceptable elsewhere |
| `ctx` | Context | Go (idiomatic), acceptable elsewhere |
| `req` | Request | Handler functions, middleware |
| `res` / `resp` | Response | Handler functions, middleware |
| `fn` | Function | Callbacks, higher-order functions |
| `args` | Arguments | Any |
| `params` | Parameters | Any |
| `env` | Environment | Configuration, deployment |
| `src` | Source | Build systems, file operations |
| `dst` | Destination | File operations, network |
| `tmp` | Temporary | Only for genuinely temporary values with a lifespan of a few lines |
| `max` | Maximum | Any |
| `min` | Minimum | Any |
| `len` | Length | Any |
| `num` | Number (count of) | Prefixing a noun: `numRetries`, `num_users` |
| `prev` | Previous | Iteration, state management |
| `next` | Next | Iteration, state management |
| `init` | Initialize | Startup, constructors |
| `msg` | Message | Messaging systems, logs, chat |
| `doc` | Document | Document management, databases |
| `img` | Image | Media handling, UI |
| `btn` | Button | UI contexts only -- never in backend code |
| `info` | Information | Only as part of a compound: `userInfo`, `errorInfo` -- never standalone |

**`info` as a standalone name is banned.** See the `naming-precision` skill. `info` is only acceptable as a suffix in a compound where the first word provides the specificity: `errorInfo`, `connectionInfo`.

## The New Hire Test

This is the definitive test for any abbreviation not on the universally understood list.

> If a competent developer joining your team today would need to ask "what does this mean?" when reading the code, the abbreviation is unacceptable.

| Abbreviation | Passes? | Why |
|-------------|---------|-----|
| `url` | Yes | Every developer knows this |
| `config` | Yes | Universal in software |
| `btn` | Yes (UI) / No (backend) | UI developers know it; backend developers may not |
| `txn` | Borderline | Common in financial codebases, obscure elsewhere. Document it. |
| `svc` | No | Write `service` |
| `mgr` | No | Write `manager` (then rename to something precise -- see `naming-precision`) |
| `impl` | No | Write `implementation` or, better, name what it implements |
| `repo` | Borderline | Common in DDD codebases. Document it or write `repository`. |
| `util` | No | Write nothing -- split the utility into specific modules |
| `acct` | No | Write `account` |
| `addr` | No | Write `address` |
| `amt` | No | Write `amount` |
| `attr` | No | Write `attribute` |
| `calc` | No | Write `calculate` or `calculation` |
| `cb` | No | Write `callback` |
| `cmd` | Borderline | Common in CLI contexts. Write `command` elsewhere. |
| `coll` | No | Write `collection` |
| `desc` | No | Write `description` |
| `dest` | No | Write `destination` -- or use the approved `dst` |
| `dict` | Borderline | Python: `dict` is the type name, fine. Elsewhere: write `dictionary` or `map`. |
| `fmt` | Go only | Go's `fmt` package makes this idiomatic in Go. Write `format` elsewhere. |
| `idx` | Borderline | Write `index`. `i` is fine for loop counters. |
| `lbl` | No | Write `label` |
| `lib` | Borderline | Common in build systems. Write `library` in application code. |
| `obj` | No | Name the actual thing. See `naming-precision`. |
| `pkg` | Go only | Go convention. Write `package` elsewhere. |
| `ptr` | Go/C only | Idiomatic in systems languages. Write `pointer` in high-level code. |
| `ref` | No | Write `reference` |
| `str` | Borderline | Python: `str` is the type name. Elsewhere: write `string`. |
| `tbl` | No | Write `table` |
| `val` | No | Write `value` -- then rename to something specific. See `naming-precision`. |

## The Consistency Rule

This rule supersedes all others. **If you use an abbreviation once, you use it everywhere. If you spell it out once, you spell it out everywhere.**

```python
# UNACCEPTABLE: message in one place, msg in another
def send_message(message: str) -> None:
    log.info(f"Sending msg: {message}")       # msg vs message
    queue.publish(msg=message)                 # msg parameter
    track_event("message_sent")               # message in event name

# CORRECT: pick one form and use it everywhere
def send_message(message: str) -> None:
    log.info(f"Sending message: {message}")
    queue.publish(message=message)
    track_event("message_sent")
```

```typescript
// UNACCEPTABLE: button in component names, btn in props and handlers
function SubmitButton({ btnText, onBtnClick }: SubmitButtonProps) {
  return <button onClick={onBtnClick}>{btnText}</button>;
}

// CORRECT: one form throughout
function SubmitButton({ buttonText, onButtonClick }: SubmitButtonProps) {
  return <button onClick={onButtonClick}>{buttonText}</button>;
}
```

```go
// UNACCEPTABLE: request in one function, req in another
func HandleRequest(request *http.Request) { ... }
func validateReq(req *http.Request) error { ... }
func logRequest(request *http.Request) { ... }

// CORRECT: pick one -- in Go handler code, req is idiomatic
func HandleRequest(req *http.Request) { ... }
func validateRequest(req *http.Request) error { ... }
func logRequest(req *http.Request) { ... }
```

**Cross-file consistency is mandatory.** If `user_service.py` uses `message` and `notification_service.py` uses `msg`, the codebase is inconsistent. Grep the codebase. Pick one. Change all occurrences.

## The Project-Level Abbreviation Registry

For any abbreviation that is not universally understood but is widely used in your domain, maintain an explicit registry. This is a file in your repository -- not a wiki, not a Confluence page, not tribal knowledge.

```markdown
# Abbreviation Registry

These abbreviations are approved for use throughout this codebase.
Using the full form is also acceptable. Mixing forms is not.

| Abbreviation | Full Form       | Context                        |
|-------------|-----------------|--------------------------------|
| `txn`       | transaction     | Payment processing, ledger     |
| `repo`      | repository      | Data access layer              |
| `sku`       | stock keeping unit | Inventory, catalog           |
| `qty`       | quantity        | Orders, inventory              |
| `amt`       | amount          | Financial calculations         |
| `org`       | organization    | Multi-tenancy                  |
```

**Rules for the registry:**
- It lives in the repository root (e.g., `ABBREVIATIONS.md` or a section in `CONTRIBUTING.md`)
- Every entry includes the context where it is used
- Adding a new abbreviation requires team agreement
- The registry is referenced in code review guidelines
- If an abbreviation is not in the registry and not universally understood, it is rejected in review

## Acronym Casing Rules

Multi-letter acronyms follow language-specific casing rules. These are covered in detail in the `casing-law` skill, but the abbreviation-relevant summary is:

| Language | Rule | Example |
|----------|------|---------|
| Python | Treat as a word in PascalCase | `HttpClient`, `JsonParser`, `UrlValidator` |
| TypeScript | Treat as a word in PascalCase/camelCase | `HttpClient`, `jsonParser`, `urlValidator` |
| Go | Keep well-known acronyms uppercase | `HTTPClient`, `JSONParser`, `URLValidator` |

**Two-letter acronyms** are a special case:
- Python / TypeScript: treat as a word: `Id`, `Ip`, `Io` in PascalCase
- Go: keep uppercase: `ID`, `IP`, `IO`

Refer to the `casing-law` skill for the complete acronym list and handling rules.

## Good/Bad Examples

### Python

```python
# BAD: Inconsistent abbreviations, unapproved short forms
def calc_ttl_amt(txn_lst, disc_pct):
    ttl = 0
    for txn in txn_lst:
        ttl += txn.amt - (txn.amt * disc_pct / 100)
    return ttl

usr_acct = get_usr_acct(acct_id)
btn_clr = get_btn_clr(theme)
addr_str = fmt_addr(usr_acct.addr)

# GOOD: Full words, clear meaning
def calculate_total_amount(
    transactions: list[Transaction],
    discount_percent: float,
) -> float:
    total = 0.0
    for transaction in transactions:
        total += transaction.amount - (transaction.amount * discount_percent / 100)
    return total

user_account = get_user_account(account_id)
button_color = get_button_color(theme)
formatted_address = format_address(user_account.address)
```

### TypeScript

```typescript
// BAD: Abbreviated everything, impossible to read without a decoder ring
interface UsrAcct {
  acctId: string;
  dispNm: string;
  regDt: Date;
  lstLoginTs: number;
  emailAddr: string;
  numOrds: number;
}

function updUsrAcctInfo(acctId: string, updData: Partial<UsrAcct>): void { ... }
function getAcctOrds(acctId: string, pgNum: number, pgSz: number): OrdLst { ... }

// GOOD: Full words, instantly readable
interface UserAccount {
  accountId: string;
  displayName: string;
  registrationDate: Date;
  lastLoginTimestamp: number;
  emailAddress: string;
  orderCount: number;
}

function updateUserAccountInfo(accountId: string, updates: Partial<UserAccount>): void { ... }
function getAccountOrders(accountId: string, pageNumber: number, pageSize: number): OrderList { ... }
```

### Go

```go
// BAD: Over-abbreviated, unclear
func ProcMsg(ctx context.Context, msg *Msg) (*Resp, error) {
    v := validateMsg(msg)
    if v != nil {
        return nil, v
    }
    r, err := svc.SendMsg(ctx, msg)
    if err != nil {
        return nil, fmt.Errorf("snd msg: %w", err)
    }
    return r, nil
}

// GOOD: Approved abbreviations only (ctx, msg, err), rest spelled out
func ProcessMessage(ctx context.Context, message *Message) (*MessageResponse, error) {
    validationErr := validateMessage(message)
    if validationErr != nil {
        return nil, validationErr
    }
    response, err := messageService.SendMessage(ctx, message)
    if err != nil {
        return nil, fmt.Errorf("send message: %w", err)
    }
    return response, nil
}
```

## Examples

Working implementations in `examples/`:
- **`examples/abbreviation-rules.md`** -- Multi-language examples showing consistent vs inconsistent abbreviation usage in Python, TypeScript, and Go, with a sample abbreviation registry

## Review Checklist

When reviewing code for abbreviation policy compliance:

- [ ] No abbreviations used that are not on the universally understood list or in the project's abbreviation registry
- [ ] Every identifier passes the new hire test: a developer joining today would not need to ask what it means
- [ ] Consistency is absolute: if `message` is used anywhere, `msg` is not used in any other file (or vice versa)
- [ ] No mixed forms within the same file, module, or package
- [ ] Multi-letter acronyms follow language-specific casing rules (see `casing-law` skill)
- [ ] `info` is never used as a standalone name -- only as part of a compound (`errorInfo`, `connectionInfo`)
- [ ] `btn` is only used in UI-layer code, never in backend or business logic
- [ ] `tmp` is only used for genuinely temporary values with a lifespan of a few lines
- [ ] Domain-specific abbreviations (`txn`, `sku`, `qty`) are documented in the project's abbreviation registry
- [ ] The abbreviation registry exists if the project uses any non-universal abbreviations
- [ ] No invented abbreviations (`acct`, `addr`, `calc`, `desc`, `lbl`, `tbl`, `val`) unless explicitly approved and registered
- [ ] Error messages and log strings use full words, not abbreviations
