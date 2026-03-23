# Scan Checklist

For each category: read 2-3 representative files, extract the pattern, classify as **architectural** (agnostic) or **implementation** (Next.js-specific).

---

## 1. Project Foundation

| What to check | How |
|---|---|
| Next.js version | `package.json` -- determines available features (App Router, Server Actions, etc.) |
| Routing strategy | Check for `app/` (App Router) and/or `pages/` (Pages Router) directories |
| next.config | `next.config.js/mjs/ts` -- images, redirects, rewrites, headers, env, experimental |
| TypeScript config | `tsconfig.json` -- strict mode, path aliases, compiler options, `jsx: "preserve"` |
| CSS config | `tailwind.config` / `postcss.config` -- theme tokens, custom utilities |
| Lint/format | `eslint.config` + `.prettierrc` -- code style enforcement |
| Root layout | `app/layout.tsx` -- HTML structure, font loading, provider hierarchy, metadata |
| Global styles | `globals.css` -- CSS variables, theme system, resets, Tailwind layers |
| Environment variables | `.env.local`, `.env` -- `NEXT_PUBLIC_` prefix convention for client-side vars |
| Deployment | `vercel.json`, `netlify.toml`, `Dockerfile` -- deployment target and config |

**Architectural patterns to extract:** Directory organization strategy, separation of concerns boundaries, environment management approach.

**Implementation patterns to extract:** next.config options, root layout structure, font loading method, provider wrapping order, metadata defaults.

---

## 2. Routing

| What to check | Read example of |
|---|---|
| Route segments | `page.tsx` files -- how routes map to URL paths |
| Layouts | `layout.tsx` files -- nested layout composition, shared UI per route group |
| Loading states | `loading.tsx` -- Suspense-based loading UI per route |
| Error handling | `error.tsx` -- route-level error boundaries, reset/retry patterns |
| Not found | `not-found.tsx` -- 404 handling, `notFound()` function usage |
| Templates | `template.tsx` -- re-mount on navigation (vs layout persistence) |
| Route groups | `(group)/` directories -- logical grouping without URL impact |
| Dynamic routes | `[param]/`, `[...catchAll]/`, `[[...optional]]/` -- parameter patterns |
| Parallel routes | `@slot/` directories -- simultaneous route rendering |
| Intercepting routes | `(.)`, `(..)`, `(...)` -- modal-in-URL patterns |
| generateStaticParams | How static paths are generated for dynamic routes |

**Extract as architectural:**
```
- Nested layouts for shared UI (nav, sidebar) at each route depth
- Route groups separate auth layout from dashboard layout
- Loading.tsx at every route for instant loading feedback
- Error.tsx at feature boundaries, not-found.tsx at leaf routes
- Dynamic segments for entity detail pages: /{resource}/[id]
```

**Extract as implementation (example):**
```typescript
// app/(dashboard)/layout.tsx
export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-screen">
      <Sidebar />
      <main className="flex-1 p-6">{children}</main>
    </div>
  );
}

// app/(dashboard)/{resource}/[id]/page.tsx
export default async function {Resource}DetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const item = await get{Resource}(id);
  if (!item) notFound();
  return <{Resource}Detail item={item} />;
}

// app/(dashboard)/{resource}/[id]/loading.tsx
export default function Loading() {
  return <{Resource}DetailSkeleton />;
}
```

---

## 3. Components (Server vs Client)

| What to check | Read example of |
|---|---|
| Server Components | Async components that fetch data directly -- the default in App Router |
| Client Components | Files with `'use client'` -- interactive UI, hooks, browser APIs |
| Boundary decisions | WHERE they place the `'use client'` boundary (leaf vs branch) |
| Composition patterns | Server wrapping Client, Client wrapping Server (via children) |
| Props serialization | What props cross the server/client boundary (must be serializable) |
| Component colocation | Components next to routes vs shared components/ directory |
| Layout primitives | Stack, Box, Grid -- or raw divs with Tailwind? |
| Typography primitives | Heading, Text, Label -- or raw HTML elements? |
| Component API design | How they design prop interfaces for reusable components |
| HOCs / wrappers | `withAuth()`, `withLayout()` -- or only hooks + composition? |

