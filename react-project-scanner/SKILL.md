---
name: react-project-scanner
description: >
  Scans any frontend project (React, Vue, Angular, Svelte, or vanilla) to extract its complete
  architecture, patterns, coding style, and conventions — then generates an autonomous skill
  that creates new projects following those exact patterns. Optionally uses Repomix to pack the
  codebase first. Also generates a .context/ directory for tool-agnostic compatibility (Cursor,
  Copilot, etc.). Use this skill whenever someone wants to analyze a codebase and turn its
  patterns into a reusable generator, capture coding standards from an existing app, create a
  "project template" based on a real codebase, or replicate an architecture for a new business
  idea. Triggers: "scan my project", "extract patterns", "create a generator from this code",
  "turn this into a template", "make a skill from my app".
---

# Codebase Pattern Extractor

Scans a frontend project → extracts architectural patterns in two layers (agnostic + framework-specific) → generates a self-contained skill that creates new projects from a business idea.

## Workflow

```
1. PACK (optional) ──→ 2. SCAN ──→ 3. EXTRACT ──→ 4. GENERATE ──→ 5. VERIFY
   Repomix               structure    two-layer       SKILL.md +      test with
   packed file            + deps       patterns        references/     sample idea
                                                       + .context/
```

---

## Phase 0: Pack with Repomix (optional, recommended)

If `repomix` is available globally (`npx repomix --version`), use it to pack the codebase into a single file first.

```bash
npx repomix <project-path> --output <project-path>/repomix-output.txt
```

If Repomix is NOT available, skip this phase — the script in Phase 1 covers structure detection.

**When Repomix IS available:** Use the packed file as a quick reference to understand the full codebase before deep-diving into specific files. Don't rely on it exclusively — you still need to read individual files for pattern extraction.

---

## Phase 1: Scan

### Step 1: Identify the project

Confirm which project to scan. Detect the framework from package.json (`react`, `vue`, `@angular/core`, `svelte`).

### Step 2: Run the structure scanner

```bash
bash <skill-path>/scripts/scan-structure.sh <project-path>
```

This outputs: directory tree, dependencies, config files, and auto-selects 1 representative file per pattern category.

### Step 3: Smart sampling

For each category the scanner identifies, select files using this strategy:

1. **Most complex file** — the longest file in the category (most patterns visible)
2. **Most recent file** — check `git log --oneline -1` per file (reflects current style, not legacy)
3. **Standard file** — a typical CRUD file (the "happy path" example)

Result: full pattern range + current style (not legacy).

### Step 4: Deep extraction

Read `<skill-path>/references/scan-checklist.md` — it defines exactly what to extract per category.

