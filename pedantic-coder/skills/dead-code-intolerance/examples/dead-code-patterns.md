# Dead Code Patterns: Identification and Removal

Multi-language examples showing the most common forms of dead code and their clean replacements. Every "before" is code that should not exist. Every "after" is what the file should look like once the dead code is removed.

## Python: The Full Cleanup

### Before -- A file riddled with dead code

```python
import os
import sys  # unused
import json  # unused
from datetime import datetime, timedelta  # timedelta unused
from typing import Optional, List  # List unused
from collections import OrderedDict  # unused -- switched to regular dict in 3.7+

# Old database connection string
# DB_URL = "postgresql://localhost:5432/myapp_dev"

# TODO: add caching here (added 2024-01-15)
# FIXME: this is slow for large datasets

# Was previously using SQLAlchemy, switched to asyncpg in Q2
POOL_SIZE = 10


class UserService:
    """Service for user operations."""

    # Keeping this in case we need to rollback the auth change
    # def authenticate_legacy(self, username: str, password: str) -> bool:
    #     hashed = hashlib.sha256(password.encode()).hexdigest()
    #     return self.db.check_password(username, hashed)

    def authenticate(self, username: str, password: str) -> bool:
        """Authenticate a user with bcrypt."""
        user = self.db.get_user(username)
        if user is None:
            return False
        return bcrypt.checkpw(password.encode(), user.password_hash)

    def get_user(self, user_id: int) -> Optional[dict]:
        """Fetch a user by ID."""
        return self.db.fetch_user(user_id)

    # This was for the old admin panel
    # def get_admin_users(self) -> List[dict]:
    #     return self.db.query("SELECT * FROM users WHERE role = 'admin'")

    def deactivate_user(self, user_id: int) -> None:
        """Deactivate a user account."""
        self.db.update_user(user_id, is_active=False)

    def _format_legacy_response(self, user: dict) -> dict:
        """Format user data for the v1 API."""
        # Nothing calls this anymore -- v1 was decommissioned
        return {
            "id": user["id"],
            "name": f"{user['first_name']} {user['last_name']}",
        }


def process_users(users: list) -> list:
    """Process a list of users."""
    results = []
    for user in users:
        if False:  # disabled for now
            send_notification(user)
        results.append(user)
    return results


# Feature flag: new_onboarding -- rolled out 100% on 2024-03-01
def get_onboarding_flow(user):
    if feature_flags.is_enabled("new_onboarding"):
        return new_onboarding(user)
    else:
        return legacy_onboarding(user)  # dead path
```

### After -- Clean, living code only

```python
import os
from datetime import datetime

POOL_SIZE = 10


class UserService:
    """Service for user operations."""

    def authenticate(self, username: str, password: str) -> bool:
        """Authenticate a user with bcrypt."""
        user = self.db.get_user(username)
        if user is None:
            return False
        return bcrypt.checkpw(password.encode(), user.password_hash)

    def get_user(self, user_id: int) -> dict | None:
        """Fetch a user by ID."""
        return self.db.fetch_user(user_id)

    def deactivate_user(self, user_id: int) -> None:
        """Deactivate a user account."""
        self.db.update_user(user_id, is_active=False)


def process_users(users: list) -> list:
    """Process a list of users."""
    return list(users)


def get_onboarding_flow(user):
    return new_onboarding(user)
```

**What was removed:**
- `sys`, `json`, `timedelta`, `List`, `OrderedDict` -- unused imports
- Commented-out `DB_URL` -- historical artifact
- TODO/FIXME comments without linked issues
- Historical comment about SQLAlchemy migration
- Commented-out `authenticate_legacy` method
- Commented-out `get_admin_users` method
- `_format_legacy_response` -- unused method (nothing calls it)
- `if False:` unreachable branch
- Feature flag check for `new_onboarding` -- fully rolled out, old path deleted

## TypeScript: The Full Cleanup

### Before -- Dead code in a React component

