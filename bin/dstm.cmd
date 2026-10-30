@echo off
rem dstm — DST Moon launcher.
rem Boots dsh with the dst-moon profile; the profile carries OUR fork
rem (see VENDORED.md) aimed at a LOCAL model (llama.cpp, OpenAI-compatible).
rem Equivalent to: dsh --profile dst-moon <args>
rem   --resume: restore the session id written to %USERPROFILE%\.dst-moon\resume.txt
rem DST-Moon keeps its own state (%USERPROFILE%\.dst-moon) so it never shares
rem settings, history or session logs with a sibling fork (DST-Comet).
rem Prereq: dsh CLI on PATH (npm i -g @deepseek-ai/dsh), profile initialized
rem         with the DST-Moon fork (scripts\install-fork.bat).
setlocal
if not defined NODE_ENV set "NODE_ENV=production"
if not defined DSH_TUI_SESSION_ROOT set "DSH_TUI_SESSION_ROOT=%USERPROFILE%\.dst-moon\sessions"
set "WORKSPACE=%DSH_TUI_WORKSPACE%"
if "%WORKSPACE%"=="" set "WORKSPACE=%CD%"
cd /d "%WORKSPACE%"

where dsh >nul 2>nul
if errorlevel 1 (
  echo [dstm] dsh CLI not found. Install it first: npm install -g @deepseek-ai/dsh 1>&2
  exit /b 1
)

set "ARGS="
:parse
if "%~1"=="" goto :run
if /i "%~1"=="--resume" (
  if exist "%USERPROFILE%\.dst-moon\resume.txt" (
    set /p DSH_TUI_RESUME_SESSION=<"%USERPROFILE%\.dst-moon\resume.txt"
  )
) else (
  set "ARGS=%ARGS% "%~1""
)
shift
goto :parse

:run
@dsh --profile dst-moon %ARGS%
endlocal
