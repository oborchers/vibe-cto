---
name: import-discipline
description: "This skill should be used when the user is organizing imports, writing require/use/include statements, fixing import ordering, dealing with circular dependencies, or when a file has disordered, ungrouped, or inconsistent imports. Covers import grouping, sorting, separation, and the rule that imports are the table of contents for a file."
version: 1.0.0
---

# Imports Are the Table of Contents

The import block is the first thing a reader sees after the module docstring. It answers the most fundamental question about any file: what does this depend on? A disordered import block is like a book with a scrambled table of contents — it forces the reader to scan every line to understand the file's dependencies. This is not a cosmetic concern. It is a readability failure.

The rules are simple, universal, and non-negotiable: group by origin, separate groups with blank lines, alphabetize within groups, import only what you use, never import everything.

## Universal Grouping Order

Every language has the same conceptual hierarchy. Adapt the specifics; preserve the structure.

```
Group 1: Standard library / built-in modules
          (blank line)
Group 2: Third-party / external packages
          (blank line)
Group 3: Internal / project-level modules
          (blank line)
Group 4: Relative / sibling imports
```

**Rules that apply everywhere:**

1. **One blank line between each group.** Not two. Not zero. One. This is the visual separator that lets the eye jump between dependency categories instantly.
2. **Alphabetized within each group.** Not by "importance," not by "order I wrote them," not by "how often I use them." Alphabetical. This makes merge conflicts smaller, makes it obvious when something is missing, and eliminates all subjective ordering debates forever.
3. **One import per line.** Multi-import lines hide dependencies and make diffs noisy. The exception is destructured imports in JavaScript/TypeScript where a single module provides multiple named exports — but even then, if it exceeds ~4 names, split across lines.
4. **No unused imports.** Not "I might need this later." Not "the linter will catch it." Delete it now. An unused import is a lie in the table of contents — it claims the file depends on something it does not.

## Python

Python's import conventions are well-established. Tools like `isort` and `ruff` enforce them automatically — but you must understand the rules to configure the tools correctly and to catch what they miss.

**Grouping order:**
```python
# 1. __future__ imports (always first, always alone)
from __future__ import annotations

# 2. Standard library
import os
import sys
from collections import defaultdict
from pathlib import Path

# 3. Third-party packages
import httpx
import pydantic
from fastapi import FastAPI, HTTPException
from sqlalchemy import Column, Integer, String

# 4. Internal / project modules
from myapp.config import Settings
from myapp.database import get_session
from myapp.models import User

# 5. Relative / sibling imports
from .exceptions import NotFoundError
from .schemas import UserCreate, UserResponse
```

**Critical Python rules:**
- `from __future__ import annotations` is always the very first import. No exceptions.
- `import os` (module import) vs `from os import path` (name import): prefer module imports for standard library to keep the namespace explicit. `os.path.join()` is clearer about origin than `path.join()`.
- `from module import *` is banned. It pollutes the namespace, makes it impossible to trace where a name came from, and breaks static analysis.
- Use `__all__` in `__init__.py` to declare the public API explicitly. Every name in `__all__` must be deliberately chosen.
- Enforce with `ruff` rule `I` (isort-compatible) or standalone `isort` with `profile = "black"`.

## TypeScript

TypeScript imports have more variety (node builtins, npm packages, workspace packages, path aliases, relative paths) but the same grouping principle applies.

**Grouping order:**
```typescript
// 1. Node built-in modules
import fs from "node:fs";
import path from "node:path";

// 2. External packages (npm)
import express from "express";
import { z } from "zod";

// 3. Organization-scoped packages
import { logger } from "@myorg/logger";
import { validateRequest } from "@myorg/middleware";

// 4. Internal path aliases (@/ or ~/)
import { db } from "@/database";
import { UserModel } from "@/models/user";
import { config } from "@/config";

// 5. Relative imports
import { NotFoundError } from "./errors";
import { userSchema } from "./schemas";
import type { UserCreateInput } from "./types";
```

**Critical TypeScript rules:**
- Node builtins use the `node:` prefix: `import fs from "node:fs"`, not `import fs from "fs"`. The prefix eliminates ambiguity with npm packages that shadow built-in names.
- `type` imports use `import type { ... }` — this is not optional when `verbatimModuleSyntax` is enabled, and it signals to the reader (and bundler) that the import is erased at runtime.
- Barrel imports (`import { everything } from "./index"`) are acceptable for re-export modules but dangerous when they pull in large dependency trees. If your barrel import causes circular dependencies or bloated bundles, import from the specific file.
- Enforce with ESLint `import/order` rule or `eslint-plugin-simple-import-sort`.

## Go

Go's import conventions are the strictest and the best-tooled. `goimports` handles formatting automatically, but you must still structure imports correctly for readability.

