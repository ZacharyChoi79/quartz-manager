# spec-002 변경 기록 (Changelog)

**Spec**: [spec.md](spec.md) | **작성 기준**: 헌법 v1.1.1 원칙 V | **작성일**: 2026-10-02

## 검증 결과

| 항목 | 결과 |
|------|------|
| 변경 전 `npm test` (T001) | 18개 스위트 / 45개 테스트 통과 |
| 변경 후 `npm test` (T011) | 18개 스위트 / 45개 테스트 통과 (회귀 없음) |
| 변경 후 `npm run build` (T011) | 성공. `manager.component.scss` 예산 초과 경고는 이번 변경과 무관(scss 미수정) |
| 수동 시나리오 (T012) | **미수행** — qssb 연동 브라우저 환경 필요. quickstart.md 2번 시나리오 수행 후 이 문서에 기록할 것 |

## 변경 파일 목록

| 파일 | 변경 |
|------|------|
| `quartz-manager-frontend/src/app/views/manager/manager.component.ts` | +60줄 수정/추가 (갱신 메서드 3개, 구독 맵 1개, 호출 연결 5곳, 진행 라벨 보정) |
| `quartz-manager-frontend/src/app/views/manager/manager.component.html` | 2줄 수정 (Previous fire, Current progress) |
| `specs/002-websocket-ui-refresh/spec-002-changelog.md` | 신규 (이 문서) |

수정 허용 범위(tasks.md) 밖의 파일 변경은 없다. (작업 시작 전부터 존재하던 `.gitignore` 변경은 이번 작업과 무관.)

## 파일별 compare

### manager.component.html

| 위치 | 변경 전 | 변경 후 | 사유 |
|------|---------|---------|------|
| Dashboard 상세 서랍 Previous fire (US1, FR-001) | `{{ selectedTrigger?.timesTriggered ? 'tracked by progress events' : 'not exposed' }}` | `{{ getTriggerPreviousFireLabel(selectedTriggerKey) }}` | 고정 문구 대신 수신된 이전 실행 시각을 표시. 이미 존재하던 메서드 재사용 |
| Execution Load의 Current progress (US2, FR-003) | `{{ getProgressPercentage() }}%` | `{{ progress?.percentage >= 0 ? getProgressPercentage() + '%' : '-' }}` | 진행률 계산 불가 시 `0%` 대신 `-` 표시 |

### manager.component.ts

| 변경 | 내용 | 관련 |
|------|------|------|
| 필드 추가 | `progressRowSubscriptions`: 트리거별 진행 구독을 보관하는 맵 | US3, FR-005 |
| 메서드 추가 `applyProgressToTrigger(triggerKey, progress)` | 수신한 `nextFireTime`/`previousFireTime`을 `triggerDetailsByName[...]`(및 다른 참조인 `selectedTrigger`)에 반영. 값이 비었거나 무효한 날짜면 덮어쓰지 않음. 저장소에 없는 트리거는 무시 | US1, FR-001·002·006 |
| 메서드 추가 `toValidDate(value)` | 날짜 유효성 검사 보조 (plan의 "메서드 1개"에 더해 필요했던 최소 보조 함수) | FR-002 |
| 메서드 추가 `syncProgressRowSubscriptions()` | `triggerKeys`와 진행 구독을 동기화(없는 키 구독, 사라진 키 해제). 이 구독은 `applyProgressToTrigger`만 호출하며 `progress`/로그/선택 표시는 변경하지 않음 | US3, FR-005·006 |
| `subscribeToTriggerTopics` 진행 구독 콜백 | `this.progress = progress` 유지 + `applyProgressToTrigger(triggerKey, progress)` 호출 추가 | US1, FR-001 |
| `getProgressLabel()` | 진행 정보가 있고 `percentage`가 유효하지 않으면 `Last fired: … · Next: …` 반환(기존엔 "Waiting for progress events") | US2, FR-003 |
| 호출 연결 5곳 | `fetchTriggers` next, `upsertTriggerKey`, unschedule 성공 콜백에서 `syncProgressRowSubscriptions()` 호출, `ngOnDestroy`에서 맵의 모든 구독 해제 | US3 |

## T006 점검 결과 (수정 0건)

다음 4곳은 이미 `triggerDetailsByName`/`selectedTrigger`를 읽고 있어 HTML을 수정하지 않았다.
- Dashboard 표 Next fire (`getTriggerNextFireLabel`)
- Dashboard 서랍 Next fire (`selectedTrigger?.nextFireTime`)
- Triggers 표 Next fire (`getTriggerNextFireLabel`)
- Triggers 상세 Schedule summary (`selectedTrigger?.nextFireTime`)

`selectTrigger`에서 `selectedTrigger`와 저장소가 같은 객체를 참조하므로 저장소 갱신으로 4곳이 함께 바뀐다.

## 변경하지 않은 것 (FR-009 확인)

WebSocket 연결·인증(`access_token`)·재연결 설정과 `services/*`, `model/*`, `app.module.ts`, `progress-panel`/`logs-panel`, 로그 구독·표시, 구독 해제 로직, 스타일, 의존성, 빌드·테스트 설정, qssb, nginx.

## 빌드 도구 변경 (spec 002 수정 허용 범위 밖 — 사용자 요청에 따른 추가)

헌법 원칙 III(최소 수정)에 따라 기존 동작은 바꾸지 않고 **프로필 추가**로 구현했다.

| 파일 | 변경 | 사유 |
|------|------|------|
| `quartz-manager-parent/quartz-manager-starter-ui/pom.xml` | 프로필 `build-webjar-local-npm` 추가(기존 `build-webjar` 불변). `exec-maven-plugin` 으로 PC 의 npm(`npm ci`/`npm run build`)을 프런트엔드 폴더에서 직접 실행, 결과 `dist` 를 `META-INF/resources/quartz-manager-ui` 로 복사 | Node 다운로드/`target\tmp` 복사 없이 설치된 Node/npm 사용 (Windows 에서 다운로드·경로 길이 문제 회피) |
| `buildUI.bat` (신규) | 기본 모드를 로컬 Node/npm 으로 하고 `--maven-node`/`-m` 로 기존 방식 선택, Node 버전 확인, `node_modules` 가 있으면 `npm ci` 생략, 로컬 저장소 경로 파라미터와 `--replace`(백업 후 교체) 지원, jar 검증 | Windows 에서의 빌드·적용 자동화 |
| `specs/002-websocket-ui-refresh/buildAndPatch.md` (신규) | 빌드·적용 가이드 | 운영 반영 절차 문서화 |

검증: Mac 에서 `mvn -Pbuild-webjar-local-npm -Dfrontend.skipInstall=true -Dnpm.shell=sh -Dnpm.shell.arg=-c -pl quartz-manager-starter-ui -am package` 가 성공하고, 생성된 jar(약 2.86MB)의 `main.768204f5aff9c1b1.js` 에 `Last fired:` 문구가 포함됨을 확인했다. **Windows(`cmd /c`) 경로와 `buildUI.bat` 은 이 환경에서 실행해 보지 못했다.**
