---

description: "프런트엔드 작업 실행 진행률/로그 WebSocket 업데이트 활용 — 작업 목록"
---

# Tasks: 프런트엔드 작업 실행 진행률/로그 WebSocket 업데이트 활용

**Input**: `/specs/001-frontend-websocket-updates/` 의 plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Prerequisites**: plan.md, spec.md (모두 존재)

**Tests**: spec에서 TDD를 요구하지 않았다. 다만 설정 값이 바뀌는 기존 서비스 spec 2개는 깨지지 않도록 갱신한다(해당 작업에 포함).

**Organization**: 사용자 스토리별로 묶는다. 모든 변경은 `quartz-manager-frontend/src/app/` 이하이며 qssb는 수정하지 않는다(헌법 IV).

## Format: `[ID] [P?] [Story] Description`

## Path Conventions

- 프런트엔드: `quartz-manager-frontend/src/app/` (이하 `APP/`)
- 변경 기록: `specs/001-frontend-websocket-updates/spec-001-changelog.md`

## Phase 1: Setup

- [ ] T001 `quartz-manager-frontend`에서 `npm ci` 실행 후 `npm test`로 기준선(변경 전 통과 여부) 기록
- [ ] T002 `specs/001-frontend-websocket-updates/spec-001-changelog.md` 뼈대(한글, "변경 파일 목록"/"compare" 섹션) 생성

## Phase 2: Foundational (모든 스토리의 선행 조건)

**⚠️ 이 단계 완료 전에는 사용자 스토리 작업을 시작하지 않는다.**

- [ ] T003 `APP/views/manager/manager.component.ts` 에 `ConsoleLogRecord`에 수신 순번 키(`id: number`)를 추가하고 `addLogRecord`에서 부여 (US1·US2 공통 기반, research 결정 4)
- [ ] T004 `APP/views/manager/manager.component.ts` 에 JSON 파싱 실패를 격리하는 private 헬퍼(`parseMessage(msg)`: 실패 시 `null` 반환, 콘솔 경고)를 추가 (research 결정 4, FR-010)

**Checkpoint**: 공통 기반 준비 완료

## Phase 3: User Story 1 - 작업 실행 로그를 새로고침 없이 확인 (Priority: P1) 🎯 MVP

**Goal**: 선택된 트리거의 로그가 실시간으로 목록에 표시되고, 파싱 오류에도 구독이 유지된다.

**Independent Test**: quickstart 2-1, 2-3 — 트리거 선택 후 즉시 실행 시 새로고침 없이 로그 표시, 최대 50건 유지.

- [ ] T005 [US1] `APP/views/manager/manager.component.ts` 의 `subscribeToTriggerTopics` 로그 구독에서 `JSON.parse` 대신 `parseMessage`를 사용하고 `null`은 `filter`로 건너뛰기 (FR-001, FR-010)
- [ ] T006 [US1] `APP/views/manager/manager.component.html` 의 Event Stream `@for (log of logs; track log.time)`을 `track log.id`로 변경 (FR-003, 키 중복 방지)
- [ ] T007 [US1] `APP/views/manager/manager.component.ts` 의 `addLogRecord`가 최대 50건 유지(`slice(0, 50)`)와 `id` 증가를 함께 보장하는지 확인·정리 (FR-003)

**Checkpoint**: US1 단독으로 로그 실시간 표시 검증 가능

## Phase 4: User Story 2 - 진행 정보를 새로고침 없이 확인 (Priority: P1)

**Goal**: 진행 메시지 수신 시 "대기 중"이 해소되고, 유효하지 않은 퍼센트(-1%)가 노출되지 않는다.

**Independent Test**: quickstart 2-2 — 크론 트리거 즉시 실행 후 진행 영역에 이전/다음 실행 시각 표시, `-1%` 미노출.

- [ ] T008 [US2] `APP/views/manager/manager.component.ts` 의 진행 구독에서 `parseMessage` 사용 및 `null` 건너뛰기 (FR-002, FR-010)
- [ ] T009 [US2] `APP/views/manager/manager.component.ts` 의 `getProgressLabel()`을 수정: `progress` 없음 → `Waiting for progress events`, `percentage >= 0` → `N% / M fired`, 그 외 → `Last fired: {previousFireTime} · Next: {nextFireTime}` (`formatDateTime` 재사용, 값 없으면 `-`) (FR-004, FR-005)
- [ ] T010 [US2] `APP/views/manager/manager.component.html` 의 "Execution Load" 카드 `Current progress` 필드(`{{ getProgressPercentage() }}%`)를 `progress`가 있고 퍼센트가 유효할 때만 `%`를 표시하고 아니면 `-` 표시하도록 수정 (FR-004)

- [ ] T023 [US2] `APP/views/manager/manager.component.ts` 의 진행 구독 처리에서, 수신한 `progress`의 `nextFireTime`/`previousFireTime`을 `triggerDetailsByName[getTriggerDetailKey(selectedTriggerKey)]`와 `selectedTrigger`에 반영하는 private 메서드 `applyProgressToTrigger(progress)`를 추가하고 T008의 구독 콜백에서 호출 (FR-013, 근본 원인: Next fire는 REST 조회 결과만 표시하고 WebSocket 메시지는 `progress`에만 저장됨)
- [ ] T024 [US2] 수신 값이 `null`이거나 유효하지 않은 날짜일 때는 기존 `nextFireTime`을 덮어쓰지 않도록 방어 조건 추가 (`APP/views/manager/manager.component.ts`, FR-013)

**Checkpoint**: US1 + US2 로 핵심 실시간 기능 완성(MVP 범위)

## Phase 5: User Story 3 - 연결 상태 파악과 자동 복구 (Priority: P2)

