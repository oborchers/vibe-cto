# Discriminated Unions vs Type Assertions

TypeScript examples showing how discriminated unions replace type assertions (`as`) for API responses, state machines, and error handling. Every `as` cast in these examples is a bug waiting to happen. Every discriminated union makes the bug impossible.

## API Responses

### Bad -- Type Assertions

```typescript
interface ApiResponse {
  status: number;
  data?: unknown;
  error?: string;
}

async function fetchUser(id: string): Promise<User> {
  const response = await fetch(`/api/users/${id}`);
  const json: ApiResponse = await response.json();

  if (json.error) {
    throw new Error(json.error);
  }

  // "as User" is a lie -- what if the server returned something else?
  return json.data as User;
}

async function fetchUsers(): Promise<User[]> {
  const response = await fetch("/api/users");
  const json: ApiResponse = await response.json();

  // Double assertion: "as unknown as User[]" -- the developer knows this is wrong
  // and is telling TypeScript to shut up anyway
  return json.data as unknown as User[];
}
```

### Good -- Discriminated Union with Zod

```typescript
import { z } from "zod";

// Define the response shapes as discriminated unions
type ApiResponse<T> =
  | { kind: "success"; data: T }
  | { kind: "error"; error: string; statusCode: number };

// Schema for User
const userSchema = z.object({
  id: z.string(),
  name: z.string(),
  email: z.string().email(),
  createdAt: z.string().datetime(),
});

type User = z.infer<typeof userSchema>;

// Generic fetch function with runtime validation
async function apiFetch<T>(
  url: string,
  schema: z.ZodType<T>,
): Promise<ApiResponse<T>> {
  const response = await fetch(url);
  const json = await response.json();

  if (!response.ok) {
    return {
      kind: "error",
      error: json.message ?? "Unknown error",
      statusCode: response.status,
    };
  }

  const result = schema.safeParse(json);
  if (!result.success) {
    return {
      kind: "error",
      error: `Invalid response: ${result.error.message}`,
      statusCode: 500,
    };
  }

  return { kind: "success", data: result.data };
}

// Usage -- no type assertions anywhere
async function fetchUser(id: string): Promise<User> {
  const response = await apiFetch(`/api/users/${id}`, userSchema);

  switch (response.kind) {
    case "success":
      return response.data; // TypeScript knows: User
    case "error":
      throw new ApiError(response.error, response.statusCode);
  }
}
```

## State Machines

### Bad -- String Status with Type Assertions

```typescript
interface Task {
  id: string;
  status: string;
  result?: unknown;
  error?: unknown;
  progress?: number;
}

function renderTask(task: Task) {
  if (task.status === "completed") {
    // "as string" -- what if result is an object? a number? null?
    const output = task.result as string;
    return <div>{output}</div>;
  }

  if (task.status === "failed") {
    const err = task.error as Error;
    return <div className="error">{err.message}</div>;
  }

  if (task.status === "running") {
    // What if progress is undefined? "as number" hides the problem.
    const pct = task.progress as number;
    return <ProgressBar value={pct} />;
  }

  return <div>Unknown state</div>;
}
```

### Good -- Discriminated Union State Machine

```typescript
type Task =
  | { id: string; status: "pending" }
  | { id: string; status: "running"; progress: number }
  | { id: string; status: "completed"; result: string }
  | { id: string; status: "failed"; error: TaskError };

interface TaskError {
  message: string;
  code: string;
  retryable: boolean;
}

function renderTask(task: Task) {
  switch (task.status) {
    case "pending":
      return <div>Waiting to start...</div>;

    case "running":
      // TypeScript knows: task.progress exists and is number
      return <ProgressBar value={task.progress} />;

    case "completed":
      // TypeScript knows: task.result exists and is string
      return <div>{task.result}</div>;

    case "failed":
      // TypeScript knows: task.error exists and is TaskError
      return (
        <div className="error">
          <p>{task.error.message}</p>
          {task.error.retryable && <button>Retry</button>}
        </div>
      );
  }

  // Exhaustiveness check: if a new status is added, this line errors
  const _exhaustive: never = task;
}
```

