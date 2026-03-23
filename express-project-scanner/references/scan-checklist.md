# Scan Checklist

For each category: read 2-3 representative files, extract the pattern, classify as **architectural** (agnostic) or **implementation** (Express/Node-specific).

---

## 1. Project Foundation

| What to check | How |
|---|---|
| Directory structure | `find src/ -type d` — identify organization strategy (flat, layered, feature-based, MVC) |
| Dependencies | Full `package.json` — note exact versions for API compatibility |
| Language | TypeScript or JavaScript? tsconfig.json strict mode? |
| Build config | tsconfig.json, swc, esbuild, tsc compilation settings |
| Runtime config | Environment variables, dotenv, config module |
| Package manager | npm / yarn / pnpm / bun — lockfile type |
| Entry point | app.ts/js + server.ts/js — middleware registration, bootstrap order |
| Docker setup | Dockerfile — base image, multi-stage build, CMD/entrypoint |
| Lint/format | eslint.config + .prettierrc — code style enforcement |

**Architectural patterns to extract:** Directory organization strategy, layer separation, dependency flow direction, config management approach.

**Implementation patterns to extract:** Specific Express app factory, middleware registration order, server bootstrap, graceful shutdown.

---

## 2. Routes & Controllers

| What to check | Read example of |
|---|---|
| Route definition | Router() creation, route grouping, prefix conventions |
| Controller pattern | Class-based, object literal, or plain functions? |
| Request handling | How req.params, req.query, req.body are consumed |
| Response format | Consistent response shape: `{ data, meta, error }` |
| Async handling | asyncHandler wrapper, try/catch, express-async-errors |
| Route middleware | Per-route auth, validation, rate limiting |
| File uploads | multer setup, file handling pattern |
| Pagination | Query params: page/limit, cursor-based, offset/limit |
| API versioning | /api/v1/ prefix, version in headers, separate routers |

**Extract as architectural:**
```
- One route file per resource
- Routes map HTTP verbs to controller methods
- Controllers handle only HTTP concerns (parse request, format response)
- Business logic delegated to service layer
- Input validation happens before controller (middleware)
```

**Extract as implementation (example):**
```typescript
// routes/{resource}.routes.ts
const router = Router();
router.get('/', validate(list{Resource}Schema), {resource}Controller.getAll);
router.post('/', auth, validate(create{Resource}Schema), {resource}Controller.create);
router.get('/:id', validate(params{Resource}Schema), {resource}Controller.getById);
router.put('/:id', auth, validate(update{Resource}Schema), {resource}Controller.update);
router.delete('/:id', auth, {resource}Controller.remove);
export default router;

// controllers/{resource}.controller.ts
export const {resource}Controller = {
  getAll: asyncHandler(async (req: Request, res: Response) => {
    const { page, limit } = req.query;
    const result = await {resource}Service.findAll({ page, limit });
    res.json({ data: result.items, meta: { total: result.total, page, limit } });
  }),
  getById: asyncHandler(async (req: Request, res: Response) => {
    const result = await {resource}Service.findById(req.params.id);
    if (!result) throw new NotFoundError('{Entity} not found');
    res.json({ data: result });
  }),
  create: asyncHandler(async (req: Request, res: Response) => {
    const result = await {resource}Service.create(req.body);
    res.status(201).json({ data: result });
  }),
};
```

---

## 3. Middleware

| What to check | Read example of |
|---|---|
| Global middleware | app.use() order in app.ts — CORS, body parser, logging, security |
| Auth middleware | Token validation, session check, user injection into req |
| Validation middleware | Joi/Zod/express-validator integration pattern |
| Error middleware | Global error handler (err, req, res, next) signature |
| Logging middleware | Request/response logging, request ID generation |
| Rate limiting | express-rate-limit or custom, per-route or global |
| Security | helmet, hpp, cors configuration |
| Custom middleware | Project-specific middleware patterns |
| Middleware order | How middleware is stacked (order matters in Express) |

