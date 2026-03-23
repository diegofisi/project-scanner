# Generated Skill Template

Use this template to write the SKILL.md for the generated project-generator skill. Adapt based on what was actually found in the scanned project.

---

## Frontmatter

```yaml
---
name: {project-name}-generator
description: >
  Generates complete, production-ready FastAPI backend projects following the {project-name}
  architecture. Given a business idea, refines it into features and produces a fully functional
  API with {key-stack-summary}. Triggers: "create a FastAPI app", "build me a backend",
  "new API project for...", "scaffold an API that...", or any request to create a backend
  application from a concept or business idea.
---
```

Description must be in third person. Include specific trigger phrases.

---

## SKILL.md Body Structure

### Section 1: Overview (5-10 lines)

```markdown
# {ProjectName} Generator

Generates FastAPI backend applications following a production-tested architecture.

## Stack
FastAPI {version} + {orm} | {validation-lib} | {auth-lib} | {task-queue} | {cache} | {package-manager}
```

Keep this SHORT. One line per concern, no explanations.

### Section 2: Pipeline (the core workflow)

```markdown
## From Idea to Project

### Step 1: Refine the Idea
ASK the user (do not assume):
- What are the 3-5 core features?
- What user roles exist? (admin, user, guest, service account)
- What are the main data entities and their relationships?
- What API operations per entity? (CRUD? custom actions? batch?)
- Auth requirements? (JWT, API key, OAuth2, none)
- Background tasks needed? (email, file processing, reports)

Present a summary table and confirm before proceeding.

### Step 2: Plan Architecture
Map features -> modules. Output:

\```
app/
├── core/               # App-wide infrastructure
│   ├── config.py       # Settings (BaseSettings)
│   ├── database.py     # Engine, session factory, get_db
│   ├── security.py     # JWT creation, password hashing
│   ├── exceptions.py   # Base exception classes
│   └── middleware.py    # CORS, logging, request ID
├── models/             # SQLAlchemy ORM models
│   ├── base.py         # DeclarativeBase, mixins
│   └── {entity}.py     # One file per entity
├── schemas/            # Pydantic schemas
│   └── {entity}.py     # Create, Read, Update per entity
├── repositories/       # Data access layer
│   ├── base.py         # Generic CRUD repository
│   └── {entity}.py     # Entity-specific queries
├── services/           # Business logic layer
│   └── {entity}.py     # Entity service class
├── api/
│   ├── deps.py         # Shared dependencies (auth, db, pagination)
│   └── v1/
│       ├── router.py   # Root v1 router (includes all feature routers)
│       └── endpoints/
│           └── {entity}.py  # Feature router
├── main.py             # FastAPI app, lifespan, middleware, router mount
├── alembic/            # Migrations
│   ├── env.py
│   └── versions/
├── tests/
│   ├── conftest.py     # Fixtures: db, client, auth, factories
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── pyproject.toml
├── Dockerfile
├── docker-compose.yml
├── .env.example
└── alembic.ini
\```

### Step 3: Generate (in this exact order)

1. **Config** -- pyproject.toml, .env.example, Dockerfile, docker-compose.yml
   Read `references/architecture.md` for config templates.

2. **Core infrastructure**
   - `core/config.py` -- Settings class with env var loading
   - `core/database.py` -- Engine, session factory, get_db dependency
   - `core/security.py` -- JWT utils, password hashing
   - `core/exceptions.py` -- Exception hierarchy
   - `core/middleware.py` -- CORS, request ID, logging
   Read `references/database.md` + `references/error-handling.md` + `references/middleware.md`

3. **Models (SQLAlchemy)**
   - `models/base.py` -- DeclarativeBase, timestamp mixin
   - `models/{entity}.py` -- One model per entity
   Read `references/models-schemas.md`

4. **Alembic**
   - `alembic.ini` + `alembic/env.py`
   - Initial migration
   Read `references/database.md`

5. **Schemas (Pydantic)**
   - `schemas/{entity}.py` -- Create, Read, Update classes per entity
   Read `references/models-schemas.md`

6. **Repositories**
   - `repositories/base.py` -- Generic CRUD
   - `repositories/{entity}.py` -- Entity-specific queries
   Read `references/database.md`

7. **Services**
   - `services/{entity}.py` -- Business logic per entity
   Read `references/services.md`

8. **Dependencies**
   - `api/deps.py` -- get_db, get_current_user, pagination
   Read `references/auth.md` + `references/api-design.md`

9. **Routers/Endpoints**
   - `api/v1/endpoints/{entity}.py` -- CRUD endpoints
   - `api/v1/router.py` -- Aggregate router
   Read `references/api-design.md`

10. **Auth** (if needed)
    - Auth endpoints (login, register, refresh)
    - Auth dependencies
    Read `references/auth.md`

11. **Main entry point**
    - `main.py` -- App creation, lifespan, middleware stack, router mounting
    Read `references/architecture.md` + `references/middleware.md`

### Step 4: Validate (MANDATORY feedback loop)
After generating, run this checklist:

\```
Validation:
- [ ] All imports resolve (no missing files, correct module paths)
- [ ] Every router uses the service layer (no direct DB access)
- [ ] Every service uses the repository layer (no direct DB queries in services unless simple)
- [ ] Every Pydantic schema has Create, Read, Update variants
- [ ] Every ORM model has corresponding Pydantic schemas
- [ ] Naming matches conventions (Read references/conventions.md)
- [ ] get_db dependency used consistently (not creating sessions manually)
- [ ] Auth dependencies protect appropriate endpoints
- [ ] Error handling follows exception hierarchy (references/error-handling.md)
- [ ] Type hints on all function parameters and return types
- [ ] Code style matches coding-style.md (docstrings, imports, naming)
- [ ] Test files follow testing.md patterns (if tests are being generated)
- [ ] Alembic env.py imports all models for autogenerate
\```

Fix any issues found, then re-validate.
```

