# Implementation Plan: 폐쇄망 대응 — 아이콘 폰트 자체 호스팅

**Branch**: `003-offline-material-icons` (실제 브랜치는 `master`, 브랜치 생성 없음) | **Date**: 2026-10-07 | **Spec**: [spec.md](spec.md)

**Input**: [spec.md](spec.md)

## Summary

화면이 자동으로 외부에서 가져오는 자원은 Material Icons 폰트 하나뿐이다. 이를 저장소 안으로 옮겨(자체 호스팅)
폐쇄망 운영과 외부 접속 없는 빌드를 동시에 보장한다. 변경은 **파일 3개**로 고정한다.

1. `src/assets/fonts/material-icons/material-icons.woff2` (신규, 128,352 bytes)
2. `src/assets/fonts/material-icons/material-icons.css` (신규, `@font-face` + `.material-icons`)
3. `src/index.html` (외부 링크 1줄을 로컬 CSS 링크로 교체)

**사전 검증(스파이크, 2026-10-07)**: 임시 복사본(`/tmp`, 저장소 미변경)에서 확인했다.
- 통제 실험: 원본 `index.html` + 죽은 프록시(`127.0.0.1:9`) → `Inlining of fonts failed ... ECONNREFUSED`로 빌드 **실패**
  (현재 Windows 오류를 재현).
- 변경본 + 같은 죽은 프록시 → 빌드 **성공**, `dist`에서 `googleapis|gstatic` 참조 **0개 파일**, `preconnect` 0건,
  `dist/assets/fonts/material-icons/`에 두 자원이 복사됨.

## Technical Context

**Language/Version**: Angular 21.2 / TypeScript 5.9 (코드 변경 없음, 정적 자원과 HTML 1줄)

**Primary Dependencies**: 변경 없음(신규 의존성 없음)

**Storage**: N/A

**Testing**: `npm test`(회귀), 외부 접속 차단 상태의 `ng build`, `dist` 검색 검증

**Target Platform**: 폐쇄망 브라우저(최신, woff2 지원). 자원은 qssb가 webjar(`/quartz-manager-ui/`)로 서빙

**Project Type**: web-application (frontend 정적 자원만 변경)

**Performance Goals**: 해당 없음(폰트 128KB, 동일 오리진 제공)

**Constraints**: FR-007/008 변경 범위 고정, 헌법 III·VII, 한글 문서(I)

**Scale/Scope**: 파일 3개 + changelog 1개

## Constitution Check

| 원칙 | 판정 | 근거 |
|------|------|------|
| I. 한글 우선 | 통과 | 산출물 한글 |
| II. 범위 한정 | 통과(분리 규정 준수) | WebSocket 기능(spec 002)과 별도 spec 003 으로 분리. 원칙 VII 이 이 분리를 요구 |
| III. 최소 수정 | 통과(예외 근거 기록) | 변경 3개, 폐쇄망 요건(원칙 VII)을 근거로 한 예외를 changelog 에 기록 |
| IV. qssb 기준 | 해당 없음 | qssb 미변경 |
| V. Changelog | 통과 예정 | `spec-003-changelog.md` 작성 |
| VI. WebSocket 갱신 | 해당 없음 | `manager.component.*` 미변경(FR-008) |
| VII. 폐쇄망 | 통과 | 외부 자동 로드 0건 달성이 이 spec 의 목표, 스파이크로 가능성 확인 |

Phase 1 설계 후 재평가: 위반 없음. Complexity Tracking 항목 없음.

## Project Structure

### Documentation (this feature)

```text
specs/003-offline-material-icons/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/asset-contract.md
├── checklists/requirements.md
├── tasks.md                         # /speckit-tasks 에서 생성
└── spec-003-changelog.md            # 구현 시 작성 (헌법 V)
```

### Source Code (repository root)

```text
quartz-manager-frontend/src/
├── index.html                                         # 수정: 외부 링크 1줄 → 로컬 CSS 링크
└── assets/fonts/material-icons/
    ├── material-icons.woff2                           # 신규
    └── material-icons.css                             # 신규
```

**Structure Decision**: 기존 `src/assets`(이미 빌드 자산으로 포함됨, `angular.json`의 `assets` 항목)를 그대로 사용한다.
수정 금지(FR-008): `angular.json`, `package*.json`, 빌드·테스트 설정, 컴포넌트·서비스·모델, `src/styles.css`,
Roboto 설정, `manager.component.*`.

## Complexity Tracking

위반 없음.
