# Casing Conventions

Comprehensive examples showing correct casing conventions in Python, TypeScript, and Go. Each example demonstrates the full range of identifier types: variables, functions, classes/structs, constants, file names, and acronym handling.

## Python: Complete Module Example

```python
# file: user_authentication.py (snake_case file name)

"""User authentication module handling login, token refresh, and session management."""

from datetime import datetime, timedelta
from enum import Enum

# --- Constants: UPPER_SNAKE_CASE ---

MAX_LOGIN_ATTEMPTS = 5
DEFAULT_SESSION_DURATION_SECONDS = 3600
BCRYPT_COST_FACTOR = 12
AUTH_COOKIE_NAME = "session_token"


# --- Enums: PascalCase class, UPPER_SNAKE_CASE members ---

class AuthProvider(str, Enum):
    EMAIL_PASSWORD = "email_password"
    GOOGLE_OAUTH = "google_oauth"
    GITHUB_OAUTH = "github_oauth"
    SAML_SSO = "saml_sso"


class SessionStatus(str, Enum):
    ACTIVE = "active"
    EXPIRED = "expired"
    REVOKED = "revoked"


# --- Classes: PascalCase ---

class HttpClient:                       # Acronym: Http, not HTTP
    """Wraps HTTP calls with retry and timeout logic."""

    def __init__(self, base_url: str, timeout_seconds: int = 30):
        self.base_url = base_url        # snake_case attributes
        self.timeout_seconds = timeout_seconds
        self._request_count = 0         # private: leading underscore + snake_case

    def fetch_json(self, endpoint: str) -> dict:
        """Fetch JSON from the given endpoint."""
        self._request_count += 1
        # implementation ...


class UserSession:
    """Represents an authenticated user session."""

    def __init__(
        self,
        session_id: str,                # snake_case parameters
        user_id: str,
        auth_provider: AuthProvider,
        ip_address: str,
    ):
        self.session_id = session_id
        self.user_id = user_id
        self.auth_provider = auth_provider
        self.ip_address = ip_address
        self.created_at = datetime.utcnow()
        self.expires_at = self.created_at + timedelta(
            seconds=DEFAULT_SESSION_DURATION_SECONDS
        )
        self.is_active = True           # boolean: snake_case

    def has_expired(self) -> bool:      # method: snake_case
        return datetime.utcnow() > self.expires_at

    def revoke_session(self) -> None:   # method: snake_case, verb + noun
        self.is_active = False


# --- Type aliases: PascalCase ---

UserId = str
SessionToken = str
LoginAttemptCount = int


# --- Functions: snake_case ---

def validate_login_credentials(
    email: str,                         # snake_case parameters
    password_hash: str,
    stored_hash: str,
) -> bool:
    """Verify the provided password against the stored hash."""
    return compare_hashes(password_hash, stored_hash)


def create_session_for_user(
    user_id: UserId,
    auth_provider: AuthProvider,
    client_ip_address: str,
) -> UserSession:
    """Create and persist a new authenticated session."""
    session = UserSession(
        session_id=generate_session_id(),
        user_id=user_id,
        auth_provider=auth_provider,
        ip_address=client_ip_address,
    )
    return session


def count_failed_login_attempts(user_id: UserId) -> LoginAttemptCount:
    """Return the number of failed logins in the current lockout window."""
    # implementation ...
    pass
```

## TypeScript: Complete Module Example

