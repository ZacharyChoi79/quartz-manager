@echo off
setlocal
rem Capture the script directory BEFORE parsing arguments: SHIFT also shifts %0, which
rem would break any later %~dp0 reference.
set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"

rem buildUI.bat -- Builds the quartz-manager UI webjar (quartz-manager-starter-ui)
rem from THIS working tree (including uncommitted frontend changes) and installs
rem it into the local Maven repository (%USERPROFILE%\.m2). See section 4 of
rem specs\002-websocket-ui-refresh\buildAndPatch.md.
rem
rem Unlike qssb's buildQuartzManager.bat, this script does NOT clone the GitHub
rem fork, so local (not yet pushed) changes are included.
rem
rem By default the Node.js/npm installed on this PC (PATH) is used (profile
rem build-webjar-local-npm): no Node download, and the frontend is built in place.
rem Use --maven-node to let Maven download Node/npm instead (profile build-webjar).
rem
rem Requirements: JDK 21+ (25 recommended) on PATH or JAVA_HOME. Maven is optional
rem (falls back to quartz-manager-parent\mvnw.cmd). Node.js ^20.19 / ^22.12 / >=24
rem and npm on PATH (default mode). If quartz-manager-frontend\node_modules exists,
rem "npm ci" is skipped and the existing node_modules is used (delete the folder to
rem force a clean "npm ci", which needs the npm registry or a populated npm cache).
rem
rem Usage:
rem   buildUI.bat [LOCAL_REPO_PATH] [--replace] [--maven-node]
rem
rem   --maven-node, -m Optional. Use the Maven-managed Node/npm (-Pbuild-webjar):
rem                    downloads Node v22.13.0 and runs npm install (needs internet).
rem   --replace, -r    Optional. Before building, back up the existing
rem                    quartz-manager-starter-ui-5.0.1.jar in the local repository to
rem                    <jar>.bak.<timestamp> (next to it), then let the build replace
rem                    the jar. Without this option the jar is simply overwritten.
rem   LOCAL_REPO_PATH  Optional. Maven local repository to use (passed to Maven as
rem                    -Dmaven.repo.local). The webjar is installed there, and the
rem                    verification step reads the jar from there. When omitted,
rem                    Maven's default local repository (%USERPROFILE%\.m2\repository,
rem                    or the localRepository in settings.xml) is used.
rem   Examples:
rem     buildUI.bat
rem     buildUI.bat D:\workspace\localrepo
rem     buildUI.bat D:\workspace\localrepo --replace
rem     buildUI.bat --maven-node
rem
rem Run this script from the quartz-manager repository root (where it lives).

set "LOCAL_REPO="
set "REPLACE="
set "MAVEN_NODE="
set "REPO_ARG=-Dbuildui.default.repo=true"
set "REPO_ROOT=%USERPROFILE%\.m2\repository"

:parse
if "%~1"=="" goto parsed
if "%~1"=="/?" goto usage
if /i "%~1"=="-h" goto usage
if /i "%~1"=="--help" goto usage
if /i "%~1"=="--replace" goto optreplace
if /i "%~1"=="-r" goto optreplace
if /i "%~1"=="--maven-node" goto optmavennode
if /i "%~1"=="-m" goto optmavennode
for %%I in ("%~1") do set "LOCAL_REPO=%%~fI"
goto nextarg
:optreplace
set "REPLACE=1"
goto nextarg
:optmavennode
set "MAVEN_NODE=1"
:nextarg
shift
goto parse

:parsed
if defined LOCAL_REPO (
    set "REPO_ARG=-Dmaven.repo.local=%LOCAL_REPO%"
    set "REPO_ROOT=%LOCAL_REPO%"
)
echo [buildUI] Maven local repository: %REPO_ROOT%

set "PARENT_DIR=%SCRIPT_DIR%quartz-manager-parent"
set "JAR_PATH=%REPO_ROOT%\it\fabioformosa\quartz-manager\quartz-manager-starter-ui\5.0.1\quartz-manager-starter-ui-5.0.1.jar"
set "CHECK_DIR=%TEMP%\quartz-manager-ui-check"
set "MIN_JAR_BYTES=1000000"

