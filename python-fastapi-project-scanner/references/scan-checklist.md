# Scan Checklist

For each category: read 2-3 representative files, extract the pattern, classify as **architectural** (agnostic) or **implementation** (FastAPI/Python-specific).

---

## 1. Project Foundation

| What to check | How |
|---|---|
| Directory structure | `find app/ -type d` -- identify organization strategy (layered, modular, DDD, flat) |
| Dependencies | Full `pyproject.toml` or `requirements.txt` -- note exact versions |
| Python version | pyproject.toml `requires-python`, `.python-version`, or `runtime.txt` |
| Package manager | Poetry lock? uv lock? Pipfile? plain pip? |
| Config/settings | settings.py or config.py -- BaseSettings, env vars, config hierarchy |
| Env files | .env, .env.example -- what variables are configured |
| Entry point | main.py -- FastAPI app creation, middleware registration, router inclusion |
| Docker setup | Dockerfile -- base image, multi-stage build, CMD/entrypoint |
| Pre-commit | .pre-commit-config.yaml -- hooks configured (ruff, mypy, black) |

**Architectural patterns to extract:** Directory organization strategy, layer separation, dependency flow direction, config management approach.

**Implementation patterns to extract:** Specific FastAPI app factory, uvicorn config, lifespan event handlers, middleware order.

---

## 2. Architecture & Module Boundaries

| What to check | Read example of |
|---|---|
| Layer organization | How routers, services, repositories, models are organized |
| Module boundaries | What goes inside a module vs shared |
| Dependency flow | Router -> Service -> Repository -> Model (one-directional?) |
| Shared code | Where shared utilities, base classes, common types live |
| API versioning | /api/v1/ prefix pattern, version in router or path |
| Init files | What `__init__.py` exports -- barrel exports or empty? |

**Extract as architectural:**
```
- Layered: routers/ -> services/ -> repositories/ -> models/
- Each layer only depends on the layer below
- Shared code in core/ or common/
- No circular imports between modules
- API versioned via /api/v1/ path prefix
```

**Extract as implementation (example):**
```python
# app/main.py
app = FastAPI(title="{ProjectName}", version="0.1.0")
app.include_router({feature}_router, prefix="/api/v1/{feature}s", tags=["{Feature}s"])

# Module structure
app/{feature}/
    __init__.py
    router.py       # APIRouter with endpoints
    service.py      # Business logic
    repository.py   # Data access
    models.py       # SQLAlchemy models
    schemas.py      # Pydantic schemas
    dependencies.py # Depends() functions
    exceptions.py   # Module-specific exceptions
```

---

## 3. API Design (Routers & Endpoints)

| What to check | Read example of |
|---|---|
| Router setup | APIRouter creation -- prefix, tags, dependencies |
| CRUD endpoints | GET (list, detail), POST, PUT/PATCH, DELETE patterns |
| Path parameters | `{id}` naming, type annotation (int, UUID, str) |
| Query parameters | Pagination, filtering, sorting parameter style |
| Request body | How request models are used (schema classes) |
| Response model | `response_model=`, `status_code=`, response classes |
| Dependencies | `Depends()` usage -- auth, db session, pagination |
| Error responses | `responses={}` parameter for OpenAPI docs |
| File upload | `UploadFile`, `File()` patterns |
| Background tasks | `BackgroundTasks` parameter usage |
| WebSocket | WebSocket endpoint pattern (if present) |

**Extract as architectural:**
```
- One router per resource/entity
- Standard CRUD: list (GET /), detail (GET /{id}), create (POST /), update (PUT /{id}), delete (DELETE /{id})
- Pagination via query params: skip, limit (or page, per_page)
- Auth dependency injected at router level (applies to all endpoints)
- DB session injected per endpoint via Depends()
```

