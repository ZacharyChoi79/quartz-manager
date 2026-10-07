# 빌드 및 적용(패치) 가이드 — spec 002 프런트엔드 변경

**대상 변경**: `quartz-manager-frontend/src/app/views/manager/manager.component.ts` / `.html` (WebSocket 메시지 기반 화면 갱신)

**환경**: 로컬 개발 PC = Windows, 운영 서버 = Linux RHEL 9, 서버 앱 = Maven 으로 빌드하는 qssb

**관련 문서**: [spec.md](spec.md) · [spec-002-changelog.md](spec-002-changelog.md) · qssb `docs/portingToLinuxNoSubscription.md`

---

## 1. 전체 구조 이해 (왜 이렇게 패치하는가)

qssb 는 관리 콘솔 화면을 **직접 가지고 있지 않다.** 화면은 Maven 의존성
`quartz-manager-starter-ui:5.0.1` jar 안에 **빌드된 정적 파일**(`META-INF/resources/quartz-manager-ui/`)
로 들어 있고, qssb 가 이를 그대로 서빙한다.

```text
[이 저장소] quartz-manager-frontend (Angular 소스, 수정한 곳)
      │  mvn -Pbuild-webjar            (기본: Maven 이 Node/npm 을 로컬 저장소 캐시에서 풀어 npm install + build)
      │  mvn -Pbuild-webjar-local-npm  (--local-npm: PC 에 설치된 Node/npm 으로 npm run build)
      ▼
quartz-manager-starter-ui-5.0.1.jar   → 로컬 ~/.m2 에 설치
      │
      ├─ 방법 1 (권장·최소 패치): 이 jar 1개만 서버 /opt/qssb/BOOT-INF/lib/ 에서 교체
      │
      └─ 방법 2 (전체 재배포): qssb 를 다시 mvn package → explode → BOOT-INF 전체 업로드
```

서버 `start.sh` 는 `java -cp BOOT-INF/classes:BOOT-INF/lib/*` 로 실행한다. 따라서 서버에서 필요한 것은
**JDK 25 런타임뿐**이고, 서버에서는 빌드하지 않는다(Maven/Node/git 불필요).

> ⚠️ **가장 중요한 주의**: qssb 의 `buildQuartzManager.bat` 은 GitHub 에서 포크
> (`ZacharyChoi79/quartz-manager`)를 **새로 clone** 해서 빌드한다. 지금 수정한 코드는
> **아직 push 되지 않은 로컬 변경**이므로, 그 스크립트를 그대로 쓰면 **변경이 반영되지 않는다.**
> 아래 §4 의 두 가지 방법 중 하나를 반드시 선택한다.

---

## 2. 필수 프로그램 설치

### 2-1. 로컬 PC (Windows) — 빌드용

| 프로그램 | 버전 | 용도 | 비고 |
|----------|------|------|------|
| JDK | 25 (최소 21) | Maven 실행, qssb 빌드 | quartz-manager 는 `java.version=21`, qssb 는 JDK 25. **25 하나로 둘 다 가능** |
| Maven | 3.9+ | webjar/qssb 빌드 | 대신 `quartz-manager-parent\mvnw.cmd` 사용 가능(설치 불필요) |
| Git | 최신 | 소스 관리/clone(방법 B) | |
| Node.js | 24.x(`^20.19` / `^22.12` / `>=24`) | `--local-npm` 모드의 빌드, `npm test` | 기본 모드(`build-webjar`)에서는 불필요: Maven 이 Node v22.13.0 / npm 10.9.0 을 **로컬 저장소 캐시**(`com\github\eirslett\node`, `\npm`)에서 `target\tmp` 로 풀어 사용(캐시에 없을 때만 다운로드) |
| OpenSSH 클라이언트 또는 WinSCP | - | 서버 업로드(`scp`) | Windows 10/11 기본 포함(`ssh`, `scp`) |

설치 예시(PowerShell, 관리자 권한 또는 사용자 권한):

```powershell
winget install EclipseAdoptium.Temurin.25.JDK
winget install Apache.Maven          # mvnw.cmd 를 쓸 거면 생략 가능
winget install Git.Git
winget install OpenJS.NodeJS.LTS     # npm test 를 로컬에서 돌릴 때만
```

설치 후 **새 터미널**을 열어 확인한다.

```powershell
java -version        # 25.x
mvn -version         # 3.9+ (JAVA_HOME 이 JDK 25 를 가리켜야 함)
git --version
```

`JAVA_HOME` 이 비어 있으면 설정한다.