if not exist "%PARENT_DIR%\pom.xml" (
    echo [buildUI][ERROR] quartz-manager-parent\pom.xml not found. Run this script from the quartz-manager repository root.
    exit /b 1
)
if not exist "%SCRIPT_DIR%quartz-manager-frontend\package.json" (
    echo [buildUI][ERROR] quartz-manager-frontend\package.json not found.
    exit /b 1
)

echo [buildUI] Checking required tools...
where java >nul 2>&1 || (echo [buildUI][ERROR] java not found on PATH. Install JDK 25 ^(minimum 21^) and set JAVA_HOME. & exit /b 1)

set "BUILD_PROFILE=-Pbuild-webjar-local-npm"
set "SKIP_INSTALL=false"
if defined MAVEN_NODE goto skipnodecheck
set "BUILD_PROFILE=-Pbuild-webjar-local-npm"
where node >nul 2>&1
if errorlevel 1 goto nonode
where npm >nul 2>&1
if errorlevel 1 goto nonode
set "NODE_MAJOR=0"
set "NODE_MINOR=0"
for /f "tokens=1,2 delims=v." %%A in ('node -v') do set "NODE_MAJOR=%%A" & set "NODE_MINOR=%%B"
set "NODE_OK=0"
if %NODE_MAJOR% GEQ 24 set "NODE_OK=1"
if %NODE_MAJOR% EQU 22 if %NODE_MINOR% GEQ 12 set "NODE_OK=1"
if %NODE_MAJOR% EQU 20 if %NODE_MINOR% GEQ 19 set "NODE_OK=1"
if "%NODE_OK%"=="0" goto badnode
echo [buildUI] Using the local Node.js v%NODE_MAJOR%.%NODE_MINOR% and npm from PATH.
if exist "%SCRIPT_DIR%quartz-manager-frontend\node_modules\" set "SKIP_INSTALL=true"
if "%SKIP_INSTALL%"=="true" echo [buildUI] node_modules found: skipping npm ci.
if "%SKIP_INSTALL%"=="false" echo [buildUI] node_modules not found: npm ci will run ^(needs the npm registry or an npm cache^).
goto nodechecked
:skipnodecheck
set "BUILD_PROFILE=-Pbuild-webjar"
echo [buildUI] --maven-node: Maven will download Node/npm ^(needs internet^).
goto nodechecked
:nodechecked
if defined MAVEN_NODE goto preflightdone
if not exist "%REPO_ROOT%\org\codehaus\mojo\exec-maven-plugin\3.5.0\exec-maven-plugin-3.5.0.jar" echo [buildUI][WARN] exec-maven-plugin 3.5.0 is not in the local repository ^(%REPO_ROOT%^). Maven must download it once: internet or a proxy is required.
:preflightdone

set "MVN_CMD="
where mvn >nul 2>&1 && set "MVN_CMD=mvn"
if not defined MVN_CMD (
    if exist "%PARENT_DIR%\mvnw.cmd" (
        set "MVN_CMD=%PARENT_DIR%\mvnw.cmd"
        echo [buildUI] mvn not found on PATH. Using the bundled Maven wrapper ^(mvnw.cmd^).
    ) else (
        echo [buildUI][ERROR] Neither mvn on PATH nor quartz-manager-parent\mvnw.cmd was found.
        exit /b 1
    )
)

if not defined REPLACE goto skipbackup
call :backup_existing_jar
if errorlevel 1 exit /b 1
:skipbackup

echo [buildUI] Building the UI webjar ^(%BUILD_PROFILE%^)...
set "LOG_FILE=%SCRIPT_DIR%buildUI.log"
echo [buildUI] Maven output is saved to: %LOG_FILE% ^(it is shown after the build finishes^)
pushd "%PARENT_DIR%"
call "%MVN_CMD%" "%REPO_ARG%" "%BUILD_PROFILE%" "-Dfrontend.skipInstall=%SKIP_INSTALL%" -DskipTests -pl quartz-manager-starter-ui -am install > "%LOG_FILE%" 2>&1
set "MVN_EXIT=%ERRORLEVEL%"
popd
if not "%MVN_EXIT%"=="0" goto mvnfailed
echo [buildUI] Maven build OK. Full log: %LOG_FILE%

echo.
echo [buildUI] Verifying the built jar...
if not exist "%JAR_PATH%" (
    echo [buildUI][ERROR] Jar not found: %JAR_PATH%
    exit /b 1
)

