#!/bin/bash
# NestJS Codebase Structure Scanner
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

# Verify NestJS project
if ! grep -q '"@nestjs/core"' "$PROJECT_PATH/package.json" 2>/dev/null; then
  echo "WARNING: @nestjs/core not found in package.json — this may not be a NestJS project."
fi

# ── Detect source directory ────────────────────────────────────────
SRC="$PROJECT_PATH/src"
if [ ! -d "$SRC" ]; then
  # NestJS monorepo: check apps/ or libs/
  if [ -d "$PROJECT_PATH/apps" ]; then
    SRC="$PROJECT_PATH/apps"
  else
    SRC="$PROJECT_PATH"
  fi
fi

echo "========================================="
echo "  NESTJS CODEBASE SCANNER"
echo "  Project: $PROJECT_PATH"
echo "  Source:  $SRC"
echo "========================================="

# ── PROJECT SIZE DETECTION ──────────────────────────────────────
TOTAL_FILES=$(find "$SRC" -type f -name "*.ts" -not -path "*/node_modules/*" -not -path "*/dist/*" -not -name "*.spec.ts" -not -name "*.e2e-spec.ts" 2>/dev/null | wc -l)
echo ""
echo "── PROJECT SIZE ──"
echo "  PROJECT_SIZE: $TOTAL_FILES source files (excluding tests)"
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
PKG="$PROJECT_PATH/package.json"

check_dep() {
  grep -q "\"$1\"" "$PKG" 2>/dev/null
}

# NestJS version
NEST_VER=$(grep -o '"@nestjs/core"\s*:\s*"[^"]*"' "$PKG" 2>/dev/null | sed 's/.*"\([^"]*\)"/\1/')
echo "  NestJS: ${NEST_VER:-not found}"

# Platform
echo -n "  Platform: "
if check_dep "@nestjs/platform-fastify"; then echo "Fastify"
elif check_dep "@nestjs/platform-express"; then echo "Express (default)"
else echo "Express (implicit)"; fi

# ── 1b. PACKAGE MANAGER DETECTION ──────────────────────────────
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

# ── 1c. MONOREPO DETECTION ──────────────────────────────────────
echo ""
echo "── MONOREPO ──"
if [ -f "$PROJECT_PATH/nest-cli.json" ]; then
  MONOREPO=$(grep -c '"projects"' "$PROJECT_PATH/nest-cli.json" 2>/dev/null)
  if [ "$MONOREPO" -gt 0 ]; then
    echo "  [YES] NestJS monorepo detected"
    echo "  Apps:"
    find "$PROJECT_PATH/apps" -maxdepth 1 -type d 2>/dev/null | tail -n +2 | sed "s|$PROJECT_PATH/||" | sed 's/^/    /'
    echo "  Libs:"
    find "$PROJECT_PATH/libs" -maxdepth 1 -type d 2>/dev/null | tail -n +2 | sed "s|$PROJECT_PATH/||" | sed 's/^/    /'
  else
    echo "  [NO] Single project"
  fi
else
  echo "  [NO] No nest-cli.json found"
fi

# ── 2. PACKAGE.JSON ─────────────────────────────────────────────
echo ""
echo "── DEPENDENCIES ──"

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

# NestJS Plugins
echo "  NestJS Modules:"
for mod in "@nestjs/config" "@nestjs/swagger" "@nestjs/typeorm" "@nestjs/mongoose" \
           "@nestjs/sequelize" "@nestjs/graphql" "@nestjs/cqrs" "@nestjs/microservices" \
           "@nestjs/websockets" "@nestjs/schedule" "@nestjs/bull" "@nestjs/cache-manager" \
           "@nestjs/terminus" "@nestjs/passport" "@nestjs/jwt" "@nestjs/throttler" \
           "@nestjs/event-emitter" "@nestjs/mapped-types" "@nestjs/serve-static"; do
  if check_dep "$mod"; then
    echo "    [FOUND] $mod"
  fi
done

