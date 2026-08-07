# Hermes Desktop 한국어 번역

[![Verify localization](https://github.com/Bum-Boo/hermes-desktop-korean/actions/workflows/verify.yml/badge.svg)](https://github.com/Bum-Boo/hermes-desktop-korean/actions/workflows/verify.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Upstream](https://img.shields.io/badge/upstream-NousResearch%2Fhermes--agent-2563eb)](https://github.com/NousResearch/hermes-agent)

[English](README.en.md) | **한국어**

Nous Research의 **Hermes Desktop**을 위한 비공식 한국어 현지화 프로젝트입니다. 화면에 노출되는 전체 번역 카탈로그와 안전한 적용 스크립트, 업스트림 호환성 검증 도구를 함께 제공합니다.

## 특징

- Desktop 번역 인터페이스 전체를 자연스러운 한국어 UI 문구로 번역
- `ko`, `ko-KR`, `한국어` 언어 별칭 지원
- 원본 키 누락과 TypeScript 타입 오류를 자동 검사
- 정확한 원문 블록만 수정하는 멱등성 PowerShell 적용 스크립트
- 특정 업스트림 커밋을 고정하여 재현 가능한 검증 제공

현재 자동 검증 기준으로 번역 경로 **2,846/2,846**, 설정 필드 이름 **127/127**, 설정 설명 **43/43**을 충족하며 TypeScript 진단은 **0건**입니다.

## 빠른 적용

요구 사항은 Git, Node.js 22.22 이상, npm, Windows PowerShell 5.1 이상입니다. 다른 운영체제에서는 PowerShell 7의 `pwsh`를 사용할 수 있습니다.

```powershell
git clone https://github.com/NousResearch/hermes-agent.git
git clone https://github.com/Bum-Boo/hermes-desktop-korean.git

powershell -NoProfile -File .\hermes-desktop-korean\scripts\apply-localization.ps1 `
  -HermesRepo .\hermes-agent
```

적용 전 변경 대상을 미리 확인하려면 `-WhatIf`를 붙입니다.

```powershell
powershell -NoProfile -File .\hermes-desktop-korean\scripts\apply-localization.ps1 `
  -HermesRepo .\hermes-agent `
  -WhatIf
```

그다음 공식 저장소 루트에서 Desktop 의존성을 설치하고 검증·빌드합니다.

```powershell
cd .\hermes-agent
npm run install:desktop
npm run typecheck --workspace apps/desktop
npm run dist:win --workspace apps/desktop
```

빌드 후 Hermes 설정의 언어 선택기에서 **한국어**를 선택할 수 있습니다.

> 이 저장소는 출처를 확인할 수 없는 실행 파일을 배포하지 않습니다. 번역을 공식 소스에 적용해 직접 빌드하는 방식을 사용합니다.

## 번역 검증

```powershell
npm ci
npm test
```

검증기는 고정된 업스트림 소스와 다음 항목을 대조합니다.

1. 영어 카탈로그의 모든 객체 경로가 한국어 카탈로그에 존재하는지 확인
2. 설정 필드 이름과 설명의 세부 키가 모두 번역되었는지 확인
3. 최신 `Translations` 계약에 대해 TypeScript 진단이 0건인지 확인
4. 검증에 사용한 Hermes Agent 커밋을 출력

이미 내려받은 업스트림 저장소를 사용하면 네트워크 없이도 검사할 수 있습니다.

```powershell
npm run verify -- --upstream C:\path\to\hermes-agent
```

## 저장소 구조

```text
src/i18n/ko.ts                  한국어 번역 카탈로그
scripts/apply-localization.ps1  공식 소스에 번역을 등록하는 스크립트
scripts/verify-localization.mjs 번역 키·타입 검증기
upstream-lock.json              검증 기준 업스트림 커밋
.github/workflows/verify.yml    지속적 통합 검사
```

## 번역 원칙

- 짧고 바로 이해되는 데스크톱 UI 문장을 사용합니다.
- 제품명과 표준 기술 용어는 유지하고, 동작과 설명은 한국어로 번역합니다.
- 템플릿 변수와 함수 매개변수는 원문 계약을 그대로 보존합니다.
- 새 업스트림 키가 추가되면 CI가 누락을 감지하도록 구성했습니다.

자세한 참여 방법은 [CONTRIBUTING.md](CONTRIBUTING.md)를 참고하세요.

## 기준 버전

현재 번역은 [`NousResearch/hermes-agent`](https://github.com/NousResearch/hermes-agent)의 `upstream-lock.json`에 기록된 커밋을 기준으로 검증합니다. 기준 커밋 변경은 번역 키 검토와 함께 별도 커밋으로 관리합니다.

## 라이선스 및 고지

이 프로젝트는 [MIT License](LICENSE)로 배포됩니다. 원본 Hermes Agent 역시 MIT 라이선스이며, Hermes 및 관련 상표는 각 권리자에게 있습니다. 이 저장소는 Nous Research의 공식 배포판이 아닌 독립적인 커뮤니티 현지화입니다.