**What changed:** Each state carries exactly the data it needs. `progress` only exists on `running`. `result` only exists on `completed`. `error` only exists on `failed`. There is no `unknown`, no `as`, and no possibility of accessing a field that does not exist in the current state.

## Error Handling

### Bad -- Catch-All with Type Assertion

```typescript
async function processPayment(orderId: string): Promise<PaymentResult> {
  try {
    const order = await getOrder(orderId);
    const charge = await chargeCard(order);
    return { success: true, chargeId: charge.id };
  } catch (error) {
    // "as Error" -- what if it's a string? a number? a Stripe error object?
    const err = error as Error;
    return { success: false, message: err.message };
  }
}
```

### Good -- Discriminated Result Type

```typescript
type Result<T, E = AppError> =
  | { ok: true; value: T }
  | { ok: false; error: E };

interface AppError {
  kind: "not_found" | "validation" | "payment_failed" | "internal";
  message: string;
  cause?: unknown;
}

async function processPayment(orderId: string): Promise<Result<PaymentReceipt>> {
  const orderResult = await getOrder(orderId);
  if (!orderResult.ok) {
    return orderResult; // propagate the error with its type
  }

  const chargeResult = await chargeCard(orderResult.value);
  if (!chargeResult.ok) {
    return {
      ok: false,
      error: {
        kind: "payment_failed",
        message: `Charge failed for order ${orderId}`,
        cause: chargeResult.error,
      },
    };
  }

  return {
    ok: true,
    value: {
      orderId,
      chargeId: chargeResult.value.id,
      amount: chargeResult.value.amount,
    },
  };
}

// Usage -- the caller must handle both cases
const result = await processPayment("ord_123");
if (result.ok) {
  console.log(`Payment successful: ${result.value.chargeId}`);
} else {
  switch (result.error.kind) {
    case "not_found":
      return res.status(404).json({ error: result.error.message });
    case "validation":
      return res.status(400).json({ error: result.error.message });
    case "payment_failed":
      return res.status(402).json({ error: result.error.message });
    case "internal":
      return res.status(500).json({ error: "Internal server error" });
  }
}
```

## Form State

### Bad -- Optional Fields Everywhere

```typescript
interface FormState {
  isSubmitting?: boolean;
  isSuccess?: boolean;
  error?: string;
  data?: FormData;
}

function handleSubmit(state: FormState) {
  if (state.isSubmitting) {
    // is data available? who knows
    showSpinner();
  } else if (state.isSuccess) {
    // is data available? maybe? probably?
    showSuccess(state.data as FormData);
  } else if (state.error) {
    showError(state.error);
  }
  // what if none of these are true? silent nothing.
}
```

### Good -- Discriminated Form State

```typescript
type FormState =
  | { status: "idle" }
  | { status: "submitting"; data: FormData }
  | { status: "success"; data: FormData; response: SubmitResponse }
  | { status: "error"; data: FormData; error: string };

function handleSubmit(state: FormState) {
  switch (state.status) {
    case "idle":
      return <SubmitButton />;
    case "submitting":
      return <Spinner />;
    case "success":
      return <SuccessMessage response={state.response} />;
    case "error":
      return <ErrorMessage error={state.error} onRetry={() => submit(state.data)} />;
  }
}
```

## Key Points

- Discriminated unions use a literal `kind`, `type`, or `status` field that TypeScript narrows on in `switch` and `if` statements
- Each variant carries exactly the data relevant to that state -- no optional fields, no `unknown`, no assertions
- The `never` exhaustiveness check at the end of a switch ensures every variant is handled -- adding a new variant causes a compile error everywhere it is unhandled
- `as` is only acceptable inside type guard functions (`function isX(v: unknown): v is X`) where you are explicitly performing a runtime check
- Result types (`{ ok: true; value: T } | { ok: false; error: E }`) replace try/catch for operations where failure is expected and must be handled by the caller
- Zod schemas provide the runtime validation that discriminated unions provide at compile time -- use both together at system boundaries