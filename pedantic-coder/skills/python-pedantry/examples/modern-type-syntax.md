# Modern Type Syntax

Side-by-side comparison of legacy typing imports versus modern Python 3.10+ type syntax. Every example on the left is wrong. Every example on the right is correct. No exceptions.

## Basic Types: Builtin Generics

### Legacy (Do Not Use)

```python
from typing import List, Dict, Tuple, Set, FrozenSet, Type

def process_items(
    items: List[str],
    metadata: Dict[str, int],
    coordinates: Tuple[float, float],
    tags: Set[str],
    frozen_tags: FrozenSet[str],
    model_class: Type["BaseModel"],
) -> List[Dict[str, str]]:
    ...
```

### Modern (Use This)

```python
def process_items(
    items: list[str],
    metadata: dict[str, int],
    coordinates: tuple[float, float],
    tags: set[str],
    frozen_tags: frozenset[str],
    model_class: type["BaseModel"],
) -> list[dict[str, str]]:
    ...
```

No import needed. The builtins support subscript syntax directly since Python 3.9 (with `from __future__ import annotations`) and natively since 3.10.

## Optional and Union

### Legacy (Do Not Use)

```python
from typing import Optional, Union

def find_user(
    user_id: str,
    include_deleted: bool = False,
) -> Optional[User]:
    ...

def parse_value(raw: str) -> Union[int, float, str]:
    ...

def send_notification(
    user: User,
    message: str,
    channel: Optional[Union[str, list[str]]] = None,
) -> None:
    ...
```

### Modern (Use This)

```python
def find_user(
    user_id: str,
    include_deleted: bool = False,
) -> User | None:
    ...

def parse_value(raw: str) -> int | float | str:
    ...

def send_notification(
    user: User,
    message: str,
    channel: str | list[str] | None = None,
) -> None:
    ...
```

`X | None` reads naturally as "X or None." `Optional[X]` buries the meaning inside a generic. The pipe syntax is clearer in every case, especially with multiple types.

## ClassVar for Class Attributes

### Legacy (Do Not Use)

```python
class OrderProcessor:
    MAX_RETRIES = 3
    BATCH_SIZE = 100
    SUPPORTED_CURRENCIES = ["USD", "EUR", "GBP"]
```

### Modern (Use This)

```python
from typing import ClassVar

class OrderProcessor:
    MAX_RETRIES: ClassVar[int] = 3
    BATCH_SIZE: ClassVar[int] = 100
    SUPPORTED_CURRENCIES: ClassVar[list[str]] = ["USD", "EUR", "GBP"]
```

`ClassVar` explicitly declares these belong to the class, not instances. Type checkers will catch attempts to set them on instances.

## Callable Types

### Legacy (Do Not Use)

```python
from typing import Callable

def retry(
    func: Callable[[str, int], bool],
    on_failure: Callable[[], None],
) -> bool:
    ...
```

### Modern (Use This)

```python
from collections.abc import Callable

def retry(
    func: Callable[[str, int], bool],
    on_failure: Callable[[], None],
) -> bool:
    ...
```

`Callable` still requires an import, but from `collections.abc`, not `typing`. The `typing.Callable` is deprecated in favor of `collections.abc.Callable`.

## Iterator, Generator, and Sequence

### Legacy (Do Not Use)

```python
from typing import Iterator, Generator, Sequence, Iterable, Mapping

def paginate(items: Sequence[Item]) -> Iterator[list[Item]]:
    ...

def stream_events(source: Iterable[RawEvent]) -> Generator[Event, None, None]:
    ...

def merge_configs(base: Mapping[str, str], overrides: Mapping[str, str]) -> dict[str, str]:
    ...
```

### Modern (Use This)

