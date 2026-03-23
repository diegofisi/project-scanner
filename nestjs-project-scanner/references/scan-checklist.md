# Scan Checklist

For each category: read 2-3 representative files, extract the pattern, classify as **architectural** (agnostic) or **implementation** (NestJS-specific).

---

## 1. Project Foundation

| What to check | How |
|---|---|
| Directory structure | `find src/ -type d` — identify organization strategy (module-based, layered, DDD) |
| Dependencies | Full `package.json` — note exact NestJS version and plugin versions |
| NestJS version | `@nestjs/core` version — v8, v9, v10+ have different APIs |
| Build config | tsconfig.json, nest-cli.json — compiler options, assets, webpack |
| Config management | @nestjs/config, ConfigModule, environment variables |
| Entry point | main.ts — bootstrap, global pipes, prefix, CORS, Swagger |
| Docker setup | Dockerfile — base image, multi-stage build, CMD |
| Monorepo | nest-cli.json projects, workspaces, monorepo mode |
| Lint/format | eslint.config + .prettierrc — code style enforcement |

**Architectural patterns to extract:** Module organization strategy, layer separation, dependency flow direction, config management approach.

**Implementation patterns to extract:** Specific NestJS bootstrap configuration, global pipe/filter setup, Swagger integration, lifecycle hooks.

---

## 2. Modules

| What to check | Read example of |
|---|---|
| Module structure | @Module() — imports, controllers, providers, exports |
| Feature modules | One module per domain entity/feature |
| Dynamic modules | forRoot / forRootAsync patterns for configurable modules |
| Global modules | @Global() modules for cross-cutting concerns |
| Module re-exports | How modules share providers across boundaries |
| Circular deps | forwardRef() usage patterns |
| Lazy modules | LazyModuleLoader usage (if present) |
| AppModule | Root module — what gets imported, order |

**Extract as architectural:**
```
- One module per domain entity/bounded context
- Modules export only services that other modules need
- Cross-cutting concerns (config, logging, auth) in global modules
- No circular module dependencies (forwardRef only as last resort)
- AppModule imports feature modules + infrastructure modules
```

**Extract as implementation (example):**
```typescript
// {entity}.module.ts
@Module({
  imports: [TypeOrmModule.forFeature([{Entity}]), CommonModule],
  controllers: [{Entity}Controller],
  providers: [{Entity}Service, {Entity}Repository],
  exports: [{Entity}Service],
})
export class {Entity}Module {}

// app.module.ts
@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    DatabaseModule,
    AuthModule,
    {Entity}Module,
  ],
})
export class AppModule {}
```

---

## 3. Controllers

| What to check | Read example of |
|---|---|
| Controller decorators | @Controller(), @Get(), @Post(), @Put(), @Delete() |
| Route parameters | @Param(), @Query(), @Body() — types, pipes |
| Response handling | Return values, @HttpCode(), @Header() |
| Guards on controllers | @UseGuards() at class or method level |
| Interceptors | @UseInterceptors() — transform, cache, logging |
| File upload | @UseInterceptors(FileInterceptor), @UploadedFile() |
| Swagger decorators | @ApiTags(), @ApiOperation(), @ApiResponse() |
| Versioning | @Version(), URI/header versioning |
| Pagination | Query params pattern, paginated response |

**Extract as architectural:**
```
- One controller per resource
- Controllers handle only HTTP concerns (parse, validate, respond)
- Business logic delegated to injected services
- Guards for authorization at class/method level
- Swagger decorators for API documentation
```

**Extract as implementation (example):**
```typescript
@ApiTags('{entities}')
@Controller('{entities}')
@UseGuards(JwtAuthGuard)
export class {Entity}Controller {
  constructor(private readonly {entity}Service: {Entity}Service) {}

  @Get()
  @ApiOperation({ summary: 'List {entities}' })
  findAll(@Query() query: Paginated{Entity}QueryDto): Promise<PaginatedResponse<{Entity}ResponseDto>> {
    return this.{entity}Service.findAll(query);
  }

  @Get(':id')
  findOne(@Param('id', ParseIntPipe) id: number): Promise<{Entity}ResponseDto> {
    return this.{entity}Service.findOne(id);
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  create(@Body() dto: Create{Entity}Dto, @CurrentUser() user: User): Promise<{Entity}ResponseDto> {
    return this.{entity}Service.create(dto, user.id);
  }

  @Patch(':id')
  update(@Param('id', ParseIntPipe) id: number, @Body() dto: Update{Entity}Dto): Promise<{Entity}ResponseDto> {
    return this.{entity}Service.update(id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(@Param('id', ParseIntPipe) id: number): Promise<void> {
    return this.{entity}Service.remove(id);
  }
}
```

