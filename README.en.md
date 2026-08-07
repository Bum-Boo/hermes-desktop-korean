# Korean localization for Hermes Desktop

[![Verify localization](https://github.com/Bum-Boo/hermes-desktop-korean/actions/workflows/verify.yml/badge.svg)](https://github.com/Bum-Boo/hermes-desktop-korean/actions/workflows/verify.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Upstream](https://img.shields.io/badge/upstream-NousResearch%2Fhermes--agent-2563eb)](https://github.com/NousResearch/hermes-agent)

**English** | [한국어](README.md)

An unofficial, source-based Korean localization for **Hermes Desktop** by Nous Research. It ships the complete Korean catalog, a cautious integration script, and reproducible compatibility checks.

## Highlights

- Korean copy for the complete Desktop translation contract
- Locale aliases for `ko`, `ko-KR`, and `한국어`
- Automated key coverage and TypeScript compatibility checks
- Idempotent PowerShell integration that only edits expected upstream blocks
- Validation pinned to an explicit upstream commit

Current automated coverage: **2,846/2,846** translation paths, **127/127** Settings label paths, **43/43** Settings description paths, and **0** TypeScript diagnostics.

## Quick start

Requirements: Git, Node.js 22.22 or newer, npm, and Windows PowerShell 5.1 or newer. On other platforms, use PowerShell 7 (`pwsh`).

```powershell
git clone https://github.com/NousResearch/hermes-agent.git
git clone https://github.com/Bum-Boo/hermes-desktop-korean.git

powershell -NoProfile -File .\hermes-desktop-korean\scripts\apply-localization.ps1 `
  -HermesRepo .\hermes-agent
```

Add `-WhatIf` to preview the target without changing files. Then install, validate, and build from the upstream repository root:

```powershell
cd .\hermes-agent
npm run install:desktop
npm run typecheck --workspace apps/desktop
npm run dist:win --workspace apps/desktop
```

The language picker will expose **한국어** in the resulting Desktop build.

> This repository does not distribute opaque, unofficial binaries. The localization is applied to auditable upstream source and built locally.

## Verification

```powershell
npm ci
npm test
```

The verifier checks full translation-path coverage, Settings field-copy coverage, TypeScript compatibility, and the exact upstream revision. To use an existing checkout without fetching raw sources:

```powershell
npm run verify -- --upstream C:\path\to\hermes-agent
```

## Project layout

```text
src/i18n/ko.ts                  Korean translation catalog
scripts/apply-localization.ps1  Safe upstream integration script
scripts/verify-localization.mjs Coverage and type verifier
upstream-lock.json              Pinned upstream revision
.github/workflows/verify.yml    Continuous verification
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for terminology and contribution rules.

## License and attribution

Released under the [MIT License](LICENSE). Hermes Agent is also MIT-licensed. Hermes and related trademarks belong to their respective owners. This project is an independent community localization and is not an official Nous Research release.
