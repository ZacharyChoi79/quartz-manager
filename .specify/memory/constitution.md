<!--
Sync Impact Report
- 버전 변경: 1.1.0 → 1.1.1 (PATCH: 사실 오류 정정)
- 수정된 원칙: VI — 갱신 의무 표에서 존재하지 않는 "Triggers 페이지 상세의 Previous fire" 행 삭제,
  "Triggers 페이지 상세의 Next fire, Schedule summary" 를 실제 요소인 "Schedule summary 문구 내
  Next fire" 로 정정, 요소 신규 추가 금지 문장 추가. 갱신 대상은 5곳.
- 추가/삭제된 섹션: 없음
- 후속 TODO: 없음 (spec 002 는 이미 5곳 기준으로 정정됨)
-->

# Quartz Manager 헌법

## 핵심 원칙

### I. 한글 우선 (최우선, NON-NEGOTIABLE)

- 사용자에 대한 모든 응답은 MUST 한글로 작성한다.
- 모든 `.md` 문서(spec, plan, tasks, changelog, 헌법 등)는 MUST 한글로 작성한다.
- 코드 식별자, 명령어, 파일 경로, 고유명사 등 번역 시 의미가 훼손되는 항목만 원문을 유지한다.

근거: 프로젝트 소유자와 모든 산출물 독자의 일관된 소통 언어를 보장하기 위함이다.

### II. 범위 한정: WebSocket 실시간 기능

- 작업 범위는 quartz-manager 프런트엔드(`quartz-manager-frontend`)가 "작업 실행 진행률 및
  로그에 대한 WebSocket 업데이트" 기능을 사용하기 위해 필요한 수정으로 MUST 한정한다.
- 해당 기능과 무관한 리팩터링, 기능 추가, 의존성 업그레이드는 MUST NOT 수행한다.
- 범위를 벗어나는 요구가 발견되면 구현하지 않고 별도 spec 으로 분리한다.

근거: 변경 표면을 최소화하여 검토 비용과 회귀 위험을 낮춘다.

### III. 최소 수정 (오픈소스 장점 보존)

- 기존 오픈소스(quartz-manager)의 구조, 패턴, 네이밍, 공개 API 를 MUST 유지한다.
- 신규 코드는 기존 코드 스타일과 관례를 따르며, 기존 파일의 수정으로 해결 가능하면
  신규 모듈/추상화를 MUST NOT 도입한다.
- 업스트림 병합 용이성을 해치는 대규모 재작성, 파일 이동, 포맷 일괄 변경은 MUST NOT 한다.
- 불가피하게 구조를 확장할 경우 plan 에 사유를 명시해야 한다(복잡도 정당화).

근거: 업스트림 업데이트를 계속 수용할 수 있어야 오픈소스 채택의 이점이 유지된다.

### IV. 서버 측은 qssb 를 기준으로 개발

- 서버 측 사양(WebSocket 엔드포인트, 메시지 포맷, 인증, 토픽 등)의 기준은
  `/Users/zacharychoi/Documents/workspace/qssb` 의 구현이며, 개발 전 MUST 해당 내용을 참조한다.
- 프런트엔드는 qssb 서버 계약에 맞춰 구현하며, 계약이 불명확하면 추측하지 않고 qssb
  코드/문서(`specs/`, `docs/`, `src/`)에서 확인한다.
- qssb 소스는 이 작업에서 MUST NOT 수정한다(참조 전용). 서버 변경이 필요하면 별도 요청으로 분리한다.

근거: 서버가 실제 계약의 원천이므로 프런트엔드 불일치를 예방한다.

### V. Spec 변경 이력 기록 (Changelog 필수)

- spec 과 관련된 모든 변경은 MUST `spec-{번호}-changelog.md` 에 기록한다.
  `{번호}` 는 `specs/` 이하에서 현재 진행 중인 spec 의 번호이다.
- 기록 내용은 MUST (1) 변경 파일 목록, (2) 각 파일의 compare(변경 전/후 diff) 내용을 포함한다.
- changelog 는 한글로 작성하며, 변경과 같은 작업 단위에서 갱신한다.

근거: spec 단위의 변경 추적성과 리뷰 가능성을 확보한다.

### VI. WebSocket 메시지로 갱신 가능한 화면 요소는 전부 갱신

서버(qssb)가 WebSocket 으로 전달하는 메시지가 담고 있는 값은, 그 값을 표시하는 모든 화면 요소에
MUST 반영한다. 메시지로 갱신 가능한 요소를 일부만 처리하고 나머지를 REST 조회 결과로 방치해서는
MUST NOT 한다. 근거 분석(2026-10-02, `manager.component` 기준)은 다음과 같다.

**메시지가 담은 값**
- 진행 메시지 `/topic/progress/{trigger}`: `nextFireTime`, `previousFireTime`, `finalFireTime`,
  `timesTriggered`, `repeatCount`, `percentage`, `jobKey`, `jobClass`
- 로그 메시지 `/topic/logs/{trigger}`: `date`, `type`, `message`, `threadName`