---

## 4. Providers & Dependency Injection

| What to check | Read example of |
|---|---|
| Service classes | @Injectable() — constructor injection pattern |
| Custom providers | useClass, useValue, useFactory, useExisting |
| Injection tokens | string tokens, Symbol tokens, InjectionToken |
| Provider scopes | DEFAULT (singleton), REQUEST, TRANSIENT |
| Async providers | Factory providers with async configuration |
| Optional injection | @Optional() decorator usage |
| Circular DI | @Inject(forwardRef(() => Service)) pattern |
| Provider hierarchy | How providers compose (service → repo → entity) |

**Extract as architectural:**
```
- Services are @Injectable() singletons by default
- Constructor injection for all dependencies
- Custom providers for configuration-dependent services
- Repository pattern: services inject repositories, not ORM directly
- No circular dependencies between services
```

**Extract as implementation (example):**
```typescript
@Injectable()
export class {Entity}Service {
  constructor(
    @InjectRepository({Entity})
    private readonly {entity}Repository: Repository<{Entity}>,
    private readonly configService: ConfigService,
    @Inject(forwardRef(() => Related{Entity}Service))
    private readonly relatedService: Related{Entity}Service,
  ) {}

  async findAll(query: Paginated{Entity}QueryDto): Promise<PaginatedResponse<{Entity}ResponseDto>> {
    const [items, total] = await this.{entity}Repository.findAndCount({
      skip: (query.page - 1) * query.limit,
      take: query.limit,
      order: { createdAt: 'DESC' },
    });
    return { items: items.map(toResponseDto), total, page: query.page, limit: query.limit };
  }

  async create(dto: Create{Entity}Dto, userId: number): Promise<{Entity}ResponseDto> {
    const entity = this.{entity}Repository.create({ ...dto, ownerId: userId });
    const saved = await this.{entity}Repository.save(entity);
    return toResponseDto(saved);
  }
}
```

---

## 5. Database & ORM

| What to check | Read example of |
|---|---|
| ORM choice | TypeORM / Prisma / Sequelize / Mongoose / MikroORM |
| Entity definitions | @Entity(), columns, relations, indexes |
| Repository pattern | TypeORM Repository, custom repos, @InjectRepository |
| QueryBuilder | Complex query construction patterns |
| Migrations | TypeORM migrations, Prisma migrate, migration workflow |
| Transactions | QueryRunner, EntityManager transactions |
| Seeds | How initial/test data is loaded |
| Connection config | TypeOrmModule.forRootAsync, connection options |
| Multiple databases | Multiple connections, read replicas |

**Extract as architectural:**
```
- ORM entities define database schema
- Repositories encapsulate query logic
- Transactions managed at the service layer
- Migrations for all schema changes
- Database connection configured via ConfigService
```

**Extract as implementation (example):**
```typescript
// entities/{entity}.entity.ts
@Entity('{entities}')
export class {Entity} {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ length: 255 })
  name: string;

  @Column({ type: 'enum', enum: {Entity}Status, default: {Entity}Status.ACTIVE })
  status: {Entity}Status;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @ManyToOne(() => User, (user) => user.{entities})
  @JoinColumn({ name: 'owner_id' })
  owner: User;

  @Column({ name: 'owner_id' })
  ownerId: number;
}

// database.module.ts
@Module({
  imports: [
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        type: 'postgres',
        url: config.get('DATABASE_URL'),
        entities: [__dirname + '/../**/*.entity{.ts,.js}'],
        migrations: [__dirname + '/../migrations/*{.ts,.js}'],
        synchronize: false,
      }),
    }),
  ],
})
export class DatabaseModule {}
```

