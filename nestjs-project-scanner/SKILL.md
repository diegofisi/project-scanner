---
name: nestjs-project-scanner
description: >
  Scans any NestJS backend project to extract its complete architecture, patterns,
  coding style, and conventions — then generates an autonomous skill that creates new projects
  following those exact patterns. Optionally uses Repomix to pack the codebase first. Also
  generates a .context/ directory for tool-agnostic compatibility (Cursor, Copilot, etc.).
  Use this skill whenever someone wants to analyze a NestJS codebase and turn its patterns into
  a reusable generator, capture coding standards from an existing backend, create a "project
  template" based on a real codebase, or replicate an architecture for a new API. Triggers:
  "scan my project", "extract patterns", "create a generator from this code", "turn this into
  a template", "make a skill from my app", "scan my NestJS project", "analyze my backend",
  "scan my Nest API".
---

# NestJS Codebase Pattern Extractor

Scans a NestJS project → extracts architectural patterns in two layers (agnostic + framework-specific) → generates a self-contained skill that creates new projects from a business idea.

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

Confirm which project to scan. Detect the framework from package.json (`@nestjs/core`, `@nestjs/common`). Identify NestJS-specific patterns: modules, controllers, services, providers, guards, interceptors, pipes.

### Step 2: Run the structure scanner

```bash
bash <skill-path>/scripts/scan-structure.sh <project-path>
```

This outputs: directory tree, dependencies, config files, architecture pattern classification, and auto-selects 1 representative file per pattern category.

### Step 3: Smart sampling

For each category the scanner identifies, select files using this strategy:

1. **Most complex file** — the longest file in the category (most patterns visible)
2. **Most recent file** — check `git log --oneline -1` per file (reflects current style, not legacy)
3. **Standard file** — a typical CRUD module (the "happy path" example)

Result: full pattern range + current style (not legacy).

### Step 4: Deep extraction

Read `<skill-path>/references/scan-checklist.md` — it defines exactly what to extract per category.

