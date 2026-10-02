# Contract: 프런트엔드 ↔ qssb WebSocket

서버가 정의한 계약을 프런트엔드가 소비하는 방식을 문서화한다(서버 기준: qssb `specs/011-job-execution-websocket/contracts/websocket-notifications.md`). 서버 변경 없음.

## 연결

| 채널 | SockJS 엔드포인트 | 인증 |
|------|-------------------|------|
| 진행률 | `{baseUrl}/quartz-manager/progress` | `CONSOLE_SESSION` 쿠키(동일 오리진, 자동 동봉) |
| 로그 | `{baseUrl}/quartz-manager/logs` | 동일 |

- `?access_token=` 쿼리는 유지하지만 qssb는 사용하지 않는다(research 결정 1).
- 미인증이면 핸드셰이크가 401로 거부된다.

## 구독 / 수신 메시지

| 토픽 | 본문(JSON) | 발행 시점 |
|------|-----------|-----------|
| `/topic/progress/{triggerName}` | `TriggerFiredBundleDTO` (data-model.md) | 실행 1회당 1건(종료 직후) |
| `/topic/logs/{triggerName}` | `LogRecord` | 실행 1회당 1건(성공 INFO / 실패 ERROR) |

`{triggerName}`은 qssb에서 `trigger_{jobName}`. 프런트엔드는 선택된 트리거 이름으로 구독하고 트리거 변경 시 해제한다.

## 클라이언트 동작 계약

1. 수신 본문 파싱 실패 ⇒ 해당 메시지만 무시, 구독 유지.
2. 연결 끊김 ⇒ 지수 백오프 재연결(초기 200ms, 최대 30s), 복구 후 구독 자동 재개(RxStomp 기본 동작).
3. 트리거 변경/해제/화면 이탈 ⇒ 기존 구독 즉시 해제, 로그·진행 표시 초기화.
4. 퍼센트 < 0 ⇒ 퍼센트 비표시, 시각 정보 표시.
