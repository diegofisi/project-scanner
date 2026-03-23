#!/bin/bash
# Codebase Structure Scanner
# Usage: bash scan-structure.sh <project-path>
# Outputs: directory tree, dependencies, configs, and representative files per category.
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

SRC="$PROJECT_PATH/src"
if [ ! -d "$SRC" ]; then
  SRC="$PROJECT_PATH/app"  # Next.js app dir
  if [ ! -d "$SRC" ]; then
    SRC="$PROJECT_PATH"
  fi
fi

echo "========================================="
echo "  CODEBASE SCANNER"
echo "  Project: $PROJECT_PATH"
echo "========================================="

# ── PROJECT SIZE DETECTION ──────────────────────────────────────
TOTAL_FILES=$(find "$SRC" -type f -not -path "*/node_modules/*" -not -path "*/.next/*" -not -path "*/dist/*" -not -path "*/build/*" 2>/dev/null | wc -l)
echo ""
echo "── PROJECT SIZE ──"
echo "  PROJECT_SIZE: $TOTAL_FILES files"
if [ "$TOTAL_FILES" -gt 2000 ]; then
  echo "  LARGE_PROJECT: true"
  echo "  RECOMMENDATION: Use parallel extraction mode (subagents) for better coverage"
else
  echo "  LARGE_PROJECT: false"
fi

# ── 0. REPOMIX DETECTION ─────────────────────────────────────────────
echo ""
echo "── REPOMIX ──"
if command -v repomix &>/dev/null || npx --no repomix --version &>/dev/null; then
  echo "  [AVAILABLE] repomix detected"
  echo "  Run: npx repomix $PROJECT_PATH --output $PROJECT_PATH/repomix-output.txt"
else
  echo "  [NOT FOUND] repomix not available — skipping (install: npm i -g repomix)"
fi

# ── 1. FRAMEWORK DETECTION ──────────────────────────────────────────
echo ""
echo "── FRAMEWORK ──"
FRAMEWORK="unknown"
if grep -q '"next"' "$PROJECT_PATH/package.json" 2>/dev/null; then
  FRAMEWORK="next (react)"
elif grep -q '"nuxt"' "$PROJECT_PATH/package.json" 2>/dev/null; then
  FRAMEWORK="nuxt (vue)"
elif grep -q '"react"' "$PROJECT_PATH/package.json" 2>/dev/null; then
  FRAMEWORK="react"
elif grep -q '"vue"' "$PROJECT_PATH/package.json" 2>/dev/null; then
  FRAMEWORK="vue"
elif grep -q '"@angular/core"' "$PROJECT_PATH/package.json" 2>/dev/null; then
  FRAMEWORK="angular"
elif grep -q '"svelte"' "$PROJECT_PATH/package.json" 2>/dev/null; then
  FRAMEWORK="svelte"
fi
echo "  Detected: $FRAMEWORK"

# ── 1b. LANGUAGE DETECTION ───────────────────────────────────────────
echo ""
echo "── LANGUAGE ──"
if [ -f "$PROJECT_PATH/tsconfig.json" ]; then
  echo "  TypeScript"
else
  echo "  JavaScript"
fi

# ── 1c. PACKAGE MANAGER DETECTION ───────────────────────────────────
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

# ── 2. PACKAGE.JSON ─────────────────────────────────────────────────
echo ""
echo "── DEPENDENCIES ──"

# Cross-platform: try python3, then python, then fallback to grep
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

# ── 2b. STACK CLASSIFICATION ──────────────────────────────────────
echo ""
echo "── STACK SUMMARY ──"
PKG="$PROJECT_PATH/package.json"

check_dep() {
  grep -q "\"$1\"" "$PKG" 2>/dev/null
}

# UI Component Library
echo -n "  UI Library:       "
if [ -f "$PROJECT_PATH/components.json" ]; then echo "shadcn/ui"
elif check_dep "@mui/material"; then echo "MUI (Material UI)"
elif check_dep "antd"; then echo "Ant Design"
elif check_dep "@chakra-ui/react"; then echo "Chakra UI"
elif check_dep "@mantine/core"; then echo "Mantine"
elif check_dep "@radix-ui/react"; then echo "Radix UI (primitives)"
elif check_dep "@headlessui/react"; then echo "Headless UI"
elif check_dep "primereact"; then echo "PrimeReact"
else echo "none / custom"; fi