# ORM / Database
echo ""
echo -n "  ORM/DB:           "
if check_dep "@nestjs/typeorm" || check_dep "typeorm"; then echo "TypeORM"
elif check_dep "@prisma/client" || check_dep "prisma"; then echo "Prisma"
elif check_dep "@nestjs/mongoose" || check_dep "mongoose"; then echo "Mongoose (MongoDB)"
elif check_dep "@nestjs/sequelize" || check_dep "sequelize"; then echo "Sequelize"
elif check_dep "@mikro-orm/core"; then echo "MikroORM"
elif check_dep "drizzle-orm"; then echo "Drizzle ORM"
elif check_dep "knex"; then echo "Knex.js"
else echo "none"; fi

# Validation
echo -n "  Validation:       "
if check_dep "class-validator"; then echo "class-validator + class-transformer"
elif check_dep "zod"; then echo "Zod"
elif check_dep "joi"; then echo "Joi"
else echo "none"; fi

# Auth
echo -n "  Auth:             "
AUTH=""
check_dep "@nestjs/passport" && AUTH="Passport"
check_dep "@nestjs/jwt" && AUTH="${AUTH:+$AUTH + }JWT"
check_dep "passport-jwt" && AUTH="${AUTH:+$AUTH + }passport-jwt"
check_dep "passport-local" && AUTH="${AUTH:+$AUTH + }passport-local"
check_dep "passport-google-oauth20" && AUTH="${AUTH:+$AUTH + }Google OAuth"
check_dep "bcrypt" && AUTH="${AUTH:+$AUTH + }bcrypt"
check_dep "bcryptjs" && AUTH="${AUTH:+$AUTH + }bcryptjs"
check_dep "argon2" && AUTH="${AUTH:+$AUTH + }argon2"
echo "${AUTH:-none}"

# API Style
echo -n "  API Style:        "
if check_dep "@nestjs/graphql"; then
  if check_dep "apollo-server-express" || check_dep "@apollo/server"; then echo "GraphQL (Apollo)"
  elif check_dep "mercurius"; then echo "GraphQL (Mercurius)"
  else echo "GraphQL"; fi
else echo "REST"; fi

# Cache
echo -n "  Cache:            "
if check_dep "@nestjs/cache-manager"; then echo "cache-manager"
elif check_dep "ioredis"; then echo "ioredis"
elif check_dep "redis"; then echo "redis"
else echo "none"; fi

# Queue
echo -n "  Queue:            "
if check_dep "@nestjs/bull" || check_dep "@nestjs/bullmq"; then echo "Bull/BullMQ"
elif check_dep "amqplib" || check_dep "amqp-connection-manager"; then echo "RabbitMQ"
else echo "none"; fi

# WebSocket
echo -n "  WebSocket:        "
if check_dep "@nestjs/websockets"; then
  if check_dep "socket.io"; then echo "Socket.io (via @nestjs/websockets)"
  elif check_dep "ws"; then echo "ws (via @nestjs/websockets)"
  else echo "@nestjs/websockets"; fi
else echo "none"; fi

# Testing
echo -n "  Testing:          "
TESTING=""
check_dep "jest" && TESTING="jest"
check_dep "@nestjs/testing" && TESTING="${TESTING:+$TESTING + }@nestjs/testing"
check_dep "supertest" && TESTING="${TESTING:+$TESTING + }supertest"
echo "${TESTING:-none}"

# Logging
echo -n "  Logging:          "
if check_dep "winston"; then echo "winston"
elif check_dep "pino"; then echo "pino"
elif check_dep "nestjs-pino"; then echo "nestjs-pino"
else echo "NestJS Logger (default)"; fi

# Security
echo -n "  Security:         "
SECURITY=""
check_dep "helmet" && SECURITY="helmet"
check_dep "@nestjs/throttler" && SECURITY="${SECURITY:+$SECURITY + }throttler"
check_dep "csurf" && SECURITY="${SECURITY:+$SECURITY + }csurf"
echo "${SECURITY:-none}"

