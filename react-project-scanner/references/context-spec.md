# .context/ Specification

Generate a `.context/` directory alongside the skill output. This makes the extracted patterns usable by ANY AI coding tool, not just Claude skills.

---

## What is .context/?

The [Codebase Context Specification](https://github.com/Agentic-Coding/Codebase-Context-Spec) is an emerging standard for documenting project architecture and conventions in a format any AI tool can consume. Tools like Cursor (.cursorrules), Copilot, and Windsurf already look for context files.

By generating `.context/`, the extracted patterns work everywhere — not just as a Claude skill.

---

## Files to Generate

### .context/index.md

```markdown
---
module-name: {project-name}-patterns
description: Architecture and coding conventions extracted from {project-name}
related-modules: []
technologies:
  - {framework}
  - {build-tool}
  - {ui-library}
  - {state-management}
  - {form-library}
  - {http-client}
conventions:
  - {convention-1}
  - {convention-2}
  - {convention-3}
architecture-style: {e.g., "vertical feature slices with container/presentational split"}
---

# {ProjectName} Architecture

## Overview
{1-2 sentences describing the project architecture}

## Stack
{framework} + {build-tool} | {ui-lib} | {state-client} + {state-server} | {form-lib} + {validation-lib} | {http-client}

## Key Decisions
- **Directory structure**: {feature-sliced / flat / domain-driven}
- **Component pattern**: {container/presentational / smart-dumb / compound}
- **Data flow**: {DTO → mapper → domain model / direct API types}
- **State**: {client-lib} for UI state, {server-lib} for cached API data
- **Forms**: {form-lib} + {validation-lib}, schemas in separate files
- **Styling**: {css-approach} with {utility-lib}
```

### .context/architecture.md

Condensed version of the skill's `references/architecture.md`. Focus on:

```markdown
# Architecture

## Directory Structure
\```
src/
├── core/          # Core business features
│   └── {feature}/
│       ├── api/         # One folder per endpoint
│       ├── components/  # Presentational (pure)
│       ├── containers/  # Smart (hooks + state)
│       ├── helpers/     # Schemas, formatters
│       ├── hooks/       # Custom hooks
│       ├── models/      # Domain models
│       ├── stores/      # Client state
│       └── pages/       # Thin page wrappers
├── features/      # Secondary features (same structure)
├── shared/        # Business-agnostic reusables
│   ├── components/
│   ├── lib/
│   ├── routes/
│   ├── hooks/
│   ├── helpers/
│   └── types/
└── main.tsx
\```

## Feature Slice Anatomy
{describe what goes where}

## Core vs Features vs Shared
- **core/**: The primary business domain
- **features/**: Secondary/supporting functionality
- **shared/**: Reusable across any feature, no business logic
```

### .context/conventions.md

Condensed version of the skill's naming and style conventions:

```markdown
# Conventions

## Naming
| Element | Convention | Example |
|---------|-----------|---------|
| Component file | PascalCase.tsx | `UserCard.tsx` |
| Hook file | camelCase.ts | `useDebounce.ts` |
| ... | ... | ... |

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

## Data Fetching
{brief description + code template}

## Mutations
{brief description + code template}

## Forms
{brief description + code template}

## State Management
{brief description + code template}

## Routing
{brief description}

## Error Handling
{error boundaries, toast patterns, loading/empty states}

## Testing
{test runner, mocking approach, test structure}
```

### .context/style.md

Condensed coding style profile — how the team writes code:

```markdown
# Coding Style

## Declaration & Export
- Components: {arrow const / function declaration}
- Exports: {named / default / barrel re-exports}

## Code Patterns
- Props: {destructured inline / separate variable}
- Conditionals: {ternary / && / early returns}
- Async: {async/await / .then()}
- Callbacks: {named handlers / inline arrows}
- Null handling: {optional chaining / guards / non-null assertions}

## Type Definitions
- Preference: {interface / type}
- Location: {colocated / centralized in types/}

## Formatting
- Comments: {JSDoc / inline / minimal}
- Import order: {React → external → aliases → relative}
- File length: {short <150 lines / medium / large}
```

---

## Guidelines

1. **Keep .context/ files SHORT** — aim for 50-100 lines each. These are reference cards, not documentation.
2. **Use the same `{placeholders}`** as the skill references for consistency.
3. **No workflow instructions** — .context/ describes patterns, not how to generate a project. That's what the skill is for.
4. **Framework-specific** — unlike skill references (which have two layers), .context/ files should be written for the specific framework that was scanned. Other tools don't need the agnostic layer.