**Extract as implementation (example):**
```python
router = APIRouter()

@router.get("/", response_model=list[{Entity}Read])
async def list_{entities}(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[{Entity}Read]:
    service = {Entity}Service(db)
    return await service.get_multi(skip=skip, limit=limit)

@router.get("/{'{entity}_id'}", response_model={Entity}Read)
async def get_{entity}(
    {entity}_id: int,
    db: AsyncSession = Depends(get_db),
) -> {Entity}Read:
    service = {Entity}Service(db)
    result = await service.get({entity}_id)
    if not result:
        raise HTTPException(status_code=404, detail="{Entity} not found")
    return result

@router.post("/", response_model={Entity}Read, status_code=status.HTTP_201_CREATED)
async def create_{entity}(
    data: {Entity}Create,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> {Entity}Read:
    service = {Entity}Service(db)
    return await service.create(data)
```

---

## 4. Models & Schemas

| What to check | Read example of |
|---|---|
| SQLAlchemy model | Table definition, column types, relationships, indexes |
| Base model class | DeclarativeBase or declarative_base(), custom base class |
| Pydantic schema | BaseModel subclasses -- Create, Read, Update pattern |
| Schema inheritance | Base -> Create, Base -> Read (with id + timestamps) |
| Validators | field_validator, model_validator usage |
| ConfigDict | model_config with from_attributes=True, json_schema_extra |
| Enum patterns | Python Enum or str/int Enum, where defined |
| Relationship schemas | Nested schemas, circular reference handling |
| Pydantic <-> ORM | How ORM objects convert to Pydantic (from_attributes) |

**Extract as architectural:**
```
- ORM models in models.py: table structure, relationships, constraints
- Pydantic schemas in schemas.py: separate Create/Read/Update classes
- Base schema holds common fields, Create adds write-only, Read adds id + timestamps
- Validators in schema classes, not in routers
- Enums in separate enums.py or constants.py
```

**Extract as implementation (example):**
```python
# models.py
class {Entity}(Base):
    __tablename__ = "{entities}"
    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(255))
    status: Mapped[{Entity}Status] = mapped_column(default={Entity}Status.ACTIVE)
    created_at: Mapped[datetime] = mapped_column(default=func.now())
    owner_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    owner: Mapped["User"] = relationship(back_populates="{entities}")

# schemas.py
class {Entity}Base(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    status: {Entity}Status = {Entity}Status.ACTIVE

class {Entity}Create({Entity}Base):
    pass

class {Entity}Update(BaseModel):
    name: str | None = None
    status: {Entity}Status | None = None

class {Entity}Read({Entity}Base):
    id: int
    created_at: datetime
    owner_id: int
    model_config = ConfigDict(from_attributes=True)
```

---

## 5. Database & ORM

| What to check | Read example of |
|---|---|
| Session setup | async_sessionmaker, engine creation, connection string |
| Session dependency | get_db() generator function |
| Repository pattern | Base repository class with CRUD methods |
| Query style | SQLAlchemy 2.0 select() vs 1.x Query API |
| Joins | How relationships are loaded (joinedload, selectinload) |
| Pagination | offset/limit pattern, cursor-based pagination |
| Transactions | Where commits happen (dependency, service, or repo) |
| Alembic config | env.py, autogenerate usage, naming conventions |
| Alembic workflow | How migrations are created and applied |
| Connection pooling | Pool size, max overflow, pool recycle settings |

**Extract as architectural:**
```
- Single engine + session factory in database.py
- Session injected via Depends(get_db) -- one session per request
- Repository classes encapsulate all DB queries
- Transactions committed in the dependency (get_db), not in services
- Alembic for migrations with autogenerate
```

**Extract as implementation (example):**
```python
# database.py
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

# repository.py
class {Entity}Repository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get(self, id: int) -> {Entity} | None:
        result = await self.db.execute(select({Entity}).where({Entity}.id == id))
        return result.scalar_one_or_none()

    async def get_multi(self, *, skip: int = 0, limit: int = 100) -> list[{Entity}]:
        result = await self.db.execute(
            select({Entity}).offset(skip).limit(limit).order_by({Entity}.id)
        )
        return list(result.scalars().all())

    async def create(self, data: {Entity}Create) -> {Entity}:
        obj = {Entity}(**data.model_dump())
        self.db.add(obj)
        await self.db.flush()
        await self.db.refresh(obj)
        return obj
```

---

## 6. Authentication & Authorization

