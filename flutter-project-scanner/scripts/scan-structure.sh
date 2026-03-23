#!/bin/bash
# Flutter/Dart Codebase Structure Scanner
# Usage: bash scan-structure.sh <project-path>
# Outputs: directory tree, dependencies, configs, architecture detection,
#          state management detection, and representative files per category.
# Works on: Linux, macOS, Windows (Git Bash / WSL)

PROJECT_PATH="${1:-.}"

if [ ! -d "$PROJECT_PATH" ]; then
  echo "ERROR: Directory '$PROJECT_PATH' does not exist."
  exit 1
fi

if [ ! -f "$PROJECT_PATH/pubspec.yaml" ]; then
  echo "ERROR: No pubspec.yaml found at '$PROJECT_PATH'. Not a Flutter/Dart project."
  exit 1
fi

LIB="$PROJECT_PATH/lib"
if [ ! -d "$LIB" ]; then
  echo "WARNING: No lib/ directory found. Scanning project root instead."
  LIB="$PROJECT_PATH"
fi

echo "========================================="
echo "  FLUTTER CODEBASE SCANNER"
echo "  Project: $PROJECT_PATH"
echo "========================================="

# ── 0. REPOMIX DETECTION ─────────────────────────────────────────────
echo ""
echo "── REPOMIX ──"
if command -v repomix &>/dev/null || npx --no repomix --version &>/dev/null; then
  echo "  [AVAILABLE] repomix detected"
  echo "  Run: npx repomix $PROJECT_PATH --output $PROJECT_PATH/repomix-output.txt"
else
  echo "  [NOT FOUND] repomix not available — skipping (install: npm i -g repomix)"
fi

# ── 1. FLUTTER/DART VERSION DETECTION ──────────────────────────────
echo ""
echo "── FLUTTER & DART VERSION ──"
FLUTTER_VER="unknown"
DART_VER="unknown"

# Check environment constraint in pubspec.yaml
if grep -q "sdk:" "$PROJECT_PATH/pubspec.yaml" 2>/dev/null; then
  DART_SDK=$(grep -A1 "environment:" "$PROJECT_PATH/pubspec.yaml" 2>/dev/null | grep "sdk:" | head -1 | sed 's/.*sdk:\s*//' | tr -d "\"'" | xargs)
  [ -n "$DART_SDK" ] && DART_VER="$DART_SDK"
  FLUTTER_SDK=$(grep -A2 "environment:" "$PROJECT_PATH/pubspec.yaml" 2>/dev/null | grep "flutter:" | head -1 | sed 's/.*flutter:\s*//' | tr -d "\"'" | xargs)
  [ -n "$FLUTTER_SDK" ] && FLUTTER_VER="$FLUTTER_SDK"
fi
echo "  Dart SDK:    $DART_VER"
echo "  Flutter SDK: $FLUTTER_VER"

# ── 1b. PROJECT INFO ───────────────────────────────────────────────
echo ""
echo "── PROJECT INFO ──"
PROJ_NAME=$(grep "^name:" "$PROJECT_PATH/pubspec.yaml" 2>/dev/null | head -1 | sed 's/name:\s*//' | xargs)
PROJ_DESC=$(grep "^description:" "$PROJECT_PATH/pubspec.yaml" 2>/dev/null | head -1 | sed 's/description:\s*//' | xargs)
PROJ_VERSION=$(grep "^version:" "$PROJECT_PATH/pubspec.yaml" 2>/dev/null | head -1 | sed 's/version:\s*//' | xargs)
echo "  Name:        ${PROJ_NAME:-N/A}"
echo "  Description: ${PROJ_DESC:-N/A}"
echo "  Version:     ${PROJ_VERSION:-N/A}"

# ── 1c. NULL SAFETY ───────────────────────────────────────────────
echo ""
echo "── NULL SAFETY ──"
if echo "$DART_VER" | grep -qE ">=\s*[23]"; then
  echo "  [ENABLED] Sound null safety (Dart SDK $DART_VER)"
else
  echo "  [CHECK MANUALLY] Dart SDK constraint: $DART_VER"
fi

# ── 2. PUBSPEC.YAML DEPENDENCIES ──────────────────────────────────
echo ""
echo "── DEPENDENCIES (pubspec.yaml) ──"

# Cross-platform: try python3, then python, then fallback to raw output
if command -v python3 &>/dev/null; then
  PYTHON_CMD="python3"
elif command -v python &>/dev/null; then
  PYTHON_CMD="python"
else
  PYTHON_CMD=""
fi

if [ -n "$PYTHON_CMD" ]; then
  PROJECT_PATH="$PROJECT_PATH" $PYTHON_CMD -c "
import sys, re, os

content = open(os.path.join(os.environ['PROJECT_PATH'], 'pubspec.yaml')).read()