---

## 6. Validation & DTOs

| What to check | Read example of |
|---|---|
| Validation library | class-validator, Zod, Joi |
| ValidationPipe | Global or per-controller pipe config |
| DTO structure | Create, Update, Response DTOs per entity |
| Decorators | @IsString(), @IsEmail(), @Min(), @MaxLength() |
| Nested validation | @ValidateNested(), @Type(() => NestedDto) |
| Partial DTOs | PartialType(), OmitType(), PickType(), IntersectionType() |
| Transform | @Transform(), class-transformer decorators |
| Custom validators | Custom validation decorator functions |
| Swagger | @ApiProperty() on DTO fields |

**Extract as architectural:**
```
- Separate Create/Update/Response DTOs per entity
- Validation decorators on DTO properties
- Global ValidationPipe with whitelist + transform
- PartialType for update DTOs (optional fields from create)
- Response DTOs exclude sensitive fields
```

**Extract as implementation (example):**
```typescript
// dto/create-{entity}.dto.ts
export class Create{Entity}Dto {
  @ApiProperty({ example: 'My {Entity}' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(255)
  name: string;

  @ApiPropertyOptional({ enum: {Entity}Status, default: {Entity}Status.ACTIVE })
  @IsEnum({Entity}Status)
  @IsOptional()
  status?: {Entity}Status;
}

// dto/update-{entity}.dto.ts
export class Update{Entity}Dto extends PartialType(Create{Entity}Dto) {}

// dto/{entity}-response.dto.ts
export class {Entity}ResponseDto {
  @ApiProperty()
  id: number;

  @ApiProperty()
  name: string;

  @ApiProperty()
  status: {Entity}Status;

  @ApiProperty()
  createdAt: Date;
}

// main.ts
app.useGlobalPipes(new ValidationPipe({
  whitelist: true,
  forbidNonWhitelisted: true,
  transform: true,
  transformOptions: { enableImplicitConversion: true },
}));
```

---

## 7. Authentication & Authorization

| What to check | Read example of |
|---|---|
| Auth strategy | @nestjs/passport strategies (JWT, Local, OAuth) |
| Guard implementation | AuthGuard, JwtAuthGuard, custom guards |
| JWT config | JwtModule.registerAsync, token expiry, secret |
| Custom decorators | @CurrentUser(), @Public(), @Roles() |
| Role-based access | RolesGuard, @Roles() decorator pattern |
| Policies | CASL integration, policy-based authorization |
| Auth module | AuthModule structure — service, controller, strategies |
| Token refresh | Refresh token flow and rotation |
| API key auth | Custom guard for API key validation |

**Extract as architectural:**
```
- JWT-based auth with Passport strategies
- Global JwtAuthGuard with @Public() to opt-out
- Role-based access via @Roles() decorator + RolesGuard
- Custom @CurrentUser() decorator to extract user from request
- Auth module encapsulates all auth logic
```

**Extract as implementation (example):**
```typescript
// guards/jwt-auth.guard.ts
@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
  constructor(private reflector: Reflector) { super(); }

  canActivate(context: ExecutionContext) {
    const isPublic = this.reflector.getAllAndOverride(IS_PUBLIC_KEY, [
      context.getHandler(), context.getClass(),
    ]);
    if (isPublic) return true;
    return super.canActivate(context);
  }
}

// decorators/current-user.decorator.ts
export const CurrentUser = createParamDecorator(
  (data: string, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    return data ? request.user?.[data] : request.user;
  },
);

// decorators/roles.decorator.ts
export const Roles = (...roles: Role[]) => SetMetadata('roles', roles);
```

---

## 8. Error Handling

| What to check | Read example of |
|---|---|
| Exception filters | @Catch(), ExceptionFilter implementation |
| HttpException | Built-in exceptions or custom subclasses |
| Custom exceptions | Domain-specific exception classes |
| Global filters | APP_FILTER provider or app.useGlobalFilters() |
| Error response | Consistent error response format |
| Validation errors | How validation pipe errors are formatted |
| Logging on errors | What gets logged on exceptions |