# Monitoring
echo -n "  Monitoring:       "
MONITORING=""
check_dep "@sentry/node" && MONITORING="Sentry"
check_dep "prom-client" && MONITORING="${MONITORING:+$MONITORING + }Prometheus"
check_dep "@opentelemetry/api" && MONITORING="${MONITORING:+$MONITORING + }OpenTelemetry"
check_dep "@nestjs/terminus" && MONITORING="${MONITORING:+$MONITORING + }Health checks"
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

# ── 2d. NESTJS PATTERNS ──────────────────────────────────────
echo ""
echo "── NESTJS PATTERNS ──"

# Count NestJS file types
MODULE_COUNT=$(find "$SRC" -name "*.module.ts" -not -path "*/node_modules/*" -not -path "*/dist/*" 2>/dev/null | wc -l)
CONTROLLER_COUNT=$(find "$SRC" -name "*.controller.ts" -not -path "*/node_modules/*" -not -path "*/dist/*" 2>/dev/null | wc -l)
SERVICE_COUNT=$(find "$SRC" -name "*.service.ts" -not -path "*/node_modules/*" -not -path "*/dist/*" 2>/dev/null | wc -l)
ENTITY_COUNT=$(find "$SRC" -name "*.entity.ts" -not -path "*/node_modules/*" -not -path "*/dist/*" 2>/dev/null | wc -l)
DTO_COUNT=$(find "$SRC" -name "*.dto.ts" -not -path "*/node_modules/*" -not -path "*/dist/*" 2>/dev/null | wc -l)
GUARD_COUNT=$(find "$SRC" -name "*.guard.ts" -not -path "*/node_modules/*" -not -path "*/dist/*" 2>/dev/null | wc -l)
INTERCEPTOR_COUNT=$(find "$SRC" -name "*.interceptor.ts" -not -path "*/node_modules/*" -not -path "*/dist/*" 2>/dev/null | wc -l)
PIPE_COUNT=$(find "$SRC" -name "*.pipe.ts" -not -path "*/node_modules/*" -not -path "*/dist/*" 2>/dev/null | wc -l)
FILTER_COUNT=$(find "$SRC" -name "*.filter.ts" -not -path "*/node_modules/*" -not -path "*/dist/*" 2>/dev/null | wc -l)
DECORATOR_COUNT=$(find "$SRC" -name "*.decorator.ts" -not -path "*/node_modules/*" -not -path "*/dist/*" 2>/dev/null | wc -l)
STRATEGY_COUNT=$(find "$SRC" -name "*.strategy.ts" -not -path "*/node_modules/*" -not -path "*/dist/*" 2>/dev/null | wc -l)
GATEWAY_COUNT=$(find "$SRC" -name "*.gateway.ts" -not -path "*/node_modules/*" -not -path "*/dist/*" 2>/dev/null | wc -l)
RESOLVER_COUNT=$(find "$SRC" -name "*.resolver.ts" -not -path "*/node_modules/*" -not -path "*/dist/*" 2>/dev/null | wc -l)
SPEC_COUNT=$(find "$SRC" -name "*.spec.ts" -not -path "*/node_modules/*" -not -path "*/dist/*" 2>/dev/null | wc -l)

echo "  Modules:       $MODULE_COUNT"
echo "  Controllers:   $CONTROLLER_COUNT"
echo "  Services:      $SERVICE_COUNT"
echo "  Entities:      $ENTITY_COUNT"
echo "  DTOs:          $DTO_COUNT"
echo "  Guards:        $GUARD_COUNT"
echo "  Interceptors:  $INTERCEPTOR_COUNT"
echo "  Pipes:         $PIPE_COUNT"
echo "  Filters:       $FILTER_COUNT"
echo "  Decorators:    $DECORATOR_COUNT"
echo "  Strategies:    $STRATEGY_COUNT"
echo "  Gateways:      $GATEWAY_COUNT"
echo "  Resolvers:     $RESOLVER_COUNT"
echo "  Test specs:    $SPEC_COUNT"

# ── 2e. ARCHITECTURE PATTERN ──────────────────────────────────
echo ""
echo "── ARCHITECTURE PATTERN ──"

