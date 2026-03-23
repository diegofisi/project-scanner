---
name: nextjs-project-scanner
description: >
  Scans any Next.js project (App Router, Pages Router, or hybrid — versions 14, 15, 16+) to extract
  its complete architecture, patterns, coding style, and conventions — then generates an autonomous
  skill that creates new Next.js projects following those exact patterns. Optionally uses Repomix to
  pack the codebase first. Also generates a .context/ directory for tool-agnostic compatibility
  (Cursor, Copilot, etc.). Use this skill whenever someone wants to analyze a Next.js codebase and
  turn its patterns into a reusable generator, capture coding standards from an existing Next.js app,
  create a "project template" based on a real Next.js codebase, or replicate a Next.js architecture
  for a new business idea. Triggers: "scan my next.js project", "extract next patterns", "create a
  generator from this next app", "turn this next.js codebase into a template", "make a skill from my
  next app".
---

# Next.js Codebase Pattern Extractor

Scans a Next.js project -> extracts architectural patterns in two layers (agnostic + Next.js-specific) -> generates a self-contained skill that creates new projects from a business idea.

## Workflow

```
1. PACK (optional) --> 2. SCAN --> 3. EXTRACT --> 4. GENERATE --> 5. VERIFY
   Repomix               structure    two-layer       SKILL.md +      test with
   packed file            + deps       patterns        references/     sample idea
                                                       + .context/
                                    ↑
                          Large project or user request?
                          YES --> Parallel Extraction Mode
                                 (8 subagents + validator)
```

---

## Phase 0: Pack with Repomix (optional, recommended)

If `repomix` is available globally (`npx repomix --version`), use it to pack the codebase into a single file first.

```bash
npx repomix <project-path> --output <project-path>/repomix-output.txt
```

If Repomix is NOT available, skip this phase -- the script in Phase 1 covers structure detection.

**When Repomix IS available:** Use the packed file as a quick reference to understand the full codebase before deep-diving into specific files. Don't rely on it exclusively -- you still need to read individual files for pattern extraction.

---

## Phase 1: Scan

### Step 1: Identify the project

Confirm which project to scan. Detect the Next.js version from package.json. Determine routing strategy:
- **App Router**: `app/` directory exists (Next.js 13.4+)
- **Pages Router**: `pages/` directory exists
- **Hybrid**: both `app/` and `pages/` directories exist

### Step 2: Run the structure scanner

```bash
bash <skill-path>/scripts/scan-structure.sh <project-path>
```

This outputs: directory tree, dependencies, config files, routing strategy detection, server/client component analysis, API routes, middleware, and auto-selects representative files per pattern category.

### Step 3: Smart sampling

For each category the scanner identifies, select files using this strategy:

1. **Most complex file** -- the longest file in the category (most patterns visible)
2. **Most recent file** -- check `git log --oneline -1` per file (reflects current style, not legacy)
3. **Standard file** -- a typical CRUD file (the "happy path" example)

Result: full pattern range + current style (not legacy).

### Step 4: Deep extraction

Read `<skill-path>/references/scan-checklist.md` -- it defines exactly what to extract per category.

