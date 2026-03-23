---
name: flutter-project-scanner
description: >
  Scans any Flutter/Dart project to extract its complete architecture, patterns, coding style, and
  conventions — then generates an autonomous skill that creates new projects following those exact
  patterns. Optionally uses Repomix to pack the codebase first. Also generates a .context/ directory
  for tool-agnostic compatibility (Cursor, Copilot, etc.). Use this skill whenever someone wants to
  analyze a Flutter codebase and turn its patterns into a reusable generator, capture coding standards
  from an existing app, create a "project template" based on a real codebase, or replicate an
  architecture for a new business idea. Triggers: "scan my flutter project", "extract flutter patterns",
  "create a generator from this dart code", "turn this flutter app into a template", "make a skill
  from my flutter app".
---

# Flutter Codebase Pattern Extractor

Scans a Flutter/Dart project -> extracts architectural patterns in two layers (agnostic + Flutter/Dart-specific) -> generates a self-contained skill that creates new projects from a business idea.

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

Confirm which project to scan. Detect it is a Flutter project from `pubspec.yaml` (look for `flutter` SDK dependency). Identify architecture pattern (Clean Architecture, MVVM, BLoC, feature-first, layer-first) and state management solution first -- these determine everything else.

### Step 2: Run the structure scanner

```bash
bash <skill-path>/scripts/scan-structure.sh <project-path>
```

