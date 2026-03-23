# Output Structure Guide

Defines what the generated skill must contain and how to organize reference files.

---

## Skill Directory

**One concern = one file.** Create a separate reference file for every distinct pattern category found in the project. Prefer many focused files (50-150 lines) over few large ones (300+ lines). If a section within a file grows past 80 lines, split it into its own file.

```
{project-name}-generator/
├── SKILL.md                    # < 500 lines, workflow + rules + reference pointers
└── references/                 # Each file < 300 lines, examples-first
    ├── architecture.md         # Project structure, config templates, feature slice anatomy
    ├── data-layer.md           # Repositories, data sources, Dio/http config, DTOs, mappers
    ├── widgets.md              # Widget patterns, composition, stateless/stateful, custom widgets
    ├── state-management.md     # BLoC/Cubit, Riverpod, Provider -- events, states, builders
    ├── navigation.md           # Router setup, route guards, deep linking, path constants
    ├── forms.md                # Form widgets, validation, submit flow, complex forms
    ├── di.md                   # get_it + injectable, Riverpod providers, service locator pattern
    ├── ui-theming.md           # ThemeData, ColorScheme, TextTheme, responsive, dark mode
    ├── conventions.md          # Naming table, file organization, barrel files, enum patterns
    ├── coding-style.md         # final vs var, cascades, extensions, null safety, imports
    ├── testing.md              # Unit, widget, integration, BLoC tests, mocking, golden tests
    ├── error-handling.md       # Failure classes, Either pattern, snackbars, loading/empty states
    └── performance.md          # const constructors, RepaintBoundary, lazy loading (if applicable)
```

This is the minimum set. Create additional reference files for any project-specific patterns found (i18n, Firebase, animations, platform channels, code generation, etc.).

---

## What goes in each file

### architecture.md
- Directory structure template with annotations
- Feature slice anatomy (what goes in data/, domain/, presentation/ per feature)
- core/ vs features/ vs shared/ -- decision criteria
- Config file templates: pubspec.yaml deps, analysis_options.yaml, build.yaml
- Entry point: main.dart (DI init, error handling bootstrap, runApp)
- App widget: MaterialApp.router or MaterialApp with theme, localization, router

### data-layer.md
- HTTP client setup (Dio instance with interceptors -- full code template)
- Interceptor patterns (auth token, error transform, logging, refresh)
- DTO template with Freezed + json_serializable
- Domain entity template (clean, no serialization)
- Mapper pattern (extension or class): DTO -> Entity
- Repository interface template (in domain/)
- Repository implementation template (in data/)
- Remote data source template
- Local data source template (if applicable)
- Either<Failure, T> pattern for error handling
- API response envelope unwrapping (if present)

### widgets.md
- Stateless widget template (with const constructor, named parameters)
- Stateful widget template (with dispose, initState patterns)
- Widget decomposition strategy (when to split into sub-widgets)
- Custom widget API design (callback types, required vs optional params)
- List item widget template
- Card widget template
- Dialog/BottomSheet widget template
- Builder widget usage (BlocBuilder, Consumer, ref.watch)
- Composition patterns (children, builder callbacks)

### state-management.md
- BLoC template: event sealed class, state sealed class, BLoC class with handlers
- Cubit template: state class, Cubit class with methods
- Riverpod template: StateNotifierProvider, FutureProvider, NotifierProvider
- Provider template: ChangeNotifier class, Consumer/Selector usage
- State shape conventions (loading, loaded, error patterns)
- How widgets connect to state (BlocBuilder, BlocListener, BlocConsumer)
- When to use which (BLoC for complex, Cubit for simple)
- State persistence (if applicable)

### navigation.md
- Router setup (GoRouter, AutoRoute, or Navigator)
- Route definition template
- Route guard / redirect pattern
- Path constants pattern (abstract class with static const)
- Shell routes for bottom navigation
- Deep linking with path parameters
- Page transitions (if custom)
- Nested navigation pattern (if present)

### forms.md
- Form + GlobalKey<FormState> template
- TextFormField with validator template
- Custom FormField template (if present)
- Form submission: validate -> call BLoC/repository -> handle result
- Error display patterns (field-level, form-level)
- Complex form patterns (multi-step, dynamic fields)
- reactive_forms / flutter_form_builder template (if used)

### di.md
- DI container setup (get_it + injectable, or Riverpod, or manual)
- Module organization pattern
- Registration types: lazySingleton, factory, singleton
- Initialization order (in main.dart before runApp)
- Feature-scoped registrations vs global
- How to add a new dependency

### ui-theming.md
- ThemeData definition (light + dark)
- ColorScheme from seed or custom
- TextTheme customization (GoogleFonts or custom)
- Input decoration theme
- AppBar theme, Card theme, etc.
- Dark mode toggle mechanism
- Spacing constants (if standardized)
- Custom ThemeExtension<T> (if present)
- Responsive breakpoints and utilities

### conventions.md
- Complete naming table (feature folders, files, classes, variables)
- Import conventions (dart: -> package: -> relative, or all package:)
- Barrel file patterns
- Enum patterns (enhanced enums with methods, or const + type)
- Type patterns (typedef usage, generic constraints)
- File organization rules (one class per file, max file length)
- Folder naming (snake_case)
- Class naming (PascalCase)
- Variable naming (camelCase)
- Private member naming (_prefixed)

### coding-style.md
- Variable declaration: final vs var vs explicit type
- Parameter style: named + required vs positional
- Trailing commas: enforced or optional
- Cascade notation usage patterns
- Extension method patterns
- Const constructor usage
- Null safety: ?. vs ! vs late vs required patterns
- String interpolation style
- Comment style: /// vs // vs none
- Import order and grouping
- Guard clauses (early returns) vs nested conditionals
- File length preferences
- Dart 3+ features: sealed classes, patterns, records

### testing.md
- Test runner config: dart_test.yaml, test/ directory structure
- Unit test template: group, test, expect
- Widget test template: pumpWidget, finder, expect
- BLoC test template: blocTest(), build, act, expect
- Repository test template: mock data source, verify
- Mocking approach: mockito (code gen), mocktail (manual), or fake
- Test data: fixtures file, factory functions, or inline objects
- Integration test template (if present)
- Golden test template (if present)
- Custom test helpers and utilities

### error-handling.md
- Failure class hierarchy (abstract Failure -> ServerFailure, CacheFailure, etc.)
- Exception classes (ServerException, CacheException, etc.)
- Either<Failure, T> usage in repositories
- BLoC error state handling
- UI error display: SnackBar, dialog, inline error widget
- Loading states: CircularProgressIndicator, Shimmer, custom skeleton
- Empty states: empty state widget pattern
- Global error handler (FlutterError.onError, PlatformDispatcher.onError)
- Network connectivity handling

### performance.md (generate only if project has these patterns)
- const constructor usage philosophy
- RepaintBoundary placement
- ListView.builder vs ListView for long lists
- Image caching: CachedNetworkImage, precacheImage
- Compute/Isolate for heavy computation
- Deferred imports / lazy loading
- Widget rebuild optimization (Selector, BlocSelector)
- Build method splitting (smaller widget trees)

---

## Two-Layer Rule

EVERY pattern in every reference file must have:

1. **Architecture section** -- Framework-agnostic description of the pattern
2. **Implementation section** -- Exact Dart/Flutter code template for the detected pattern

Two layers = adaptable. The architecture sections alone are enough to implement the patterns in any framework.

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
