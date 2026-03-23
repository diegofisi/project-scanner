---
name: python-fastapi-project-scanner
description: >
  Scans any Python FastAPI backend project to extract its complete architecture, patterns,
  coding style, and conventions — then generates an autonomous skill that creates new projects
  following those exact patterns. Optionally uses Repomix to pack the codebase first. Also
  generates a .context/ directory for tool-agnostic compatibility (Cursor, Copilot, etc.).
  Use this skill whenever someone wants to analyze a FastAPI codebase and turn its patterns into
  a reusable generator, capture coding standards from an existing backend, create a "project
  template" based on a real codebase, or replicate an architecture for a new API. Triggers:
  "scan my project", "extract patterns", "create a generator from this code", "turn this into
  a template", "make a skill from my app", "scan my FastAPI project", "analyze my backend".
---

# FastAPI Codebase Pattern Extractor

Scans a Python FastAPI project -> extracts architectural patterns in two layers (agnostic + framework-specific) -> generates a self-contained skill that creates new projects from a business idea.

## Workflow

```
1. PACK (optional) --> 2. SCAN --> 3. EXTRACT --> 4. GENERATE --> 5. VERIFY
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

If Repomix is NOT available, skip this phase -- the script in Phase 1 covers structure detection.

**When Repomix IS available:** Use the packed file as a quick reference to understand the full codebase before deep-diving into specific files. Don't rely on it exclusively -- you still need to read individual files for pattern extraction.

---

## Phase 1: Scan

### Step 1: Identify the project

Confirm which project to scan. Detect the framework stack from `pyproject.toml` or `requirements.txt` (look for `fastapi`, `sqlalchemy`, `pydantic`, etc.). Detect the project structure pattern: `app/` vs `src/` vs flat.

### Step 2: Run the structure scanner

```bash
bash <skill-path>/scripts/scan-structure.sh <project-path>
```

This outputs: directory tree, dependencies, config files, architecture pattern classification, and auto-selects 1 representative file per pattern category.

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
3. Classify as **architectural** (framework-agnostic) or **implementation** (FastAPI/Python-specific)
4. Note any **inconsistencies** (files that don't follow the majority pattern)

**Example -- extracting a repository pattern:**

```
ARCHITECTURAL (agnostic):
  - Each domain entity has a dedicated repository class
  - Repositories accept a database session via constructor injection
  - Repositories handle only data access -- no business logic
  - Standard CRUD methods: get, get_multi, create, update, delete

IMPLEMENTATION (FastAPI-specific):
  - Repositories use AsyncSession from sqlalchemy.ext.asyncio
  - Session injected via Depends(get_db) in the router, passed to service, then to repo
  - Queries use SQLAlchemy 2.0 select() style
  - Pagination via offset/limit with total count

INCONSISTENCY:
  - app/modules/reports/ queries the database directly in the router -- legacy, do NOT replicate
```

### Step 5: Decision log

For each major pattern, document WHY the team chose it over alternatives:

```
DECISIONS:
  - SQLAlchemy over Tortoise ORM -> async support + mature ecosystem (seen: full async session usage)
  - Pydantic v2 over v1 -> better perf, model_validator (seen: ConfigDict, field_validator usage)
  - Poetry over pip -> lockfile + dependency groups (seen: pyproject.toml with [tool.poetry])
  - Repository pattern -> testable data access (seen: repos injected into services, mocked in tests)
  - Alembic over manual -> versioned migrations (seen: alembic/ directory with env.py)