**반드시 갱신해야 하는 화면 요소 (갱신 의무 대상)**

| 화면 위치 | 사용할 메시지 값 | 현재 상태 |
|-----------|------------------|-----------|
| Dashboard "Next Scheduled Fires" 표의 Next fire | `nextFireTime` | 미반영(REST 값만 표시) |
| Dashboard 상세 서랍의 Next fire | `nextFireTime` | 미반영 |
| Dashboard 상세 서랍의 Previous fire | `previousFireTime` | 고정 문구만 표시 |
| Triggers 페이지 표의 Next fire | `nextFireTime` | 미반영 |
| Triggers 페이지 상세의 Schedule summary 문구 내 Next fire | `nextFireTime` | 미반영 |
| 진행 카드(Dashboard 서랍, Execution Load의 Current progress, Executions의 Execution Inspector) | `percentage`, `timesTriggered`, 시각 값 | 반영 중이나 크론은 `percentage = -1`로 "대기 중"에 머무름 → 시각 정보 표시로 보정 |
| Event Stream 목록, "EVENTS" 카드, "Logs received" | 로그 메시지 전체 | 반영 중(유지) |

- 진행 메시지를 수신하면 해당 트리거의 `nextFireTime`/`previousFireTime`을 트리거 상세 저장소
  (`triggerDetailsByName`)와 선택된 트리거(`selectedTrigger`)에 MUST 반영하여, 위 표의 모든 요소가
  재조회 없이 한 번에 갱신되도록 한다.
- 화면 목록에 표시되는 모든 트리거 행이 갱신 대상이다. 구독이 선택된 트리거에 한정되어 있어 이를
  충족하지 못하면, plan 에 목록 표시 트리거 전체 구독(또는 이에 준하는 최소 수정 방안)을 MUST
  명시하고 사유를 기록한다.
- Triggers 페이지 상세에는 Previous fire 표시 요소가 없으므로, 갱신을 위해 요소를 새로 추가하지
  MUST NOT 한다(원칙 III). 표의 위치는 현재 화면에 실제 존재하는 5곳이다.
- 수신 값이 `null` 이거나 유효하지 않은 날짜이면 기존 표시값을 MUST 유지한다. `percentage < 0` 은
  퍼센트로 표시하지 않고 시각 정보로 대체한다.

**갱신 대상이 아닌 요소 (메시지에 값이 없음 — 추측하여 갱신 금지)**
- State 칩(표·상세), Misfire, Priority, Calendar: 메시지에 해당 값이 없으므로 MUST NOT 메시지로
  갱신하며 기존 REST 조회를 유지한다.
- Final fire, Repeat 요약: 크론 트리거에서는 값이 변하지 않거나(`repeatCount`/`timesTriggered` = 0)
  비어 있으므로 갱신 의무에서 제외하되, 값이 유효하게 전달되면 반영해도 된다(MAY).

근거: 서버가 이미 발행하는 값을 화면이 쓰지 않으면 "실시간 업데이트" 기능이 실제로는 동작하지 않는
것처럼 보인다(진행 메시지는 수신되지만 Next fire 가 갱신되지 않던 문제).

## 추가 제약 사항

- 대상 프런트엔드: `quartz-manager-frontend`. 서버 참조: qssb (읽기 전용).
- 기존 REST API 및 화면 동작은 WebSocket 기능 추가로 인해 하위 호환성이 깨지지 않아야 한다.
- 비밀 정보(토큰, 자격 증명)는 코드와 changelog 에 MUST NOT 포함한다.

## 개발 워크플로 및 변경 기록

1. 구현 전 qssb 의 관련 서버 코드를 확인하고 계약을 spec 에 반영한다.
2. 최소 수정 원칙에 따라 변경 대상 파일을 먼저 식별하고 plan 에 나열한다.
3. 구현 후 변경 파일 목록과 compare 내용을 `spec-{번호}-changelog.md` 에 기록한다.
4. 변경 검증(프런트엔드 빌드/테스트, WebSocket 연결 동작 확인)을 완료한 뒤 완료로 보고한다.
5. plan 단계의 헌법 점검(Constitution Check)은 위 6개 원칙 준수를 확인해야 한다.
6. 구현 후 원칙 VI 의 갱신 의무 대상 표의 각 요소가 메시지 수신으로 갱신되는지 확인한다.

## 거버넌스

- 본 헌법은 다른 모든 관행에 우선한다.
- 개정은 문서화된 변경 사유와 함께 이 파일을 수정하여 수행하며, 영향받는 템플릿/문서의
  정합성을 확인한다.
- 버전 정책(시맨틱 버전): MAJOR 는 원칙 삭제/재정의, MINOR 는 원칙·섹션 추가 또는 대폭 확장,
  PATCH 는 문구 명확화.
- 모든 PR/리뷰는 원칙 준수 여부를 확인해야 하며, 위반은 plan 의 복잡도 추적 항목에서
  정당화되지 않는 한 허용되지 않는다.

**Version**: 1.1.1 | **Ratified**: 2026-10-01 | **Last Amended**: 2026-10-02
