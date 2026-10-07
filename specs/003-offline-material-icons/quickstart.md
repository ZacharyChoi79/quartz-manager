# Quickstart: 검증 가이드

## 사전 조건

- `cd quartz-manager-frontend && npm ci` (이미 `node_modules` 가 있으면 생략)

## 1. 외부 접속 차단 상태의 빌드 (SC-003)

외부 접속을 막기 위해 죽은 프록시를 지정한다(PowerShell: `$env:HTTPS_PROXY="http://127.0.0.1:9"`, cmd:
`set HTTPS_PROXY=http://127.0.0.1:9`).

```bash
HTTPS_PROXY=http://127.0.0.1:9 HTTP_PROXY=http://127.0.0.1:9 npm run build
```

기대: `Index html generation complete.` (변경 전에는 `Inlining of fonts failed ... ECONNREFUSED` 로 실패).

## 2. dist 검증 (SC-004)

```bash
grep -rlE "googleapis|gstatic" dist           # 출력 없음
ls dist/assets/fonts/material-icons           # material-icons.css, material-icons.woff2
grep -o '<link[^>]*material-icons[^>]*>' dist/index.html
```

## 3. 회귀 (SC-006)

```bash
npm test      # 18 suites / 45 tests 통과가 기준선
```

## 4. 브라우저 확인 (SC-001, SC-002)

- 헤더 메뉴 버튼, 트리거 설정 화면의 날짜 선택 버튼 2개가 **글자가 아닌 아이콘**으로 보인다.
- 개발자 도구 Network 에서 외부 호스트 요청이 0건이다(필터: 도메인이 서버 호스트가 아닌 항목 없음).
- 인터넷을 끊거나 해당 호스트를 차단한 상태에서도 동일하다.

## 5. 변경 범위 확인 (SC-005)

`git status --short` 에서 변경 파일이 `src/index.html`, `src/assets/fonts/material-icons/*` 와 changelog 뿐이다.

## 6. 변경 기록

`spec-003-changelog.md` 에 변경 파일 목록과 compare 내용, 근거(헌법 원칙 VII)를 한글로 기록한다.