# State Management (client)
echo -n "  State (client):   "
if check_dep "zustand"; then echo "zustand"
elif check_dep "@reduxjs/toolkit"; then echo "Redux Toolkit"
elif check_dep "redux"; then echo "Redux"
elif check_dep "jotai"; then echo "jotai"
elif check_dep "recoil"; then echo "recoil"
elif check_dep "mobx"; then echo "MobX"
elif check_dep "valtio"; then echo "valtio"
elif check_dep "pinia"; then echo "Pinia (Vue)"
elif check_dep "vuex"; then echo "Vuex"
else echo "none / React Context"; fi

# State Management (server)
echo -n "  State (server):   "
if check_dep "@tanstack/react-query"; then echo "@tanstack/react-query"
elif check_dep "@tanstack/vue-query"; then echo "@tanstack/vue-query"
elif check_dep "react-query"; then echo "react-query (legacy)"
elif check_dep "swr"; then echo "SWR"
elif check_dep "@apollo/client"; then echo "Apollo Client"
elif check_dep "urql"; then echo "urql"
elif check_dep "@trpc/react-query"; then echo "tRPC + react-query"
else echo "none / manual"; fi

# Forms
echo -n "  Forms:            "
if check_dep "react-hook-form"; then echo "react-hook-form"
elif check_dep "formik"; then echo "Formik"
elif check_dep "@tanstack/react-form"; then echo "@tanstack/react-form"
elif check_dep "vee-validate"; then echo "VeeValidate (Vue)"
else echo "none / native"; fi

# Validation
echo -n "  Validation:       "
if check_dep "zod"; then echo "zod"
elif check_dep "yup"; then echo "yup"
elif check_dep "joi"; then echo "joi"
elif check_dep "superstruct"; then echo "superstruct"
elif check_dep "valibot"; then echo "valibot"
else echo "none"; fi

# HTTP Client
echo -n "  HTTP Client:      "
if check_dep "axios"; then echo "axios"
elif check_dep "ky"; then echo "ky"
elif check_dep "got"; then echo "got"
elif check_dep "graphql-request"; then echo "graphql-request"
else echo "fetch (native)"; fi

# Router
echo -n "  Router:           "
if check_dep "react-router-dom"; then echo "react-router-dom"
elif check_dep "@tanstack/react-router"; then echo "@tanstack/react-router"
elif check_dep "next"; then echo "Next.js (file-based)"
elif check_dep "nuxt"; then echo "Nuxt (file-based)"
elif check_dep "vue-router"; then echo "vue-router"
elif check_dep "@angular/router"; then echo "@angular/router"
else echo "none / custom"; fi

# CSS approach
echo -n "  CSS:              "
if check_dep "tailwindcss"; then echo "Tailwind CSS"
elif check_dep "styled-components"; then echo "styled-components"
elif check_dep "@emotion/react"; then echo "Emotion"
elif check_dep "sass"; then echo "Sass/SCSS"
elif check_dep "less"; then echo "Less"
else echo "vanilla CSS"; fi

# Toast/Notifications
echo -n "  Toasts:           "
if check_dep "sonner"; then echo "sonner"
elif check_dep "react-hot-toast"; then echo "react-hot-toast"
elif check_dep "react-toastify"; then echo "react-toastify"
elif check_dep "notistack"; then echo "notistack"
else echo "none / custom"; fi

# Date library
echo -n "  Dates:            "
if check_dep "date-fns"; then echo "date-fns"
elif check_dep "dayjs"; then echo "dayjs"
elif check_dep "luxon"; then echo "luxon"
elif check_dep "moment"; then echo "moment (legacy)"
else echo "none / native Date"; fi

# Icons
echo -n "  Icons:            "
if check_dep "lucide-react"; then echo "lucide-react"
elif check_dep "react-icons"; then echo "react-icons"
elif check_dep "@heroicons/react"; then echo "Heroicons"
elif check_dep "@phosphor-icons/react"; then echo "Phosphor Icons"
elif check_dep "@tabler/icons-react"; then echo "Tabler Icons"
else echo "none / custom"; fi