For each category:
1. Read 2-3 representative files (selected via smart sampling above)
2. Extract the pattern as a generic template with `{placeholders}`
3. Classify as **architectural** (framework-agnostic) or **implementation** (Next.js-specific)
4. Note any **inconsistencies** (files that don't follow the majority pattern)

**Example -- extracting a data-fetching pattern:**

```
ARCHITECTURAL (agnostic):
  - Server-side data fetching at the route level
  - Typed data access functions per entity
  - Cache strategy defined per data freshness need
  - Mutations via form-bound server actions

IMPLEMENTATION (Next.js-specific):
  - async Server Components call data functions directly
  - fetch() with { next: { revalidate: 3600 } } for ISR
  - 'use server' actions in separate files under actions/
  - revalidatePath('/dashboard') after mutations

INCONSISTENCY:
  - app/legacy-reports/ uses client-side useEffect fetching -- legacy, do NOT replicate
```

### Step 5: Decision log

For each major pattern, document WHY the team chose it over alternatives:

```
DECISIONS:
  - App Router over Pages Router -> server components by default, streaming, simpler data fetching
  - Server Actions over API routes for mutations -> collocated, type-safe, progressive enhancement
  - next-auth over custom JWT -> built-in session management, provider support
  - Prisma over raw SQL -> type-safe queries, schema as single source of truth
  - Parallel routes for modals -> URL-shareable modals, independent loading states
```

Look for evidence in: comments, README, PR descriptions, commit messages, and the absence of alternatives in dependencies.

---

## Parallel Extraction Mode (large projects / on demand)

**Activates when:**
- The scan output shows `LARGE_PROJECT: true` (>= 2000 source files), OR
- The user explicitly requests it ("use subagents", "parallel scan", "deep scan", "scan with agents")

**Why:** A single agent extracting patterns from a 5,000+ file project will exhaust its context window. Parallel extraction delegates each concern to a dedicated subagent with its own clean context, then a validator agent checks consistency.

### How it works

After running the scan script (Phase 1, Step 2), **instead of** doing Steps 3-5 in the current context, spawn subagents in parallel:

#### Extraction subagents (launch ALL in parallel)

| # | Agent | What it reads | What it produces |
|---|-------|---------------|------------------|
| 1 | **Architecture** | Directory tree, config files (next.config, tsconfig, eslint, middleware.ts), package.json | `references/architecture.md` |
| 2 | **Routing + Pages** | App Router structure (layout, page, loading, error, not-found), dynamic routes, route groups, parallel routes | `references/routing.md` |
| 3 | **Components** | 3 Server Components + 3 Client Components, 'use client' boundary analysis, composition patterns | `references/components.md` + `references/ui-styling.md` |
| 4 | **Data Fetching + Server Actions** | async Server Components, fetch() configs, 'use server' files, revalidation, ISR/SSG patterns | `references/data-fetching.md` + `references/server-actions.md` |
| 5 | **API Routes + Middleware** | route.ts handlers, middleware.ts, NextRequest/NextResponse patterns, auth middleware | `references/api-routes.md` + `references/auth-middleware.md` |
| 6 | **State + Forms** | Client state (Zustand/Redux), form components, validation schemas, server action form integration | `references/state.md` + `references/forms.md` |
| 7 | **Testing** | Test files, test utils, mocks, fixtures, component tests vs integration tests | `references/testing.md` + `references/error-handling.md` |
| 8 | **Coding Style** | 5 representative files across categories, scan output coding style signals section | `references/coding-style.md` + `references/conventions.md` |

**Each subagent receives:**
1. The scan output (file listings for its category only)
2. The relevant section from `<skill-path>/references/scan-checklist.md`
3. Instructions: read 2-3 files via smart sampling, extract two-layer patterns (architecture + implementation), note inconsistencies, produce the reference file(s)

**Prompt template for each subagent:**
```
You are extracting {CATEGORY} patterns from a Next.js project at {PROJECT_PATH}.

SCAN OUTPUT (your category):
{filtered scan output}

CHECKLIST (what to extract):
{relevant scan-checklist.md section}

INSTRUCTIONS:
1. Read 2-3 representative files using smart sampling (most complex, most recent, standard)
2. Extract patterns as generic templates with {placeholders}
3. Classify each as ARCHITECTURAL (agnostic) or IMPLEMENTATION (Next.js-specific)
4. Note inconsistencies (files that don't follow the majority)
5. Document WHY the team chose this pattern (decision log)
6. Output the reference file(s) in markdown format with both layers

Do NOT read files outside your category. Focus only on {CATEGORY}.
```

#### Validator agent (runs AFTER all extraction agents complete)

Once all 8 subagents return their reference files, spawn a **validator agent** that:

1. **Reads all generated reference files** together
2. **Cross-checks consistency:**
   - Server vs Client boundaries in `components.md` align with `data-fetching.md` and `state.md`
   - Naming conventions in `conventions.md` match patterns in all other files
   - Import paths in code examples are consistent with `architecture.md` structure
   - Server Actions patterns in `server-actions.md` align with form patterns in `forms.md`
   - Middleware patterns in `auth-middleware.md` are consistent with routing in `routing.md`
3. **Checks completeness:**
   - Every reference file has BOTH layers (architecture + implementation)
   - All code examples use `{placeholders}` not hardcoded names
   - No duplicate patterns across files (each concern in exactly one file)
   - Decision log entries present for major choices
4. **Produces a validation report:**
   - List of conflicts found (with file + line references)
   - List of missing patterns
   - Suggested fixes
5. **Applies fixes** to the reference files if conflicts are found

**Prompt template for the validator:**
```
You are validating the extracted patterns from a Next.js project.

REFERENCE FILES:
{all reference file contents}

SCAN OUTPUT SUMMARY:
{key metrics from scan: Next.js version, routing strategy, dependencies, file counts}

VALIDATE:
1. Cross-check Server/Client component boundaries are consistent across ALL files
2. Verify import paths match the architecture structure
3. Confirm every file has both ARCHITECTURAL and IMPLEMENTATION layers
4. Check for duplicate/conflicting patterns between files
5. Verify {placeholders} are used consistently (not hardcoded names)
6. Check Server Actions + data fetching + forms patterns are aligned
7. Check decision log entries exist for major tool/pattern choices

OUTPUT: A validation report with conflicts, missing items, and fixes applied.
```

### Manual activation

The user can also request parallel extraction on any project size:
- "scan with subagents" / "use parallel extraction" / "deep scan"
- "scan my project at /path --parallel"

When manually activated on a small project, it provides deeper coverage (more files read per category) even though the context window isn't at risk.

### Assembly

After the validator completes, the coordinator (main agent) uses the validated reference files to proceed with Phase 2 (Generate the Skill) as normal. The reference files are already produced -- the coordinator only needs to assemble the SKILL.md, .context/, and do final verification.

---

## Phase 2: Generate the Skill

Read `<skill-path>/references/skill-template.md` for the exact output structure.

Read `<skill-path>/references/output-structure.md` for the file organization of the generated skill.

### Generated skill structure

**One concern = one file.** Create a separate reference file for every distinct pattern category. Prefer focused files (50-150 lines) over large ones. If a section exceeds 80 lines, split it into its own file. A complex project should produce 15-20+ reference files.

```
{project-name}-generator/
├── SKILL.md                         # Main workflow (< 500 lines)
└── references/
    ├── architecture.md              # AGNOSTIC: structure, organization, decisions
    ├── routing.md                   # App Router/Pages Router, file conventions, dynamic routes
    ├── components.md                # Server vs Client components, composition, 'use client' boundaries
    ├── data-fetching.md             # Server fetch, client hooks, ISR, SSG, streaming
    ├── server-actions.md            # 'use server', form actions, revalidation
    ├── api-routes.md                # Route handlers, middleware, NextRequest/NextResponse
    ├── state.md                     # Client state library + server state approach
    ├── forms.md                     # Forms, validation, server action integration
    ├── auth-middleware.md           # Auth setup, middleware.ts, session, route protection
    ├── ui-styling.md                # CSS approach, next/font, next/image, theming
    ├── conventions.md               # Naming, file organization, enums, types
    ├── coding-style.md              # Arrow vs function, exports, async, comments, null handling
    ├── testing.md                   # Test runner, mocking, structure, custom render
    ├── error-handling.md            # error.tsx, loading.tsx, not-found.tsx, toasts, boundaries
    └── performance.md               # Streaming, Suspense, lazy loading, ISR, edge runtime
```

This is the minimum set. Create additional reference files for any project-specific patterns found (i18n, CMS integration, real-time, analytics, etc.).

### Two-layer rule (every reference file)

Each reference file MUST contain both layers:

```markdown
## Data Fetching

### Architecture (framework-agnostic)
- Data fetched at the route level, not in leaf components
- Typed data access functions per entity
- Cache strategy per data type (static, ISR, dynamic)
- Parallel data fetching where possible

### Next.js Implementation
\```typescript
// app/{resource}/page.tsx
export default async function {Resource}Page() {
  const items = await get{Resources}();
  return <{Resource}List items={items} />;
}

// lib/data/{resource}.ts
export async function get{Resources}() {
  const res = await fetch(`${API_URL}/{resources}`, {
    next: { revalidate: 3600 },
  });
  if (!res.ok) throw new Error('Failed to fetch {resources}');
  return res.json() as Promise<{Resource}[]>;
}
\```
```

Two layers = works for the scanned framework and can be adapted to others.

---

## Phase 3: Generate .context/ (tool-agnostic compatibility)

After generating the skill, also create a `.context/` directory following the Codebase Context Specification. This makes the extracted patterns usable by ANY AI tool (Cursor, Copilot, Windsurf, etc.), not just Claude.

Read `<skill-path>/references/context-spec.md` for the exact format.

### Generated .context/ structure

```
{project-name}-generator/
├── .context/
│   ├── index.md                     # Overview: architecture, stack, key decisions
│   ├── architecture.md              # Directory structure, routing, feature organization
│   ├── conventions.md               # Naming rules, patterns, do/don't examples
│   ├── patterns.md                  # Data fetching, server actions, forms, state, error handling
│   └── style.md                     # Coding style profile: declarations, exports, async, null handling
├── SKILL.md
└── references/
    └── ...
```

The `.context/` files are a **condensed, prose-friendly** version of the skill references -- designed for tools that read markdown context but don't understand skill workflows.

---

## Phase 4: Write the generated SKILL.md

The generated SKILL.md must follow this pipeline:

### Step 1: Refine the idea (ASK the user)
- Core features (3-5 main things users can do)
- User roles (admin, user, guest)
- Key pages/views
- Data models (main entities + relationships)
- API endpoints or server actions needed per entity

Present a summary table and confirm before proceeding.

### Step 2: Plan architecture
Map features to the project's directory structure. Output a directory tree.

### Step 3: Generate in order
```
config files -> shared/lib -> shared/components -> auth -> layouts -> core features -> API routes -> middleware -> entry point
```

### Step 4: Validate (feedback loop)
```
Generate code -> Check imports resolve -> Check naming matches conventions -> Check patterns match references -> Check server/client boundaries correct -> Fix issues -> Repeat
```

The generated skill MUST include this validation loop. Without it, generated code will have broken imports, missing 'use client' directives, and inconsistent patterns.

---

## Phase 5: Verify

Before delivering, validate with this test: given the prompt "I want a task management app", the generated skill must produce a project indistinguishable from the original team's code.

Check:
- [ ] SKILL.md under 500 lines
- [ ] All references one level deep (no nested references)
- [ ] Description in third person with trigger phrases
- [ ] Every reference has BOTH architectural + implementation layers
- [ ] Code examples use `{placeholders}` not hardcoded names
- [ ] Validation feedback loop included
- [ ] Generation order is explicit
- [ ] .context/ directory generated with index.md, architecture.md, conventions.md, patterns.md, style.md
- [ ] coding-style.md captures the team's personal style (not just patterns)
- [ ] testing.md captures test runner, mocking strategy, and test templates
- [ ] error-handling.md captures error.tsx, loading.tsx, not-found.tsx, and toast patterns
- [ ] Server vs Client component boundaries documented with decision criteria
- [ ] Server Actions patterns captured (if used)
- [ ] Route handler patterns captured (if used)
- [ ] Middleware patterns captured (if used)
- [ ] Metadata/SEO patterns documented
- [ ] Inconsistencies documented -- generated skill follows the MAJORITY pattern
- [ ] Decision log included -- WHY each major tool/pattern was chosen
- [ ] Additional reference files created for any project-specific patterns (i18n, CMS, analytics, etc.)

---

## Key Principles

**Examples > prose.** A code snippet with `{placeholders}` teaches better than a paragraph of description.

**Only include what Claude can't infer.** Don't explain what Server Components are. DO show your specific server/client boundary pattern with a real example.

**Appropriate freedom.** Exact scripts for fragile operations (directory structure, config files, middleware). High freedom for component internals and business logic.

**Generic placeholders.** Replace `TaskCard` with `{Entity}Card`, `getUsers` with `get{Resources}`, `/dashboard` with `/{route}`. Keep structural patterns intact.

**Two outputs, one scan.** The skill (SKILL.md + references/) is for Claude. The .context/ is for everything else. Same patterns, different format.
