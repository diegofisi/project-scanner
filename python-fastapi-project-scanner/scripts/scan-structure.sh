#!/bin/bash
# FastAPI Codebase Structure Scanner
# Usage: bash scan-structure.sh <project-path>
# Outputs: directory tree, dependencies, configs, architecture pattern, and representative files per category.
# Works on: Linux, macOS, Windows (Git Bash / WSL)

PROJECT_PATH="${1:-.}"

if [ ! -d "$PROJECT_PATH" ]; then
  echo "ERROR: Directory '$PROJECT_PATH' does not exist."
  exit 1
fi

# ── Detect dependency file ─────────────────────────────────────────
PYPROJECT="$PROJECT_PATH/pyproject.toml"
REQUIREMENTS="$PROJECT_PATH/requirements.txt"
SETUP_PY="$PROJECT_PATH/setup.py"
SETUP_CFG="$PROJECT_PATH/setup.cfg"

HAS_PYPROJECT=false
HAS_REQUIREMENTS=false

if [ -f "$PYPROJECT" ]; then
  HAS_PYPROJECT=true
fi
if [ -f "$REQUIREMENTS" ]; then
  HAS_REQUIREMENTS=true
fi

if [ "$HAS_PYPROJECT" = false ] && [ "$HAS_REQUIREMENTS" = false ] && [ ! -f "$SETUP_PY" ]; then
  echo "ERROR: No pyproject.toml, requirements.txt, or setup.py found at '$PROJECT_PATH'."
  exit 1
fi

# ── Detect source directory ────────────────────────────────────────
SRC=""
if [ -d "$PROJECT_PATH/app" ]; then
  SRC="$PROJECT_PATH/app"
elif [ -d "$PROJECT_PATH/src" ]; then
  # Check for nested package inside src/
  NESTED=$(find "$PROJECT_PATH/src" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | head -1)
  if [ -n "$NESTED" ] && [ -f "$NESTED/__init__.py" ]; then
    SRC="$NESTED"
  else
    SRC="$PROJECT_PATH/src"
  fi
elif [ -d "$PROJECT_PATH/backend" ]; then
  SRC="$PROJECT_PATH/backend"
else
  # Fallback: look for a directory with __init__.py and main.py
  for dir in "$PROJECT_PATH"/*/; do
    if [ -f "${dir}__init__.py" ] && [ -f "${dir}main.py" ]; then
      SRC="${dir%/}"
      break
    fi
  done
  if [ -z "$SRC" ]; then
    SRC="$PROJECT_PATH"
  fi
fi

echo "========================================="
echo "  FASTAPI CODEBASE SCANNER"
echo "  Project: $PROJECT_PATH"
echo "  Source:  $SRC"
echo "========================================="

# ── 0. REPOMIX DETECTION ─────────────────────────────────────────
echo ""
echo "-- REPOMIX --"
if command -v repomix &>/dev/null || npx --no repomix --version &>/dev/null; then
  echo "  [AVAILABLE] repomix detected"
  echo "  Run: npx repomix $PROJECT_PATH --output $PROJECT_PATH/repomix-output.txt"
else
  echo "  [NOT FOUND] repomix not available -- skipping (install: npm i -g repomix)"
fi

# ── 1. FRAMEWORK DETECTION ────────────────────────────────────────
echo ""
echo "-- FRAMEWORK --"

check_dep() {
  local dep_name="$1"
  if [ "$HAS_PYPROJECT" = true ]; then
    grep -qi "$dep_name" "$PYPROJECT" 2>/dev/null && return 0
  fi
  if [ "$HAS_REQUIREMENTS" = true ]; then
    grep -qi "$dep_name" "$REQUIREMENTS" 2>/dev/null && return 0
  fi
  if [ -f "$SETUP_PY" ]; then
    grep -qi "$dep_name" "$SETUP_PY" 2>/dev/null && return 0
  fi
  if [ -f "$SETUP_CFG" ]; then
    grep -qi "$dep_name" "$SETUP_CFG" 2>/dev/null && return 0
  fi
  # Also check requirements/ directory for split requirements files
  if [ -d "$PROJECT_PATH/requirements" ]; then
    grep -rqi "$dep_name" "$PROJECT_PATH/requirements/" 2>/dev/null && return 0
  fi
  return 1
}

FRAMEWORK="unknown"
if check_dep "fastapi"; then
  FRAMEWORK="fastapi"
elif check_dep "litestar"; then
  FRAMEWORK="litestar"
elif check_dep "django"; then
  FRAMEWORK="django"
elif check_dep "flask"; then
  FRAMEWORK="flask"
elif check_dep "starlette"; then
  FRAMEWORK="starlette"
fi
echo "  Detected: $FRAMEWORK"

# ── 1b. PYTHON VERSION ───────────────────────────────────────────
echo ""
echo "-- PYTHON VERSION --"
PY_VERSION="unknown"
if [ "$HAS_PYPROJECT" = true ]; then
  PY_VERSION=$(sed -n 's/.*python_requires\s*=\s*"\([^"]*\)".*/\1/p' "$PYPROJECT" 2>/dev/null | head -1)
  [ -z "$PY_VERSION" ] && PY_VERSION=$(sed -n 's/.*requires-python\s*=\s*"\([^"]*\)".*/\1/p' "$PYPROJECT" 2>/dev/null | head -1)
  [ -z "$PY_VERSION" ] && PY_VERSION=$(sed -n 's/.*python\s*=\s*"\([^"]*\)".*/\1/p' "$PYPROJECT" 2>/dev/null | head -1)