# Testing
echo -n "  Testing:          "
TESTING=""
check_dep "vitest" && TESTING="vitest"
check_dep "jest" && TESTING="${TESTING:+$TESTING + }jest"
check_dep "@testing-library/react" && TESTING="${TESTING:+$TESTING + }testing-library"
check_dep "cypress" && TESTING="${TESTING:+$TESTING + }cypress"
check_dep "@playwright/test" && TESTING="${TESTING:+$TESTING + }playwright"
check_dep "msw" && TESTING="${TESTING:+$TESTING + }msw"
echo "${TESTING:-none}"

# Animation
echo -n "  Animation:        "
if check_dep "framer-motion"; then echo "framer-motion"
elif check_dep "motion"; then echo "motion"
elif check_dep "react-spring"; then echo "react-spring"
elif check_dep "gsap"; then echo "gsap"
else echo "none"; fi

# ── 2c. API ARCHITECTURE ─────────────────────────────────────────
echo ""
echo "── API ARCHITECTURE ──"
if check_dep "@trpc/client" || check_dep "@trpc/react-query"; then
  echo "  [tRPC] End-to-end typesafe API"
elif check_dep "graphql" || check_dep "@apollo/client" || check_dep "urql" || check_dep "graphql-request"; then
  echo "  [GraphQL]"
  check_dep "@apollo/client" && echo "    Client: Apollo"
  check_dep "urql" && echo "    Client: urql"
  check_dep "graphql-request" && echo "    Client: graphql-request"
  if check_dep "graphql-codegen" || check_dep "@graphql-codegen/cli"; then echo "    Codegen: graphql-codegen"; fi
else
  echo "  [REST]"
fi

# ── 2d. PATH ALIASES ─────────────────────────────────────────────
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
elif [ -f "$PROJECT_PATH/jsconfig.json" ]; then
  echo "  (jsconfig.json — read manually for aliases)"
else
  echo "  No tsconfig.json or jsconfig.json found"
fi

# ── 3. DIRECTORY STRUCTURE ──────────────────────────────────────────
echo ""
echo "── DIRECTORY STRUCTURE ──"
find "$SRC" -maxdepth 5 -type d 2>/dev/null | sed "s|$PROJECT_PATH/||" | sort

# ── 4. FILE COUNTS ─────────────────────────────────────────────────
echo ""
echo "── FILE COUNTS ──"
find "$SRC" -type f 2>/dev/null | awk -F/ '{print $NF}' | grep '\.' | sed 's/.*\.//' | sort | uniq -c | sort -rn

# ── 5. CONFIG FILES ────────────────────────────────────────────────
echo ""
echo "── CONFIG FILES ──"
for config in vite.config.js vite.config.ts webpack.config.js next.config.js next.config.mjs next.config.ts \
              tsconfig.json jsconfig.json tailwind.config.js tailwind.config.ts \
              postcss.config.js postcss.config.cjs postcss.config.mjs \
              .eslintrc .eslintrc.js .eslintrc.cjs eslint.config.js eslint.config.mjs \
              .prettierrc .prettierrc.js .prettierrc.cjs biome.json \
              components.json \
              .env.example .env.local \
              Dockerfile docker-compose.yml docker-compose.yaml \
              vercel.json netlify.toml fly.toml \
              .github/workflows \
              turbo.json nx.json lerna.json pnpm-workspace.yaml \
              vitest.config.ts vitest.config.js jest.config.ts jest.config.js \
              cypress.config.ts playwright.config.ts \
              .env .env.development .env.production; do
  if [ -f "$PROJECT_PATH/$config" ] || [ -d "$PROJECT_PATH/$config" ]; then
    echo "  [FOUND] $config"
  fi
done

# ── 5b. MONOREPO DETECTION ───────────────────────────────────────
echo ""
echo "── MONOREPO ──"
if [ -f "$PROJECT_PATH/turbo.json" ] || [ -f "$PROJECT_PATH/nx.json" ] || [ -f "$PROJECT_PATH/lerna.json" ] || [ -f "$PROJECT_PATH/pnpm-workspace.yaml" ]; then
  echo "  [YES] Monorepo detected"
  [ -f "$PROJECT_PATH/turbo.json" ] && echo "    Tool: Turborepo"
  [ -f "$PROJECT_PATH/nx.json" ] && echo "    Tool: Nx"
  [ -f "$PROJECT_PATH/lerna.json" ] && echo "    Tool: Lerna"
  [ -f "$PROJECT_PATH/pnpm-workspace.yaml" ] && echo "    Tool: pnpm workspaces"