| What to check | Read example of |
|---|---|
| Auth strategy | JWT, OAuth2, API keys, session-based |
| Token creation | How access/refresh tokens are generated |
| Token validation | Dependency that validates and decodes token |
| Password hashing | passlib, bcrypt, argon2 |
| OAuth2 scheme | OAuth2PasswordBearer, OAuth2PasswordRequestForm |
| Current user | get_current_user dependency pattern |
| Role checking | Permission dependencies, RBAC pattern |
| Token refresh | Refresh token flow, rotation |
| Middleware auth | Auth middleware vs per-endpoint dependency |
| API key auth | Header or query parameter API key validation |

**Extract as architectural:**
```
- JWT-based auth with access + refresh tokens
- OAuth2PasswordBearer for token extraction
- get_current_user dependency decodes token and fetches user
- Role-based access via permission dependencies: require_role("admin")
- Password hashing via passlib[bcrypt]
- Token refresh via dedicated endpoint
```

**Extract as implementation (example):**
```python
# auth/dependencies.py
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")

async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id: int = payload.get("sub")
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")
    user = await UserRepository(db).get(user_id)
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
    return user

def require_role(*roles: str):
    async def dependency(current_user: User = Depends(get_current_user)) -> User:
        if current_user.role not in roles:
            raise HTTPException(status_code=403, detail="Insufficient permissions")
        return current_user
    return dependency
```

---

## 7. Services / Business Logic

| What to check | Read example of |
|---|---|
| Service structure | Class-based or function-based services |
| DB injection | How services receive the database session |
| Transaction scope | Where transactions begin/commit/rollback |
| Cross-service calls | How services call other services |
| Validation | Business rule validation location |
| External API calls | How services call external APIs |
| Event publishing | Domain events, signals, or pub/sub |

**Extract as architectural:**
```
- Service classes receive db session in constructor
- Services contain business logic, not data access
- Services call repositories for data access
- Complex operations use a single transaction (service coordinates)
- Business validation raises custom exceptions, not HTTPException
```

**Extract as implementation (example):**
```python
class {Entity}Service:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.repo = {Entity}Repository(db)

    async def create(self, data: {Entity}Create, user_id: int) -> {Entity}:
        # Business validation
        existing = await self.repo.get_by_name(data.name)
        if existing:
            raise {Entity}AlreadyExistsError(data.name)
        # Create entity
        return await self.repo.create(data, owner_id=user_id)

    async def update(self, id: int, data: {Entity}Update, user_id: int) -> {Entity}:
        entity = await self.repo.get(id)
        if not entity:
            raise {Entity}NotFoundError(id)
        if entity.owner_id != user_id:
            raise PermissionDeniedError()
        return await self.repo.update(entity, data)
```

---

## 8. Error Handling

| What to check | Read example of |
|---|---|
| Exception hierarchy | Custom exception base class and subclasses |
| Exception handlers | `@app.exception_handler()` registration |
| HTTPException usage | Direct raises vs custom exception classes |
| Error response format | Consistent error JSON structure |
| Validation errors | How Pydantic ValidationError is formatted |
| 404 handling | How "not found" is communicated across layers |
| Logging on errors | What gets logged (traceback, request context) |

**Extract as architectural:**
```
- Custom exception base class with status_code + detail
- Exception handlers translate custom exceptions to HTTP responses
- Services raise custom exceptions, routers never catch them
- Consistent error response: {"detail": "...", "code": "...", "errors": [...]}
- Validation errors reformatted to match error response format
```

**Extract as implementation (example):**
```python
# exceptions.py
class AppException(Exception):
    def __init__(self, detail: str, status_code: int = 400, code: str = "APP_ERROR"):
        self.detail = detail
        self.status_code = status_code
        self.code = code

class {Entity}NotFoundError(AppException):
    def __init__(self, id: int):
        super().__init__(detail=f"{Entity} {id} not found", status_code=404, code="{ENTITY}_NOT_FOUND")

# main.py
@app.exception_handler(AppException)
async def app_exception_handler(request: Request, exc: AppException):
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail, "code": exc.code},
    )
```

---

## 9. Middleware