# Simple YAML parsing for dependencies
def extract_deps(content, section):
    pattern = r'^' + section + r':\s*\n((?:[ \t]+\S.*\n)*)'
    match = re.search(pattern, content, re.MULTILINE)
    if not match:
        return {}
    block = match.group(1)
    deps = {}
    for line in block.split('\n'):
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        if ':' in line:
            parts = line.split(':', 1)
            key = parts[0].strip()
            val = parts[1].strip()
            if key and not key.startswith('-'):
                deps[key] = val if val else '(path/git/sdk)'
    return deps

prod = extract_deps(content, 'dependencies')
dev = extract_deps(content, 'dev_dependencies')

print('  Production:')
for k, v in sorted(prod.items()):
    print(f'    {k}: {v}')
print()
print('  Dev:')
for k, v in sorted(dev.items()):
    print(f'    {k}: {v}')
" 2>/dev/null
else
  echo "  (python not found — showing raw pubspec.yaml)"
  cat "$PROJECT_PATH/pubspec.yaml"
fi

# ── 2b. STACK CLASSIFICATION ──────────────────────────────────────
echo ""
echo "── STACK SUMMARY ──"
PUBSPEC="$PROJECT_PATH/pubspec.yaml"

check_dep() {
  grep -q "^[[:space:]]*$1:" "$PUBSPEC" 2>/dev/null
}

# State Management
echo -n "  State Mgmt:       "
STATE=""
if check_dep "flutter_bloc"; then STATE="flutter_bloc (BLoC/Cubit)"
elif check_dep "bloc"; then STATE="bloc"
elif check_dep "hooks_riverpod"; then STATE="hooks_riverpod"
elif check_dep "flutter_riverpod"; then STATE="flutter_riverpod"
elif check_dep "riverpod"; then STATE="riverpod"
elif check_dep "provider"; then STATE="provider"
elif check_dep "get"; then STATE="GetX"
elif check_dep "getx"; then STATE="GetX"
elif check_dep "mobx"; then STATE="MobX"
elif check_dep "flutter_mobx"; then STATE="flutter_mobx"
elif check_dep "signals"; then STATE="signals"
elif check_dep "flutter_signals"; then STATE="flutter_signals"
else STATE="none / setState / ValueNotifier"; fi
echo "$STATE"

# Navigation/Routing
echo -n "  Navigation:       "
if check_dep "go_router"; then echo "go_router"
elif check_dep "go_router_builder"; then echo "go_router_builder (type-safe)"
elif check_dep "auto_route"; then echo "auto_route"
elif check_dep "beamer"; then echo "beamer"
elif check_dep "get"; then echo "GetX (built-in routing)"
elif check_dep "routemaster"; then echo "routemaster"
else echo "Navigator (built-in)"; fi

# HTTP Client
echo -n "  HTTP Client:      "
if check_dep "dio"; then echo "dio"
elif check_dep "retrofit"; then echo "retrofit (dio-based)"
elif check_dep "chopper"; then echo "chopper"
elif check_dep "http"; then echo "http (dart:io)"
elif check_dep "graphql_flutter"; then echo "graphql_flutter"
elif check_dep "graphql"; then echo "graphql"
else echo "none / dart:io HttpClient"; fi

# Dependency Injection
echo -n "  DI:               "
if check_dep "get_it" && check_dep "injectable"; then echo "get_it + injectable"
elif check_dep "get_it"; then echo "get_it"
elif check_dep "injectable"; then echo "injectable"
elif check_dep "riverpod" || check_dep "flutter_riverpod" || check_dep "hooks_riverpod"; then echo "Riverpod (provider-based)"
elif check_dep "get" || check_dep "getx"; then echo "GetX (built-in bindings)"
else echo "none / manual"; fi

# Local Storage
echo -n "  Local Storage:    "
STORAGE=""
check_dep "hive" && STORAGE="hive"
check_dep "hive_flutter" && STORAGE="${STORAGE:+$STORAGE + }hive_flutter"
check_dep "isar" && STORAGE="${STORAGE:+$STORAGE + }isar"
check_dep "drift" && STORAGE="${STORAGE:+$STORAGE + }drift"
check_dep "sqflite" && STORAGE="${STORAGE:+$STORAGE + }sqflite"
check_dep "shared_preferences" && STORAGE="${STORAGE:+$STORAGE + }shared_preferences"
check_dep "flutter_secure_storage" && STORAGE="${STORAGE:+$STORAGE + }flutter_secure_storage"
echo "${STORAGE:-none}"