fi
if [ -z "$PY_VERSION" ] || [ "$PY_VERSION" = "unknown" ]; then
  if [ -f "$PROJECT_PATH/runtime.txt" ]; then
    PY_VERSION=$(cat "$PROJECT_PATH/runtime.txt" 2>/dev/null)
  elif [ -f "$PROJECT_PATH/.python-version" ]; then
    PY_VERSION=$(cat "$PROJECT_PATH/.python-version" 2>/dev/null)
  fi
fi
echo "  ${PY_VERSION:-unknown}"

# ── 1c. PACKAGE MANAGER DETECTION ────────────────────────────────
echo ""
echo "-- PACKAGE MANAGER --"
if [ -f "$PROJECT_PATH/poetry.lock" ]; then
  echo "  Poetry"
elif [ -f "$PROJECT_PATH/uv.lock" ]; then
  echo "  uv"
elif [ -f "$PROJECT_PATH/pdm.lock" ]; then
  echo "  PDM"
elif [ -f "$PROJECT_PATH/Pipfile.lock" ] || [ -f "$PROJECT_PATH/Pipfile" ]; then
  echo "  Pipenv"
elif [ -f "$PROJECT_PATH/conda-lock.yml" ] || [ -f "$PROJECT_PATH/environment.yml" ]; then
  echo "  Conda"
elif [ -f "$REQUIREMENTS" ]; then
  echo "  pip (requirements.txt)"
elif [ "$HAS_PYPROJECT" = true ]; then
  # Check if pyproject.toml has build-system hints
  if grep -q "poetry" "$PYPROJECT" 2>/dev/null; then
    echo "  Poetry (from pyproject.toml)"
  elif grep -q "pdm" "$PYPROJECT" 2>/dev/null; then
    echo "  PDM (from pyproject.toml)"
  elif grep -qE "hatchling|hatch" "$PYPROJECT" 2>/dev/null; then
    echo "  Hatch"
  elif grep -q "flit" "$PYPROJECT" 2>/dev/null; then
    echo "  Flit"
  elif grep -q "setuptools" "$PYPROJECT" 2>/dev/null; then
    echo "  setuptools"
  else
    echo "  unknown (pyproject.toml present)"
  fi
else
  echo "  unknown"
fi

# ── 2. DEPENDENCIES ──────────────────────────────────────────────
echo ""
echo "-- DEPENDENCIES --"

if [ "$HAS_PYPROJECT" = true ]; then
  echo "  Source: pyproject.toml"
  echo ""
  # Show project name/version
  PROJ_NAME=$(sed -n 's/^name\s*=\s*"\([^"]*\)".*/\1/p' "$PYPROJECT" 2>/dev/null | head -1)
  PROJ_VER=$(sed -n 's/^version\s*=\s*"\([^"]*\)".*/\1/p' "$PYPROJECT" 2>/dev/null | head -1)
  echo "  Name: ${PROJ_NAME:-N/A} v${PROJ_VER:-N/A}"
  echo ""

  echo "  Production dependencies:"
  # Try to extract from [tool.poetry.dependencies] or [project.dependencies]
  if command -v python3 &>/dev/null; then
    PYTHON_CMD="python3"
  elif command -v python &>/dev/null; then
    PYTHON_CMD="python"
  else
    PYTHON_CMD=""
  fi

  if [ -n "$PYTHON_CMD" ]; then
    PYPROJECT="$PYPROJECT" $PYTHON_CMD -c "
import sys, os
try:
    import tomllib
except ImportError:
    try:
        import tomli as tomllib
    except ImportError:
        # Manual parsing fallback
        print('    (install tomli for better parsing: pip install tomli)')
        sys.exit(0)

with open(os.environ['PYPROJECT'], 'rb') as f:
    data = tomllib.load(f)

# Poetry style
poetry_deps = data.get('tool', {}).get('poetry', {}).get('dependencies', {})
if poetry_deps:
    for k, v in sorted(poetry_deps.items()):
        if k == 'python':
            continue
        print(f'    {k}: {v}')

# PEP 621 style
pep_deps = data.get('project', {}).get('dependencies', [])
if pep_deps:
    for d in sorted(pep_deps):
        print(f'    {d}')

# Dev dependencies
poetry_dev = data.get('tool', {}).get('poetry', {}).get('group', {}).get('dev', {}).get('dependencies', {})
if poetry_dev:
    print()
    print('  Dev dependencies:')
    for k, v in sorted(poetry_dev.items()):
        print(f'    {k}: {v}')

pep_optional = data.get('project', {}).get('optional-dependencies', {})
dev_keys = [k for k in pep_optional if k in ('dev', 'test', 'testing', 'lint', 'development')]
if dev_keys:
    print()
    print('  Dev/Test dependencies:')
    for key in dev_keys:
        for d in sorted(pep_optional[key]):
            print(f'    [{key}] {d}')

# Scripts
scripts = data.get('project', {}).get('scripts', {})
poetry_scripts = data.get('tool', {}).get('poetry', {}).get('scripts', {})
all_scripts = {**scripts, **poetry_scripts}
if all_scripts:
    print()
    print('  Scripts:')
    for k, v in all_scripts.items():
        print(f'    {k}: {v}')
" 2>/dev/null
  else
    echo "    (python not found -- showing raw pyproject.toml)"
    cat "$PYPROJECT"
  fi
elif [ "$HAS_REQUIREMENTS" = true ]; then
  echo "  Source: requirements.txt"
  echo ""
  # Filter out comments and blank lines
  grep -v '^\s*#' "$REQUIREMENTS" | grep -v '^\s*$' | sed 's/^/    /'
fi