# Check if modules contain self-contained feature dirs
HAS_FEATURE_MODULES=false
for dir in "$SRC"/*/; do
  if [ -d "$dir" ] && [ "$(basename "$dir")" != "common" ] && [ "$(basename "$dir")" != "shared" ]; then
    if [ -f "${dir}$(basename "$dir").module.ts" ] 2>/dev/null || find "$dir" -maxdepth 1 -name "*.module.ts" 2>/dev/null | grep -q .; then
      HAS_FEATURE_MODULES=true
      break
    fi
  fi
done

if [ "$HAS_FEATURE_MODULES" = true ]; then
  echo "  [MODULAR] Feature module-based architecture"
  echo "    Each feature has: module + controller + service + DTOs"
else
  # Check for layered
  HAS_CONTROLLERS_DIR=$(find "$SRC" -maxdepth 2 -type d -name "controllers" 2>/dev/null | head -1)
  HAS_SERVICES_DIR=$(find "$SRC" -maxdepth 2 -type d -name "services" 2>/dev/null | head -1)
  if [ -n "$HAS_CONTROLLERS_DIR" ] && [ -n "$HAS_SERVICES_DIR" ]; then
    echo "  [LAYERED] Layered architecture"
    echo "    Separate directories: controllers/, services/, entities/"
  else
    echo "  [FLAT] Flat or minimal structure"
  fi
fi

# Check for CQRS
if check_dep "@nestjs/cqrs"; then
  echo "  [CQRS] Command-Query Responsibility Segregation detected"
  COMMAND_COUNT=$(find "$SRC" -name "*.command.ts" -not -path "*/node_modules/*" 2>/dev/null | wc -l)
  QUERY_COUNT=$(find "$SRC" -name "*.query.ts" -not -path "*/node_modules/*" 2>/dev/null | wc -l)
  EVENT_COUNT=$(find "$SRC" -name "*.event.ts" -not -path "*/node_modules/*" 2>/dev/null | wc -l)
  HANDLER_COUNT=$(find "$SRC" -name "*.handler.ts" -not -path "*/node_modules/*" 2>/dev/null | wc -l)
  echo "    Commands: $COMMAND_COUNT, Queries: $QUERY_COUNT, Events: $EVENT_COUNT, Handlers: $HANDLER_COUNT"
fi

# Check for microservices
if check_dep "@nestjs/microservices"; then
  echo "  [MICROSERVICES] Microservices patterns detected"
fi

# ── 3. DIRECTORY STRUCTURE ────────────────────────────────────────
echo ""
echo "── DIRECTORY STRUCTURE ──"
find "$SRC" -maxdepth 5 -type d -not -path "*/node_modules/*" -not -path "*/dist/*" -not -path "*/.git/*" 2>/dev/null | sed "s|$PROJECT_PATH/||" | sort

# ── 4. FILE COUNTS ───────────────────────────────────────────────
echo ""
echo "── FILE COUNTS ──"
find "$SRC" -type f -not -path "*/node_modules/*" -not -path "*/dist/*" 2>/dev/null | awk -F/ '{print $NF}' | grep '\.' | sed 's/.*\.//' | sort | uniq -c | sort -rn

# NestJS-specific file breakdown
echo ""
echo "── NESTJS FILE BREAKDOWN ──"
find "$SRC" -type f -name "*.ts" -not -path "*/node_modules/*" -not -path "*/dist/*" 2>/dev/null | awk -F/ '{print $NF}' | grep -E '\.(module|controller|service|entity|dto|guard|interceptor|pipe|filter|decorator|strategy|gateway|resolver|spec)\.ts$' | sed 's/.*\.\([^.]*\)\.ts/\1/' | sort | uniq -c | sort -rn

# ── 5. CONFIG FILES ──────────────────────────────────────────────
echo ""
echo "── CONFIG FILES ──"
for config in nest-cli.json tsconfig.json tsconfig.build.json package.json \
              .env .env.example .env.local .env.development .env.production .env.test \
              .eslintrc.js .eslintrc.cjs eslint.config.js eslint.config.mjs \
              .prettierrc .prettierrc.js biome.json \
              jest.config.js jest.config.ts jest-e2e.json \
              ormconfig.js ormconfig.ts \
              docker-compose.yml docker-compose.yaml Dockerfile .dockerignore \
              Makefile Procfile \
              .github/workflows \
              .swcrc webpack.config.js \
              commitlint.config.js .husky; do
  if [ -f "$PROJECT_PATH/$config" ] || [ -d "$PROJECT_PATH/$config" ]; then
    echo "  [FOUND] $config"
  fi
done

# Prisma
if [ -d "$PROJECT_PATH/prisma" ]; then
  echo "  [FOUND] prisma/ directory"
  MIGRATION_COUNT=$(find "$PROJECT_PATH/prisma/migrations" -type d -mindepth 1 2>/dev/null | wc -l)
  echo "    Migrations: $MIGRATION_COUNT"
fi

# TypeORM migrations
TYPEORM_MIGRATIONS=$(find "$SRC" -path "*/migrations/*.ts" -not -path "*/node_modules/*" 2>/dev/null | wc -l)
if [ "$TYPEORM_MIGRATIONS" -gt 0 ]; then
  echo "  [FOUND] TypeORM migrations: $TYPEORM_MIGRATIONS"
fi

# ── 6. REPRESENTATIVE FILES ──────────────────────────────────────
echo ""
echo "══════════════════════════════════════════"
echo "  REPRESENTATIVE FILES (1 per category)"
echo "══════════════════════════════════════════"

# Entry point
echo ""
echo "── ENTRY POINT ──"
for f in main.ts app.module.ts; do
  found=$(find "$SRC" -maxdepth 2 -name "$f" -not -path "*/node_modules/*" 2>/dev/null | head -1)
  if [ -n "$found" ]; then
    echo "  $found" | sed "s|$PROJECT_PATH/||"
  fi
done

# Modules
echo ""
echo "── MODULES (pick 1 to read) ──"
find "$SRC" -name "*.module.ts" -not -name "app.module.ts" -not -path "*/node_modules/*" -not -path "*/dist/*" -type f 2>/dev/null | head -10 | sed "s|$PROJECT_PATH/||"

# Controllers
echo ""
echo "── CONTROLLERS (pick 1 to read) ──"
find "$SRC" -name "*.controller.ts" -not -name "app.controller.ts" -not -path "*/node_modules/*" -not -path "*/dist/*" -not -name "*.spec.ts" -type f 2>/dev/null | head -10 | sed "s|$PROJECT_PATH/||"

# Services
echo ""
echo "── SERVICES (pick 1 to read) ──"
find "$SRC" -name "*.service.ts" -not -name "app.service.ts" -not -path "*/node_modules/*" -not -path "*/dist/*" -not -name "*.spec.ts" -type f 2>/dev/null | head -10 | sed "s|$PROJECT_PATH/||"

# Entities
echo ""
echo "── ENTITIES (pick 1 to read) ──"
find "$SRC" -name "*.entity.ts" -not -path "*/node_modules/*" -not -path "*/dist/*" -type f 2>/dev/null | head -10 | sed "s|$PROJECT_PATH/||"

# DTOs
echo ""
echo "── DTOS (pick 1 to read) ──"
find "$SRC" -name "*.dto.ts" -not -path "*/node_modules/*" -not -path "*/dist/*" -type f 2>/dev/null | head -10 | sed "s|$PROJECT_PATH/||"

# Guards
echo ""
echo "── GUARDS ──"
find "$SRC" -name "*.guard.ts" -not -path "*/node_modules/*" -not -path "*/dist/*" -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Interceptors
echo ""
echo "── INTERCEPTORS ──"
find "$SRC" -name "*.interceptor.ts" -not -path "*/node_modules/*" -not -path "*/dist/*" -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Pipes
echo ""
echo "── PIPES ──"
find "$SRC" -name "*.pipe.ts" -not -path "*/node_modules/*" -not -path "*/dist/*" -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Exception filters
echo ""
echo "── EXCEPTION FILTERS ──"
find "$SRC" -name "*.filter.ts" -not -path "*/node_modules/*" -not -path "*/dist/*" -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Custom decorators
echo ""
echo "── CUSTOM DECORATORS ──"
find "$SRC" -name "*.decorator.ts" -not -path "*/node_modules/*" -not -path "*/dist/*" -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Strategies (Passport)
echo ""
echo "── STRATEGIES ──"
find "$SRC" -name "*.strategy.ts" -not -path "*/node_modules/*" -not -path "*/dist/*" -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Gateways (WebSocket)
echo ""
echo "── GATEWAYS ──"
find "$SRC" -name "*.gateway.ts" -not -path "*/node_modules/*" -not -path "*/dist/*" -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Resolvers (GraphQL)
echo ""
echo "── RESOLVERS ──"
find "$SRC" -name "*.resolver.ts" -not -path "*/node_modules/*" -not -path "*/dist/*" -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Config files (app config)
echo ""
echo "── APP CONFIG ──"
find "$SRC" \( -name "*config*" -o -name "*Config*" -o -name "*.config.*" \) \
  -not -path "*/node_modules/*" -not -path "*/dist/*" -not -name "*.spec.ts" \
  -not -name "tsconfig*" -not -name "jest*" -not -name "eslint*" -not -name "nest-cli*" \
  -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Middleware
echo ""
echo "── MIDDLEWARE ──"
find "$SRC" \( -name "*.middleware.ts" -o -path "*/middleware/*" \) \
  -not -path "*/node_modules/*" -not -path "*/dist/*" -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Auth files
echo ""
echo "── AUTH FILES ──"
find "$SRC" -path "*auth*" -name "*.ts" -not -path "*/node_modules/*" -not -path "*/dist/*" \
  -not -name "*.spec.ts" -type f 2>/dev/null | head -10 | sed "s|$PROJECT_PATH/||"

# Database files
echo ""
echo "── DATABASE FILES ──"
find "$SRC" \( -name "*database*" -o -name "*db*" -o -name "*datasource*" -o -name "*typeorm*" -o -name "*prisma*" \) \
  -name "*.ts" -not -path "*/node_modules/*" -not -path "*/dist/*" -not -name "*.spec.ts" \
  -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Constants / enums
echo ""
echo "── CONSTANTS / ENUMS ──"
find "$SRC" \( -name "*constant*" -o -name "*enum*" -o -name "*Constants*" -o -name "*Enum*" \) \
  -not -path "*/node_modules/*" -not -path "*/dist/*" -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Shared / common module
echo ""
echo "── SHARED / COMMON ──"
find "$SRC" \( -path "*/common/*" -o -path "*/shared/*" -o -path "*/core/*" \) \
  -name "*.ts" -not -path "*/node_modules/*" -not -path "*/dist/*" -not -name "*.spec.ts" \
  -type f 2>/dev/null | head -10 | sed "s|$PROJECT_PATH/||"

# CQRS files
if check_dep "@nestjs/cqrs"; then
  echo ""
  echo "── CQRS FILES ──"
  find "$SRC" \( -name "*.command.ts" -o -name "*.query.ts" -o -name "*.event.ts" -o -name "*.handler.ts" -o -name "*.saga.ts" \) \
    -not -path "*/node_modules/*" -not -path "*/dist/*" -type f 2>/dev/null | head -10 | sed "s|$PROJECT_PATH/||"
fi

# Test files
echo ""
echo "── TEST FILES ──"
find "$SRC" -name "*.spec.ts" -not -path "*/node_modules/*" -not -path "*/dist/*" -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"
if [ -d "$PROJECT_PATH/test" ]; then
  echo "  [DIR] test/ (e2e)"
  find "$PROJECT_PATH/test" -type f -name "*.ts" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||" | sed 's/^/    /'
fi

# ── 7. MODULE SLICE EXAMPLE ─────────────────────────────────────
echo ""
echo "══════════════════════════════════════════"
echo "  MODULE SLICE EXAMPLE"
echo "══════════════════════════════════════════"
echo ""
echo "  Shows one complete NestJS module with all its files."
echo ""

SLICE_DIR=""
for dir in "$SRC"/*/; do
  if [ -d "$dir" ]; then
    DIRNAME=$(basename "$dir")
    # Skip common directories
    if [ "$DIRNAME" = "common" ] || [ "$DIRNAME" = "shared" ] || [ "$DIRNAME" = "core" ] || [ "$DIRNAME" = "config" ] || [ "$DIRNAME" = "database" ]; then
      continue
    fi
    MODULE_FILE=$(find "$dir" -maxdepth 1 -name "*.module.ts" 2>/dev/null | head -1)
    if [ -n "$MODULE_FILE" ]; then
      FILE_COUNT=$(find "$dir" -type f -name "*.ts" -not -path "*/node_modules/*" 2>/dev/null | wc -l)
      if [ "$FILE_COUNT" -ge 3 ]; then
        SLICE_DIR="${dir%/}"
        break
      fi
    fi
  fi
