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
rem Fork-isolation pin (same convention as the comet fork's launchers): the
rem TUI also reads DSH_TUI_STATE_DIR, so even if a rebase restores the
rem upstream ~/.dsh-tui default the state dir stays Moon-owned.
if not defined DSH_TUI_STATE_DIR set "DSH_TUI_STATE_DIR=%USERPROFILE%\.dst-moon"
rem Ask the local server which aliases it is serving (node is guaranteed:
rem dsh needs it) and pass them pipe-separated; the profile materializes the
rem llama-local model list from this. Empty (server down) -> fallback alias.
set "DSH_LLAMA_MODELS="
for /f "usebackq delims=" %%i in (`node -e "const t=setTimeout(()=>process.exit(0),1500);fetch('http://127.0.0.1:8080/v1/models').then(r=>r.json()).then(j=>{clearTimeout(t);process.stdout.write((j.data||[]).map(m=>m.id).filter(Boolean).join('|'));process.exit(0)}).catch(()=>{clearTimeout(t);process.exit(0)})" 2^>nul`) do set "DSH_LLAMA_MODELS=%%i"
rem Per-alias context windows from the rig's start-*.bat launchers
rem (--alias X + -c N): alias:ctx pipe pairs -> DSH_LLAMA_CTX, so the
rem declared window follows the loaded model (bonsai 32k vs 262k others).
rem DSH_LLAMA_BATS_DIR overrides the rig default; missing dir -> empty.
set "DSH_LLAMA_CTX="
for /f "usebackq delims=" %%i in (`node -e "const fs=require('node:fs'),p=require('node:path');const d=process.env.DSH_LLAMA_BATS_DIR||'C:/Code/Ai_Model';const out=[];try{for(const f of fs.readdirSync(d)){if(!/^start-.*\.bat$/i.test(f))continue;const tk=fs.readFileSync(p.join(d,f),'latin1').replace(/\r|\n/g,' ').split(/\s+/);const ai=tk.indexOf('--alias');let ci=tk.indexOf('--ctx-size');if(ci<0)ci=tk.indexOf('-c');const a=ai>=0?tk[ai+1]:undefined;const s=ci>=0?tk[ci+1]:undefined;if(a&&s&&/^\d+$/.test(s))out.push(a+':'+s)}}catch(e){}process.stdout.write(out.join('|'))" 2^>nul`) do set "DSH_LLAMA_CTX=%%i"
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