# ── 2b. STACK CLASSIFICATION ────────────────────────────────────
echo ""
echo "-- STACK SUMMARY --"

# FastAPI version
echo -n "  FastAPI:          "
FA_VER=""
if [ "$HAS_PYPROJECT" = true ]; then
  FA_VER=$(grep -i 'fastapi' "$PYPROJECT" 2>/dev/null | sed -n 's/.*fastapi[>=<~!]*\([0-9][0-9.]*\).*/\1/p' | head -1)
fi
if [ -z "$FA_VER" ] && [ "$HAS_REQUIREMENTS" = true ]; then
  FA_VER=$(grep -i 'fastapi' "$REQUIREMENTS" 2>/dev/null | sed -n 's/.*fastapi[>=<~!]*\([0-9][0-9.]*\).*/\1/p' | head -1)
fi
echo "${FA_VER:-detected (version unknown)}"

# ORM
echo -n "  ORM:              "
if check_dep "sqlmodel"; then echo "SQLModel (Pydantic + SQLAlchemy hybrid)"
elif check_dep "sqlalchemy"; then echo "SQLAlchemy"
elif check_dep "tortoise-orm"; then echo "Tortoise ORM"
elif check_dep "peewee"; then echo "Peewee"
elif check_dep "beanie"; then echo "Beanie (MongoDB ODM)"
elif check_dep "mongoengine"; then echo "MongoEngine"
elif check_dep "odmantic"; then echo "ODMantic"
else echo "none"; fi

# Migrations
echo -n "  Migrations:       "
if check_dep "alembic"; then echo "Alembic"
elif check_dep "aerich"; then echo "Aerich (Tortoise)"
else echo "none"; fi

# Pydantic version
echo -n "  Validation:       "
if check_dep "pydantic"; then
  PYDANTIC_VER=$(grep -i 'pydantic' "$PYPROJECT" 2>/dev/null | sed -n 's/.*pydantic[>=<~!]*\([0-9]\).*/\1/p' | head -1)
  if [ -z "$PYDANTIC_VER" ] && [ "$HAS_REQUIREMENTS" = true ]; then
    PYDANTIC_VER=$(grep -i 'pydantic' "$REQUIREMENTS" 2>/dev/null | sed -n 's/.*pydantic[>=<~!]*\([0-9]\).*/\1/p' | head -1)
  fi
  if [ "$PYDANTIC_VER" = "2" ] || [ -z "$PYDANTIC_VER" ]; then
    echo "Pydantic v2"
  else
    echo "Pydantic v1"
  fi
elif check_dep "marshmallow"; then echo "Marshmallow"
elif check_dep "attrs"; then echo "attrs"
else echo "Pydantic (built-in with FastAPI)"; fi

# Auth
echo -n "  Auth:             "
AUTH=""
check_dep "python-jose" && AUTH="python-jose"
check_dep "pyjwt" && AUTH="${AUTH:+$AUTH + }PyJWT"
check_dep "passlib" && AUTH="${AUTH:+$AUTH + }passlib"
check_dep "bcrypt" && AUTH="${AUTH:+$AUTH + }bcrypt"
check_dep "authlib" && AUTH="${AUTH:+$AUTH + }authlib"
check_dep "fastapi-users" && AUTH="${AUTH:+$AUTH + }fastapi-users"
check_dep "fastapi-jwt-auth" && AUTH="${AUTH:+$AUTH + }fastapi-jwt-auth"
echo "${AUTH:-none}"

# HTTP Client
echo -n "  HTTP Client:      "
if check_dep "httpx"; then echo "httpx"
elif check_dep "aiohttp"; then echo "aiohttp"
elif check_dep "requests"; then echo "requests"
else echo "none"; fi

# Task Queue
echo -n "  Task Queue:       "
if check_dep "celery"; then echo "Celery"
elif check_dep "arq"; then echo "ARQ"
elif check_dep "saq"; then echo "SAQ"
elif check_dep "dramatiq"; then echo "Dramatiq"
elif check_dep "huey"; then echo "Huey"
elif check_dep "rq"; then echo "RQ (Redis Queue)"
else echo "none"; fi

# Cache
echo -n "  Cache:            "
if check_dep "fastapi-cache2"; then echo "fastapi-cache2"
elif check_dep "fastapi-cache"; then echo "fastapi-cache"
elif check_dep "aioredis"; then echo "aioredis"
elif check_dep "redis"; then echo "redis-py"
else echo "none"; fi

# Testing
echo -n "  Testing:          "
TESTING=""
check_dep "pytest" && TESTING="pytest"
check_dep "pytest-asyncio" && TESTING="${TESTING:+$TESTING + }pytest-asyncio"
check_dep "httpx" && TESTING="${TESTING:+$TESTING + }httpx (AsyncClient)"
{ check_dep "factory.boy" || check_dep "factory-boy"; } && TESTING="${TESTING:+$TESTING + }factory-boy"
check_dep "faker" && TESTING="${TESTING:+$TESTING + }faker"
check_dep "pytest-mock" && TESTING="${TESTING:+$TESTING + }pytest-mock"
check_dep "pytest-cov" && TESTING="${TESTING:+$TESTING + }pytest-cov"
check_dep "coverage" && TESTING="${TESTING:+$TESTING + }coverage"
echo "${TESTING:-none}"

# Logging
echo -n "  Logging:          "
if check_dep "loguru"; then echo "loguru"
elif check_dep "structlog"; then echo "structlog"
elif check_dep "python-json-logger"; then echo "python-json-logger"
else echo "stdlib logging"; fi