# Code Generation
echo -n "  Code Gen:         "
CODEGEN=""
check_dep "freezed" && CODEGEN="freezed"
check_dep "json_serializable" && CODEGEN="${CODEGEN:+$CODEGEN + }json_serializable"
check_dep "build_runner" && CODEGEN="${CODEGEN:+$CODEGEN + }build_runner"
check_dep "retrofit_generator" && CODEGEN="${CODEGEN:+$CODEGEN + }retrofit_generator"
check_dep "injectable_generator" && CODEGEN="${CODEGEN:+$CODEGEN + }injectable_generator"
check_dep "auto_route_generator" && CODEGEN="${CODEGEN:+$CODEGEN + }auto_route_generator"
check_dep "hive_generator" && CODEGEN="${CODEGEN:+$CODEGEN + }hive_generator"
check_dep "envied_generator" && CODEGEN="${CODEGEN:+$CODEGEN + }envied_generator"
echo "${CODEGEN:-none}"

# Forms
echo -n "  Forms:            "
if check_dep "reactive_forms"; then echo "reactive_forms"
elif check_dep "flutter_form_builder"; then echo "flutter_form_builder"
elif check_dep "form_builder_validators"; then echo "form_builder_validators"
else echo "built-in Form / TextFormField"; fi

# Testing
echo -n "  Testing:          "
TESTING=""
check_dep "flutter_test" && TESTING="flutter_test"
check_dep "bloc_test" && TESTING="${TESTING:+$TESTING + }bloc_test"
check_dep "mockito" && TESTING="${TESTING:+$TESTING + }mockito"
check_dep "mocktail" && TESTING="${TESTING:+$TESTING + }mocktail"
check_dep "integration_test" && TESTING="${TESTING:+$TESTING + }integration_test"
check_dep "golden_toolkit" && TESTING="${TESTING:+$TESTING + }golden_toolkit"
check_dep "patrol" && TESTING="${TESTING:+$TESTING + }patrol"
echo "${TESTING:-none}"

# Lint / Analysis
echo -n "  Lint:             "
if check_dep "very_good_analysis"; then echo "very_good_analysis"
elif check_dep "flutter_lints"; then echo "flutter_lints"
elif check_dep "lint"; then echo "lint"
elif check_dep "pedantic"; then echo "pedantic"
elif [ -f "$PROJECT_PATH/analysis_options.yaml" ]; then echo "custom (analysis_options.yaml)"
else echo "none"; fi

# i18n / Localization
echo -n "  i18n:             "
if check_dep "easy_localization"; then echo "easy_localization"
elif check_dep "intl"; then echo "intl"
elif check_dep "flutter_localizations"; then echo "flutter_localizations"
elif check_dep "slang"; then echo "slang"
else echo "none"; fi

# UI Extras
echo -n "  UI Extras:        "
UI_EXTRAS=""
check_dep "flutter_screenutil" && UI_EXTRAS="flutter_screenutil"
check_dep "responsive_framework" && UI_EXTRAS="${UI_EXTRAS:+$UI_EXTRAS + }responsive_framework"
check_dep "cached_network_image" && UI_EXTRAS="${UI_EXTRAS:+$UI_EXTRAS + }cached_network_image"
check_dep "flutter_svg" && UI_EXTRAS="${UI_EXTRAS:+$UI_EXTRAS + }flutter_svg"
check_dep "shimmer" && UI_EXTRAS="${UI_EXTRAS:+$UI_EXTRAS + }shimmer"
echo "${UI_EXTRAS:-none}"

# Firebase
echo -n "  Firebase:         "
FIREBASE=""
check_dep "firebase_core" && FIREBASE="firebase_core"
check_dep "cloud_firestore" && FIREBASE="${FIREBASE:+$FIREBASE + }cloud_firestore"
check_dep "firebase_auth" && FIREBASE="${FIREBASE:+$FIREBASE + }firebase_auth"
check_dep "firebase_messaging" && FIREBASE="${FIREBASE:+$FIREBASE + }firebase_messaging"
check_dep "firebase_storage" && FIREBASE="${FIREBASE:+$FIREBASE + }firebase_storage"
check_dep "firebase_analytics" && FIREBASE="${FIREBASE:+$FIREBASE + }firebase_analytics"
check_dep "firebase_crashlytics" && FIREBASE="${FIREBASE:+$FIREBASE + }firebase_crashlytics"
echo "${FIREBASE:-none}"

# Animation
echo -n "  Animation:        "
if check_dep "flutter_animate"; then echo "flutter_animate"
elif check_dep "rive"; then echo "rive"
elif check_dep "lottie"; then echo "lottie"
elif check_dep "animations"; then echo "animations (Material motion)"
else echo "none / built-in"; fi

# Functional Programming
echo -n "  FP Utilities:     "
FP=""
check_dep "dartz" && FP="dartz (Either, Option)"
check_dep "fpdart" && FP="fpdart (Either, Option)"
check_dep "equatable" && FP="${FP:+$FP + }equatable"
echo "${FP:-none}"

# ── 3. ARCHITECTURE PATTERN DETECTION ──────────────────────────────
echo ""
echo "── ARCHITECTURE PATTERN ──"

# Detect architecture from directory structure
ARCH="unknown"

