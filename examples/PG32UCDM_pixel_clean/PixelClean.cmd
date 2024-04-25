@echo off

:: Get the GUID of the currently active power plan
for /f "tokens=3" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes" /v ActivePowerScheme ^| find "ActivePowerScheme"') do (
    set "active_plan_guid=%%a"
)

:: Use the active power plan GUID to construct the registry key for the monitor's timeout value
set "reg_key=HKLM\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\%active_plan_guid%\7516b95f-f776-4464-8c53-06167f40cc99\3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e"

:: Query the registry to retrieve the monitor's timeout value for AC power
for /f "tokens=3" %%a in ('reg query "%reg_key%" /v ACSettingIndex ^| find "ACSettingIndex"') do (
    set "original_monitor_timeout_hex=%%a"
)

:: Convert monitor timeout value from hexadecimal seconds to decimal minutes
set /a "original_monitor_timeout_dec=original_monitor_timeout_hex / 60"

:: Run winddcutil to detect monitors and find the display index
for /f "tokens=1" %%a in ('powershell -Command "(Invoke-Expression '.\winddcutil.exe detect') | Where-Object {$_ -like '1 ASUS PG32UCDM*'} | ForEach-Object {($_ -split ' ')[0]}"') do (
    set "monindex=%%a"
)

:: Verify if monitor index is found
if not defined monindex (
    echo Monitor not found.
    exit /b
)

echo Monitor found: ASUS PG32UCDM (Index: %monindex%)

:: Run winddcutil to get the current value of register 0xFD
for /f "tokens=3" %%a in ('"winddcutil.exe" getvcp %monindex% 0xfd') do (
    set "current_value=%%a"
)

:: Extract numeric part from the response
set "current_value=%current_value:* =%"

:: Calc proposed values
set /a proposed_value=current_value + 16

:: Display the values of important variables and ask for confirmation
:: echo Current monitor timeout (AC): %original_monitor_timeout_dec% minutes
:: echo Current monitor index: %monindex%
:: echo Current value of register 0xFD: %current_value%
:: echo Proposed value of register 0xFD: %proposed_value%
:: echo.
:: set /p "confirmation=Do you want to proceed (Y/N)? "
:: if /i "%confirmation%" neq "Y" (
::    echo Operation cancelled by user.
::    exit /b
::)


:: Change monitor's timeout to 10 minutes to ensure pixel cleaning can complete
powercfg -change -monitor-timeout-ac 10
:: Run winddcutil to set the pixel cleaning value to the calculated new value
echo PLEASE WAIT, FINISHING UP.
echo IF %original_monitor_timeout_dec% OR MORE MINUTES HAVE ELAPSED WITHOUT USER INPUT YOUR DISPLAY WILL ENTER STANDBY.
start "" "winddcutil.exe" setvcp %monindex% 0xfd %proposed_value%
:: Wait for 6 minutes
timeout /t 360 /nobreak >nul
:: Restore original monitor timeout value and exit
powercfg -change -monitor-timeout-ac %original_monitor_timeout_dec%
exit /b
