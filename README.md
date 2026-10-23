📖 Overview

A small Windows batch script that force-restarts the Logitech G HUB background services without requiring a full reboot. It automatically re-launches itself with Administrator privileges (triggering a UAC prompt), kills the stuck lghub_agent.exe process, stops the LGHUBUpdaterService, and then relaunches lghub_updater.exe in service mode so G HUB can reconnect.

Typical use case: G HUB is stuck on "Loading", devices aren't detected, or the updater service is hung and a reboot is overkill.
🔍 Detailed Breakdown
Part 1 — Self-elevation to Administrator
bat

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

    @echo off — suppresses command echoing so the console stays clean.

    Architecture check — the script probes config\system (a file only Administrators can read) using cacls. On 64-bit Windows it deliberately uses the SysWOW64 copy of cacls.exe to dodge the 32-bit file-system redirection that would otherwise map system32 to SysWOW64 and produce a false result.

    >nul 2>&1 — hides both stdout and stderr from the probe.

    IF %errorlevel% NEQ 0 — a non-zero exit code means the probe was denied, i.e. the script is not running elevated.

bat

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params= %*
    echo UAC.ShellExecute "cmd.exe", "/c ""%~s0"" %params:"=""%", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

    Writes a tiny VBScript to %temp%\getadmin.vbs that calls Shell.Application.ShellExecute with the verb runas — this is the canonical way to trigger a UAC prompt from batch, because runas is a shell verb, not a cmd builtin.

    %~s0 — the current script's path in 8.3 short-name form, which avoids quoting problems if the path contains spaces.

    %params:"=""% — forwards any command-line arguments the user passed, escaping embedded quotes.

    1 — the final argument tells ShellExecute to show the elevated window.

    The VBS is executed, deleted, and the original (non-elevated) process exits with exit /B so only one instance keeps running.

bat

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"

    pushd "%CD%" — saves the current working directory onto the directory stack.

    CD /D "%~dp0" — switches into the folder containing the .bat file, so relative paths (logs, configs, etc.) resolve correctly even when launched from C:\Windows\System32 via the elevation trick.

Part 2 — Logitech G HUB Service Reset
bat

echo Killing Logitech G HUB Agent...
taskkill /f /im lghub_agent.exe 2>nul

    taskkill /f /im lghub_agent.exe — forcibly terminates every process whose image name is lghub_agent.exe (/f = force, /im = match by image name). This is the G HUB tray/background agent that frequently holds device handles open.

    2>nul — silences the "process not found" error if G HUB wasn't running.

bat

echo Stopping LGHUBUpdaterService...
net stop LGHUBUpdaterService /y 2>nul

    Stops the Logitech G HUB Updater Windows service. /y suppresses the prompt that appears when other services depend on it.

    Again, errors are suppressed in case the service is already stopped.

bat

echo Waiting 2 seconds for processes to clear...
timeout /t 2 /nobreak >nul

    Gives Windows time to release the file handles and sockets held by the killed processes before the updater is relaunched. /nobreak ignores key presses so the delay can't be skipped accidentally.

bat

echo Launching G HUB Updater as a service...
start "" /b "C:\Program Files\LGHUB\lghub_updater.exe" --run-as-service

    start "" — the empty title prevents start from interpreting the quoted exe path as the window title.

    /b — launches the process without spawning a new console window, so the batch continues and the user sees no extra black window.

    --run-as-service — the flag G HUB's own launcher uses to run the updater in the background service role; it lets the GUI re-attach to it.

bat

echo Logitech G HUB services successfully reset!
timeout /t 3 >nul
exit

    Prints a success line, waits 3 s so the user can read it, then closes the console.

⚙️ Requirements
Requirement	Detail
OS	Windows 10 / 11 (x86 or x64)
Privileges	Administrator (script auto-requests via UAC)
Install path	C:\Program Files\LGHUB\ — default G HUB location
Dependencies	None beyond stock Windows binaries (cacls, taskkill, net, timeout, wscript)
🚀 Usage

    Save the script as reset-ghub.bat (or any name ending in .bat).

    Right-click → Run as administrator, or double-click and accept the UAC prompt.

    Wait ~5 seconds. You should see:
    text

    Requesting administrative privileges...
    Killing Logitech G HUB Agent...
    Stopping LGHUBUpdaterService...
    Waiting 2 seconds for processes to clear...
    Launching G HUB Updater as a service...
    Logitech G HUB services successfully reset!

    Launch Logitech G HUB from the Start menu.