**Extract as architectural:**
```
- Server Components by default -- only add 'use client' when interactivity needed
- 'use client' boundary pushed as far down the tree as possible (leaf components)
- Data fetching happens in Server Components (pages, layouts), passed as props to Client
- Interactive forms, event handlers, useState/useEffect -> Client Components
- Shared components may be Server or Client depending on need
```

**Extract as implementation (example):**
```typescript
// Server Component (default -- no directive)
// app/{resource}/page.tsx
export default async function {Resource}Page() {
  const items = await get{Resources}();
  return <{Resource}List items={items} />;  // Client Component receives data as props
}

// Client Component (interactive)
// components/{resource}-list.tsx
'use client';

import { useState } from 'react';

export function {Resource}List({ items }: { items: {Resource}[] }) {
  const [search, setSearch] = useState('');
  const filtered = items.filter(item =>
    item.name.toLowerCase().includes(search.toLowerCase())
  );
  return (
    <div>
      <SearchInput value={search} onChange={setSearch} />
      {filtered.map(item => <{Resource}Card key={item.id} item={item} />)}
    </div>
  );
}

// Composition: Server wrapping Client with Server children
// layout.tsx
export default function Layout({ children }: { children: React.ReactNode }) {
  return (
    <ClientShell>           {/* 'use client' */}
      <ServerSidebar />     {/* Server Component passed as children */}
      {children}
    </ClientShell>
  );
}
```

---

## 4. Data Fetching

| What to check | Read example of |
|---|---|
| Server-side fetch | `fetch()` in Server Components -- cache, revalidate, tags options |
| Data access layer | `lib/data/*.ts` or `lib/queries/*.ts` -- typed functions wrapping fetch/ORM |
| ORM usage | Prisma/Drizzle calls in server code -- how queries are structured |
| Cache strategy | `{ cache: 'force-cache' }`, `{ next: { revalidate: N } }`, `{ cache: 'no-store' }` |
| React cache() | `cache()` wrapper for request deduplication |
| unstable_cache | Next.js data cache with tags for on-demand revalidation |
| Client-side fetching | SWR, TanStack Query, or useEffect -- for real-time/interactive data |
| ISR | `revalidate` export in pages/route segments |
| SSG | `generateStaticParams` for static page generation |
| Streaming | Suspense boundaries for progressive page rendering |
| Parallel fetching | `Promise.all` or multiple awaits in Server Components |

**Extract as architectural:**
```
- Data fetched at route level (pages), never in leaf components
- Typed data access functions per entity in lib/data/
- Cache strategy per data type: static (build), ISR (revalidate), dynamic (no-store)
- Parallel data fetching with Promise.all where possible
- Client-side fetching only for real-time data or user-triggered updates
```

**Extract as implementation (example):**
```typescript
// lib/data/{resource}.ts
export async function get{Resources}(): Promise<{Resource}[]> {
  const res = await fetch(`${API_URL}/{resources}`, {
    next: { revalidate: 3600, tags: ['{resources}'] },
  });
  if (!res.ok) throw new Error('Failed to fetch {resources}');
  return res.json();
}

export async function get{Resource}(id: string): Promise<{Resource} | null> {
  const res = await fetch(`${API_URL}/{resources}/${id}`, {
    next: { tags: ['{resource}', id] },
  });
  if (res.status === 404) return null;
  if (!res.ok) throw new Error('Failed to fetch {resource}');
  return res.json();
}

// OR with Prisma:
export async function get{Resources}() {
  return prisma.{resource}.findMany({
    orderBy: { createdAt: 'desc' },
    include: { author: true },
  });
}

// Client-side (when needed):
'use client';
const { data, mutate } = useSWR(`/api/{resources}`, fetcher);
```

---

## 5. Server Actions

