---
name: symmetry
description: "This skill should be used when the user is writing parallel code paths (CRUD operations, event handlers, API endpoints), implementing matching pairs (create/destroy, open/close, serialize/deserialize), or when similar operations have dissimilar structures. Covers structural mirroring, signature consistency, and the rule that parallel things must look parallel."
version: 1.0.0
---

# Parallel Things Must Look Parallel

If two functions do analogous work, they must have analogous structure. Same parameter order. Same return shape. Same error handling pattern. Same naming scheme. No exceptions. No "well, this one is slightly different because..." -- stop. If the work is parallel, the code is parallel. Period.

Symmetry is not aesthetics. It is how a reader builds a mental model of your codebase. When `create_user` and `create_product` have the same shape, the reader learns the pattern once and applies it everywhere. When they differ -- different parameter order, different return type, different error wrapping -- the reader must re-learn the pattern for every module. That is a tax on every person who touches the code for the rest of its life.

## The Symmetry Rule

**If two things do analogous work, they must have analogous structure.**

This applies at every level:
- **Function signatures** -- same parameter order, same types, same defaults
- **Return shapes** -- same envelope, same field names, same error representation
- **Error handling** -- same wrapping strategy, same logging, same recovery pattern
- **Naming** -- same verb/noun scheme, same prefixes, same suffixes
- **File structure** -- same sections, same ordering, same grouping
- **Test structure** -- same setup, same assertion style, same teardown

## CRUD Symmetry

CRUD handlers are the most common symmetry violation. Every handler for a resource must have identical structure: same logging calls, same error handling, same response shape. If `create` logs the operation, `delete` logs the operation. If `read` wraps errors in a `ServiceError`, `update` wraps errors in a `ServiceError`.

**GOOD -- symmetric CRUD:**

```python
class UserService:
    def create_user(self, data: CreateUserInput) -> ServiceResult[User]:
        logger.info("creating user", extra={"email": data.email})
        try:
            user = self.repo.insert(data)
            return ServiceResult(data=user, error=None)
        except DatabaseError as exc:
            logger.error("failed to create user", extra={"error": str(exc)})
            return ServiceResult(data=None, error=ServiceError.from_exception(exc))

    def get_user(self, user_id: str) -> ServiceResult[User]:
        logger.info("getting user", extra={"user_id": user_id})
        try:
            user = self.repo.find_by_id(user_id)
            return ServiceResult(data=user, error=None)
        except DatabaseError as exc:
            logger.error("failed to get user", extra={"error": str(exc)})
            return ServiceResult(data=None, error=ServiceError.from_exception(exc))

    def update_user(self, user_id: str, data: UpdateUserInput) -> ServiceResult[User]:
        logger.info("updating user", extra={"user_id": user_id})
        try:
            user = self.repo.update(user_id, data)
            return ServiceResult(data=user, error=None)
        except DatabaseError as exc:
            logger.error("failed to update user", extra={"error": str(exc)})
            return ServiceResult(data=None, error=ServiceError.from_exception(exc))

    def delete_user(self, user_id: str) -> ServiceResult[None]:
        logger.info("deleting user", extra={"user_id": user_id})
        try:
            self.repo.remove(user_id)
            return ServiceResult(data=None, error=None)
        except DatabaseError as exc:
            logger.error("failed to delete user", extra={"error": str(exc)})
            return ServiceResult(data=None, error=ServiceError.from_exception(exc))
```

Every method: log entry, try/except, repo call, `ServiceResult` return, error wrapping. Same shape. A reader who understands one method understands all four.

**BAD -- asymmetric CRUD:**

```python
class UserService:
    def create_user(self, data: CreateUserInput) -> User:
        # Returns raw object, no wrapper
        user = self.repo.insert(data)
        print(f"Created user {user.id}")  # print instead of logger
        return user

    def get_user(self, user_id: str) -> dict:
        # Returns dict instead of model
        try:
            return self.repo.find_by_id(user_id).__dict__
        except Exception:
            return None  # Swallows error, returns None

    def update_user(self, user_id: str, data: UpdateUserInput) -> ServiceResult[User]:
        # Now suddenly uses ServiceResult
        logger.info("updating user", extra={"user_id": user_id})
        try:
            user = self.repo.update(user_id, data)
            return ServiceResult(data=user, error=None)
        except DatabaseError as exc:
            return ServiceResult(data=None, error=ServiceError.from_exception(exc))

    def remove(self, id: str) -> bool:
        # Different method name. Different param name. Returns bool.
        self.repo.remove(id)
        return True
```