# Clean Architecture detection
if [ -d "$LIB/data" ] && [ -d "$LIB/domain" ] && [ -d "$LIB/presentation" ]; then
  ARCH="Clean Architecture (data/domain/presentation at root)"
elif find "$LIB" -type d -name "data" 2>/dev/null | head -1 | grep -q "data" && \
     find "$LIB" -type d -name "domain" 2>/dev/null | head -1 | grep -q "domain" && \
     find "$LIB" -type d -name "presentation" 2>/dev/null | head -1 | grep -q "presentation"; then
  ARCH="Clean Architecture (per-feature data/domain/presentation)"
fi

# Feature-first detection
if [ -d "$LIB/features" ] || [ -d "$LIB/feature" ]; then
  if [ "$ARCH" = "unknown" ]; then
    ARCH="Feature-first organization"
  else
    ARCH="$ARCH + Feature-first"
  fi
fi

# Layer-first detection
if [ -d "$LIB/models" ] && [ -d "$LIB/screens" ] && [ -d "$LIB/services" ]; then
  ARCH="Layer-first (models/screens/services)"
elif [ -d "$LIB/models" ] && [ -d "$LIB/views" ] && [ -d "$LIB/controllers" ]; then
  ARCH="MVC (models/views/controllers)"
elif [ -d "$LIB/models" ] && [ -d "$LIB/views" ] && [ -d "$LIB/view_models" ]; then
  ARCH="MVVM (models/views/view_models)"
fi

# BLoC-specific pattern detection
BLOC_COUNT=$(find "$LIB" \( -name "*_bloc.dart" -o -name "*_cubit.dart" \) 2>/dev/null | wc -l)
if [ "$BLOC_COUNT" -gt 0 ]; then
  ARCH="$ARCH (BLoC pattern: $BLOC_COUNT blocs/cubits found)"
fi

echo "  Detected: $ARCH"

# Sub-pattern detection
echo ""
echo "  Directory clues:"
[ -d "$LIB/core" ] && echo "    [FOUND] lib/core/ — shared core utilities"
[ -d "$LIB/common" ] && echo "    [FOUND] lib/common/ — shared common code"
[ -d "$LIB/shared" ] && echo "    [FOUND] lib/shared/ — shared layer"
[ -d "$LIB/config" ] && echo "    [FOUND] lib/config/ — app configuration"
[ -d "$LIB/di" ] && echo "    [FOUND] lib/di/ — dependency injection setup"
[ -d "$LIB/injection" ] && echo "    [FOUND] lib/injection/ — DI container"
[ -d "$LIB/l10n" ] && echo "    [FOUND] lib/l10n/ — localization"
[ -d "$LIB/router" ] || [ -d "$LIB/routes" ] || [ -d "$LIB/navigation" ] && echo "    [FOUND] routing directory"
[ -d "$LIB/theme" ] || [ -d "$LIB/themes" ] && echo "    [FOUND] theme directory"
[ -d "$LIB/widgets" ] && echo "    [FOUND] lib/widgets/ — shared widgets"
[ -d "$LIB/utils" ] || [ -d "$LIB/helpers" ] && echo "    [FOUND] utils/helpers directory"
[ -d "$LIB/extensions" ] && echo "    [FOUND] lib/extensions/ — Dart extension methods"
[ -d "$LIB/mixins" ] && echo "    [FOUND] lib/mixins/ — Dart mixins"

# ── 4. CONFIG FILES ────────────────────────────────────────────────
echo ""
echo "── CONFIG FILES ──"
for config in pubspec.yaml pubspec.lock analysis_options.yaml \
              l10n.yaml build.yaml \
              .flutter-plugins .flutter-plugins-dependencies \
              .metadata \
              firebase.json .firebaserc \
              Makefile \
              Dockerfile docker-compose.yml docker-compose.yaml \
              .github/workflows \
              .fvm/fvm_config.json .tool-versions \
              .env .env.example .env.dev .env.staging .env.prod \
              devtools_options.yaml \
              dart_test.yaml \
              mason.yaml mason-lock.json; do
  if [ -f "$PROJECT_PATH/$config" ] || [ -d "$PROJECT_PATH/$config" ]; then
    echo "  [FOUND] $config"
  fi
done

# Check for flavor/scheme configs
echo ""
echo "── BUILD FLAVORS ──"
FLAVORS_FOUND=0
for flavor_dir in "$PROJECT_PATH/android/app/src/dev" "$PROJECT_PATH/android/app/src/staging" "$PROJECT_PATH/android/app/src/prod" "$PROJECT_PATH/android/app/src/production"; do
  if [ -d "$flavor_dir" ]; then
    echo "  [FOUND] $(basename "$flavor_dir") flavor (Android)"
    FLAVORS_FOUND=1
  fi
done

