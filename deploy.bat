@echo off
REM ============================================================
REM  deploy.bat  -  one-step ship for haphazardsolutions.com
REM
REM  Stages everything, commits, pushes to the current branch,
REM  then watches the GitHub Pages build + deploy for THIS commit
REM  and reports pass/fail (plus the live-site HTTP status).
REM
REM  Usage:   deploy.bat "Your commit message"
REM
REM  Needs git, gh (authenticated), and curl - standard on this
REM  machine. Safe to run from anywhere; cd's to its own folder.
REM ============================================================

setlocal
set "REPO=smearvox/haphazardsolutions.com"
set "SITE=https://haphazardsolutions.com"

pushd "%~dp0"

if "%~1"=="" (
  echo [x] Commit message required.
  echo     Usage: %~nx0 "Your commit message"
  goto :fail
)

git rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
  echo [x] Not inside a git repository: %CD%
  goto :fail
)

set "BRANCH="
for /f "usebackq delims=" %%b in (`git rev-parse --abbrev-ref HEAD`) do set "BRANCH=%%b"
if /i not "%BRANCH%"=="main" (
  echo [!] On branch "%BRANCH%", not "main". Pages deploys from main;
  echo     this pushes "%BRANCH%" and the deploy watch may not apply.
)

set "DIRTY="
for /f "delims=" %%s in ('git status --porcelain') do set "DIRTY=1"
if not defined DIRTY (
  echo [i] Nothing to commit - working tree is clean.
  goto :done
)

echo [1/5] Staging all changes...
git add -A || goto :fail

echo [2/5] Committing...
git commit -m "%~1" || goto :fail

set "SHA="
for /f "usebackq delims=" %%s in (`git rev-parse HEAD`) do set "SHA=%%s"

echo [3/5] Pushing to origin/%BRANCH%...
git push origin %BRANCH% || goto :fail

where gh >nul 2>&1
if errorlevel 1 (
  echo [i] gh CLI not found - push done, Pages will build shortly. Skipping watch.
  goto :done
)

echo [4/5] Waiting for the Pages run for %SHA:~0,7%...
set "TRIES=0"
:waitrun
call :getrun
if /i "%RUNSHA%"=="%SHA%" goto :haverun
set /a TRIES+=1
if %TRIES% geq 20 (
  echo [i] New run not detected in time. Latest seen: %RUNID% ^(%RUNSHA:~0,7%^)
  echo     Check manually: gh run list --repo %REPO%
  goto :done
)
ping -n 6 127.0.0.1 >nul
goto :waitrun
:haverun

echo [5/5] Watching build ^& deploy ^(run %RUNID%^)...
gh run watch %RUNID% --repo %REPO% --exit-status
if errorlevel 1 (
  echo.
  echo [x] Deploy did NOT succeed.
  echo     Logs:   gh run view %RUNID% --repo %REPO% --log-failed
  echo     Re-run: gh run rerun %RUNID% --repo %REPO% --failed
  goto :fail
)

echo.
echo [*] Deployed. Live-site check:
curl -s -o NUL -w "    %SITE%/ -> HTTP %%{http_code}\n" %SITE%/
goto :done

REM --- subroutine: latest run's id + head SHA -------------------
:getrun
set "RUNID="
set "RUNSHA="
for /f "usebackq delims=" %%i in (`gh run list --repo %REPO% --limit 1 --json databaseId --jq ".[0].databaseId" 2^>NUL`) do set "RUNID=%%i"
for /f "usebackq delims=" %%h in (`gh run list --repo %REPO% --limit 1 --json headSha --jq ".[0].headSha" 2^>NUL`) do set "RUNSHA=%%h"
goto :eof

:done
echo.
echo Done.
popd
endlocal
exit /b 0

:fail
echo.
echo Aborted.
popd
endlocal
exit /b 1
