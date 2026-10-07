# Data Model: 아이콘 폰트 자체 호스팅

데이터 엔티티는 없다. 정적 자원 3개의 관계만 정의한다.

## 자원 구성

| 자원 | 경로(`quartz-manager-frontend/` 기준) | 역할 |
|------|---------------------------------------|------|
| 폰트 파일 | `src/assets/fonts/material-icons/material-icons.woff2` | 아이콘 글리프(128,352 bytes, Google Material Icons v145) |
| 스타일 정의 | `src/assets/fonts/material-icons/material-icons.css` | 폰트를 `Material Icons` 글꼴로 선언(`@font-face`)하고 `.material-icons` 표시 규칙 정의 |
| 연결 | `src/index.html` | `<link href="assets/fonts/material-icons/material-icons.css" rel="stylesheet">` 한 줄 |

## 관계

```text
index.html ──<link>──▶ material-icons.css ──url()──▶ material-icons.woff2
                              ▲
mat-icon 컴포넌트(header, simple-trigger-config) ─ 글꼴 'Material Icons' 사용 ─┘
```

## 규칙

- CSS 의 `url()` 은 같은 폴더의 파일을 **상대 경로**로 가리킨다(절대 URL 금지).
- `index.html` 의 링크는 앱의 다른 자원과 같은 **상대 경로**(앞에 `/` 없음)로 쓴다.
- CSS 첫 줄 주석에 출처(Google Fonts), 버전(v145), 라이선스(Apache-2.0)를 적는다.
