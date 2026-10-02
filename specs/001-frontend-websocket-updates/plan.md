# Implementation Plan: 프런트엔드 작업 실행 진행률/로그 WebSocket 업데이트 활용

**Branch**: `001-frontend-websocket-updates` (현재 작업 브랜치는 `master`, 브랜치 생성 없음) | **Date**: 2026-10-01 | **Spec**: [spec.md](spec.md)

**Input**: [spec.md](spec.md)

## Summary

프런트엔드에는 진행률/로그 WebSocket(STOMP over SockJS) 구독 코드가 이미 있고 구독 주소도
qssb 계약과 일치한다. 따라서 신규 구현 없이 **기존 코드를 보완**한다.

1. 진행 정보 표시 보정: qssb의 크론 트리거는 `percentage = -1`을 보내므로 "대기 중"에 머무는
   현상을 수정하고, 이전/다음 실행 시각을 표시한다(FR-002/004/005).
2. 연결 상태 표시와 재연결 정책: 연결 상태(연결됨/재연결 중/끊김)를 노출하고, 재연결 간격을
   지수 백오프로 바꿔 인증 거부 시 200ms 무한 재시도를 막는다(FR-007/008/009).
3. 안전성: 메시지 파싱 오류 격리, 로그 목록 키 중복 방지(FR-003/010).

서버(qssb)는 수정하지 않는다. 변경 내역은 `spec-001-changelog.md`에 기록한다(FR-012).

## Technical Context

**Language/Version**: TypeScript 5.9.3, Angular 21.2.12 (기존 그대로)

**Primary Dependencies**: `@stomp/rx-stomp` 2.4.0(→ `@stomp/stompjs` 7.3.0), `sockjs-client`, `rxjs` 7.8 — 신규 의존성 추가 없음

**Storage**: N/A

**Testing**: Jest 30 (`npm test`, 기존 `*.spec.ts` 패턴: `RxStomp.prototype.configure/activate` 스파이)

**Target Platform**: 브라우저(관리 콘솔 SPA). 서버 qssb가 `/quartz-manager-ui/`로 서빙하고 `/quartz-manager/{progress,logs}`에서 SockJS 제공

**Project Type**: web-application (frontend 수정만, backend 참조 전용)

**Performance Goals**: 작업 실행 후 3초 이내 로그 표시(SC-001) — 서버 발행 직후 수신이므로 추가 처리 없음

**Constraints**: 최소 수정(헌법 III), qssb 읽기 전용(IV), 한글 문서(I), 기존 REST/화면 동작 비회귀(SC-006)

**Scale/Scope**: 수정 대상 5~7개 파일(서비스 2, 공용 베이스 1, 컴포넌트 1~2, 템플릿 1, 스펙 파일)

## Constitution Check

*GATE: Phase 0 전 통과 필요, Phase 1 후 재평가.*

| 원칙 | 판정 | 근거 |
|------|------|------|
| I. 한글 우선 | 통과 | 모든 산출물 한글 |
| II. 범위 한정 | 통과 | WebSocket 진행률/로그 관련 파일만 수정 |
| III. 최소 수정 | 통과 | 신규 모듈·의존성 없음, 기존 `RxStompService`/`manager.component` 보완만 |
| IV. qssb 기준 | 통과 | qssb `ConsoleSecurityConfig`, `011` 계약 확인(research.md 결정 1), qssb 미수정 |
| V. Changelog | 통과 예정 | 구현 시 `spec-001-changelog.md` 작성(tasks에 포함) |

Phase 1 설계 후 재평가: 위반 없음. Complexity Tracking 항목 없음.

## Project Structure

### Documentation (this feature)

```text
specs/001-frontend-websocket-updates/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/websocket-client.md
├── checklists/requirements.md
└── tasks.md                          # /speckit-tasks 에서 생성
spec-001-changelog.md                  # 구현 시 작성 (저장소 루트 또는 spec 디렉터리 — tasks에서 확정)
```

### Source Code (repository root)

```text
quartz-manager-frontend/src/app/
├── services/
│   ├── rx-stomp.service.ts                 # 수정: 연결 상태 노출(connectionState$ 기반)
│   ├── progress.rx-websocket.service.ts    # 수정: 재연결 백오프 설정
│   ├── logs.rx-websocket.service.ts        # 수정: 재연결 백오프 설정
│   └── *.rx-websocket.service.spec.ts      # 수정: 설정 값 검증 갱신
├── views/manager/
│   ├── manager.component.ts                # 수정: 진행 라벨/파싱 오류 격리/연결 상태/로그 키
│   ├── manager.component.html              # 수정: 연결 상태 칩, 진행 표시, @for track 키
│   └── manager.component.spec.ts           # (존재 시) 진행 표시 케이스 추가
└── model/trigger-fired-bundle.model.ts     # 변경 없음
```

**Structure Decision**: 기존 `quartz-manager-frontend` 단일 프로젝트 구조를 유지한다. `progress-panel`/
`logs-panel` 컴포넌트는 별도 사용처가 있으므로 동일한 퍼센트 처리 보정만 필요한지 구현 시 확인한다.

## Complexity Tracking

위반 없음.