```python
from collections.abc import Iterator, Generator, Sequence, Iterable, Mapping

def paginate(items: Sequence[Item]) -> Iterator[list[Item]]:
    ...

def stream_events(source: Iterable[RawEvent]) -> Generator[Event, None, None]:
    ...

def merge_configs(base: Mapping[str, str], overrides: Mapping[str, str]) -> dict[str, str]:
    ...
```

All abstract base classes come from `collections.abc`, not `typing`.

## Complete Before/After: A Real Module

### Before -- Legacy Typing Throughout

```python
from typing import Any, ClassVar, Dict, Final, List, Optional, Set, Tuple, Union
from datetime import datetime
from enum import StrEnum


class TaskStatus(StrEnum):
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"


class TaskManager:
    MAX_CONCURRENT: int = 10
    DEFAULT_TIMEOUT: int = 300

    def __init__(self, workers: int = 4) -> None:
        self.workers = workers
        self.tasks: Dict[str, "Task"] = {}
        self.completed: List[str] = []
        self.failed: Set[str] = set()

    def submit(
        self,
        name: str,
        payload: Dict[str, Any],
        priority: Optional[int] = None,
        tags: Optional[List[str]] = None,
        timeout: Optional[int] = None,
    ) -> str:
        ...

    def get_result(self, task_id: str) -> Optional[Dict[str, Any]]:
        ...

    def get_stats(self) -> Dict[str, Union[int, float]]:
        ...

    def cancel(self, task_ids: List[str]) -> Tuple[List[str], List[str]]:
        """Returns (cancelled, not_found)."""
        ...
```

### After -- Modern Python

```python
from typing import Any, ClassVar, Final
from datetime import datetime
from enum import StrEnum


class TaskStatus(StrEnum):
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"


class TaskManager:
    MAX_CONCURRENT: ClassVar[int] = 10
    DEFAULT_TIMEOUT: ClassVar[int] = 300

    def __init__(self, workers: int = 4) -> None:
        self.workers = workers
        self.tasks: dict[str, "Task"] = {}
        self.completed: list[str] = []
        self.failed: set[str] = set()

    def submit(
        self,
        name: str,
        payload: dict[str, Any],
        priority: int | None = None,
        tags: list[str] | None = None,
        timeout: int | None = None,
    ) -> str:
        ...

    def get_result(self, task_id: str) -> dict[str, Any] | None:
        ...

    def get_stats(self) -> dict[str, int | float]:
        ...

    def cancel(self, task_ids: list[str]) -> tuple[list[str], list[str]]:
        """Returns (cancelled, not_found)."""
        ...
```

**What changed:**
- `Dict` -> `dict`, `List` -> `list`, `Set` -> `set`, `Tuple` -> `tuple`
- `Optional[X]` -> `X | None`
- `Union[int, float]` -> `int | float`
- `ClassVar` added to class-level constants
- `typing` imports reduced from 9 to 3 (`Any`, `ClassVar`, `Final` -- these have no builtin equivalents)

## Ruff Rules That Enforce This

| Rule | What It Catches |
|------|----------------|
| `UP006` | `typing.List` -> `list`, `typing.Dict` -> `dict`, etc. |
| `UP007` | `typing.Optional[X]` -> `X \| None`, `typing.Union[X, Y]` -> `X \| Y` |
| `UP035` | `typing.Sequence` -> `collections.abc.Sequence`, etc. |

Enable all three. They auto-fix with `ruff check --fix`.

## Key Points

- Modern syntax requires zero imports for basic generics (`list`, `dict`, `set`, `tuple`, `frozenset`, `type`)
- `X | None` is universally clearer than `Optional[X]`
- Abstract collections (`Sequence`, `Mapping`, `Iterator`) come from `collections.abc`, not `typing`
- `typing` is still needed for: `Any`, `ClassVar`, `Final`, `Literal`, `TypeVar`, `Generic`, `Protocol`, `TypedDict`, `Annotated`, `ParamSpec`
- Ruff rules UP006, UP007, UP035 catch and auto-fix all legacy typing patterns