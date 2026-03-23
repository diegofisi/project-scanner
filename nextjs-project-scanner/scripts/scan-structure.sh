#!/bin/bash
# Next.js Codebase Structure Scanner
# Usage: bash scan-structure.sh <project-path>
# Outputs: directory tree, dependencies, configs, routing strategy, server/client components,
#          API routes, middleware, and representative files per category.
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

# Determine source root
SRC="$PROJECT_PATH/src"
APP_DIR=""
PAGES_DIR=""

# Detect app/ directory (App Router)
if [ -d "$PROJECT_PATH/src/app" ]; then
  APP_DIR="$PROJECT_PATH/src/app"
elif [ -d "$PROJECT_PATH/app" ]; then
  APP_DIR="$PROJECT_PATH/app"
fi

# Detect pages/ directory (Pages Router)
if [ -d "$PROJECT_PATH/src/pages" ]; then
  PAGES_DIR="$PROJECT_PATH/src/pages"
elif [ -d "$PROJECT_PATH/pages" ]; then
  PAGES_DIR="$PROJECT_PATH/pages"
fi

# Fallback SRC
if [ ! -d "$SRC" ]; then
  SRC="$PROJECT_PATH"
fi

echo "========================================="
echo "  NEXT.JS CODEBASE SCANNER"
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

# -- 0. REPOMIX DETECTION -----------------------------------------------
echo ""
echo "-- REPOMIX --"
if command -v repomix &>/dev/null || npx --no repomix --version &>/dev/null; then
  echo "  [AVAILABLE] repomix detected"
  echo "  Run: npx repomix $PROJECT_PATH --output $PROJECT_PATH/repomix-output.txt"
else
  echo "  [NOT FOUND] repomix not available -- skipping (install: npm i -g repomix)"
fi

# -- 1. NEXT.JS VERSION & FRAMEWORK DETECTION ---------------------------
echo ""
echo "-- NEXT.JS VERSION --"

# Cross-platform: try python3, then python, then fallback to grep
if command -v python3 &>/dev/null; then
  PYTHON_CMD="python3"
elif command -v python &>/dev/null; then
  PYTHON_CMD="python"
else
  PYTHON_CMD=""
fi

