---

description: "폐쇄망 대응 — 아이콘 폰트 자체 호스팅 작업 목록"
---

# Tasks: 폐쇄망 대응 — 아이콘 폰트 자체 호스팅

**Input**: `/specs/003-offline-material-icons/` 의 plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Prerequisites**: plan.md, spec.md (존재). 헌법 v1.2.0(원칙 VII) 준수.

**Tests**: spec 에서 요청하지 않았다. 신규 테스트 파일은 만들지 않고 기존 `npm test`(회귀), 외부 접속 차단 상태의 `ng build`, `dist` 검색으로 검증한다.

**Organization**: 사용자 스토리별로 묶는다.

## ⛔ 수정 허용 범위 (FR-007/008 — 위반 시 작업 중단)

수정·추가할 수 있는 파일은 **이 4개뿐**이다. (`FE` = `quartz-manager-frontend`)
- `FE/src/assets/fonts/material-icons/material-icons.woff2` (신규)
- `FE/src/assets/fonts/material-icons/material-icons.css` (신규)
- `FE/src/index.html` (외부 링크 **1줄만** 교체)
- `specs/003-offline-material-icons/spec-003-changelog.md` (신규, 문서)

그 외는 **수정 금지**: `angular.json`, `package*.json`, 빌드·테스트 설정, 컴포넌트·서비스·모델, `src/styles.css`, Roboto 설정,
`manager.component.*`(spec 002), qssb, nginx. 포맷 변경·미사용 코드 정리·주석 삭제·`index.html` 의 다른 줄 수정도 금지한다.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: 서로 다른 파일이라 병렬 가능.
- 약칭: `FE` = `quartz-manager-frontend`, 외부 접속 차단 = 환경 변수 `HTTPS_PROXY=http://127.0.0.1:9`, `HTTP_PROXY=http://127.0.0.1:9`
  (PowerShell: `$env:HTTPS_PROXY="http://127.0.0.1:9"`, cmd: `set HTTPS_PROXY=http://127.0.0.1:9`).

## Phase 1: Setup

- [X] T001 `FE` 에서 `npm test` 로 변경 전 기준선(통과 수)을 기록하고, 외부 접속 차단 상태로 `npm run build` 를 실행해 **변경 전에는 `Inlining of fonts failed`로 실패함**을 확인한다(통제 실험, 코드 수정 없음). `node_modules` 가 없으면 `npm ci` 먼저
- [X] T002 `specs/003-offline-material-icons/spec-003-changelog.md` 뼈대(한글: 근거, 변경 파일 목록, 파일별 compare, 검증 결과, 폰트 출처·sha256) 를 만든다 (헌법 V, FR-010)

## Phase 2: Foundational

없음 (스토리 간 선행 작업 없음).

## Phase 3: User Story 1 - 폐쇄망 화면에서 아이콘 정상 표시 (Priority: P1) 🎯 MVP

**Goal**: 헤더 메뉴 버튼과 날짜 선택 버튼 2개가 외부 접속 없이 아이콘 모양으로 표시된다.

**Independent Test**: quickstart 4 — 외부 호스트 차단 상태에서 아이콘 3곳이 아이콘으로 보이고 외부 요청이 0건.