**Grouping order:**
```go
import (
	// 1. Standard library
	"context"
	"fmt"
	"net/http"
	"time"

	// 2. External packages
	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5"
	"go.uber.org/zap"

	// 3. Internal packages
	"myapp/internal/config"
	"myapp/internal/database"
	"myapp/internal/models"
)
```

**Critical Go rules:**
- Go enforces unused imports at the compiler level. The code does not compile. This is the correct behavior.
- Use `goimports` (or `gofumpt` which includes it) to auto-format. But verify it groups correctly — some versions do not separate internal from external.
- Dot imports (`import . "testing"`) are banned outside of test files using frameworks that require them (and even then, use sparingly).
- Blank imports (`import _ "database/sql"`) are only acceptable for side-effect registration (e.g., database drivers). Always add a comment explaining why: `import _ "github.com/lib/pq" // register PostgreSQL driver`.
- Named imports are for conflict resolution only: `import pg "github.com/jackc/pgx/v5"` when two packages have the same name.

## Inline and Lazy Imports

Inline imports (importing inside a function instead of at the top of the file) are a code smell by default. They break the "table of contents" contract — the reader cannot see all dependencies at a glance.

**Acceptable ONLY in these cases:**

1. **Documented circular dependency.** Two modules that must reference each other, where a top-level import creates a cycle. The inline import breaks the cycle. Always add a comment:
   ```python
   def get_user_orders(user_id: str) -> list:
       # Inline import to break circular dependency: models -> services -> models
       from myapp.services.orders import OrderService
       return OrderService.find_by_user(user_id)
   ```

2. **Conditional heavy import.** A module that is expensive to load (e.g., ML model, large data file) and only needed in a rarely-executed code path:
   ```python
   def generate_report():
       # Lazy import: pandas is only needed for reporting, not on every request
       import pandas as pd
       ...
   ```

3. **Optional dependency.** A feature that works with or without a package:
   ```python
   try:
       import orjson as json  # Faster JSON if available
   except ImportError:
       import json
   ```

In all three cases, the comment explaining WHY is mandatory. An inline import without an explanation is a violation.

## Star Imports and Wildcards

`from module import *` is banned. In every language. Without exception.

**Why:**
- The reader cannot determine where any name came from without running the code or using an IDE
- Two star imports with overlapping names silently shadow each other
- Static analysis tools cannot verify usage
- Adding a new export to the source module can silently break the importing module

```python
# BAD — where does Request come from? Flask? Django? A local module?
from flask import *
from myapp.models import *

# GOOD — every dependency is traceable
from flask import Flask, Request, jsonify
from myapp.models import User, Order
```

```typescript
// BAD
export * from "./models";
export * from "./utils";
// If models and utils both export "validate", which one wins?

// GOOD — explicit re-exports
export { User, Order } from "./models";
export { formatDate, parseId } from "./utils";
```

## Re-Exports

Centralize public APIs through index files, but make them explicit.

```python
# myapp/models/__init__.py
from .user import User
from .order import Order
from .product import Product

__all__ = ["Order", "Product", "User"]  # Alphabetized. Always.
```

```typescript
// models/index.ts
export { Order } from "./order";
export { Product } from "./product";
export { User } from "./user";
// Alphabetized. Explicit. No star re-exports.
```

## Unused Imports

Delete them. Immediately. Not after the feature is done. Not when the linter runs. Now.

An unused import is:
- A lie in the table of contents
- A false dependency that confuses refactoring tools
- A potential source of circular dependency issues
- Clutter that trains readers to ignore the import block

"But I might need it later" is not a reason. Version control exists. Import it again when you need it. The 3 seconds of re-typing are cheaper than the permanent tax of a false dependency.

## Examples

Working implementations in `examples/`:
- **`examples/import-ordering.md`** — Multi-language examples (Python, TypeScript, Go) showing properly organized imports with correct grouping, separation, alphabetization, and common violations fixed.

## Review Checklist

When writing or reviewing import blocks:

- [ ] Imports are grouped by origin: stdlib, third-party, internal, relative
- [ ] Exactly one blank line separates each group
- [ ] Imports are alphabetized within each group
- [ ] No unused imports exist in the file
- [ ] No star/wildcard imports (`from x import *`, `export * from`)
- [ ] No inline imports without a comment explaining the reason (circular dep, conditional heavy import, optional dep)
- [ ] Python: `from __future__` is the very first import if present
- [ ] TypeScript: Node builtins use the `node:` prefix; type-only imports use `import type`
- [ ] Go: blank imports (`import _`) have a comment explaining the side effect
- [ ] Re-exports are centralized in `__init__.py` / `index.ts` with explicit names, not star exports
- [ ] `__all__` (Python) and `export` statements are alphabetized
- [ ] Import style is consistent across every file in the project — if one file groups and sorts, all files group and sort