done

if [ -n "$SLICE_DIR" ]; then
  FILE_COUNT=$(find "$SLICE_DIR" -type f -name "*.ts" -not -path "*/node_modules/*" 2>/dev/null | wc -l)
  echo "── $(basename "$SLICE_DIR") ($FILE_COUNT TypeScript files) ──"
  find "$SLICE_DIR" -type f -name "*.ts" -not -path "*/node_modules/*" 2>/dev/null | sed "s|$PROJECT_PATH/||" | sort
else
  echo "  No feature module found with 3+ files."
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
  result=$(find "$search_path" \( "$@" \) -not -path "*/node_modules/*" -not -path "*/dist/*" -type f -print0 2>/dev/null | xargs -0 wc -l 2>/dev/null | grep -v " total$" | sort -rn | head -1)
  if [ -n "$result" ]; then
    local lines file
    lines=$(echo "$result" | awk '{print $1}')
    file=$(echo "$result" | sed 's/^[[:space:]]*[0-9]*//' | sed 's/^[[:space:]]*//' | sed "s|$PROJECT_PATH/||")
    echo "  $label: $file ($lines lines)"
  fi
}

show_largest "Module" "$SRC" -name "*.module.ts" -not -name "app.module.ts"
show_largest "Controller" "$SRC" -name "*.controller.ts" -not -name "*.spec.ts"
show_largest "Service" "$SRC" -name "*.service.ts" -not -name "*.spec.ts"
show_largest "Entity" "$SRC" -name "*.entity.ts"
show_largest "DTO" "$SRC" -name "*.dto.ts"
show_largest "Guard" "$SRC" -name "*.guard.ts"
show_largest "Interceptor" "$SRC" -name "*.interceptor.ts"
show_largest "Test" "$SRC" -name "*.spec.ts"
show_largest "Resolver" "$SRC" -name "*.resolver.ts"
show_largest "Gateway" "$SRC" -name "*.gateway.ts"