| What to check | Read example of |
|---|---|
| 'use server' directive | Top-of-file directive in action files |
| Organization | Separate files (`actions/{resource}.ts`) vs inline in components |
| Form integration | `<form action={serverAction}>` or `formAction` on buttons |
| useActionState | Pending state, error handling, optimistic updates |
| useFormStatus | Pending state in submit buttons |
| Revalidation | `revalidatePath()`, `revalidateTag()` after mutations |
| Redirect | `redirect()` after successful mutations |
| Error handling | try/catch with structured error returns vs throwing |
| Input validation | Zod schema validation inside server actions |

**Extract as architectural:**
```
- Server actions in separate files per domain: actions/{resource}.ts
- Every action validates input with Zod before processing
- Actions return { success, data?, error? } objects -- never throw for expected errors
- Revalidation targets specific paths/tags, not broad invalidation
- Redirect after create/delete, revalidate after update
```

**Extract as implementation (example):**
```typescript
// actions/{resource}.ts
'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { z } from 'zod';

const create{Resource}Schema = z.object({
  name: z.string().min(1).max(255),
  description: z.string().optional(),
});

export async function create{Resource}(formData: FormData) {
  const parsed = create{Resource}Schema.safeParse({
    name: formData.get('name'),
    description: formData.get('description'),
  });

  if (!parsed.success) {
    return { error: parsed.error.flatten().fieldErrors };
  }

  const item = await db.{resource}.create({ data: parsed.data });
  revalidatePath('/{resources}');
  redirect(`/{resources}/${item.id}`);
}

// With useActionState (React 19+):
// components/create-{resource}-form.tsx
'use client';

import { useActionState } from 'react';
import { create{Resource} } from '@/actions/{resource}';

export function Create{Resource}Form() {
  const [state, action, isPending] = useActionState(create{Resource}, null);
  return (
    <form action={action}>
      <input name="name" />
      {state?.error?.name && <p>{state.error.name}</p>}
      <SubmitButton pending={isPending} />
    </form>
  );
}
```

---

## 6. API Routes

| What to check | Read example of |
|---|---|
| Route handlers | `app/api/*/route.ts` -- GET, POST, PUT, DELETE exports |
| Request handling | `NextRequest` usage, search params, body parsing |
| Response patterns | `NextResponse.json()`, status codes, error responses |
| Auth in routes | How they verify auth in route handlers |
| Middleware | `middleware.ts` -- request interception, redirects, auth checks |
| Middleware matchers | `config.matcher` -- which routes middleware applies to |
| Edge runtime | `export const runtime = 'edge'` usage |

**Extract as architectural:**
```
- Route handlers for external API consumption or webhooks
- Server Actions preferred over route handlers for form mutations
- Middleware handles auth redirects and header injection
- Consistent error response shape across all route handlers
```

**Extract as implementation (example):**
```typescript
// app/api/{resources}/route.ts
import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
  const { searchParams } = request.nextUrl;
  const page = parseInt(searchParams.get('page') ?? '1');
  const items = await get{Resources}({ page });
  return NextResponse.json(items);
}

export async function POST(request: NextRequest) {
  const body = await request.json();
  const parsed = create{Resource}Schema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: parsed.error.flatten() }, { status: 400 });
  }
  const item = await create{Resource}(parsed.data);
  return NextResponse.json(item, { status: 201 });
}

// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const token = request.cookies.get('session')?.value;
  if (!token && request.nextUrl.pathname.startsWith('/dashboard')) {
    return NextResponse.redirect(new URL('/login', request.url));
  }
  return NextResponse.next();
}

export const config = {
  matcher: ['/dashboard/:path*', '/api/:path*'],
};
```

---

## 7. State Management

| What to check | Read example of |
|---|---|
| Client state library | Zustand/Jotai/Redux -- which and why (or just React Context/useState) |
| Store structure | A store file -- shape, actions, reset pattern |
| Server state approach | Server Components fetch data or TanStack Query/SWR for client-side |
| Context usage | React Context for theme, auth, or dependency injection |
| URL state | `useSearchParams` for filters, pagination, tabs |
| Cookie state | `cookies()` in Server Components, `js-cookie` client-side |

**Extract as architectural:**
```
- Server state: fetched in Server Components, passed as props (no client cache needed)
- Client state: {library} for UI state (modals, selections, view preferences)
- URL state: search params for shareable state (filters, pagination)
- No global state for server data -- Server Components eliminate the need
```

