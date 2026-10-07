# Contract: 화면 자원 계약 (외부 접속 금지)

## 화면이 로드하는 자원

| 요청 | 출처 | 허용 |
|------|------|------|
| `assets/fonts/material-icons/material-icons.css` | 같은 오리진(webjar) | 허용 |
| `assets/fonts/material-icons/material-icons.woff2` | 같은 오리진(CSS 가 참조) | 허용 |
| `fonts.googleapis.com`, `fonts.gstatic.com`, `use.fontawesome.com` 등 외부 호스트 | 외부 | **금지**(자동 로드 0건) |

## 빌드 결과물 계약

- `dist/index.html` 에 외부 폰트 `<link>`/`preconnect`/`@font-face src:url(https://...)` 가 없다.
- `dist/assets/fonts/material-icons/` 에 `material-icons.css`, `material-icons.woff2` 가 포함된다.
- `grep -rE "googleapis|gstatic|fontawesome" dist` 는 자동 로드 참조를 찾지 못한다
  (`index.html` 의 주석 속 `fontawesome` 문구는 주석이므로 허용).

## 변경 금지(FR-008)

`angular.json`, `package*.json`, 컴포넌트·서비스·모델, `src/styles.css`, Roboto, `manager.component.*`, qssb, nginx.
