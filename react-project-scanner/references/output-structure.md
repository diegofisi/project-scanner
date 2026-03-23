# Output Structure Guide

Defines what the generated skill must contain and how to organize reference files.

---

## Skill Directory

**One concern = one file.** Create a separate reference file for every distinct pattern category found in the project. Prefer many focused files (50-150 lines) over few large ones (300+ lines). If a section within a file grows past 80 lines, split it into its own file.

```
{project-name}-generator/
├── SKILL.md                    # < 500 lines, workflow + rules + reference pointers
└── references/                 # Each file < 300 lines, examples-first
    ├── architecture.md         # Project structure, config templates, feature slice anatomy
    ├── data-layer.md           # HTTP client, query/mutation hooks, DTOs, mappers
    ├── components.md           # Container/presentational, layout/typography primitives, composition
    ├── state.md                # Client state (stores), server state (query client config)
    ├── forms.md                # Schema-first validation, form ↔ dialog integration
    ├── routing-auth.md         # Router setup, route guards, lazy loading, auth flow, token management
    ├── ui-styling.md           # CSS approach, theme variables, dark mode, cn() utility, design tokens
    ├── conventions.md          # Naming table, enum pattern, type patterns, file organization rules
    ├── coding-style.md         # Arrow vs function, export style, async patterns, comment style
    ├── testing.md              # Test runner, mocking, test structure, custom render, patterns
    ├── error-handling.md       # Error boundaries, toast/notifications, loading/empty states, fallbacks
    └── performance.md          # Memoization, lazy loading, virtualization, Suspense (if applicable)
```

This is the minimum set. Create additional reference files for any project-specific patterns found (i18n, drag-and-drop, real-time, file uploads, complex permissions, etc.).

---

## What goes in each file

### architecture.md
- Directory structure template with annotations
- Feature slice anatomy (what goes in api/, components/, containers/, etc.)
- core/ vs features/ vs shared/ — decision criteria
- Config file templates: package.json deps, vite.config, tsconfig, tailwind.config
- Entry point: main.tsx + App.tsx with provider hierarchy

### data-layer.md
- HTTP client setup (full code template)
- Query hook template with DTO + mapper
- Mutation hook template with cache invalidation
- DTO file template (interface + mapper function)
- Domain model template
- Response envelope handling
- Token refresh pattern (if present)
- extractArray / normalize helpers (if present)

### components.md
- Presentational component template (with forwardRef + displayName)
- Container component template (hooks → presentational)
- Layout primitives code: Stack, Box, Grid (full implementation)
- Typography primitives code: H1-H6, P, Small, Span (full implementation)
- Dialog pattern: controlled props (open, onOpenChange, form, onSubmit, isPending)
- Actions menu / context menu pattern (if present)

### state.md
- Store creation template
- Store shape conventions (state + actions + reset)
- How to access store in components
- When to use client state vs server state
- Query client configuration (staleTime, retry, etc.)

### forms.md
- Schema template (.schema.ts file)
- useForm setup with resolver
- Form ↔ Container ↔ Dialog integration flow
- Validation error display pattern
- Submit handler: form.handleSubmit → mutation.mutate → {onSuccess, onError}

### routing-auth.md
- Router setup (createBrowserRouter or equivalent)
- Route definition pattern with lazy loading
- Route guard wrapper components
- Path constants pattern (const object + type)
- Auth store template
- Login page template
- Auth callback handler
- Token management (storage, injection, refresh, de-duplication)
- Logout cleanup

### ui-styling.md
- CSS variables (light + dark theme)
- Tailwind config (if used): theme extensions, custom values
- cn() utility implementation
- Dark mode toggle mechanism
- Component styling patterns (conditional classes)

### conventions.md
- Complete naming table (feature folders, components, hooks, stores, schemas, DTOs, models, API folders, types, enums)
- Enum pattern: `const {} as const` + type extraction (with example)
- Import conventions (path aliases, barrel exports)
- Language: what language are user-facing strings in?

### coding-style.md
- Component declaration style: arrow const vs function declaration
- Export style: default vs named, barrel re-export patterns
- Props destructuring: inline vs separate variable
- Conditional rendering: ternary vs && vs early returns
- Async patterns: async/await vs .then(), error handling location
- Callback naming: `handleClick` vs inline arrows
- Comment philosophy: JSDoc, inline, or no comments
- Import ordering: group order, separators, alias usage
- Null/undefined handling: optional chaining, non-null assertions
- Type definitions: interface vs type, colocated vs centralized
- File organization: length limits, when to split

### testing.md
- Test runner: vitest/jest/cypress/playwright — config and setup
- File structure: colocated `*.test.tsx` or `__tests__/` directory
- Mocking strategy: MSW for APIs, vi.mock/jest.mock for modules
- Custom render: test utils with provider wrappers (QueryClient, Router, Theme)
- Hook test template: renderHook + waitFor pattern
- Component test template: render + screen queries + assertions
- E2E test template (if present): page objects, selectors, flows
- Test data: factory functions, fixtures, or inline objects
- Coverage expectations and what they prioritize testing

### error-handling.md
- Error boundaries: placement strategy (page-level, feature-level, global)
- Fallback UI: error component patterns and recovery actions
- Loading states: page-level (Suspense), component-level (skeleton/spinner)
- Empty states: empty state component pattern
- Toast/notifications: library, variants (success, error, warning, undo)
- API error handling: error transformation, user-facing messages
- Form error display: field-level, summary, toast

### performance.md (generate only if project has these patterns)
- React.memo: which component types get memoized
- useMemo/useCallback: usage philosophy (liberal vs measured)
- Route-level lazy loading: React.lazy + Suspense boundaries
- Code splitting: manual splits beyond routes
- List virtualization: library and implementation (tanstack-virtual, react-window)
- Image optimization: lazy loading, responsive images, next/image
- Bundle considerations: tree-shaking, dynamic imports

---

## Two-Layer Rule

EVERY pattern in every reference file must have:

1. **Architecture section** — Framework-agnostic description of the pattern
2. **Implementation section** — Exact code template for the detected framework

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
