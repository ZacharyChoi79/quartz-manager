# Phase 0 Research: 아이콘 폰트 자체 호스팅

Technical Context 에 `NEEDS CLARIFICATION` 은 없다. 아래는 코드·빌드 실험으로 확인한 결정이다.

## 결정 1: 폰트 자원은 `src/assets` 에 두고 `index.html` 에서 상대 경로 `<link>` 로 연결한다

- **Decision**: `assets/fonts/material-icons/material-icons.css` 를 `index.html` 의 기존 외부 링크 자리에 둔다.
- **Rationale**:
  - `angular.json` 의 `assets` 가 이미 `src/assets` 전체를 빌드 결과에 복사한다 → 설정 변경 불필요(스파이크에서
    `dist/assets/fonts/material-icons/` 복사 확인).
  - 이 앱의 모든 자원 참조가 이미 **상대 경로**다(번들 스크립트 `main.*.js`, `favicon.ico`, 컴포넌트의
    `assets/image/...`). `<base href>` 도 없다. 같은 규칙을 쓰면 `/quartz-manager-ui/index.html` 아래에서 스크립트가
    로드되는 환경이면 폰트 CSS 도 반드시 로드된다.
  - Angular 의 폰트 인라인 최적화는 Google Fonts·Adobe 주소만 대상이므로 로컬 링크는 빌드 중 접속하지 않는다
    (스파이크: 죽은 프록시에서도 성공).
- **Alternatives considered**:
  - `angular.json` 의 `styles` 에 등록 — 빌드 설정 변경이라 FR-008 위반. 기각.
  - `src/styles.css` 에 `@import` — 기존 스타일 파일 수정이라 FR-008 위반. 기각.
  - npm 패키지(`material-icons`, `@fontsource/...`) — 의존성 추가, FR-008 위반이며 폐쇄망 `npm install` 부담. 기각.

## 결정 2: 폰트는 현재 화면이 쓰는 것과 동일한 버전(v145)의 woff2 한 개를 그대로 사용한다

- **Decision**: `https://fonts.gstatic.com/s/materialicons/v145/flUhRq6tzZclQEJ-Vdg-IuiaDsNc.woff2`(128,352 bytes,
  `Web Open Font Format (Version 2)`)를 받아 저장한다.
- **Rationale**: Google 의 CSS 가 최신 브라우저(woff2)에 반환하는 단일 파일이며, 현재 운영·빌드 결과가 참조하는
  파일과 같아 표시 차이가 없다(SC-006). 이 CSS 는 `@font-face` 하나와 `.material-icons` 클래스 하나로 구성된다.
- **Alternatives considered**: woff/ttf 다중 포맷 포함 — 구형 브라우저는 범위 밖(spec 가정)이고 파일이 늘어
  기각.

## 결정 3: CSS 는 Google 이 반환한 규칙을 그대로 옮기고 `src` 만 상대 경로로 바꾼다

- **Decision**: `@font-face` 의 `src: url(material-icons.woff2) format('woff2')`, `.material-icons` 규칙은 원본과
  동일(크기 24px, `line-height: 1`, `-webkit-font-feature-settings: 'liga'` 등). 파일 맨 위에 출처·버전·라이선스
  주석을 넣는다(FR-005).
- **Rationale**: `mat-icon` 이 의존하는 글리프 이름 → 아이콘 변환(리가처)과 크기·정렬이 원본과 같아야 한다(FR-006).
  CSS `url()` 은 CSS 파일 기준 상대 경로이므로 폴더 이동에도 안전하다.

## 결정 4: 검증은 "외부 접속 차단 상태의 빌드 + dist 검색"으로 한다

- **Decision**: 죽은 프록시(`HTTPS_PROXY=http://127.0.0.1:9`)를 설정해 외부 접속을 차단한 채 `ng build` 를 실행하고,
  `dist` 에서 `googleapis|gstatic|fontawesome` 자동 로드 참조를 검색한다. 통제군(변경 전)이 같은 조건에서 실패함을
  함께 보여 준다.
- **Rationale**: 스파이크로 이 방법이 현재 오류를 재현함을 확인했다. 인터넷을 실제로 끊지 않아도 재현 가능해
  개발 PC 에서 반복하기 쉽다.

## 알려진 사항 / 위험

- **스타일 비동기 로드**: Angular 가 로컬 `<link>` 도 `media="print" onload="this.media='all'"` 방식으로 비동기
  로드하도록 변환한다(`<noscript>` 대체 포함). 아이콘 폰트가 적용되기 전 짧은 순간 아이콘 이름 글자가 보일 수
  있다(FOUT). 이전(Google 링크 인라인)에는 CSS 가 HTML 에 인라인되어 있었다. 기능 영향은 없고
  `angular.json`/`styles.css` 변경 없이는 막을 수 없어 수용한다.
- **라이선스**: Material Icons 는 Apache-2.0. CSS 상단 주석에 출처·버전·라이선스 URL 을 기록하고 changelog 에도
  남긴다. 라이선스 전문 사본 파일까지 요구하는 엄격한 준수가 필요하면 4번째 파일(`LICENSE`) 추가가 필요하며
  FR-007 의 3개 범위를 넘으므로 필요 시 spec 을 개정한다.
- **폰트 고정**: v145 로 고정되어 원본의 아이콘 추가는 반영되지 않는다(현재 사용 아이콘 `menu`, `event` 는 포함).
- 이번 계획 단계에서는 저장소를 변경하지 않았다. 스파이크는 `/tmp/qm-spike` 임시 복사본에서만 수행했다.
