# Output Structure Guide

Defines what the generated skill must contain and how to organize reference files.

---

## Skill Directory

**One concern = one file.** Create a separate reference file for every distinct pattern category found in the project. Prefer many focused files (50-150 lines) over few large ones (300+ lines). If a section within a file grows past 80 lines, split it into its own file.

```
{project-name}-generator/
├── SKILL.md                    # < 500 lines, workflow + rules + reference pointers
└── references/                 # Each file < 300 lines, examples-first
    ├── architecture.md         # Project structure, config templates, feature organization
    ├── routing.md              # App Router / Pages Router patterns, file conventions, dynamic routes
    ├── components.md           # Server vs Client components, composition, 'use client' boundaries
    ├── data-fetching.md        # Server fetch, ORM queries, client-side hooks, ISR, SSG, streaming
    ├── server-actions.md       # 'use server', form actions, revalidation, error returns
    ├── api-routes.md           # Route handlers, middleware, NextRequest/NextResponse
    ├── state.md                # Client state (stores), URL state, cookie state
    ├── forms.md                # Schema-first validation, server action forms, react-hook-form
    ├── auth-middleware.md      # Auth setup, middleware.ts, session, protected routes
    ├── ui-styling.md           # CSS approach, next/font, next/image, theming, design tokens
    ├── conventions.md          # Naming table, type patterns, file organization rules
    ├── coding-style.md         # Arrow vs function, export style, async patterns, comment style
    ├── testing.md              # Test runner, mocking, structure, Server Component tests
    ├── error-handling.md       # error.tsx, loading.tsx, not-found.tsx, toasts, boundaries
    └── performance.md          # Streaming, Suspense, ISR, edge runtime, image/font optimization
```

This is the minimum set. Create additional reference files for any project-specific patterns found (i18n, CMS integration, real-time, analytics, email templates, etc.).

---

## What goes in each file

### architecture.md
- Directory structure template with annotations
- App Router directory organization (route groups, colocation)
- Feature organization within app/ (colocated vs separated components)
- Shared code organization: components/, lib/, actions/, types/
- Config file templates: package.json deps, next.config, tsconfig, tailwind.config
- Root layout: HTML structure, font loading, provider hierarchy
- Environment variables: NEXT_PUBLIC_ conventions, .env file hierarchy

### routing.md
- Route segment file conventions (page, layout, loading, error, not-found, template)
- Route groups: `(auth)`, `(dashboard)`, `(marketing)` -- when and how
- Dynamic routes: `[param]`, `[...catchAll]`, `[[...optional]]` patterns
- Parallel routes: `@slot` directories, `default.tsx` fallbacks
- Intercepting routes: `(.)`, `(..)`, `(...)` for modal patterns
- generateStaticParams template for SSG
- Link component patterns: active detection, prefetching behavior
- Navigation hooks: useRouter, usePathname, useSearchParams usage

### components.md
- Server Component template (async, data fetching, no hooks)
- Client Component template ('use client', hooks, event handlers)
- When to use which -- decision criteria checklist
- Composition: server wrapping client, client wrapping server via children
- Props serialization rules (what can cross the boundary)
- Colocated components (next to route) vs shared components
- Layout primitives: Stack, Grid, Flex, Container (or Tailwind patterns)
- Typography primitives: Heading, Text, Label (or raw elements)
- Dialog/Modal pattern with parallel routes or client state
- Reusable component API: variant/size props, slot props

### data-fetching.md
- Server-side fetch with cache/revalidate options (full template)
- Data access layer: `lib/data/{resource}.ts` pattern
- ORM query patterns (Prisma/Drizzle if used)
- React `cache()` for request deduplication
- `unstable_cache` with tags for on-demand revalidation
- Client-side fetching: SWR/TanStack Query setup (if used)
- ISR pattern: `revalidate` export + `revalidateTag`/`revalidatePath`
- SSG pattern: `generateStaticParams` + data fetching
- Streaming: nested Suspense with fallbacks
- Parallel data fetching: `Promise.all` in Server Components
- Error handling in data functions (throw vs return null)

### server-actions.md
- File organization: `actions/{resource}.ts` or `lib/actions/{resource}.ts`
- 'use server' directive placement (top of file)
- Input validation with Zod inside actions
- Return type pattern: `{ success, data?, error? }`
- FormData parsing patterns
- Revalidation: `revalidatePath()` vs `revalidateTag()` -- when to use which
- Redirect after mutations
- useActionState integration (React 19+)
- useFormStatus for submit buttons
- Optimistic updates with `useOptimistic`
- Error handling: structured errors vs throwing

### api-routes.md
- Route handler template: GET, POST, PUT, DELETE exports
- NextRequest: search params, body parsing, headers, cookies
- NextResponse: JSON responses, status codes, headers
- Auth verification in route handlers
- Middleware template: redirect, rewrite, header injection
- Middleware matcher configuration
- Edge runtime declaration
- Webhook handler patterns
- CORS handling (if needed)