set "JAR_BYTES=0"
for %%F in ("%JAR_PATH%") do set "JAR_BYTES=%%~zF"
echo [buildUI] Jar size: %JAR_BYTES% bytes
if %JAR_BYTES% LSS %MIN_JAR_BYTES% (
    echo [buildUI][ERROR] Jar is smaller than 1MB. The webjar is probably empty ^(the npm build step failed^).
    exit /b 1
)

where jar >nul 2>&1
if errorlevel 1 (
    echo [buildUI][WARN] JDK jar tool not found on PATH. Skipping the bundle content check.
    goto done
)

if exist "%CHECK_DIR%" rmdir /s /q "%CHECK_DIR%"
mkdir "%CHECK_DIR%"
pushd "%CHECK_DIR%"
jar xf "%JAR_PATH%"
findstr /s /m /c:"Last fired:" *.js >nul 2>&1
if errorlevel 1 (
    echo [buildUI][WARN] The marker text "Last fired:" was not found in the bundle. The latest frontend changes may not be included.
) else (
    echo [buildUI] Bundle check OK: the latest frontend changes are included.
)
for /r "META-INF\resources\quartz-manager-ui" %%F in (main.*.js) do echo [buildUI] Bundle file: %%~nxF
popd
rmdir /s /q "%CHECK_DIR%"

:done
echo.
echo [buildUI] Done.
echo   Jar: %JAR_PATH%
echo Next: upload this jar to the server and replace BOOT-INF\lib\quartz-manager-starter-ui-5.0.1.jar
echo       ^(see section 5 of specs\002-websocket-ui-refresh\buildAndPatch.md^).
goto end

:usage
echo Usage: buildUI.bat [LOCAL_REPO_PATH] [--replace] [--maven-node]
echo   LOCAL_REPO_PATH  Optional Maven local repository ^(-Dmaven.repo.local^). Default: Maven's default repository.
echo   --replace, -r    Back up the existing jar in the local repository as ^<jar^>.bak.^<timestamp^>, then replace it.
echo   --maven-node, -m Use the Maven-managed Node/npm ^(-Pbuild-webjar, needs internet^) instead of the local Node.js.
echo   Example: buildUI.bat D:\workspace\localrepo --replace
goto end

:mvnfailed
echo.
echo [buildUI][ERROR] Maven build failed ^(exit code %MVN_EXIT%^). Full log: %LOG_FILE%
echo.
echo ---- Lines containing errors ----
findstr /i /c:"[ERROR]" /c:"npm ERR" /c:"Could not" /c:"Failed to execute" /c:"BUILD FAILURE" /c:"Cannot run program" "%LOG_FILE%"
echo.
echo ---- Last 40 lines of the log ----
powershell -NoProfile -Command "Get-Content -LiteralPath '%LOG_FILE%' -Tail 40"
echo.
echo Hints: exec-maven-plugin could not be resolved = needs internet/proxy once.
echo        npm ERR network/ENOTFOUND = quartz-manager-frontend\node_modules is missing and the npm registry is unreachable.
exit /b 1

:nonode
echo [buildUI][ERROR] node or npm not found on PATH. Install Node.js ^(^20.19 / ^22.12 / ^>=24^), or use --maven-node.
exit /b 1

:badnode
echo [buildUI][ERROR] Unsupported Node.js version v%NODE_MAJOR%.%NODE_MINOR%. Use ^20.19, ^22.12 or ^>=24, or use --maven-node.
exit /b 1

:backup_existing_jar
if not exist "%JAR_PATH%" goto nobackup
set "BACKUP_STAMP=backup"
for /f %%T in ('powershell -nologo -noprofile -command "Get-Date -Format yyyyMMddHHmmss" 2^>nul') do set "BACKUP_STAMP=%%T"
copy /y "%JAR_PATH%" "%JAR_PATH%.bak.%BACKUP_STAMP%" >nul
if errorlevel 1 goto backupfail
echo [buildUI] Existing jar backed up: %JAR_PATH%.bak.%BACKUP_STAMP%
exit /b 0
:nobackup
echo [buildUI] --replace: no existing jar in the local repository, nothing to back up.
exit /b 0
:backupfail
echo [buildUI][ERROR] Could not back up the existing jar. Aborting before the build.
exit /b 1

:end
endlocal
