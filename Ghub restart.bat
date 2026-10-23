@echo off
:: Automatically elevate the script to run as Administrator
IF "%PROCESSOR_ARCHITECTURE%" EQU "amd64" (
>nul 2>&1 "%SYSTEMROOT%\SysWOW64\cacls.exe" "%SYSTEMROOT%\SysWOW64\config\system"
) ELSE (
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
)
IF %errorlevel% NEQ 0 (
    echo Requesting administrative privileges...
    goto UACPrompt
) ELSE ( goto gotAdmin )
:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params= %*
    echo UAC.ShellExecute "cmd.exe", "/c ""%~s0"" %params:"=""%", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B
:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"

:: -----------------------------------------
:: Main Logitech G HUB Logic Starts Here
:: -----------------------------------------

echo Killing Logitech G HUB Agent...
taskkill /f /im lghub_agent.exe 2>nul

echo Stopping LGHUBUpdaterService...
net stop LGHUBUpdaterService /y 2>nul

echo Waiting 2 seconds for processes to clear...
timeout /t 2 /nobreak >nul

echo Launching G HUB Updater as a service...
start "" /b "C:\Program Files\LGHUB\lghub_updater.exe" --run-as-service

echo Logitech G HUB services successfully reset!
timeout /t 3 >nul
exit
