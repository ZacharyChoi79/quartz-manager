# Quickstart: 검증 가이드

## 사전 조건

- qssb 기동(콘솔 로그인 가능), 크론 트리거 2개 이상(트리거 A, B).
- 프런트엔드: `cd quartz-manager-frontend && npm ci`.

## 1. 회귀

```bash
cd quartz-manager-frontend && npm test && npm run build
```

기대: 기존 테스트 통과, 빌드 성공.

## 2. 수동 시나리오 (spec 대응)

1. 트리거 A 선택 → A 작업 "Trigger Now" → 새로고침 없이 **5곳**의 시각이 바뀜(SC-001):
   Dashboard 표 Next fire, Dashboard 서랍 Next/Previous fire, Triggers 표 Next fire, Triggers 상세 Schedule summary.
2. 같은 시점 진행 카드 3곳(서랍, Execution Load의 Current progress, Executions의 Inspector)이 "대기 중"이
   아니며 `-1%`가 어디에도 없음(SC-002).
3. A 선택 상태에서 B 작업 실행 → 목록의 B 행 Next fire만 갱신, A의 선택·진행 표시 불변(SC-003).
4. 트리거 삭제(unschedule) 후 다른 트리거 실행 → 오류 없이 동작.
5. 로그(Event Stream, EVENTS, Logs received) 동작이 변경 전과 동일.
6. 변경 파일 확인: `git diff --stat`에 `manager.component.ts`, `manager.component.html`, changelog 외 파일이 없음(SC-004).

## 3. 변경 기록

`spec-002-changelog.md`에 변경 파일 목록과 compare 내용을 한글로 기록한다.