**Extract as architectural:**
```
- Global middleware registered in specific order: security → parsing → logging → auth
- Per-route middleware for validation and authorization
- Error handling middleware registered LAST
- Request context (user, requestId) attached to req object
```

**Extract as implementation (example):**
```typescript
// app.ts — middleware order
app.use(helmet());
app.use(cors(corsOptions));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(requestIdMiddleware);
app.use(morganMiddleware);

// routes
app.use('/api/v1/{resources}', {resource}Routes);

// error handling (LAST)
app.use(notFoundHandler);
app.use(errorHandler);

// middleware/error.middleware.ts
export const errorHandler = (err: AppError, req: Request, res: Response, next: NextFunction) => {
  const statusCode = err.statusCode || 500;
  res.status(statusCode).json({
    status: 'error',
    code: err.code || 'INTERNAL_ERROR',
    message: err.message,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
  });
};
```

---

## 4. Models & Validation

| What to check | Read example of |
|---|---|
| ORM/ODM | Prisma / Sequelize / TypeORM / Mongoose / Knex / Drizzle |
| Model definition | How tables/collections are defined |
| Relationships | hasMany, belongsTo, references — how relations are set up |
| Migrations | How schema changes are managed |
| Validation library | Zod / Joi / express-validator / class-validator |
| Schema location | Same file as model or separate schemas/ directory |
| DTO pattern | Separate Create/Update/Response DTOs? |
| Type inference | z.infer, Prisma generated types, manual interfaces |
| Enum handling | TypeScript enums, const objects, or string unions |

**Extract as architectural:**
```
- ORM models define database schema (tables, columns, relations)
- Validation schemas define API input contracts (separate from DB models)
- DTOs: Create{Entity}Dto, Update{Entity}Dto, {Entity}Response
- Types inferred from validation schemas (z.infer) when possible
- Enums in separate constants file
```

**Extract as implementation (example):**
```typescript
// models/ (Prisma example)
model {Entity} {
  id        String   @id @default(cuid())
  name      String
  status    {Entity}Status @default(ACTIVE)
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  ownerId   String
  owner     User     @relation(fields: [ownerId], references: [id])
}

// schemas/{resource}.schema.ts (Zod example)
export const create{Entity}Schema = z.object({
  body: z.object({
    name: z.string().min(1).max(255),
    status: z.nativeEnum({Entity}Status).optional(),
  }),
});
export type Create{Entity}Dto = z.infer<typeof create{Entity}Schema>['body'];

export const update{Entity}Schema = z.object({
  params: z.object({ id: z.string().cuid() }),
  body: z.object({
    name: z.string().min(1).max(255).optional(),
    status: z.nativeEnum({Entity}Status).optional(),
  }),
});
```

---

## 5. Database & ORM

| What to check | Read example of |
|---|---|
| Connection setup | Database client creation, connection string, pooling |
| Query patterns | ORM queries, raw queries, query builder usage |
| Transactions | How transactions are handled (Prisma.$transaction, knex.transaction) |
| Repository pattern | Repository classes wrapping ORM calls? Or direct ORM in services? |
| Seed data | How initial/test data is loaded |
| Migration workflow | Migration creation, running, rollback commands |
| Connection pooling | Pool size, idle timeout, connection limits |
| Multiple databases | Read replicas, separate databases per concern |

**Extract as architectural:**
```
- Single database client instance, shared across the app
- Connection string from environment variables
- Repository classes encapsulate all DB queries (or direct ORM usage)
- Transactions managed at the service layer
- Migrations for all schema changes (never manual DB edits)
```

