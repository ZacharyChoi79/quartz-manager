# Implementation Plan: WebSocket 메시지 기반 화면 갱신 (최소 수정)

**Branch**: `002-websocket-ui-refresh` (실제 브랜치는 `master`, 브랜치 생성 없음) | **Date**: 2026-10-02 | **Spec**: [spec.md](spec.md)

**Input**: [spec.md](spec.md)

## Summary

WebSocket 연결과 메시지 수신은 이미 정상이다. 화면이 갱신되지 않는 원인은 수신한 진행 정보(`nextFireTime`,
`previousFireTime`, `percentage`)를 화면 요소가 쓰지 않는 것이다. 수정은 **단일 컴포넌트**
(`manager.component.ts`/`.html`)에 한정하고 다음만 한다.

1. 진행 정보 수신 시 `triggerDetailsByName`(및 `selectedTrigger`)의 `nextFireTime`/`previousFireTime`을
   갱신하는 private 메서드 1개 추가 → 5개 화면 위치가 모두 갱신됨(US1).
2. 진행 라벨/퍼센트 표시가 `percentage < 0`일 때 시각 정보를 보여 주도록 보정(US2).
3. 목록의 모든 트리거에 대해 진행 토픽을 구독(US3)하는 private 메서드 1개 추가.

서비스, 모델, 모듈, 스타일, 다른 컴포넌트, 의존성, 서버(qssb)는 변경하지 않는다.

## Technical Context

**Language/Version**: TypeScript 5.9.3, Angular 21.2.12 (기존 그대로)

**Primary Dependencies**: `@stomp/rx-stomp` 2.4.0 등 기존 의존성 — 변경/추가 없음

**Storage**: N/A

**Testing**: Jest 30 — 기존 `npm test`로 회귀 확인. `manager.component`는 기존 spec이 없고 의존성이 많아 신규 spec은 추가하지 않음(research 결정 6)

**Target Platform**: 브라우저 SPA(qssb가 `quartz-manager-starter-ui` jar로 서빙)

**Project Type**: web-application (frontend 수정만, qssb 참조 전용)

**Performance Goals**: 실행 후 3초 이내 반영(SC-001) — 수신 즉시 반영이므로 추가 비용 없음

**Constraints**: FR-008/009 변경 금지 목록 준수, 최소 수정(헌법 III·VI), 한글 문서(I)

**Scale/Scope**: 파일 2개 수정(`manager.component.ts`, `manager.component.html`), 변경 기록 1개

## Constitution Check

| 원칙 | 판정 | 근거 |
|------|------|------|
| I. 한글 우선 | 통과 | 산출물 한글 |
| II. 범위 한정 | 통과 | WebSocket 메시지 화면 갱신 외 수정 없음 |
| III. 최소 수정 | 통과 | 신규 파일/의존성/서비스 변경 없음, 기존 컴포넌트 2파일만 수정 |
| IV. qssb 기준 | 통과 | 진행 정보 구조·발행 시점은 qssb `011` 계약 기준, qssb 미수정 |
| V. Changelog | 통과 예정 | `spec-002-changelog.md` 작성 |
| VI. 갱신 가능 요소 전체 갱신 | 통과(정정 필요 1건) | US1~US3로 대상 요소 전부 포함. 단 헌법 표의 "Triggers 페이지 상세 Previous fire"는 실제 화면에 해당 요소가 없음(아래 정정 사항) |

**정정 사항**: 헌법 v1.1.0 원칙 VI 표는 "Triggers 페이지 상세의 Previous fire"를 갱신 대상으로 적었으나,
코드 확인 결과(`manager.component.html` 225~236행) 해당 요소는 존재하지 않는다. 표시 요소를 새로 추가하면
최소 수정 원칙(III)과 충돌하므로 요소를 추가하지 않고 spec에서 제외했다. 헌법 표는 `/speckit-constitution`
으로 PATCH(1.1.1) 정정할 것을 권한다.

Phase 1 설계 후 재평가: 위반 없음. Complexity Tracking 항목 없음.

## Project Structure

### Documentation (this feature)

```text
specs/002-websocket-ui-refresh/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/ui-refresh-contract.md
├── checklists/requirements.md
├── tasks.md                      # /speckit-tasks 에서 생성
└── spec-002-changelog.md         # 구현 시 작성 (헌법 V)
```

### Source Code (repository root)

```text
quartz-manager-frontend/src/app/views/manager/
├── manager.component.ts      # 수정: 갱신 메서드 추가, 구독 연결, 진행 라벨 보정
└── manager.component.html    # 수정: Previous fire 고정 문구 → 값, Current progress 표시 보정
```

**Structure Decision**: 변경 파일을 위 2개로 고정한다. 아래 파일은 **수정 금지**(FR-009): `services/*`
(`rx-stomp`, `progress.rx-websocket`, `logs.rx-websocket` 및 spec), `model/*`, `app.module.ts`,
`components/progress-panel/*`, `components/logs-panel/*`, `*.scss`, `package*.json`, 빌드/테스트 설정.

## Complexity Tracking

위반 없음.
