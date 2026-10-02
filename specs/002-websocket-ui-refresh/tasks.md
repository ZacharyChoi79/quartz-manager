---

description: "WebSocket 메시지 기반 화면 갱신 (최소 수정) — 작업 목록"
---

# Tasks: WebSocket 메시지 기반 화면 갱신 (최소 수정)

**Input**: `/specs/002-websocket-ui-refresh/` 의 plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Prerequisites**: plan.md, spec.md (존재). 헌법 v1.1.1 준수.

**Tests**: spec에서 요청하지 않았고 `manager.component`에 기존 spec이 없어 신규 테스트 파일은 만들지 않는다(research 결정 6). 기존 `npm test`로 회귀만 확인한다.

**Organization**: 사용자 스토리별로 묶는다.

## ⛔ 수정 허용 범위 (FR-008/009 — 위반 시 작업 중단)

수정 가능한 파일은 **이 3개뿐**이다.
- `quartz-manager-frontend/src/app/views/manager/manager.component.ts`
- `quartz-manager-frontend/src/app/views/manager/manager.component.html`
- `specs/002-websocket-ui-refresh/spec-002-changelog.md` (신규, 문서)

그 외 파일(`services/*`, `model/*`, `app.module.ts`, `progress-panel`, `logs-panel`, `*.scss`, `package*.json`, 빌드·테스트 설정, qssb, nginx)은 **수정 금지**. 포맷 일괄 변경, 미사용 코드 정리, 리네임, import 정리 등 목적 외 변경도 금지한다.

## Format: `[ID] [P?] [Story] Description`

- 같은 두 파일을 순서대로 수정하므로 **[P] 병렬 작업은 없다**.
- 약칭: `TS` = `quartz-manager-frontend/src/app/views/manager/manager.component.ts`, `HTML` = `quartz-manager-frontend/src/app/views/manager/manager.component.html`

## Phase 1: Setup

- [X] T001 `quartz-manager-frontend`에서 `npm ci` 후 `npm test`를 실행해 변경 전 기준선(통과/실패 목록)을 기록한다(코드 수정 없음)
- [X] T002 `specs/002-websocket-ui-refresh/spec-002-changelog.md` 뼈대(한글, "변경 파일 목록"/"파일별 compare" 섹션)를 만든다 (헌법 V, FR-010)

## Phase 2: Foundational (모든 스토리의 선행 조건)

**⚠️ 완료 전에는 사용자 스토리 작업을 시작하지 않는다.**

- [X] T003 TS에 private 메서드 `applyProgressToTrigger(triggerKey: TriggerKey, progress: TriggerFiredBundle)`을 추가한다. 동작: `triggerDetailsByName[this.getTriggerDetailKey(triggerKey)]`가 있을 때만, `progress.nextFireTime`/`previousFireTime` 각각이 비어 있지 않고 `Number.isNaN(new Date(v).getTime())`이 아닐 때에 한해 해당 필드를 덮어쓴다. `selectedTrigger`가 같은 트리거(`sameTriggerKey`)이고 저장소 객체와 다른 참조이면 같은 값을 반영한다. 저장소에 없으면 아무것도 하지 않는다 (FR-001, FR-002, FR-006, research 결정 1·2)

**Checkpoint**: 갱신 메서드 준비 완료

## Phase 3: User Story 1 - 다음/이전 실행 시각 갱신 (Priority: P1) 🎯 MVP

**Goal**: 선택된 트리거의 작업 실행 후 US1 표의 5개 위치가 새로고침 없이 갱신된다.

**Independent Test**: quickstart 2-1 — 트리거 선택 후 "Trigger Now" → 5곳의 시각 변경.

- [X] T004 [US1] TS의 `subscribeToTriggerTopics` 안 진행 구독 콜백에서 기존 `this.progress = progress`는 그대로 두고, 같은 콜백에서 `this.applyProgressToTrigger(triggerKey, progress)`를 추가로 호출한다. 로그 구독 코드와 `unsubscribeFromTriggerTopics`는 수정하지 않는다 (FR-001, FR-009)
- [X] T005 [US1] HTML의 Dashboard 상세 서랍 Previous fire 필드(119행 부근, `selectedTrigger?.timesTriggered ? 'tracked by progress events' : 'not exposed'`)를 `getTriggerPreviousFireLabel(selectedTriggerKey)` 호출로 교체한다. 이 줄 외의 HTML은 수정하지 않는다 (FR-001, research 결정 4)
- [X] T006 [US1] 읽기 전용 점검: HTML의 Dashboard 표 Next fire(106행 `getTriggerNextFireLabel`), Dashboard 서랍 Next fire(120행 `selectedTrigger?.nextFireTime`), Triggers 표 Next fire(218행), Triggers 상세 Schedule summary(236행)가 모두 `triggerDetailsByName`/`selectedTrigger`를 읽는지 확인한다. 읽고 있으면 **수정하지 않는다**(수정 0건이 정상). 다르게 읽는 곳이 있으면 그 줄만 최소 수정하고 changelog에 사유를 기록한다

**Checkpoint**: US1 단독으로 5곳 갱신 검증 가능 (MVP)

## Phase 4: User Story 2 - 진행 카드 "대기 중" 해소 (Priority: P1)