# Linting / Formatting
echo -n "  Linting:          "
LINTING=""
check_dep "ruff" && LINTING="ruff"
check_dep "black" && LINTING="${LINTING:+$LINTING + }black"
check_dep "isort" && LINTING="${LINTING:+$LINTING + }isort"
check_dep "mypy" && LINTING="${LINTING:+$LINTING + }mypy"
check_dep "pylint" && LINTING="${LINTING:+$LINTING + }pylint"
check_dep "flake8" && LINTING="${LINTING:+$LINTING + }flake8"
check_dep "pyright" && LINTING="${LINTING:+$LINTING + }pyright"
echo "${LINTING:-none}"

# Email
echo -n "  Email:            "
if check_dep "fastapi-mail"; then echo "fastapi-mail"
elif check_dep "sendgrid"; then echo "SendGrid"
elif check_dep "aiosmtplib"; then echo "aiosmtplib"
else echo "none"; fi

# File Storage
echo -n "  File Storage:     "
if check_dep "boto3"; then echo "boto3 (AWS S3)"
elif check_dep "google-cloud-storage"; then echo "Google Cloud Storage"
elif check_dep "azure-storage-blob"; then echo "Azure Blob Storage"
elif check_dep "minio"; then echo "MinIO"
else echo "none"; fi

# Monitoring
echo -n "  Monitoring:       "
MONITORING=""
check_dep "sentry-sdk" && MONITORING="Sentry"
check_dep "prometheus-client" && MONITORING="${MONITORING:+$MONITORING + }Prometheus"
check_dep "opentelemetry" && MONITORING="${MONITORING:+$MONITORING + }OpenTelemetry"
check_dep "prometheus-fastapi-instrumentator" && MONITORING="${MONITORING:+$MONITORING + }FastAPI Instrumentator"
echo "${MONITORING:-none}"

# WebSocket
echo -n "  WebSocket:        "
WS_FILES=$(grep -rlE "WebSocket|websocket_route|@.*websocket" "$SRC" --include="*.py" 2>/dev/null | wc -l)
if [ "$WS_FILES" -gt 0 ]; then echo "yes ($WS_FILES files)"
else echo "no"; fi

# CORS
echo -n "  CORS:             "
CORS_FILES=$(grep -rl "CORSMiddleware" "$SRC" --include="*.py" 2>/dev/null | wc -l)
if [ "$CORS_FILES" -gt 0 ]; then echo "yes (CORSMiddleware)"
else echo "no"; fi

# OpenAPI customization
echo -n "  OpenAPI custom:   "
OPENAPI_FILES=$(grep -rlE "openapi_url|docs_url|redoc_url|swagger_ui|openapi_schema" "$SRC" --include="*.py" 2>/dev/null | wc -l)
if [ "$OPENAPI_FILES" -gt 0 ]; then echo "yes ($OPENAPI_FILES files)"
else echo "default"; fi

# ── 2c. ARCHITECTURE PATTERN ────────────────────────────────────
echo ""
echo "-- ARCHITECTURE PATTERN --"

# Detect architecture style
ARCH_STYLE="flat"

# Check for layered architecture (routers/ services/ repositories/ models/)
HAS_ROUTERS=$(find "$SRC" -type d \( -name "routers" -o -name "routes" -o -name "endpoints" -o -name "api" \) 2>/dev/null | head -1)
HAS_SERVICES=$(find "$SRC" -type d \( -name "services" -o -name "service" \) 2>/dev/null | head -1)
HAS_REPOS=$(find "$SRC" -type d \( -name "repositories" -o -name "repos" -o -name "repository" \) 2>/dev/null | head -1)
HAS_MODELS=$(find "$SRC" -type d \( -name "models" -o -name "model" \) 2>/dev/null | head -1)
HAS_SCHEMAS=$(find "$SRC" -type d \( -name "schemas" -o -name "schema" \) 2>/dev/null | head -1)

# Check for feature/module-based organization
HAS_MODULES=$(find "$SRC" -type d -name "modules" 2>/dev/null | head -1)
HAS_DOMAINS=$(find "$SRC" -type d \( -name "domains" -o -name "domain" \) 2>/dev/null | head -1)
HAS_FEATURES=$(find "$SRC" -type d -name "features" 2>/dev/null | head -1)

if [ -n "$HAS_DOMAINS" ]; then
  ARCH_STYLE="ddd"
  echo "  [DDD] Domain-Driven Design"
  echo "    Detected: domains/ directory with bounded contexts"
elif [ -n "$HAS_MODULES" ] || [ -n "$HAS_FEATURES" ]; then
  # Check if modules have self-contained routers/services/models
  MODULE_DIR="${HAS_MODULES:-$HAS_FEATURES}"
  SELF_CONTAINED=$(find "$MODULE_DIR" -mindepth 2 -maxdepth 2 -type d \( -name "routers" -o -name "services" -o -name "models" -o -name "schemas" \) 2>/dev/null | wc -l)
  if [ "$SELF_CONTAINED" -gt 2 ]; then
    ARCH_STYLE="modular"
    echo "  [MODULAR] Feature/Module-based with self-contained modules"
    echo "    Each module has its own routers, services, models"
  else
    ARCH_STYLE="modular-flat"
    echo "  [MODULAR-FLAT] Module-based with shared layers"
  fi
elif [ -n "$HAS_ROUTERS" ] && [ -n "$HAS_SERVICES" ] && [ -n "$HAS_REPOS" ]; then
  ARCH_STYLE="layered-full"
  echo "  [LAYERED] Full layered architecture"
  echo "    Router -> Service -> Repository -> Model"