### Section 3: Reference pointers

```markdown
## References

| File | Read when |
|------|-----------|
| `references/architecture.md` | Planning structure, creating config files, main.py |
| `references/api-design.md` | Creating routers, endpoints, dependencies |
| `references/models-schemas.md` | Creating ORM models or Pydantic schemas |
| `references/database.md` | Setting up database, repositories, migrations |
| `references/auth.md` | Implementing authentication or authorization |
| `references/services.md` | Writing business logic in service classes |
| `references/error-handling.md` | Adding exceptions, error handlers, error responses |
| `references/middleware.md` | Adding CORS, logging, or custom middleware |
| `references/conventions.md` | Naming anything (files, variables, modules) |
| `references/coding-style.md` | Writing any code -- ensures style matches the original team |
| `references/testing.md` | Creating test fixtures, API tests, mocking |
| `references/performance.md` | Caching, pooling, background tasks |

**NOTE:** Additional reference files may exist for project-specific patterns (WebSocket, Celery, file uploads, etc.). Check the references/ directory for the full list.
```

### Section 4: Critical rules (non-negotiable, extracted from scan)

```markdown
## Rules

{Extract from scanned project. Examples:}
- NEVER put business logic in routers -- always use the service layer
- NEVER query the database directly in services -- use repository classes
- EVERY endpoint must have response_model and status_code defined
- EVERY Pydantic schema must have model_config = ConfigDict(from_attributes=True) if read from ORM
- Services raise custom domain exceptions, NEVER HTTPException
- Routers translate exceptions to HTTP responses via exception handlers
- All functions have full type annotations (parameters + return type)
- get_db dependency handles commit/rollback, services do NOT call session.commit()
- Query keys: f"{entity}:{id}" for cache invalidation
- All endpoints protected by auth dependency unless explicitly public
```

---

## Reference File Guidelines

Each reference file must:

1. **Be under 300 lines** (add TOC if over 100 lines)
2. **Lead with code examples** -- prose only to explain WHY
3. **Use `{placeholders}`** -- `{Entity}`, `{entity}`, `{resource}`, `{feature}`
4. **Include Do/Don't** -- show the anti-pattern next to the correct pattern
5. **Contain BOTH layers** -- architectural (agnostic) + implementation (FastAPI-specific)
6. **One concern = one file.** Create a separate file for every distinct pattern category. If a section exceeds 80 lines, split it into its own file. A complex project should produce 15-20+ reference files

**Example structure for a reference file:**

```markdown
# Database Patterns

## Contents
- Engine & Session Setup
- Repository Pattern
- Query Patterns
- Pagination

## Engine & Session Setup

### Architecture
- Single async engine with connection pooling
- Session factory scoped to request lifecycle
- Dependency injection provides session to handlers

### Implementation
\```python
engine = create_async_engine(settings.DATABASE_URL, pool_size=5, max_overflow=10)
async_session_factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with async_session_factory() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
\```

## Repository Pattern

### Architecture
- Base class with generic CRUD operations
- Entity-specific repos extend base with custom queries
- Repos receive session, do NOT create or commit

### Implementation
\```python
class BaseRepository(Generic[ModelType]):
    def __init__(self, model: type[ModelType], db: AsyncSession):
        self.model = model
        self.db = db

    async def get(self, id: int) -> ModelType | None:
        result = await self.db.execute(select(self.model).where(self.model.id == id))
        return result.scalar_one_or_none()
\```

### Don't
\```python
# Do NOT commit in repositories
async def create(self, data):
    obj = self.model(**data.model_dump())
    self.db.add(obj)
    await self.db.commit()  # Wrong: commit belongs in get_db or service
    return obj
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
│   ├── architecture.md   # Directory structure + module anatomy
│   ├── conventions.md    # Naming table + do/don't rules
│   ├── patterns.md       # API design + database + auth + services templates
│   └── style.md          # Coding style profile (type hints, docstrings, async, imports)
├── SKILL.md
└── references/
    └── ...
```