**Goal**: 진행 정보 수신 후 진행 카드 3곳이 "대기 중"에서 벗어나고 음수 퍼센트가 보이지 않는다.

**Independent Test**: quickstart 2-2 — 크론 트리거 실행 후 3곳 확인, `-1%` 미노출.

- [X] T007 [US2] TS의 `getProgressLabel()`을 수정한다: `progress`가 없으면 기존 `Waiting for progress events`, `percentage >= 0`이면 기존 `N% / M fired`, 그 외(`percentage < 0`)이면 `Last fired: {formatDateTime(previousFireTime) || '-'} · Next: {formatDateTime(nextFireTime) || '-'}`를 반환한다. 이 메서드를 공유하는 Dashboard 서랍(126행)과 Executions Inspector(271행)는 HTML을 수정하지 않는다 (FR-003, FR-004, research 결정 3)
- [X] T008 [US2] HTML의 Execution Load "Current progress" 필드(143행 `{{ getProgressPercentage() }}%`)를 `progress`가 있고 `progress.percentage >= 0`일 때만 `N%`, 그 외 `-`로 표시하도록 수정한다. 이 필드 외 HTML과 `getProgressPercentage()`는 수정하지 않는다 (FR-003)

**Checkpoint**: US1 + US2 로 선택 트리거 기준 핵심 갱신 완성

## Phase 5: User Story 3 - 목록 전체 트리거 갱신 (Priority: P2)

**Goal**: 선택하지 않은 트리거의 작업 실행도 목록 행의 Next fire를 갱신한다.

**Independent Test**: quickstart 2-3 — A 선택 상태에서 B 실행 → B 행만 갱신, A 표시 불변.

- [X] T009 [US3] TS에 필드 `private progressRowSubscriptions: {[key: string]: Subscription} = {}`와 private 메서드 `syncProgressRowSubscriptions()`를 추가한다. 동작: `this.triggerKeys`의 각 트리거에 대해 `getTriggerDetailKey` 키가 맵에 없으면 `this.progressRxWebsocketService.watch('/topic/progress/' + triggerKey.name)`를 `JSON.parse(msg.body)`로 해석해 구독하고 콜백에서 `this.ngZone.run(() => this.applyProgressToTrigger(triggerKey, progress))`를 호출해 맵에 저장한다. `triggerKeys`에 없는 키의 구독은 해제하고 맵에서 삭제한다. 이 구독은 `this.progress`와 `selectedTrigger` 표시를 직접 바꾸지 않는다 (FR-005, FR-006, research 결정 5)
- [X] T010 [US3] TS의 4곳에서 `syncProgressRowSubscriptions()`를 호출한다: (a) `fetchTriggers()`의 `next` 콜백에서 `this.triggerKeys` 대입 직후, (b) `upsertTriggerKey()`에서 키를 추가한 직후, (c) unschedule 성공 콜백(`this.triggerKeys` 필터링 직후), (d) `ngOnDestroy()`에서는 맵의 모든 구독을 해제한다. 위 4곳 외의 로직은 수정하지 않는다 (FR-005)

**Checkpoint**: 모든 스토리 완료

## Phase 6: Polish & 검증

- [X] T011 `quartz-manager-frontend`에서 `npm test`와 `npm run build`를 실행해 T001 기준선과 비교한다. 새 실패가 있으면 이번 변경만 수정한다 (FR-011, SC-005)
- [ ] T012 quickstart.md 2번 수동 시나리오 1~5를 qssb 연동 환경에서 수행하고 결과(통과/실패)를 changelog에 기록한다 (SC-001~003)
- [X] T013 `git diff --stat`로 변경 파일이 수정 허용 범위의 3개뿐인지 확인한다. 그 외 파일이 있으면 되돌린다. `git diff`에서 목적 외 변경(공백·포맷·리네임·import 정리)이 없는지도 확인한다 (FR-008, FR-009, SC-004)
- [X] T014 `spec-002-changelog.md`를 완성한다: 변경 파일 목록, 파일별 compare(변경 전/후 핵심 코드와 한글 설명), T006 점검 결과(수정 없음 여부), T012 결과, 비밀 정보 미포함 확인 (헌법 V, FR-010)

## Dependencies & Execution Order

- Phase 1 → Phase 2(T003) → US1(T004~T006) → US2(T007~T008) → US3(T009~T010) → Phase 6
- 모든 작업이 `TS`/`HTML` 두 파일을 수정하므로 **순차 진행**. 병렬 불가.
- US2는 US1과 독립 검증 가능하나 같은 파일이라 US1 이후 진행. US3는 T003이 필수 선행.

## Implementation Strategy

- **MVP**: Phase 1~2 + US1 (T001~T006). 5곳 시각 갱신까지 완료되면 중단해도 가치가 있다.
- **이후**: US2(진행 카드) → US3(전체 트리거) → 검증.
- 각 스토리 완료 시 해당 변경을 changelog에 즉시 누적한다.
- 어떤 작업에서든 "수정 허용 범위" 밖 파일을 건드려야 할 것 같으면 중단하고 사유를 보고한다.

## Notes

- 서버(qssb)·nginx·연결/인증/재연결·로그 표시·구독 해제·스타일은 건드리지 않는다(FR-009).
- Triggers 페이지 상세에는 Previous fire 요소가 없으므로 새로 추가하지 않는다(헌법 v1.1.1 원칙 VI).