**Extract as implementation (example):**
```typescript
// database/prisma.ts
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient({
  log: process.env.NODE_ENV === 'development' ? ['query'] : [],
});

export default prisma;

// repositories/{resource}.repository.ts
export class {Entity}Repository {
  async findAll(params: { skip: number; take: number }) {
    return prisma.{entity}.findMany({
      skip: params.skip,
      take: params.take,
      orderBy: { createdAt: 'desc' },
      include: { owner: { select: { id: true, name: true } } },
    });
  }

  async findById(id: string) {
    return prisma.{entity}.findUnique({ where: { id } });
  }

  async create(data: Create{Entity}Dto) {
    return prisma.{entity}.create({ data });
  }
}
```

---

## 6. Authentication & Authorization

| What to check | Read example of |
|---|---|
| Auth strategy | JWT, sessions (express-session), OAuth2, API keys, Passport.js |
| Token creation | How access/refresh tokens are generated and signed |
| Token validation | Auth middleware that verifies and decodes tokens |
| Password hashing | bcrypt, argon2, scrypt |
| Passport strategies | Local, Google, GitHub strategies configuration |
| Current user | How authenticated user is attached to request (req.user) |
| Role checking | Role/permission middleware, RBAC pattern |
| Token refresh | Refresh token flow, rotation |
| Session management | express-session config, store (Redis, DB) |

**Extract as architectural:**
```
- JWT-based auth with access + refresh tokens (or session-based)
- Auth middleware validates token and injects user into req
- Role-based access via permission middleware: requireRole('admin')
- Password hashing via bcrypt with configurable salt rounds
- Token refresh via dedicated endpoint with refresh token rotation
```

**Extract as implementation (example):**
```typescript
// middleware/auth.middleware.ts
export const authenticate = asyncHandler(async (req: Request, res: Response, next: NextFunction) => {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) throw new UnauthorizedError('No token provided');

  const payload = jwt.verify(token, config.jwtSecret) as JwtPayload;
  const user = await userService.findById(payload.sub);
  if (!user) throw new UnauthorizedError('User not found');

  req.user = user;
  next();
});

export const requireRole = (...roles: string[]) => {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!roles.includes(req.user.role)) {
      throw new ForbiddenError('Insufficient permissions');
    }
    next();
  };
};
```

---

## 7. Services / Business Logic

| What to check | Read example of |
|---|---|
| Service structure | Class-based or function-based services |
| Dependency injection | How services receive dependencies (constructor, module import, DI container) |
| Transaction scope | Where transactions begin/commit/rollback |
| Cross-service calls | How services call other services |
| Validation | Business rule validation location |
| External API calls | How services call external APIs (axios, fetch) |
| Event handling | EventEmitter, pub/sub patterns |
| Background jobs | Bull/BullMQ, Agenda, node-cron usage |

**Extract as architectural:**
```
- Service classes/modules contain business logic
- Services call repositories for data access (not ORM directly)
- Complex operations use transactions (service coordinates)
- Business validation in services, not controllers
- External API calls wrapped in dedicated client classes
```

**Extract as implementation (example):**
```typescript
// services/{resource}.service.ts
export class {Entity}Service {
  constructor(private repo: {Entity}Repository) {}

  async findAll(params: PaginationParams) {
    const skip = (params.page - 1) * params.limit;
    const [items, total] = await Promise.all([
      this.repo.findAll({ skip, take: params.limit }),
      this.repo.count(),
    ]);
    return { items, total };
  }

  async create(data: Create{Entity}Dto, userId: string) {
    const existing = await this.repo.findByName(data.name);
    if (existing) throw new ConflictError('{Entity} already exists');
    return this.repo.create({ ...data, ownerId: userId });
  }
}
```

---

## 8. Error Handling

| What to check | Read example of |
|---|---|
| Error class hierarchy | Custom error base class with statusCode, code |
| Error middleware | Global (err, req, res, next) handler |
| Async error handling | asyncHandler wrapper or express-async-errors |
| Validation errors | How Zod/Joi errors are formatted for the client |
| 404 handling | Not found route handler |
| Logging on errors | What gets logged (stack trace, request context) |
| Error response format | Consistent JSON structure for all errors |