elif [ -n "$HAS_ROUTERS" ] && [ -n "$HAS_SERVICES" ]; then
  ARCH_STYLE="layered"
  echo "  [LAYERED] Service-based layered architecture"
  echo "    Router -> Service -> Model (no repository layer)"
elif [ -n "$HAS_ROUTERS" ]; then
  ARCH_STYLE="router-based"
  echo "  [ROUTER-BASED] Router-centric"
  echo "    Routers with inline logic, models separate"
else
  echo "  [FLAT] Flat structure or single-file"
fi

# ── 2d. ASYNC PATTERN ──────────────────────────────────────────
echo ""
echo "-- ASYNC PATTERN --"
ASYNC_ENDPOINTS=$(grep -rl "async def " "$SRC" --include="*.py" 2>/dev/null | wc -l)
SYNC_ENDPOINTS=$(grep -rl "^def " "$SRC" --include="*.py" 2>/dev/null | wc -l)
echo "  Files with async def: $ASYNC_ENDPOINTS"
echo "  Files with sync def:  $SYNC_ENDPOINTS"
if [ "$ASYNC_ENDPOINTS" -gt "$SYNC_ENDPOINTS" ]; then
  echo "  [ASYNC-FIRST] Primarily async codebase"
else
  echo "  [MIXED] Mix of async and sync"
fi

# ── 3. DIRECTORY STRUCTURE ────────────────────────────────────────
echo ""
echo "-- DIRECTORY STRUCTURE --"
find "$SRC" -maxdepth 5 -type d 2>/dev/null | sed "s|$PROJECT_PATH/||" | sort

# ── 4. FILE COUNTS ───────────────────────────────────────────────
echo ""
echo "-- FILE COUNTS --"
find "$SRC" -type f -name "*.py" 2>/dev/null | wc -l | xargs -I{} echo "  Python files: {}"
find "$SRC" -type f 2>/dev/null | awk -F/ '{print $NF}' | grep '\.' | sed 's/.*\.//' | sort | uniq -c | sort -rn

# ── 5. CONFIG FILES ──────────────────────────────────────────────
echo ""
echo "-- CONFIG FILES --"
for config in pyproject.toml setup.py setup.cfg requirements.txt requirements-dev.txt \
              Pipfile Pipfile.lock poetry.lock uv.lock pdm.lock \
              .env .env.example .env.local .env.development .env.production .env.test \
              alembic.ini \
              Dockerfile docker-compose.yml docker-compose.yaml \
              Makefile \
              .pre-commit-config.yaml \
              mypy.ini .mypy.ini \
              .flake8 .pylintrc \
              ruff.toml .ruff.toml \
              pytest.ini conftest.py \
              tox.ini noxfile.py \
              .github/workflows \
              .gitlab-ci.yml \
              .dockerignore .gitignore \
              runtime.txt .python-version \
              Procfile; do
  if [ -f "$PROJECT_PATH/$config" ] || [ -d "$PROJECT_PATH/$config" ]; then
    echo "  [FOUND] $config"
  fi
done

# Check for alembic directory
if [ -d "$PROJECT_PATH/alembic" ] || [ -d "$SRC/alembic" ] || [ -d "$PROJECT_PATH/migrations" ]; then
  echo "  [FOUND] alembic/migrations directory"
fi

# ── 5b. SETTINGS PATTERN ────────────────────────────────────────
echo ""
echo "-- SETTINGS PATTERN --"
SETTINGS_FILES=$(find "$SRC" \( -name "settings.py" -o -name "config.py" -o -name "conf.py" -o -name "configuration.py" \) 2>/dev/null)
if [ -n "$SETTINGS_FILES" ]; then
  echo "$SETTINGS_FILES" | sed "s|$PROJECT_PATH/||" | sed 's/^/  /'
  # Check for BaseSettings usage
  if echo "$SETTINGS_FILES" | xargs grep -ql "BaseSettings" 2>/dev/null; then
    echo "  [PATTERN] pydantic-settings (BaseSettings)"
  elif echo "$SETTINGS_FILES" | xargs grep -qlE "environ|os.getenv|os.environ" 2>/dev/null; then
    echo "  [PATTERN] os.environ / os.getenv"
  fi
else
  echo "  No settings.py or config.py found"
fi

# ── 6. REPRESENTATIVE FILES ──────────────────────────────────────
echo ""
echo "=========================================="
echo "  REPRESENTATIVE FILES (1 per category)"
echo "=========================================="

# Entry point
echo ""
echo "-- ENTRY POINT --"
for f in main.py app.py server.py asgi.py; do
  found=$(find "$SRC" -maxdepth 2 -name "$f" 2>/dev/null | head -1)
  if [ -n "$found" ]; then
    echo "  $found" | sed "s|$PROJECT_PATH/||"
  fi
done

# Router files
echo ""
echo "-- ROUTERS (pick 1 to read) --"
find "$SRC" \( -name "*router*" -o -name "*route*" -o -name "*endpoint*" -o -name "*api*.py" \) \
  -not -name "__init__.py" -not -name "*.pyc" -not -path "*__pycache__*" \
  -not -path "*/alembic/*" -not -path "*/migrations/*" 2>/dev/null | head -10 | sed "s|$PROJECT_PATH/||"

# Service files
echo ""
echo "-- SERVICES (pick 1 to read) --"
find "$SRC" \( -name "*service*" -o -name "*use_case*" -o -name "*usecase*" \) \
  -not -name "__init__.py" -not -name "*.pyc" -not -path "*__pycache__*" \
  -not -path "*/test*" 2>/dev/null | head -10 | sed "s|$PROJECT_PATH/||"

