# Output Structure Guide

Defines what the generated skill must contain and how to organize reference files.

---

## Skill Directory

**One concern = one file.** Create a separate reference file for every distinct pattern category found in the project. Prefer many focused files (50-150 lines) over few large ones (300+ lines). If a section within a file grows past 80 lines, split it into its own file.

```
{project-name}-generator/
├── SKILL.md                    # < 500 lines, workflow + rules + reference pointers
└── references/                 # Each file < 300 lines, examples-first
    ├── architecture.md         # Project structure, config templates, module anatomy, decisions
    ├── api-design.md           # Router setup, endpoint patterns, dependencies, response models
    ├── models-schemas.md       # SQLAlchemy models, Pydantic schemas, Create/Read/Update, validators
    ├── database.md             # Engine/session setup, repository pattern, queries, Alembic
    ├── auth.md                 # JWT flow, OAuth2, get_current_user, RBAC, permissions
    ├── services.md             # Service layer, business logic, transaction management
    ├── error-handling.md       # Exception hierarchy, handlers, error response format, validation errors
    ├── middleware.md            # CORS, logging, request ID, custom middleware, middleware order
    ├── conventions.md          # Naming table, enum pattern, import rules, file organization
    ├── coding-style.md         # Type hints, docstrings, async, f-strings, comprehensions, decorators
    ├── testing.md              # pytest, fixtures, AsyncClient, factories, mocking, conftest, structure
    └── performance.md          # Caching, connection pooling, background tasks (if applicable)
```

This is the minimum set. Create additional reference files for any project-specific patterns found (WebSocket, Celery workers, file uploads, rate limiting, email, event system, etc.).

---

## What goes in each file

### architecture.md
- Directory structure template with annotations
- Module anatomy (what goes in router.py, service.py, repository.py, models.py, schemas.py)
- Layer dependency rules (which layer can call which)
- core/ vs modules/ vs shared/ -- decision criteria
- Config file templates: pyproject.toml deps, Dockerfile, docker-compose
- Entry point: main.py with app factory, lifespan, middleware, router inclusion
- API versioning strategy

### api-design.md
- APIRouter creation template (prefix, tags, dependencies)
- CRUD endpoint template (list, detail, create, update, delete)
- Path parameter conventions (id type, naming)
- Query parameter patterns (pagination, filtering, sorting)
- Response model usage (response_model, status_code)
- Dependency injection patterns (Depends() chains)
- File upload endpoint template (if present)
- WebSocket endpoint template (if present)
- Background task endpoint template (if present)

### models-schemas.md
- SQLAlchemy model template (Mapped types, relationships, indexes)
- Base model class (DeclarativeBase, mixins for timestamps, soft delete)
- Pydantic schema hierarchy: Base -> Create, Base -> Read (with id + timestamps)
- Update schema pattern (all fields optional)
- Field validators (field_validator, model_validator)
- ConfigDict settings (from_attributes, json_schema_extra)
- Enum definition pattern
- Nested schema pattern for relationships
- Pydantic <-> ORM conversion

### database.md
- Engine creation (async_engine, connection string, pool settings)
- Session factory (async_sessionmaker)
- get_db dependency (session lifecycle, commit/rollback)
- Base repository class (generic CRUD methods)
- Entity repository template (custom queries)
- SQLAlchemy 2.0 query patterns (select, join, filter, order_by)
- Eager loading patterns (joinedload, selectinload)
- Pagination query helpers
- Alembic env.py template
- Migration workflow (autogenerate, manual, naming)

### auth.md
- JWT token creation (access + refresh)
- OAuth2PasswordBearer setup
- get_current_user dependency (full code)
- Password hashing utility
- Login endpoint template
- Token refresh endpoint template
- Role-based permission dependency
- API key auth dependency (if present)
- Token storage and expiry config

### services.md
- Service class template (constructor with db session)
- CRUD service methods
- Business validation pattern
- Cross-service coordination
- Transaction management
- External API call patterns
- Event publishing (if present)

### error-handling.md
- Exception base class and hierarchy
- Exception handler registration in main.py
- Error response JSON format
- Per-layer exception strategy (services raise domain, routers translate)
- Validation error reformatting
- 404/409/403 common error patterns
- Logging on errors (what gets logged, at what level)

### middleware.md
- CORS middleware config template
- Request ID middleware template
- Logging/timing middleware template
- Auth middleware (if used instead of per-endpoint dependency)
- Middleware registration order in main.py
- Custom middleware base (BaseHTTPMiddleware vs pure ASGI)

### conventions.md
- Complete naming table (modules, routers, services, repos, models, schemas, tests, enums)
- Enum pattern: `class {Entity}Status(str, Enum)` or `IntEnum`
- Import conventions: absolute vs relative, organization order
- File organization rules
- Module structure template
- `__init__.py` export patterns
- Language/locale for user-facing strings

### coding-style.md
- Type hint style: `str | None` vs `Optional[str]`, `list[int]` vs `List[int]`
- Docstring style: Google/NumPy/reST/none, where applied
- String formatting: f-strings vs .format() vs %
- Async patterns: when to use async def vs def
- Function declaration style: short focused functions vs long procedures
- Guard clauses and early returns
- Comprehension vs loop preference
- Decorator usage patterns
- Private naming: `_private` convention
- Comment philosophy: minimal vs comprehensive
- Import ordering with example
- Error handling style: try/except patterns
- Context manager usage

### testing.md
- pytest configuration (pyproject.toml section)
- Test directory structure (unit, integration, e2e)
- Root conftest.py (full code: fixtures, client, db)
- AsyncClient test template
- Database fixture (transaction rollback pattern)
- Factory/fixture for test data
- Auth fixture (how to make authenticated requests in tests)
- Mocking strategy (pytest-mock, monkeypatch, dependency_overrides)
- Assertion patterns
- Coverage config and expectations

### performance.md (generate only if project has these patterns)
- Redis caching pattern and key naming
- Cache invalidation strategy
- Response caching decorators
- Database connection pool tuning
- Background task patterns (FastAPI BackgroundTasks, Celery)
- N+1 query prevention (eager loading strategy)
- Response compression

---

## Two-Layer Rule

EVERY pattern in every reference file must have:

1. **Architecture section** -- Framework-agnostic description of the pattern
2. **Implementation section** -- Exact code template for FastAPI/Python

Two layers = adaptable. The architecture sections alone are enough to implement the patterns in any framework (Django, Flask, Litestar).

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