else
  echo "  [NO] Single package"
fi

# ── 6. REPRESENTATIVE FILES ────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════"
echo "  REPRESENTATIVE FILES (1 per category)"
echo "══════════════════════════════════════════"

# Entry points
echo ""
echo "── ENTRY POINTS ──"
for f in main.tsx main.ts main.jsx main.js index.tsx index.ts App.tsx App.vue App.svelte; do
  found=$(find "$SRC" -maxdepth 1 -name "$f" 2>/dev/null | head -1)
  if [ -n "$found" ]; then
    echo "  $found" | sed "s|$PROJECT_PATH/||"
  fi
done

# Global CSS
echo ""
echo "── GLOBAL STYLES ──"
find "$SRC" -maxdepth 2 \( -name "index.css" -o -name "globals.css" -o -name "global.css" -o -name "app.css" \) -type f 2>/dev/null | head -1 | sed "s|$PROJECT_PATH/||"

# Store files (client state)
echo ""
echo "── STORES (pick 1 to read) ──"
find "$SRC" \( -name "*store*" -o -name "*Store*" \) -not -path "*/node_modules/*" -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# API hooks - queries
echo ""
echo "── QUERY HOOKS (pick 1 to read) ──"
find "$SRC" -name "useGet*" -not -path "*/node_modules/*" -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# API hooks - mutations
echo ""
echo "── MUTATION HOOKS (pick 1 to read) ──"
find "$SRC" \( -name "useCreate*" -o -name "useUpdate*" -o -name "useDelete*" -o -name "usePost*" \) -not -path "*/node_modules/*" -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# DTO files
echo ""
echo "── DTO FILES (pick 1 to read) ──"
find "$SRC" -name "*.dto.*" -not -path "*/node_modules/*" -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Model files
echo ""
echo "── MODEL FILES (pick 1 to read) ──"
find "$SRC" -name "*.model.*" -not -path "*/node_modules/*" -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Schema files
echo ""
echo "── SCHEMA FILES (pick 1 to read) ──"
find "$SRC" -name "*.schema.*" -not -path "*/node_modules/*" -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Container components
echo ""
echo "── CONTAINERS (pick 1 to read) ──"
find "$SRC" -name "*Container*" -not -path "*/node_modules/*" -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Dialog/Modal components
echo ""
echo "── DIALOGS/MODALS (pick 1 to read) ──"
find "$SRC" \( -name "*Dialog*" -o -name "*Modal*" \) -not -path "*/node_modules/*" -not -path "*/ui/*" -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Page components
echo ""
echo "── PAGES (pick 1 to read) ──"
find "$SRC" -name "*Page*" -not -path "*/node_modules/*" -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Custom hooks (non-API)
echo ""
echo "── CUSTOM HOOKS (pick 1 to read) ──"
find "$SRC" -name "use*" -not -name "useGet*" -not -name "useCreate*" -not -name "useUpdate*" -not -name "useDelete*" -not -path "*/node_modules/*" -not -path "*/api/*" -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Router files
echo ""
echo "── ROUTER FILES ──"
find "$SRC" \( -name "*router*" -o -name "*Router*" -o -name "*route*" -o -name "*Route*" \) -not -path "*/node_modules/*" -type f 2>/dev/null | head -10 | sed "s|$PROJECT_PATH/||"

# Layout components
echo ""
echo "── LAYOUT COMPONENTS ──"
find "$SRC" -path "*/layout/*" -type f -not -path "*/node_modules/*" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Typography / UI primitives
echo ""
echo "── UI PRIMITIVES ──"
find "$SRC" -path "*/ui/*" -type f -not -path "*/node_modules/*" 2>/dev/null | head -10 | sed "s|$PROJECT_PATH/||"

# HTTP client / lib
echo ""
echo "── LIB/UTILS ──"
find "$SRC" -path "*/lib/*" -type f -not -path "*/node_modules/*" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Auth files
echo ""
echo "── AUTH FILES ──"
find "$SRC" -path "*auth*" -type f -not -path "*/node_modules/*" 2>/dev/null | head -10 | sed "s|$PROJECT_PATH/||"

