@echo off
REM Builds GameAnalytics_x64.dll (and GameAnalytics.dll for 32-bit) for the
REM GameMaker extension. Run from a Developer Command Prompt; requires CMake and
REM zlib (vcpkg: vcpkg install zlib:x64-windows-static zlib:x86-windows-static,
REM then pass -DCMAKE_TOOLCHAIN_FILE=<vcpkg>/scripts/buildsystems/vcpkg.cmake).
REM
REM Usage: build_windows.bat [path-to-gameanalytics-sdk-cpp] [x64^|Win32]
setlocal
set HERE=%~dp0
set SDK_DIR=%~1
if "%SDK_DIR%"=="" set SDK_DIR=%HERE%..\..\..\..\..\gameanalytics-sdk-cpp
set ARCH=%~2
if "%ARCH%"=="" set ARCH=x64

cmake -S "%HERE%" -B "%HERE%build-windows-%ARCH%" -A %ARCH% -DGA_SDK_DIR="%SDK_DIR%" %CMAKE_EXTRA_ARGS%
if errorlevel 1 exit /b 1
cmake --build "%HERE%build-windows-%ARCH%" --config Release
if errorlevel 1 exit /b 1

echo.
echo Built into %HERE%..
endlocal