**Extract as architectural:**
```
- Custom error base class with statusCode + code
- Async errors caught via wrapper or express-async-errors
- Services throw custom errors, controllers never catch them
- Error middleware translates errors to consistent JSON response
- Validation errors reformatted with field-level details
```

**Extract as implementation (example):**
```typescript
// errors/AppError.ts
export class AppError extends Error {
  constructor(
    message: string,
    public statusCode: number = 400,
    public code: string = 'APP_ERROR',
  ) {
    super(message);
    this.name = this.constructor.name;
    Error.captureStackTrace(this, this.constructor);
  }
}

export class NotFoundError extends AppError {
  constructor(message = 'Resource not found') {
    super(message, 404, 'NOT_FOUND');
  }
}

export class UnauthorizedError extends AppError {
  constructor(message = 'Unauthorized') {
    super(message, 401, 'UNAUTHORIZED');
  }
}

export class ConflictError extends AppError {
  constructor(message = 'Resource already exists') {
    super(message, 409, 'CONFLICT');
  }
}
```

---

## 9. Naming Conventions

Extract as a table — this is critical for the generated skill:

| Element | Convention | Example |
|---------|-----------|---------|
| Route file | ? | |
| Controller file | ? | |
| Service file | ? | |
| Repository file | ? | |
| Model file | ? | |
| Schema file | ? | |
| Middleware file | ? | |
| DTO / interface | ? | |
| Constants file | ? | |
| Test file | ? | |
| Error class | ? | |

---

## 10. Testing

| What to check | Read example of |
|---|---|
| Test runner | jest / vitest / mocha / node:test |
| File location | Colocated (`.test.ts` next to source) or `__tests__/` or `tests/` directory? |
| API testing | supertest / httpx — how endpoints are tested |
| Mocking pattern | jest.mock, vi.mock, sinon — what gets mocked |
| DB in tests | Test database, transaction rollback, in-memory, mocked |
| Auth in tests | How authenticated requests are made |
| Setup files | Global setup, test utils, custom matchers |
| Assertion style | expect().toBe(), assert(), should() |
| Fixtures/factories | How test data is created |
| Coverage | Coverage config, thresholds |

**Extract as architectural:**
```
- Tests in tests/ directory (or colocated with source)
- API tests via supertest hitting real endpoints
- DB tests use transaction rollback or test database
- External services mocked at boundary
- Factory functions for test data creation
```

**Extract as implementation (example):**
```typescript
// tests/{resource}.test.ts
describe('{Entity} API', () => {
  beforeEach(async () => {
    await prisma.{entity}.deleteMany();
  });

  describe('GET /api/v1/{resources}', () => {
    it('should return paginated list', async () => {
      await {entity}Factory.createMany(5);
      const res = await request(app)
        .get('/api/v1/{resources}')
        .set('Authorization', `Bearer ${testToken}`)
        .expect(200);

      expect(res.body.data).toHaveLength(5);
      expect(res.body.meta.total).toBe(5);
    });
  });

  describe('POST /api/v1/{resources}', () => {
    it('should create and return 201', async () => {
      const res = await request(app)
        .post('/api/v1/{resources}')
        .set('Authorization', `Bearer ${testToken}`)
        .send({ name: 'Test {Entity}' })
        .expect(201);

      expect(res.body.data.name).toBe('Test {Entity}');
    });
  });
});
```

---

## 11. Coding Style Fingerprint

This section captures the **personal coding style** of the team — not WHAT they build but HOW they write code. Read 5-6 diverse files to extract these signals.