| What to check | Read example of |
|---|---|
| CORS setup | CORSMiddleware config -- origins, methods, headers |
| Logging middleware | Request/response logging, timing |
| Request ID | X-Request-ID generation and propagation |
| Error middleware | Global exception catching |
| Auth middleware | Token validation at middleware level (vs dependency) |
| Custom middleware | Any project-specific middleware |
| Middleware order | How middleware is stacked in main.py |

**Extract as architectural:**
```
- CORS configured for specific origins (not "*" in production)
- Request ID generated per request, attached to logs
- Request timing logged for performance monitoring
- Middleware added in specific order: CORS -> RequestID -> Logging -> Auth
```

**Extract as implementation (example):**
```python
# main.py
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# middleware/request_id.py
class RequestIDMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        request_id = request.headers.get("X-Request-ID", str(uuid4()))
        request.state.request_id = request_id
        response = await call_next(request)
        response.headers["X-Request-ID"] = request_id
        return response
```

---

## 10. Testing

| What to check | Read example of |
|---|---|
| Test runner | pytest config (pyproject.toml or pytest.ini) |
| Test structure | tests/ directory layout (unit/, integration/, e2e/) |
| Conftest files | Root conftest.py -- fixtures, client, db setup |
| API test pattern | AsyncClient (httpx) for endpoint tests |
| DB fixtures | Test database, transaction rollback, in-memory SQLite |
| Factories | Factory Boy or custom factory functions |
| Mocking | pytest-mock, unittest.mock, how external services are mocked |
| Auth in tests | How authenticated requests are made in tests |
| Assertions | assert style, custom matchers, response checking |
| Coverage | Coverage config, thresholds |

**Extract as architectural:**
```
- Tests in tests/ directory mirroring app/ structure
- Conftest provides: db session, test client, auth token, factories
- API tests via AsyncClient hitting real endpoints
- DB tests use transaction rollback (no data persistence between tests)
- External services mocked at the boundary (repository or HTTP client)
```

**Extract as implementation (example):**
```python
# conftest.py
@pytest.fixture
async def db_session() -> AsyncGenerator[AsyncSession, None]:
    async with async_session_factory() as session:
        async with session.begin():
            yield session
            await session.rollback()

@pytest.fixture
async def client(db_session: AsyncSession) -> AsyncGenerator[AsyncClient, None]:
    async def override_get_db():
        yield db_session
    app.dependency_overrides[get_db] = override_get_db
    async with AsyncClient(app=app, base_url="http://test") as ac:
        yield ac
    app.dependency_overrides.clear()

# test_{feature}.py
@pytest.mark.anyio
async def test_create_{entity}(client: AsyncClient, auth_headers: dict):
    response = await client.post(
        "/api/v1/{entities}/",
        json={"name": "Test {Entity}"},
        headers=auth_headers,
    )
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Test {Entity}"
    assert "id" in data
```

---

## 11. Coding Style Fingerprint

This section captures the **personal coding style** of the team -- not WHAT they build but HOW they write Python code. Read 5-6 diverse files to extract these signals.

| Signal | What to look for |
|---|---|
| Type hints | Everywhere (`def foo(x: int) -> str`)? Optional? Only function signatures? None? |
| Type hint style | `Optional[str]` vs `str \| None` (Python 3.10+)? `list[int]` vs `List[int]`? |
| Docstrings | Google style (Args/Returns)? NumPy style? reST (:param)? None? |
| f-strings vs format | `f"hello {name}"` or `"hello {}".format(name)` or `"hello %s" % name`? |
| Walrus operator | `:=` used in if statements, while loops? |
| Match/case | `match` statements (Python 3.10+)? |
| Async style | `async def` everywhere or mix of sync/async endpoints? |
| Import style | Absolute (`from app.models`) or relative (`from .models`)? |
| Import organization | stdlib -> third-party -> local? Separator lines? |
| Naming | `snake_case` consistency? `SCREAMING_SNAKE` for constants? Private `_prefix`? |
| Class style | Pydantic models vs dataclasses vs plain classes? |
| Function length | Short focused (10-20 lines) or long procedures (50+ lines)? |
| Error handling | try/except blocks? Custom exceptions? Bare `except:`? |
| List comprehensions | Preferred over loops? Nested comprehensions? |
| Generator usage | `yield` generators? Generator expressions? |
| Context managers | `with` for resource management? Custom context managers? |
| Decorator patterns | Custom decorators? Heavy or light decorator usage? |
| Private naming | `_private` prefix? `__dunder` names? |
| Guard clauses | Early returns at top of function or nested if/else? |
| Comment style | `# TODO:`, `# FIXME:`, inline comments? No comments? |
| String quotes | Double `"` or single `'`? Consistent? |
| File length | Short (<100 lines) or long (300+ lines)? |

