#!/bin/bash
# Express Codebase Structure Scanner
# Usage: bash scan-structure.sh <project-path>
# Outputs: directory tree, dependencies, configs, architecture pattern, and representative files per category.
# Works on: Linux, macOS, Windows (Git Bash / WSL)

PROJECT_PATH="${1:-.}"

if [ ! -d "$PROJECT_PATH" ]; then
  echo "ERROR: Directory '$PROJECT_PATH' does not exist."
  exit 1
fi

if [ ! -f "$PROJECT_PATH/package.json" ]; then
  echo "ERROR: No package.json found at '$PROJECT_PATH'."
  exit 1
fi

# ── Detect source directory ────────────────────────────────────────
SRC="$PROJECT_PATH/src"
if [ ! -d "$SRC" ]; then
  SRC="$PROJECT_PATH/server"
  if [ ! -d "$SRC" ]; then
    SRC="$PROJECT_PATH/api"
    if [ ! -d "$SRC" ]; then
      SRC="$PROJECT_PATH"
    fi
  fi
fi

echo "========================================="
echo "  EXPRESS CODEBASE SCANNER"
echo "  Project: $PROJECT_PATH"
echo "  Source:  $SRC"
echo "========================================="

# ── PROJECT SIZE DETECTION ──────────────────────────────────────
TOTAL_FILES=$(find "$SRC" -type f \( -name "*.ts" -o -name "*.js" -o -name "*.mjs" -o -name "*.cjs" \) -not -path "*/node_modules/*" -not -path "*/dist/*" -not -path "*/build/*" 2>/dev/null | wc -l)
echo ""
echo "── PROJECT SIZE ──"
echo "  PROJECT_SIZE: $TOTAL_FILES files"
if [ "$TOTAL_FILES" -gt 2000 ]; then
  echo "  LARGE_PROJECT: true"
  echo "  RECOMMENDATION: Use parallel extraction mode (subagents) for better coverage"
else
  echo "  LARGE_PROJECT: false"
fi

# ── 0. REPOMIX DETECTION ─────────────────────────────────────────
echo ""
echo "── REPOMIX ──"
if command -v repomix &>/dev/null || npx --no repomix --version &>/dev/null; then
  echo "  [AVAILABLE] repomix detected"
  echo "  Run: npx repomix $PROJECT_PATH --output $PROJECT_PATH/repomix-output.txt"
else
  echo "  [NOT FOUND] repomix not available — skipping (install: npm i -g repomix)"
fi

# ── 1. FRAMEWORK DETECTION ──────────────────────────────────────
echo ""
echo "── FRAMEWORK ──"
FRAMEWORK="unknown"
if grep -q '"express"' "$PROJECT_PATH/package.json" 2>/dev/null; then
  FRAMEWORK="express"
elif grep -q '"fastify"' "$PROJECT_PATH/package.json" 2>/dev/null; then
  FRAMEWORK="fastify"
elif grep -q '"koa"' "$PROJECT_PATH/package.json" 2>/dev/null; then
  FRAMEWORK="koa"
elif grep -q '"@hapi/hapi"' "$PROJECT_PATH/package.json" 2>/dev/null; then
  FRAMEWORK="hapi"
elif grep -q '"restify"' "$PROJECT_PATH/package.json" 2>/dev/null; then
  FRAMEWORK="restify"
fi
echo "  Detected: $FRAMEWORK"

# ── 1b. LANGUAGE DETECTION ──────────────────────────────────────
echo ""
echo "── LANGUAGE ──"
if [ -f "$PROJECT_PATH/tsconfig.json" ]; then
  echo "  TypeScript"
  LANG_EXT="ts"
else
  echo "  JavaScript"
  LANG_EXT="js"
fi

# ── 1c. MODULE SYSTEM ──────────────────────────────────────────
echo ""
echo "── MODULE SYSTEM ──"
PKG_TYPE=$(grep -o '"type"\s*:\s*"[^"]*"' "$PROJECT_PATH/package.json" 2>/dev/null | sed 's/.*"\([^"]*\)"/\1/')
if [ "$PKG_TYPE" = "module" ]; then
  echo "  ESM (type: module)"
elif [ "$LANG_EXT" = "ts" ]; then
  echo "  TypeScript (compiled)"
else
  echo "  CommonJS (default)"
fi

# ── 1d. PACKAGE MANAGER DETECTION ──────────────────────────────
echo ""
echo "── PACKAGE MANAGER ──"
if [ -f "$PROJECT_PATH/pnpm-lock.yaml" ]; then
  echo "  pnpm"
