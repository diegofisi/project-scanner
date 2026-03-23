# Generated Skill Template

Use this template to write the SKILL.md for the generated project-generator skill. Adapt based on what was actually found in the scanned project.

---

## Frontmatter

```yaml
---
name: {project-name}-generator
description: >
  Generates complete, production-ready {framework} projects following the {project-name}
  architecture. Given a business idea, refines it into features and produces a fully functional
  application with {key-stack-summary}. Triggers: "create a {framework} app", "build me a web app",
  "new project for...", "scaffold an app that...", or any request to create a frontend application
  from a concept or business idea.
---
```

Description must be in third person. Include specific trigger phrases.

---

## SKILL.md Body Structure

### Section 1: Overview (5-10 lines)

```markdown
# {ProjectName} Generator

Generates {framework} applications following a production-tested architecture.

## Stack
{framework} {version} + {build-tool} | {ui-library} | {state-client} + {state-server} | {form-lib} + {validation-lib} | {http-client} | {router} | {css-approach}
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
- What API operations per entity? (CRUD? custom?)

Present a summary table and confirm before proceeding.

### Step 2: Plan Architecture
Map features → feature slices. Output:

\```
src/
├── core/          # Core business logic ({list discovered core features})
│   └── {feature}/
│       ├── api/         # One folder per endpoint
│       ├── components/  # Presentational
│       ├── containers/  # Smart components
│       ├── helpers/     # Schemas, formatters, utils
│       ├── hooks/       # Custom hooks (non-API)
│       ├── models/      # Domain models
│       ├── stores/      # Client state
│       ├── pages/       # Page components
│       └── types/       # Additional types
├── features/      # Secondary features
│   └── {feature}/ # Same structure as core
├── shared/        # Framework-agnostic reusables
│   ├── components/{layout,ui}/
│   ├── lib/       # http-client, query-client, utils
│   ├── routes/    # Router setup + guards
│   ├── hooks/     # Shared hooks
│   ├── helpers/   # Pure utilities
│   └── types/     # Shared enums, interfaces
└── main.tsx       # Entry point
\```

### Step 3: Generate (in this exact order)

1. **Config** — package.json, vite.config, tsconfig, tailwind.config, index.html
   Read `references/architecture.md` for config templates.

2. **Entry + Global** — main.tsx, App.tsx, index.css
   Read `references/ui-styling.md` for theme variables.

3. **Shared layer**
   - `shared/lib/` — http-client, query-client, utils
   - `shared/components/ui/` — base UI components
   - `shared/components/layout/` — layout primitives
   - `shared/types/` — shared enums and types
   Read `references/ui-styling.md` + `references/conventions.md`

4. **Auth** (if needed)
   Read `references/routing-auth.md` for auth store, login, guards.

5. **Core features** — for each feature, build the full vertical slice
   Read `references/components.md` + `references/data-layer.md` + `references/forms.md` + `references/state.md`

6. **Secondary features** — same pattern, lower priority

7. **Routing** — wire all pages into router
   Read `references/routing-auth.md`

8. **Final wiring** — connect everything in App.tsx

### Step 4: Validate (MANDATORY feedback loop)
After generating, run this checklist:

\```
Validation:
- [ ] All imports resolve (no missing files)
- [ ] Every component follows container/presentational split
- [ ] Every API hook follows the DTO → mapper → domain model pattern
- [ ] Every form uses a separate .schema.ts file
- [ ] Naming matches conventions (Read references/conventions.md)
- [ ] All mutations invalidate the correct query keys
- [ ] Route guards protect appropriate routes
- [ ] No raw HTML divs (use layout primitives)
- [ ] No TypeScript enums (use const objects)
- [ ] Code style matches coding-style.md (arrow vs function, export style, etc.)
- [ ] Error handling follows error-handling.md (boundaries, toasts, loading states)
- [ ] Test files follow testing.md patterns (if tests are being generated)
\```

Fix any issues found, then re-validate.
```

### Section 3: Reference pointers

