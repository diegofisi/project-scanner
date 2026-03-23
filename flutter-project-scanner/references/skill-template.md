# Generated Skill Template

Use this template to write the SKILL.md for the generated project-generator skill. Adapt based on what was actually found in the scanned Flutter project.

---

## Frontmatter

```yaml
---
name: {project-name}-generator
description: >
  Generates complete, production-ready Flutter applications following the {project-name}
  architecture. Given a business idea, refines it into features and produces a fully functional
  app with {key-stack-summary}. Triggers: "create a flutter app", "build me a mobile app",
  "new flutter project for...", "scaffold an app that...", or any request to create a Flutter
  application from a concept or business idea.
---
```

Description must be in third person. Include specific trigger phrases.

---

## SKILL.md Body Structure

### Section 1: Overview (5-10 lines)

```markdown
# {ProjectName} Generator

Generates Flutter applications following a production-tested architecture.

## Stack
Flutter {version} + Dart {version} | {state-management} | {http-client} | {navigation} | {di-solution} | {code-gen}
```

Keep this SHORT. One line per concern, no explanations.

### Section 2: Pipeline (the core workflow)

```markdown
## From Idea to Project

### Step 1: Refine the Idea
ASK the user (do not assume):
- What are the 3-5 core features?
- What user roles exist? (admin, user, guest)
- What are the main screens/pages?
- What are the data entities and their relationships?
- What API operations per entity? (CRUD? custom?)
- What platforms? (iOS, Android, Web, Desktop)

Present a summary table and confirm before proceeding.

### Step 2: Plan Architecture
Map features -> feature slices. Output:

\```
lib/
├── core/                # Cross-feature shared code
│   ├── di/              # Dependency injection setup
│   ├── error/           # Failure classes, error handler
│   ├── network/         # Dio client, interceptors
│   ├── router/          # GoRouter / AutoRoute setup
│   ├── theme/           # ThemeData, colors, text styles
│   ├── utils/           # Extensions, helpers, constants
│   └── widgets/         # Shared reusable widgets
├── features/            # Feature modules
│   └── {feature}/
│       ├── data/
│       │   ├── datasources/    # Remote + local data sources
│       │   ├── models/         # DTOs (Freezed + json_serializable)
│       │   └── repositories/   # Repository implementations
│       ├── domain/
│       │   ├── entities/       # Domain models (pure Dart)
│       │   ├── repositories/   # Abstract repository contracts
│       │   └── usecases/       # Use case classes
│       └── presentation/
│           ├── bloc/           # BLoC/Cubit + events + states
│           ├── pages/          # Screen-level widgets
│           └── widgets/        # Feature-specific widgets
├── app.dart             # MaterialApp widget
└── main.dart            # Entry point (DI init, runApp)
\```

### Step 3: Generate (in this exact order)

1. **Config** -- pubspec.yaml, analysis_options.yaml, build.yaml, l10n.yaml (if i18n)
   Read `references/architecture.md` for config templates.

2. **Core / Shared layer**
   - `core/error/` -- Failure classes, exception classes
   - `core/network/` -- Dio client, interceptors
   - `core/utils/` -- Extensions, constants, helpers
   - `core/theme/` -- ThemeData (light + dark), colors, text styles
   - `core/widgets/` -- Shared widgets (loading indicator, error widget, empty state)
   Read `references/ui-theming.md` + `references/error-handling.md`

3. **DI setup** -- injection container, module registrations
   Read `references/di.md`

4. **Models / Entities** -- for each entity:
   - Domain entity (pure Dart class or Freezed)
   - DTO (Freezed + json_serializable)
   - Mapper (DTO -> Entity extension)
   Read `references/data-layer.md`

5. **Data layer** -- for each feature:
   - Remote data source (API calls)
   - Local data source (if caching)
   - Repository interface (in domain/)
   - Repository implementation (in data/)
   Read `references/data-layer.md`

6. **State management** -- for each feature:
   - BLoC/Cubit with events and states (or Riverpod providers)
   Read `references/state-management.md`

7. **Widgets / Components** -- shared and feature-specific
   Read `references/widgets.md`

8. **Screens / Pages** -- for each feature:
   - List page, detail page, create/edit page
   Read `references/widgets.md` + `references/forms.md`

9. **Navigation / Routing** -- wire all pages into router
   Read `references/navigation.md`

10. **App entry point** -- main.dart + app.dart
    Connect DI, router, theme, localization
    Read `references/architecture.md`

### Step 4: Validate (MANDATORY feedback loop)
After generating, run this checklist:

\```
Validation:
- [ ] All imports resolve (no missing files, correct package: paths)
- [ ] pubspec.yaml lists all used dependencies
- [ ] analysis_options.yaml rules match coding style
- [ ] Every model uses the project's serialization approach (Freezed/json_serializable/manual)
- [ ] Every repository follows interface + implementation pattern
- [ ] DTOs and entities are separate (if Clean Architecture)
- [ ] Mappers exist for every DTO -> Entity conversion
- [ ] State management follows the project's pattern (BLoC events/states, Riverpod providers, etc.)
- [ ] Every screen connects to state via correct builder (BlocBuilder, Consumer, ref.watch)
- [ ] Naming matches conventions (Read references/conventions.md)
- [ ] Navigation uses path constants, not string literals
- [ ] Route guards protect authenticated routes
- [ ] Forms validate before submission
- [ ] Error handling follows Either/Failure pattern (or project's approach)
- [ ] const constructors used where possible
- [ ] Trailing commas match project style
- [ ] Code style matches coding-style.md (final vs var, extensions, null safety)
- [ ] Test files follow testing.md patterns (if tests are being generated)
- [ ] build_runner generated files (.g.dart, .freezed.dart) are referenced but NOT manually written
\```

Fix any issues found, then re-validate.
```