# ── 9. CODING STYLE SIGNALS ────────────────────────────────────
echo ""
echo "══════════════════════════════════════════"
echo "  CODING STYLE SIGNALS"
echo "══════════════════════════════════════════"

# Barrel exports
BARREL_COUNT=$(find "$SRC" -name "index.ts" -not -path "*/node_modules/*" -not -path "*/dist/*" 2>/dev/null | wc -l)
echo ""
echo "── BARREL EXPORTS ──"
echo "  index.ts files: $BARREL_COUNT"
if [ "$BARREL_COUNT" -gt 5 ]; then
  echo "  [HEAVY] Uses barrel exports extensively"
elif [ "$BARREL_COUNT" -gt 0 ]; then
  echo "  [LIGHT] Some barrel exports"
else
  echo "  [NONE] No barrel exports — direct imports"
fi

# Decorator usage density
echo ""
echo "── DECORATOR USAGE ──"
SWAGGER_DECORATORS=$(grep -rE "@Api(Tags|Operation|Response|Property|Body|Param|Query)" "$SRC" --include="*.ts" 2>/dev/null | grep -v "node_modules" | grep -v "dist/" | wc -l)
VALIDATION_DECORATORS=$(grep -rE "@Is(String|Number|Email|Not|Array|Boolean|Enum|Optional)|@Min|@Max|@Length" "$SRC" --include="*.ts" 2>/dev/null | grep -v "node_modules" | grep -v "dist/" | wc -l)
echo "  Swagger decorators:    $SWAGGER_DECORATORS"
echo "  Validation decorators: $VALIDATION_DECORATORS"