# Check for multiple main files (common flavor pattern)
for main_file in "$LIB/main_dev.dart" "$LIB/main_staging.dart" "$LIB/main_prod.dart" "$LIB/main_production.dart" "$LIB/main_development.dart"; do
  if [ -f "$main_file" ]; then
    echo "  [FOUND] $(basename "$main_file")"
    FLAVORS_FOUND=1
  fi
done

if [ "$FLAVORS_FOUND" -eq 0 ]; then
  echo "  No build flavors detected"
fi

# ── 5. DIRECTORY STRUCTURE ────────────────────────────────────────
echo ""
echo "── DIRECTORY STRUCTURE (lib/) ──"
find "$LIB" -maxdepth 5 -type d 2>/dev/null | sed "s|$PROJECT_PATH/||" | sort

# ── 6. FILE COUNTS ───────────────────────────────────────────────
echo ""
echo "── FILE COUNTS ──"
find "$LIB" -type f 2>/dev/null | awk -F/ '{print $NF}' | grep '\.' | sed 's/.*\.//' | sort | uniq -c | sort -rn

echo ""
echo "── GENERATED FILES ──"
FREEZED_COUNT=$(find "$LIB" -name "*.freezed.dart" 2>/dev/null | wc -l)
G_COUNT=$(find "$LIB" -name "*.g.dart" 2>/dev/null | wc -l)
GR_COUNT=$(find "$LIB" -name "*.gr.dart" 2>/dev/null | wc -l)
echo "  *.freezed.dart: $FREEZED_COUNT"
echo "  *.g.dart:       $G_COUNT"
echo "  *.gr.dart:      $GR_COUNT (auto_route)"

# ── 7. REPRESENTATIVE FILES ──────────────────────────────────────
echo ""
echo "══════════════════════════════════════════"
echo "  REPRESENTATIVE FILES (1 per category)"
echo "══════════════════════════════════════════"

# Entry points
echo ""
echo "── ENTRY POINTS ──"
for f in main.dart app.dart app_widget.dart application.dart; do
  found=$(find "$LIB" -maxdepth 2 -name "$f" 2>/dev/null | head -1)
  if [ -n "$found" ]; then
    echo "  $(echo "$found" | sed "s|$PROJECT_PATH/||")"
  fi
done

# BLoC / Cubit files
echo ""
echo "── BLOCS / CUBITS (pick 1 to read) ──"
find "$LIB" \( -name "*_bloc.dart" -o -name "*_cubit.dart" \) -not -name "*.freezed.dart" -not -name "*.g.dart" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# BLoC State files
echo ""
echo "── BLOC STATES (pick 1 to read) ──"
find "$LIB" -name "*_state.dart" -not -name "*.freezed.dart" -not -name "*.g.dart" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# BLoC Event files
echo ""
echo "── BLOC EVENTS (pick 1 to read) ──"
find "$LIB" -name "*_event.dart" -not -name "*.freezed.dart" -not -name "*.g.dart" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Riverpod provider files
echo ""
echo "── PROVIDERS (Riverpod/Provider — pick 1 to read) ──"
find "$LIB" \( -name "*_provider.dart" -o -name "*_providers.dart" -o -name "*_notifier.dart" \) -not -name "*.g.dart" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Repository files
echo ""
echo "── REPOSITORIES (pick 1 to read) ──"
find "$LIB" \( -name "*_repository.dart" -o -name "*_repo.dart" -o -name "*repository_impl.dart" \) -not -name "*.g.dart" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Data source files
echo ""
echo "── DATA SOURCES (pick 1 to read) ──"
find "$LIB" \( -name "*_data_source.dart" -o -name "*_remote_source.dart" -o -name "*_local_source.dart" -o -name "*_api.dart" -o -name "*_service.dart" \) -not -name "*.g.dart" -not -name "*.freezed.dart" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Model / Entity files
echo ""
echo "── MODELS / ENTITIES (pick 1 to read) ──"
find "$LIB" \( -name "*_model.dart" -o -name "*_entity.dart" -o -name "*_dto.dart" \) -not -name "*.freezed.dart" -not -name "*.g.dart" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Use case / Interactor files
echo ""
echo "── USE CASES / INTERACTORS (pick 1 to read) ──"
find "$LIB" \( -name "*_usecase.dart" -o -name "*_use_case.dart" -o -name "*_interactor.dart" \) 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Screen / Page files
echo ""
echo "── SCREENS / PAGES (pick 1 to read) ──"
find "$LIB" \( -name "*_screen.dart" -o -name "*_page.dart" -o -name "*_view.dart" \) -not -name "*.g.dart" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Widget files (shared/reusable)
echo ""
echo "── SHARED WIDGETS (pick 1 to read) ──"
find "$LIB" \( -path "*/widgets/*" -o -path "*/components/*" -o -path "*/common/widgets/*" \) -name "*.dart" -not -name "*.g.dart" -not -name "*.freezed.dart" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Router files
echo ""
echo "── ROUTER FILES ──"
find "$LIB" \( -name "*router*" -o -name "*route*" -o -name "*navigation*" -o -name "app_router.dart" \) -name "*.dart" -not -name "*.g.dart" -not -name "*.gr.dart" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# DI / Injection files
echo ""
echo "── DI / INJECTION FILES ──"
find "$LIB" \( -name "*injection*" -o -name "*injector*" -o -name "service_locator*" -o -name "di.dart" -o -name "locator.dart" -o -name "*_module.dart" \) -name "*.dart" -not -name "*.g.dart" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Theme files
echo ""
echo "── THEME FILES ──"
find "$LIB" \( -name "*theme*" -o -name "*color*" -o -name "*style*" -o -name "*typography*" \) -name "*.dart" -not -name "*.g.dart" -not -name "*.freezed.dart" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# HTTP / API client
echo ""
echo "── HTTP / API CLIENT ──"
find "$LIB" \( -name "*http*" -o -name "*dio*" -o -name "*api_client*" -o -name "*network*" -o -name "*interceptor*" \) -name "*.dart" -not -name "*.g.dart" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Error / Failure classes
echo ""
echo "── ERROR / FAILURE CLASSES ──"
find "$LIB" \( -name "*error*" -o -name "*failure*" -o -name "*exception*" \) -name "*.dart" -not -name "*.g.dart" -not -name "*.freezed.dart" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Extension methods
echo ""
echo "── EXTENSION FILES ──"
find "$LIB" \( -name "*extension*" -o -path "*/extensions/*" \) -name "*.dart" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Utility / Helper files
echo ""
echo "── UTILS / HELPERS ──"
find "$LIB" \( -path "*/utils/*" -o -path "*/helpers/*" -o -path "*/utilities/*" \) -name "*.dart" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Constants
echo ""
echo "── CONSTANTS / CONFIG ──"
find "$LIB" \( -name "*constant*" -o -name "*config*" -o -name "*env*" -o -name "*app_config*" \) -name "*.dart" -not -name "*.g.dart" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Barrel files (exports)
echo ""
echo "── BARREL FILES ──"
find "$LIB" -name "*.dart" -print0 2>/dev/null | xargs -0 grep -l "^export " 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# i18n / Localization
echo ""
echo "── I18N / LOCALIZATION ──"
find "$PROJECT_PATH" \( -name "*.arb" -o -path "*/l10n/*" -o -path "*/localization/*" -o -path "*/locale/*" -o -name "*translations*" \) -not -path "*/build/*" -not -path "*/.dart_tool/*" -type f 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"