NEXT_VERSION="unknown"
if [ -n "$PYTHON_CMD" ]; then
  NEXT_VERSION=$(PROJECT_PATH="$PROJECT_PATH" $PYTHON_CMD -c "
import json, os
d = json.load(open(os.path.join(os.environ['PROJECT_PATH'], 'package.json')))
deps = {**d.get('dependencies',{}), **d.get('devDependencies',{})}
v = deps.get('next', 'not found')
print(v)
" 2>/dev/null)
else
  NEXT_VERSION=$(grep -o '"next"[[:space:]]*:[[:space:]]*"[^"]*"' "$PROJECT_PATH/package.json" 2>/dev/null | grep -o '[0-9][^"]*')
fi
echo "  next: $NEXT_VERSION"

# Detect React version
REACT_VERSION="unknown"
if [ -n "$PYTHON_CMD" ]; then
  REACT_VERSION=$(PROJECT_PATH="$PROJECT_PATH" $PYTHON_CMD -c "
import json, os
d = json.load(open(os.path.join(os.environ['PROJECT_PATH'], 'package.json')))
deps = {**d.get('dependencies',{}), **d.get('devDependencies',{})}
print(deps.get('react', 'not found'))
" 2>/dev/null)
fi
echo "  react: $REACT_VERSION"

# -- 1b. ROUTING STRATEGY DETECTION -------------------------------------
echo ""
echo "-- ROUTING STRATEGY --"
ROUTING="unknown"
if [ -n "$APP_DIR" ] && [ -n "$PAGES_DIR" ]; then
  ROUTING="hybrid"
  echo "  [HYBRID] Both App Router and Pages Router detected"
  echo "    App Router:   $APP_DIR"
  echo "    Pages Router: $PAGES_DIR"
elif [ -n "$APP_DIR" ]; then
  ROUTING="app"
  echo "  [APP ROUTER] app/ directory detected at $APP_DIR"
elif [ -n "$PAGES_DIR" ]; then
  ROUTING="pages"
  echo "  [PAGES ROUTER] pages/ directory detected at $PAGES_DIR"
else
  echo "  [UNKNOWN] No app/ or pages/ directory found"
fi

# -- 1c. LANGUAGE DETECTION ---------------------------------------------
echo ""
echo "-- LANGUAGE --"
if [ -f "$PROJECT_PATH/tsconfig.json" ]; then
  echo "  TypeScript"
else
  echo "  JavaScript"
fi

# -- 1d. PACKAGE MANAGER DETECTION --------------------------------------
echo ""
echo "-- PACKAGE MANAGER --"
if [ -f "$PROJECT_PATH/pnpm-lock.yaml" ]; then
  echo "  pnpm"
elif [ -f "$PROJECT_PATH/yarn.lock" ]; then
  echo "  yarn"
elif [ -f "$PROJECT_PATH/bun.lockb" ] || [ -f "$PROJECT_PATH/bun.lock" ]; then
  echo "  bun"
elif [ -f "$PROJECT_PATH/package-lock.json" ]; then
  echo "  npm"
else
  echo "  unknown"
fi

# -- 2. PACKAGE.JSON ----------------------------------------------------
echo ""
echo "-- DEPENDENCIES --"
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
  echo "  (python not found -- showing raw package.json)"
  cat "$PROJECT_PATH/package.json"
fi

# -- 2b. STACK CLASSIFICATION -------------------------------------------
echo ""
echo "-- STACK SUMMARY --"
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
elif check_dep "@nextui-org/react"; then echo "NextUI"
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
else echo "none / React Context"; fi

# State Management (server)
echo -n "  State (server):   "
if check_dep "@tanstack/react-query"; then echo "@tanstack/react-query"
elif check_dep "react-query"; then echo "react-query (legacy)"
elif check_dep "swr"; then echo "SWR"
elif check_dep "@apollo/client"; then echo "Apollo Client"
elif check_dep "urql"; then echo "urql"
elif check_dep "@trpc/react-query"; then echo "tRPC + react-query"
else echo "none / Server Components"; fi

# Forms
echo -n "  Forms:            "
if check_dep "react-hook-form"; then echo "react-hook-form"
elif check_dep "formik"; then echo "Formik"
elif check_dep "@tanstack/react-form"; then echo "@tanstack/react-form"
else echo "none / native / server actions"; fi

# Validation
echo -n "  Validation:       "
if check_dep "zod"; then echo "zod"
elif check_dep "yup"; then echo "yup"
elif check_dep "joi"; then echo "joi"
elif check_dep "valibot"; then echo "valibot"
elif check_dep "superstruct"; then echo "superstruct"
else echo "none"; fi

# HTTP Client
echo -n "  HTTP Client:      "
if check_dep "axios"; then echo "axios"
elif check_dep "ky"; then echo "ky"
elif check_dep "got"; then echo "got"
elif check_dep "graphql-request"; then echo "graphql-request"
else echo "fetch (native)"; fi

# CSS approach
echo -n "  CSS:              "
if check_dep "tailwindcss"; then echo "Tailwind CSS"
elif check_dep "styled-components"; then echo "styled-components"
elif check_dep "@emotion/react"; then echo "Emotion"
elif check_dep "sass"; then echo "Sass/SCSS"
elif check_dep "less"; then echo "Less"
elif check_dep "@vanilla-extract/css"; then echo "vanilla-extract"
else echo "vanilla CSS / CSS Modules"; fi

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

# -- 2c. NEXT.JS-SPECIFIC STACK -----------------------------------------
echo ""
echo "-- NEXT.JS STACK --"

# Auth
echo -n "  Auth:             "
if check_dep "next-auth" || check_dep "@auth/nextjs"; then echo "NextAuth.js / Auth.js"
elif check_dep "@clerk/nextjs"; then echo "Clerk"
elif check_dep "@supabase/auth-helpers-nextjs" || check_dep "@supabase/ssr"; then echo "Supabase Auth"
elif check_dep "@kinde-oss/kinde-auth-nextjs"; then echo "Kinde"
elif check_dep "lucia"; then echo "Lucia"
elif check_dep "@auth0/nextjs-auth0"; then echo "Auth0"
else echo "none / custom"; fi

# ORM / Database
echo -n "  ORM:              "
if check_dep "@prisma/client" || check_dep "prisma"; then echo "Prisma"
elif check_dep "drizzle-orm"; then echo "Drizzle"
elif check_dep "kysely"; then echo "Kysely"
elif check_dep "typeorm"; then echo "TypeORM"
elif check_dep "sequelize"; then echo "Sequelize"
elif check_dep "mongoose"; then echo "Mongoose"
else echo "none"; fi

# Database (direct indicators)
echo -n "  Database:         "
if [ -f "$PROJECT_PATH/prisma/schema.prisma" ]; then echo "PostgreSQL/MySQL/SQLite (via Prisma schema)"
elif check_dep "@supabase/supabase-js"; then echo "Supabase (PostgreSQL)"
elif check_dep "@planetscale/database"; then echo "PlanetScale (MySQL)"
elif check_dep "@vercel/postgres"; then echo "Vercel Postgres"
elif check_dep "@vercel/kv"; then echo "Vercel KV (Redis)"
elif check_dep "@upstash/redis"; then echo "Upstash Redis"
elif check_dep "mongodb" || check_dep "mongoose"; then echo "MongoDB"
elif check_dep "better-sqlite3"; then echo "SQLite"
else echo "unknown / external API"; fi

# CMS
echo -n "  CMS:              "
if check_dep "contentlayer" || check_dep "contentlayer2"; then echo "Contentlayer"
elif check_dep "next-mdx-remote" || check_dep "@next/mdx"; then echo "MDX"
elif check_dep "@sanity/client" || check_dep "next-sanity"; then echo "Sanity"
elif check_dep "contentful"; then echo "Contentful"
elif check_dep "@notionhq/client"; then echo "Notion"
elif check_dep "strapi"; then echo "Strapi"
else echo "none"; fi

# Analytics & Monitoring
echo -n "  Analytics:        "
ANALYTICS=""
check_dep "@vercel/analytics" && ANALYTICS="Vercel Analytics"
check_dep "@vercel/speed-insights" && ANALYTICS="${ANALYTICS:+$ANALYTICS + }Speed Insights"
check_dep "@sentry/nextjs" && ANALYTICS="${ANALYTICS:+$ANALYTICS + }Sentry"
check_dep "posthog-js" && ANALYTICS="${ANALYTICS:+$ANALYTICS + }PostHog"
echo "${ANALYTICS:-none}"

# Email
echo -n "  Email:            "
if check_dep "resend"; then echo "Resend"
elif check_dep "@sendgrid/mail"; then echo "SendGrid"
elif check_dep "nodemailer"; then echo "Nodemailer"
elif check_dep "react-email"; then echo "React Email"
else echo "none"; fi

# File uploads
echo -n "  Uploads:          "
if check_dep "uploadthing" || check_dep "@uploadthing/react"; then echo "UploadThing"
elif check_dep "@vercel/blob"; then echo "Vercel Blob"
elif check_dep "@aws-sdk/client-s3"; then echo "AWS S3"
else echo "none"; fi

# -- 2d. API ARCHITECTURE -----------------------------------------------
echo ""
echo "-- API ARCHITECTURE --"
if check_dep "@trpc/client" || check_dep "@trpc/react-query" || check_dep "@trpc/server"; then
  echo "  [tRPC] End-to-end typesafe API"
elif check_dep "graphql" || check_dep "@apollo/client" || check_dep "urql" || check_dep "graphql-request"; then
  echo "  [GraphQL]"
  check_dep "@apollo/client" && echo "    Client: Apollo"
  check_dep "urql" && echo "    Client: urql"
  check_dep "graphql-request" && echo "    Client: graphql-request"
elif [ -n "$APP_DIR" ]; then
  API_ROUTES=$(find "$APP_DIR" \( -name "route.ts" -o -name "route.js" \) 2>/dev/null | wc -l)
  if [ "$API_ROUTES" -gt 0 ]; then
    echo "  [REST - Route Handlers] $API_ROUTES route handler(s) found"
  else
    echo "  [Server Components + Server Actions] No API routes -- direct server-side data access"
  fi
elif [ -n "$PAGES_DIR" ] && [ -d "$PAGES_DIR/api" ]; then
  API_FILES=$(find "$PAGES_DIR/api" -type f \( -name "*.ts" -o -name "*.js" \) 2>/dev/null | wc -l)
  echo "  [REST - API Routes] $API_FILES API route(s) in pages/api/"
else
  echo "  [Unknown]"
fi

# -- 2e. DEPLOYMENT TARGET -----------------------------------------------
echo ""
echo "-- DEPLOYMENT TARGET --"
if [ -f "$PROJECT_PATH/vercel.json" ]; then echo "  Vercel (vercel.json found)"
elif [ -f "$PROJECT_PATH/netlify.toml" ]; then echo "  Netlify (netlify.toml found)"
elif [ -f "$PROJECT_PATH/Dockerfile" ]; then echo "  Docker (Dockerfile found)"
elif [ -f "$PROJECT_PATH/fly.toml" ]; then echo "  Fly.io (fly.toml found)"
elif [ -f "$PROJECT_PATH/render.yaml" ]; then echo "  Render (render.yaml found)"
else echo "  Unknown (defaulting to Vercel)"; fi

# -- 2f. PATH ALIASES ---------------------------------------------------
echo ""
echo "-- PATH ALIASES --"
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

# -- 3. DIRECTORY STRUCTURE ----------------------------------------------
echo ""
echo "-- DIRECTORY STRUCTURE --"
if [ -d "$SRC" ] && [ "$SRC" != "$PROJECT_PATH" ]; then
  find "$SRC" -maxdepth 6 -type d 2>/dev/null | sed "s|$PROJECT_PATH/||" | sort
else
  # Show top-level + app/ and pages/ trees
  find "$PROJECT_PATH" -maxdepth 6 -type d \
    -not -path "*/node_modules/*" \
    -not -path "*/.next/*" \
    -not -path "*/.git/*" \
    2>/dev/null | sed "s|$PROJECT_PATH/||" | sort
fi

# -- 4. FILE COUNTS ------------------------------------------------------
echo ""
echo "-- FILE COUNTS --"
SEARCH_DIR="$SRC"
[ -n "$APP_DIR" ] && [ "$SRC" = "$PROJECT_PATH" ] && SEARCH_DIR="$APP_DIR"
find "$SEARCH_DIR" -type f -not -path "*/node_modules/*" -not -path "*/.next/*" 2>/dev/null | awk -F/ '{print $NF}' | grep '\.' | sed 's/.*\.//' | sort | uniq -c | sort -rn

# -- 5. CONFIG FILES -----------------------------------------------------
echo ""
echo "-- CONFIG FILES --"
for config in next.config.js next.config.mjs next.config.ts \
              tsconfig.json tailwind.config.js tailwind.config.ts tailwind.config.mjs \
              postcss.config.js postcss.config.cjs postcss.config.mjs \
              .eslintrc .eslintrc.js .eslintrc.cjs eslint.config.js eslint.config.mjs \
              .prettierrc .prettierrc.js .prettierrc.cjs biome.json \
              components.json \
              middleware.ts middleware.js \
              .env.example .env.local .env .env.development .env.production \
              prisma/schema.prisma drizzle.config.ts drizzle.config.js \
              Dockerfile docker-compose.yml docker-compose.yaml \
              vercel.json netlify.toml fly.toml \
              .github/workflows \
              turbo.json nx.json pnpm-workspace.yaml \
              vitest.config.ts vitest.config.js jest.config.ts jest.config.js \
              cypress.config.ts playwright.config.ts \
              next-env.d.ts \
              instrumentation.ts instrumentation.js; do
  if [ -f "$PROJECT_PATH/$config" ] || [ -d "$PROJECT_PATH/$config" ]; then
    echo "  [FOUND] $config"
  fi
done

# -- 5b. MONOREPO DETECTION ---------------------------------------------
echo ""
echo "-- MONOREPO --"
if [ -f "$PROJECT_PATH/turbo.json" ] || [ -f "$PROJECT_PATH/nx.json" ] || [ -f "$PROJECT_PATH/lerna.json" ] || [ -f "$PROJECT_PATH/pnpm-workspace.yaml" ]; then
  echo "  [YES] Monorepo detected"
  [ -f "$PROJECT_PATH/turbo.json" ] && echo "    Tool: Turborepo"
  [ -f "$PROJECT_PATH/nx.json" ] && echo "    Tool: Nx"
  [ -f "$PROJECT_PATH/pnpm-workspace.yaml" ] && echo "    Tool: pnpm workspaces"
else
  echo "  [NO] Single package"
fi

# -- 6. APP ROUTER ANALYSIS (if present) ---------------------------------
if [ -n "$APP_DIR" ]; then
  echo ""
  echo "=========================================="
  echo "  APP ROUTER ANALYSIS"
  echo "=========================================="

  # Route segments
  echo ""
  echo "-- ROUTE SEGMENTS --"
  echo "  Pages (page.tsx/jsx/js/ts):"
  find "$APP_DIR" \( -name "page.tsx" -o -name "page.jsx" -o -name "page.ts" -o -name "page.js" \) 2>/dev/null | sed "s|$PROJECT_PATH/||" | sort

  echo ""
  echo "  Layouts (layout.tsx/jsx/js/ts):"
  find "$APP_DIR" \( -name "layout.tsx" -o -name "layout.jsx" -o -name "layout.ts" -o -name "layout.js" \) 2>/dev/null | sed "s|$PROJECT_PATH/||" | sort

  echo ""
  echo "  Loading states (loading.tsx):"
  find "$APP_DIR" \( -name "loading.tsx" -o -name "loading.jsx" -o -name "loading.js" \) 2>/dev/null | sed "s|$PROJECT_PATH/||" | sort

  echo ""
  echo "  Error boundaries (error.tsx):"
  find "$APP_DIR" \( -name "error.tsx" -o -name "error.jsx" -o -name "error.js" \) 2>/dev/null | sed "s|$PROJECT_PATH/||" | sort

  echo ""
  echo "  Not found (not-found.tsx):"
  find "$APP_DIR" \( -name "not-found.tsx" -o -name "not-found.jsx" -o -name "not-found.js" \) 2>/dev/null | sed "s|$PROJECT_PATH/||" | sort

  echo ""
  echo "  Templates (template.tsx):"
  find "$APP_DIR" \( -name "template.tsx" -o -name "template.jsx" -o -name "template.js" \) 2>/dev/null | sed "s|$PROJECT_PATH/||" | sort

  echo ""
  echo "  Default (default.tsx -- parallel routes):"
  find "$APP_DIR" \( -name "default.tsx" -o -name "default.jsx" -o -name "default.js" \) 2>/dev/null | sed "s|$PROJECT_PATH/||" | sort

  # Route groups
  echo ""
  echo "-- ROUTE GROUPS (parenthesized directories) --"
  find "$APP_DIR" -type d 2>/dev/null | grep '(' | sed "s|$PROJECT_PATH/||" | sort

  # Dynamic routes
  echo ""
  echo "-- DYNAMIC ROUTES --"
  echo "  [param] segments:"
  find "$APP_DIR" -type d -name "\[*\]" 2>/dev/null | grep -v '\.\.\.' | sed "s|$PROJECT_PATH/||" | sort
  echo "  [...catchAll] segments:"
  find "$APP_DIR" -type d -name "\[...*\]" 2>/dev/null | sed "s|$PROJECT_PATH/||" | sort
  echo "  [[...optionalCatchAll]] segments:"
  find "$APP_DIR" -type d -name "\[\[...*\]\]" 2>/dev/null | sed "s|$PROJECT_PATH/||" | sort

  # Parallel routes
  echo ""
  echo "-- PARALLEL ROUTES (@slot directories) --"
  find "$APP_DIR" -type d -name "@*" 2>/dev/null | sed "s|$PROJECT_PATH/||" | sort

  # Intercepting routes
  echo ""
  echo "-- INTERCEPTING ROUTES --"
  find "$APP_DIR" -type d 2>/dev/null | grep -E '\(\.\)|\(\.\.\)|\(\.\.\.\)' | sed "s|$PROJECT_PATH/||" | sort

  # API Route Handlers
  echo ""
  echo "-- API ROUTE HANDLERS --"
  find "$APP_DIR" \( -name "route.ts" -o -name "route.js" \) 2>/dev/null | sed "s|$PROJECT_PATH/||" | sort

  # Server Actions files
  echo ""
  echo "-- SERVER ACTIONS --"
  echo "  Files with 'use server':"
  grep -rlE "'use server'|\"use server\"" "$APP_DIR" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" 2>/dev/null | sed "s|$PROJECT_PATH/||" | sort
  # Also check src/actions, src/lib/actions, etc.
  for actions_dir in "$SRC/actions" "$SRC/lib/actions" "$PROJECT_PATH/actions"; do
    if [ -d "$actions_dir" ]; then
      echo "  Actions directory: $(echo "$actions_dir" | sed "s|$PROJECT_PATH/||")"
      find "$actions_dir" -type f \( -name "*.ts" -o -name "*.tsx" \) 2>/dev/null | sed "s|$PROJECT_PATH/||" | sort
    fi
  done

  # Server vs Client Component analysis
  echo ""
  echo "-- SERVER vs CLIENT COMPONENTS --"
  CLIENT_FILES=$(grep -rlE "'use client'|\"use client\"" "$APP_DIR" --include="*.tsx" --include="*.jsx" 2>/dev/null | wc -l)
  TOTAL_COMPONENTS=$(find "$APP_DIR" -type f \( -name "*.tsx" -o -name "*.jsx" \) -not -name "*.test.*" -not -name "*.spec.*" 2>/dev/null | wc -l)
  SERVER_FILES=$((TOTAL_COMPONENTS - CLIENT_FILES))
  echo "  Total component files: $TOTAL_COMPONENTS"
  echo "  'use client' files:   $CLIENT_FILES"
  echo "  Server Components:     $SERVER_FILES (no directive = server by default)"

  # Also check components/ directory if it exists
  for comp_dir in "$SRC/components" "$PROJECT_PATH/components"; do
    if [ -d "$comp_dir" ]; then
      CC=$(grep -rlE "'use client'|\"use client\"" "$comp_dir" --include="*.tsx" --include="*.jsx" 2>/dev/null | wc -l)
      TC=$(find "$comp_dir" \( -name "*.tsx" -o -name "*.jsx" \) 2>/dev/null | wc -l)
      SC=$((TC - CC))
      echo "  --- In $(echo "$comp_dir" | sed "s|$PROJECT_PATH/||")/ ---"
      echo "  Total: $TC | Client: $CC | Server: $SC"
    fi
  done

  echo ""
  echo "  Sample 'use client' files:"
  grep -rlE "'use client'|\"use client\"" "$APP_DIR" --include="*.tsx" --include="*.jsx" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

  # Route segment config
  echo ""
  echo "-- ROUTE SEGMENT CONFIG --"
  echo "  export const dynamic:"
  grep -rl "export const dynamic" "$APP_DIR" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" 2>/dev/null | sed "s|$PROJECT_PATH/||"
  echo "  export const revalidate:"
  grep -rl "export const revalidate" "$APP_DIR" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" 2>/dev/null | sed "s|$PROJECT_PATH/||"
  echo "  export const runtime:"
  grep -rl "export const runtime" "$APP_DIR" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" 2>/dev/null | sed "s|$PROJECT_PATH/||"
  echo "  export const fetchCache:"
  grep -rl "export const fetchCache" "$APP_DIR" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" 2>/dev/null | sed "s|$PROJECT_PATH/||"

  # Metadata
  echo ""
  echo "-- METADATA / SEO --"
  echo "  Files exporting metadata or generateMetadata:"
  grep -rlE "export const metadata|export async function generateMetadata|export function generateMetadata" "$APP_DIR" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" 2>/dev/null | sed "s|$PROJECT_PATH/||" | sort
  # Check for sitemap, robots, opengraph
  for seo_file in sitemap.ts sitemap.xml robots.ts robots.txt opengraph-image.tsx manifest.ts manifest.json; do
    found=$(find "$APP_DIR" -name "$seo_file" 2>/dev/null | head -1)
    [ -n "$found" ] && echo "  [FOUND] $(echo "$found" | sed "s|$PROJECT_PATH/||")"
  done
fi

# -- 6b. PAGES ROUTER ANALYSIS (if present) ----------------------------
if [ -n "$PAGES_DIR" ]; then
  echo ""
  echo "=========================================="
  echo "  PAGES ROUTER ANALYSIS"
  echo "=========================================="

  echo ""
  echo "-- PAGE FILES --"
  find "$PAGES_DIR" \( -name "*.tsx" -o -name "*.jsx" -o -name "*.ts" -o -name "*.js" \) -not -name "_*" -not -path "*/api/*" 2>/dev/null | sed "s|$PROJECT_PATH/||" | sort

  echo ""
  echo "-- SPECIAL FILES --"
  for special in _app.tsx _app.jsx _app.js _document.tsx _document.jsx _document.js _error.tsx _error.jsx 404.tsx 404.jsx 500.tsx 500.jsx; do
    found=$(find "$PAGES_DIR" -maxdepth 1 -name "$special" 2>/dev/null | head -1)
    [ -n "$found" ] && echo "  [FOUND] $(echo "$found" | sed "s|$PROJECT_PATH/||")"
  done

  echo ""
  echo "-- API ROUTES (pages/api/) --"
  if [ -d "$PAGES_DIR/api" ]; then
    find "$PAGES_DIR/api" -type f \( -name "*.ts" -o -name "*.js" \) 2>/dev/null | sed "s|$PROJECT_PATH/||" | sort
  else
    echo "  No pages/api/ directory"
  fi

  echo ""
  echo "-- DATA FETCHING PATTERNS --"
  echo "  getServerSideProps:"
  grep -rl "getServerSideProps" "$PAGES_DIR" --include="*.tsx" --include="*.ts" --include="*.jsx" --include="*.js" 2>/dev/null | sed "s|$PROJECT_PATH/||"
  echo "  getStaticProps:"
  grep -rl "getStaticProps" "$PAGES_DIR" --include="*.tsx" --include="*.ts" --include="*.jsx" --include="*.js" 2>/dev/null | sed "s|$PROJECT_PATH/||"
  echo "  getStaticPaths:"
  grep -rl "getStaticPaths" "$PAGES_DIR" --include="*.tsx" --include="*.ts" --include="*.jsx" --include="*.js" 2>/dev/null | sed "s|$PROJECT_PATH/||"
fi

# -- 7. MIDDLEWARE -------------------------------------------------------
echo ""
echo "-- MIDDLEWARE --"
for mw in middleware.ts middleware.js src/middleware.ts src/middleware.js; do
  if [ -f "$PROJECT_PATH/$mw" ]; then
    echo "  [FOUND] $mw"
    echo "  Contents preview (first 30 lines):"
    head -30 "$PROJECT_PATH/$mw" 2>/dev/null | sed 's/^/    /'
  fi
done
MIDDLEWARE_FOUND=$(find "$PROJECT_PATH" -maxdepth 2 -name "middleware.*" -not -path "*/node_modules/*" 2>/dev/null | head -1)
if [ -z "$MIDDLEWARE_FOUND" ]; then
  echo "  No middleware.ts/js found"
fi

# -- 8. REPRESENTATIVE FILES --------------------------------------------
echo ""
echo "=========================================="
echo "  REPRESENTATIVE FILES (1 per category)"
echo "=========================================="

# Next.js config
echo ""
echo "-- NEXT.JS CONFIG --"
for f in next.config.ts next.config.mjs next.config.js; do
  if [ -f "$PROJECT_PATH/$f" ]; then
    echo "  $f"
    break
  fi
done

# Root layout
echo ""
echo "-- ROOT LAYOUT --"
if [ -n "$APP_DIR" ]; then
  find "$APP_DIR" -maxdepth 1 \( -name "layout.tsx" -o -name "layout.jsx" -o -name "layout.ts" -o -name "layout.js" \) 2>/dev/null | head -1 | sed "s|$PROJECT_PATH/||"
fi

# Global CSS
echo ""
echo "-- GLOBAL STYLES --"
find "$SRC" -maxdepth 3 \( -name "globals.css" -o -name "global.css" -o -name "index.css" -o -name "app.css" \) -not -path "*/node_modules/*" 2>/dev/null | head -1 | sed "s|$PROJECT_PATH/||"

# Font configuration
echo ""
echo "-- FONT CONFIG --"
grep -rl "next/font" "$SRC" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" 2>/dev/null | head -3 | sed "s|$PROJECT_PATH/||"

# Image usage
echo ""
echo "-- IMAGE USAGE (next/image) --"
IMAGE_USAGE=$(grep -rl "next/image" "$SRC" --include="*.tsx" --include="*.jsx" 2>/dev/null | wc -l)
echo "  Files using next/image: $IMAGE_USAGE"
grep -rl "next/image" "$SRC" --include="*.tsx" --include="*.jsx" 2>/dev/null | head -3 | sed "s|$PROJECT_PATH/||"

# Navigation hooks
echo ""
echo "-- NAVIGATION (next/navigation or next/router) --"
NAV_FILES=$(grep -rl "next/navigation" "$SRC" --include="*.ts" --include="*.tsx" 2>/dev/null | wc -l)
ROUTER_FILES=$(grep -rl "next/router" "$SRC" --include="*.ts" --include="*.tsx" 2>/dev/null | wc -l)
echo "  next/navigation imports: $NAV_FILES"
echo "  next/router imports:     $ROUTER_FILES"

# Server-side imports (next/headers, cookies, etc.)
echo ""
echo "-- SERVER IMPORTS (next/headers, cookies) --"
HEADERS_FILES=$(grep -rl "next/headers" "$SRC" --include="*.ts" --include="*.tsx" 2>/dev/null | wc -l)
echo "  next/headers imports: $HEADERS_FILES"
grep -rl "next/headers" "$SRC" --include="*.ts" --include="*.tsx" 2>/dev/null | head -3 | sed "s|$PROJECT_PATH/||"
COOKIES_USAGE=$(grep -rl "cookies()" "$SRC" --include="*.ts" --include="*.tsx" 2>/dev/null | wc -l)
echo "  cookies() usage: $COOKIES_USAGE"

# Store files (client state)
echo ""
echo "-- STORES (pick 1 to read) --"
find "$SRC" \( -name "*store*" -o -name "*Store*" \) -not -path "*/node_modules/*" -not -path "*/.next/*" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Data access / lib files
echo ""
echo "-- DATA ACCESS / LIB --"
find "$SRC" -path "*/lib/*" -type f -not -path "*/node_modules/*" -not -path "*/.next/*" 2>/dev/null | head -10 | sed "s|$PROJECT_PATH/||"

# Server action files
echo ""
echo "-- SERVER ACTION FILES --"
find "$SRC" \( -name "*action*" -o -name "*Action*" \) -type f -not -path "*/node_modules/*" -not -path "*/.next/*" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Client hooks
echo ""
echo "-- CLIENT HOOKS (pick 1 to read) --"
find "$SRC" -name "use*" -type f -not -path "*/node_modules/*" -not -path "*/.next/*" 2>/dev/null | head -10 | sed "s|$PROJECT_PATH/||"

# Shared components
echo ""
echo "-- SHARED COMPONENTS --"
for comp_dir in "$SRC/components" "$PROJECT_PATH/components" "$SRC/shared/components"; do
  if [ -d "$comp_dir" ]; then
    echo "  $(echo "$comp_dir" | sed "s|$PROJECT_PATH/||")/"
    find "$comp_dir" -type f -not -path "*/node_modules/*" 2>/dev/null | head -10 | sed "s|$PROJECT_PATH/||"
  fi
done

# UI primitives
echo ""
echo "-- UI PRIMITIVES --"
find "$SRC" -path "*/ui/*" -type f -not -path "*/node_modules/*" -not -path "*/.next/*" 2>/dev/null | head -10 | sed "s|$PROJECT_PATH/||"

# Schema files (validation)
echo ""
echo "-- SCHEMA FILES (pick 1 to read) --"
find "$SRC" -name "*.schema.*" -not -path "*/node_modules/*" -not -path "*/.next/*" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"
# Also check prisma schema
[ -f "$PROJECT_PATH/prisma/schema.prisma" ] && echo "  prisma/schema.prisma"

# Auth files
echo ""
echo "-- AUTH FILES --"
find "$SRC" -path "*auth*" -type f -not -path "*/node_modules/*" -not -path "*/.next/*" 2>/dev/null | head -10 | sed "s|$PROJECT_PATH/||"
# Also check root-level auth config
for af in auth.ts auth.js auth.config.ts auth.config.js; do
  [ -f "$PROJECT_PATH/$af" ] && echo "  $af"
done

# Providers
echo ""
echo "-- PROVIDERS --"
find "$SRC" \( -name "*Provider*" -o -name "*provider*" -o -name "providers.tsx" -o -name "providers.ts" \) -not -path "*/node_modules/*" -not -path "*/.next/*" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Types
echo ""
echo "-- TYPE FILES --"
find "$SRC" -path "*/types/*" -type f -not -path "*/node_modules/*" -not -path "*/.next/*" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"
find "$SRC" \( -name "*.types.*" -o -name "*.d.ts" \) 2>/dev/null | grep -v node_modules | grep -v '/\.next/' | head -5 | sed "s|$PROJECT_PATH/||"

# Error handling
echo ""
echo "-- ERROR HANDLING --"
find "$SRC" \( -name "error.*" -o -name "not-found.*" -o -name "*Error*" -o -name "*ErrorBoundary*" \) -type f -not -path "*/node_modules/*" -not -path "*/.next/*" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Constants / Enums
echo ""
echo "-- CONSTANTS / ENUMS --"
find "$SRC" \( -name "*constant*" -o -name "*enum*" -o -name "*Constants*" -o -name "*Enum*" -o -name "*config*" \) -type f -not -path "*/node_modules/*" -not -path "*/.next/*" -not -name "*.config.*" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Test files
echo ""
echo "-- TEST FILES --"
find "$SRC" \( -name "*.test.*" -o -name "*.spec.*" \) -not -path "*/node_modules/*" -not -path "*/.next/*" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"
[ -d "$PROJECT_PATH/__tests__" ] && echo "  [DIR] __tests__/"
[ -d "$PROJECT_PATH/cypress" ] && echo "  [DIR] cypress/"
[ -d "$PROJECT_PATH/e2e" ] && echo "  [DIR] e2e/"
[ -d "$PROJECT_PATH/tests" ] && echo "  [DIR] tests/"

# i18n
echo ""
echo "-- I18N / LOCALES --"
find "$PROJECT_PATH" \( -name "i18n*" -o -path "*/locales/*" -o -path "*/translations/*" -o -path "*/messages/*" -o -name "*.locale.*" \) -not -path "*/node_modules/*" -not -path "*/.next/*" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"
# Check for next-intl or next-i18next
check_dep "next-intl" && echo "  [LIB] next-intl"
check_dep "next-i18next" && echo "  [LIB] next-i18next"

# -- 9. FEATURE SLICE EXAMPLE -------------------------------------------
echo ""
echo "=========================================="
echo "  FEATURE SLICE EXAMPLE"
echo "=========================================="
echo ""
echo "  Shows one complete feature/route with all its files."
echo ""

SLICE_DIR=""
# For App Router: find the deepest route group or feature-like directory
if [ -n "$APP_DIR" ]; then
  # Look for meaningful route directories (not (group) wrappers, but actual features)
  SLICE_DIR=$(find "$APP_DIR" -mindepth 1 -maxdepth 2 -type d \
    -not -name "api" -not -name ".*" \
    2>/dev/null | while read -r dir; do
    count=$(find "$dir" -type f 2>/dev/null | wc -l)
    echo "$count $dir"
  done | sort -rn | head -1 | sed 's/^[[:space:]]*[0-9]*[[:space:]]*//')
fi

# Fallback to feature/module directories
if [ -z "$SLICE_DIR" ]; then
  for base_dir in "$SRC/features" "$SRC/modules" "$SRC/core" "$SRC/domains"; do
    if [ -d "$base_dir" ]; then
      SLICE_DIR=$(find "$base_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | while read -r dir; do
        count=$(find "$dir" -type f 2>/dev/null | wc -l)
        echo "$count $dir"
      done | sort -rn | head -1 | sed 's/^[[:space:]]*[0-9]*[[:space:]]*//')
      [ -n "$SLICE_DIR" ] && break
    fi
  done
fi

if [ -n "$SLICE_DIR" ]; then
  echo "-- $(basename "$SLICE_DIR") ($(find "$SLICE_DIR" -type f 2>/dev/null | wc -l) files) --"
  find "$SLICE_DIR" -type f 2>/dev/null | sed "s|$PROJECT_PATH/||" | sort
else
  echo "  No feature directory found with nested structure."
fi

# -- 10. SMART SAMPLING -- LARGEST FILES PER CATEGORY --------------------
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
  result=$(find "$search_path" \( "$@" \) -not -path "*/node_modules/*" -not -path "*/.next/*" -type f -print0 2>/dev/null | xargs -0 wc -l 2>/dev/null | grep -v " total$" | sort -rn | head -1)
  if [ -n "$result" ]; then
    local lines file
    lines=$(echo "$result" | awk '{print $1}')
    file=$(echo "$result" | sed 's/^[[:space:]]*[0-9]*//' | sed 's/^[[:space:]]*//' | sed "s|$PROJECT_PATH/||")
    echo "  $label: $file ($lines lines)"
  fi
}

show_largest "Page" "$SRC" -name "page.tsx" -o -name "page.jsx"
show_largest "Layout" "$SRC" -name "layout.tsx" -o -name "layout.jsx"
show_largest "Route Handler" "$SRC" -name "route.ts" -o -name "route.js"
show_largest "Component" "$SRC" -name "*.tsx" -not -name "*.test.*" -not -name "*.spec.*" -not -name "page.*" -not -name "layout.*" -not -name "error.*" -not -name "loading.*" -not -path "*/ui/*"
show_largest "Client Component" "$SRC" -name "*.tsx"
show_largest "Hook" "$SRC" -name "use*.ts" -not -name "*.test.*" -not -name "*.spec.*"
show_largest "Server Action" "$SRC" -name "*action*"
show_largest "Schema" "$SRC" -name "*.schema.*"
show_largest "Store" "$SRC" -name "*store*" -o -name "*Store*"
show_largest "Test" "$SRC" -name "*.test.*" -o -name "*.spec.*"
show_largest "Middleware" "$PROJECT_PATH" -name "middleware.*"
show_largest "Auth" "$SRC" -name "*auth*"

# -- 11. CODING STYLE SIGNALS -------------------------------------------
echo ""
echo "=========================================="
echo "  CODING STYLE SIGNALS"
echo "=========================================="

# Barrel exports (index.ts usage)
BARREL_COUNT=$(find "$SRC" \( -name "index.ts" -o -name "index.tsx" -o -name "index.js" -o -name "index.jsx" \) -not -path "*/node_modules/*" -not -path "*/.next/*" 2>/dev/null | wc -l)
echo ""
echo "-- BARREL EXPORTS --"
echo "  index.ts/tsx files: $BARREL_COUNT"
if [ "$BARREL_COUNT" -gt 5 ]; then
  echo "  [HEAVY] Uses barrel exports extensively"
elif [ "$BARREL_COUNT" -gt 0 ]; then
  echo "  [LIGHT] Some barrel exports"
else
  echo "  [NONE] No barrel exports -- direct imports"
fi

# Export style (default vs named)
echo ""
echo "-- EXPORT STYLE --"
DEFAULT_EXPORTS=$(grep -r "export default" "$SRC" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" 2>/dev/null | grep -v node_modules | grep -v '/\.next/' | wc -l)
NAMED_EXPORTS=$(grep -rE "export const|export function|export type|export interface|export async function" "$SRC" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" 2>/dev/null | grep -v node_modules | grep -v '/\.next/' | wc -l)
echo "  export default: $DEFAULT_EXPORTS"
echo "  named exports:  $NAMED_EXPORTS"

# Component declaration style
echo ""
echo "-- COMPONENT STYLE --"
ARROW_COMPS=$(grep -r "export const.*=.*(" "$SRC" --include="*.tsx" --include="*.jsx" 2>/dev/null | grep -v node_modules | grep -v '/\.next/' | wc -l)
FUNC_COMPS=$(grep -rE "export function |export default function " "$SRC" --include="*.tsx" --include="*.jsx" 2>/dev/null | grep -v node_modules | grep -v '/\.next/' | wc -l)
echo "  Arrow (const X = () =>): $ARROW_COMPS"
echo "  Function declaration:    $FUNC_COMPS"
echo "  NOTE: Next.js App Router pages commonly use 'export default function' by convention"

# Interface vs Type
echo ""
echo "-- TYPE DEFINITIONS --"
INTERFACES=$(grep -rE "export interface |interface " "$SRC" --include="*.ts" --include="*.tsx" 2>/dev/null | grep -v node_modules | grep -v '/\.next/' | wc -l)
TYPE_ALIASES=$(grep -rE "export type |type " "$SRC" --include="*.ts" --include="*.tsx" 2>/dev/null | grep -v node_modules | grep -v '/\.next/' | wc -l)
echo "  interface: $INTERFACES"
echo "  type:      $TYPE_ALIASES"

# 'use client' vs 'use server' directives
echo ""
echo "-- DIRECTIVE USAGE --"
USE_CLIENT=$(grep -rlE "'use client'|\"use client\"" "$SRC" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" 2>/dev/null | grep -v node_modules | grep -v '/\.next/' | wc -l)
USE_SERVER=$(grep -rlE "'use server'|\"use server\"" "$SRC" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" 2>/dev/null | grep -v node_modules | grep -v '/\.next/' | wc -l)
echo "  'use client' files: $USE_CLIENT"
echo "  'use server' files: $USE_SERVER"

# Async components (Server Component pattern)
echo ""
echo "-- ASYNC COMPONENTS (Server Component pattern) --"
ASYNC_COMPS=$(grep -rE "export default async function|export async function.*Page|export async function.*Layout" "$SRC" --include="*.tsx" --include="*.jsx" 2>/dev/null | grep -v node_modules | grep -v '/\.next/' | wc -l)
echo "  async function components: $ASYNC_COMPS"

echo ""
echo "========================================="
echo "  SCAN COMPLETE"
echo "========================================="
echo ""
echo "  Next: Read 1-2 files per category above,"
echo "  following references/scan-checklist.md"
