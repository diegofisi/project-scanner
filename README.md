# Claude Code Project Scanners

A collection of **Claude Code custom skills** that scan existing codebases, extract architectural patterns, and generate reusable skills that can create new projects following those exact patterns.

Each scanner analyzes a real project and produces:
- A **SKILL.md** generator that creates new apps from a business idea
- **Reference files** with two-layer documentation (architecture + implementation)
- A **.context/** directory for tool-agnostic compatibility (Cursor, Copilot, Windsurf)

## Available Scanners

| Scanner | Target | Detects |
|---------|--------|---------|
| `react-project-scanner` | React, Vue, Angular, Svelte | Components, hooks, state (Zustand/Redux), forms (Zod/RHF), routing |
| `nextjs-project-scanner` | Next.js (App Router, Pages, hybrid) | Server/Client Components, Server Actions, ISR, streaming, API routes |
| `flutter-project-scanner` | Flutter / Dart | Clean Architecture, BLoC/Riverpod, Freezed models, GoRouter, DI |
| `python-fastapi-project-scanner` | Python FastAPI | Routers, Pydantic schemas, SQLAlchemy, repository pattern, JWT auth |

## Installation

### 1. Clone the repository

```bash
git clone <repo-url> ~/.claude/skills/project-scanners
```

### 2. Register the skills in Claude Code

Add the skill directories to your Claude Code settings. Each scanner is a self-contained skill with its own `SKILL.md`, `references/`, and `scripts/`.

You can register them globally or per-project:

**Global** (`~/.claude/settings.json`):
```json
{
  "skills": [
    "/path/to/react-project-scanner",
    "/path/to/nextjs-project-scanner",
    "/path/to/flutter-project-scanner",
    "/path/to/python-fastapi-project-scanner"
  ]
}
```

**Per-project** (`.claude/settings.local.json` in your project root):
```json
{
  "skills": [
    "/path/to/react-project-scanner"
  ]
}
```

### 3. Requirements

- **Claude Code** CLI installed
- **Bash** (Linux, macOS, Git Bash on Windows, or WSL)
- **Python 3** (optional, improves JSON/TOML parsing accuracy)
- **Repomix** (optional, `npm install -g repomix` for codebase packing)

## Usage

### Quick Start

Open Claude Code in any project and invoke the scanner:

```
You: scan my project at /path/to/my-react-app
```

Or use the skill trigger directly:

```
You: /react-project-scanner /path/to/my-react-app
```

### Trigger Phrases

The scanners respond to natural language:

- *"scan my project"*
- *"extract patterns from this codebase"*
- *"create a generator from this code"*
- *"turn this into a template"*
- *"make a skill from my app"*

### Workflow

Each scanner follows a 5-phase pipeline:

```
1. PACK (optional)  -->  2. SCAN  -->  3. EXTRACT  -->  4. GENERATE  -->  5. VERIFY
   Repomix                structure     two-layer        SKILL.md +       test with
   packed file             + deps        patterns         references/      sample idea
                                                          + .context/
```

#### Phase 0 - Pack (optional)
Consolidates the codebase into a single file using Repomix for faster analysis:
```
npx repomix /path/to/project --output /path/to/project/repomix-output.txt
```

#### Phase 1 - Scan
Runs the bash scanner script to detect framework, dependencies, architecture, and file structure:
```bash
bash scripts/scan-structure.sh /path/to/project
```

#### Phase 2 - Extract
Reads 2-3 representative files per category (most complex, most recent, standard) and extracts patterns in two layers:
- **Architecture layer**: Framework-agnostic principles (e.g., "repository pattern separates data access from business logic")
- **Implementation layer**: Framework-specific code templates with `{placeholders}` (e.g., actual Zustand store patterns)

#### Phase 3 - Generate
Produces the output skill with:
- `SKILL.md` - Main skill definition (<500 lines)
- `references/` - 12-20+ files, one concern per file (50-150 lines each)
- `.context/` - 5 files for tool-agnostic AI compatibility

#### Phase 4 - Verify
Validates against a comprehensive checklist (imports resolve, naming conventions match, patterns are consistent, etc.)

## Parallel Extraction Mode (large projects)

For projects with **2,000+ source files**, or when manually requested, the scanners automatically switch to **Parallel Extraction Mode** using subagents to avoid context window exhaustion.

### How it works

```
┌─────────────────────────────────────────────────────┐
│  COORDINATOR (main agent)                           │
│  1. Runs scan-structure.sh                          │
│  2. Detects LARGE_PROJECT: true (or user request)   │
│  3. Spawns 8 extraction subagents in parallel       │
│  4. Spawns validator agent after all complete        │
│  5. Assembles final SKILL.md + .context/            │
└──────────┬──────────────────────────────┬───────────┘
           │                              │
     ┌─────▼─────┐                  ┌─────▼─────┐
     │ 8 EXTRACT │  (parallel)      │ VALIDATOR  │  (sequential)
     │ SUBAGENTS │ ──────────────►  │   AGENT    │
     └───────────┘                  └───────────-┘
```

Each extraction subagent focuses on a single concern (architecture, components, data layer, state, forms, routing, testing, coding style) and reads only the files relevant to its category. This keeps each agent's context clean and focused.

The **validator agent** runs after all extractors finish and:
- Cross-checks consistency between all reference files
- Verifies naming conventions, import paths, and data flow patterns align
- Ensures every file has both architecture + implementation layers
- Applies fixes to any conflicts found

### Activation

| Trigger | How |
|---------|-----|
| **Automatic** | Scan output shows `LARGE_PROJECT: true` (>= 2000 files) |
| **Manual** | User says: "deep scan", "parallel scan", "scan with subagents", or adds `--parallel` |

Manual activation on smaller projects provides deeper coverage (more files read per category).

## Output Structure

After scanning a project called `my-app`, the generated skill looks like:

```
my-app-generator/
├── SKILL.md                    # Main generator skill
├── .context/                   # Tool-agnostic context
│   ├── index.md
│   ├── architecture.md
│   ├── conventions.md
│   ├── patterns.md
│   └── style.md
└── references/                 # Detailed pattern docs
    ├── architecture.md
    ├── components.md
    ├── data-layer.md
    ├── state-management.md
    ├── forms.md
    ├── routing.md
    ├── ui-styling.md
    ├── conventions.md
    ├── coding-style.md
    ├── testing.md
    ├── error-handling.md
    └── performance.md
```

## Using a Generated Skill

Once a skill is generated from scanning a project, you can use it to create new apps:

```
You: I want to build a task management app with projects, tasks, labels, and team collaboration

Claude: [Uses the generated skill to create the full project following the exact patterns extracted from the original codebase]
```

The generated skill will:
1. Refine the idea (clarify features, entities, roles)
2. Plan the architecture
3. Generate code in the correct order (config -> core -> models -> data -> state -> UI -> navigation -> entry point)
4. Validate against extracted conventions
5. Run a mandatory feedback loop

## Scanner File Structure

Each scanner has the same internal structure:

```
{framework}-project-scanner/
├── SKILL.md                        # Skill definition + workflow
├── scripts/
│   └── scan-structure.sh           # Bash codebase analyzer
└── references/
    ├── scan-checklist.md           # What to extract per category
    ├── output-structure.md         # Generated output format guide
    ├── skill-template.md           # Template for generated SKILL.md
    └── context-spec.md             # .context/ file specification
```

## Compatibility

- **OS**: Linux, macOS, Windows (Git Bash / WSL)
- **Claude Code**: Required for skill execution
- **.context/ output**: Compatible with Cursor, GitHub Copilot, Windsurf, and any AI tool that reads markdown context files

## License

MIT
