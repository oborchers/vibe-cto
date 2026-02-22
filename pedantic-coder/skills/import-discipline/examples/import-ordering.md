# Import Ordering Patterns

Multi-language examples showing properly organized imports. Every file's import block should be a clean, scannable table of contents: grouped by origin, separated by blank lines, alphabetized within groups.

## Python

### BAD — Disordered, Ungrouped

```python
from myapp.models import User
import os
from fastapi import FastAPI
from .schemas import UserCreate
import httpx
from pathlib import Path
from myapp.config import Settings
from collections import defaultdict
from sqlalchemy import Column, Integer, String
from .exceptions import NotFoundError
import sys
from pydantic import BaseModel
from myapp.database import get_session
```

Problems: no grouping, no blank lines between groups, no alphabetical order. The reader has to scan every line to understand dependencies.

### GOOD — Properly Grouped and Sorted

```python
import os
import sys
from collections import defaultdict
from pathlib import Path

import httpx
from fastapi import FastAPI
from pydantic import BaseModel
from sqlalchemy import Column, Integer, String

from myapp.config import Settings
from myapp.database import get_session
from myapp.models import User

from .exceptions import NotFoundError
from .schemas import UserCreate
```

### BAD — Star Imports and Unused Imports

```python
from os import *            # star import — namespace pollution
from typing import *        # star import — where does Optional come from?
import json                 # unused — delete it
import logging              # unused — delete it
from flask import Flask, request, jsonify, abort, redirect, url_for, session
# Only Flask and request are used in this file. The rest are dead weight.

from myapp.utils import *   # star import — which names come from here?
```

### GOOD — Explicit and Minimal

```python
from os import getcwd

from flask import Flask, request

from myapp.utils import format_date, generate_id
```

### BAD — Inline Import Without Explanation

```python
def create_report(data: list[dict]) -> bytes:
    import pandas as pd    # Why is this inline? No comment. Violation.
    df = pd.DataFrame(data)
    return df.to_csv().encode()

def get_user_orders(user_id: str):
    from myapp.services import OrderService   # Why inline? No explanation.
    return OrderService.find_by_user(user_id)
```

### GOOD — Inline Import With Mandatory Explanation

```python
def create_report(data: list[dict]) -> bytes:
    # Lazy import: pandas adds ~200ms startup time and is only needed for reporting
    import pandas as pd

    df = pd.DataFrame(data)
    return df.to_csv().encode()

def get_user_orders(user_id: str):
    # Inline import to break circular dependency: models -> services -> models
    from myapp.services import OrderService

    return OrderService.find_by_user(user_id)
```

### BAD — __init__.py Re-Export

```python
# myapp/models/__init__.py
from .user import *
from .order import *
from .product import *
# What is exported? Nobody knows without reading three files.
```

### GOOD — __init__.py Re-Export

```python
# myapp/models/__init__.py
from .order import Order, OrderItem
from .product import Product, ProductVariant
from .user import User, UserProfile

__all__ = [
    "Order",
    "OrderItem",
    "Product",
    "ProductVariant",
    "User",
    "UserProfile",
]
```

### Complete Python File — Correct Import Order

```python
"""User service module.

Handles user creation, retrieval, and permission checks.
"""

from __future__ import annotations

import hashlib
import logging
from datetime import datetime, timezone
from typing import TYPE_CHECKING
from uuid import uuid4

import httpx
from fastapi import Depends, HTTPException
from pydantic import EmailStr
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from myapp.config import settings
from myapp.database import get_session
from myapp.models import User
from myapp.permissions import has_permission

from .schemas import UserCreate, UserResponse, UserUpdate

if TYPE_CHECKING:
    from myapp.services.billing import BillingService

logger = logging.getLogger(__name__)
```

## TypeScript

### BAD — Disordered, Ungrouped

```typescript
import { UserModel } from "@/models/user";
import express from "express";
import { z } from "zod";
import { NotFoundError } from "./errors";
import fs from "node:fs";
import { logger } from "@myorg/logger";
import { db } from "@/database";
import path from "node:path";
import { userSchema } from "./schemas";
import { validateRequest } from "@myorg/middleware";
import { config } from "@/config";
```

