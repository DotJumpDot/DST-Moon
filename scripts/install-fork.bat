@echo off
rem DST-Moon installer: builds the fork (if needed), packs it to
rem dist\dst-moon.tgz, builds+packs the engine fork packages to
rem engine\dist\, installs everything into the dst-moon dsh profile
rem (created if missing), and finally copies profile\cordis.patch.yml
rem over the profile's patch layer. The profile keeps file:/link:
rem dependencies on those tarballs, so they must STAY on disk — future
rem dsh plugin / pnpm operations in the profile resolve them.
rem
rem pnpm 11 + nodeLinker=hoisted is required for pack: pnpm 12 refuses
rem bundledDependencies under the default isolated linker.
setlocal enabledelayedexpansion
set "ROOT=%~dp0.."
set "FORK=%ROOT%\vendor\dsh-tui"
set "DIST=%ROOT%\dist"
set "ENGINE=%ROOT%\engine"
set "EDIST=%ENGINE%\dist"
set "PROFILE=dst-moon"
set "PROFILEDIR=%USERPROFILE%\.dsh\profiles\dst-moon"
set "PLUG=!ROOT:\=/!/plugins/dst-moon-agent-tools"

where dsh >nul 2>nul || (echo [dstm-install] dsh CLI not on PATH & exit /b 1)

rem lib\ holds settings.json + types\ after a compile — the real "is it
rem built" marker (there is no lib\index.js). The fork is a pnpm workspace,
rem so the build goes through pnpm, never npm (npm chokes on workspace:*).
if not exist "%FORK%\lib\settings.json" (
  echo [dstm-install] lib/ missing - building fork with pnpm...
  pushd "%FORK%"
  call npx -y pnpm@11.21.0 install --config.nodeLinker=hoisted
  if errorlevel 1 (popd & echo [dstm-install] fork install failed & exit /b 1)
  call npx -y pnpm@11.21.0 run compile
  if errorlevel 1 (popd & echo [dstm-install] fork compile failed & exit /b 1)
  popd
)

rem Upstream rc.6 plugins ride in the dsh-tui bundle against the rc.2 host;
rem the running host pairs them byte-for-byte (same exemptions as Comet's
rem profile). Grant before adding so a fresh run is unattended.
call dsh plugin --profile %PROFILE% allow-version @deepseek-ai/dsh-code-runtime-worker-thread@0.1.0-rc.6 --dsh-version 0.2.1-rc.2 --accept-risk >nul 2>nul
call dsh plugin --profile %PROFILE% allow-version @deepseek-ai/dsh-agent-presets@0.1.0-rc.6 --dsh-version 0.2.1-rc.2 --accept-risk >nul 2>nul
call dsh plugin --profile %PROFILE% allow-version @deepseek-ai/dsh-experimental-tool-agent-team@0.2.1-rc.2-moon.1 --dsh-version 0.2.1-rc.2 --accept-risk >nul 2>nul

if not exist "%DIST%" mkdir "%DIST%"

echo [dstm-install] packing fork -^> dist\dst-moon.tgz ...
pushd "%FORK%"
if exist "%DIST%\dst-moon.tgz" del "%DIST%\dst-moon.tgz"
call npx -y pnpm@11.21.0 pack --config.nodeLinker=hoisted
if errorlevel 1 (popd & echo [dstm-install] pack failed & exit /b 1)
set "TGZ="
for /f "delims=" %%f in ('dir /b *.tgz 2^>nul') do set "TGZ=%%f"
if "!TGZ!"=="" (popd & echo [dstm-install] no tarball produced & exit /b 1)
move /y "!TGZ!" "%DIST%\dst-moon.tgz" >nul
popd

echo [dstm-install] building + packing engine fork ...
if not exist "%EDIST%" mkdir "%EDIST%"
pushd "%ENGINE%"
call npx -y pnpm@11.21.0 install --config.nodeLinker=hoisted
if errorlevel 1 (popd & echo [dstm-install] engine install failed & exit /b 1)
call npx -y pnpm@11.21.0 run build
if errorlevel 1 (popd & echo [dstm-install] engine build failed & exit /b 1)
call npx -y pnpm@11.21.0 -r pack --config.nodeLinker=hoisted
if errorlevel 1 (popd & echo [dstm-install] engine pack failed & exit /b 1)
popd
rem pnpm -r pack drops every workspace tarball in the workspace ROOT,
rem not in the package dirs — move them from there.
for /f "delims=" %%f in ('dir /b "%ENGINE%\*.tgz" 2^>nul') do move /y "%ENGINE%\%%f" "%EDIST%\%%f" >nul

echo [dstm-install] installing into profile %PROFILE% ...
call dsh plugin --profile %PROFILE% add "%DIST%\dst-moon.tgz"
if errorlevel 1 (echo [dstm-install] fork install failed & exit /b 1)
for /f "delims=" %%f in ('dir /b "%EDIST%\*.tgz" 2^>nul') do (
  call dsh plugin --profile %PROFILE% add "%EDIST%\%%f"
  if errorlevel 1 (echo [dstm-install] engine install failed: %%f & exit /b 1)
)
call dsh plugin --profile %PROFILE% add "link:%PLUG%"
if errorlevel 1 (echo [dstm-install] plugin link failed & exit /b 1)

echo [dstm-install] copying profile patch layer ...
if not exist "%PROFILEDIR%" mkdir "%PROFILEDIR%"
copy /y "%ROOT%\profile\cordis.patch.yml" "%PROFILEDIR%\cordis.patch.yml" >nul

echo [dstm-install] done. Launch with: dstm