# Route guards
echo ""
echo "── ROUTE GUARDS ──"
find "$SRC" \( -name "*Guard*" -o -name "*guard*" -o -name "*ProtectedRoute*" -o -name "*PrivateRoute*" -o -name "*AuthRoute*" \) -not -path "*/node_modules/*" -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# HOCs / Wrappers
echo ""
echo "── HOCS / WRAPPERS ──"
find "$SRC" \( -name "with*" -o -name "With*" -o -name "*Wrapper*" -o -name "*wrapper*" -o -name "*HOC*" -o -name "*hoc*" \) -not -path "*/node_modules/*" -not -path "*/ui/*" -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Helpers
echo ""
echo "── HELPER FILES ──"
find "$SRC" -path "*/helpers/*" -type f -not -path "*/node_modules/*" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Types
echo ""
echo "── TYPE FILES ──"
find "$SRC" -path "*/types/*" -type f -not -path "*/node_modules/*" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Contexts / Providers
echo ""
echo "── CONTEXTS / PROVIDERS ──"
find "$SRC" \( -name "*Context*" -o -name "*Provider*" -o -name "*context*" -o -name "*provider*" \) -not -path "*/node_modules/*" -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Error boundaries / Fallbacks
echo ""
echo "── ERROR HANDLING ──"
find "$SRC" \( -name "*Error*" -o -name "*Fallback*" -o -name "*error-boundary*" -o -name "*ErrorBoundary*" \) -not -path "*/node_modules/*" -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Constants / Enums
echo ""
echo "── CONSTANTS / ENUMS ──"
find "$SRC" \( -name "*constant*" -o -name "*enum*" -o -name "*Constants*" -o -name "*Enum*" \) -not -path "*/node_modules/*" -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# API client setup
echo ""
echo "── API CLIENT ──"
find "$SRC" \( -name "*http*" -o -name "*axios*" -o -name "*api-client*" -o -name "*fetcher*" -o -name "*httpClient*" \) -not -path "*/node_modules/*" -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Test files
echo ""
echo "── TEST FILES ──"
find "$SRC" \( -name "*.test.*" -o -name "*.spec.*" \) -not -path "*/node_modules/*" -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"
if [ -d "$PROJECT_PATH/__tests__" ]; then
  echo "  [DIR] __tests__/"
fi
if [ -d "$PROJECT_PATH/cypress" ]; then
  echo "  [DIR] cypress/"
fi
if [ -d "$PROJECT_PATH/e2e" ] || [ -d "$PROJECT_PATH/tests" ]; then
  echo "  [DIR] e2e/ or tests/"
fi

# i18n
echo ""
echo "── I18N / LOCALES ──"
find "$PROJECT_PATH" \( -name "i18n*" -o -path "*/locales/*" -o -path "*/translations/*" -o -name "*.locale.*" \) -not -path "*/node_modules/*" -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Composables (Vue)
if [ "$FRAMEWORK" = "vue" ] || [ "$FRAMEWORK" = "nuxt (vue)" ]; then
  echo ""
  echo "── COMPOSABLES (Vue) ──"
  find "$SRC" \( -name "use*" -path "*/composables/*" \) -not -path "*/node_modules/*" -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"
fi

# Services (Angular)
if [ "$FRAMEWORK" = "angular" ]; then
  echo ""
  echo "── SERVICES (Angular) ──"
  find "$SRC" -name "*.service.ts" -not -path "*/node_modules/*" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"
fi

# ── 7. FEATURE SLICE EXAMPLE ──────────────────────────────────────
echo ""
echo "══════════════════════════════════════════"
echo "  FEATURE SLICE EXAMPLE"
echo "══════════════════════════════════════════"
echo ""
echo "  Shows one complete feature with all its files."
echo "  Pick the first feature directory under core/ or features/ that has 5+ files."
echo ""

SLICE_DIR=""
for base_dir in "$SRC/core" "$SRC/features" "$SRC/modules" "$SRC/pages" "$SRC/views"; do
  if [ -d "$base_dir" ]; then
    SLICE_DIR=$(find "$base_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | while read -r dir; do
      count=$(find "$dir" -type f 2>/dev/null | wc -l)
      echo "$count $dir"
    done | sort -rn | head -1 | sed 's/^[[:space:]]*[0-9]*[[:space:]]*//')
    [ -n "$SLICE_DIR" ] && break
  fi
done

if [ -n "$SLICE_DIR" ]; then
  echo "── $(basename "$SLICE_DIR") ($(find "$SLICE_DIR" -type f 2>/dev/null | wc -l) files) ──"
  find "$SLICE_DIR" -type f 2>/dev/null | sed "s|$PROJECT_PATH/||" | sort