For each category:
1. Read 2-3 representative files (selected via smart sampling above)
2. Extract the pattern as a generic template with `{placeholders}`
3. Classify as **architectural** (framework-agnostic) or **implementation** (framework-specific)
4. Note any **inconsistencies** (files that don't follow the majority pattern)

**Example — extracting a data-fetching pattern:**

```
ARCHITECTURAL (agnostic):
  - Each API endpoint gets its own folder
  - DTOs are separate from domain models
  - Mapper functions transform API → Domain
  - Queries use cache invalidation on mutations

IMPLEMENTATION (React-specific):
  - useQuery with `select` for DTO → Domain mapping
  - useMutation with `onSuccess` → queryClient.invalidateQueries
  - Query keys: ['resource', id, params]

INCONSISTENCY:
  - src/features/reports/ fetches directly — legacy, do NOT replicate
```

### Step 5: Decision log

For each major pattern, document WHY the team chose it over alternatives:

```
DECISIONS:
  - Zustand over Redux → simpler API, no boilerplate (seen: no reducers, no actions)
  - Zod over Yup → better TypeScript inference (seen: z.infer usage everywhere)
  - Barrel exports → clean imports from features (seen: index.ts in every feature)
  - No Context for state → only Zustand + React Query (seen: 0 createContext calls)
```

Look for evidence in: comments, README, PR descriptions, commit messages, and the absence of alternatives in dependencies.

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
    ├── data-layer.md                # API patterns, DTOs, mappers, caching
    ├── components.md                # Component patterns, composition, props, API design
    ├── state.md                     # Client + server state patterns
    ├── forms.md                     # Forms, validation, schemas
    ├── routing-auth.md              # Routes, guards, auth flow
    ├── ui-styling.md                # Layout primitives, theming, CSS approach
    ├── conventions.md               # Naming, file organization, enums, types
    ├── coding-style.md              # Arrow vs function, exports, async, comments, null handling
    ├── testing.md                   # Test runner, mocking, structure, custom render
    ├── error-handling.md            # Error boundaries, toasts, loading/empty states
    └── performance.md               # Memoization, lazy loading, virtualization (if applicable)
```

This is the minimum set. Create additional reference files for any project-specific patterns found (i18n, drag-and-drop, real-time, file uploads, complex permissions, etc.).

### Two-layer rule (every reference file)

Each reference file MUST contain both layers:

```markdown
## Data Fetching

### Architecture (framework-agnostic)
- One folder per endpoint: `api/{action-name}/`
- Separate DTO types from domain models
- Mapper functions: `toModel(dto) → DomainModel`
- Cache invalidation after mutations

### React Implementation
\```typescript
export function useGet{Resource}(id: string) {
  return useQuery<{Resource}DTO, Error, {Resource}>({
    queryKey: ['{resource}', id],
    queryFn: () => get{Resource}(id),
    select: to{Resource},
  });
}
\```

### Vue Implementation (if applicable)
\```typescript
export function useGet{Resource}(id: string) {
  return useQuery({ ... })  // @tanstack/vue-query
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
│   ├── architecture.md              # Directory structure, feature slices, separation of concerns
│   ├── conventions.md               # Naming rules, patterns, do/don't examples
│   ├── patterns.md                  # Data layer, forms, state, routing, error handling, testing
│   └── style.md                     # Coding style profile: declarations, exports, async, null handling
├── SKILL.md
└── references/
    └── ...
```

The `.context/` files are a **condensed, prose-friendly** version of the skill references — designed for tools that read markdown context but don't understand skill workflows.

---

## Phase 4: Write the generated SKILL.md

The generated SKILL.md must follow this pipeline:

### Step 1: Refine the idea (ASK the user)
- Core features (3-5 main things users can do)
- User roles (admin, user, guest)
- Key pages/views
- Data models (main entities + relationships)
- API endpoints needed per entity

### Step 2: Plan architecture
Map features to the project's feature-slice structure. Output a directory tree.

### Step 3: Generate in order
```
config files → shared/lib → shared/components → auth → core features → secondary features → routing → entry point
```

### Step 4: Validate (feedback loop)
```
Generate code → Check imports resolve → Check naming matches conventions → Check patterns match references → Fix issues → Repeat
```

The generated skill MUST include this validation loop. Without it, generated code will have broken imports and inconsistent patterns.

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
- [ ] error-handling.md captures error boundaries, toasts, loading/empty states
- [ ] Inconsistencies documented — generated skill follows the MAJORITY pattern
- [ ] Decision log included — WHY each major tool/pattern was chosen
- [ ] Additional reference files created for any project-specific patterns (i18n, real-time, etc.)

---

## Key Principles

**Examples > prose.** A code snippet with `{placeholders}` teaches better than a paragraph of description.

**Only include what Claude can't infer.** Don't explain what DTOs are. DO show your specific DTO → Domain mapper pattern with a real example.

**Appropriate freedom.** Exact scripts for fragile operations (directory structure, config files). High freedom for component internals and business logic.

**Generic placeholders.** Replace `FileNode` with `{Entity}`, `useGetFolderContents` with `useGet{Resource}`, `/folders` with `/{resource}`. Keep structural patterns intact.

**Two outputs, one scan.** The skill (SKILL.md + references/) is for Claude. The .context/ is for everything else. Same patterns, different format.