```typescript
// file: user-authentication.ts (kebab-case file name)

// --- Constants: UPPER_SNAKE_CASE ---

const MAX_LOGIN_ATTEMPTS = 5;
const DEFAULT_SESSION_DURATION_MS = 3_600_000;
const BCRYPT_COST_FACTOR = 12;
const AUTH_COOKIE_NAME = "session_token";

// --- Enums: PascalCase name, PascalCase members ---

enum AuthProvider {
  EmailPassword = "email_password",
  GoogleOauth = "google_oauth",       // Acronym: Oauth, not OAuth
  GithubOauth = "github_oauth",
  SamlSso = "saml_sso",              // Acronym: Sso, not SSO
}

enum SessionStatus {
  Active = "active",
  Expired = "expired",
  Revoked = "revoked",
}

// --- Interfaces and Types: PascalCase ---

interface UserSession {
  sessionId: string;                   // camelCase fields
  userId: string;
  authProvider: AuthProvider;
  ipAddress: string;                   // Acronym in camelCase: ip, not IP
  createdAt: Date;
  expiresAt: Date;
  isActive: boolean;
}

interface LoginCredentials {
  email: string;
  passwordHash: string;
}

type UserId = string;                  // PascalCase type alias
type SessionToken = string;
type LoginAttemptCount = number;

// --- Classes: PascalCase ---

class HttpClient {                     // Acronym: Http, not HTTP
  private baseUrl: string;             // camelCase private fields
  private timeoutMs: number;
  private requestCount: number;

  constructor(baseUrl: string, timeoutMs: number = 30_000) {
    this.baseUrl = baseUrl;
    this.timeoutMs = timeoutMs;
    this.requestCount = 0;
  }

  async fetchJson(endpoint: string): Promise<unknown> {  // camelCase methods
    this.requestCount += 1;
    // implementation ...
  }
}

class SessionManager {
  private activeSessions: Map<string, UserSession>;

  constructor() {
    this.activeSessions = new Map();
  }

  createSessionForUser(                // camelCase method
    userId: UserId,                    // camelCase parameters
    authProvider: AuthProvider,
    clientIpAddress: string,
  ): UserSession {
    const session: UserSession = {
      sessionId: generateSessionId(),
      userId,
      authProvider,
      ipAddress: clientIpAddress,
      createdAt: new Date(),
      expiresAt: new Date(Date.now() + DEFAULT_SESSION_DURATION_MS),
      isActive: true,
    };
    this.activeSessions.set(session.sessionId, session);
    return session;
  }

  hasSessionExpired(sessionId: string): boolean {  // camelCase method
    const session = this.activeSessions.get(sessionId);
    if (!session) return true;
    return new Date() > session.expiresAt;
  }

  revokeSession(sessionId: string): void {
    const session = this.activeSessions.get(sessionId);
    if (session) {
      session.isActive = false;
    }
  }
}

// --- Functions: camelCase ---

function validateLoginCredentials(
  email: string,                       // camelCase parameters
  passwordHash: string,
  storedHash: string,
): boolean {
  return compareHashes(passwordHash, storedHash);
}

function countFailedLoginAttempts(userId: UserId): LoginAttemptCount {
  // implementation ...
  return 0;
}

// --- Cross-boundary mapping (API snake_case -> internal camelCase) ---

interface ApiUserResponse {
  user_id: string;
  first_name: string;
  last_name: string;
  created_at: string;
  is_active: boolean;
}

interface User {
  userId: string;
  firstName: string;
  lastName: string;
  createdAt: Date;
  isActive: boolean;
}

function mapApiResponseToUser(apiResponse: ApiUserResponse): User {
  return {
    userId: apiResponse.user_id,
    firstName: apiResponse.first_name,
    lastName: apiResponse.last_name,
    createdAt: new Date(apiResponse.created_at),
    isActive: apiResponse.is_active,
  };
}
```

## TypeScript React Component Example

