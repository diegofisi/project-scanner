# Generated Skill Template

Use this template to write the SKILL.md for the generated project-generator skill. Adapt based on what was actually found in the scanned project.

---

## Frontmatter

```yaml
---
name: {project-name}-generator
description: >
  Generates complete, production-ready Next.js projects following the {project-name}
  architecture. Given a business idea, refines it into features and produces a fully functional
  Next.js application with {key-stack-summary}. Triggers: "create a next.js app", "build me a
  web app", "new next project for...", "scaffold an app that...", or any request to create a
  Next.js application from a concept or business idea.
---
```

Description must be in third person. Include specific trigger phrases.

---

## SKILL.md Body Structure

### Section 1: Overview (5-10 lines)

```markdown
# {ProjectName} Generator

Generates Next.js applications following a production-tested architecture.

## Stack
Next.js {version} ({routing-strategy}) | {ui-library} | {state-approach} | {form-approach} + {validation-lib} | {auth-lib} | {orm} | {css-approach}
```

Keep this SHORT. One line per concern, no explanations.

### Section 2: Pipeline (the core workflow)

```markdown
## From Idea to Project

### Step 1: Refine the Idea
ASK the user (do not assume):
- What are the 3-5 core features?
- What user roles exist? (admin, user, guest)
- What are the main pages/views?
- What are the data entities and their relationships?
- What operations per entity? (CRUD? custom actions?)
- Does it need auth? What providers?

Present a summary table and confirm before proceeding.

### Step 2: Plan Architecture
Map features -> route segments and feature organization. Output:

\```
app/
├── (auth)/
│   ├── login/page.tsx
│   └── register/page.tsx
├── (dashboard)/
│   ├── layout.tsx          # Dashboard shell (nav + sidebar)
│   ├── page.tsx            # Dashboard home
│   └── {feature}/
│       ├── page.tsx        # List view
│       ├── [id]/
│       │   ├── page.tsx    # Detail view
│       │   └── edit/
│       │       └── page.tsx
│       ├── new/
│       │   └── page.tsx    # Create view
│       ├── loading.tsx     # Feature loading state
│       └── error.tsx       # Feature error boundary
├── api/
│   └── {resource}/
│       └── route.ts        # REST endpoints (if needed)
├── layout.tsx              # Root layout (html, body, fonts, providers)
├── page.tsx                # Landing page
├── loading.tsx             # Root loading
├── error.tsx               # Root error
└── not-found.tsx           # 404 page
components/
├── ui/                     # Base UI components (shadcn or custom)
├── {feature}/              # Feature-specific components
└── shared/                 # Cross-feature components
lib/
├── data/                   # Data access functions per entity
├── actions/                # Server actions per entity
├── schemas/                # Zod validation schemas
├── utils/                  # Pure utility functions
└── {auth-lib}.ts           # Auth configuration
types/
└── index.ts                # Shared types and interfaces
\```

### Step 3: Generate (in this exact order)

1. **Config** -- package.json, next.config, tsconfig, tailwind.config, postcss.config
   Read `references/architecture.md` for config templates.

2. **Root layout + Global** -- app/layout.tsx, globals.css, app/loading.tsx, app/error.tsx, app/not-found.tsx
   Read `references/routing.md` + `references/ui-styling.md` for root setup.

3. **Shared layer**
   - `lib/` -- data access functions, utils, auth config
   - `components/ui/` -- base UI components
   - `components/shared/` -- cross-feature components
   - `types/` -- shared types and interfaces
   Read `references/components.md` + `references/ui-styling.md` + `references/conventions.md`

4. **Auth** (if needed)
   - Auth configuration, middleware, login/register pages
   Read `references/auth-middleware.md`

5. **Layouts** -- dashboard layout, route group layouts
   Read `references/routing.md` + `references/components.md`

6. **Core features** -- for each feature, build the full vertical slice:
   - Data access: `lib/data/{resource}.ts`
   - Server actions: `lib/actions/{resource}.ts` (or `actions/{resource}.ts`)
   - Validation schemas: `lib/schemas/{resource}.ts`
   - Pages: `app/(dashboard)/{feature}/page.tsx`, `[id]/page.tsx`, etc.
   - Components: `components/{feature}/` -- list, detail, form, card
   - Loading/Error: `loading.tsx`, `error.tsx` per route
   Read `references/data-fetching.md` + `references/server-actions.md` + `references/forms.md` + `references/components.md`

7. **API routes** (if needed) -- route handlers for external consumption
   Read `references/api-routes.md`

8. **Middleware** -- auth redirects, headers, request interception
   Read `references/auth-middleware.md`

9. **Landing page + metadata** -- app/page.tsx, metadata exports
   Read `references/ui-styling.md` + `references/conventions.md`

### Step 4: Validate (MANDATORY feedback loop)
After generating, run this checklist:

\```
Validation:
- [ ] All imports resolve (no missing files, correct path aliases)
- [ ] Every Server Component is async when fetching data
- [ ] Every interactive component has 'use client' directive
- [ ] No hooks in Server Components (useState, useEffect, etc.)
- [ ] Every server action file has 'use server' directive
- [ ] Every form validates input with Zod
- [ ] Server actions validate input before processing
- [ ] All mutations revalidate the correct paths/tags
- [ ] Every dynamic route has proper params typing
- [ ] Loading.tsx present at each route level
- [ ] Error.tsx present at feature boundaries
- [ ] Metadata exported from all public pages
- [ ] Middleware protects appropriate routes
- [ ] Naming matches conventions (Read references/conventions.md)
- [ ] Code style matches coding-style.md (declarations, exports, etc.)
- [ ] No raw HTML divs for layout (use layout primitives or Tailwind patterns)
- [ ] Environment variables use NEXT_PUBLIC_ prefix for client-side vars
- [ ] Error handling follows error-handling.md patterns
\```

Fix any issues found, then re-validate.
```

