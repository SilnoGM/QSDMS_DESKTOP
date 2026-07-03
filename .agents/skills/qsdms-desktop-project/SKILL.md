---
name: qsdms-desktop-project
description: Use when working in the QSDMS_DESKTOP repository, especially Flutter desktop frontend code, GetX routes/controllers, NestJS backend contracts, Chinese visible UI text, desktop responsive layout, project docs, verification, or repo-specific implementation decisions.
---

# QSDMS Desktop Project

## Overview

Use this skill as the project-specific entry point before applying the generic Flutter or Dart skills. It keeps agent work aligned with this repository's real roots, language rules, verification commands, and safety boundaries.

## Truth Sources

Read only the relevant files for the task:

- Overall stack, contracts, quality rules: `docs/技术栈规范文档.md`
- Desktop responsive and adaptive layout rules: `docs/响应式设计方案.md`
- Flutter frontend structure and commands: `frontend/README.md`
- Backend structure, API notes, and commands: `backend/README.md`
- Current dependencies: `frontend/pubspec.yaml` and `backend/package.json`

## Repository Rules

- Treat the repository root as the coordination workspace; the real Flutter app root is `frontend/`, and the real NestJS backend root is `backend/`.
- Preserve existing user changes. Check `git status --short --branch --untracked-files=all` before staging, and stage only files belonging to the current task.
- Keep user-visible desktop UI copy in Chinese. Keep commands, paths, API strings, route names, DTO fields, package names, variables, logs, and error codes in English.
- Build Flutter pages for a desktop-first enterprise workbench: dense tables, filters, forms, master-detail workflows, hover/focus states, keyboard-friendly interactions, and stable `1280 x 800` minimum-window behavior.
- Use `GetX` for route registration, controller state, and dependency injection. Keep complex business orchestration out of widgets; place API access in services or repositories.
- Treat backend DTOs and OpenAPI output as the frontend contract source. Do not change public APIs, data structures, database schema, or delete files without explicit user confirmation.
- Never commit `.env`, hardcode secrets, or log passwords, tokens, database URLs, or private user data.

## Official Skill Routing

Prefer the installed official skills for specialized work:

- Flutter widget tests: `flutter-add-widget-test`
- Flutter integration tests: `flutter-add-integration-test`
- Responsive Flutter layout: `flutter-build-responsive-layout`
- Flutter layout debugging: `flutter-fix-layout-issues`
- Flutter architecture review: `flutter-apply-architecture-best-practices`
- JSON models/code generation: `flutter-implement-json-serialization`
- Declarative routing: `flutter-setup-declarative-routing`
- Localization: `flutter-setup-localization`
- HTTP client work: `flutter-use-http-package`
- Dart unit tests, static analysis, coverage, mocks, package conflicts, runtime errors, and pattern matching: use the matching `dart-*` skill.

Only use FFI/native-asset skills such as `dart-setup-ffi-assets` or `dart-use-ffigen` when the task explicitly involves C/C++ interop, native assets, or FFI.

## Verification Commands

Run commands from the correct subdirectory and report failures exactly.

Frontend changes:

```bash
cd frontend
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

Desktop runtime or packaging changes:

```bash
cd frontend
flutter build macos
flutter run -d macos
```

Backend changes:

```bash
cd backend
pnpm test
pnpm test:e2e
pnpm build
```

Prisma changes also need:

```bash
cd backend
pnpm prisma:generate
```

Skills-only changes:

```bash
npx -y skills list --json
python3 -c 'from pathlib import Path; import re; text = Path(".agents/skills/qsdms-desktop-project/SKILL.md").read_text(); assert re.match(r"^---\n(?s:.*?)\n---", text); assert "name: qsdms-desktop-project" in text; assert "description:" in text'
git diff --check -- .agents/skills/qsdms-desktop-project skills-lock.json docs/agent-skills配置说明.md
```

The imported official Flutter and Dart skill files are vendor content; do not rewrite them just to satisfy whitespace checks unless the user explicitly approves normalizing third-party skill files.

## Commit Boundary

Use a narrow commit for the current task. Commit messages must use an English type and Chinese description, for example `chore: 配置项目级 Flutter agent skills`.