```tsx
// file: UserProfileCard.tsx (PascalCase for React component files)

import { useState, useEffect } from "react";

// --- Constants: UPPER_SNAKE_CASE ---

const MAX_BIO_LENGTH = 280;
const AVATAR_PLACEHOLDER_URL = "/images/default-avatar.png";

// --- Props interface: PascalCase ---

interface UserProfileCardProps {
  userId: string;                      // camelCase fields
  isEditable: boolean;
  onProfileUpdate: (profile: UserProfile) => void;  // camelCase callback
}

interface UserProfile {
  userId: string;
  displayName: string;
  avatarUrl: string;                   // Acronym: Url, not URL
  bioText: string;
  isVerified: boolean;
}

// --- Component: PascalCase ---

function UserProfileCard({
  userId,                              // camelCase destructured props
  isEditable,
  onProfileUpdate,
}: UserProfileCardProps) {
  // --- Hooks: camelCase with "use" prefix ---
  const [userProfile, setUserProfile] = useState<UserProfile | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [hasUnsavedChanges, setHasUnsavedChanges] = useState(false);

  useEffect(() => {
    fetchUserProfile(userId).then((profile) => {
      setUserProfile(profile);
      setIsLoading(false);
    });
  }, [userId]);

  // --- Event handlers: camelCase, verb + noun ---

  function handleBioChange(newBioText: string): void {
    if (newBioText.length > MAX_BIO_LENGTH) return;
    setHasUnsavedChanges(true);
    setUserProfile((prev) =>
      prev ? { ...prev, bioText: newBioText } : null
    );
  }

  function handleSaveProfile(): void {
    if (!userProfile) return;
    onProfileUpdate(userProfile);
    setHasUnsavedChanges(false);
  }

  if (isLoading) return <ProfileSkeleton />;
  if (!userProfile) return <ProfileNotFound />;

  return (
    <div className="user-profile-card">   {/* kebab-case CSS classes */}
      <img
        className="profile-avatar"
        src={userProfile.avatarUrl || AVATAR_PLACEHOLDER_URL}
        alt={`${userProfile.displayName} avatar`}
      />
      <h2 className="profile-display-name">{userProfile.displayName}</h2>
      {userProfile.isVerified && <VerifiedBadge />}
      <p className="profile-bio">{userProfile.bioText}</p>
      {isEditable && hasUnsavedChanges && (
        <button onClick={handleSaveProfile}>Save Changes</button>
      )}
    </div>
  );
}

export default UserProfileCard;
```

## Go: Complete Package Example

