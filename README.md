# Reset Logitech G HUB

A small Windows batch script that force-restarts the Logitech G HUB background
services without a full reboot. It re-launches itself with Administrator
privileges, kills the stuck `lghub_agent.exe` process, stops the
`LGHUBUpdaterService`, and relaunches `lghub_updater.exe` in service mode so
G HUB can reconnect.

Use it when G HUB is stuck on "Loading", devices are not detected, or the
updater service is hung and a reboot is overkill.

## How it works

The script has two parts:

1. Self-elevation to Administrator (UAC prompt).
2. Killing and restarting the Logitech G HUB services.

## Part 1 - Self-elevation to Administrator

```bat
@echo off
IF "%PROCESSOR_ARCHITECTURE%" EQU "amd64" (
    >nul 2>&1 "%SYSTEMROOT%\SysWOW64\cacls.exe" "%SYSTEMROOT%\SysWOW64\config\system"
) ELSE (
    >nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
)
IF %errorlevel% NEQ 0 (
    echo Requesting administrative privileges...
    goto UACPrompt
) ELSE ( goto gotAdmin )