# Export style
echo ""
echo "── EXPORT STYLE ──"
DEFAULT_EXPORTS=$(grep -rE "export default" "$SRC" --include="*.ts" 2>/dev/null | grep -v "node_modules" | grep -v "dist/" | wc -l)
NAMED_EXPORTS=$(grep -rE "export (class|const|function|enum|interface|type|abstract)" "$SRC" --include="*.ts" 2>/dev/null | grep -v "node_modules" | grep -v "dist/" | wc -l)
echo "  export default: $DEFAULT_EXPORTS"
echo "  named exports:  $NAMED_EXPORTS"

# Async patterns
echo ""
echo "── ASYNC PATTERNS ──"
ASYNC_AWAIT=$(grep -r "async " "$SRC" --include="*.ts" 2>/dev/null | grep -v "node_modules" | grep -v "dist/" | wc -l)
OBSERVABLE=$(grep -rE "Observable|from\(|of\(|pipe\(" "$SRC" --include="*.ts" 2>/dev/null | grep -v "node_modules" | grep -v "dist/" | wc -l)
echo "  async/await:  $ASYNC_AWAIT"
echo "  Observable/RxJS: $OBSERVABLE"

# Interface vs Type
echo ""
echo "── TYPE DEFINITIONS ──"
INTERFACES=$(grep -rE "export interface " "$SRC" --include="*.ts" 2>/dev/null | grep -v "node_modules" | grep -v "dist/" | wc -l)
TYPE_ALIASES=$(grep -rE "export type " "$SRC" --include="*.ts" 2>/dev/null | grep -v "node_modules" | grep -v "dist/" | wc -l)
ENUMS=$(grep -rE "export enum " "$SRC" --include="*.ts" 2>/dev/null | grep -v "node_modules" | grep -v "dist/" | wc -l)
echo "  interface: $INTERFACES"
echo "  type:      $TYPE_ALIASES"
echo "  enum:      $ENUMS"

