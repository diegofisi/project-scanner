---
name: express-project-scanner
description: >
  Scans any Node.js Express backend project to extract its complete architecture, patterns,
  coding style, and conventions — then generates an autonomous skill that creates new projects
  following those exact patterns. Optionally uses Repomix to pack the codebase first. Also
  generates a .context/ directory for tool-agnostic compatibility (Cursor, Copilot, etc.).
  Use this skill whenever someone wants to analyze an Express codebase and turn its patterns into
  a reusable generator, capture coding standards from an existing backend, create a "project
  template" based on a real codebase, or replicate an architecture for a new API. Triggers:
  "scan my project", "extract patterns", "create a generator from this code", "turn this into
  a template", "make a skill from my app", "scan my Express project", "analyze my backend",
  "scan my Node.js API".
---

# Express Codebase Pattern Extractor

Scans a Node.js Express project → extracts architectural patterns in two layers (agnostic + framework-specific) → generates a self-contained skill that creates new projects from a business idea.

## Workflow

```
1. PACK (optional) ──→ 2. SCAN ──→ 3. EXTRACT ──→ 4. GENERATE ──→ 5. VERIFY
   Repomix               structure    two-layer       SKILL.md +      test with
   packed file            + deps       patterns        references/     sample idea
                                                       + .context/
                                    ↑
                          Large project or user request?
                          YES → Parallel Extraction Mode
                                (8 subagents + validator)
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

Confirm which project to scan. Detect the framework from package.json (`express`, `koa`, `hapi`, `fastify`). Detect the language (TypeScript vs JavaScript). Detect the project structure pattern: `src/` vs flat.

### Step 2: Run the structure scanner

```bash
bash <skill-path>/scripts/scan-structure.sh <project-path>
```

This outputs: directory tree, dependencies, config files, architecture pattern classification, and auto-selects 1 representative file per pattern category.

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
3. Classify as **architectural** (framework-agnostic) or **implementation** (Express/Node-specific)
4. Note any **inconsistencies** (files that don't follow the majority pattern)

**Example — extracting a controller pattern:**

```
ARCHITECTURAL (agnostic):
  - Each resource has a dedicated controller file
  - Controllers receive service instances (dependency injection or module import)
  - Controllers handle only HTTP concerns — no business logic
  - Standard CRUD methods: getAll, getById, create, update, delete

IMPLEMENTATION (Express-specific):
  - Controllers are classes/objects with methods receiving (req, res, next)
  - Error handling via next(error) or async wrapper
  - Response formatting: res.status(201).json({ data })
  - Input validation via middleware (Joi/Zod/express-validator)

INCONSISTENCY:
  - src/routes/legacy-reports.js — business logic directly in route handler
    → AVOID: always use controller + service pattern
```

### Step 5: Decision log

For each major pattern, document WHY the team chose it over alternatives:

```
DECISIONS:
  - Express over Fastify → mature ecosystem, team familiarity (seen: extensive middleware usage)
  - Prisma over Sequelize → type-safe queries, simpler migrations (seen: prisma/ directory)
  - Zod over Joi → better TypeScript inference (seen: z.infer usage in DTOs)
  - Repository pattern → testable data access (seen: repos imported in services, mocked in tests)
  - JWT over sessions → stateless API (seen: no session middleware, JWT in auth middleware)
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
| 1 | **Architecture** | Directory tree, package.json, tsconfig, config files, project structure | `references/architecture.md` |
| 2 | **Routes + Controllers** | Route files, controller files, middleware chains, request/response patterns | `references/routes-controllers.md` |
| 3 | **Models + Validation** | ORM models (Prisma/Sequelize/TypeORM/Mongoose), DTOs, Zod/Joi schemas, validation middleware | `references/models-validation.md` |
| 4 | **Database** | Connection setup, query patterns, migrations, transactions, repositories | `references/database.md` |
| 5 | **Auth + Middleware** | JWT/session/OAuth flow, auth middleware, RBAC, CORS, logging, rate limiting, custom middleware | `references/auth.md` + `references/middleware.md` |
| 6 | **Services** | Service layer, business logic, external API calls, event emitters, background jobs | `references/services.md` |
| 7 | **Testing** | Test files, test utils, supertest setup, mocking, fixtures, factories | `references/testing.md` + `references/error-handling.md` |
| 8 | **Coding Style** | 5 representative files across categories, scan output coding style signals section | `references/coding-style.md` + `references/conventions.md` |