# Repository files
echo ""
echo "-- REPOSITORIES (pick 1 to read) --"
find "$SRC" \( -name "*repository*" -o -name "*repo*" -o -name "*dal*" -o -name "*crud*" \) \
  -not -name "__init__.py" -not -name "*.pyc" -not -path "*__pycache__*" \
  -not -path "*/test*" 2>/dev/null | head -10 | sed "s|$PROJECT_PATH/||"

# Model files (SQLAlchemy / ORM)
echo ""
echo "-- ORM MODELS (pick 1 to read) --"
find "$SRC" \( -name "*model*" -o -name "*entity*" -o -name "*table*" \) -name "*.py" \
  -not -name "__init__.py" -not -name "*.pyc" -not -path "*__pycache__*" \
  -not -path "*/test*" -not -path "*/schema*" -not -path "*/alembic/*" 2>/dev/null | head -10 | sed "s|$PROJECT_PATH/||"

# Schema files (Pydantic)
echo ""
echo "-- PYDANTIC SCHEMAS (pick 1 to read) --"
find "$SRC" \( -name "*schema*" -o -name "*dto*" -o -name "*serializer*" \) -name "*.py" \
  -not -name "__init__.py" -not -name "*.pyc" -not -path "*__pycache__*" \
  -not -path "*/test*" -not -path "*/alembic/*" 2>/dev/null | head -10 | sed "s|$PROJECT_PATH/||"

# Database / session files
echo ""
echo "-- DATABASE FILES --"
find "$SRC" \( -name "*database*" -o -name "*db*" -o -name "*session*" -o -name "*connection*" \) -name "*.py" \
  -not -name "__init__.py" -not -name "*.pyc" -not -path "*__pycache__*" \
  -not -path "*/alembic/*" -not -path "*/migrations/*" 2>/dev/null | head -10 | sed "s|$PROJECT_PATH/||"

# Dependencies files (FastAPI Depends)
echo ""
echo "-- DEPENDENCY FILES --"
find "$SRC" \( -name "*depend*" -o -name "*deps*" \) -name "*.py" \
  -not -name "__init__.py" -not -name "*.pyc" -not -path "*__pycache__*" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Auth files
echo ""
echo "-- AUTH FILES --"
find "$SRC" -path "*auth*" -name "*.py" -not -name "*.pyc" -not -path "*__pycache__*" \
  -not -path "*/test*" 2>/dev/null | head -10 | sed "s|$PROJECT_PATH/||"

# Middleware files
echo ""
echo "-- MIDDLEWARE --"
find "$SRC" \( -name "*middleware*" -o -path "*/middleware/*" \) -name "*.py" \
  -not -name "__init__.py" -not -name "*.pyc" -not -path "*__pycache__*" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Exception / error handling files
echo ""
echo "-- EXCEPTION / ERROR HANDLING --"
find "$SRC" \( -name "*exception*" -o -name "*error*" -o -name "*exc*" \) -name "*.py" \
  -not -name "__init__.py" -not -name "*.pyc" -not -path "*__pycache__*" \
  -not -path "*/test*" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Config / settings
echo ""
echo "-- CONFIG / SETTINGS --"
find "$SRC" \( -name "*config*" -o -name "*settings*" -o -name "*conf*" \) -name "*.py" \
  -not -name "__init__.py" -not -name "*.pyc" -not -path "*__pycache__*" \
  -not -path "*/alembic/*" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Alembic
echo ""
echo "-- ALEMBIC --"
for d in "$PROJECT_PATH/alembic" "$SRC/alembic" "$PROJECT_PATH/migrations" "$SRC/migrations"; do
  if [ -d "$d" ]; then
    echo "  Directory: $d" | sed "s|$PROJECT_PATH/||"
    # Show env.py
    if [ -f "$d/env.py" ]; then
      echo "    env.py found"
    fi
    # Count migration files
    MIGRATION_COUNT=$(find "$d" -name "*.py" -path "*/versions/*" 2>/dev/null | wc -l)
    echo "    Migrations: $MIGRATION_COUNT"
  fi
done

# Background task / worker files
echo ""
echo "-- BACKGROUND TASKS / WORKERS --"
find "$SRC" \( -name "*task*" -o -name "*worker*" -o -name "*celery*" -o -name "*job*" -o -name "*queue*" \) -name "*.py" \
  -not -name "__init__.py" -not -name "*.pyc" -not -path "*__pycache__*" \
  -not -path "*/test*" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Utils / helpers
echo ""
echo "-- UTILS / HELPERS --"
find "$SRC" \( -name "*util*" -o -name "*helper*" -o -name "*common*" -o -path "*/utils/*" -o -path "*/helpers/*" \) -name "*.py" \
  -not -name "__init__.py" -not -name "*.pyc" -not -path "*__pycache__*" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Constants / enums
echo ""
echo "-- CONSTANTS / ENUMS --"
find "$SRC" \( -name "*constant*" -o -name "*enum*" -o -name "*enums*" \) -name "*.py" \
  -not -name "__init__.py" -not -name "*.pyc" -not -path "*__pycache__*" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Test files
echo ""
echo "-- TEST FILES --"
find "$PROJECT_PATH" \( -name "test_*" -o -name "*_test.py" -o -name "conftest.py" \) \
  -not -path "*__pycache__*" -not -name "*.pyc" 2>/dev/null | head -10 | sed "s|$PROJECT_PATH/||"
if [ -d "$PROJECT_PATH/tests" ]; then
  echo "  [DIR] tests/"
  find "$PROJECT_PATH/tests" -maxdepth 3 -type d 2>/dev/null | sed "s|$PROJECT_PATH/||" | sed 's/^/    /'