**Goal**: 연결 상태 표시, 지수 백오프 재연결, 연결 실패 안내.

**Independent Test**: quickstart 2-4, 2-5 — 서버 재기동 시 상태가 재연결 중→연결됨, 세션 없음 시 연결 실패 안내와 재시도 간격 증가.

- [ ] T011 [P] [US3] `APP/services/progress.rx-websocket.service.ts` 의 설정을 `reconnectDelay: 200` 유지 + `reconnectTimeMode: ReconnectionTimeMode.EXPONENTIAL` + `maxReconnectDelay: 30000`으로 변경 (`@stomp/stompjs`에서 import) (FR-008, FR-009)
- [ ] T012 [P] [US3] `APP/services/logs.rx-websocket.service.ts` 에 T011과 동일한 재연결 설정 적용 (FR-008, FR-009)
- [ ] T013 [P] [US3] `APP/services/progress.rx-websocket.service.spec.ts` 의 설정 검증에 `reconnectTimeMode`, `maxReconnectDelay` 기대값 추가 (기존 `reconnectDelay` 200 검증 유지)
- [ ] T014 [P] [US3] `APP/services/logs.rx-websocket.service.spec.ts` 에 T013과 동일한 검증 추가
- [ ] T015 [US3] `APP/views/manager/manager.component.ts` 에 두 서비스의 `connectionState$`(RxStompState)를 구독해 `realtimeStatus: 'CONNECTED' | 'RECONNECTING' | 'FAILED'`를 계산(한 번도 OPEN 되지 못한 CLOSED가 5회 반복되면 FAILED, 두 채널 중 하나라도 비정상이면 비정상)하고 `ngOnDestroy`에서 해제 (FR-007, FR-009, data-model 연결 상태)
- [ ] T016 [US3] `APP/views/manager/manager.component.html` 의 Event Stream 툴바 정적 `STREAMING` 칩을 `realtimeStatus` 기반 칩(연결됨/재연결 중/연결 실패 — 로그인/세션 확인)으로 교체 (FR-007, FR-009)

**Checkpoint**: US3 독립 검증 가능

## Phase 6: User Story 4 - 트리거 전환 시 구독 정리 (Priority: P2)

**Goal**: 트리거 전환/해제/화면 이탈 시 이전 구독 해제와 표시 초기화.

**Independent Test**: quickstart 2-3 — A→B→해제 반복 시 다른 트리거 메시지가 섞이지 않음.

- [ ] T017 [US4] `APP/views/manager/manager.component.ts` 에서 트리거 선택 해제/삭제(unschedule) 경로가 `unsubscribeFromTriggerTopics()`를 호출하고 `logs`/`progress`를 초기화하는지 확인하고 누락된 경로에 추가 (FR-006)
- [ ] T018 [US4] `APP/views/manager/manager.component.ts` 의 `subscribeToTriggerTopics`가 같은 트리거 재선택 시 중복 구독을 만들지 않는지 확인하고 필요 시 동일 이름 조기 반환 추가 (FR-006)

**Checkpoint**: 모든 스토리 완료

## Phase 7: Polish & Cross-Cutting

- [ ] T019 `quartz-manager-frontend`에서 `npm test` 및 `npm run build` 실행, 실패 시 수정 (SC-006)
- [ ] T020 quickstart.md 2번 수동 시나리오 1~6을 qssb 연동 환경에서 수행하고 결과를 `spec-001-changelog.md`에 기록
- [ ] T021 `specs/001-frontend-websocket-updates/spec-001-changelog.md` 를 완성: 변경 파일 목록과 각 파일의 compare(`git diff` 요약, 한글 설명) 기록, 비밀 정보 미포함 확인 (헌법 V, FR-012)
- [ ] T025 확인 완료 사실 기록: qssb가 서빙하는 `quartz-manager-starter-ui` 5.0.1 번들은 이 소스와 동일(구독 코드 포함), 브라우저에서 `/progress`·`/logs` WebSocket 101 및 STOMP 메시지 수신 확인, nginx에서 WebSocket 업그레이드가 안 되는 환경은 코드 밖 이슈로 `spec-001-changelog.md`에 안내만 기록
- [ ] T022 `APP/components/progress-panel`, `APP/components/logs-panel` 은 어떤 템플릿에서도 사용되지 않음을 확인했으므로 **수정 제외**함을 changelog에 명시 (헌법 II·III)

## Dependencies & Execution Order

- Phase 1 → Phase 2 → (US1, US2, US3, US4) → Phase 7
- US1·US2는 같은 파일(`manager.component.ts`)을 수정하므로 순차(US1 → US2) 진행
- US3는 서비스 파일 수정(T011~T014)이 독립이라 US1/US2와 병행 가능, 단 T015/T016은 `manager.component.*`를 수정하므로 US1·US2 이후 진행
- US4는 `manager.component.ts` 순차 작업, US2 이후

### Parallel Opportunities

- T011 ∥ T012 ∥ T013 ∥ T014 (서로 다른 파일)
- US3의 서비스 작업(T011~T014)은 US1/US2와 병행 가능

## Implementation Strategy

- **MVP**: Phase 1~2 + US1 + US2 (실시간 로그·진행 표시). 여기서 중단해도 사용자 가치가 있다.
- **이후**: US3(신뢰성) → US4(정리) → Polish.
- 각 스토리 완료 시 changelog에 변경 파일/compare를 즉시 누적 기록한다(헌법 V).

## Notes

- 서버(qssb) 수정 금지, 신규 의존성 추가 금지(헌법 III·IV).
- `?access_token=` 쿼리와 기존 `reconnectDelay: 200` 초기값은 유지한다(research 결정 1·3).