```markdown
## References

| File | Read when |
|------|-----------|
| `references/architecture.md` | Planning structure, creating config files |
| `references/data-layer.md` | Creating API hooks, DTOs, HTTP client |
| `references/components.md` | Building any component or container |
| `references/state.md` | Creating stores or managing client/server state |
| `references/forms.md` | Building forms with validation |
| `references/routing-auth.md` | Setting up routes, guards, or auth flow |
| `references/ui-styling.md` | Styling, theming, layout/typography primitives |
| `references/conventions.md` | Naming anything (files, variables, folders) |
| `references/coding-style.md` | Writing any code — ensures style matches the original team |
| `references/testing.md` | Creating tests for hooks, components, or pages |
| `references/error-handling.md` | Adding error boundaries, toasts, loading/empty states |
| `references/performance.md` | Optimizing components, lazy loading, virtualization |

**NOTE:** Additional reference files may exist for project-specific patterns (i18n, real-time, etc.). Check the references/ directory for the full list.
```

### Section 4: Critical rules (non-negotiable, extracted from scan)

```markdown
## Rules

{Extract from scanned project. Examples:}
- NEVER use raw HTML for layout — always Stack, Box, Grid
- NEVER use TypeScript enums — use `const {} as const` + type extraction
- EVERY API endpoint gets its own folder: `api/{action-name}/{action}.dto.ts` + `use{Action}.ts`
- EVERY form uses a Zod schema in a separate `.schema.ts` file
- Containers hold ALL hooks/logic; presentational components are pure props → JSX
- Mutations use `onSuccess`/`onError` callbacks, NEVER try/catch with mutateAsync
- Query keys follow: `['{resource}', id?, params?]`
- Toast notifications for all mutation feedback (success + error)
```

---

## Reference File Guidelines

Each reference file must:

1. **Be under 300 lines** (add TOC if over 100 lines)
2. **Lead with code examples** — prose only to explain WHY
3. **Use `{placeholders}`** — `{Entity}`, `{Resource}`, `{feature-name}`
4. **Include Do/Don't** — show the anti-pattern next to the correct pattern
5. **Contain BOTH layers** — architectural (agnostic) + implementation (framework-specific)
6. **One concern = one file.** Create a separate file for every distinct pattern category. If a section exceeds 80 lines, split it into its own file. A complex project should produce 15-20+ reference files

**Example structure for a reference file:**

```markdown
# Data Layer Patterns

## Contents
- HTTP Client Setup
- Query Hooks
- Mutation Hooks
- DTO & Mapper Pattern

## HTTP Client Setup

### Architecture
- Single configured instance with interceptors
- Request: inject auth token
- Response: unwrap API envelope, handle 401 with token refresh

### Implementation
\```typescript
export const httpClient = axios.create({ baseURL: BASE_URL });

httpClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('accessToken');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});
\```

## Query Hooks

### Architecture
- One file per query: `use{Action}.ts`
- DTO types + mapper in sibling `{action}.dto.ts`
- `select` transforms DTO → Domain at query level

### Implementation
\```typescript
export function useGet{Resource}(id: string) {
  return useQuery<{Resource}DTO, Error, {Resource}>({
    queryKey: ['{resource}', id],
    queryFn: () => get{Resource}(id),
    select: to{Resource},
    enabled: !!id,
  });
}
\```

### Don't
\```typescript
// ❌ Don't transform in the component
const { data } = useQuery({ queryKey: ['files'], queryFn: getFiles });
const mapped = data?.map(toFile); // Wrong place for transformation
\```
```

---

## .context/ Generation

After generating the skill (SKILL.md + references/), also generate a `.context/` directory in the same output folder. This provides tool-agnostic compatibility for Cursor, Copilot, Windsurf, etc.

Read `<skill-path>/references/context-spec.md` for the exact format and templates.

The `.context/` files are **condensed summaries** of the references — 50-100 lines each, no workflow instructions, framework-specific (no agnostic layer needed).

```
{project-name}-generator/
├── .context/
│   ├── index.md          # Overview + stack + key decisions
│   ├── architecture.md   # Directory structure + feature slice anatomy
│   ├── conventions.md    # Naming table + do/don't rules
│   ├── patterns.md       # Data layer + forms + state + routing templates
│   └── style.md          # Coding style profile (arrow vs function, exports, async, etc.)
├── SKILL.md
└── references/
    └── ...
```
