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
  - Flutter
  - Dart
  - {state-management}
  - {http-client}
  - {navigation}
  - {di-solution}
  - {code-generation}
conventions:
  - {convention-1}
  - {convention-2}
  - {convention-3}
architecture-style: {e.g., "Clean Architecture with feature-first organization and BLoC pattern"}
---

# {ProjectName} Architecture

## Overview
{1-2 sentences describing the project architecture}

## Stack
Flutter {version} + Dart {version} | {state-mgmt} | {http-client} | {navigation} | {di-solution} | {code-gen}

## Key Decisions
- **Directory structure**: {Clean Architecture per-feature / layer-first / feature-first}
- **State management**: {BLoC/Cubit / Riverpod / Provider / GetX} -- why chosen
- **Data flow**: {DTO -> mapper -> entity via Either<Failure, T>}
- **DI**: {get_it + injectable / Riverpod / manual}
- **Models**: {Freezed + json_serializable / manual / json_serializable only}
- **Navigation**: {GoRouter / AutoRoute / Navigator} -- declarative vs imperative
- **Styling**: {Material 3 / Cupertino / custom} with {theming approach}
```

### .context/architecture.md

Condensed version of the skill's `references/architecture.md`. Focus on:

```markdown
# Architecture

## Directory Structure
\```
lib/
├── core/                # Cross-feature shared code
│   ├── di/              # Dependency injection setup
│   ├── error/           # Failure + exception classes
│   ├── network/         # HTTP client + interceptors
│   ├── router/          # Route definitions + guards
│   ├── theme/           # ThemeData + colors + text styles
│   ├── utils/           # Extensions, helpers, constants
│   └── widgets/         # Shared reusable widgets
├── features/            # Feature modules
│   └── {feature}/
│       ├── data/
│       │   ├── datasources/
│       │   ├── models/
│       │   └── repositories/
│       ├── domain/
│       │   ├── entities/
│       │   ├── repositories/
│       │   └── usecases/
│       └── presentation/
│           ├── bloc/
│           ├── pages/
│           └── widgets/
├── app.dart
└── main.dart
\```

## Feature Slice Anatomy
{describe what goes where within a feature}

## Core vs Features
- **core/**: Cross-cutting concerns (network, DI, theme, error handling, shared widgets)
- **features/**: Business domain modules, each self-contained with data/domain/presentation
- **Dependency rule**: domain/ never imports from data/ or presentation/
```

### .context/conventions.md

Condensed version of the skill's naming and style conventions:

```markdown
# Conventions

## Naming
| Element | Convention | Example |
|---------|-----------|---------|
| Feature folder | snake_case | `user_profile/` |
| Dart file | snake_case | `user_model.dart` |
| Class | PascalCase | `UserModel` |
| Variable | camelCase | `userName` |
| Constant | camelCase or SCREAMING_SNAKE | `maxRetries` or `MAX_RETRIES` |
| Private | _prefixed | `_userName` |
| BLoC | {Entity}Bloc | `UserBloc` |
| Cubit | {Entity}Cubit | `UserCubit` |
| State | {Entity}State | `UserState` |
| Event | {Entity}Event | `UserEvent` |
| Repository | {Entity}Repository | `UserRepository` |
| Use case | {Action}{Entity} | `GetUser` |
| DTO | {Entity}DTO / {Entity}Model | `UserDTO` |
| Entity | {Entity} | `User` |
| Screen/Page | {Entity}{Action}Page | `UserDetailPage` |
| Widget | {Entity}Card | `UserCard` |

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

Condensed version of data-layer, forms, state, and routing patterns:

```markdown
# Code Patterns

## Data Layer
{brief description + repository/data source code template}

## Models
{brief description + Freezed/manual model code template}

## State Management
{brief description + BLoC/Cubit/Riverpod template}

## Navigation
{brief description + router setup}

## Forms
{brief description + form template}

## Error Handling
{Failure classes, Either pattern, error UI}

## Testing
{test runner, mocking approach, BLoC test template}
```

### .context/style.md

Condensed coding style profile -- how the team writes Dart code:

```markdown
# Coding Style

## Declaration & Types
- Variables: {final / var / explicit types}
- Parameters: {named + required / positional}
- Constructors: {const always / const when possible}

## Code Patterns
- Trailing commas: {enforced / optional}
- Cascade notation: {used for X / rare}
- Extension methods: {heavy use on X, Y / minimal}
- Null safety: {?. everywhere / ! in tests only / late for controllers}
- String interpolation: {$name / ${name} always}

## Organization
- Imports: {dart: -> package: -> relative}
- Comments: {/// for public API / // minimal / none}
- File length: {short <150 lines / medium}
- Guard clauses: {early returns / nested if-else}

## Modern Dart
- Sealed classes: {for states/events / not used}
- Pattern matching: {switch expressions / traditional switch}
- Records: {used / not used}
- Enhanced enums: {methods + properties / simple}
```

---

## Guidelines

1. **Keep .context/ files SHORT** -- aim for 50-100 lines each. These are reference cards, not documentation.
2. **Use the same `{placeholders}`** as the skill references for consistency.
3. **No workflow instructions** -- .context/ describes patterns, not how to generate a project. That's what the skill is for.
4. **Framework-specific** -- unlike skill references (which have two layers), .context/ files should be written for Flutter/Dart specifically. Other tools don't need the agnostic layer.