| Signal | What to look for |
|---|---|
| Arrow vs function declarations | `const handler = () =>` or `function handler()`? |
| Export style | `export default` or named exports? Barrel re-exports? |
| Import style | ES modules or CommonJS (require)? |
| Destructuring depth | `const { name, age } = req.body` inline or separate? |
| Async patterns | `async/await` + try/catch or `.then().catch()`? |
| Error handling style | Custom error classes or generic Error? |
| Comment style | JSDoc? `// TODO`? Inline comments? None? |
| Import order | Node builtins → third-party → local? Separator lines? |
| Type definitions | `interface` or `type`? Same file or in `types/`? |
| Callback handling | Inline callbacks or named functions? |
| Optional chaining | `data?.name` or `data && data.name`? |
| String style | Template literals always or only when interpolating? |
| Null handling | `null`, `undefined`, non-null assertions `!`, or default values? |
| Guard clauses | Early returns at top of function or nested if/else? |
| File length | Short focused files (<100 lines) or large files (300+ lines)? |
| Semicolons | With or without? |
| Quotes | Single `'` or double `"`? |

**Extract as a style profile:**
```
CODING STYLE PROFILE:
- Functions: arrow functions for handlers, function declarations for middleware
- Exports: named exports, barrel re-exports via index.ts
- Modules: ES modules (import/export), no CommonJS
- Destructuring: inline in function parameters
- Async: async/await everywhere, errors via custom error classes
- Comments: minimal — only for non-obvious business logic
- Imports: node:* builtins → third-party → @/ aliases → relative, blank line separators
- Types: interface for objects, type for unions/intersections, in same file
- Callbacks: named handlers, no inline callbacks
- Null: optional chaining + nullish coalescing, no non-null assertions
- Files: short (<150 lines), one concern per file
- Semicolons: yes / no
- Quotes: single / double
```

---

## 12. Inconsistencies & Anti-patterns

Look for places where the team does NOT follow their own patterns. These are critical to document so the generated skill avoids reproducing mistakes.

| What to look for | Why it matters |
|---|---|
| Business logic in route handlers (bypassing services) | Inconsistent layer separation |
| Direct DB queries in controllers (bypassing repos/services) | Some files may skip the pattern |
| Mixed CommonJS + ES modules | Module system inconsistency |
| Inconsistent error handling (some throw, some res.status) | No unified approach |
| Missing validation on some endpoints | Not all routes validated |
| Raw `console.log` instead of logger | Debug artifacts |
| Inconsistent response format | Some endpoints return different shapes |
| Mixed async patterns (callbacks, promises, async/await) | Style inconsistency |
| Unused middleware registered | Dead code |

**Document as:**
```
INCONSISTENCIES FOUND:
- ❌ src/routes/legacy-reports.js — business logic directly in route handler
  → AVOID: always use controller + service pattern
- ❌ src/controllers/admin.controller.ts — queries DB directly without service
  → AVOID: controllers only call services, never DB
- ❌ 3 of 10 routes lack input validation
  → RULE: every route MUST have validation middleware

DECISION: When inconsistency found, follow the MAJORITY pattern (the one used most).
```

---

## 13. Advanced (if present)

Only scan these if they exist in the project:

### WebSocket
- Socket.io / ws setup, event naming, room management
- Authentication for WebSocket connections
- Message structure and serialization

### Background Jobs
- Bull/BullMQ/Agenda queue setup, job definitions
- Worker configuration, concurrency settings
- Job retry policies, error handling
- Cron/scheduled jobs

### Caching
- Redis cache pattern, key naming, TTL management
- Cache invalidation strategy
- Response caching middleware

### File Uploads
- Multer configuration, file validation, storage
- Large file handling (streaming)
- Cloud storage integration (S3, GCS)

### Rate Limiting
- express-rate-limit or custom, configuration
- Per-route or global limits
- Rate limit response headers

### GraphQL
- Apollo Server / express-graphql setup
- Schema definition pattern (SDL vs code-first)
- Resolver patterns, DataLoader usage

### Real-time
- Server-Sent Events (SSE) pattern
- Long polling endpoints

### Health Checks
- Health check endpoint pattern
- Readiness vs liveness checks
- Database, Redis, external service checks