This outputs: directory tree, dependencies from pubspec.yaml, config files, architecture pattern detection, state management detection, and auto-selects 1 representative file per pattern category.

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
3. Classify as **architectural** (framework-agnostic) or **implementation** (Flutter/Dart-specific)
4. Note any **inconsistencies** (files that don't follow the majority pattern)

**Example -- extracting a data-fetching pattern:**

```
ARCHITECTURAL (agnostic):
  - Each API endpoint gets its own repository method
  - DTOs are separate from domain entities
  - Mapper functions transform DTO -> Entity
  - Repository interface in domain, implementation in data layer

IMPLEMENTATION (Flutter-specific):
  - Dio with interceptors for HTTP client
  - Freezed models with fromJson/toJson via json_serializable
  - Repository pattern: abstract class in domain/, impl in data/
  - BLoC consumes repository, emits states

INCONSISTENCY:
  - lib/features/reports/ calls Dio directly -- legacy, do NOT replicate
```

### Step 5: Decision log

For each major pattern, document WHY the team chose it over alternatives:

```
DECISIONS:
  - BLoC over Riverpod -> explicit state transitions, testable (seen: every feature has *_bloc.dart + *_state.dart + *_event.dart)
  - Freezed over manual models -> immutable, union types, copyWith (seen: *.freezed.dart everywhere)
  - GoRouter over Navigator 2.0 -> declarative routing, deep linking (seen: router.dart with GoRoute definitions)
  - get_it over manual DI -> service locator, lazy singletons (seen: injection_container.dart)
```

Look for evidence in: comments, README, pubspec.yaml dev_dependencies, analysis_options.yaml rules, and the absence of alternatives in dependencies.

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
    ├── data-layer.md                # Repositories, data sources, Dio/http config, DTOs, mappers
    ├── widgets.md                   # Widget patterns, composition, stateless/stateful, custom widgets
    ├── state-management.md          # BLoC/Cubit, Riverpod, Provider, state classes
    ├── navigation.md                # GoRouter/AutoRoute, guards, deep linking, path constants
    ├── forms.md                     # Form widgets, validation, reactive_forms, form state
    ├── di.md                        # get_it + injectable, Riverpod providers, service locator
    ├── ui-theming.md                # ThemeData, ColorScheme, TextTheme, responsive, dark mode
    ├── conventions.md               # Naming, file organization, barrel files, enums
    ├── coding-style.md              # final vs var, cascades, extensions, null safety, imports
    ├── testing.md                   # Unit, widget, integration, BLoC tests, mocking, golden tests
    ├── error-handling.md            # Error classes, failure handling, snackbars, loading/empty states
    └── performance.md               # const constructors, RepaintBoundary, lazy loading (if applicable)
```

This is the minimum set. Create additional reference files for any project-specific patterns found (i18n, Firebase, animations, platform channels, code generation, etc.).

### Two-layer rule (every reference file)

Each reference file MUST contain both layers:

```markdown
## Data Layer

### Architecture (framework-agnostic)
- Repository interface defines contract in domain layer
- Implementation in data layer uses HTTP client
- DTOs map to domain entities via extension methods or mapper classes
- Error handling converts exceptions to domain failures

### Flutter Implementation
\```dart
abstract class {Entity}Repository {
  Future<Either<Failure, List<{Entity}>>> getAll();
  Future<Either<Failure, {Entity}>> getById(String id);
}

class {Entity}RepositoryImpl implements {Entity}Repository {
  final {Entity}RemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  const {Entity}RepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<{Entity}>>> getAll() async {
    try {
      final dtos = await remoteDataSource.getAll();
      return Right(dtos.map((dto) => dto.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
\```
```

Two layers = works for the scanned framework and can be adapted to others.

---

## Phase 3: Generate .context/ (tool-agnostic compatibility)

After generating the skill, also create a `.context/` directory following the Codebase Context Specification. This makes the extracted patterns usable by ANY AI tool (Cursor, Copilot, Windsurf, etc.), not just Claude.

Read `<skill-path>/references/context-spec.md` for the exact format.

### Generated .context/ structure

```
{project-name}-generator/
├── .context/
│   ├── index.md                     # Overview: architecture, stack, key decisions
│   ├── architecture.md              # Directory structure, feature slices, separation of concerns
│   ├── conventions.md               # Naming rules, patterns, do/don't examples
│   ├── patterns.md                  # Data layer, forms, state, routing, error handling, testing
│   └── style.md                     # Coding style profile: declarations, null safety, async, imports
├── SKILL.md
└── references/
    └── ...
```

The `.context/` files are a **condensed, prose-friendly** version of the skill references -- designed for tools that read markdown context but don't understand skill workflows.

---

## Phase 4: Write the generated SKILL.md

The generated SKILL.md must follow this pipeline:

### Step 1: Refine the idea (ASK the user)
- Core features (3-5 main things users can do)
- User roles (admin, user, guest)
- Key screens/pages
- Data models (main entities + relationships)
- API endpoints needed per entity

Present a summary table and confirm before proceeding.

### Step 2: Plan architecture
Map features to the project's feature structure. Output a directory tree.

### Step 3: Generate in order
```
pubspec.yaml + analysis_options.yaml --> core/utils --> DI setup --> models/entities --> data layer (repositories + data sources) --> state management (BLoCs/providers) --> widgets/components --> screens/pages --> navigation/routing --> app entry point (main.dart + app.dart)
```

### Step 4: Validate (feedback loop)
```
Generate code -> Check imports resolve -> Check naming matches conventions -> Check patterns match references -> Check build_runner codegen files referenced correctly -> Fix issues -> Repeat
```

The generated skill MUST include this validation loop. Without it, generated code will have broken imports and inconsistent patterns.

---

## Phase 5: Verify

Before delivering, validate with this test: given the prompt "I want a task management app", the generated skill must produce a project indistinguishable from the original team's code.

Check:
- [ ] SKILL.md under 500 lines
- [ ] All references one level deep (no nested references)
- [ ] Description in third person with trigger phrases
- [ ] Every reference has BOTH architectural + implementation layers
- [ ] Code examples use `{placeholders}` not hardcoded names
- [ ] Validation feedback loop included
- [ ] Generation order is explicit (pubspec -> core -> DI -> models -> data -> state -> widgets -> screens -> nav -> main)
- [ ] .context/ directory generated with index.md, architecture.md, conventions.md, patterns.md, style.md
- [ ] coding-style.md captures the team's Dart style (final vs var, cascades, extensions, null safety)
- [ ] testing.md captures test runner, mocking strategy, and test templates
- [ ] error-handling.md captures failure classes, snackbar patterns, loading/empty states
- [ ] state-management.md captures BLoC/Cubit/Riverpod/Provider patterns with full event/state templates
- [ ] Inconsistencies documented -- generated skill follows the MAJORITY pattern
- [ ] Decision log included -- WHY each major tool/pattern was chosen
- [ ] Additional reference files created for any project-specific patterns (i18n, Firebase, animations, etc.)

---

## Key Principles

**Examples > prose.** A code snippet with `{placeholders}` teaches better than a paragraph of description.

**Only include what Claude can't infer.** Don't explain what a Repository is. DO show your specific repository pattern with Freezed models, Either types, and failure handling.

**Appropriate freedom.** Exact scripts for fragile operations (directory structure, pubspec.yaml, analysis_options). High freedom for widget internals and business logic.

**Generic placeholders.** Replace `TaskModel` with `{Entity}`, `TaskBloc` with `{Entity}Bloc`, `/tasks` with `/{resource}`. Keep structural patterns intact.

**Two outputs, one scan.** The skill (SKILL.md + references/) is for Claude. The .context/ is for everything else. Same patterns, different format.