**Extract as architectural:**
```
- Custom exception classes for domain errors
- Global exception filter formats all errors consistently
- Services throw domain exceptions, not HttpException
- Exception filter maps domain exceptions to HTTP status codes
- Validation errors formatted with field-level details
```

**Extract as implementation (example):**
```typescript
// exceptions/{entity}-not-found.exception.ts
export class {Entity}NotFoundException extends NotFoundException {
  constructor(id: number) {
    super(`{Entity} with id ${id} not found`);
  }
}

// filters/all-exceptions.filter.ts
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const status = exception instanceof HttpException ? exception.getStatus() : 500;
    const message = exception instanceof HttpException ? exception.getResponse() : 'Internal server error';

    response.status(status).json({
      statusCode: status,
      message: typeof message === 'string' ? message : (message as any).message,
      timestamp: new Date().toISOString(),
    });
  }
}
```

---

## 9. Guards, Interceptors, Pipes & Middleware

| What to check | Read example of |
|---|---|
| Guards | @UseGuards() — auth, roles, throttle |
| Interceptors | @UseInterceptors() — transform, cache, logging, timeout |
| Pipes | @UsePipes() — validation, parse (ParseIntPipe, etc.) |
| Middleware | NestMiddleware — logging, request context |
| Execution order | Guard → Interceptor (before) → Pipe → Handler → Interceptor (after) → Filter |
| Custom decorators | Composed decorators combining guard + metadata |
| Global registration | Global vs controller vs route-level application |

**Extract as architectural:**
```
- Guards for authorization decisions (can this user do this?)
- Interceptors for cross-cutting response transformation
- Pipes for input validation and transformation
- Middleware for request-level concerns (logging, context)
- Prefer decorators over manual middleware registration
```

---

## 10. Testing

| What to check | Read example of |
|---|---|
| Test framework | Jest (default NestJS) |
| Module testing | Test.createTestingModule() setup |
| Mock providers | How services/repos are mocked in unit tests |
| Controller tests | How controller endpoints are tested |
| Service tests | How services are tested with mocked dependencies |
| E2E tests | INestApplication, supertest, test database |
| Test utils | Custom test utilities, shared mocking helpers |
| Fixtures | Factory functions, test data builders |
| Coverage | Coverage config, thresholds |

**Extract as architectural:**
```
- Unit tests colocated with source (*.spec.ts)
- Test.createTestingModule for DI setup in tests
- Services tested with mocked repositories
- Controllers tested with mocked services
- E2E tests use real app instance + test database
```

**Extract as implementation (example):**
```typescript
// {entity}.service.spec.ts
describe('{Entity}Service', () => {
  let service: {Entity}Service;
  let repo: jest.Mocked<Repository<{Entity}>>;

  beforeEach(async () => {
    const module = await Test.createTestingModule({
      providers: [
        {Entity}Service,
        {
          provide: getRepositoryToken({Entity}),
          useValue: {
            findAndCount: jest.fn(),
            findOne: jest.fn(),
            create: jest.fn(),
            save: jest.fn(),
            remove: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get({Entity}Service);
    repo = module.get(getRepositoryToken({Entity}));
  });

  describe('findOne', () => {
    it('should return entity when found', async () => {
      const entity = { id: 1, name: 'Test' } as {Entity};
      repo.findOne.mockResolvedValue(entity);
      expect(await service.findOne(1)).toEqual(entity);
    });

    it('should throw NotFoundException when not found', async () => {
      repo.findOne.mockResolvedValue(null);
      await expect(service.findOne(1)).rejects.toThrow({Entity}NotFoundException);
    });
  });
});

// e2e/{entity}.e2e-spec.ts
describe('{Entity}Controller (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = module.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ whitelist: true }));
    await app.init();
  });

  it('GET /{entities} should return list', () => {
    return request(app.getHttpServer())
      .get('/{entities}')
      .set('Authorization', `Bearer ${token}`)
      .expect(200)
      .expect((res) => expect(res.body.data).toBeInstanceOf(Array));
  });
});
```

---

## 11. Coding Style Fingerprint

This section captures the **personal coding style** of the team — not WHAT they build but HOW they write NestJS code. Read 5-6 diverse files to extract these signals.