# Test files
echo ""
echo "── TEST FILES ──"
find "$PROJECT_PATH/test" -name "*_test.dart" -not -path "*/build/*" 2>/dev/null | head -5 | sed "s|$PROJECT_PATH/||"
if [ -d "$PROJECT_PATH/integration_test" ]; then
  echo "  [DIR] integration_test/"
  find "$PROJECT_PATH/integration_test" -name "*.dart" 2>/dev/null | head -3 | sed "s|$PROJECT_PATH/||"
fi
if [ -d "$PROJECT_PATH/test/golden" ] || [ -d "$PROJECT_PATH/test/goldens" ]; then
  echo "  [DIR] golden tests found"
fi

# ── 8. FEATURE SLICE EXAMPLE ─────────────────────────────────────
echo ""
echo "══════════════════════════════════════════"
echo "  FEATURE SLICE EXAMPLE"
echo "══════════════════════════════════════════"
echo ""
echo "  Shows one complete feature with all its files."
echo "  Pick the first feature directory that has 5+ files."
echo ""

SLICE_DIR=""
for base_dir in "$LIB/features" "$LIB/feature" "$LIB/core" "$LIB/modules" "$LIB/presentation" "$LIB/pages"; do
  if [ -d "$base_dir" ]; then
    SLICE_DIR=$(find "$base_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | while read -r dir; do
      count=$(find "$dir" -type f -name "*.dart" -not -name "*.g.dart" -not -name "*.freezed.dart" 2>/dev/null | wc -l)
      echo "$count $dir"
    done | sort -rn | head -1 | sed 's/^[[:space:]]*[0-9]*[[:space:]]*//')
    [ -n "$SLICE_DIR" ] && break
  fi
done

if [ -n "$SLICE_DIR" ]; then
  DART_FILE_COUNT=$(find "$SLICE_DIR" -type f -name "*.dart" -not -name "*.g.dart" -not -name "*.freezed.dart" 2>/dev/null | wc -l)
  echo "── $(basename "$SLICE_DIR") ($DART_FILE_COUNT Dart files, excluding generated) ──"
  find "$SLICE_DIR" -type f -name "*.dart" -not -name "*.g.dart" -not -name "*.freezed.dart" 2>/dev/null | sed "s|$PROJECT_PATH/||" | sort
else
  echo "  No feature directory found with nested structure."
