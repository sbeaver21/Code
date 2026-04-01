@echo off

:: ====================================================================================================================
:: Batch file to detect whether a Microsoft Visual C++ Redistributable (VC Redist) package has been installed on the
:: current machine.
:: Start with the parent key, e.g. "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\", look for numeric
:: child keys. Then, compare each child key's major version with the minimum required version. For each match, find out
:: if the child key's version is installed.
:: Return 0 if the an installed VC Redist version is detected.
:: Return 1 if none of the child keys have a VC Redist version installed that meets or exceeds the minimum required
:: version.
:: ====================================================================================================================

setlocal ENABLEDELAYEDEXPANSION

:: Detect whether the Windows OS is 32-bit or 64-bit
reg query "HKLM\Hardware\Description\System\CentralProcessor\0" | find /i "x86" > NUL && set OSTYPE=32BIT || set OSTYPE=64BIT
if %OSTYPE%==32BIT (
    set "REG_KEY_BEGIN=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\VisualStudio\"
)
if %OSTYPE%==64BIT (
    rem CLI and UI installers still support 32-bit Windows, so Windows CLI and
    rem ovftool.exe are still 32-bit, thus requiring 32-bit VC Redist
    set "REG_KEY_BEGIN=HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\"
)
set "REG_KEY_END=\VC\Runtimes\x86"
set "VALUE_NAME=Installed"

:: Accept the minimum required VC Redist version via the first parameter
set MINIMUM_REDIST_VER=%1
if [%MINIMUM_REDIST_VER%] == [] (
    :: If no parameters are provided, use 14.0 as the default minimum required VC Redist version
    set "MINIMUM_REDIST_VER=14.0"
)

for /F "usebackq" %%A IN (`reg query %REG_KEY_BEGIN% 2^>nul`) do (
    set VsMajorVersion=%%~nA
    set VsFullVersion=%%~nxA

    set "NotNumeric="&for /f "delims=0123456789" %%i in ("!VsMajorVersion!") do set "NotNumeric=%%i"
    if not defined NotNumeric (
        set /a COMPARE_STATUS=0
        call :compare !VsMajorVersion! COMPARE_STATUS

        if !COMPARE_STATUS! geq 0 (
            :: Look whether a VS Redist package is installed
            set "KEY_NAME=%REG_KEY_BEGIN%!VsFullVersion!%REG_KEY_END%"
            set /a INSTALL_STATUS=0

            call :checkInstallStatus !KEY_NAME! INSTALL_STATUS
            if !INSTALL_STATUS!==0x1 (
                @echo Microsoft Visual C++ Redistributable version !VsFullVersion! is detected. This meets the minimum required version %MINIMUM_REDIST_VER%.
                exit /b 0
            )
        )
    )
)
:: For 64-bit support, replace the following text
:: @echo Microsoft Visual 64-bit (x64) C++ Redistributable package is required. Download the latest 64-bit (x64) VC Redistributable package from Microsoft (https://www.visualstudio.com/downloads/), or, if Internet access is not available, install the package by running vc_redist.x64.exe, located in the vcsa\ovftool\win32\vcredist\ directory.
:: Message to the user to install the 32-bit VC Redist
@echo Microsoft Visual C++ 32-bit (x86) Redistributable is required. Download the latest 32-bit (x86) VC Redistributable package from Microsoft (https://www.visualstudio.com/downloads/), or, if Internet access is not available, install the package by running vc_redist.x86.exe, located in the vcsa\ovftool\win32\vcredist\ directory.
exit /b 1

:compare
set /a v1=%1
set /a v2=%MINIMUM_REDIST_VER

if %v1% gtr %v2% (
    set /a %2=1
)
if %v1% lss %v2% (
    set /a %2=-1
)
if %v1% equ %v2% (
    set /a %2=0
)
exit /b %errorlevel%


:checkInstallStatus
set "KeyName=%1"
for /F "usebackq skip=2 tokens=1-2*" %%A IN (`reg query %KeyName% /v %VALUE_NAME% 2^>nul`) do (
        set Name=%%A
        set Type=%%B
        set Value=%%C
)
set %2=%Value%
exit /b %errorlevel%