Four methods, four different patterns. Different return types (`User`, `dict`, `ServiceResult`, `bool`). Different error handling (none, swallow, wrap, ignore). Different naming (`delete_user` vs `remove`, `user_id` vs `id`). This is not a service -- it is four unrelated functions that happen to share a class.

## Matching Pairs

If you have `open`, you have `close`. Not `disconnect`. Not `shutdown`. Not `teardown`. The naming mirrors the action.

**The rule:** for every operation that acquires/creates/starts something, the inverse operation uses the exact antonym with the same noun.

| Create | Destroy |
|--------|---------|
| `open_connection` | `close_connection` |
| `acquire_lock` | `release_lock` |
| `start_timer` | `stop_timer` |
| `subscribe` | `unsubscribe` |
| `serialize` | `deserialize` |
| `encode` | `decode` |
| `push` | `pop` |
| `begin_transaction` | `end_transaction` |
| `register_handler` | `unregister_handler` |
| `create_session` | `destroy_session` |

**BAD pairs:**

| Create | Destroy | Problem |
|--------|---------|---------|
| `open_connection` | `disconnect` | Different verb, dropped noun |
| `acquire_lock` | `free_lock` | `free` is not the antonym of `acquire` |
| `start_timer` | `cancel_timer` | `cancel` implies error; `stop` is the antonym |
| `create_session` | `end_session` | `end` is not the antonym of `create`; use `destroy` |
| `register_handler` | `remove_handler` | `remove` is not the antonym of `register` |

## Function Signature Consistency

If `create_user(name, email, role)` takes arguments in that order, then `update_user(name, email, role)` takes them in the same order. Not `update_user(email, name, role)`. Not `update_user(role, name, email)`.

**GOOD:**

```typescript
function createUser(name: string, email: string, role: Role): Promise<User>;
function updateUser(id: string, name: string, email: string, role: Role): Promise<User>;
function deleteUser(id: string): Promise<void>;

function createProduct(name: string, price: number, category: Category): Promise<Product>;
function updateProduct(id: string, name: string, price: number, category: Category): Promise<Product>;
function deleteProduct(id: string): Promise<void>;
```

The pattern: create takes the fields. Update takes `id` first, then the same fields in the same order. Delete takes `id`. This holds for every resource.

**BAD:**

```typescript
function createUser(name: string, email: string, role: Role): Promise<User>;
function updateUser(email: string, role: Role, name: string, id: string): Promise<User>;
function removeUser(userId: string): Promise<boolean>;

function createProduct(category: Category, name: string, price: number): Promise<Product>;
function modifyProduct(id: string, updates: Partial<Product>): Promise<Product>;
function deleteProduct(id: string): Promise<void>;
```

Parameter order shuffled. Verbs inconsistent (`update`/`modify`/`remove`/`delete`). One returns `Promise<boolean>`, others return the entity. One takes a partial object, others take individual fields. The reader must check every signature individually.

## Return Shape Consistency

If `getUser` returns `{ data, error }`, then `getProduct` returns `{ data, error }`. Not `{ result, err }`. Not `{ payload, exception }`. Not just the raw object.

**GOOD:**

```go
type Result[T any] struct {
    Data  T
    Error error
}

func (s *UserService) GetUser(id string) Result[User] {
    user, err := s.repo.FindByID(id)
    return Result[User]{Data: user, Error: err}
}

func (s *ProductService) GetProduct(id string) Result[Product] {
    product, err := s.repo.FindByID(id)
    return Result[Product]{Data: product, Error: err}
}

func (s *OrderService) GetOrder(id string) Result[Order] {
    order, err := s.repo.FindByID(id)
    return Result[Order]{Data: order, Error: err}
}
```

**BAD:**

```go
func (s *UserService) GetUser(id string) (*User, error) {
    return s.repo.FindByID(id)
}

func (s *ProductService) GetProduct(id string) (ProductResult, error) {
    // Returns a different wrapper type
    p, err := s.repo.FindByID(id)
    return ProductResult{Payload: p}, err
}

func (s *OrderService) FetchOrder(id string) map[string]interface{} {
    // Different verb. Returns raw map. No error.
    order, _ := s.repo.FindByID(id)
    return orderToMap(order)
}
```

Three services, three different return conventions. A developer touching any service must first discover that service's unique return pattern instead of relying on the one they already know.

## Error Handling Symmetry

If module A wraps errors with `fmt.Errorf("user: %w", err)`, module B wraps them with `fmt.Errorf("product: %w", err)`. Same format string structure. Same wrapping verb. Same context level.