---

## 8. Forms & Validation

| What to check | Read example of |
|---|---|
| Form approach | Server Actions with `<form action={}>` or react-hook-form or native |
| Validation library | Zod / Yup / Valibot |
| Schema location | Same file or separate `.schema.ts` |
| Progressive enhancement | Forms that work without JavaScript |
| useActionState | Pending state + error display from server actions |
| useFormStatus | Pending state in submit buttons |
| Client validation | Client-side validation before server action (or server-only) |
| Error display | How validation errors render (field-level, summary, toast) |

**Extract as implementation (example):**
```typescript
// With Server Actions:
// lib/schemas/{resource}.ts
export const create{Resource}Schema = z.object({
  name: z.string().min(1, 'Required').max(255),
  email: z.string().email('Invalid email'),
});
export type Create{Resource}Input = z.infer<typeof create{Resource}Schema>;

// With react-hook-form + Server Actions:
'use client';
const form = useForm<Create{Resource}Input>({
  resolver: zodResolver(create{Resource}Schema),
});
const onSubmit = form.handleSubmit(async (data) => {
  const result = await create{Resource}Action(data);
  if (result?.error) {
    toast.error(result.error);
  }
});
```

---

## 9. UI & Styling

| What to check | Read example of |
|---|---|
| CSS approach | Tailwind / CSS Modules / styled-components / CSS-in-JS |
| Theme system | CSS variables, dark mode toggle, theme provider |
| next/font | Font loading -- Google Fonts, local fonts, variable fonts |
| next/image | Image optimization patterns, sizes, priority |
| next/link | Link component usage, active link detection |
| Class utility | `cn()` / `clsx` / `classnames` |
| Design tokens | Spacing, radius, colors, shadows |
| Responsive patterns | Mobile-first, breakpoints, container queries |
| Dark mode | `class` strategy vs `media` strategy, `next-themes` |

---

## 10. Auth & Middleware

| What to check | Read example of |
|---|---|
| Auth library | next-auth / Clerk / Supabase / custom |
| Session strategy | JWT vs database sessions |
| Auth config | `auth.ts` or `auth.config.ts` -- providers, callbacks |
| Protected routes | Middleware-based vs layout-based vs component-based protection |
| Auth helpers | `auth()` in Server Components, `useSession()` in Client Components |
| Role-based access | How roles/permissions are checked |
| Sign in / Sign out | Login page, sign-out action, redirect flows |
| OAuth providers | Which providers are configured (Google, GitHub, etc.) |

**Extract as architectural:**
```
- Middleware redirects unauthenticated users from protected routes
- auth() helper used in Server Components for session data
- useSession() hook for Client Component auth state
- Role checks at layout level, not in individual components
```

---

## 11. Testing

| What to check | Read example of |
|---|---|
| Test runner | vitest / jest / cypress / playwright |
| File location | Colocated (`*.test.tsx` next to source) or `__tests__/` directory |
| Mocking pattern | MSW for API? `vi.mock` / `jest.mock`? next/navigation mocks? |
| Server Component testing | How they test async Server Components |
| Server Action testing | How they test server actions (unit vs integration) |
| What they test | Unit components? Integration pages? E2E flows? |
| Setup files | `setupTests.ts`, custom render, test utils |
| E2E approach | Playwright page objects, fixture patterns |

**Extract as architectural:**
```
- Tests colocated with source / in __tests__ directory
- Server Components tested via integration tests (rendering full pages)
- Server Actions tested as unit functions (call directly, check DB)
- Client Components tested with @testing-library/react
- E2E tests cover critical user flows (auth, CRUD, navigation)
```

---

## 12. Coding Style Fingerprint

This section captures the **personal coding style** of the team. Read 5-6 diverse files to extract these signals.

