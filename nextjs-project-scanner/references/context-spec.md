# .context/ Specification

Generate a `.context/` directory alongside the skill output. This makes the extracted patterns usable by ANY AI coding tool, not just Claude skills.

---

## What is .context/?

The [Codebase Context Specification](https://github.com/Agentic-Coding/Codebase-Context-Spec) is an emerging standard for documenting project architecture and conventions in a format any AI tool can consume. Tools like Cursor (.cursorrules), Copilot, and Windsurf already look for context files.

By generating `.context/`, the extracted patterns work everywhere -- not just as a Claude skill.

---

## Files to Generate

### .context/index.md

```markdown
---
module-name: {project-name}-patterns
description: Architecture and coding conventions extracted from {project-name}
related-modules: []
technologies:
  - next.js
  - react
  - {css-approach}
  - {auth-library}
  - {orm}
  - {validation-library}
conventions:
  - {convention-1}
  - {convention-2}
  - {convention-3}
architecture-style: {e.g., "App Router with Server Components, server actions, and route-level data fetching"}
---

# {ProjectName} Architecture

## Overview
{1-2 sentences describing the project architecture}

## Stack
Next.js {version} ({routing-strategy}) | {ui-lib} | {state-approach} | {form-approach} + {validation-lib} | {auth-lib} | {orm} | {css-approach}

## Key Decisions
- **Routing**: {App Router / Pages Router / Hybrid} -- {why}
- **Data fetching**: {Server Components with fetch / ORM in data layer / client-side SWR}
- **Mutations**: {Server Actions / API routes / client mutations}
- **Auth**: {next-auth / Clerk / custom} -- {session strategy}
- **State**: {Server Components for server data, {client-lib} for UI state, URL params for shareable state}
- **Styling**: {css-approach} with {utility-lib}
- **Database**: {ORM} with {database}
```

### .context/architecture.md

Condensed version of the skill's `references/architecture.md` and `references/routing.md`. Focus on:

```markdown
# Architecture

## Directory Structure
\```
app/
├── (auth)/               # Auth route group (login, register)
│   ├── login/page.tsx
│   └── layout.tsx        # Auth-specific layout
├── (dashboard)/          # Dashboard route group
│   ├── layout.tsx        # Dashboard shell (nav + sidebar)
│   ├── page.tsx          # Dashboard home
│   └── {feature}/
│       ├── page.tsx      # List view (Server Component)
│       ├── [id]/page.tsx # Detail view (Server Component)
│       ├── loading.tsx   # Suspense fallback
│       └── error.tsx     # Error boundary
├── api/                  # Route handlers (for external APIs/webhooks)
├── layout.tsx            # Root layout (html, body, fonts, providers)
├── page.tsx              # Landing page
├── not-found.tsx         # 404
└── error.tsx             # Root error boundary
components/
├── ui/                   # Base UI (shadcn / custom)
├── {feature}/            # Feature-specific components
└── shared/               # Cross-feature components
lib/
├── data/                 # Data access functions
├── actions/              # Server actions
├── schemas/              # Zod validation schemas
└── utils/                # Pure utilities
types/                    # Shared types and interfaces
\```

## Routing Strategy
{App Router / Pages Router / Hybrid}
- Route groups separate concerns: (auth), (dashboard), (marketing)
- Nested layouts for shared UI at each level
- loading.tsx + error.tsx at every feature boundary
- Dynamic routes for entity detail pages

## Server vs Client Components
- Server Components by default (no directive needed)
- 'use client' only for: event handlers, hooks, browser APIs, interactive UI
- Data fetching in Server Components (pages/layouts), props down to Client
- 'use client' boundary pushed as deep as possible (leaf components)

## Data Flow
- Server: page.tsx (async) -> lib/data/{resource}.ts -> database/API
- Mutations: form -> server action (lib/actions/{resource}.ts) -> revalidate
- Client-side: only for real-time data or interactive updates
```

### .context/conventions.md

Condensed version of the skill's naming and style conventions:

```markdown
# Conventions

## Naming
| Element | Convention | Example |
|---------|-----------|---------|
| Route segment | kebab-case | `user-settings/` |
| Page file | page.tsx (fixed) | `app/dashboard/page.tsx` |
| Layout file | layout.tsx (fixed) | `app/(dashboard)/layout.tsx` |
| Component file | PascalCase.tsx | `UserCard.tsx` |
| Server action file | kebab-case.ts | `lib/actions/create-user.ts` |
| Data access file | kebab-case.ts | `lib/data/users.ts` |
| Schema file | kebab-case.ts | `lib/schemas/user.ts` |
| Hook file | camelCase.ts | `useDebounce.ts` |
| Type file | kebab-case.ts | `types/user.ts` |
| CSS Module | kebab-case.module.css | `user-card.module.css` |
| Env variable (server) | UPPER_SNAKE | `DATABASE_URL` |
| Env variable (client) | NEXT_PUBLIC_ prefix | `NEXT_PUBLIC_API_URL` |

## Do
- Use Server Components by default
- Fetch data in page.tsx, pass as props
- Validate all server action inputs with Zod
- Use next/image, next/link, next/font
- Export metadata from all public pages
- Add loading.tsx and error.tsx at feature boundaries

## Don't
- Add 'use client' unless interactivity is required
- Fetch data in Client Components when Server Components work
- Use raw <img>, <a>, or external font links
- Skip input validation in server actions
- Use TypeScript enums (use const objects instead)
- Put business logic in page.tsx (extract to lib/)
```

### .context/patterns.md

Condensed version of data fetching, server actions, forms, state, and error handling patterns:

```markdown
# Code Patterns

## Data Fetching (Server)
\```typescript
// lib/data/{resource}.ts
export async function get{Resources}() {
  const res = await fetch(`${API_URL}/{resources}`, {
    next: { revalidate: 3600, tags: ['{resources}'] },
  });
  if (!res.ok) throw new Error('Failed to fetch');
  return res.json() as Promise<{Resource}[]>;
}

// app/{feature}/page.tsx
export default async function {Feature}Page() {
  const items = await get{Resources}();
  return <{Resource}List items={items} />;
}
\```

## Server Actions
\```typescript
// lib/actions/{resource}.ts
'use server';
export async function create{Resource}(formData: FormData) {
  const parsed = create{Resource}Schema.safeParse(Object.fromEntries(formData));
  if (!parsed.success) return { error: parsed.error.flatten().fieldErrors };
  await db.{resource}.create({ data: parsed.data });
  revalidatePath('/{resources}');
  redirect('/{resources}');
}
\```

## Forms
\```typescript
// components/{feature}/create-form.tsx
'use client';
export function Create{Resource}Form() {
  const [state, action, isPending] = useActionState(create{Resource}, null);
  return (
    <form action={action}>
      <input name="name" />
      {state?.error?.name && <p className="text-red-500">{state.error.name}</p>}
      <button type="submit" disabled={isPending}>
        {isPending ? 'Creating...' : 'Create'}
      </button>
    </form>
  );
}
\```

## Error Handling
\```typescript
// app/{feature}/error.tsx
'use client';
export default function Error({ error, reset }: { error: Error; reset: () => void }) {
  return (
    <div>
      <h2>Something went wrong</h2>
      <button onClick={reset}>Try again</button>
    </div>
  );
}

// app/{feature}/loading.tsx
export default function Loading() {
  return <{Feature}Skeleton />;
}
\```

## Route Handlers (if needed)
\```typescript
// app/api/{resources}/route.ts
export async function GET(request: NextRequest) {
  const items = await get{Resources}();
  return NextResponse.json(items);
}
\```
```

### .context/style.md

Condensed coding style profile -- how the team writes code:

```markdown
# Coding Style

## Declaration & Export
- Pages: `export default function {Page}Page()` (async when fetching)
- Components: {arrow const / function declaration} with {named / default} exports
- Server actions: `export async function` in files with 'use server' directive
- Hooks: `export function use{Hook}()` -- always named exports

## Directives
- 'use client' at top of file, blank line after
- 'use server' at top of file, blank line after
- Only add when needed -- Server Components are the default

## Code Patterns
- Props: {destructured inline / separate variable}
- Conditionals: {ternary / && / early returns}
- Async: {async/await everywhere / .then() for simple chains}
- Callbacks: {named handlers / inline arrows}
- Null handling: {optional chaining / guards / non-null assertions}

## Type Definitions
- Preference: {interface / type}
- Location: {colocated / centralized in types/}
- Params typing: `params: Promise<{ id: string }>` (Next.js 15+)

## Formatting
- Comments: {JSDoc / inline / minimal}
- Import order: {React -> next/ -> external -> @/ aliases -> relative}
- File length: {short <150 lines / medium / large}
- Blank lines: {between sections / between functions / minimal}
```

---

## Guidelines

1. **Keep .context/ files SHORT** -- aim for 50-100 lines each. These are reference cards, not documentation.
2. **Use the same `{placeholders}`** as the skill references for consistency.
3. **No workflow instructions** -- .context/ describes patterns, not how to generate a project. That's what the skill is for.
4. **Framework-specific** -- unlike skill references (which have two layers), .context/ files should be written for Next.js specifically. Other tools don't need the agnostic layer.
