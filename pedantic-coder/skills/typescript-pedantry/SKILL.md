---
name: typescript-pedantry
description: "This skill should be used when the user is writing TypeScript code and needs guidance on TypeScript-specific pedantry: strict tsconfig settings, discriminated unions over type assertions, Zod schemas for runtime validation, barrel exports, as const assertions, ESLint strict rules, and TypeScript-specific patterns that go beyond universal principles."
version: 1.0.0
---

# TypeScript Is Not "JavaScript With Types Sprinkled On"

TypeScript has a type system powerful enough to catch entire categories of bugs at compile time. But only if you use it. `strict: true` is the bare minimum, not the finish line. `as` casts are not type safety -- they are escape hatches that undermine the entire point of using TypeScript. Zod schemas validate at runtime what TypeScript validates at compile time. Discriminated unions make impossible states unrepresentable. If your TypeScript code uses `any`, type assertions, or unchecked casts, you are writing JavaScript with extra syntax and calling it type-safe.

## Strict tsconfig: The Non-Negotiable Baseline

`strict: true` enables a bundle of checks. It is the starting point, not the goal. These additional flags catch real bugs that `strict` alone misses:

```jsonc
// tsconfig.json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noPropertyAccessFromIndexSignature": true,
    "noFallthroughCasesInSwitch": true,
    "forceConsistentCasingInFileNames": true,
    "verbatimModuleSyntax": true
  }
}
```

| Flag | What It Catches |
|------|----------------|
| `strict` | Enables `strictNullChecks`, `strictFunctionTypes`, `strictBindCallApply`, `strictPropertyInitialization`, `noImplicitAny`, `noImplicitThis`, `alwaysStrict`, `useUnknownInCatchVariables` |
| `noUncheckedIndexedAccess` | `array[0]` returns `T \| undefined`, not `T` -- forces null checks after indexing |
| `exactOptionalPropertyTypes` | `{ name?: string }` means `name` is `string \| undefined`, NOT `string \| undefined \| null` -- prevents assigning `undefined` explicitly |
| `noPropertyAccessFromIndexSignature` | Forces bracket notation for index signatures: `obj["key"]` not `obj.key` -- makes it clear the property may not exist |
| `noFallthroughCasesInSwitch` | Prevents missing `break` in switch cases |
| `forceConsistentCasingInFileNames` | Prevents `import from './User'` when the file is `user.ts` -- catches bugs on case-insensitive filesystems |
| `verbatimModuleSyntax` | Requires `import type` for type-only imports -- cleaner output, clearer intent |

**Do not weaken these.** If a library does not compile under strict mode, the library is the problem, not your config.

## Discriminated Unions Over Type Assertions

`as` is not type narrowing. It is the developer lying to the compiler. Discriminated unions make the type system work for you instead of against you.

```typescript
// BAD -- type assertion is a lie the compiler believes without verification
interface ApiResponse {
  data?: unknown;
  error?: string;
}

function handleResponse(response: ApiResponse) {
  if (response.error) {
    console.error(response.error);
    return;
  }
  // "as" tells TypeScript "trust me" -- TypeScript should never trust you
  const user = response.data as User;
  console.log(user.name); // runtime crash if data is not a User
}
```

```typescript
// GOOD -- discriminated union makes invalid states unrepresentable
type ApiResponse<T> =
  | { kind: "success"; data: T }
  | { kind: "error"; error: string; statusCode: number };

function handleResponse(response: ApiResponse<User>) {
  switch (response.kind) {
    case "success":
      // TypeScript KNOWS response.data is User here -- no assertion needed
      console.log(response.data.name);
      break;
    case "error":
      console.error(`${response.statusCode}: ${response.error}`);
      break;
  }
}
```

When you need runtime narrowing that TypeScript cannot infer, use type guard functions:

```typescript
// GOOD -- type guard with runtime check
function isUser(value: unknown): value is User {
  return (
    typeof value === "object" &&
    value !== null &&
    "id" in value &&
    "name" in value &&
    typeof (value as Record<string, unknown>).id === "string" &&
    typeof (value as Record<string, unknown>).name === "string"
  );
}

// Usage
if (isUser(data)) {
  console.log(data.name); // TypeScript knows data is User
}
```

**The rule:** `as` is banned except inside type guard functions. If you need to narrow a type, use a discriminated union or a type guard. Never use `as` to make the compiler shut up.

## Zod Schemas for Runtime Validation

TypeScript types vanish at runtime. They cannot protect you from malformed API responses, invalid user input, corrupt environment variables, or poisoned JSON. Zod fills this gap: define a schema, derive the type from it, and validate at every system boundary.