- [X] T003 [P] [US1] 인터넷이 되는 환경에서 `curl -fsSL -o FE/src/assets/fonts/material-icons/material-icons.woff2 https://fonts.gstatic.com/s/materialicons/v145/flUhRq6tzZclQEJ-Vdg-IuiaDsNc.woff2` 로 폰트를 받는다(폴더가 없으면 생성). `file` 이 `Web Open Font Format (Version 2)` 인지, 크기가 128352 bytes 인지 확인하고 `shasum -a 256` 값을 기록한다 (FR-001, FR-005)
- [X] T004 [P] [US1] `FE/src/assets/fonts/material-icons/material-icons.css` 를 만든다. 맨 위 주석에 출처(Google Fonts), 버전(v145), 라이선스(Apache License 2.0, https://www.apache.org/licenses/LICENSE-2.0)를 적고, `@font-face { font-family: 'Material Icons'; font-style: normal; font-weight: 400; src: url(material-icons.woff2) format('woff2'); }` 와 원본 `.material-icons` 규칙(`font-family`, `font-weight: normal`, `font-style: normal`, `font-size: 24px`, `line-height: 1`, `letter-spacing: normal`, `text-transform: none`, `display: inline-block`, `white-space: nowrap`, `word-wrap: normal`, `direction: ltr`, `-webkit-font-feature-settings: 'liga'`, `-webkit-font-smoothing: antialiased`)을 그대로 넣는다. `url()` 은 같은 폴더의 상대 경로만 쓴다 (FR-001, FR-005, FR-006)
- [X] T005 [US1] `FE/src/index.html` 의 `<link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">` **한 줄만** `<link href="assets/fonts/material-icons/material-icons.css" rel="stylesheet">` 로 교체한다. 다른 줄(주석 처리된 fontawesome 포함)은 수정하지 않는다 (FR-001, FR-007)
- [ ] T006 [US1] 브라우저 확인: `FE` 에서 `npm start` 또는 빌드 결과를 서빙해 헤더 메뉴 버튼과 트리거 설정 화면의 날짜 선택 버튼 2개가 글자(`menu`, `event`)가 아닌 아이콘으로 보이는지, 개발자 도구 Network 에 외부 호스트 요청이 0건인지 확인하고 결과를 changelog 에 기록한다(자동화할 수 없는 수동 확인) (FR-002, SC-001, SC-002)

**Checkpoint**: US1 단독으로 아이콘 표시 검증 가능 (MVP)

## Phase 4: User Story 2 - 외부 접속 없이 화면 빌드 성공 (Priority: P1)

**Goal**: 외부 접속이 막히거나 사설 인증서 환경에서도 빌드가 성공하고, 결과물에 외부 자동 로드 참조가 없다.

**Independent Test**: quickstart 1, 2.

- [X] T007 [US2] 외부 접속 차단 상태로 `FE` 에서 `npm run build` 를 실행해 `Index html generation complete.` 와 빌드 성공을 확인한다(T001 의 실패와 대비). 인증서 오류 환경에서도 같은 결과여야 한다 (FR-003, SC-003)
- [X] T008 [US2] `FE` 에서 `grep -rlE "googleapis|gstatic" dist` 가 출력 없음임을 확인하고(주석 속 `fontawesome` 문구는 허용), `dist/assets/fonts/material-icons/` 에 `material-icons.css`, `material-icons.woff2` 가 있는지, `dist/index.html` 에 `preconnect` 와 외부 `@font-face` 가 없는지 확인한다. 결과를 changelog 에 기록한다 (FR-004, SC-004)

**Checkpoint**: US1 + US2 로 핵심 목표 달성

## Phase 5: User Story 3 - 기존 화면에 부작용 없음 (Priority: P2)

**Goal**: 아이콘 이외의 화면과 spec 002 기능에 변화가 없고, 변경 범위를 지켰다.

**Independent Test**: quickstart 3, 5.

- [X] T009 [US3] `FE` 에서 `npm test` 를 실행해 T001 기준선과 같은 결과(실패 증가 0)인지 확인한다 (SC-006)
- [X] T010 [US3] 저장소 루트에서 `git status --short` 와 `git diff --stat` 으로 이번 작업의 변경이 수정 허용 범위의 4개뿐인지 확인한다. 그 외 파일(특히 `angular.json`, `package*.json`, `src/styles.css`, `manager.component.*`)이 변경되었으면 되돌린다. `git diff -- FE/src/index.html` 이 정확히 1줄 교체인지 확인한다 (FR-007, FR-008, SC-005)
- [X] T011 [US3] 폰트 파일의 sha256 이 T003 에서 기록한 값과 같은지 다시 확인하고, 헤더·트리거 설정 화면의 아이콘 크기·정렬이 변경 전과 같은지 육안으로 비교한다(T006 과 함께 수행 가능) (FR-006, SC-006)

**Checkpoint**: 모든 스토리 완료

## Phase 6: Polish

- [X] T012 `spec-003-changelog.md` 를 완성한다: 근거(헌법 원칙 VII, 폐쇄망), 변경 파일 목록, 파일별 compare(`index.html` 1줄 전후, CSS 전체, woff2 는 크기·sha256·출처 URL·버전), T001 통제 실험 결과와 T007·T008·T009 결과, T006 수동 확인 결과, 라이선스(Apache-2.0) 기록, "Angular 가 로컬 스타일 링크를 비동기 로드하므로 아이콘이 적용되기 직전 글자가 잠깐 보일 수 있음" 안내 (헌법 V, FR-010)

## Dependencies & Execution Order

- Phase 1 → US1(T003~T006) → US2(T007~T008) → US3(T009~T011) → Phase 6
- **T003 ∥ T004** 는 서로 다른 파일이라 병렬 가능. T005 는 T003·T004 이후(링크가 가리킬 파일이 있어야 함).
- T007 은 T005 이후(변경된 `index.html` 로 빌드). T008 은 T007 이후(`dist` 필요).

### Parallel Opportunities

- T003 ∥ T004 (폰트 파일 받기 / CSS 작성)

## Implementation Strategy

- **MVP**: Phase 1 + US1(T001~T005) + T007. 파일 3개만 만들어도 아이콘과 빌드 문제가 해결된다.
- 이후 검증(T008~T011)과 changelog(T012)를 마친다.
- "수정 허용 범위" 밖 파일을 건드려야 할 것 같으면 중단하고 사유를 보고한다(spec 개정 필요).

## Notes

- spec 002(WebSocket 화면 갱신)와 변경 파일이 겹치지 않아 독립적으로 진행할 수 있다. 003 이 먼저 끝나면 Windows 에서의 `self-signed certificate` 빌드 오류가 해소되어 002 의 빌드·검증이 가능해진다.
- 라이선스 전문 사본 파일이 필요한 엄격한 준수가 요구되면 spec 개정(4번째 파일 추가) 후 진행한다(research.md 알려진 위험 참조).