```go
// file: user_authentication.go (snake_case file name)

package auth // lowercase, single word, no underscores

import (
    "crypto/rand"
    "encoding/base64"
    "fmt"
    "net/http"
    "time"
)

// --- Constants: PascalCase (exported), camelCase (unexported) ---

const MaxLoginAttempts = 5                    // Exported: PascalCase
const DefaultSessionDuration = time.Hour      // Exported: PascalCase
const bcryptCostFactor = 12                   // Unexported: camelCase
const authCookieName = "session_token"        // Unexported: camelCase

// --- Enums (Go uses const + iota or string constants) ---

type AuthProvider string

const (
    AuthProviderEmailPassword AuthProvider = "email_password"
    AuthProviderGoogleOAuth   AuthProvider = "google_oauth"
    AuthProviderGitHubOAuth   AuthProvider = "github_oauth"
    AuthProviderSAMLSSO       AuthProvider = "saml_sso"
)

type SessionStatus string

const (
    SessionStatusActive  SessionStatus = "active"
    SessionStatusExpired SessionStatus = "expired"
    SessionStatusRevoked SessionStatus = "revoked"
)

// --- Interfaces: PascalCase, often -er suffix ---

type SessionStore interface {
    SaveSession(session *UserSession) error
    FindSessionByID(sessionID string) (*UserSession, error)  // ID uppercase (Go convention)
    DeleteSessionByID(sessionID string) error
}

// --- Structs: PascalCase (exported), camelCase (unexported fields) ---

// UserSession represents an authenticated user session.
type UserSession struct {
    SessionID    string        `json:"session_id" db:"session_id"`    // ID uppercase
    UserID       string        `json:"user_id" db:"user_id"`          // ID uppercase
    AuthProvider AuthProvider  `json:"auth_provider" db:"auth_provider"`
    IPAddress    string        `json:"ip_address" db:"ip_address"`    // IP uppercase
    CreatedAt    time.Time     `json:"created_at" db:"created_at"`
    ExpiresAt    time.Time     `json:"expires_at" db:"expires_at"`
    IsActive     bool          `json:"is_active" db:"is_active"`
}

// HTTPClient wraps HTTP calls with retry and timeout logic.
type HTTPClient struct {                      // HTTP uppercase (Go convention)
    BaseURL      string                       // URL uppercase (Go convention)
    TimeoutMS    int                          // Exported
    requestCount int                          // unexported: camelCase
}

// loginAttempt is unexported — internal tracking only.
type loginAttempt struct {                    // unexported: camelCase
    userID    string                          // unexported field: camelCase, ID uppercase
    ipAddress string
    timestamp time.Time
    succeeded bool
}

// --- Methods: receiver is 1-2 letter abbreviation ---

// HasExpired checks whether the session has passed its expiration time.
func (s *UserSession) HasExpired() bool {     // receiver: s for UserSession
    return time.Now().After(s.ExpiresAt)
}

// Revoke marks the session as inactive.
func (s *UserSession) Revoke() {
    s.IsActive = false
}

// FetchJSON performs a GET request and decodes the JSON response.
func (c *HTTPClient) FetchJSON(endpoint string, target interface{}) error {
    c.requestCount++
    url := fmt.Sprintf("%s%s", c.BaseURL, endpoint)
    // implementation ...
    _ = url
    return nil
}

// --- Functions: PascalCase (exported), camelCase (unexported) ---

// CreateSessionForUser creates and persists a new authenticated session.
func CreateSessionForUser(
    userID string,                            // ID uppercase
    provider AuthProvider,
    clientIPAddress string,                   // IP uppercase
    store SessionStore,
) (*UserSession, error) {
    sessionID, err := generateSessionID()     // unexported helper: camelCase
    if err != nil {
        return nil, fmt.Errorf("generate session ID: %w", err)
    }

    session := &UserSession{
        SessionID:    sessionID,
        UserID:       userID,
        AuthProvider: provider,
        IPAddress:    clientIPAddress,
        CreatedAt:    time.Now(),
        ExpiresAt:    time.Now().Add(DefaultSessionDuration),
        IsActive:     true,
    }

    if err := store.SaveSession(session); err != nil {
        return nil, fmt.Errorf("save session: %w", err)
    }

    return session, nil
}

// ValidateLoginCredentials checks the provided password against the stored hash.
func ValidateLoginCredentials(email, passwordHash, storedHash string) bool {
    return compareHashes(passwordHash, storedHash)
}

// generateSessionID creates a cryptographically random session identifier.
func generateSessionID() (string, error) {    // unexported: camelCase
    bytes := make([]byte, 32)
    if _, err := rand.Read(bytes); err != nil {
        return "", fmt.Errorf("read random bytes: %w", err)
    }
    return base64.URLEncoding.EncodeToString(bytes), nil
}

// compareHashes is an unexported helper.
func compareHashes(a, b string) bool {        // unexported: camelCase
    // implementation ...
    return a == b
}
```

## Acronym Handling Side-by-Side

```
                    Python          TypeScript      Go
─────────────────────────────────────────────────────────────
HTTP client class   HttpClient      HttpClient      HTTPClient
JSON parser         JsonParser      JsonParser      JSONParser
URL validator       UrlValidator    UrlValidator     URLValidator
User ID field       user_id         userId          UserID
API key constant    API_KEY         API_KEY         APIKey (exported)
IP address var      ip_address      ipAddress       ipAddress (unexported)
SQL database        SqlDatabase     SqlDatabase     SQLDatabase
HTML template       HtmlTemplate    HtmlTemplate    HTMLTemplate
```

## Key Points

- **One convention per language, applied everywhere.** Python: `snake_case`. TypeScript: `camelCase`. Go: visibility-based PascalCase/camelCase. No exceptions.
- **Mixed casing in one file is a defect.** Treat it with the same urgency as a failing test. Fix it immediately.
- **Acronyms follow language rules.** Python and TypeScript treat them as words (`HttpClient`). Go keeps them uppercase (`HTTPClient`). Do not cross-pollinate.
- **Map at boundaries.** API sends `snake_case`, frontend uses `camelCase` -- convert at the edge, never let foreign casing leak into application code.
- **File names are part of the convention.** `snake_case.py`, `kebab-case.ts`, `PascalCase.tsx`, `snake_case.go`. No mixing.
- **No `I` prefix on TypeScript interfaces.** `UserProfile`, not `IUserProfile`.
- **Go: zero underscores in identifiers.** The only underscores in Go are in file names and test function names.