```typescript
// BAD -- trusting runtime data based on a compile-time type
interface CreateUserRequest {
  name: string;
  email: string;
  age: number;
}

app.post("/users", (req, res) => {
  // req.body is `any` at runtime -- this "type" is a lie
  const body = req.body as CreateUserRequest;
  createUser(body); // name could be undefined, age could be "twenty-five"
});
```

```typescript
// GOOD -- schema defines truth, type is derived
import { z } from "zod";

const createUserSchema = z.object({
  name: z.string().min(1).max(200),
  email: z.string().email(),
  age: z.number().int().min(0).max(150),
});

// Type is derived FROM the schema -- single source of truth
type CreateUserRequest = z.infer<typeof createUserSchema>;

app.post("/users", (req, res) => {
  const result = createUserSchema.safeParse(req.body);
  if (!result.success) {
    return res.status(400).json({ errors: result.error.flatten() });
  }
  // result.data is CreateUserRequest -- validated at runtime, typed at compile time
  createUser(result.data);
});
```

**Where to validate with Zod:**
- API request handlers (body, query params, path params)
- Environment variable loading
- External API responses
- File/JSON parsing
- Message queue consumers
- Anything that crosses a trust boundary

**The rule:** derive types from schemas (`z.infer<typeof schema>`), never the other way around. The schema is the source of truth. The type is the consequence.

## Environment Variables with Zod

```typescript
// BAD -- scattered process.env access
const port = parseInt(process.env.PORT || "3000");
const dbUrl = process.env.DATABASE_URL!; // non-null assertion -- crashes if missing

// GOOD -- validated at startup
const envSchema = z.object({
  PORT: z.coerce.number().int().min(1).max(65535).default(3000),
  DATABASE_URL: z.string().url(),
  API_KEY: z.string().min(1),
  NODE_ENV: z.enum(["development", "production", "test"]).default("development"),
});

export const env = envSchema.parse(process.env);
// env.PORT is number, env.DATABASE_URL is string -- typed and validated
```

## Barrel Exports (index.ts)

Every module gets one `index.ts` that re-exports its public API. Internal files are never imported directly from outside the module. This establishes clear module boundaries and makes refactoring internal files safe.

```
// BAD -- importing internal files directly
import { UserService } from "../users/user-service";
import { UserRepository } from "../users/user-repository";
import { hashPassword } from "../users/utils/password";
```

```
// GOOD -- importing from the module's public API
import { UserService } from "../users";
// UserRepository and hashPassword are internal -- not exported
```

```typescript
// users/index.ts -- the module's public API
export { UserService } from "./user-service";
export type { User, CreateUserInput, UpdateUserInput } from "./user-types";

// UserRepository, password utils, and internal helpers are NOT exported
// They are implementation details of this module
```

**Rules for barrel files:**
1. One `index.ts` per module directory
2. Only export what external consumers need
3. Keep barrel files lean -- exports only, no logic
4. Use `export type` for type-only exports (with `verbatimModuleSyntax`)
5. Internal files are never imported with path traversal from outside

## `as const` for Literal Types

`as const` makes TypeScript infer the narrowest possible type for a value. Use it for config objects, status maps, route definitions, and any constant where the literal values matter.

```typescript
// BAD -- TypeScript infers wide types
const HTTP_STATUS = {
  OK: 200,           // type: number
  NOT_FOUND: 404,    // type: number
  SERVER_ERROR: 500, // type: number
};

// GOOD -- TypeScript infers literal types
const HTTP_STATUS = {
  OK: 200,           // type: 200
  NOT_FOUND: 404,    // type: 404
  SERVER_ERROR: 500, // type: 500
} as const;
```

For type-checked constant objects, use `as const satisfies`:

```typescript
// GOOD -- as const satisfies: narrowest type AND type checking
interface RouteConfig {
  path: string;
  method: "GET" | "POST" | "PUT" | "DELETE";
  auth: boolean;
}

const ROUTES = {
  getUser: { path: "/users/:id", method: "GET", auth: true },
  createUser: { path: "/users", method: "POST", auth: true },
  healthCheck: { path: "/health", method: "GET", auth: false },
} as const satisfies Record<string, RouteConfig>;

// ROUTES.getUser.method is literally "GET", not string
// AND TypeScript verifies each route matches RouteConfig
```

## Template Literal Types for String Patterns

When a string follows a pattern, encode the pattern in the type system:

```typescript
// BAD -- any string is accepted
function getEnvVar(name: string): string | undefined {
  return process.env[name];
}

// GOOD -- only valid env var names accepted
type EnvVarName = `MYAPP_${string}`;

function getEnvVar(name: EnvVarName): string | undefined {
  return process.env[name];
}

getEnvVar("MYAPP_DATABASE_URL"); // OK
getEnvVar("DATABASE_URL");       // TypeScript error
```

