# Parallel Structure

Multi-language examples showing symmetric vs asymmetric code paths. Every parallel operation -- CRUD handlers, matching pairs, event handlers -- must have identical structure. When one deviates, the reader's mental model breaks.

## Python -- CRUD Service Symmetry

### BAD -- Every method is a snowflake

```python
class ProjectService:
    def create_project(self, name: str, owner_id: str) -> Project:
        project = self.db.insert({"name": name, "owner_id": owner_id})
        print(f"Created {project.id}")
        return project

    def get_project(self, project_id: str) -> dict | None:
        try:
            return self.db.find(project_id).__dict__
        except Exception:
            return None

    def update(self, pid: str, fields: dict) -> bool:
        self.db.update(pid, fields)
        logging.info("Updated project %s", pid)
        return True

    def remove_project(self, id: str):
        self.db.delete(id)
```

Problems:
- `create_project` uses `print`, others use `logging` or nothing
- `get_project` returns `dict | None`, `create_project` returns `Project`, `update` returns `bool`
- `update` has a different name (`update` vs `create_project`/`get_project`/`remove_project`)
- `remove_project` uses `remove` instead of `delete` -- breaks the CRUD naming
- Parameter names: `project_id`, `pid`, `id` -- three names for the same concept
- `get_project` swallows errors silently; `create_project` does not handle errors at all

### GOOD -- One pattern, four methods

```python
from dataclasses import dataclass
from typing import Generic, TypeVar

T = TypeVar("T")


@dataclass(frozen=True)
class ServiceResult(Generic[T]):
    data: T | None
    error: ServiceError | None


class ProjectService:
    def __init__(self, repo: ProjectRepo) -> None:
        self.repo = repo

    def create_project(self, name: str, owner_id: str) -> ServiceResult[Project]:
        logger.info("creating project", extra={"owner_id": owner_id})
        try:
            project = self.repo.insert(name=name, owner_id=owner_id)
            return ServiceResult(data=project, error=None)
        except DatabaseError as exc:
            logger.error("failed to create project", extra={"error": str(exc)})
            return ServiceResult(data=None, error=ServiceError.from_exception(exc))

    def get_project(self, project_id: str) -> ServiceResult[Project]:
        logger.info("getting project", extra={"project_id": project_id})
        try:
            project = self.repo.find_by_id(project_id)
            return ServiceResult(data=project, error=None)
        except DatabaseError as exc:
            logger.error("failed to get project", extra={"error": str(exc)})
            return ServiceResult(data=None, error=ServiceError.from_exception(exc))

    def update_project(self, project_id: str, name: str, owner_id: str) -> ServiceResult[Project]:
        logger.info("updating project", extra={"project_id": project_id})
        try:
            project = self.repo.update(project_id, name=name, owner_id=owner_id)
            return ServiceResult(data=project, error=None)
        except DatabaseError as exc:
            logger.error("failed to update project", extra={"error": str(exc)})
            return ServiceResult(data=None, error=ServiceError.from_exception(exc))

    def delete_project(self, project_id: str) -> ServiceResult[None]:
        logger.info("deleting project", extra={"project_id": project_id})
        try:
            self.repo.remove(project_id)
            return ServiceResult(data=None, error=None)
        except DatabaseError as exc:
            logger.error("failed to delete project", extra={"error": str(exc)})
            return ServiceResult(data=None, error=ServiceError.from_exception(exc))
```

Every method: log entry, try/except, repo call, `ServiceResult` return, same error wrapping. Predictable. Scannable. One pattern learned, four methods understood.

## TypeScript -- Matching Pairs

### BAD -- Mismatched verbs and signatures

```typescript
class ConnectionPool {
  openConnection(host: string, port: number): Connection {
    const conn = new Connection(host, port);
    conn.connect();
    this.pool.push(conn);
    return conn;
  }

  disconnect(conn: Connection): void {
    // "disconnect" is not the antonym of "open"
    conn.close();
    this.pool = this.pool.filter((c) => c !== conn);
  }

  startHeartbeat(conn: Connection, intervalMs: number): void {
    conn.heartbeatTimer = setInterval(() => conn.ping(), intervalMs);
  }

  cancelHeartbeat(connection: Connection): void {
    // "cancel" is not the antonym of "start"
    // parameter name "connection" instead of "conn"
    if (connection.heartbeatTimer) {
      clearInterval(connection.heartbeatTimer);
    }
  }

  registerEventHandler(event: string, handler: EventHandler): void {
    this.handlers.set(event, handler);
  }

  removeHandler(eventName: string, fn: EventHandler): void {
    // "remove" is not the antonym of "register"
    // "eventName" instead of "event", "fn" instead of "handler"
    this.handlers.delete(eventName);
  }
}
```

### GOOD -- Exact antonyms, consistent signatures

