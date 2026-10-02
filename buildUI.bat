@echo off
setlocal
cd /d "%~dp0"

rem buildUI.bat -- Builds the quartz-manager UI webjar (quartz-manager-starter-ui)
rem from THIS working tree (including uncommitted frontend changes) and installs
rem it into the local Maven repository (%USERPROFILE%\.m2). See section 4 of
rem specs\002-websocket-ui-refresh\buildAndPatch.md.
rem
rem Unlike qssb's buildQuartzManager.bat, this script does NOT clone the GitHub
rem fork, so local (not yet pushed) changes are included.
rem
rem Requirements: JDK 21+ (25 recommended) on PATH or JAVA_HOME. Maven is optional
rem (falls back to quartz-manager-parent\mvnw.cmd). Internet access is needed:
rem the frontend-maven-plugin downloads Node v22.13.0 and runs npm install.
rem
rem Run this script from the quartz-manager repository root (where it lives).

set "PARENT_DIR=%~dp0quartz-manager-parent"
set "JAR_PATH=%USERPROFILE%\.m2\repository\it\fabioformosa\quartz-manager\quartz-manager-starter-ui\5.0.1\quartz-manager-starter-ui-5.0.1.jar"
set "CHECK_DIR=%TEMP%\quartz-manager-ui-check"
set "MIN_JAR_BYTES=4000000"

if not exist "%PARENT_DIR%\pom.xml" (
    echo [buildUI][ERROR] quartz-manager-parent\pom.xml not found. Run this script from the quartz-manager repository root.
    exit /b 1
)
if not exist "%~dp0quartz-manager-frontend\package.json" (
    echo [buildUI][ERROR] quartz-manager-frontend\package.json not found.
    exit /b 1
)

echo [buildUI] Checking required tools...
where java >nul 2>&1 || (echo [buildUI][ERROR] java not found on PATH. Install JDK 25 ^(minimum 21^) and set JAVA_HOME. & exit /b 1)

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

echo [buildUI] Building the UI webjar with -Pbuild-webjar ^(npm install + npm run build, about 1-2 minutes^)...
pushd "%PARENT_DIR%"
call "%MVN_CMD%" -DskipTests -Pbuild-webjar -pl quartz-manager-starter-ui -am install
if errorlevel 1 (
    echo [buildUI][ERROR] Maven build failed. Check the log above ^(node download / npm install / npm run build steps^).
    popd
    exit /b 1
)
popd

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
    echo [buildUI][ERROR] Jar is smaller than 4MB. The webjar is probably empty ^(node/npm step failed^).
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

endlocal
