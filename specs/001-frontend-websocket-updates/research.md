# Phase 0 Research: 프런트엔드 WebSocket 업데이트 활용

Technical Context에 `NEEDS CLARIFICATION`은 남지 않았다. 아래는 qssb/프런트엔드 코드를 직접
읽어 확인한 결정이다.

## 결정 1: 연결 인증은 기존 방식(동일 오리진 쿠키)에 맡기고 `access_token` 쿼리는 유지한다

- **Decision**: SockJS 연결 URL(`{base}/quartz-manager/progress|logs?access_token=...`)은 변경하지 않는다.
- **Rationale**: qssb `ConsoleSecurityConfig`는 `/quartz-manager/**`를 `CONSOLE_SESSION` 쿠키로 인증
  (`ConsoleSessionAuthenticationFilter`)하며 JWT/`access_token`을 쓰지 않는다. 콘솔이 qssb와 같은
  오리진(`/quartz-manager-ui/`)에서 서빙되므로 SockJS 핸드셰이크에 쿠키가 자동 동봉된다.
  `QuartzManagerEndpointGatingFilter`도 `/progress`, `/logs`를 차단하지 않는다.
  `ApiService.getToken()`은 qssb에서 `undefined`이므로 쿼리 값은 무의미하지만 해롭지 않고,
  업스트림 코드/기존 테스트(`'/progress?access_token='` 검증)를 유지하는 것이 최소 수정이다.
- **Alternatives considered**: 쿼리 파라미터 제거 — 업스트림 호환·테스트 변경만 늘고 이득 없음. 기각.

## 결정 2: 진행 정보는 퍼센트가 아니라 "수신 여부 + 시각"을 기준으로 표시한다

- **Decision**: `progress`가 존재하면 "수신됨"으로 보고, `percentage >= 0`이면 `N% / M fired`, 아니면
  `Last fired: {previousFireTime} · Next: {nextFireTime}` 형태로 표시한다. 진행 막대는 퍼센트가
  유효할 때만 채운다.
- **Rationale**: qssb `data-model.md`에 따르면 크론 트리거에서는 `repeatCount/timesTriggered`가 0이라
  `percentage`는 항상 -1. 현재 `getProgressLabel()`은 `percentage < 0`을 "대기 중"으로 처리해
  이벤트를 받아도 대기로 보인다(spec User Story 2).
- **Alternatives considered**: 서버에서 퍼센트 보정 — 서버 수정 금지(IV). 기각.

## 결정 3: 재연결은 지수 백오프로 바꾸고 연결 상태는 RxStomp의 `connectionState$`로 노출한다

- **Decision**: 두 서비스 설정에서 `reconnectDelay: 200` 고정을 `reconnectDelay`(초기 값 유지) +
  `reconnectTimeMode: ReconnectionTimeMode.EXPONENTIAL` + `maxReconnectDelay`(예: 30000)로 변경한다
  (`@stomp/stompjs` 7.3.0 지원). `RxStompService`에 `connectionState$`(rx-stomp 기본 제공)를
  그대로 사용해 매니저 화면에서 상태 칩을 표시한다.
- **Rationale**: SockJS는 핸드셰이크 401의 HTTP 상태를 노출하지 않아 "인증 거부"를 정확히 구분할 수
  없다. 대신 한 번도 연결되지 못한 채 실패가 반복되면 "연결 실패 — 로그인/세션 확인" 안내를
  띄우고(상태 판정은 연결 시도 횟수 기준), 백오프로 서버 부하를 막는다.
- **Alternatives considered**: 오류 발생 시 `deactivate()`로 완전 중단 — 일시 장애 후 자동 복구(FR-008)와
  충돌. 기각.

## 결정 4: 메시지 처리 오류 격리와 목록 키

- **Decision**: `JSON.parse`를 `map` 안에서 `try/catch`로 감싸 실패 시 해당 메시지만 건너뛰고(스트림 유지),
  `@for (log of logs; track log.time)`는 동일 시각 중복에 취약하므로 수신 순번을 가진 키로 바꾼다.
- **Rationale**: 현재 `map` 내부 예외는 구독을 종료시키고(`err` 핸들러 호출 후 complete), 이후 메시지를
  모두 놓친다. 같은 밀리초의 로그는 `track` 키가 충돌한다.
- **Alternatives considered**: 전체 구독 재시도 — 메시지 1건 오류로 재구독은 과함. 기각.

## 결정 5: 로그 최대 보관 건수

- **Decision**: 기존 `manager.component`의 `slice(0, 50)`을 유지한다(spec FR-003의 "최대 보관 건수"를
  이미 충족).
- **Rationale**: 최소 수정. `logs-panel`의 `MAX_LOGS = 30`은 별도 컴포넌트이므로 건드리지 않는다.

## 구현 시 확인 항목(위험)

- `progress-panel`/`logs-panel` 컴포넌트가 실제 화면에서 사용되는지(템플릿 참조) 확인 후, 미사용이면 수정 제외.
- `node_modules`가 설치되어 있지 않아 이번 계획 단계에서는 빌드/테스트를 실행하지 못했다(구현 단계에서 `npm ci` 후 검증).
