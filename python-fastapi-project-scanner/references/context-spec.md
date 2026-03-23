# .context/ Specification

Generate a `.context/` directory alongside the skill output. This makes the extracted patterns usable by ANY AI coding tool, not just Claude skills.

---

## What is .context/?

The [Codebase Context Specification](https://github.com/Agentic-Coding/Codebase-Context-Spec) is an emerging standard for documenting project architecture and conventions in a format any AI tool can consume. Tools like Cursor (.cursorrules), Copilot, and Windsurf already look for context files.

By generating `.context/`, the extracted patterns work everywhere -- not just as a Claude skill.

---

## Files to Generate

### .context/index.md

```markdown
---
module-name: {project-name}-patterns
description: Architecture and coding conventions extracted from {project-name}
related-modules: []
technologies:
  - python
  - fastapi
  - {orm}
  - {validation-lib}
  - {auth-lib}
  - {task-queue}
conventions:
  - {convention-1}
  - {convention-2}
  - {convention-3}
architecture-style: {e.g., "layered architecture with repository pattern" or "modular DDD"}
---

# {ProjectName} Architecture

## Overview
{1-2 sentences describing the project architecture}

## Stack
FastAPI {version} + {orm} | {validation-lib} | {auth-lib} | {task-queue} | {package-manager}

## Key Decisions
- **Directory structure**: {layered / modular / DDD / flat}
- **Data access**: {repository pattern / direct ORM / CRUD classes}
- **Business logic**: {service layer / inline in routers / use cases}
- **Auth**: {JWT / API key / OAuth2 / none}
- **Database**: {PostgreSQL + SQLAlchemy async / SQLite / MongoDB + Beanie}
- **Migrations**: {Alembic autogenerate / manual / none}
- **Config**: {pydantic-settings BaseSettings / environ / dotenv}
```

### .context/architecture.md

Condensed version of the skill's `references/architecture.md`. Focus on:

```markdown
# Architecture

## Directory Structure
\```
app/
├── core/               # App-wide infrastructure
│   ├── config.py       # Settings (BaseSettings)
│   ├── database.py     # Engine, session, get_db
│   ├── security.py     # JWT, password hashing
│   ├── exceptions.py   # Exception hierarchy
│   └── middleware.py    # CORS, request ID, logging
├── models/             # SQLAlchemy ORM models
│   ├── base.py         # DeclarativeBase + mixins
│   └── {entity}.py     # One model per entity
├── schemas/            # Pydantic schemas
│   └── {entity}.py     # Create, Read, Update per entity
├── repositories/       # Data access layer
│   ├── base.py         # Generic CRUD
│   └── {entity}.py     # Entity-specific queries
├── services/           # Business logic
│   └── {entity}.py     # Service class per entity
├── api/
│   ├── deps.py         # Shared dependencies
│   └── v1/endpoints/   # Routers per entity
├── main.py             # App entry point
└── tests/
\```

## Layer Rules
- Routers depend on services (never on repositories directly)
- Services depend on repositories (never on routers)
- Repositories depend on models (never on schemas)
- Schemas used at the API boundary only (routers + services)

## Module Anatomy
{describe what goes where in a typical module}
```

### .context/conventions.md

Condensed version of the skill's naming and style conventions:

```markdown
# Conventions

## Naming
| Element | Convention | Example |
|---------|-----------|---------|
| Module directory | snake_case | `user_management/` |
| Router file | snake_case | `users.py` |
| Service file | snake_case | `user_service.py` |
| Repository file | snake_case | `user_repository.py` |
| Model class | PascalCase | `class User(Base)` |
| Schema class | PascalCase + suffix | `UserCreate`, `UserRead` |
| Table name | plural snake_case | `users` |
| Router variable | snake_case | `router = APIRouter()` |
| Endpoint function | snake_case verb | `async def create_user()` |
| Constant | SCREAMING_SNAKE | `MAX_PAGE_SIZE = 100` |
| Enum | PascalCase(str, Enum) | `class UserRole(str, Enum)` |

## Patterns

### Do
- {correct pattern with brief code example}

### Don't
- {anti-pattern with brief code example}

## Rules
- {rule 1}
- {rule 2}
```

### .context/patterns.md

Condensed version of API design, database, auth, services, and error handling patterns:

```markdown
# Code Patterns

## Endpoint Pattern
{brief description + code template}

## Repository Pattern
{brief description + code template}

## Service Pattern
{brief description + code template}

## Schema Pattern
{brief description + Create/Read/Update templates}

## Authentication
{JWT flow, get_current_user dependency}

## Error Handling
{exception hierarchy, error response format}

## Testing
{test client setup, API test template, fixtures}
```

### .context/style.md

Condensed coding style profile -- how the team writes Python code:

```markdown
# Coding Style

## Type Hints
- Coverage: {everywhere / function signatures only / minimal}
- Syntax: {str | None / Optional[str] / mixed}
- Built-in generics: {list[int] / List[int]}

## Docstrings
- Style: {Google / NumPy / reST / none}
- Where: {all public functions / classes only / none}

## Code Patterns
- Strings: {f-strings / .format() / %}
- Async: {async everywhere / mixed / sync only}
- Imports: {absolute / relative}
- Import order: {stdlib -> third-party -> local}
- Guard clauses: {early returns / nested if-else}
- Comprehensions: {preferred / loops for everything}
- Error handling: {custom exceptions / HTTPException / try-except}

## Naming
- Functions: {snake_case}
- Classes: {PascalCase}
- Constants: {SCREAMING_SNAKE}
- Private: {_prefix / __dunder / none}

## Formatting
- Quotes: {double " / single '}
- Line length: {88 / 120 / 79}
- Comments: {minimal / Google-style docstrings / extensive inline}
- File length: {short <150 lines / medium / large}
```

---

## Guidelines

1. **Keep .context/ files SHORT** -- aim for 50-100 lines each. These are reference cards, not documentation.
2. **Use the same `{placeholders}`** as the skill references for consistency.
3. **No workflow instructions** -- .context/ describes patterns, not how to generate a project. That's what the skill is for.
4. **Framework-specific** -- unlike skill references (which have two layers), .context/ files should be written for FastAPI/Python specifically. Other tools don't need the agnostic layer.