| Signal | What to look for |
|---|---|
| Decorator density | Minimal (only required) or heavy (Swagger, validation, custom)? |
| Class vs functional | Everything class-based or some functional patterns? |
| Export style | One class per file? Multiple exports? Barrel re-exports? |
| DI style | Constructor injection only? @Inject() for tokens? |
| Async patterns | async/await everywhere? Observable (RxJS) anywhere? |
| Comment style | JSDoc? `// TODO`? Inline comments? None? |
| Import order | @nestjs → third-party → local? Separator lines? |
| Type definitions | Interfaces for contracts? Types for DTOs? Enums? |
| Error handling | Custom exceptions? Built-in HttpException? |
| File length | Short focused files (<100 lines) or large files (300+ lines)? |
| Test style | Arrange-Act-Assert? Given-When-Then? describe/it nesting? |
| DTO style | Separate file per DTO or all DTOs in one file per module? |

**Extract as a style profile:**
```
CODING STYLE PROFILE:
- Decorators: heavy — Swagger + validation + custom on every endpoint
- Classes: everything class-based following NestJS conventions
- Exports: one class per file, barrel re-exports via index.ts
- DI: constructor injection, @Inject() only for tokens
- Async: async/await, no Observables (except WebSocket)
- Comments: minimal — only JSDoc on public service methods
- Imports: @nestjs/* → third-party → @app/* → relative
- Types: interfaces for contracts, enums for constants
- Errors: custom exception classes extending HttpException
- Files: focused (< 150 lines), split when growing
- Tests: describe/it with Arrange-Act-Assert comments
- DTOs: one file per DTO class
```

---

## 12. Inconsistencies & Anti-patterns

Look for places where the team does NOT follow their own patterns. These are critical to document so the generated skill avoids reproducing mistakes.

| What to look for | Why it matters |
|---|---|
| Business logic in controllers (bypassing services) | Inconsistent layer separation |
| Direct repository access in controllers | Skipping service layer |
| Missing DTOs (raw objects as request body) | No validation on some endpoints |
| @Injectable() scope inconsistencies | Mixing singleton and request-scoped |
| Circular module dependencies | forwardRef overuse |
| Missing guards on sensitive endpoints | Security gap |
| Mixed response formats (some wrap, some don't) | Inconsistent API |
| Raw entity returned (no response DTO) | Exposes DB structure |
| Unused providers in module declarations | Dead code |

**Document as:**
```
INCONSISTENCIES FOUND:
- ❌ src/legacy/legacy.controller.ts — queries database directly, no service
  → AVOID: always inject service, never repository in controller
- ❌ src/reports/reports.controller.ts — returns raw entity, no response DTO
  → AVOID: always map to response DTO
- ❌ 3 of 10 modules missing Swagger decorators
  → RULE: every endpoint MUST have @ApiOperation and @ApiResponse

DECISION: When inconsistency found, follow the MAJORITY pattern (the one used most).
```

---

## 13. Advanced (if present)

Only scan these if they exist in the project:

### GraphQL
- @nestjs/graphql, @Resolver(), @Query(), @Mutation()
- Schema-first vs code-first approach
- DataLoader pattern for N+1 prevention
- Subscriptions

### CQRS
- @nestjs/cqrs, commands, queries, events, sagas
- Command/Query bus patterns
- Event sourcing (if present)

### Microservices
- @nestjs/microservices, transport layer (TCP, Redis, RabbitMQ, Kafka)
- @MessagePattern(), @EventPattern()
- Client proxy patterns

### WebSocket
- @WebSocketGateway(), @SubscribeMessage()
- Namespace/room patterns
- Auth for WebSocket connections

### Health Checks
- @nestjs/terminus, HealthController
- Custom health indicators
- Database, Redis, external service checks

### Task Scheduling
- @nestjs/schedule, @Cron(), @Interval()
- Queue processing with @nestjs/bull

### Caching
- @nestjs/cache-manager, @CacheKey(), @CacheTTL()
- Cache interceptor patterns
- Redis cache store

### Swagger
- @nestjs/swagger setup
- Swagger plugin in nest-cli.json
- Decorator patterns for auto-documentation