```typescript
// Prefixed IDs
type UserId = `usr_${string}`;
type OrderId = `ord_${string}`;

function getUser(id: UserId): Promise<User> { ... }
function getOrder(id: OrderId): Promise<Order> { ... }

getUser("usr_01HXK3GJ5V"); // OK
getUser("ord_01HXK3GJ5V"); // TypeScript error -- cannot pass OrderId as UserId
```

## Never Use `any`

`any` disables the type system. It is a virus: one `any` infects every value it touches, cascading type erasure through your codebase. Use `unknown` instead and narrow.

```typescript
// BAD -- any disables all type checking
function processEvent(event: any) {
  console.log(event.name.toUpperCase()); // no error at compile time, crash at runtime
}

// GOOD -- unknown requires narrowing
function processEvent(event: unknown) {
  if (typeof event === "object" && event !== null && "name" in event) {
    const name = (event as { name: unknown }).name;
    if (typeof name === "string") {
      console.log(name.toUpperCase()); // safe
    }
  }
}

// BETTER -- use Zod for runtime validation of unknown data
const eventSchema = z.object({
  name: z.string(),
  timestamp: z.string().datetime(),
});

function processEvent(event: unknown) {
  const parsed = eventSchema.parse(event);
  console.log(parsed.name.toUpperCase()); // safe and typed
}
```

## ESLint Strict Rules

```jsonc
// eslint.config.js (flat config)
{
  "extends": [
    "@typescript-eslint/strict-type-checked",
    "@typescript-eslint/stylistic-type-checked"
  ],
  "rules": {
    "@typescript-eslint/no-explicit-any": "error",
    "@typescript-eslint/no-non-null-assertion": "error",
    "@typescript-eslint/consistent-type-imports": ["error", {
      "prefer": "type-imports",
      "fixStyle": "inline-type-imports"
    }],
    "@typescript-eslint/no-unnecessary-condition": "error",
    "@typescript-eslint/prefer-nullish-coalescing": "error",
    "@typescript-eslint/strict-boolean-expressions": "error",
    "@typescript-eslint/switch-exhaustiveness-check": "error"
  }
}
```

| Rule | What It Catches |
|------|----------------|
| `no-explicit-any` | Any use of the `any` type -- use `unknown` instead |
| `no-non-null-assertion` | The `!` postfix operator -- it is `as` for null checks, equally dangerous |
| `consistent-type-imports` | `import type` for type-only imports -- cleaner output |
| `no-unnecessary-condition` | `if (x)` when `x` is always truthy -- dead code |
| `prefer-nullish-coalescing` | `x ?? y` over `x \|\| y` when `x` could be `0` or `""` |
| `strict-boolean-expressions` | Prevents `if (obj)` when `obj` is not a boolean -- use `if (obj !== undefined)` |
| `switch-exhaustiveness-check` | Ensures every case in a discriminated union switch is handled |

## Examples

Working implementations in `examples/`:
- **`examples/strict-tsconfig.md`** -- Complete tsconfig.json with explanation of every strict flag, what it catches, and why it matters
- **`examples/discriminated-unions.md`** -- TypeScript examples showing discriminated unions vs type assertions for API responses, state machines, and error handling

## Review Checklist

When reviewing TypeScript code:

- [ ] `tsconfig.json` has `strict: true` plus `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`, `noPropertyAccessFromIndexSignature`
- [ ] No `as` type assertions outside of type guard functions
- [ ] No `any` type anywhere -- use `unknown` and narrow, or define a proper type
- [ ] No non-null assertions (`!`) -- check for null/undefined explicitly
- [ ] Discriminated unions (with `kind` or `type` field) are used for variant types
- [ ] Zod schemas validate all runtime data at system boundaries (API handlers, env vars, external data)
- [ ] Types are derived from Zod schemas (`z.infer<typeof schema>`), not defined separately
- [ ] Each module has an `index.ts` barrel file exporting only its public API
- [ ] Internal files are not imported directly from outside their module
- [ ] `as const` is used for constant objects where literal types matter
- [ ] `as const satisfies` is used when constants need both literal types AND type checking
- [ ] `import type` is used for type-only imports (enforced by `verbatimModuleSyntax`)
- [ ] ESLint uses `@typescript-eslint/strict-type-checked` ruleset
- [ ] `no-explicit-any` is set to "error", not "warn"
- [ ] Nullish coalescing (`??`) is used instead of logical OR (`||`) for default values