```powershell
setx JAVA_HOME "C:\Program Files\Eclipse Adoptium\jdk-25.0.x-hotspot"
```

(경로는 실제 설치 폴더로 바꾼다. 설정 후 새 터미널을 연다.)

사내망에서 Maven Central/npm 에 프록시가 필요하면 `%USERPROFILE%\.m2\settings.xml` 의 `<proxies>` 와
`npm config set proxy/https-proxy` 를 설정해야 한다(webjar 빌드는 Node 다운로드와 `npm install` 에 인터넷을 쓴다).

### 2-2. 운영 서버 (RHEL 9) — 실행용

**추가 설치할 것이 없다.** 이미 있는 것만 필요하다.

| 항목 | 상태 |
|------|------|
| JDK 25 런타임 (`/usr/lib/jvm/temurin-25-jdk`) | 이미 설치됨(`portingToLinuxNoSubscription.md` §2) |
| `qssb` 서비스 계정, `/opt/qssb/` | 이미 구성됨 |
| `scp` 수신 가능(sshd) | 이미 사용 중 |

서버에는 Maven/Node/git 을 **설치하지 않는다.**

---

## 3. 사전 확인 (로컬 PC, 이 저장소 루트)

```powershell
cd C:\...\quartz-manager

git status --short
```

기대: 이번 작업 변경은 아래 2개뿐이다(다른 `.gitignore` 변경 등은 이번 작업과 무관).

```text
 M quartz-manager-frontend/src/app/views/manager/manager.component.html
 M quartz-manager-frontend/src/app/views/manager/manager.component.ts
```

(선택) 프런트엔드 단독 검증:

```powershell
cd quartz-manager-frontend
npm ci
npm test            # 18개 스위트 / 45개 테스트 통과가 기준선
npm run build       # 성공해야 함 (scss 예산 경고는 기존 것이므로 무시)
cd ..
```

---

## 4. 빌드 — quartz-manager UI 웹자(jar) 만들기

**방법 A (권장): 로컬 작업 트리에서 직접 빌드.** push 없이 지금 수정한 코드가 그대로 반영된다.
저장소 루트의 [buildUI.bat](../../buildUI.bat) 한 번이면 된다.

```powershell
cd C:\...\quartz-manager
.\buildUI.bat                       # Maven 기본 로컬 저장소(%USERPROFILE%\.m2) 사용
.\buildUI.bat D:\workspace\localrepo   # 지정한 로컬 저장소 사용 (portable/오프라인 저장소)
.\buildUI.bat D:\workspace\localrepo --replace   # 빌드 전에 저장소의 기존 jar 를 .bak 로 백업한 뒤 교체
.\buildUI.bat D:\workspace\localrepo --local-npm  # PC 에 설치된 Node/npm 사용(-Pbuild-webjar-local-npm)
```