**Extract as a style profile:**
```
CODING STYLE PROFILE:
- Type hints: everywhere, using Python 3.10+ union syntax (str | None)
- Docstrings: Google style on public functions only
- Strings: f-strings exclusively, double quotes
- Async: async def for all endpoints, sync for utility functions
- Imports: absolute, organized stdlib -> third-party -> local with blank line separators
- Naming: strict snake_case, SCREAMING_SNAKE for constants, _private for internal
- Classes: Pydantic for schemas/config, SQLAlchemy for ORM, no plain classes
- Functions: short (< 25 lines), one responsibility per function
- Errors: custom exception hierarchy, no bare except
- Comprehensions: preferred for simple transforms, loops for complex logic
- Guard clauses: early returns for validation, no deep nesting
- Comments: minimal -- only for non-obvious business logic
- Files: focused (< 150 lines), one concern per file
```

---

## 12. Inconsistencies & Anti-patterns

Look for places where the team does NOT follow their own patterns. These are critical to document so the generated skill avoids reproducing mistakes.

| What to look for | Why it matters |
|---|---|
| Business logic in routers (bypassing services) | Inconsistent layer separation |
| Direct DB queries in routers (bypassing repos) | Some files may skip the repository pattern |
| Mixed sync/async without clear rationale | Inconsistent async usage |
| HTTPException raised in services (not custom exceptions) | Service layer leaking HTTP concerns |
| Raw SQL mixed with ORM queries | Inconsistent data access |
| Missing type hints in some modules | Typing discipline varies |
| Different pagination patterns across endpoints | No unified approach |
| Inconsistent error response format | Some endpoints return different structures |
| Raw `print()` instead of logging | Debug artifacts |
| Circular imports worked around with TYPE_CHECKING | Architectural issue |

**Document as:**
```
INCONSISTENCIES FOUND:
- app/modules/legacy/ -- business logic directly in router, no service layer
  -> AVOID: always use service layer between router and repository
- app/users/service.py -- raises HTTPException instead of custom exception
  -> AVOID: services raise domain exceptions, routers translate to HTTP
- 2 of 8 modules lack type hints on function parameters
  -> RULE: every function MUST have full type annotations

DECISION: When inconsistency found, follow the MAJORITY pattern (the one used most).
```

---

## 13. Advanced (if present)

Only scan these if they exist in the project:

### WebSocket
- WebSocket endpoint pattern, connection management, rooms/channels
- Authentication for WebSocket connections
- Message serialization (JSON, Protocol Buffers)

### Background Tasks
- FastAPI BackgroundTasks usage pattern
- Celery/ARQ/SAQ task definitions, worker configuration
- Task retry policies, error handling
- Periodic tasks / scheduled jobs

### Caching
- Redis cache pattern, key naming, TTL management
- Cache invalidation strategy
- Response caching decorators
- Database query caching

### File Uploads
- UploadFile handling, file validation, storage
- Large file handling (streaming, chunked uploads)
- Cloud storage integration (S3, GCS)

### Rate Limiting
- Rate limiting library (slowapi, fastapi-limiter)
- Rate limit configuration per endpoint
- Rate limit response headers

### Pagination
- Offset/limit vs cursor-based
- Paginated response schema
- Total count handling (with/without)

### Event System
- Domain events, pub/sub pattern
- Event handlers, event bus
- Integration events for cross-service communication

### Health Checks
- Health check endpoint pattern
- Readiness vs liveness checks
- Database, Redis, external service checks
