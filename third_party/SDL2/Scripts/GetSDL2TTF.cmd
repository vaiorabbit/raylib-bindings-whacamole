::
:: Usage:
:: - %1 : SDL2_ttf version string (e.g. 2.0.18)
::

@echo off
setlocal EnableDelayedExpansion

:: Build common variables
set VERSION=%1
if "%1"=="" (
    set VERSION=2.20.0
)
set BASENAME=SDL2_ttf-!VERSION!-win32-x64
set PACKAGE=!BASENAME!.zip

pushd
cd /D "%~dp0"

if not exist ..\Archives (
    mkdir ..\Archives
)

:: Get SDL2_ttf package and then extract
if not exist !PACKAGE! (
    curl -L https://github.com/libsdl-org/SDL_ttf/releases/download/release-!VERSION!/!PACKAGE! -o ../Archives/!PACKAGE!
    if !ERRORLEVEL! neq 0 goto error
)

pushd
cd ../Archives/

if not exist !BASENAME! (
    powershell Expand-Archive -Path !PACKAGE! -Force
    if !ERRORLEVEL! neq 0 goto error
)

:: Copy headers/libraries

xcopy /y !BASENAME!\*.dll ..
if !ERRORLEVEL! neq 0 goto error

popd

popd

echo setup SDL2_ttf library successfully
pause
exit /b 0

:error
echo failed to setup SDL2_ttf library
pause
exit /b 1

endlocal