**기본 모드는 Maven 이 관리하는 Node/npm 을 쓴다**(프로필 `build-webjar`, 원본 그대로).
- `frontend-maven-plugin` 이 Node v22.13.0 / npm 10.9.0 을 **로컬 Maven 저장소 캐시**
  (`<저장소>\com\github\eirslett\node\22.13.0\`, `...\npm\10.9.0\`)에서 꺼내 `quartz-manager-starter-ui\target\tmp` 에 풀고,
  **캐시에 없을 때만** 다운로드한다. 이어서 같은 곳에서 `npm install` 과 `npm run build` 를 실행한다.
- 주의: **`npm install` 은 npm 레지스트리(또는 npm 캐시)가 필요**하다. Node 가 캐시되어 있어도 이 단계는 인터넷이 필요할 수 있다.
- 스크립트는 시작할 때 저장소에 `frontend-maven-plugin 1.11.0`, `node\22.13.0`, `npm\10.9.0` 이 있는지 확인해 없으면 `[WARN]` 을 낸다.

`--local-npm`(`-n`)을 주면 **PC 에 설치된 Node.js/npm(PATH)** 을 쓴다(프로필 `build-webjar-local-npm`).
- Node 다운로드/압축 해제 없이 프런트엔드를 `quartz-manager-frontend` 폴더에서 **제자리 빌드**한다(`target\tmp` 복사 없음).
- 시작 시 `node`/`npm` 존재와 Node 버전(`^20.19` / `^22.12` / `>=24`)을 확인한다.
- `quartz-manager-frontend\node_modules` 가 **있으면 `npm ci` 를 건너뛴다**.
- `exec-maven-plugin 3.5.0` 이 로컬 저장소에 있어야 한다(처음 한 번만 다운로드).

`--replace`(또는 `-r`)를 주면 로컬 저장소에 이미 있는 `quartz-manager-starter-ui-5.0.1.jar` 를
`quartz-manager-starter-ui-5.0.1.jar.bak.<타임스탬프>` 로 같은 폴더에 백업한 뒤 새 jar 로 교체한다
(옵션이 없으면 백업 없이 덮어쓴다). 백업 파일은 `.jar` 로 끝나지 않으므로 Maven 이 의존성으로 쓰지 않는다.

파라미터로 로컬 저장소 경로를 주면 Maven 에 `-Dmaven.repo.local` 로 전달하고, 빌드된 jar 도 그 저장소에
설치되며 스크립트의 검증 단계도 그 경로의 jar 를 확인한다.

`buildUI.bat` 은 JDK 확인 → (`mvn` 이 없으면 `mvnw.cmd` 사용) 빌드·설치 → jar 크기(1MB 이상)와
번들 안의 `Last fired:` 문구 확인(§4-1)까지 자동으로 수행한다. 직접 실행하려면 아래와 같다.

```powershell
cd quartz-manager-parent
.\mvnw.cmd -DskipTests -Pbuild-webjar -pl quartz-manager-starter-ui -am install
```

Maven 을 설치했다면 `mvn -DskipTests -Pbuild-webjar -pl quartz-manager-starter-ui -am install` 도 동일하다.

기본 모드(`build-webjar`)의 내부 동작: `quartz-manager-frontend` 를 `quartz-manager-starter-ui\target\tmp` 로 복사(`node_modules`, `dist` 제외)
→ Node v22.13.0 자동 설치 → `npm install` → `npm run build` → 결과를
`META-INF/resources/quartz-manager-ui/` 로 이동 → jar 로 패키징 → `%USERPROFILE%\.m2` 에 설치. 약 1~2분.

**방법 B: 변경을 커밋·push 한 뒤 기존 qssb 스크립트 사용.** (포크 저장소에 반영해 두고 싶을 때)

```powershell
git add quartz-manager-frontend/src/app/views/manager/manager.component.ts `
        quartz-manager-frontend/src/app/views/manager/manager.component.html `
        specs/002-websocket-ui-refresh
git commit -m "WebSocket 메시지 기반 화면 갱신 (spec 002)"
git push origin master
# 이후 qssb 저장소에서
buildQuartzManager.bat        # GitHub 에서 clone 후 -Pbuild-webjar 로 빌드/설치
```

> `git add` 는 위 경로만 지정한다. `.claude/`, `.specify/`, `.mcp.json`, `.gitignore` 등은 이번 변경과
> 무관하므로 포함하지 않는다.

### 4-1. 빌드 결과 검증 (반드시 수행)

`buildUI.bat` 을 썼다면 크기·문구 확인은 이미 자동으로 수행된다. 수동으로 확인하려면 아래를 따른다.

```powershell
$jar = "$env:USERPROFILE\.m2\repository\it\fabioformosa\quartz-manager\quartz-manager-starter-ui\5.0.1\quartz-manager-starter-ui-5.0.1.jar"
Get-Item $jar | Select-Object Length, LastWriteTime
```

- **크기가 1MB 이상**이어야 정상이다(정상 빌드는 약 2.8MB). 5KB 미만이면 빈 웹자(npm 빌드 실패)이므로 §9 를 본다.
- **LastWriteTime 이 방금 시각**이어야 한다(오래된 jar 이면 install 이 안 된 것).

변경 코드 포함 여부 확인(번들 안에 새 문구가 있는지):

```powershell
$tmp = Join-Path $env:TEMP "uicheck"
Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory $tmp | Out-Null
Push-Location $tmp
jar xf $jar
Get-ChildItem -Recurse -Filter "main.*.js" | Select-String -SimpleMatch "Last fired:" -List | Select-Object Path
Pop-Location
```

`main.<해시>.js` 한 줄이 출력되면 새 코드가 들어간 것이다. 변경 전 번들 이름은 `main.f5b0d42b232197f2.js` 였으므로
**해시 부분이 달라져야 한다.**

---

## 5. 적용(패치) — 방법 1: jar 1개만 교체 (권장)

qssb 코드는 바뀌지 않았으므로 **qssb 를 다시 빌드할 필요가 없다.** 서버의
`BOOT-INF/lib/quartz-manager-starter-ui-5.0.1.jar` 한 파일만 바꾸면 된다.

### 5-1. 로컬 → 서버 업로드 (Windows PowerShell)

```powershell
scp $jar root@rhel-host:/tmp/quartz-manager-starter-ui-5.0.1.jar
```

(`rhel-host` 는 실제 서버 주소. 계정은 기존 업로드와 동일하게 사용한다.)

### 5-2. 서버에서 교체 (RHEL 9, root 로 로그인)

```bash
cd /opt/qssb

# 1) 먼저 애플리케이션을 정지한다 (실행 중인 JVM 이 열고 있는 jar 를 바꾸면 안 된다)
sudo -u qssb ./stop.sh
#   stop.sh 가 없거나 응답이 없으면: kill -TERM $(cat /opt/qssb/.run/app.pid)

# 2) 기존 jar 백업
cp -p BOOT-INF/lib/quartz-manager-starter-ui-5.0.1.jar \
      /opt/qssb/quartz-manager-starter-ui-5.0.1.jar.bak.$(date +%Y%m%d%H%M)

# 3) 교체
cp /tmp/quartz-manager-starter-ui-5.0.1.jar BOOT-INF/lib/quartz-manager-starter-ui-5.0.1.jar
chown qssb:qssb BOOT-INF/lib/quartz-manager-starter-ui-5.0.1.jar
chmod 644 BOOT-INF/lib/quartz-manager-starter-ui-5.0.1.jar

# 4) SELinux 컨텍스트 복원 (Enforcing 인 경우)
restorecon -v BOOT-INF/lib/quartz-manager-starter-ui-5.0.1.jar

# 5) 기동
sudo -u qssb ./start.sh
tail -f /opt/qssb/.run/app.log      # 에러 없이 기동되는지 확인
```

> 계정 전환 방식(`sudo -u qssb` 대신 `su - qssb -c` 등)은 서버의 기존 운영 방식을 따른다.
> 중요한 것은 **정지 → 교체 → 기동** 순서다.

**백업 파일은 `/opt/qssb/BOOT-INF/lib/` 안에 두지 않는다.** `start.sh` 의 클래스패스가
`BOOT-INF/lib/*` 이므로 `.jar` 로 끝나는 백업이 lib 안에 있으면 두 버전이 함께 로드된다
(위 예시는 `/opt/qssb/` 바로 아래에 백업하고 확장자도 `.bak...` 로 끝난다).

## 6. 적용 — 방법 2: 전체 재배포 (qssb 코드도 함께 바뀌었을 때)

jar 하나가 아니라 qssb 전체를 재배포해야 하는 경우(예: qssb 소스도 수정). 기존 절차 그대로다.

```text
1) §4 방법 A 또는 B 로 starter-ui jar 를 ~/.m2 에 설치
2) qssb 저장소에서  buildApp.bat       → target\batch-scheduler-integration-1.0.0.jar
3)                 explodeJar.bat     → target\exploded\BOOT-INF\{classes,lib}
4) application-mssql.yml 의 접속 정보 확인 (portingToLinuxNoSubscription.md §3-4)
5) scp -r target\exploded\BOOT-INF root@rhel-host:/opt/qssb/   (기존 BOOT-INF 는 먼저 정지 후 교체)
```

자세한 단계와 권한/SELinux 처리는 qssb `docs/portingToLinuxNoSubscription.md` §3-2 ~ §4, §7 ~ §9 를 따른다.
이 방법에서도 BOOT-INF/lib 의 `quartz-manager-starter-ui-5.0.1.jar` 는 §4 에서 만든 새 jar 가 들어 있어야 한다.

---

## 7. 적용 후 검증

1. **브라우저 캐시 무효화**: 접속 후 `Ctrl+F5`(강력 새로고침). 파일명 해시가 바뀌므로 대부분 자동 갱신되지만,
   `index.html` 이 캐시되면 옛 `main.<해시>.js` 를 계속 요청한다.
   nginx 에서 `/quartz-manager-ui/` 를 캐시하고 있다면 캐시를 비운다(`nginx적용.md` 참고).
2. 개발자 도구 Network 에서 로드되는 `main.<해시>.js` 가 **`main.f5b0d42b232197f2.js` 가 아닌 새 해시**인지 확인.
3. WebSocket 연결(`/quartz-manager/progress/...`, `/logs/...`)과 STOMP 메시지 수신은 기존과 동일하다
   (연결 코드는 변경하지 않았다).
4. [quickstart.md](quickstart.md) 2번 시나리오 수행:
   - 트리거 선택 → "Trigger Now" → Dashboard 표/서랍, Triggers 표/상세의 **Next fire / Previous fire** 가 새로고침 없이 갱신
   - 진행 카드가 "Waiting for progress events" 에 머무르지 않고 `Last fired: … · Next: …` 표시, `-1%` 미노출
   - 선택하지 않은 트리거의 작업을 실행해도 목록의 해당 행 Next fire 갱신
5. 결과를 [spec-002-changelog.md](spec-002-changelog.md) 의 "수동 시나리오 (T012)" 항목에 기록한다.

> 참고: 운영 서버가 nginx 뒤에서 WebSocket 업그레이드가 안 되는 경우 SockJS 가 xhr 폴링으로 대체되어 동작한다
> (기능은 동작). WebSocket 자체를 쓰려면 nginx 의 `Upgrade`/`Connection` 헤더 전달 설정이 필요하며 이 변경과 별개다.

---

## 8. 롤백

문제가 있으면 백업 jar 로 되돌린다(서버).

```bash
cd /opt/qssb
sudo -u qssb ./stop.sh
cp -p /opt/qssb/quartz-manager-starter-ui-5.0.1.jar.bak.<백업시각> BOOT-INF/lib/quartz-manager-starter-ui-5.0.1.jar
chown qssb:qssb BOOT-INF/lib/quartz-manager-starter-ui-5.0.1.jar
restorecon -v BOOT-INF/lib/quartz-manager-starter-ui-5.0.1.jar
sudo -u qssb ./start.sh
```

로컬 PC 의 `~/.m2` 에 설치된 jar 는 이번 빌드로 덮어써졌으므로, 이전 버전이 필요하면 코드를 되돌린 뒤 §4 를 다시 수행한다.

---

## 9. 문제 해결

| 증상 | 원인 / 조치 |
|------|-------------|
| 빌드한 jar 가 5KB 미만 | `-Pbuild-webjar` 를 빼먹었거나 node/npm 단계 실패. Maven 로그에서 `install node and npm`, `npm install`, `npm run build` 단계 확인. 프록시 설정 확인(§2-1) |
| `node or npm not found on PATH` / `Unsupported Node.js version` (`--local-npm` 모드) | Node.js 가 PATH 에 없거나 버전이 낮음. `node -v` 확인 후 `^20.19` / `^22.12` / `>=24` 설치,  또는 `--local-npm` 없이(기본 모드) 실행 |
| `--local-npm` 모드에서 `npm ci` 가 실패 | `node_modules` 가 없어 레지스트리 접속이 필요. 프록시/레지스트리 설정(`npm config`) 후 재시도하거나, 인터넷 PC 에서 설치한 같은 OS 의 `node_modules` 를 `quartz-manager-frontend` 에 복사(그러면 `npm ci` 를 건너뜀) |
| `--local-npm` 모드에서 `npm run build` 실패 | 프런트엔드 폴더에서 직접 `npm run build` 를 실행해 같은 오류가 나는지 확인(소스/의존성 문제인지 구분) |
| `Cannot download Node` / `npm install` 실패 | 인터넷/프록시 문제. `settings.xml` 프록시와 `npm config` 확인 |
| `invalid target release: 21/25` | `JAVA_HOME` 이 JDK 21 이상을 가리키는지 확인 |
| 새 코드가 안 보임 | (1) 방법 B 인데 push 안 함, (2) 서버 jar 교체 후 재기동 안 함, (3) 브라우저/nginx 캐시. §7 확인 |
| 서버 기동 시 클래스 중복/이상 동작 | `BOOT-INF/lib` 안에 `starter-ui` jar 가 2개 이상(백업을 lib 에 둠). 하나만 남긴다 |
| 기동 실패(`app.log`) | 롤백(§8) 후 로그 확인. jar 소유권/SELinux(`restorecon`) 재확인 |
| 이번 변경이 반영 안 된 채 `buildQuartzManager.bat` 만 실행 | 정상 동작이다(원격 포크를 clone). §1 의 주의 참조 — 방법 A 사용 또는 push 후 실행 |

---

## 10. 요약 체크리스트

- [ ] JDK 25 / Maven(또는 `mvnw.cmd`) / Git 설치 확인 (로컬 Windows)
- [ ] `git status` 로 변경 파일이 의도한 2개인지 확인
- [ ] §4 방법 A(또는 B)로 `quartz-manager-starter-ui-5.0.1.jar` 빌드·설치
- [ ] jar 크기 1MB 이상 + `Last fired:` 문구 포함 확인
- [ ] `scp` 로 서버 `/tmp` 업로드
- [ ] 서버 정지 → 백업(lib 밖) → 교체 → 소유권/`restorecon` → 기동
- [ ] 브라우저 강제 새로고침 후 새 `main.<해시>.js` 확인, quickstart 시나리오 수행
- [ ] 결과를 `spec-002-changelog.md` 에 기록