For each category:
1. Read 2-3 representative files (selected via smart sampling above)
2. Extract the pattern as a generic template with `{placeholders}`
3. Classify as **architectural** (framework-agnostic) or **implementation** (NestJS-specific)
4. Note any **inconsistencies** (files that don't follow the majority pattern)

**Example — extracting a module pattern:**

```
ARCHITECTURAL (agnostic):
  - Each domain entity has its own module with bounded dependencies
  - Modules declare which providers are exported to other modules
  - Cross-module communication via exported services only
  - Circular dependencies resolved via forwardRef

IMPLEMENTATION (NestJS-specific):
  - @Module() decorator with imports, controllers, providers, exports
  - Dynamic modules via forRoot/forRootAsync for configurable providers
  - Global modules via @Global() for cross-cutting concerns (config, logging)
  - Module registration order in AppModule

INCONSISTENCY:
  - src/legacy/ module imports services directly without module exports
    → AVOID: always export services from their module
```

### Step 5: Decision log

For each major pattern, document WHY the team chose it over alternatives:

```
DECISIONS:
  - NestJS over Express → structured DI, decorators, module system (seen: extensive decorator usage)
  - TypeORM over Prisma → mature NestJS integration, entity decorators (seen: @Entity throughout)
  - class-validator over Zod → native NestJS pipe integration (seen: ValidationPipe global)
  - CQRS pattern → command/query separation (seen: @nestjs/cqrs in deps)
  - Microservices → event-driven via RabbitMQ (seen: @nestjs/microservices)
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
| 1 | **Architecture** | Directory tree, AppModule, config files, project structure, module graph | `references/architecture.md` |
| 2 | **Modules + Controllers** | @Module declarations, @Controller endpoints, route decorators, DTOs, pipes | `references/modules-controllers.md` |
| 3 | **Providers + DI** | @Injectable services, custom providers, injection tokens, factories, scopes | `references/providers-di.md` |
| 4 | **Database** | TypeORM/Prisma/Mongoose entities, repositories, migrations, QueryBuilder, transactions | `references/database.md` |
| 5 | **Auth + Guards** | JWT/Passport strategies, @UseGuards, custom decorators, RBAC, middleware | `references/auth.md` + `references/guards-interceptors.md` |
| 6 | **Validation + Pipes** | class-validator DTOs, ValidationPipe config, custom pipes, transformers | `references/validation.md` |
| 7 | **Testing** | *.spec.ts files, Test.createTestingModule, mock providers, e2e tests | `references/testing.md` + `references/error-handling.md` |
| 8 | **Coding Style** | 5 representative files across categories, scan output coding style signals | `references/coding-style.md` + `references/conventions.md` |

**Each subagent receives:**
1. The scan output (file listings for its category only)
2. The relevant section from `<skill-path>/references/scan-checklist.md`
3. Instructions: read 2-3 files via smart sampling, extract two-layer patterns (architecture + implementation), note inconsistencies, produce the reference file(s)

**Prompt template for each subagent:**
```
You are extracting {CATEGORY} patterns from a NestJS project at {PROJECT_PATH}.

SCAN OUTPUT (your category):
{filtered scan output}

CHECKLIST (what to extract):
{relevant scan-checklist.md section}

INSTRUCTIONS:
1. Read 2-3 representative files using smart sampling (most complex, most recent, standard)
2. Extract patterns as generic templates with {placeholders}
3. Classify each as ARCHITECTURAL (agnostic) or IMPLEMENTATION (NestJS-specific)
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
   - Module imports/exports in `architecture.md` are consistent with provider patterns in `providers-di.md`
   - DTOs in `validation.md` align with controller endpoints in `modules-controllers.md`
   - Entity definitions in `database.md` match DTO field patterns in `validation.md`
   - Guard usage in `auth.md` is consistent with controller decorators in `modules-controllers.md`
   - Exception filters in `error-handling.md` align with service throw patterns
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
You are validating the extracted patterns from a NestJS project.

REFERENCE FILES:
{all reference file contents}

SCAN OUTPUT SUMMARY:
{key metrics from scan: NestJS version, ORM, dependencies, file counts}

VALIDATE:
1. Cross-check module dependency graph: imports, exports, providers consistency
2. Verify DI tokens and injection patterns are consistent
3. Confirm every file has both ARCHITECTURAL and IMPLEMENTATION layers
4. Check DTOs match entity fields (types, decorators, validators)
5. Verify {placeholders} are used consistently (not hardcoded names)
6. Check guard/interceptor usage is consistent across controllers
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
    ├── architecture.md              # AGNOSTIC: structure, module graph, decisions
    ├── modules-controllers.md       # @Module, @Controller, endpoint decorators, route patterns
    ├── providers-di.md              # @Injectable, custom providers, injection tokens, scopes
    ├── database.md                  # Entities, repositories, TypeORM/Prisma, migrations, QueryBuilder
    ├── validation.md                # DTOs, class-validator, ValidationPipe, custom pipes
    ├── auth.md                      # JWT/Passport strategies, guards, RBAC, custom decorators
    ├── guards-interceptors.md       # Guards, interceptors, exception filters, middleware
    ├── services.md                  # Service layer patterns, business logic, transactions
    ├── error-handling.md            # Exception filters, HttpException, custom exceptions
    ├── conventions.md               # Naming table, file organization, decorator usage, barrel exports
    ├── coding-style.md              # Decorators, DI patterns, async, comments, type usage
    ├── testing.md                   # Test.createTestingModule, mock providers, e2e, supertest
    └── performance.md               # Caching (@CacheKey), lazy modules, clustering (if applicable)
```

This is the minimum set. Create additional reference files for any project-specific patterns found (WebSocket gateways, microservices, CQRS, GraphQL resolvers, Swagger, health checks, etc.).

### Two-layer rule (every reference file)

Each reference file MUST contain both layers:

```markdown
## Controller Pattern

### Architecture (framework-agnostic)
- One controller per resource, handling HTTP concerns only
- Route-level guards for authorization
- Input validation via pipes before handler execution
- Business logic delegated to service layer

### NestJS Implementation
\```typescript
@Controller('{resources}')
@UseGuards(JwtAuthGuard)
export class {Entity}Controller {
  constructor(private readonly {entity}Service: {Entity}Service) {}

  @Get()
  findAll(@Query() query: Paginated{Entity}QueryDto) {
    return this.{entity}Service.findAll(query);
  }

  @Get(':id')
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.{entity}Service.findOne(id);
  }

  @Post()
  @UseGuards(RolesGuard)
  @Roles(Role.ADMIN)
  create(@Body() dto: Create{Entity}Dto) {
    return this.{entity}Service.create(dto);
  }
}
\```
```

Two layers = works for the scanned framework and can be adapted to others (Express, Fastify, Spring Boot).

---

## Phase 3: Generate .context/ (tool-agnostic compatibility)

After generating the skill, also create a `.context/` directory following the Codebase Context Specification. This makes the extracted patterns usable by ANY AI tool (Cursor, Copilot, Windsurf, etc.), not just Claude.

Read `<skill-path>/references/context-spec.md` for the exact format.

### Generated .context/ structure

```
{project-name}-generator/
├── .context/
│   ├── index.md                     # Overview: architecture, stack, key decisions
│   ├── architecture.md              # Module graph, directory structure, layer separation
│   ├── conventions.md               # Naming rules, decorator patterns, do/don't examples
│   ├── patterns.md                  # Controllers, services, DI, validation, auth, testing
│   └── style.md                     # Coding style profile: decorators, types, async, imports
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
- Auth requirements (JWT, API key, OAuth2, none)
- Microservices? CQRS? GraphQL?

Present a summary table and confirm before proceeding.

### Step 2: Plan architecture
Map features to NestJS modules. Output a module dependency tree.

### Step 3: Generate in order
```
nest-cli.json + tsconfig → config module → database module + entities/migrations →
DTOs + validation → repositories/services → guards + interceptors →
controllers → module declarations → auth module → app.module.ts → main.ts bootstrap
```

### Step 4: Validate (feedback loop)
```
Generate code → Check module imports/exports → Check DI providers →
Check naming matches conventions → Check patterns match references →
Fix issues → Repeat
```

The generated skill MUST include this validation loop. Without it, generated code will have broken DI and inconsistent module boundaries.

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
- [ ] Generation order is explicit (config → db → entities → DTOs → services → controllers → modules → app)
- [ ] .context/ directory generated with index.md, architecture.md, conventions.md, patterns.md, style.md
- [ ] coding-style.md captures the team's decorator and DI style (not just patterns)
- [ ] testing.md captures Test.createTestingModule, mock providers, e2e test templates
- [ ] error-handling.md captures exception filters, HttpException hierarchy, error responses
- [ ] auth.md captures the full JWT/Passport/Guard flow if present
- [ ] database.md captures entity definitions, repository patterns, migration workflow
- [ ] Inconsistencies documented — generated skill follows the MAJORITY pattern
- [ ] Decision log included — WHY each major tool/pattern was chosen
- [ ] Additional reference files for NestJS-specific patterns (CQRS, microservices, GraphQL, etc.)

---

## Key Principles

**Examples > prose.** A code snippet with `{placeholders}` teaches better than a paragraph of description.

**Only include what Claude can't infer.** Don't explain what NestJS decorators are. DO show your specific module + controller + service pattern with a real example.

**Appropriate freedom.** Exact scripts for fragile operations (module declarations, DI setup, guard configuration). High freedom for business logic and endpoint internals.

**Generic placeholders.** Replace `User` with `{Entity}`, `UserService` with `{Entity}Service`, `/users` with `/{resources}`. Keep structural patterns intact.

**Two outputs, one scan.** The skill (SKILL.md + references/) is for Claude. The .context/ is for everything else. Same patterns, different format.