```typescript
import React, { useState, useEffect, useCallback, useMemo, useRef } from "react";
import { format, parseISO, addDays } from "date-fns";  // addDays unused
import { clsx } from "clsx";  // unused
import { z } from "zod";
// import { legacy_validate } from "./old-validators";  // commented import

// Old API endpoint
// const API_URL = "https://api-v1.example.com";

const API_URL = "https://api.example.com";

// TODO: add pagination support
// FIXME: memory leak on unmount (added 6 months ago)

interface User {
  id: string;
  name: string;
  email: string;
  // role: string;  // removed in v3 migration
}

// This was for the legacy dashboard
// interface LegacyUser {
//   userId: number;
//   fullName: string;
// }

const userSchema = z.object({
  id: z.string(),
  name: z.string(),
  email: z.string().email(),
});

// Was previously used for SSR hydration
// function hydrateUserData(raw: unknown): User {
//   return userSchema.parse(raw);
// }

export function UserList() {
  const [users, setUsers] = useState<User[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  // const [error, setError] = useState<string | null>(null);  // unused state
  const mountedRef = useRef(true);  // unused ref

  useEffect(() => {
    fetchUsers();
  }, []);

  async function fetchUsers() {
    setIsLoading(true);
    const response = await fetch(`${API_URL}/users`);
    const data = await response.json();
    setUsers(data);
    setIsLoading(false);
  }

  // Keeping for when we add search
  // function filterUsers(query: string): User[] {
  //   return users.filter(u =>
  //     u.name.toLowerCase().includes(query.toLowerCase())
  //   );
  // }

  if (isLoading) return <div>Loading...</div>;

  return (
    <ul>
      {users.map((user) => (
        <li key={user.id}>{user.name}</li>
      ))}
    </ul>
  );
}

// Not exported, not used internally
function formatUserForExport(user: User): string {
  return `${user.name} <${user.email}>`;
}
```

### After -- Clean component

```typescript
import React, { useState, useEffect } from "react";
import { z } from "zod";

const API_URL = "https://api.example.com";

interface User {
  id: string;
  name: string;
  email: string;
}

const userSchema = z.object({
  id: z.string(),
  name: z.string(),
  email: z.string().email(),
});

export function UserList() {
  const [users, setUsers] = useState<User[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    fetchUsers();
  }, []);

  async function fetchUsers() {
    setIsLoading(true);
    const response = await fetch(`${API_URL}/users`);
    const data = await response.json();
    setUsers(data);
    setIsLoading(false);
  }

  if (isLoading) return <div>Loading...</div>;

  return (
    <ul>
      {users.map((user) => (
        <li key={user.id}>{user.name}</li>
      ))}
    </ul>
  );
}
```

**What was removed:**
- `useCallback`, `useMemo`, `useRef`, `addDays`, `clsx`, `format`, `parseISO` -- unused imports
- Commented-out `legacy_validate` import
- Commented-out old `API_URL`
- TODO/FIXME without linked issues
- Commented-out `role` field with historical note
- Commented-out `LegacyUser` interface
- Commented-out `hydrateUserData` function
- Unused `error` state and `mountedRef`
- Commented-out `filterUsers` function
- `formatUserForExport` -- not exported, not called

## Go: The Full Cleanup

### Before -- Dead code in a Go service