**Each subagent receives:**
1. The scan output (file listings for its category only)
2. The relevant section from `<skill-path>/references/scan-checklist.md`
3. Instructions: read 2-3 files via smart sampling, extract two-layer patterns (architecture + implementation), note inconsistencies, produce the reference file(s)

**Prompt template for each subagent:**
```
You are extracting {CATEGORY} patterns from a Node.js Express project at {PROJECT_PATH}.

SCAN OUTPUT (your category):
{filtered scan output}

CHECKLIST (what to extract):
{relevant scan-checklist.md section}

INSTRUCTIONS:
1. Read 2-3 representative files using smart sampling (most complex, most recent, standard)
2. Extract patterns as generic templates with {placeholders}
3. Classify each as ARCHITECTURAL (agnostic) or IMPLEMENTATION (Express/Node-specific)
4. Note inconsistencies (files that don't follow the majority)
5. Document WHY the team chose this pattern (decision log)
6. Output the reference file(s) in markdown format with both layers

Do NOT read files outside your category. Focus only on {CATEGORY}.
```

#### Validator agent (runs AFTER all extraction agents complete)

Once all 8 subagents return their reference files, spawn a **validator agent** that:

1. **Reads all generated reference files** together
2. **Cross-checks consistency:**
   - Naming conventions in `conventions.md` match patterns in all other files
   - Import paths in code examples are consistent with `architecture.md` structure
   - Validation schemas in `models-validation.md` align with controller request handling in `routes-controllers.md`
   - Repository/ORM patterns in `database.md` match how services consume them in `services.md`
   - Auth middleware in `auth.md` is consistent with how routes use them in `routes-controllers.md`
   - Error handling in `error-handling.md` aligns with controller/middleware exception patterns
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
You are validating the extracted patterns from a Node.js Express project.

REFERENCE FILES:
{all reference file contents}

SCAN OUTPUT SUMMARY:
{key metrics from scan: Express version, ORM, language, dependencies, file counts}

VALIDATE:
1. Cross-check data flow: Route → Controller → Service → Repository/Model is consistent
2. Verify import paths match the architecture structure
3. Confirm every file has both ARCHITECTURAL and IMPLEMENTATION layers
4. Check validation schemas match ORM model fields (types, constraints)
5. Verify {placeholders} are used consistently (not hardcoded names)
6. Check auth middleware injection is consistent across routes
7. Check decision log entries exist for major tool/pattern choices

OUTPUT: A validation report with conflicts, missing items, and fixes applied.
```

### Manual activation

The user can also request parallel extraction on any project size:
- "scan with subagents" / "use parallel extraction" / "deep scan"
- "scan my project at /path --parallel"

When manually activated on a small project, it provides deeper coverage (more files read per category) even though the context window isn't at risk.

### Assembly

After the validator completes, the coordinator (main agent) uses the validated reference files to proceed with Phase 2 (Generate the Skill) as normal. The reference files are already produced — the coordinator only needs to assemble the SKILL.md, .context/, and do final verification.

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
    ├── routes-controllers.md        # Route definitions, controller patterns, request/response
    ├── models-validation.md         # ORM models, DTOs, validation schemas (Zod/Joi)
    ├── database.md                  # Connection setup, queries, migrations, transactions
    ├── auth.md                      # JWT/session flow, auth middleware, RBAC
    ├── services.md                  # Service layer, business logic, external API calls
    ├── error-handling.md            # Error classes, error middleware, validation error formatting
    ├── middleware.md                 # CORS, logging, rate limiting, request context, custom middleware
    ├── conventions.md               # Naming table, file organization, import rules, enum patterns
    ├── coding-style.md              # Arrow vs function, exports, async, comments, null handling
    ├── testing.md                   # Test runner, supertest, mocking, fixtures, test structure
    └── performance.md               # Caching, clustering, connection pooling (if applicable)
```

This is the minimum set. Create additional reference files for any project-specific patterns found (WebSocket, queue workers, file uploads, rate limiting, email, GraphQL subscriptions, etc.).

### Two-layer rule (every reference file)

Each reference file MUST contain both layers:

```markdown
## Route + Controller Pattern

### Architecture (framework-agnostic)
- One route file per resource, mapping HTTP verbs to controller methods
- Controllers handle only request parsing and response formatting
- Input validation happens before the controller (middleware)
- Business logic delegated to service layer

### Express Implementation
\```typescript
// routes/{resource}.routes.ts
const router = Router();
router.get('/', validate(list{Resource}Schema), {resource}Controller.getAll);
router.get('/:id', validate(param{Resource}Schema), {resource}Controller.getById);
router.post('/', validate(create{Resource}Schema), {resource}Controller.create);
router.put('/:id', validate(update{Resource}Schema), {resource}Controller.update);
router.delete('/:id', validate(param{Resource}Schema), {resource}Controller.remove);
export default router;

// controllers/{resource}.controller.ts
export const {resource}Controller = {
  getAll: asyncHandler(async (req: Request, res: Response) => {
    const result = await {resource}Service.findAll(req.query);
    res.json({ data: result });
  }),
  create: asyncHandler(async (req: Request, res: Response) => {
    const result = await {resource}Service.create(req.body);
    res.status(201).json({ data: result });
  }),
};
\```
```

Two layers = works for the scanned framework and can be adapted to others (Fastify, Koa, Hapi).

---

## Phase 3: Generate .context/ (tool-agnostic compatibility)

After generating the skill, also create a `.context/` directory following the Codebase Context Specification. This makes the extracted patterns usable by ANY AI tool (Cursor, Copilot, Windsurf, etc.), not just Claude.

Read `<skill-path>/references/context-spec.md` for the exact format.

### Generated .context/ structure

```
{project-name}-generator/
├── .context/
│   ├── index.md                     # Overview: architecture, stack, key decisions
│   ├── architecture.md              # Directory structure, module boundaries, layer separation
│   ├── conventions.md               # Naming rules, patterns, do/don't examples
│   ├── patterns.md                  # API design, database, auth, services, error handling, testing
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
- Core features (3-5 main things the API does)
- User roles (admin, user, guest, service-to-service)
- Data models (main entities + relationships)
- API endpoints per entity (CRUD? custom actions? batch operations?)
- Auth requirements (JWT, API key, sessions, none)
- Background jobs needed?

Present a summary table and confirm before proceeding.

### Step 2: Plan architecture
Map features to the project's module/feature structure. Output a directory tree.

### Step 3: Generate in order
```
package.json + tsconfig → config/env → database setup + models/migrations →
validation schemas → repositories/services → middleware → controllers →
routes → auth → error handling → app.ts entry point → server.ts
```

### Step 4: Validate (feedback loop)
```
Generate code → Check imports resolve → Check naming matches conventions →
Check patterns match references → Fix issues → Repeat
```

The generated skill MUST include this validation loop. Without it, generated code will have broken imports and inconsistent patterns.

---

## Phase 5: Verify

Before delivering, validate with this test: given the prompt "I want a task management API", the generated skill must produce a project indistinguishable from the original team's code.

Check:
- [ ] SKILL.md under 500 lines
- [ ] All references one level deep (no nested references)
- [ ] Description in third person with trigger phrases
- [ ] Every reference has BOTH architectural + implementation layers
- [ ] Code examples use `{placeholders}` not hardcoded names
- [ ] Validation feedback loop included
- [ ] Generation order is explicit (config → db → models → schemas → services → controllers → routes → app)
- [ ] .context/ directory generated with index.md, architecture.md, conventions.md, patterns.md, style.md
- [ ] coding-style.md captures the team's personal style (not just patterns)
- [ ] testing.md captures test runner, mocking strategy, and test templates
- [ ] error-handling.md captures error classes, error middleware, validation formatting
- [ ] auth.md captures the full JWT/session flow if present
- [ ] database.md captures connection setup, ORM patterns, migration workflow
- [ ] Inconsistencies documented — generated skill follows the MAJORITY pattern
- [ ] Decision log included — WHY each major tool/pattern was chosen
- [ ] Additional reference files created for any project-specific patterns (WebSocket, queues, etc.)

---

## Key Principles

**Examples > prose.** A code snippet with `{placeholders}` teaches better than a paragraph of description.

**Only include what Claude can't infer.** Don't explain what Express middleware is. DO show your specific error middleware pattern with a real example.

**Appropriate freedom.** Exact scripts for fragile operations (directory structure, config files, database setup). High freedom for business logic and endpoint internals.

**Generic placeholders.** Replace `User` with `{Entity}`, `getUser` with `get{Entity}`, `/users` with `/{resource}`. Keep structural patterns intact.

**Two outputs, one scan.** The skill (SKILL.md + references/) is for Claude. The .context/ is for everything else. Same patterns, different format.