fi

# ── 7. MODULE SLICE EXAMPLE ─────────────────────────────────────
echo ""
echo "=========================================="
echo "  MODULE SLICE EXAMPLE"
echo "=========================================="
echo ""
echo "  Shows one complete module/feature with all its files."
echo "  Pick the first feature directory that has 3+ Python files."
echo ""

SLICE_DIR=""
for base_dir in "$SRC/modules" "$SRC/domains" "$SRC/features" "$SRC/routers" "$SRC/api" \
                "$SRC/api/v1" "$SRC/api/v1/endpoints"; do
  if [ -d "$base_dir" ]; then
    SLICE_DIR=$(find "$base_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | while read -r dir; do
      count=$(find "$dir" -type f -name "*.py" 2>/dev/null | wc -l)
      echo "$count $dir"
    done | sort -rn | head -1 | sed 's/^[[:space:]]*[0-9]*[[:space:]]*//')
    [ -n "$SLICE_DIR" ] && break
  fi
done

# If no module dir found, try finding a directory with router + service + model
if [ -z "$SLICE_DIR" ]; then
  for dir in "$SRC"/*/; do
    if [ -d "$dir" ] && [ "$(basename "$dir")" != "__pycache__" ]; then
      PY_COUNT=$(find "$dir" -type f -name "*.py" -not -path "*__pycache__*" 2>/dev/null | wc -l)
      if [ "$PY_COUNT" -ge 3 ]; then
        SLICE_DIR="${dir%/}"
        break
      fi
    fi
  done
fi

if [ -n "$SLICE_DIR" ]; then
  PY_COUNT=$(find "$SLICE_DIR" -type f -name "*.py" -not -path "*__pycache__*" 2>/dev/null | wc -l)
  echo "-- $(basename "$SLICE_DIR") ($PY_COUNT Python files) --"
  find "$SLICE_DIR" -type f -name "*.py" -not -path "*__pycache__*" 2>/dev/null | sed "s|$PROJECT_PATH/||" | sort
else
  echo "  No module directory found with nested structure."
fi

# ── 8. LARGEST FILES PER CATEGORY ───────────────────────────────
echo ""
echo "=========================================="
echo "  LARGEST FILES (for smart sampling)"
echo "=========================================="
echo ""
echo "  Read the longest file per category to see the most complete patterns."
echo ""

show_largest() {
  local label="$1"
  local search_path="$2"
  shift 2
  local result
  result=$(find "$search_path" \( "$@" \) -name "*.py" -not -path "*__pycache__*" -not -name "*.pyc" -type f -print0 2>/dev/null | xargs -0 wc -l 2>/dev/null | grep -v " total$" | sort -rn | head -1)
  if [ -n "$result" ]; then
    local lines file
    lines=$(echo "$result" | awk '{print $1}')
    file=$(echo "$result" | sed 's/^[[:space:]]*[0-9]*//' | sed 's/^[[:space:]]*//' | sed "s|$PROJECT_PATH/||")
    echo "  $label: $file ($lines lines)"
  fi
}

show_largest "Router" "$SRC" -name "*router*" -o -name "*route*" -o -name "*endpoint*"
show_largest "Service" "$SRC" -name "*service*" -o -name "*use_case*"
show_largest "Repository" "$SRC" -name "*repository*" -o -name "*repo*" -o -name "*crud*"
show_largest "Model (ORM)" "$SRC" -name "*model*" -not -path "*/schema*"
show_largest "Schema" "$SRC" -name "*schema*" -o -name "*dto*"
show_largest "Auth" "$SRC" -path "*auth*"
show_largest "Middleware" "$SRC" -name "*middleware*"
show_largest "Test" "$PROJECT_PATH" -name "test_*" -o -name "*_test.py"
show_largest "Config" "$SRC" -name "*config*" -o -name "*settings*"
show_largest "Utils" "$SRC" -name "*util*" -o -name "*helper*"

# ── 9. CODING STYLE SIGNALS ────────────────────────────────────
echo ""
echo "=========================================="
echo "  CODING STYLE SIGNALS"
echo "=========================================="

# Type hints usage
echo ""
echo "-- TYPE HINTS --"
TYPE_HINTS=$(grep -rlE ": str|: int|: float|: bool|: list|: dict|: Optional|: Union|-> " "$SRC" --include="*.py" 2>/dev/null | wc -l)
TOTAL_PY=$(find "$SRC" -name "*.py" -not -path "*__pycache__*" 2>/dev/null | wc -l)
echo "  Files with type hints: $TYPE_HINTS / $TOTAL_PY"
if [ "$TOTAL_PY" -gt 0 ]; then
  PCT=$((TYPE_HINTS * 100 / TOTAL_PY))
  if [ "$PCT" -gt 80 ]; then
    echo "  [HEAVY] Type hints used extensively"
  elif [ "$PCT" -gt 40 ]; then
    echo "  [MODERATE] Type hints used in most files"
  else
    echo "  [LIGHT] Minimal type hint usage"
  fi
fi

