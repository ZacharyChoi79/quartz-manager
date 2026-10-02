# Phase 0 Research: WebSocket 메시지 기반 화면 갱신

Technical Context에 `NEEDS CLARIFICATION`은 없다. 코드(`manager.component.*`)와 qssb 계약을 직접
확인한 결정이다.

## 결정 1: 갱신은 "트리거 상세 저장소"에 값을 써서 한 번에 5곳을 갱신한다

- **Decision**: 진행 정보 수신 시 `triggerDetailsByName[getTriggerDetailKey(key)]`의 `nextFireTime`과
  `previousFireTime`을 갱신하고, `selectedTrigger`가 다른 객체 참조이면 같이 갱신한다.
- **Rationale**: 5개 화면 위치는 모두 이 저장소를 읽는다. Dashboard/Triggers 표는
  `getTriggerNextFireLabel` → `getTriggerDetail`, 서랍/상세는 `selectedTrigger`를 읽는다. 저장소 한 곳만
  갱신하면 템플릿 수정이 거의 필요 없다(바인딩 변경 최소).
- **Alternatives considered**: 각 템플릿 위치가 `progress`를 직접 읽도록 변경 — 표 행마다 다른 트리거 값이
  필요해 구조 변경이 커지고 수정 지점이 5곳으로 늘어 기각.

## 결정 2: 날짜 유효성은 대입 전에 검사한다

- **Decision**: 수신 값이 비었거나 `new Date(v)`가 유효하지 않으면 해당 필드를 덮어쓰지 않는다.
- **Rationale**: FR-002. 기존 `formatDateTime`은 무효 값을 `null`로 바꿔 "not available"을 표시하므로,
  대입 후에는 이전 정상 값이 사라진다. 대입 전 검사가 필요하다.

## 결정 3: 진행 카드 보정은 `getProgressLabel()`과 "Current progress" 필드 2곳만 수정한다

- **Decision**: `getProgressLabel()`에서 `progress`가 있고 `percentage < 0`이면
  `Last fired: {previous} · Next: {next}`를 반환(`formatDateTime` 재사용). `manager.component.html`의
  "Execution Load > Current progress" 필드는 퍼센트가 유효할 때만 `N%`, 아니면 `-`를 표시한다.
- **Rationale**: 진행 카드 3곳 중 2곳(서랍, Execution Inspector)은 `getProgressLabel()`을 공유하므로 이
  메서드 수정으로 자동 해결된다. 나머지 1곳(Current progress)만 템플릿 수정이 필요하다.
- **Alternatives considered**: 진행 막대 스타일 변경 — 스타일은 변경 금지(FR-009). 기각.

## 결정 4: Dashboard 서랍의 Previous fire는 고정 문구를 값으로 바꾼다

- **Decision**: 119행 `selectedTrigger?.timesTriggered ? 'tracked by progress events' : 'not exposed'`를
  `getTriggerPreviousFireLabel(selectedTriggerKey)` 호출로 교체한다. 이 메서드는 이미 존재하고 템플릿에서
  쓰이지 않는다(코드 확인).
- **Rationale**: 신규 메서드 없이 기존 메서드 재사용 — 최소 수정.
- **주의**: 이 메서드는 `trigger['previousFireTime']`를 읽으므로 결정 1에서 반드시 같은 저장소 필드에
  써야 한다. 값이 없으면 `'not available'`이 표시된다.

## 결정 5: 목록 전체 갱신(US3)은 "토픽별 진행 구독"을 별도 맵으로 관리한다

- **Decision**: `progressRowSubscriptions: {[key: string]: Subscription}`를 두고, `triggerKeys`와 동기화하는
  private 메서드 `syncProgressRowSubscriptions()`가 없는 키는 구독하고 사라진 키는 해제한다. 호출 지점은
  4곳: 트리거 목록 로드 완료 시, 새 트리거 추가(`upsertTriggerKey`), 트리거 삭제(unschedule 성공) 시,
  `ngOnDestroy`.
- **Rationale**: 기존 선택 트리거 구독(`subscribeToTriggerTopics`)은 로그 구독과 묶여 있고 FR-009로
  변경 금지다. 별도 구독 맵을 추가하면 기존 동작을 건드리지 않는다. rx-stomp의 `watch`는 같은 목적지를
  여러 번 구독해도 되며 중복 반영은 같은 값을 쓰므로 무해하다(멱등).
- **Alternatives considered**:
  - 기존 `subscribeToTriggerTopics`를 모든 트리거를 구독하도록 확장 — 로그 구독/초기화 로직과 얽혀 기존
    동작을 변경할 위험. 기각.
  - 주기적 REST 재조회 — 새 타이머와 호출 증가, WebSocket 활용이 목적이라는 방향과 어긋남. 기각.
- **구독 수 위험**: 트리거 수가 많으면 구독도 그만큼 늘지만 서버 부하는 토픽 단위 구독이라 작다. 본
  프로젝트 트리거 수는 소규모(배치 Job 단위)로 가정한다(spec 가정).

## 결정 6: 신규 테스트 파일은 추가하지 않는다

- **Decision**: `manager.component.spec.ts`를 새로 만들지 않고, 기존 `npm test`(회귀)와 quickstart 수동
  시나리오로 검증한다.
- **Rationale**: 컴포넌트가 10여 개 서비스에 의존하고 기존 spec이 없다. 신규 spec은 목적 외 파일이 되어
  FR-008/SC-004(무관 파일 변경 0건)와 충돌할 수 있다. 구현 후 순수 로직(날짜 유효성, 라벨)은 quickstart의
  브라우저 검증으로 확인한다.

## 확인된 사실 요약

- 연결/수신 정상(운영 브라우저: 101 + STOMP MESSAGE, nginx 환경에서는 xhr 폴링 병행) → 연결 수정 불필요.
- 서버 `nextFireTime`은 `context.getTrigger()` 기준으로 실행 직후의 다음 발화 시각 — 화면에 그대로 써도
  의미가 맞다(qssb data-model).
- `Trigger` 모델에 `nextFireTime`/`previousFireTime`(Date) 필드가 이미 있어 모델 변경이 필요 없다.
- 수신 값은 문자열(ISO)이므로 `formatDateTime(Date|string)`이 그대로 처리한다.
