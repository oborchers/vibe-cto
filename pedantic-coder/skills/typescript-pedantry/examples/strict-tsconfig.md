# Strict tsconfig Settings

Complete `tsconfig.json` configuration with explanation of every strict flag. Each flag exists because there is a class of bugs it prevents. Disabling any of them is opening a door you want locked.

## The Complete Configuration

```jsonc
{
  "compilerOptions": {
    // --- Strictness (non-negotiable) ---
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noPropertyAccessFromIndexSignature": true,
    "noFallthroughCasesInSwitch": true,

    // --- Module resolution ---
    "module": "ESNext",
    "moduleResolution": "bundler",
    "verbatimModuleSyntax": true,
    "resolveJsonModule": true,

    // --- Output ---
    "target": "ES2022",
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "outDir": "./dist",
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,

    // --- Consistency ---
    "forceConsistentCasingInFileNames": true,
    "isolatedModules": true,
    "skipLibCheck": true,

    // --- Path aliases ---
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

## Flag-by-Flag Explanation

### `strict: true`

This is a shorthand that enables all of the following:

| Sub-Flag | What It Prevents |
|----------|-----------------|
| `strictNullChecks` | Accessing `.name` on a value that could be `null` or `undefined`. Without this, every variable is secretly nullable, and TypeScript pretends it is not. |
| `strictFunctionTypes` | Passing a function with incompatible parameter types. Enables contravariant parameter checking. |
| `strictBindCallApply` | Calling `.bind()`, `.call()`, or `.apply()` with wrong argument types. |
| `strictPropertyInitialization` | Declaring a class property without initializing it in the constructor. Prevents `undefined` at runtime. |
| `noImplicitAny` | Using a value without a type annotation when TypeScript cannot infer one. Forces you to be explicit. |
| `noImplicitThis` | Using `this` in a function where its type is not known. Prevents `this` bugs in callbacks. |
| `alwaysStrict` | Emits `"use strict"` in every file. |
| `useUnknownInCatchVariables` | `catch (e)` gives `e` type `unknown` instead of `any`. Forces you to check before using. |

### `noUncheckedIndexedAccess: true`

```typescript
// WITHOUT noUncheckedIndexedAccess:
const arr = [1, 2, 3];
const first = arr[0]; // type: number (WRONG -- could be undefined if array is empty)

// WITH noUncheckedIndexedAccess:
const arr = [1, 2, 3];
const first = arr[0]; // type: number | undefined (CORRECT)

// Forces you to handle the undefined case:
if (first !== undefined) {
  console.log(first.toFixed(2)); // safe
}
```

This flag catches a massive class of bugs: array out-of-bounds access, missing object keys, and any indexed lookup that assumes the value exists.

### `exactOptionalPropertyTypes: true`

```typescript
interface Config {
  name: string;
  description?: string; // optional -- can be missing
}

// WITHOUT exactOptionalPropertyTypes:
const config: Config = { name: "app", description: undefined }; // allowed (WRONG)

// WITH exactOptionalPropertyTypes:
const config: Config = { name: "app", description: undefined }; // ERROR
// Optional means "can be missing", not "can be undefined"

// Correct ways:
const config1: Config = { name: "app" }; // missing -- OK
const config2: Config = { name: "app", description: "My app" }; // present -- OK
```

This enforces the difference between "the property is not present" and "the property is present but set to undefined." These are semantically different and should be treated differently.

### `noPropertyAccessFromIndexSignature: true`

```typescript
interface StringMap {
  [key: string]: string;
}

const map: StringMap = { greeting: "hello" };

// WITHOUT noPropertyAccessFromIndexSignature:
const val = map.greeting; // allowed -- looks like a known property (misleading)

// WITH noPropertyAccessFromIndexSignature:
const val = map.greeting; // ERROR -- use bracket notation
const val = map["greeting"]; // OK -- makes it clear this is a dynamic lookup
```

Bracket notation signals to the reader: "this key may or may not exist." Dot notation implies the property is definitely there.

### `verbatimModuleSyntax: true`

```typescript
// WITHOUT verbatimModuleSyntax:
import { User } from "./types"; // is this a value or a type? ambiguous

// WITH verbatimModuleSyntax:
import type { User } from "./types"; // type-only -- removed at compile time
import { createUser } from "./service"; // value -- kept at runtime
```

Forces `import type` for type-only imports. This makes the intent explicit and can improve build performance because the bundler knows which imports are erasable.

### `forceConsistentCasingInFileNames: true`

```typescript
// File is named: user-service.ts

// On macOS/Windows (case-insensitive filesystem):
import { UserService } from "./User-Service"; // works but wrong

// On Linux (case-sensitive filesystem):
import { UserService } from "./User-Service"; // CRASH -- file not found

// With forceConsistentCasingInFileNames:
import { UserService } from "./User-Service"; // ERROR on all platforms
import { UserService } from "./user-service"; // OK
```

This flag prevents the classic "works on my Mac, breaks in CI" bug.

## The Flags You Should NOT Set

| Flag | Why Not |
|------|---------|
| `skipLibCheck: false` | Checking library types slows compilation and surfaces errors in third-party code you cannot fix. Leave `skipLibCheck: true`. |
| `noImplicitReturns` | Overlaps with ESLint's `consistent-return` and can conflict with exhaustive switch patterns. Use ESLint instead. |
| `noUnusedLocals` / `noUnusedParameters` | Use ESLint's `no-unused-vars` instead -- it has better auto-fix and more configuration options. These compiler flags cannot be suppressed per-line. |

## Key Points

- `strict: true` is the floor, not the ceiling -- add `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`, and `noPropertyAccessFromIndexSignature` on top
- Every flag prevents a specific class of runtime bug that the compiler can catch at build time
- Never weaken strict settings to make a library compile -- fix the library or add a focused type declaration
- `verbatimModuleSyntax` replaces the old `importsNotUsedAsValues` and `preserveValueImports` flags
- If the team complains about strictness, the answer is: "The bugs these flags prevent are more annoying than the extra checks"