elif [ -f "$PROJECT_PATH/yarn.lock" ]; then
  echo "  yarn"
elif [ -f "$PROJECT_PATH/bun.lockb" ]; then
  echo "  bun"
elif [ -f "$PROJECT_PATH/package-lock.json" ]; then
  echo "  npm"
else
  echo "  unknown"
fi

# ── 2. PACKAGE.JSON ─────────────────────────────────────────────
echo ""
echo "── DEPENDENCIES ──"

# Cross-platform: try python3, then python, then fallback to cat
if command -v python3 &>/dev/null; then
  PYTHON_CMD="python3"
elif command -v python &>/dev/null; then
  PYTHON_CMD="python"
else
  PYTHON_CMD=""
fi

if [ -n "$PYTHON_CMD" ]; then
  PROJECT_PATH="$PROJECT_PATH" $PYTHON_CMD -c "
import sys, json, os
d = json.load(open(os.path.join(os.environ['PROJECT_PATH'], 'package.json')))
print(f\"  Name: {d.get('name','N/A')} v{d.get('version','N/A')}\")
print()
print('  Production:')
for k,v in sorted(d.get('dependencies',{}).items()):
    print(f'    {k}: {v}')
print()
print('  Dev:')
for k,v in sorted(d.get('devDependencies',{}).items()):
    print(f'    {k}: {v}')
print()
print('  Scripts:')
for k,v in d.get('scripts',{}).items():
    print(f'    {k}: {v}')
" 2>/dev/null
else
  echo "  (python not found — showing raw package.json)"
  cat "$PROJECT_PATH/package.json"
fi

# ── 2b. STACK CLASSIFICATION ──────────────────────────────────
echo ""
echo "── STACK SUMMARY ──"
PKG="$PROJECT_PATH/package.json"

check_dep() {
  grep -q "\"$1\"" "$PKG" 2>/dev/null
}

# ORM / Database
echo -n "  ORM/DB:           "
if check_dep "prisma" || check_dep "@prisma/client"; then echo "Prisma"
elif check_dep "sequelize"; then echo "Sequelize"
elif check_dep "typeorm"; then echo "TypeORM"
elif check_dep "mongoose"; then echo "Mongoose (MongoDB)"
elif check_dep "knex"; then echo "Knex.js (query builder)"
elif check_dep "drizzle-orm"; then echo "Drizzle ORM"
elif check_dep "objection"; then echo "Objection.js"
elif check_dep "mikro-orm" || check_dep "@mikro-orm/core"; then echo "MikroORM"
elif check_dep "pg"; then echo "pg (raw PostgreSQL)"
elif check_dep "mysql2"; then echo "mysql2 (raw MySQL)"
elif check_dep "better-sqlite3"; then echo "better-sqlite3"
elif check_dep "mongodb"; then echo "mongodb (native driver)"
else echo "none"; fi

# Validation
echo -n "  Validation:       "
if check_dep "zod"; then echo "Zod"
elif check_dep "joi"; then echo "Joi"
elif check_dep "express-validator"; then echo "express-validator"
elif check_dep "class-validator"; then echo "class-validator"
elif check_dep "yup"; then echo "Yup"
elif check_dep "ajv"; then echo "Ajv"
else echo "none"; fi

# Auth
echo -n "  Auth:             "
AUTH=""
check_dep "jsonwebtoken" && AUTH="jsonwebtoken"
check_dep "passport" && AUTH="${AUTH:+$AUTH + }Passport.js"
check_dep "bcrypt" && AUTH="${AUTH:+$AUTH + }bcrypt"
check_dep "bcryptjs" && AUTH="${AUTH:+$AUTH + }bcryptjs"
check_dep "argon2" && AUTH="${AUTH:+$AUTH + }argon2"
check_dep "express-session" && AUTH="${AUTH:+$AUTH + }express-session"
check_dep "connect-redis" && AUTH="${AUTH:+$AUTH + }connect-redis"
echo "${AUTH:-none}"

# HTTP Client
echo -n "  HTTP Client:      "
if check_dep "axios"; then echo "axios"
elif check_dep "got"; then echo "got"
elif check_dep "node-fetch"; then echo "node-fetch"
elif check_dep "undici"; then echo "undici"
else echo "native fetch / none"; fi

# Task Queue
echo -n "  Task Queue:       "
if check_dep "bull"; then echo "Bull"
elif check_dep "bullmq"; then echo "BullMQ"
elif check_dep "agenda"; then echo "Agenda"
elif check_dep "bee-queue"; then echo "Bee Queue"
elif check_dep "node-cron"; then echo "node-cron"
else echo "none"; fi

# Cache
echo -n "  Cache:            "
if check_dep "ioredis"; then echo "ioredis"
elif check_dep "redis"; then echo "redis"
elif check_dep "node-cache"; then echo "node-cache"
elif check_dep "lru-cache"; then echo "lru-cache"
else echo "none"; fi

# WebSocket
echo -n "  WebSocket:        "
if check_dep "socket.io"; then echo "Socket.io"
elif check_dep "ws"; then echo "ws"
elif check_dep "@socket.io/redis-adapter"; then echo "Socket.io + Redis adapter"
else echo "none"; fi

# Testing
echo -n "  Testing:          "
TESTING=""
check_dep "jest" && TESTING="jest"
check_dep "vitest" && TESTING="${TESTING:+$TESTING + }vitest"
check_dep "mocha" && TESTING="${TESTING:+$TESTING + }mocha"
check_dep "supertest" && TESTING="${TESTING:+$TESTING + }supertest"
check_dep "chai" && TESTING="${TESTING:+$TESTING + }chai"
check_dep "sinon" && TESTING="${TESTING:+$TESTING + }sinon"
check_dep "nock" && TESTING="${TESTING:+$TESTING + }nock"
check_dep "msw" && TESTING="${TESTING:+$TESTING + }msw"
echo "${TESTING:-none}"

# Logging
echo -n "  Logging:          "
if check_dep "winston"; then echo "winston"
elif check_dep "pino"; then echo "pino"
elif check_dep "morgan"; then echo "morgan"
elif check_dep "bunyan"; then echo "bunyan"
else echo "console / none"; fi

# Security
echo -n "  Security:         "
SECURITY=""
check_dep "helmet" && SECURITY="helmet"
check_dep "cors" && SECURITY="${SECURITY:+$SECURITY + }cors"
check_dep "hpp" && SECURITY="${SECURITY:+$SECURITY + }hpp"
check_dep "express-rate-limit" && SECURITY="${SECURITY:+$SECURITY + }rate-limit"
check_dep "csurf" && SECURITY="${SECURITY:+$SECURITY + }csurf"
echo "${SECURITY:-none}"

# Email
echo -n "  Email:            "
if check_dep "nodemailer"; then echo "nodemailer"
elif check_dep "@sendgrid/mail"; then echo "SendGrid"
elif check_dep "mailgun"; then echo "Mailgun"
elif check_dep "postmark"; then echo "Postmark"
else echo "none"; fi

# File Upload
echo -n "  File Upload:      "
if check_dep "multer"; then echo "multer"
elif check_dep "formidable"; then echo "formidable"
elif check_dep "busboy"; then echo "busboy"
else echo "none"; fi

# API Documentation
echo -n "  API Docs:         "
if check_dep "swagger-jsdoc" || check_dep "swagger-ui-express"; then echo "Swagger/OpenAPI"
elif check_dep "@apidevtools/swagger-parser"; then echo "Swagger Parser"
else echo "none"; fi

# Monitoring
echo -n "  Monitoring:       "
MONITORING=""
check_dep "@sentry/node" && MONITORING="Sentry"
check_dep "prom-client" && MONITORING="${MONITORING:+$MONITORING + }Prometheus"
check_dep "@opentelemetry/api" && MONITORING="${MONITORING:+$MONITORING + }OpenTelemetry"
check_dep "newrelic" && MONITORING="${MONITORING:+$MONITORING + }New Relic"
echo "${MONITORING:-none}"

# ── 2c. PATH ALIASES ──────────────────────────────────────────
echo ""
echo "── PATH ALIASES ──"
if [ -f "$PROJECT_PATH/tsconfig.json" ]; then
  if [ -n "$PYTHON_CMD" ]; then
    PROJECT_PATH="$PROJECT_PATH" $PYTHON_CMD -c "
import json, re, os
raw = open(os.path.join(os.environ['PROJECT_PATH'], 'tsconfig.json')).read()
raw = re.sub(r'//.*', '', raw)
raw = re.sub(r'/\*.*?\*/', '', raw, flags=re.DOTALL)
raw = re.sub(r',\s*([}\]])', r'\1', raw)
d = json.loads(raw)
paths = d.get('compilerOptions', {}).get('paths', {})
base = d.get('compilerOptions', {}).get('baseUrl', '.')
if paths:
    print(f'  baseUrl: {base}')
    for alias, targets in paths.items():
        print(f'  {alias} -> {targets[0]}')
else:
    print('  No path aliases configured')
" 2>/dev/null || echo "  (could not parse tsconfig.json)"
  else
    grep -A 20 '"paths"' "$PROJECT_PATH/tsconfig.json" 2>/dev/null | head -15 || echo "  (no paths found)"
  fi
else
  echo "  No tsconfig.json found"
fi

# ── 2d. ARCHITECTURE PATTERN ────────────────────────────────────
echo ""
echo "── ARCHITECTURE PATTERN ──"

ARCH_STYLE="flat"

# Check for layered architecture
HAS_ROUTES=$(find "$SRC" -maxdepth 3 -type d \( -name "routes" -o -name "routers" \) 2>/dev/null | head -1)
HAS_CONTROLLERS=$(find "$SRC" -maxdepth 3 -type d \( -name "controllers" -o -name "controller" \) 2>/dev/null | head -1)
HAS_SERVICES=$(find "$SRC" -maxdepth 3 -type d \( -name "services" -o -name "service" \) 2>/dev/null | head -1)
HAS_MODELS=$(find "$SRC" -maxdepth 3 -type d \( -name "models" -o -name "model" -o -name "entities" \) 2>/dev/null | head -1)
HAS_REPOS=$(find "$SRC" -maxdepth 3 -type d \( -name "repositories" -o -name "repos" -o -name "repository" \) 2>/dev/null | head -1)
HAS_MIDDLEWARE=$(find "$SRC" -maxdepth 3 -type d \( -name "middleware" -o -name "middlewares" \) 2>/dev/null | head -1)

# Check for feature/module-based
HAS_MODULES=$(find "$SRC" -maxdepth 2 -type d \( -name "modules" -o -name "features" -o -name "domains" \) 2>/dev/null | head -1)

if [ -n "$HAS_MODULES" ]; then
  MODULE_DIR="$HAS_MODULES"
  SELF_CONTAINED=$(find "$MODULE_DIR" -mindepth 2 -maxdepth 2 -type d \( -name "routes" -o -name "controllers" -o -name "services" -o -name "models" \) 2>/dev/null | wc -l)
  if [ "$SELF_CONTAINED" -gt 2 ]; then
    ARCH_STYLE="modular"
    echo "  [MODULAR] Feature/Module-based with self-contained modules"
    echo "    Each module has its own routes, controllers, services, models"
  else
    ARCH_STYLE="modular-flat"
    echo "  [MODULAR-FLAT] Module-based with shared layers"
  fi
elif [ -n "$HAS_ROUTES" ] && [ -n "$HAS_CONTROLLERS" ] && [ -n "$HAS_SERVICES" ] && [ -n "$HAS_REPOS" ]; then
  ARCH_STYLE="layered-full"
  echo "  [LAYERED] Full layered architecture"
  echo "    Route → Controller → Service → Repository → Model"
elif [ -n "$HAS_ROUTES" ] && [ -n "$HAS_CONTROLLERS" ] && [ -n "$HAS_SERVICES" ]; then
  ARCH_STYLE="layered"
  echo "  [LAYERED] Controller + Service architecture"
  echo "    Route → Controller → Service → Model"
elif [ -n "$HAS_ROUTES" ] && [ -n "$HAS_CONTROLLERS" ]; then
  ARCH_STYLE="mvc"
  echo "  [MVC] Route + Controller pattern"
  echo "    Route → Controller → Model (no service layer)"
elif [ -n "$HAS_ROUTES" ]; then
  ARCH_STYLE="route-based"
  echo "  [ROUTE-BASED] Route-centric"
  echo "    Routes with inline logic or thin controllers"
else
  echo "  [FLAT] Flat structure or single-file"
fi

# ── 3. DIRECTORY STRUCTURE ────────────────────────────────────────
echo ""
echo "── DIRECTORY STRUCTURE ──"
find "$SRC" -maxdepth 5 -type d -not -path "*/node_modules/*" -not -path "*/dist/*" -not -path "*/build/*" -not -path "*/.git/*" 2>/dev/null | sed "s|$PROJECT_PATH/||" | sort

# ── 4. FILE COUNTS ───────────────────────────────────────────────
echo ""
echo "── FILE COUNTS ──"
find "$SRC" -type f -not -path "*/node_modules/*" -not -path "*/dist/*" -not -path "*/build/*" 2>/dev/null | awk -F/ '{print $NF}' | grep '\.' | sed 's/.*\.//' | sort | uniq -c | sort -rn

# ── 5. CONFIG FILES ──────────────────────────────────────────────
echo ""
echo "── CONFIG FILES ──"
for config in tsconfig.json jsconfig.json package.json \
              .env .env.example .env.local .env.development .env.production .env.test \
              .eslintrc .eslintrc.js .eslintrc.cjs .eslintrc.json eslint.config.js eslint.config.mjs \
              .prettierrc .prettierrc.js .prettierrc.cjs biome.json \
              jest.config.js jest.config.ts vitest.config.ts vitest.config.js \
              nodemon.json .swcrc esbuild.config.js \
              Dockerfile docker-compose.yml docker-compose.yaml .dockerignore \
              Makefile Procfile \
              .github/workflows .gitlab-ci.yml \
              knexfile.js knexfile.ts ormconfig.js ormconfig.ts \
              prisma/schema.prisma \
              swagger.json openapi.yaml openapi.json \
              .editorconfig \
              commitlint.config.js .husky; do
  if [ -f "$PROJECT_PATH/$config" ] || [ -d "$PROJECT_PATH/$config" ]; then
    echo "  [FOUND] $config"
  fi
done

# Check for prisma directory
if [ -d "$PROJECT_PATH/prisma" ]; then
  echo "  [FOUND] prisma/ directory"
  MIGRATION_COUNT=$(find "$PROJECT_PATH/prisma/migrations" -type d -mindepth 1 2>/dev/null | wc -l)
  echo "    Migrations: $MIGRATION_COUNT"
fi

# ── 6. REPRESENTATIVE FILES ──────────────────────────────────────
echo ""
echo "══════════════════════════════════════════"
echo "  REPRESENTATIVE FILES (1 per category)"
echo "══════════════════════════════════════════"

# Entry points
echo ""
echo "── ENTRY POINTS ──"
for f in app.ts app.js server.ts server.js index.ts index.js main.ts main.js; do
  found=$(find "$SRC" -maxdepth 2 -name "$f" -not -path "*/node_modules/*" 2>/dev/null | head -1)
  if [ -n "$found" ]; then
    echo "  $found" | sed "s|$PROJECT_PATH/||"
  fi
done

# Route files
echo ""
echo "── ROUTES (pick 1 to read) ──"
find "$SRC" \( -name "*route*" -o -name "*router*" -o -name "*.routes.*" \) \
  -not -path "*/node_modules/*" -not -path "*/dist/*" -not -name "*.test.*" -not -name "*.spec.*" \
  -type f 2>/dev/null | head -10 | sed "s|$PROJECT_PATH/||"

# Controller files
echo ""
echo "── CONTROLLERS (pick 1 to read) ──"
find "$SRC" \( -name "*controller*" -o -name "*Controller*" -o -name "*.controller.*" \) \
  -not -path "*/node_modules/*" -not -path "*/dist/*" -not -name "*.test.*" -not -name "*.spec.*" \
  -type f 2>/dev/null | head -10 | sed "s|$PROJECT_PATH/||"

# Service files
echo ""
echo "── SERVICES (pick 1 to read) ──"
find "$SRC" \( -name "*service*" -o -name "*Service*" -o -name "*.service.*" \) \
  -not -path "*/node_modules/*" -not -path "*/dist/*" -not -name "*.test.*" -not -name "*.spec.*" \
  -type f 2>/dev/null | head -10 | sed "s|$PROJECT_PATH/||"

# Repository files
echo ""
echo "── REPOSITORIES (pick 1 to read) ──"
find "$SRC" \( -name "*repository*" -o -name "*Repository*" -o -name "*.repository.*" -o -name "*repo*" \) \
  -not -path "*/node_modules/*" -not -path "*/dist/*" -not -name "*.test.*" -not -name "*.spec.*" \
  -not -name "*package*" -type f 2>/dev/null | head -10 | sed "s|$PROJECT_PATH/||"

# Model files
echo ""
echo "── MODELS (pick 1 to read) ──"
find "$SRC" \( -name "*model*" -o -name "*Model*" -o -name "*.model.*" -o -name "*entity*" \) \
  -not -path "*/node_modules/*" -not -path "*/dist/*" -not -name "*.test.*" -not -name "*.spec.*" \
  -not -path "*/schema*" -type f 2>/dev/null | head -10 | sed "s|$PROJECT_PATH/||"

# Schema / validation files
echo ""
echo "── VALIDATION SCHEMAS (pick 1 to read) ──"
find "$SRC" \( -name "*schema*" -o -name "*Schema*" -o -name "*.schema.*" -o -name "*dto*" -o -name "*Dto*" -o -name "*validator*" \) \
  -not -path "*/node_modules/*" -not -path "*/dist/*" -not -name "*.test.*" -not -name "*.spec.*" \
  -not -path "*/prisma/*" -type f 2>/dev/null | head -10 | sed "s|$PROJECT_PATH/||"

# Middleware files
echo ""
echo "── MIDDLEWARE (pick 1 to read) ──"
find "$SRC" \( -name "*middleware*" -o -name "*Middleware*" -o -path "*/middleware/*" -o -path "*/middlewares/*" \) \
  -not -path "*/node_modules/*" -not -path "*/dist/*" -not -name "*.test.*" -not -name "*.spec.*" \
  -type f 2>/dev/null | head -10 | sed "s|$PROJECT_PATH/||"

# Auth files
echo ""
echo "── AUTH FILES ──"
find "$SRC" -path "*auth*" -not -path "*/node_modules/*" -not -path "*/dist/*" \
  -not -name "*.test.*" -not -name "*.spec.*" -type f 2>/dev/null | head -10 | sed "s|$PROJECT_PATH/||"

# Error handling
echo ""
echo "── ERROR HANDLING ──"
find "$SRC" \( -name "*error*" -o -name "*Error*" -o -name "*exception*" -o -name "*Exception*" \) \
  -not -path "*/node_modules/*" -not -path "*/dist/*" -not -name "*.test.*" -not -name "*.spec.*" \
  -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Database files
echo ""
echo "── DATABASE FILES ──"
find "$SRC" \( -name "*database*" -o -name "*db*" -o -name "*connection*" -o -name "*prisma*" -o -name "*knex*" \) \
  -not -path "*/node_modules/*" -not -path "*/dist/*" -not -name "*.test.*" -not -name "*.spec.*" \
  -not -name "*.lock" -not -name "*.log" -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Config files (app config, not tooling)
echo ""
echo "── APP CONFIG ──"
find "$SRC" \( -name "*config*" -o -name "*Config*" -o -name "*.config.*" \) \
  -not -path "*/node_modules/*" -not -path "*/dist/*" -not -name "*.test.*" -not -name "*.spec.*" \
  -not -name "tsconfig*" -not -name "jest*" -not -name "vitest*" -not -name "eslint*" -not -name "prettier*" \
  -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Utils / helpers
echo ""
echo "── UTILS / HELPERS ──"
find "$SRC" \( -name "*util*" -o -name "*helper*" -o -name "*common*" -o -path "*/utils/*" -o -path "*/helpers/*" \) \
  -not -path "*/node_modules/*" -not -path "*/dist/*" -not -name "*.test.*" -not -name "*.spec.*" \
  -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Types / interfaces
echo ""
echo "── TYPE FILES ──"
find "$SRC" \( -name "*.d.ts" -o -name "*types*" -o -name "*interfaces*" -o -path "*/types/*" \) \
  -not -path "*/node_modules/*" -not -path "*/dist/*" -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Constants / enums
echo ""
echo "── CONSTANTS / ENUMS ──"
find "$SRC" \( -name "*constant*" -o -name "*enum*" -o -name "*Constants*" -o -name "*Enum*" \) \
  -not -path "*/node_modules/*" -not -path "*/dist/*" -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Queue / workers
echo ""
echo "── QUEUE / WORKERS ──"
find "$SRC" \( -name "*queue*" -o -name "*worker*" -o -name "*job*" -o -name "*bull*" -o -name "*task*" \) \
  -not -path "*/node_modules/*" -not -path "*/dist/*" -not -name "*.test.*" -not -name "*.spec.*" \
  -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Test files
echo ""
echo "── TEST FILES ──"
find "$SRC" \( -name "*.test.*" -o -name "*.spec.*" \) -not -path "*/node_modules/*" -not -path "*/dist/*" -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"
if [ -d "$PROJECT_PATH/tests" ] || [ -d "$PROJECT_PATH/__tests__" ]; then
  TEST_DIR="${PROJECT_PATH}/tests"
  [ -d "$PROJECT_PATH/__tests__" ] && TEST_DIR="$PROJECT_PATH/__tests__"
  echo "  [DIR] $(basename "$TEST_DIR")/"
  find "$TEST_DIR" -maxdepth 3 -type f -not -path "*/node_modules/*" 2>/dev/null | head -10 | sed "s|$PROJECT_PATH/||" | sed 's/^/    /'
fi

# ── 7. MODULE SLICE EXAMPLE ─────────────────────────────────────
echo ""
echo "══════════════════════════════════════════"
echo "  MODULE SLICE EXAMPLE"
echo "══════════════════════════════════════════"
echo ""
echo "  Shows one complete module/feature with all its files."
echo ""

SLICE_DIR=""
for base_dir in "$SRC/modules" "$SRC/features" "$SRC/domains" "$SRC/routes" "$SRC/api" "$SRC/api/v1"; do
  if [ -d "$base_dir" ]; then
    SLICE_DIR=$(find "$base_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | while read -r dir; do
      count=$(find "$dir" -type f -not -path "*/node_modules/*" 2>/dev/null | wc -l)
      echo "$count $dir"
    done | sort -rn | head -1 | sed 's/^[[:space:]]*[0-9]*[[:space:]]*//')
    [ -n "$SLICE_DIR" ] && break
  fi
done

if [ -n "$SLICE_DIR" ]; then
  FILE_COUNT=$(find "$SLICE_DIR" -type f -not -path "*/node_modules/*" 2>/dev/null | wc -l)
  echo "── $(basename "$SLICE_DIR") ($FILE_COUNT files) ──"
  find "$SLICE_DIR" -type f -not -path "*/node_modules/*" 2>/dev/null | sed "s|$PROJECT_PATH/||" | sort
else
  echo "  No module directory found with nested structure."
fi

# ── 8. LARGEST FILES PER CATEGORY ───────────────────────────────
echo ""
echo "══════════════════════════════════════════"
echo "  LARGEST FILES (for smart sampling)"
echo "══════════════════════════════════════════"
echo ""
echo "  Read the longest file per category to see the most complete patterns."
echo ""

show_largest() {
  local label="$1"
  local search_path="$2"
  shift 2
  local result
  result=$(find "$search_path" \( "$@" \) -not -path "*/node_modules/*" -not -path "*/dist/*" -not -path "*/build/*" -type f -print0 2>/dev/null | xargs -0 wc -l 2>/dev/null | grep -v " total$" | sort -rn | head -1)
  if [ -n "$result" ]; then
    local lines file
    lines=$(echo "$result" | awk '{print $1}')
    file=$(echo "$result" | sed 's/^[[:space:]]*[0-9]*//' | sed 's/^[[:space:]]*//' | sed "s|$PROJECT_PATH/||")
    echo "  $label: $file ($lines lines)"
  fi
}

show_largest "Route" "$SRC" -name "*route*" -o -name "*router*"
show_largest "Controller" "$SRC" -name "*controller*" -o -name "*Controller*"
show_largest "Service" "$SRC" -name "*service*" -o -name "*Service*"
show_largest "Repository" "$SRC" -name "*repository*" -o -name "*Repository*"
show_largest "Model" "$SRC" -name "*model*" -o -name "*Model*"
show_largest "Schema" "$SRC" -name "*schema*" -o -name "*Schema*" -o -name "*dto*"
show_largest "Middleware" "$SRC" -name "*middleware*" -o -name "*Middleware*"
show_largest "Auth" "$SRC" -path "*auth*" -not -name "*.test.*"
show_largest "Test" "$SRC" -name "*.test.*" -o -name "*.spec.*"
show_largest "Config" "$SRC" -name "*config*" -not -name "tsconfig*"
show_largest "Utils" "$SRC" -name "*util*" -o -name "*helper*"

# ── 9. CODING STYLE SIGNALS ────────────────────────────────────
echo ""
echo "══════════════════════════════════════════"
echo "  CODING STYLE SIGNALS"
echo "══════════════════════════════════════════"

# Barrel exports
BARREL_COUNT=$(find "$SRC" \( -name "index.ts" -o -name "index.js" \) -not -path "*/node_modules/*" -not -path "*/dist/*" 2>/dev/null | wc -l)
echo ""
echo "── BARREL EXPORTS ──"
echo "  index.ts/js files: $BARREL_COUNT"
if [ "$BARREL_COUNT" -gt 5 ]; then
  echo "  [HEAVY] Uses barrel exports extensively"
elif [ "$BARREL_COUNT" -gt 0 ]; then
  echo "  [LIGHT] Some barrel exports"
else
  echo "  [NONE] No barrel exports — direct imports"
fi

# Export style
echo ""
echo "── EXPORT STYLE ──"
DEFAULT_EXPORTS=$(grep -rE "export default|module\.exports" "$SRC" --include="*.ts" --include="*.js" 2>/dev/null | grep -v "node_modules" | grep -v "dist/" | wc -l)
NAMED_EXPORTS=$(grep -rE "export (const|function|class|type|interface|enum)" "$SRC" --include="*.ts" --include="*.js" 2>/dev/null | grep -v "node_modules" | grep -v "dist/" | wc -l)
echo "  export default / module.exports: $DEFAULT_EXPORTS"
echo "  named exports:                   $NAMED_EXPORTS"

# Module system in use
echo ""
echo "── MODULE IMPORTS ──"
REQUIRE_COUNT=$(grep -r "require(" "$SRC" --include="*.ts" --include="*.js" 2>/dev/null | grep -v "node_modules" | grep -v "dist/" | wc -l)
IMPORT_COUNT=$(grep -r "^import " "$SRC" --include="*.ts" --include="*.js" 2>/dev/null | grep -v "node_modules" | grep -v "dist/" | wc -l)
echo "  import (ESM): $IMPORT_COUNT"
echo "  require (CJS): $REQUIRE_COUNT"

# Async patterns
echo ""
echo "── ASYNC PATTERNS ──"
ASYNC_AWAIT=$(grep -r "async " "$SRC" --include="*.ts" --include="*.js" 2>/dev/null | grep -v "node_modules" | grep -v "dist/" | wc -l)
THEN_CATCH=$(grep -rE "\.then\(|\.catch\(" "$SRC" --include="*.ts" --include="*.js" 2>/dev/null | grep -v "node_modules" | grep -v "dist/" | wc -l)
CALLBACKS=$(grep -rE "function\s*\(err," "$SRC" --include="*.ts" --include="*.js" 2>/dev/null | grep -v "node_modules" | grep -v "dist/" | wc -l)
echo "  async/await: $ASYNC_AWAIT"
echo "  .then/.catch: $THEN_CATCH"
echo "  callbacks (err, ...): $CALLBACKS"

# Function style
echo ""
echo "── FUNCTION STYLE ──"
ARROW=$(grep -rE "const \w+ = (async )?\(" "$SRC" --include="*.ts" --include="*.js" 2>/dev/null | grep -v "node_modules" | grep -v "dist/" | wc -l)
FUNC_DECL=$(grep -rE "^(export )?(async )?function " "$SRC" --include="*.ts" --include="*.js" 2>/dev/null | grep -v "node_modules" | grep -v "dist/" | wc -l)
echo "  Arrow functions (const x = () =>): $ARROW"
echo "  Function declarations:              $FUNC_DECL"

# Type definitions
echo ""
echo "── TYPE DEFINITIONS ──"
INTERFACES=$(grep -rE "export interface |interface " "$SRC" --include="*.ts" 2>/dev/null | grep -v "node_modules" | grep -v "dist/" | wc -l)
TYPE_ALIASES=$(grep -rE "export type |type " "$SRC" --include="*.ts" 2>/dev/null | grep -v "node_modules" | grep -v "dist/" | wc -l)
echo "  interface: $INTERFACES"
echo "  type:      $TYPE_ALIASES"

# Error handling
echo ""
echo "── ERROR HANDLING ──"
TRY_CATCH=$(grep -r "try {" "$SRC" --include="*.ts" --include="*.js" 2>/dev/null | grep -v "node_modules" | grep -v "dist/" | wc -l)
CUSTOM_ERRORS=$(grep -rE "class \w+Error extends" "$SRC" --include="*.ts" --include="*.js" 2>/dev/null | grep -v "node_modules" | grep -v "dist/" | wc -l)
NEXT_ERROR=$(grep -r "next(err" "$SRC" --include="*.ts" --include="*.js" 2>/dev/null | grep -v "node_modules" | grep -v "dist/" | wc -l)
echo "  try/catch blocks:      $TRY_CATCH"
echo "  Custom error classes:  $CUSTOM_ERRORS"
echo "  next(error) calls:     $NEXT_ERROR"

echo ""
echo "========================================="
echo "  SCAN COMPLETE"
echo "========================================="
echo ""
echo "  Next: Read 1-2 files per category above,"
echo "  following references/scan-checklist.md"