### GOOD — Properly Grouped and Sorted

```typescript
import fs from "node:fs";
import path from "node:path";

import express from "express";
import { z } from "zod";

import { logger } from "@myorg/logger";
import { validateRequest } from "@myorg/middleware";

import { config } from "@/config";
import { db } from "@/database";
import { UserModel } from "@/models/user";

import { NotFoundError } from "./errors";
import { userSchema } from "./schemas";
```

### BAD — Missing Type Imports and Star Re-Exports

```typescript
// Importing types as values — bloats bundle, confuses reader
import { User, UserService, CreateUserInput } from "./user";
// CreateUserInput is a type, but imported as a value

// Star re-export — opaque, conflict-prone
export * from "./models";
export * from "./utils";
export * from "./errors";
```

### GOOD — Explicit Type Imports and Named Re-Exports

```typescript
import { UserService } from "./user";
import type { CreateUserInput, User } from "./user";

// Explicit re-exports — every name is visible and intentional
export { AppError, NotFoundError, ValidationError } from "./errors";
export { Order, Product, User } from "./models";
export { formatDate, generateId, parseInput } from "./utils";
```

### Complete TypeScript File — Correct Import Order

```typescript
/**
 * User router module.
 * Handles all /users endpoints.
 */

import crypto from "node:crypto";

import { Router } from "express";
import { z } from "zod";

import { authMiddleware } from "@myorg/auth";
import { logger } from "@myorg/logger";

import { config } from "@/config";
import { db } from "@/database";
import { UserModel } from "@/models/user";
import { hashPassword } from "@/utils/crypto";

import { NotFoundError, ValidationError } from "./errors";
import { createUserSchema, updateUserSchema } from "./schemas";
import type { CreateUserInput, UpdateUserInput, UserResponse } from "./types";

const router = Router();
```

## Go

### BAD — Ungrouped Imports

```go
import (
	"myapp/internal/models"
	"fmt"
	"github.com/gin-gonic/gin"
	"context"
	"myapp/internal/database"
	"go.uber.org/zap"
	"net/http"
	"github.com/jackc/pgx/v5"
	"time"
	"myapp/internal/config"
)
```

### GOOD — Properly Grouped and Sorted

```go
import (
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5"
	"go.uber.org/zap"

	"myapp/internal/config"
	"myapp/internal/database"
	"myapp/internal/models"
)
```

### BAD — Dot Import and Unexplained Blank Import

```go
import (
	. "github.com/onsi/gomega"     // dot import in production code — banned
	_ "github.com/lib/pq"          // why? no comment
	mydb "database/sql"             // unnecessary alias
)
```

### GOOD — Explained Blank Import, No Dot Imports

```go
import (
	"database/sql"

	_ "github.com/lib/pq" // register PostgreSQL driver for database/sql
)
```

### Complete Go File — Correct Import Order

```go
// Package users handles user-related HTTP handlers and business logic.
package users

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"go.uber.org/zap"
	"golang.org/x/crypto/bcrypt"

	"myapp/internal/config"
	"myapp/internal/database"
	"myapp/internal/middleware"
	"myapp/internal/models"
)

// Handler holds dependencies for user HTTP handlers.
type Handler struct {
	db     *database.Client
	logger *zap.Logger
	config *config.Config
}
```

## Key Points

- **Group by origin, separate with blank lines, alphabetize within groups.** This is the entire rule. Every language applies it the same way.
- **One blank line between groups. Not two. Not zero.** The blank line is the visual separator. More than one is noise. Zero is a wall of text.
- **Delete unused imports immediately.** They are lies in the table of contents. "Might need later" is not a reason to keep them.
- **No star imports, ever.** They destroy traceability. Import exactly what you use.
- **Inline imports require a comment.** If the import is not at the top, the reader deserves to know why. No comment, no inline import.
- **Re-exports are explicit.** `__all__` and `export` statements list every name. Star re-exports are just star imports with extra steps.