else
  echo "  No feature directory found with nested structure."
fi

# ── 8. SMART SAMPLING — LARGEST FILES PER CATEGORY ──────────────
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
  result=$(find "$search_path" \( "$@" \) -not -path "*/node_modules/*" -type f -print0 2>/dev/null | xargs -0 wc -l 2>/dev/null | grep -v " total$" | sort -rn | head -1)
  if [ -n "$result" ]; then
    local lines file
    lines=$(echo "$result" | awk '{print $1}')
    file=$(echo "$result" | sed 's/^[[:space:]]*[0-9]*//' | sed 's/^[[:space:]]*//' | sed "s|$PROJECT_PATH/||")
    echo "  $label: $file ($lines lines)"
  fi
}

show_largest "Component" "$SRC" -name "*.tsx" -not -name "*.test.*" -not -name "*.spec.*" -not -path "*/ui/*"
show_largest "Hook" "$SRC" -name "use*.ts" -not -name "*.test.*" -not -name "*.spec.*"
show_largest "Page" "$SRC" -name "*Page*" -o -name "*page*" -o -name "*View*"
show_largest "Store" "$SRC" -name "*store*" -o -name "*Store*"
show_largest "Schema" "$SRC" -name "*.schema.*"
show_largest "DTO" "$SRC" -name "*.dto.*"
show_largest "Test" "$SRC" -name "*.test.*" -o -name "*.spec.*"
show_largest "Guard" "$SRC" -name "*Guard*" -o -name "*guard*" -o -name "*ProtectedRoute*"
show_largest "Container" "$SRC" -name "*Container*"

# ── 9. CODING STYLE SIGNALS ──────────────────────────────────────
echo ""
echo "══════════════════════════════════════════"
echo "  CODING STYLE SIGNALS"
echo "══════════════════════════════════════════"

# Barrel exports (index.ts usage)
BARREL_COUNT=$(find "$SRC" \( -name "index.ts" -o -name "index.tsx" -o -name "index.js" -o -name "index.jsx" \) -not -path "*/node_modules/*" 2>/dev/null | wc -l)
echo ""
echo "── BARREL EXPORTS ──"
echo "  index.ts/tsx files: $BARREL_COUNT"
if [ "$BARREL_COUNT" -gt 5 ]; then
  echo "  [HEAVY] Uses barrel exports extensively"
elif [ "$BARREL_COUNT" -gt 0 ]; then
  echo "  [LIGHT] Some barrel exports"
else
  echo "  [NONE] No barrel exports — direct imports"
fi

# Export style (default vs named)
echo ""
echo "── EXPORT STYLE ──"
DEFAULT_EXPORTS=$(grep -r "export default" "$SRC" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" 2>/dev/null | wc -l)
NAMED_EXPORTS=$(grep -rE "export const|export function|export type|export interface" "$SRC" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" 2>/dev/null | wc -l)
echo "  export default: $DEFAULT_EXPORTS"
echo "  named exports:  $NAMED_EXPORTS"

# Component declaration style
echo ""
echo "── COMPONENT STYLE ──"
ARROW_COMPS=$(grep -r "export const.*=.*(" "$SRC" --include="*.tsx" --include="*.jsx" 2>/dev/null | wc -l)
FUNC_COMPS=$(grep -r "export function " "$SRC" --include="*.tsx" --include="*.jsx" 2>/dev/null | wc -l)
echo "  Arrow (const X = () =>): $ARROW_COMPS"
echo "  Function declaration:    $FUNC_COMPS"

# Interface vs Type
echo ""
echo "── TYPE DEFINITIONS ──"
INTERFACES=$(grep -rE "export interface |interface " "$SRC" --include="*.ts" --include="*.tsx" 2>/dev/null | wc -l)
TYPE_ALIASES=$(grep -rE "export type |type " "$SRC" --include="*.ts" --include="*.tsx" 2>/dev/null | wc -l)
echo "  interface: $INTERFACES"
echo "  type:      $TYPE_ALIASES"

echo ""
echo "========================================="
echo "  SCAN COMPLETE"
echo "========================================="
echo ""
echo "  Next: Read 1-2 files per category above,"
echo "  following references/scan-checklist.md"