**GOOD:**

```go
// user_service.go
func (s *UserService) Create(input CreateUserInput) (*User, error) {
    user, err := s.repo.Insert(input)
    if err != nil {
        return nil, fmt.Errorf("user service: create: %w", err)
    }
    return user, nil
}

// product_service.go
func (s *ProductService) Create(input CreateProductInput) (*Product, error) {
    product, err := s.repo.Insert(input)
    if err != nil {
        return nil, fmt.Errorf("product service: create: %w", err)
    }
    return product, nil
}
```

**BAD:**

```go
// user_service.go
func (s *UserService) Create(input CreateUserInput) (*User, error) {
    user, err := s.repo.Insert(input)
    if err != nil {
        return nil, fmt.Errorf("user service: create: %w", err)
    }
    return user, nil
}

// product_service.go
func (s *ProductService) Create(input CreateProductInput) (*Product, error) {
    product, err := s.repo.Insert(input)
    if err != nil {
        return nil, errors.New("failed to create product: " + err.Error())
        // Different wrapping style. Uses errors.New instead of fmt.Errorf.
        // Loses the error chain (%w). Different message format.
    }
    return product, nil
}
```

## Test Symmetry

Test files for similar modules should mirror each other. Same describe/it structure. Same setup pattern. Same assertion helpers. If someone can look at `user_test.go` and predict the shape of `product_test.go`, the tests are symmetric.

**GOOD:**

```typescript
// user.test.ts
describe("UserService", () => {
  let service: UserService;
  let repo: MockUserRepo;

  beforeEach(() => {
    repo = new MockUserRepo();
    service = new UserService(repo);
  });

  describe("create", () => {
    it("returns the created user", async () => { /* ... */ });
    it("throws ValidationError on invalid input", async () => { /* ... */ });
    it("wraps database errors in ServiceError", async () => { /* ... */ });
  });

  describe("getById", () => {
    it("returns the user when found", async () => { /* ... */ });
    it("throws NotFoundError when missing", async () => { /* ... */ });
  });
});

// product.test.ts -- same shape
describe("ProductService", () => {
  let service: ProductService;
  let repo: MockProductRepo;

  beforeEach(() => {
    repo = new MockProductRepo();
    service = new ProductService(repo);
  });

  describe("create", () => {
    it("returns the created product", async () => { /* ... */ });
    it("throws ValidationError on invalid input", async () => { /* ... */ });
    it("wraps database errors in ServiceError", async () => { /* ... */ });
  });

  describe("getById", () => {
    it("returns the product when found", async () => { /* ... */ });
    it("throws NotFoundError when missing", async () => { /* ... */ });
  });
});
```

## The "Local Optimization" Anti-Pattern

The most common symmetry violation starts with a reasonable-sounding excuse: "This function is slightly different, so I will handle it slightly differently." Maybe `delete` does not need to return the entity. Maybe `getProduct` can skip error wrapping because "it is simple." Maybe `closeConnection` is called `teardown` because "it does more than just closing."

Every one of these "local optimizations" breaks the global pattern. The reader now has two patterns to track instead of one. Then a third developer adds a third variation. Within six months, every function is a special case and no one can predict the shape of anything.

**The fix is simple:** match the existing pattern. If the pattern is wrong, change it everywhere. Never create a one-off variation.

## Examples

Working implementations in `examples/`:
- **`examples/parallel-structure.md`** -- Multi-language examples showing symmetric vs asymmetric code paths for CRUD operations and matching pairs in Python, TypeScript, and Go

## Review Checklist

When reviewing code that involves parallel operations:

- [ ] All CRUD handlers for a resource have identical structure -- same logging, same error handling, same response shape
- [ ] Matching pairs use exact antonyms with the same noun (`open_connection`/`close_connection`, not `open_connection`/`disconnect`)
- [ ] Functions that do analogous work across different modules have the same parameter order
- [ ] Return shapes are identical across parallel functions -- same wrapper type, same field names
- [ ] Error handling follows the same wrapping strategy in every module -- same format, same context level
- [ ] Test files for similar modules mirror each other -- same structure, same setup, same assertion patterns
- [ ] No "local optimization" has created a one-off variation of an established pattern
- [ ] If a new function does not fit the existing pattern, the pattern is updated everywhere -- not just bypassed here
- [ ] Event handler registrations follow the same signature pattern (same args, same return, same naming)
- [ ] Serialization/deserialization pairs are structurally identical -- same options, same error handling