### Section 3: Reference pointers

```markdown
## References

| File | Read when |
|------|-----------|
| `references/architecture.md` | Planning structure, creating config files |
| `references/routing.md` | Setting up routes, layouts, loading/error states |
| `references/components.md` | Building any component (server vs client decision) |
| `references/data-fetching.md` | Fetching data server-side or client-side |
| `references/server-actions.md` | Creating mutations, form actions, revalidation |
| `references/api-routes.md` | Building route handlers or middleware |
| `references/state.md` | Managing client state, URL state, cookies |
| `references/forms.md` | Building forms with validation |
| `references/auth-middleware.md` | Setting up auth, middleware, protected routes |
| `references/ui-styling.md` | Styling, theming, fonts, images, layout primitives |
| `references/conventions.md` | Naming anything (files, variables, folders) |
| `references/coding-style.md` | Writing any code -- ensures style matches the original team |
| `references/testing.md` | Creating tests for components, actions, or pages |
| `references/error-handling.md` | Adding error.tsx, loading.tsx, not-found.tsx, toasts |
| `references/performance.md` | Streaming, ISR, image/font optimization, edge runtime |

**NOTE:** Additional reference files may exist for project-specific patterns (i18n, CMS, analytics, etc.). Check the references/ directory for the full list.
```

### Section 4: Critical rules (non-negotiable, extracted from scan)

```markdown
## Rules

{Extract from scanned project. Examples:}
- EVERY component is a Server Component by default -- only add 'use client' when interactivity is needed
- NEVER fetch data in Client Components when a Server Component can do it
- EVERY server action validates input with Zod before processing
- EVERY mutation calls revalidatePath or revalidateTag after success
- EVERY dynamic route page types params as Promise<{ param: string }> (Next.js 15+)
- EVERY public page exports metadata or generateMetadata
- NEVER use TypeScript enums -- use `const {} as const` + type extraction
- ALWAYS use next/image for images, never raw <img> tags
- ALWAYS use next/link for internal navigation, never raw <a> tags
- ALWAYS use next/font for fonts, never external stylesheet links
- Error boundaries (error.tsx) at every feature route boundary
- Loading states (loading.tsx) at every route segment
```

---

## Reference File Guidelines

Each reference file must:

1. **Be under 300 lines** (add TOC if over 100 lines)
2. **Lead with code examples** -- prose only to explain WHY
3. **Use `{placeholders}`** -- `{Entity}`, `{Resource}`, `{feature-name}`
4. **Include Do/Don't** -- show the anti-pattern next to the correct pattern
5. **Contain BOTH layers** -- architectural (agnostic) + implementation (Next.js-specific)
6. **One concern = one file.** Create a separate file for every distinct pattern category. If a section exceeds 80 lines, split it into its own file. A complex project should produce 15-20+ reference files

**Example structure for a reference file:**

```markdown
# Data Fetching Patterns

## Contents
- Server-Side Fetch
- Data Access Layer
- Client-Side Fetching
- Caching Strategy

## Server-Side Fetch

### Architecture
- Data fetched at route level (page.tsx), never in leaf components
- Typed data access functions per entity
- Cache strategy defined per data freshness requirement

### Implementation
\```typescript
// lib/data/{resource}.ts
export async function get{Resources}() {
  const res = await fetch(`${API_URL}/{resources}`, {
    next: { revalidate: 3600, tags: ['{resources}'] },
  });
  if (!res.ok) throw new Error('Failed to fetch {resources}');
  return res.json() as Promise<{Resource}[]>;
}
\```

### Don't
\```typescript
// Client Component fetching when Server Component would work
'use client';
export function {Resource}List() {
  const [items, setItems] = useState([]);
  useEffect(() => {
    fetch('/api/{resources}').then(r => r.json()).then(setItems);
  }, []);
  // ...
}
\```
```

---

## .context/ Generation

After generating the skill (SKILL.md + references/), also generate a `.context/` directory in the same output folder. This provides tool-agnostic compatibility for Cursor, Copilot, Windsurf, etc.

Read `<skill-path>/references/context-spec.md` for the exact format and templates.

The `.context/` files are **condensed summaries** of the references -- 50-100 lines each, no workflow instructions, framework-specific (no agnostic layer needed).

```
{project-name}-generator/
├── .context/
│   ├── index.md          # Overview + stack + key decisions
│   ├── architecture.md   # Directory structure + routing + feature organization
│   ├── conventions.md    # Naming table + do/don't rules
│   ├── patterns.md       # Data fetching + server actions + forms + state templates
│   └── style.md          # Coding style profile (declarations, exports, async, etc.)
├── SKILL.md
└── references/
    └── ...
```