fi

# ── 9. LARGEST FILES PER CATEGORY (SMART SAMPLING) ──────────────
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
  result=$(find "$search_path" \( "$@" \) -not -path "*/build/*" -not -path "*/.dart_tool/*" -not -name "*.g.dart" -not -name "*.freezed.dart" -not -name "*.gr.dart" -type f -print0 2>/dev/null | xargs -0 wc -l 2>/dev/null | grep -v " total$" | sort -rn | head -1)
  if [ -n "$result" ]; then
    local lines file
    lines=$(echo "$result" | awk '{print $1}')
    file=$(echo "$result" | sed 's/^[[:space:]]*[0-9]*//' | sed 's/^[[:space:]]*//' | sed "s|$PROJECT_PATH/||")
    echo "  $label: $file ($lines lines)"
  fi
}

show_largest "Screen/Page" "$LIB" -name "*_screen.dart" -o -name "*_page.dart" -o -name "*_view.dart"
show_largest "BLoC/Cubit" "$LIB" -name "*_bloc.dart" -o -name "*_cubit.dart"
show_largest "Repository" "$LIB" -name "*_repository.dart" -o -name "*repository_impl.dart"
show_largest "Model" "$LIB" -name "*_model.dart" -o -name "*_entity.dart"
show_largest "Widget" "$LIB" -name "*_widget.dart" -o -name "*_card.dart" -o -name "*_item.dart"
show_largest "UseCase" "$LIB" -name "*_usecase.dart" -o -name "*_use_case.dart"
show_largest "DataSource" "$LIB" -name "*_data_source.dart" -o -name "*_api.dart" -o -name "*_service.dart"
show_largest "Router" "$LIB" -name "*router*" -o -name "*route*"
show_largest "Test" "$PROJECT_PATH/test" -name "*_test.dart"
show_largest "Theme" "$LIB" -name "*theme*" -o -name "*style*"

# ── 10. CODING STYLE SIGNALS ─────────────────────────────────────
echo ""
echo "══════════════════════════════════════════"
echo "  CODING STYLE SIGNALS"
echo "══════════════════════════════════════════"

# Barrel exports
BARREL_COUNT=$(find "$LIB" -name "*.dart" -print0 2>/dev/null | xargs -0 grep -l "^export " 2>/dev/null | wc -l)
echo ""
echo "── BARREL EXPORTS ──"
echo "  Files with exports: $BARREL_COUNT"
if [ "$BARREL_COUNT" -gt 5 ]; then
  echo "  [HEAVY] Uses barrel exports extensively"
elif [ "$BARREL_COUNT" -gt 0 ]; then
  echo "  [LIGHT] Some barrel exports"
else
  echo "  [NONE] No barrel exports — direct imports"
fi

# final vs var vs explicit type
echo ""
echo "── VARIABLE DECLARATIONS ──"
FINAL_COUNT=$(grep -r "^\s*final " "$LIB" --include="*.dart" 2>/dev/null | grep -v "\.g\.dart" | grep -v "\.freezed\.dart" | wc -l)
VAR_COUNT=$(grep -r "^\s*var " "$LIB" --include="*.dart" 2>/dev/null | grep -v "\.g\.dart" | grep -v "\.freezed\.dart" | wc -l)
echo "  final declarations: $FINAL_COUNT"
echo "  var declarations:   $VAR_COUNT"
if [ "$FINAL_COUNT" -gt "$VAR_COUNT" ] && [ "$FINAL_COUNT" -gt 0 ]; then
  echo "  [IMMUTABLE-FIRST] Prefers final over var"
elif [ "$VAR_COUNT" -gt "$FINAL_COUNT" ] && [ "$VAR_COUNT" -gt 0 ]; then
  echo "  [MUTABLE] Prefers var over final"
fi

# const constructors
echo ""
echo "── CONST USAGE ──"
CONST_CONSTRUCTORS=$(grep -rE "const \w+\(" "$LIB" --include="*.dart" 2>/dev/null | grep -v "\.g\.dart" | grep -v "\.freezed\.dart" | wc -l)
echo "  const constructors: $CONST_CONSTRUCTORS"

# Trailing commas detection
echo ""
echo "── TRAILING COMMAS ──"
TRAILING_COMMAS=$(grep -r ",$" "$LIB" --include="*.dart" 2>/dev/null | grep -v "\.g\.dart" | grep -v "\.freezed\.dart" | wc -l)
echo "  Lines ending with comma: $TRAILING_COMMAS"
if [ "$TRAILING_COMMAS" -gt 50 ]; then
  echo "  [ENFORCED] Trailing commas used extensively (likely enforced by linter)"
elif [ "$TRAILING_COMMAS" -gt 10 ]; then
  echo "  [MODERATE] Some trailing commas"
else
  echo "  [RARE] Few trailing commas"
fi