# Docstring style
echo ""
echo "-- DOCSTRING STYLE --"
GOOGLE_DOCS=$(grep -rlE "Args:|Returns:|Raises:" "$SRC" --include="*.py" 2>/dev/null | wc -l)
NUMPY_DOCS=$(grep -rl "----------" "$SRC" --include="*.py" 2>/dev/null | wc -l)
REST_DOCS=$(grep -rlE ":param |:type |:returns:" "$SRC" --include="*.py" 2>/dev/null | wc -l)
TRIPLE_QUOTES=$(grep -rl '"""' "$SRC" --include="*.py" 2>/dev/null | wc -l)
echo "  Google style (Args/Returns): $GOOGLE_DOCS"
echo "  NumPy style (----------):    $NUMPY_DOCS"
echo "  reST style (:param):         $REST_DOCS"
echo "  Files with docstrings:       $TRIPLE_QUOTES"
if [ "$GOOGLE_DOCS" -gt "$NUMPY_DOCS" ] && [ "$GOOGLE_DOCS" -gt "$REST_DOCS" ]; then
  echo "  [GOOGLE] Primarily Google-style docstrings"
elif [ "$NUMPY_DOCS" -gt 0 ]; then
  echo "  [NUMPY] Primarily NumPy-style docstrings"
elif [ "$REST_DOCS" -gt 0 ]; then
  echo "  [REST] Primarily reST-style docstrings"
elif [ "$TRIPLE_QUOTES" -gt 0 ]; then
  echo "  [MINIMAL] Docstrings present but no consistent style"
else
  echo "  [NONE] No docstrings detected"
fi

# Import style
echo ""
echo "-- IMPORT STYLE --"
ABSOLUTE_IMPORTS=$(grep -rcE "^from app\.|^from src\.|^import app\.|^import src\." "$SRC" --include="*.py" 2>/dev/null | awk -F: '{sum+=$2} END {print sum+0}')
RELATIVE_IMPORTS=$(grep -rcE "^from \.|^from \.\." "$SRC" --include="*.py" 2>/dev/null | awk -F: '{sum+=$2} END {print sum+0}')
echo "  Absolute imports: $ABSOLUTE_IMPORTS"
echo "  Relative imports: $RELATIVE_IMPORTS"

# Async patterns
echo ""
echo "-- ASYNC PATTERNS --"
ASYNC_DEF=$(grep -rc "async def " "$SRC" --include="*.py" 2>/dev/null | awk -F: '{sum+=$2} END {print sum+0}')
SYNC_DEF=$(grep -rcE "^def |^    def " "$SRC" --include="*.py" 2>/dev/null | awk -F: '{sum+=$2} END {print sum+0}')
AWAIT_COUNT=$(grep -rc "await " "$SRC" --include="*.py" 2>/dev/null | awk -F: '{sum+=$2} END {print sum+0}')
echo "  async def count: $ASYNC_DEF"
echo "  def count:       $SYNC_DEF"
echo "  await usage:     $AWAIT_COUNT"

# String formatting
echo ""
echo "-- STRING FORMATTING --"
FSTRINGS=$(grep -rcE 'f".*\{.*\}.*"|f'"'"'.*\{.*\}.*'"'" "$SRC" --include="*.py" 2>/dev/null | awk -F: '{sum+=$2} END {print sum+0}')
FORMAT_CALLS=$(grep -rc '\.format(' "$SRC" --include="*.py" 2>/dev/null | awk -F: '{sum+=$2} END {print sum+0}')
PERCENT_FMT=$(grep -rc '% (' "$SRC" --include="*.py" 2>/dev/null | awk -F: '{sum+=$2} END {print sum+0}')
echo "  f-strings:    $FSTRINGS"
echo "  .format():    $FORMAT_CALLS"
echo "  % formatting: $PERCENT_FMT"

# Walrus operator
echo ""
echo "-- MODERN PYTHON --"
WALRUS=$(grep -rc ":=" "$SRC" --include="*.py" 2>/dev/null | awk -F: '{sum+=$2} END {print sum+0}')
MATCH_CASE=$(grep -rcE "^    match |^match " "$SRC" --include="*.py" 2>/dev/null | awk -F: '{sum+=$2} END {print sum+0}')
echo "  Walrus operator (:=): $WALRUS"
echo "  match/case:           $MATCH_CASE"

# Class patterns
echo ""
echo "-- CLASS PATTERNS --"
PYDANTIC_MODELS=$(grep -rcE "class.*BaseModel|class.*BaseSettings" "$SRC" --include="*.py" 2>/dev/null | awk -F: '{sum+=$2} END {print sum+0}')
DATACLASSES=$(grep -rc "@dataclass" "$SRC" --include="*.py" 2>/dev/null | awk -F: '{sum+=$2} END {print sum+0}')
PLAIN_CLASSES=$(grep -rc "^class " "$SRC" --include="*.py" 2>/dev/null | awk -F: '{sum+=$2} END {print sum+0}')
echo "  Pydantic models:  $PYDANTIC_MODELS"
echo "  Dataclasses:      $DATACLASSES"
echo "  Total classes:    $PLAIN_CLASSES"

# Error handling
echo ""
echo "-- ERROR HANDLING --"
TRY_EXCEPT=$(grep -rc "try:" "$SRC" --include="*.py" 2>/dev/null | awk -F: '{sum+=$2} END {print sum+0}')
RAISE_HTTP=$(grep -rc "raise HTTPException" "$SRC" --include="*.py" 2>/dev/null | awk -F: '{sum+=$2} END {print sum+0}')
CUSTOM_EXC=$(grep -rcE "class.*Exception|class.*Error" "$SRC" --include="*.py" 2>/dev/null | awk -F: '{sum+=$2} END {print sum+0}')
echo "  try/except blocks:      $TRY_EXCEPT"
echo "  raise HTTPException:    $RAISE_HTTP"
echo "  Custom exception classes: $CUSTOM_EXC"

echo ""
echo "========================================="
echo "  SCAN COMPLETE"
echo "========================================="
echo ""
echo "  Next: Read 1-2 files per category above,"
echo "  following references/scan-checklist.md"
