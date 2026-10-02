# Contract: 화면 갱신 계약

서버 계약은 변경 없음(qssb `specs/011-job-execution-websocket/contracts/websocket-notifications.md`).
이 문서는 **수신 메시지 → 화면 요소**의 계약만 정의한다.

## 수신 (변경 없음)

| 토픽 | 시점 | 사용 필드 |
|------|------|-----------|
| `/topic/progress/{triggerName}` | 작업 종료 직후 1회 | `nextFireTime`, `previousFireTime`, `percentage`, `timesTriggered` |
| `/topic/logs/{triggerName}` | 작업 종료 직후 1회 | (변경 없음 — 기존 표시 유지) |

`{triggerName}`은 `triggerKey.name` — 기존 구독과 동일.

## 화면 반영 계약

1. **GIVEN** 목록에 표시된 트리거 T, **WHEN** `/topic/progress/T` 수신, **THEN**
   `triggerDetailsByName[T].nextFireTime/previousFireTime`이 유효 값일 때만 갱신된다.
2. 위 갱신으로 US1 표의 5개 위치가 변경된다(spec.md).
3. **WHEN** `percentage < 0`, **THEN** 진행 카드는 `Last fired: … · Next: …`을, "Current progress"는 `-`를 표시.
4. **WHEN** 선택된 트리거 메시지, **THEN** 추가로 `progress` 변수가 갱신된다(기존 동작).
5. 수신하지 않는 값(State/Misfire/Priority/Calendar)은 변경하지 않는다.

## 변경 금지(FR-009)

연결 URL, 인증(`access_token`), 재연결 설정, 서비스 클래스, 로그 구독·표시, 구독 해제 로직, 스타일, 의존성.