# Extension methods
echo ""
echo "── EXTENSION METHODS ──"
EXTENSION_COUNT=$(grep -r "^extension " "$LIB" --include="*.dart" 2>/dev/null | grep -v "\.g\.dart" | wc -l)
echo "  extension declarations: $EXTENSION_COUNT"

# Cascade notation
echo ""
echo "── CASCADE NOTATION ──"
CASCADE_COUNT=$(grep -r "\.\." "$LIB" --include="*.dart" 2>/dev/null | grep -v "\.g\.dart" | grep -v "\.freezed\.dart" | grep -v "import " | grep -v "//" | wc -l)
echo "  Cascade usage (..) occurrences: $CASCADE_COUNT"

# Named parameters vs positional
echo ""
echo "── PARAMETER STYLE ──"
NAMED_PARAMS=$(grep -r "required " "$LIB" --include="*.dart" 2>/dev/null | grep -v "\.g\.dart" | grep -v "\.freezed\.dart" | wc -l)
echo "  required named params: $NAMED_PARAMS"

# part / part of usage
echo ""
echo "── PART DIRECTIVES ──"
PART_COUNT=$(grep -r "^part " "$LIB" --include="*.dart" 2>/dev/null | grep -v "\.g\.dart" | grep -v "\.freezed\.dart" | wc -l)
PART_OF_COUNT=$(grep -r "^part of " "$LIB" --include="*.dart" 2>/dev/null | grep -v "\.g\.dart" | grep -v "\.freezed\.dart" | wc -l)
echo "  part directives:    $PART_COUNT"
echo "  part of directives: $PART_OF_COUNT"

# Import organization
echo ""
echo "── IMPORT STYLE ──"
DART_IMPORTS=$(grep -r "^import 'dart:" "$LIB" --include="*.dart" 2>/dev/null | grep -v "\.g\.dart" | wc -l)
PACKAGE_IMPORTS=$(grep -r "^import 'package:" "$LIB" --include="*.dart" 2>/dev/null | grep -v "\.g\.dart" | wc -l)
RELATIVE_IMPORTS=$(grep -r "^import '\." "$LIB" --include="*.dart" 2>/dev/null | grep -v "\.g\.dart" | wc -l)
echo "  dart: imports:     $DART_IMPORTS"
echo "  package: imports:  $PACKAGE_IMPORTS"
echo "  relative imports:  $RELATIVE_IMPORTS"

# Doc comments vs inline
echo ""
echo "── COMMENT STYLE ──"
DOC_COMMENTS=$(grep -r "^\s*///" "$LIB" --include="*.dart" 2>/dev/null | grep -v "\.g\.dart" | grep -v "\.freezed\.dart" | wc -l)
INLINE_COMMENTS=$(grep -r "^\s*//" "$LIB" --include="*.dart" 2>/dev/null | grep -v "^\s*///" | grep -v "\.g\.dart" | grep -v "\.freezed\.dart" | wc -l)
echo "  /// doc comments:  $DOC_COMMENTS"
echo "  // inline comments: $INLINE_COMMENTS"

# Null safety patterns
echo ""
echo "── NULL SAFETY PATTERNS ──"
NULL_AWARE=$(grep -r "\?\." "$LIB" --include="*.dart" 2>/dev/null | grep -v "\.g\.dart" | grep -v "\.freezed\.dart" | wc -l)
BANG_OPERATOR=$(grep -r "[a-zA-Z]\!" "$LIB" --include="*.dart" 2>/dev/null | grep -v "\.g\.dart" | grep -v "\.freezed\.dart" | grep -v "!=" | wc -l)
LATE_KEYWORD=$(grep -r "^\s*late " "$LIB" --include="*.dart" 2>/dev/null | grep -v "\.g\.dart" | wc -l)
echo "  ?. (null-aware):   $NULL_AWARE"
echo "  ! (bang operator): $BANG_OPERATOR"
echo "  late keyword:      $LATE_KEYWORD"

# Dart 3+ features
echo ""
echo "── DART 3+ FEATURES ──"
SEALED_CLASSES=$(grep -r "^sealed class " "$LIB" --include="*.dart" 2>/dev/null | grep -v "\.g\.dart" | wc -l)
PATTERN_MATCH=$(grep -r "switch.*{" "$LIB" --include="*.dart" 2>/dev/null | grep -v "\.g\.dart" | wc -l)
RECORDS=$(grep -rE "\(\w+,\s*\w+\)" "$LIB" --include="*.dart" 2>/dev/null | grep -v "\.g\.dart" | wc -l)
echo "  sealed classes:      $SEALED_CLASSES"
echo "  switch expressions:  $PATTERN_MATCH"
echo "  records usage:       $RECORDS"

echo ""
echo "========================================="
echo "  SCAN COMPLETE"
echo "========================================="
echo ""
echo "  Next: Read 1-2 files per category above,"
echo "  following references/scan-checklist.md"