```

Look for evidence in: comments, README, PR descriptions, commit messages, pyproject.toml metadata, and the absence of alternatives in dependencies.

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
    ├── api-design.md                # Router patterns, endpoint conventions, dependencies, responses
    ├── models-schemas.md            # SQLAlchemy models, Pydantic schemas, Create/Read/Update pattern
    ├── database.md                  # Session management, repository pattern, queries, migrations
    ├── auth.md                      # JWT flow, OAuth2, permission dependencies, RBAC
    ├── services.md                  # Service layer, business logic, transaction management
    ├── error-handling.md            # Exception hierarchy, error responses, validation errors
    ├── middleware.md                 # CORS, logging, request context, custom middleware
    ├── conventions.md               # Naming table, file organization, import rules, enum patterns
    ├── coding-style.md              # Type hints, docstrings, async patterns, f-strings, comprehensions
    ├── testing.md                   # pytest, fixtures, AsyncClient, factories, mocking, conftest
    └── performance.md               # Caching, connection pooling, background tasks (if applicable)
```

This is the minimum set. Create additional reference files for any project-specific patterns found (WebSocket, Celery workers, file uploads, rate limiting, email, etc.).

### Two-layer rule (every reference file)

Each reference file MUST contain both layers:

```markdown
## Database Session Management

### Architecture (framework-agnostic)
- Single async session factory configured at app startup
- Sessions scoped to request lifecycle
- Dependency injection provides session to route handlers
- Transactions managed at the service layer

### FastAPI Implementation
\```python
async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with async_session_factory() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise

@router.get("/{resource_name}")
async def get_{resource}(db: AsyncSession = Depends(get_db)):
    ...
\```
```

Two layers = works for the scanned framework and can be adapted to others (Django, Flask, Litestar).

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
│   └── style.md                     # Coding style profile: type hints, docstrings, async, imports
├── SKILL.md
└── references/
    └── ...
```

The `.context/` files are a **condensed, prose-friendly** version of the skill references -- designed for tools that read markdown context but don't understand skill workflows.

---

## Phase 4: Write the generated SKILL.md

The generated SKILL.md must follow this pipeline:

### Step 1: Refine the idea (ASK the user)
- Core features (3-5 main things the API does)
- User roles (admin, user, guest, service-to-service)
- Data models (main entities + relationships)
- API endpoints per entity (CRUD? custom actions? batch operations?)
- Auth requirements (JWT, API key, OAuth2, none)
- Background tasks needed?

Present a summary table and confirm before proceeding.

### Step 2: Plan architecture
Map features to the project's module structure. Output a directory tree.

### Step 3: Generate in order
```
pyproject.toml/requirements.txt -> config/settings -> database setup + models -> alembic ->
schemas (Pydantic) -> repositories/services -> dependencies -> routers/endpoints ->
middleware -> auth -> main.py entry point
```

### Step 4: Validate (feedback loop)
```
Generate code -> Check imports resolve -> Check naming matches conventions ->
Check patterns match references -> Fix issues -> Repeat
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
- [ ] Generation order is explicit (config -> db -> models -> schemas -> repos -> services -> routers -> main)
- [ ] .context/ directory generated with index.md, architecture.md, conventions.md, patterns.md, style.md
- [ ] coding-style.md captures the team's personal Python style (not just patterns)
- [ ] testing.md captures pytest fixtures, mocking strategy, and test templates
- [ ] error-handling.md captures exception hierarchy, error responses, validation error formatting
- [ ] auth.md captures the full JWT/OAuth2 flow if present
- [ ] database.md captures session management, repository pattern, migration workflow
- [ ] Inconsistencies documented -- generated skill follows the MAJORITY pattern
- [ ] Decision log included -- WHY each major tool/pattern was chosen
- [ ] Additional reference files created for any project-specific patterns (WebSocket, Celery, etc.)

---

## Key Principles

**Examples > prose.** A code snippet with `{placeholders}` teaches better than a paragraph of description.

**Only include what Claude can't infer.** Don't explain what Pydantic is. DO show your specific schema inheritance pattern with a real example.

**Appropriate freedom.** Exact scripts for fragile operations (directory structure, config files, alembic setup). High freedom for business logic and endpoint internals.

**Generic placeholders.** Replace `User` with `{Entity}`, `get_user` with `get_{entity}`, `/users` with `/{resource}`. Keep structural patterns intact.

**Two outputs, one scan.** The skill (SKILL.md + references/) is for Claude. The .context/ is for everything else. Same patterns, different format.
