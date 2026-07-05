@echo off
REM ============================================================
REM  deploy.bat  -  one-step ship for haphazardsolutions.com
REM
REM  Stages everything, commits, pushes to the current branch,
REM  then watches the GitHub Pages build + deploy and reports
REM  pass/fail (and the live-site HTTP status on success).
REM
REM  Usage:   deploy.bat "Your commit message"
REM
REM  Needs git, gh (authenticated), and curl - all standard on
REM  this machine. Safe to run from anywhere; it cd's to its
REM  own folder (the repo root) first.
REM ============================================================

setlocal
set "REPO=smearvox/haphazardsolutions.com"
set "SITE=https://haphazardsolutions.com"

pushd "%~dp0"

REM --- commit message is required --------------------------------
if "%~1"=="" (
  echo [x] Commit message required.
  echo     Usage: %~nx0 "Your commit message"
  goto :fail
)

REM --- must be inside a git work tree ----------------------------
git rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
  echo [x] Not inside a git repository: %CD%
  goto :fail
)

REM --- which branch are we on? (Pages deploys from main) ---------
set "BRANCH="
for /f "usebackq delims=" %%b in (`git rev-parse --abbrev-ref HEAD`) do set "BRANCH=%%b"
if /i not "%BRANCH%"=="main" (
  echo [!] On branch "%BRANCH%", not "main". Pages deploys from main;
  echo     this pushes "%BRANCH%" and the deploy watch may not apply.
)

REM --- anything to ship? -----------------------------------------
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

echo [3/5] Pushing to origin/%BRANCH%...
git push origin %BRANCH% || goto :fail

REM --- watch the Pages deploy ------------------------------------
where gh >nul 2>&1
if errorlevel 1 (
  echo [i] gh CLI not found - push done, Pages will build shortly. Skipping watch.
  goto :done
)

echo [4/5] Locating the Pages run...
timeout /t 8 /nobreak >nul
call :getrun
if not defined RUNID ( timeout /t 6 /nobreak >nul & call :getrun )
if not defined RUNID (
  echo [i] Couldn't find the run yet. Check it manually:
  echo     gh run list --repo %REPO%
  goto :done
)

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
echo [*] Deployed. Checking the live site...
for /f "usebackq delims=" %%c in (`curl -s -o NUL -w "%%{http_code}" %SITE%/`) do set "CODE=%%c"
echo     %SITE%/  ->  HTTP %CODE%
goto :done

REM --- subroutine: fetch the latest run id -----------------------
:getrun
for /f "usebackq delims=" %%i in (`gh run list --repo %REPO% --limit 1 --json databaseId --jq ".[0].databaseId" 2^>NUL`) do set "RUNID=%%i"
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