```go
package user

import (
	"context"
	"encoding/xml"  // unused -- removed XML support in v2
	"fmt"
	"log"
	"net/http"
	"sync"  // unused
	"time"
)

// Old configuration format
// const defaultTimeout = 30 * time.Second

const requestTimeout = 10 * time.Second

// TODO: add circuit breaker
// FIXME: handle context cancellation properly

// Was previously using a custom HTTP client
// var defaultClient = &http.Client{Timeout: 60 * time.Second}

// Service handles user operations.
type Service struct {
	baseURL string
	client  *http.Client
}

// NewService creates a new user service.
func NewService(baseURL string) *Service {
	return &Service{
		baseURL: baseURL,
		client:  &http.Client{Timeout: requestTimeout},
	}
}

// GetUser fetches a user by ID.
func (s *Service) GetUser(ctx context.Context, id string) (*User, error) {
	// Old implementation using XML
	// resp, err := s.client.Get(s.baseURL + "/users/" + id + ".xml")
	// if err != nil {
	//     return nil, err
	// }
	// var user User
	// xml.NewDecoder(resp.Body).Decode(&user)

	resp, err := s.client.Get(s.baseURL + "/users/" + id)
	if err != nil {
		return nil, fmt.Errorf("fetching user %s: %w", id, err)
	}
	defer resp.Body.Close()

	var user User
	if err := decodeJSON(resp.Body, &user); err != nil {
		return nil, fmt.Errorf("decoding user %s: %w", id, err)
	}

	return &user, nil
}

// FormatLegacyID converts old integer IDs to the new string format.
// Nothing calls this anymore -- migration completed in January.
func FormatLegacyID(id int) string {
	return fmt.Sprintf("usr_%06d", id)
}

// GetUserV1 is the old API handler.
// Keeping for backward compat -- but the v1 routes were removed 3 months ago.
func (s *Service) GetUserV1(w http.ResponseWriter, r *http.Request) {
	// ...legacy implementation...
	log.Println("v1 handler called")
}

// debugDump prints user data for debugging. Never called in production.
func debugDump(u *User) {
	if false {
		fmt.Printf("DEBUG: %+v\n", u)
	}
}

// Feature flag: new_profile_endpoint -- 100% since sprint 42
func (s *Service) GetProfile(ctx context.Context, id string) (*Profile, error) {
	if featureFlags.IsEnabled("new_profile_endpoint") {
		return s.getProfileV2(ctx, id)
	}
	return s.getProfileLegacy(ctx, id)  // dead path
}

func (s *Service) getProfileV2(ctx context.Context, id string) (*Profile, error) {
	// current implementation
	return nil, nil
}

func (s *Service) getProfileLegacy(ctx context.Context, id string) (*Profile, error) {
	// nobody reaches this
	return nil, nil
}
```

### After -- Clean service

```go
package user

import (
	"context"
	"fmt"
	"net/http"
	"time"
)

const requestTimeout = 10 * time.Second

// Service handles user operations.
type Service struct {
	baseURL string
	client  *http.Client
}

// NewService creates a new user service.
func NewService(baseURL string) *Service {
	return &Service{
		baseURL: baseURL,
		client:  &http.Client{Timeout: requestTimeout},
	}
}

// GetUser fetches a user by ID.
func (s *Service) GetUser(ctx context.Context, id string) (*User, error) {
	resp, err := s.client.Get(s.baseURL + "/users/" + id)
	if err != nil {
		return nil, fmt.Errorf("fetching user %s: %w", id, err)
	}
	defer resp.Body.Close()

	var user User
	if err := decodeJSON(resp.Body, &user); err != nil {
		return nil, fmt.Errorf("decoding user %s: %w", id, err)
	}

	return &user, nil
}

// GetProfile fetches a user's profile by ID.
func (s *Service) GetProfile(ctx context.Context, id string) (*Profile, error) {
	// implementation
	return nil, nil
}
```

**What was removed:**
- `encoding/xml`, `log`, `sync` -- unused imports
- Commented-out `defaultTimeout` constant
- TODO/FIXME without linked issues
- Commented-out old HTTP client
- Commented-out XML implementation in GetUser
- `FormatLegacyID` -- unused function (migration complete)
- `GetUserV1` -- dead handler (v1 routes removed)
- `debugDump` -- unused function with unreachable `if false` branch
- Feature flag `new_profile_endpoint` -- fully rolled out, flag check removed
- `getProfileLegacy` -- dead code path, no longer reachable

## Key Points

- Every piece of dead code was removed for a specific reason. None of it was "harmless"
- The after versions are shorter, clearer, and contain only code that actually executes
- Git preserves every line that was deleted -- nothing is lost, it is just not cluttering the working codebase
- Unused imports are the easiest dead code to catch (linters do it automatically) and the most common to ignore
- Feature flags that have been fully rolled out are the most dangerous form of dead code because they carry the illusion of being intentional