```typescript
class ConnectionPool {
  openConnection(host: string, port: number): Connection {
    const conn = new Connection(host, port);
    conn.connect();
    this.pool.push(conn);
    return conn;
  }

  closeConnection(conn: Connection): void {
    conn.close();
    this.pool = this.pool.filter((c) => c !== conn);
  }

  startHeartbeat(conn: Connection, intervalMs: number): void {
    conn.heartbeatTimer = setInterval(() => conn.ping(), intervalMs);
  }

  stopHeartbeat(conn: Connection): void {
    if (conn.heartbeatTimer) {
      clearInterval(conn.heartbeatTimer);
    }
  }

  registerHandler(event: string, handler: EventHandler): void {
    this.handlers.set(event, handler);
  }

  unregisterHandler(event: string, handler: EventHandler): void {
    this.handlers.delete(event);
  }
}
```

`open`/`close`. `start`/`stop`. `register`/`unregister`. Same parameter names in each pair. No surprises.

## Go -- Return Shape and Error Wrapping Consistency

### BAD -- Three services, three return conventions

```go
// user_service.go
func (s *UserService) GetUser(id string) (*User, error) {
    user, err := s.repo.FindByID(id)
    if err != nil {
        return nil, fmt.Errorf("user service: get: %w", err)
    }
    return user, nil
}

// product_service.go
func (s *ProductService) GetProduct(id string) (ProductResponse, error) {
    // Different return type -- ProductResponse instead of *Product
    p, err := s.repo.FindByID(id)
    if err != nil {
        return ProductResponse{}, errors.New("product lookup failed: " + err.Error())
        // errors.New instead of fmt.Errorf. Loses the error chain.
        // Different message format.
    }
    return ProductResponse{Item: p, FetchedAt: time.Now()}, nil
}

// order_service.go
func (s *OrderService) FetchOrder(id string) map[string]interface{} {
    // Different verb ("Fetch" instead of "Get").
    // Returns map instead of struct. No error return.
    order, _ := s.repo.FindByID(id)
    result := make(map[string]interface{})
    result["order"] = order
    result["timestamp"] = time.Now()
    return result
}
```

### GOOD -- One return pattern across all services

```go
type ServiceResult[T any] struct {
    Data  T
    Error error
}

// user_service.go
func (s *UserService) GetUser(id string) ServiceResult[*User] {
    user, err := s.repo.FindByID(id)
    if err != nil {
        return ServiceResult[*User]{Error: fmt.Errorf("user service: get: %w", err)}
    }
    return ServiceResult[*User]{Data: user}
}

// product_service.go
func (s *ProductService) GetProduct(id string) ServiceResult[*Product] {
    product, err := s.repo.FindByID(id)
    if err != nil {
        return ServiceResult[*Product]{Error: fmt.Errorf("product service: get: %w", err)}
    }
    return ServiceResult[*Product]{Data: product}
}

// order_service.go
func (s *OrderService) GetOrder(id string) ServiceResult[*Order] {
    order, err := s.repo.FindByID(id)
    if err != nil {
        return ServiceResult[*Order]{Error: fmt.Errorf("order service: get: %w", err)}
    }
    return ServiceResult[*Order]{Data: order}
}
```

Same generic result type. Same `fmt.Errorf` wrapping with `"{service}: {operation}: %w"`. Same verb (`Get`). A developer who reads one service can write the next one from memory.

## Go -- Event Handler Symmetry

### BAD -- Inconsistent handler registration

```go
type EventBus struct { /* ... */ }

func (b *EventBus) On(event string, callback func(payload interface{})) {
    b.handlers[event] = append(b.handlers[event], callback)
}

func (b *EventBus) RemoveListener(eventName string, cb func(payload interface{})) {
    // "RemoveListener" vs "On" -- no symmetry
    // "eventName" vs "event", "cb" vs "callback"
    handlers := b.handlers[eventName]
    // ... removal logic
}

func (b *EventBus) Fire(event string, data interface{}) {
    for _, h := range b.handlers[event] {
        h(data)
    }
}
```

### GOOD -- Symmetric registration

```go
type EventBus struct { /* ... */ }

func (b *EventBus) Subscribe(event string, handler HandlerFunc) {
    b.handlers[event] = append(b.handlers[event], handler)
}

func (b *EventBus) Unsubscribe(event string, handler HandlerFunc) {
    handlers := b.handlers[event]
    // ... removal logic
}

func (b *EventBus) Publish(event string, payload interface{}) {
    for _, handler := range b.handlers[event] {
        handler(payload)
    }
}
```

`Subscribe`/`Unsubscribe` -- exact antonym. Same parameters: `event string, handler HandlerFunc`. `Publish` completes the trio with the same `event` naming.

## Key Points

- CRUD handlers for a resource are identical in shape -- same logging, same error handling, same return type, same naming convention
- Matching pairs use exact antonyms: `open`/`close`, `start`/`stop`, `subscribe`/`unsubscribe`, `register`/`unregister`
- Parameter names are consistent within pairs -- if one uses `conn`, the other uses `conn`, not `connection`
- Return types are consistent across parallel services -- if `GetUser` returns `ServiceResult[*User]`, `GetProduct` returns `ServiceResult[*Product]`
- Error wrapping follows the same format string in every module -- same structure, same context level
- When you find asymmetry, the fix is to match the existing pattern -- not to introduce a third variation
