# Data Model: WebSocket 메시지 기반 화면 갱신

신규 엔티티 없음. 기존 구조 간의 반영 규칙만 정의한다.

## 입력: 진행 정보 (`TriggerFiredBundle`, 변경 없음)

[trigger-fired-bundle.model.ts](../../quartz-manager-frontend/src/app/model/trigger-fired-bundle.model.ts)

사용 필드: `nextFireTime`(string), `previousFireTime`(string), `percentage`(number), `timesTriggered`(number)

## 대상: 트리거 상세 (`Trigger`, 변경 없음)

[trigger.model.ts](../../quartz-manager-frontend/src/app/model/trigger.model.ts) — `nextFireTime: Date`, `previousFireTime: Date`

저장 위치: 컴포넌트 필드 `triggerDetailsByName[“{group}.{name}”]`, 선택 트리거는 `selectedTrigger`.

## 반영 규칙

| 규칙 | 내용 |
|------|------|
| 키 | 메시지의 트리거 이름 → `getTriggerDetailKey(triggerKey)`로 상세 저장소 조회. 저장소에 없으면 무시(오류 없음) |
| 시각 | `nextFireTime`, `previousFireTime` 각각 값이 있고 유효한 날짜일 때만 덮어씀 |
| 선택 트리거 | `selectedTrigger`가 같은 트리거이면 동일 값 반영(같은 참조면 자동) |
| 타 트리거 | 다른 트리거의 메시지는 그 트리거의 상세에만 반영, 선택 표시·`progress` 변수는 변경 안 함(FR-006) |
| `progress` 변수 | 선택된 트리거 구독의 메시지만 저장(기존 동작 유지) |
| 표시 보정 | `progress` 있음 + `percentage < 0` → 시각 라벨, `percentage >= 0` → 기존 `N% / M fired` |

## 화면 갱신 위치 ↔ 읽는 값 (갱신 후)

| 위치 | 읽는 곳 |
|------|---------|
| Dashboard 표 Next fire | `triggerDetailsByName[..].nextFireTime` |
| Dashboard 서랍 Next fire | `selectedTrigger.nextFireTime` |
| Dashboard 서랍 Previous fire | `triggerDetailsByName[..].previousFireTime` (`getTriggerPreviousFireLabel`) |
| Triggers 표 Next fire | `triggerDetailsByName[..].nextFireTime` |
| Triggers 상세 Schedule summary | `selectedTrigger.nextFireTime` |
| 진행 카드(서랍, Inspector) | `progress` + `getProgressLabel()` |
| Execution Load > Current progress | `progress.percentage` (유효 시) |
