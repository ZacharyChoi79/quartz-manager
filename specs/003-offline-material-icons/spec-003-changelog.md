# spec-003 변경 기록 (Changelog)

**Spec**: [spec.md](spec.md) | **작성 기준**: 헌법 v1.2.0 원칙 V | **작성일**: 2026-10-07

## 근거

운영 환경이 폐쇄망이다(헌법 원칙 VII). 화면이 자동으로 외부에서 가져오던 자원은 Material Icons 폰트 하나뿐이었고
(`src/index.html`의 Google Fonts 링크), 이 링크 때문에 ① 운영 브라우저가 외부에 접속하지 못해 아이콘 대신 글자가
보이고, ② 프로덕션 빌드의 폰트 인라인이 빌드 중 외부에 접속해 사설 인증서 환경에서 빌드가 실패했다
(`self-signed certificate in certificate chain`). 원칙 III(최소 수정)의 예외로, 폐쇄망 요건을 근거로 자체 호스팅한다.

## 검증 결과

| 항목 | 결과 |
|------|------|
| 변경 전 `npm test` (T001) | 18개 스위트 / 45개 테스트 통과 |
| **통제 실험** 변경 전 + 외부 접속 차단(`HTTPS_PROXY=http://127.0.0.1:9`) 빌드 (T001) | **실패** — `Inlining of fonts failed ... connect ECONNREFUSED 127.0.0.1:9` (Windows 오류 재현) |
| 변경 후 + 같은 조건 빌드 (T007) | **성공** — `Index html generation complete.` |
| `dist`의 `googleapis`/`gstatic` 참조 파일 수 (T008) | **0개** |
| `dist/index.html`의 `preconnect` | 0건 |
| `dist/assets/fonts/material-icons/` | `material-icons.css`(830 bytes), `material-icons.woff2`(128,352 bytes) 포함 |
| `dist` 폰트 sha256 = 저장소 폰트 sha256 (T011) | 일치 |
| 변경 후 `npm test` (T009) | 18개 스위트 / 45개 테스트 통과 (회귀 없음) |
| 웹자 경로(`/quartz-manager-ui/`) 서빙 확인 | `index.html` 200, CSS 200 `text/css`, woff2 200 `font/woff2`(128,352 bytes) |
| 브라우저 육안 확인 (T006) | **미수행** — 아이콘 3곳이 글자가 아닌 아이콘으로 보이는지, Network 외부 요청 0건인지 직접 확인 필요 |

`dist` 안의 `fontawesome` 문구는 `index.html` 15행의 **주석**뿐이며 자동 로드가 아니다(변경하지 않음).

## 변경 파일 목록

| 파일 | 변경 |
|------|------|
| `quartz-manager-frontend/src/index.html` | 1줄 교체 (+1/-1) |
| `quartz-manager-frontend/src/assets/fonts/material-icons/material-icons.css` | 신규 (830 bytes) |
| `quartz-manager-frontend/src/assets/fonts/material-icons/material-icons.woff2` | 신규 (128,352 bytes) |
| `specs/003-offline-material-icons/spec-003-changelog.md` | 신규 (이 문서) |

수정 허용 범위(tasks.md) 밖의 변경은 없다. `quartz-manager-frontend` 안에서 `git status` 에 나타나는 것은 위 2개
(`index.html` 수정, `assets/fonts/` 신규)뿐이다. (같은 저장소의 `.specify/memory/constitution.md`, `buildUI.bat`,
spec 002 문서 변경은 이번 작업 이전의 별개 변경이다.)

## 파일별 compare

### `quartz-manager-frontend/src/index.html`

```diff
-  <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
+  <link href="assets/fonts/material-icons/material-icons.css" rel="stylesheet">
```

파비콘(`favicon.ico`)·번들 스크립트와 같은 **상대 경로** 방식이다. 다른 줄(주석 처리된 fontawesome 포함)은 변경하지 않았다.

### `quartz-manager-frontend/src/assets/fonts/material-icons/material-icons.css` (신규)

Google 이 최신 브라우저에 반환하는 CSS(`@font-face` 1개 + `.material-icons` 1개)를 그대로 옮기고 `src` 만 같은 폴더의
상대 경로로 바꿨다.

```css
@font-face {
  font-family: 'Material Icons';
  font-style: normal;
  font-weight: 400;
  src: url(material-icons.woff2) format('woff2');   /* 원본: url(https://fonts.gstatic.com/...) */
}
.material-icons { /* font-family, font-size: 24px, line-height: 1, text-transform: none, 'liga' 등 원본과 동일 */ }
```

상단 주석에 출처·버전·라이선스를 기록했다. 출처 URL 문자열(`gstatic`)은 `dist` 검증(`googleapis|gstatic` 0건)을
흐리지 않도록 **CSS 주석이 아니라 이 문서에만** 적는다.

### `quartz-manager-frontend/src/assets/fonts/material-icons/material-icons.woff2` (신규)

| 항목 | 값 |
|------|----|
| 출처 URL | https://fonts.gstatic.com/s/materialicons/v145/flUhRq6tzZclQEJ-Vdg-IuiaDsNc.woff2 |
| 버전 | Google Fonts Material Icons, 파일 버전 `v145` |
| 형식 / 크기 | Web Open Font Format (Version 2) / 128,352 bytes |
| sha256 | `8265f64786397d6b832d1ca0aafdf149ad84e72759fffa9f7272e91a0fb015d1` |
| 라이선스 | Apache License 2.0 (https://www.apache.org/licenses/LICENSE-2.0) |
| 받은 날짜 | 2026-10-07 |

## 알려진 사항

- Angular 가 로컬 스타일 링크도 `media="print" onload="this.media='all'"` 방식(비동기 로드)으로 변환한다. 그래서
  아이콘 폰트가 적용되기 직전에 아이콘 이름 글자(`menu`, `event`)가 **잠깐 보일 수 있다**. 기능 영향은 없고,
  막으려면 `angular.json`/`styles.css` 변경이 필요해 범위 밖이므로 수용했다.
- 폰트는 v145 로 고정된다. 현재 화면이 쓰는 아이콘(`menu`, `event`)은 포함되어 있다.
- Apache-2.0 의 라이선스 전문 사본 파일은 포함하지 않았다(FR-007 의 3개 범위). 엄격한 준수가 필요하면 spec 개정 후
  `LICENSE` 파일을 추가해야 한다.
- 반영하려면 `quartz-manager-starter-ui` webjar 를 다시 빌드·교체해야 한다(`specs/002-websocket-ui-refresh/buildAndPatch.md` 참고).
  새 jar 에는 `META-INF/resources/quartz-manager-ui/assets/fonts/material-icons/` 가 포함된다.