| Signal | What to look for |
|---|---|
| Arrow vs function declarations | `const Comp = () =>` or `function Comp()` or `export default function Page()`? |
| Export style | `export default` (common for pages) or named exports? Barrel re-exports? |
| Page component style | `export default function` (convention) or `export default async function`? |
| Destructuring depth | Props destructured inline `({ name, age })` or separate `const { name } = props`? |
| Conditional rendering | Ternaries, `&&`, early returns, or wrapper `<Show when={}>` ? |
| Async patterns | `async/await` + try/catch or `.then().catch()`? Where do they handle errors? |
| Comment style | JSDoc? `// TODO`? Inline comments? No comments at all? |
| Import order | React first -> third-party -> @/ aliases -> relative? Separator lines? |
| Type definitions | `interface` or `type`? Same file or in `types/`? |
| Callback handling | Inline `onClick={() => doX()}` or named `onClick={handleClick}`? |
| Optional chaining | `data?.name` or `data && data.name`? |
| String style | Template literals always or only when interpolating? |
| Null handling | `null`, `undefined`, or non-null assertions `!`? |
| Guard clauses | Early returns at top of function or nested if/else? |

**Extract as a style profile:**
```
CODING STYLE PROFILE:
- Pages: export default function (async for Server Components)
- Components: arrow functions with named exports
- Props: destructured inline, typed with interface
- Conditionals: early returns for guards, ternary for inline JSX
- Async: async/await everywhere, errors in error.tsx boundaries
- Comments: minimal -- only for non-obvious business logic
- Imports: React -> external -> @/ aliases -> relative, no separators
- Callbacks: named handlers (handleClick, handleSubmit) -- never inline
- Null: optional chaining, no non-null assertions
- Files: short (<150 lines), split into multiple files when growing
- Directives: 'use client' only when hooks or interactivity needed
```

---

## 13. Inconsistencies & Anti-patterns

Look for places where the team does NOT follow their own patterns.

| What to look for | Why it matters |
|---|---|
| Client Components that could be Server Components | Unnecessary 'use client' -- missing server-side benefits |
| Data fetching in Client Components when Server would work | Waterfall requests, no streaming |
| Server Actions without input validation | Security risk |
| Inconsistent error handling (some routes have error.tsx, some don't) | Uneven UX |
| Mixed routing strategies (some features in app/, some in pages/) | Migration in progress |
| Direct DB calls in page.tsx instead of data access layer | No separation of concerns |
| Inline styles mixed with Tailwind classes | Styling inconsistency |
| Inconsistent metadata (some pages have it, some don't) | SEO gaps |
| Raw `console.log` left in server code | Debug artifacts |

**Document as:**
```
INCONSISTENCIES FOUND:
- app/legacy-reports/ uses 'use client' + useEffect for data -- should be Server Component
  -> AVOID: use async Server Components for data fetching
- app/api/users/route.ts returns raw errors without standard shape
  -> RULE: all API routes return { data, error } envelope
- 3 of 8 dynamic routes missing generateStaticParams
  -> RULE: add generateStaticParams for all known-at-build-time paths

DECISION: When inconsistency found, follow the MAJORITY pattern.
```

---

## 14. Advanced (if present)

Only scan these if they exist in the project:

### Internationalization
- `next-intl`, `next-i18next`, or manual i18n
- `[locale]` segment in app/ directory
- Message files location and format

### CMS Integration
- Contentlayer, Sanity, Contentful -- content fetching patterns
- MDX processing and rendering

### Analytics & Monitoring
- `@vercel/analytics`, `@vercel/speed-insights`
- Sentry error tracking integration
- PostHog or custom analytics

### Edge Runtime
- `export const runtime = 'edge'` on specific routes
- Edge-compatible data sources

### Performance
- Streaming with nested Suspense boundaries
- `React.lazy` for heavy client components
- Image optimization: `next/image` with `sizes`, `priority`, `placeholder`
- Font optimization: `next/font` with `display`, `subsets`, `variable`
- ISR patterns with `revalidate` and on-demand revalidation via `revalidateTag`
- Partial Prerendering (PPR) if enabled

### Real-time
- WebSocket, Server-Sent Events, or polling patterns
- Pusher, Ably, or custom real-time setup

### Email
- React Email templates, Resend/SendGrid integration