### state.md
- Client state library setup (Zustand/Jotai/Redux or Context)
- Store creation template with types
- When to use client state vs server state vs URL state
- URL state with useSearchParams: filters, pagination, tabs
- Cookie-based state for preferences
- React Context for dependency injection (theme, auth provider)

### forms.md
- Schema template (.schema.ts file)
- Server Action form: `<form action={}>` pattern
- react-hook-form + Server Action integration (if used)
- useActionState: pending state + error display
- useFormStatus: submit button pending state
- Progressive enhancement (forms work without JS)
- Client-side validation before server submission
- Validation error display: field-level, summary, toast
- File upload in forms (if present)

### auth-middleware.md
- Auth library setup (next-auth, Clerk, etc.)
- Auth configuration: providers, callbacks, session strategy
- `auth()` usage in Server Components
- `useSession()` usage in Client Components
- Middleware auth check pattern
- Protected layout pattern (auth check in layout.tsx)
- Sign in / Sign out flows
- Role-based access patterns
- OAuth callback handling

### ui-styling.md
- CSS approach: Tailwind / CSS Modules / styled-components
- CSS variables (light + dark theme tokens)
- Tailwind config: theme extensions, custom values, plugins
- `cn()` utility implementation
- Dark mode: `next-themes` or manual class/media approach
- next/font setup: Google Fonts, local fonts, CSS variable injection
- next/image patterns: sizes, priority, placeholder, remote patterns
- next/link patterns: active state, prefetch control
- Responsive design patterns
- Component styling patterns (conditional classes, variants)

### conventions.md
- Complete naming table (files, folders, components, hooks, actions, types)
- Type pattern: `interface` vs `type`, colocated vs centralized
- Enum pattern: `const {} as const` + type extraction
- Import conventions: path aliases, barrel exports, import order
- File organization: max file length, when to split
- Environment variables: naming, NEXT_PUBLIC_ prefix usage
- Language: what language are user-facing strings in?

### coding-style.md
- Page component style: `export default function` vs `export default async function`
- Component declaration: arrow const vs function declaration
- Export style: default vs named, barrel patterns
- Props destructuring: inline vs separate variable
- Conditional rendering: ternary vs && vs early returns
- Async patterns: async/await vs .then(), error handling location
- Callback naming: `handleClick` vs inline arrows
- Comment philosophy: JSDoc, inline, or no comments
- Import ordering: group order, separators, alias usage
- Null/undefined handling: optional chaining, non-null assertions
- Type definitions: interface vs type, colocated vs centralized
- File organization: length limits, when to split
- Directive placement: 'use client' / 'use server' at top, blank line after

### testing.md
- Test runner config: vitest/jest -- setup and configuration
- File structure: colocated `*.test.tsx` or `__tests__/` directory
- Mocking: MSW for API, vi.mock/jest.mock for modules, next/navigation mocks
- Server Component testing: how to test async components
- Server Action testing: unit test as plain functions
- Client Component testing: render + screen queries + assertions
- E2E testing: Playwright/Cypress page objects and flow patterns
- Test data: factory functions, fixtures, or inline objects
- Custom render: test utils with provider wrappers

### error-handling.md
- error.tsx pattern: route-level error boundaries, reset button, logging
- loading.tsx pattern: skeleton components, spinner patterns
- not-found.tsx pattern: 404 pages, `notFound()` function usage
- Global error: `global-error.tsx` for root error boundary
- Toast/notifications: library, variants (success, error, warning)
- Server Action error returns: structured field errors
- Data function errors: throw vs return null patterns
- API route error responses: consistent error shape

### performance.md (generate only if project has these patterns)
- Streaming: nested Suspense boundaries, streaming strategy
- ISR: revalidate times per content type, on-demand revalidation
- Image optimization: next/image configuration, remote patterns, sizes
- Font optimization: next/font subsets, display strategy, variable fonts
- Edge runtime: which routes use edge, why
- Code splitting: dynamic imports for heavy client components
- Partial Prerendering (PPR): if enabled/used
- React.memo / useMemo / useCallback philosophy in Client Components
- Bundle analysis: next/bundle-analyzer usage

---

## Two-Layer Rule

EVERY pattern in every reference file must have:

1. **Architecture section** -- Framework-agnostic description of the pattern
2. **Implementation section** -- Exact code template for Next.js

Two layers = adaptable. The architecture sections alone are enough to implement the patterns in any framework.

---

## Quality Checklist for Reference Files

- [ ] Under 300 lines (with TOC if over 100)
- [ ] Code examples lead, prose explains why
- [ ] All entity names use `{placeholders}`
- [ ] Every pattern has a Do and Don't example
- [ ] Both architectural + implementation layers present
- [ ] No references to other reference files (one level deep from SKILL.md only)
- [ ] No time-sensitive information
- [ ] Consistent terminology throughout
- [ ] Server vs Client distinction clear in all component examples
- [ ] 'use client' / 'use server' directives shown where required
