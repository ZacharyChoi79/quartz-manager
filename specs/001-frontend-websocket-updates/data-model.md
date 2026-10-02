# Data Model: 프런트엔드 WebSocket 업데이트 활용

신규 서버 엔티티는 없다. 서버(qssb)가 발행하는 두 메시지와, 프런트엔드가 추가로 유지하는 연결 상태만 다룬다.

## 작업 실행 진행 정보 (`TriggerFiredBundle`, 변경 없음)

[trigger-fired-bundle.model.ts](../../quartz-manager-frontend/src/app/model/trigger-fired-bundle.model.ts)

| 필드 | 타입 | 비고 |
|------|------|------|
| timesTriggered / repeatCount | number | 크론 트리거는 0 |
| previousFireTime / nextFireTime / finalFireTime | string(날짜) | null 가능 |
| jobKey / jobClass | string | |
| percentage | number | 계산 불가 시 -1 |

**표시 규칙(FR-004/005)**: 메시지 수신 ⇒ 수신됨. `percentage >= 0` ⇒ 퍼센트 표시, 아니면 시각 정보 표시.

## 작업 실행 로그 레코드 (서버 `LogRecord`, 화면용 `ConsoleLogRecord`로 변환)

| 서버 필드 | 화면 필드 | 비고 |
|-----------|-----------|------|
| date | time | |
| type (INFO/WARN/ERROR) | severity | 없으면 INFO |
| message | message | 없으면 JSON 문자열 |
| threadName | source | 없으면 트리거 그룹/이름 |

최대 50건 유지(최신이 앞).

## 실시간 연결 상태 (프런트엔드 전용)

| 상태 | 판정 | 화면 |
|------|------|------|
| CONNECTED | `connectionState$ === OPEN` | 연결됨 |
| RECONNECTING | CONNECTING/CLOSING 또는 연결 이력 있는 CLOSED | 재연결 중 |
| FAILED | 한 번도 OPEN 되지 못하고 CLOSED가 N회(예: 5) 반복 | 연결 실패 — 로그인/세션 확인 |

진행/로그 두 채널 중 하나라도 비정상이면 비정상으로 표시한다.