### Section 3: Reference pointers

```markdown
## References

| File | Read when |
|------|-----------|
| `references/architecture.md` | Planning structure, creating config files, entry point |
| `references/data-layer.md` | Creating repositories, data sources, DTOs, HTTP client |
| `references/widgets.md` | Building any widget (screens, components, dialogs) |
| `references/state-management.md` | Creating BLoCs/Cubits, providers, connecting state to UI |
| `references/navigation.md` | Setting up routes, guards, deep linking |
| `references/forms.md` | Building forms with validation |
| `references/di.md` | Registering dependencies, adding new services |
| `references/ui-theming.md` | Styling, theming, colors, responsive layout |
| `references/conventions.md` | Naming anything (files, classes, variables, folders) |
| `references/coding-style.md` | Writing any Dart code -- ensures style matches original team |
| `references/testing.md` | Creating unit, widget, BLoC, or integration tests |
| `references/error-handling.md` | Adding failure classes, error UI, loading/empty states |
| `references/performance.md` | Optimizing widgets, lists, images, heavy computation |

**NOTE:** Additional reference files may exist for project-specific patterns (i18n, Firebase, animations, etc.). Check the references/ directory for the full list.
```

### Section 4: Critical rules (non-negotiable, extracted from scan)

```markdown
## Rules

{Extract from scanned project. Examples:}
- NEVER put business logic in widgets -- always in BLoC/Cubit/Provider
- NEVER use dynamic type -- always use typed models
- EVERY API call goes through a repository (never call Dio from a widget)
- EVERY model uses Freezed + json_serializable (no manual fromJson)
- EVERY feature follows data/domain/presentation structure
- Repository interfaces live in domain/, implementations in data/
- DTOs and entities are ALWAYS separate classes with mapper
- All widget constructors MUST be const
- Use Either<Failure, T> for all repository return types
- Named parameters for all widget constructors (positional only for simple utility functions)
- Path constants for all routes (never inline string paths)
- Trailing commas enforced on all multi-line argument lists
```

---

## Reference File Guidelines

Each reference file must:

1. **Be under 300 lines** (add TOC if over 100 lines)
2. **Lead with code examples** -- prose only to explain WHY
3. **Use `{placeholders}`** -- `{Entity}`, `{Feature}`, `{resource}`
4. **Include Do/Don't** -- show the anti-pattern next to the correct pattern
5. **Contain BOTH layers** -- architectural (agnostic) + implementation (Flutter/Dart-specific)
6. **One concern = one file.** Create a separate file for every distinct pattern category. If a section exceeds 80 lines, split it into its own file. A complex project should produce 15-20+ reference files

**Example structure for a reference file:**

```markdown
# Data Layer Patterns

## Contents
- HTTP Client Setup
- Repository Pattern
- DTO & Mapper Pattern
- Error Handling

## HTTP Client Setup

### Architecture
- Single configured instance with interceptors
- Request: inject auth token
- Response: unwrap API envelope, handle 401 with token refresh

### Implementation
\```dart
final dio = Dio(BaseOptions(
  baseUrl: AppConfig.apiBaseUrl,
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 10),
));

dio.interceptors.addAll([
  AuthInterceptor(tokenStorage: sl()),
  ErrorInterceptor(),
  LogInterceptor(requestBody: true, responseBody: true),
]);
\```

## Repository Pattern

### Architecture
- Interface in domain/ defines the contract
- Implementation in data/ handles HTTP + error mapping
- Returns Either<Failure, T> -- never throws

### Implementation
\```dart
abstract class {Entity}Repository {
  Future<Either<Failure, List<{Entity}>>> getAll();
  Future<Either<Failure, {Entity}>> getById(String id);
  Future<Either<Failure, {Entity}>> create(Create{Entity}Params params);
  Future<Either<Failure, Unit>> delete(String id);
}
\```

### Don't
\```dart
// Never call Dio directly from a widget or BLoC
class {Entity}Bloc extends Bloc<{Entity}Event, {Entity}State> {
  final Dio dio; // WRONG -- should depend on repository, not HTTP client
}
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
│   ├── architecture.md   # Directory structure + feature slice anatomy
│   ├── conventions.md    # Naming table + do/don't rules
│   ├── patterns.md       # Data layer + forms + state + routing templates
│   └── style.md          # Coding style profile (final vs var, cascades, null safety, etc.)
├── SKILL.md
└── references/
    └── ...
```