# Error handling
echo ""
echo "── ERROR HANDLING ──"
HTTP_EXCEPTION=$(grep -r "HttpException\|throw new " "$SRC" --include="*.ts" 2>/dev/null | grep -v "node_modules" | grep -v "dist/" | grep -v "spec.ts" | wc -l)
CUSTOM_EXCEPTIONS=$(grep -rE "class \w+(Exception|Error) extends" "$SRC" --include="*.ts" 2>/dev/null | grep -v "node_modules" | grep -v "dist/" | wc -l)
echo "  throw statements:      $HTTP_EXCEPTION"
echo "  Custom exception classes: $CUSTOM_EXCEPTIONS"

# Global setup (main.ts patterns)
echo ""
echo "── GLOBAL SETUP (main.ts) ──"
MAIN_FILE=$(find "$SRC" -maxdepth 2 -name "main.ts" -not -path "*/node_modules/*" 2>/dev/null | head -1)
if [ -n "$MAIN_FILE" ]; then
  grep -oE "useGlobal(Pipes|Filters|Interceptors|Guards)|enableCors|setGlobalPrefix|useStaticAssets|enableVersioning" "$MAIN_FILE" 2>/dev/null | sed 's/^/  /'
  if grep -q "SwaggerModule" "$MAIN_FILE" 2>/dev/null; then
    echo "  SwaggerModule (API docs enabled)"
  fi
  if grep -q "ValidationPipe" "$MAIN_FILE" 2>/dev/null; then
    echo "  ValidationPipe (global validation)"
  fi
fi

echo ""
echo "========================================="
echo "  SCAN COMPLETE"
echo "========================================="
echo ""
echo "  Next: Read 1-2 files per category above,"
echo "  following references/scan-checklist.md"
