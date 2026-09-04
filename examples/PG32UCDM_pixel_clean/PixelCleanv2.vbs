Dim WSHShell, objExec, activePlanGUID, originalMonitorTimeoutSec
Dim monindex, currentValue, proposedValue, output, errOutput, userResponse, rc
Dim originalTimeoutDetermined

Const VIDEOIDLE_GUID = "3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e"
Const TEMP_TIMEOUT_SEC = 600

On Error Resume Next ' Enable error handling

Set WSHShell = CreateObject("WScript.Shell")

' Initialize flag
originalTimeoutDetermined = False

' Single routine that puts the display timeout back to the exact value read at
' startup. Called from step 6 (the change may have half-applied), from step 7
' (pixel cleaning did not start) and from step 9 (normal completion). The
' WScript.Quit paths in steps 1, 2 and 3, and the confirmation prompt, do not
' call it, because no powercfg command has run by that point.
Sub RestoreOriginalMonitorTimeout()
    If Not originalTimeoutDetermined Then
        WScript.Echo "Original display timeout could not be determined. Please restore it manually."
        Exit Sub
    End If

    If SetVideoIdleAC(originalMonitorTimeoutSec) Then
        WScript.Echo "Original Windows display timeout restored to " & originalMonitorTimeoutSec & " seconds."
    Else
        WScript.Echo "Error: could not restore the original Windows display timeout." & vbCrLf & _
                     "Please set it back to " & originalMonitorTimeoutSec & " seconds manually."
    End If
End Sub

' Step 1: Get the GUID of the currently active power plan
Set objExec = WSHShell.Exec("reg query ""HKLM\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes"" /v ActivePowerScheme")
Do While objExec.Status = 0
    WScript.Sleep 100
Loop
output = objExec.StdOut.ReadAll()
errOutput = objExec.StdErr.ReadAll()

' reg.exe reports failures on stderr, so stdout alone cannot tell a failed query
' apart from a missing value.
If objExec.ExitCode <> 0 Or InStr(output, "ActivePowerScheme") = 0 Then
    WScript.Echo "Error: could not read the active power scheme." & vbCrLf & Trim(errOutput)
    WScript.Quit
End If

' Trim() only strips spaces in VBScript, so drop the trailing newline explicitly.
activePlanGUID = Trim(Split(output, " ")(UBound(Split(output, " "))))
activePlanGUID = Replace(Replace(activePlanGUID, vbCr, ""), vbLf, "")

' Step 2: Read the effective "turn off display after" value for AC power, in
' seconds. The per-scheme registry value only exists once the setting has been
' explicitly overridden; otherwise Windows falls back to a default stored
' elsewhere, so reading that key directly fails on many machines. WMI reports the
' effective value either way and does not depend on the display language.
originalMonitorTimeoutSec = GetVideoIdleAC(activePlanGUID)

If originalMonitorTimeoutSec < 0 Then
    WScript.Echo "Error: could not read the current Windows display timeout" & vbCrLf & _
                 "for power scheme " & activePlanGUID & "."
    WScript.Quit
End If

originalTimeoutDetermined = True

' Returns the effective AC value of the VIDEOIDLE power setting in seconds
' (0 means "never"), or -1 if it cannot be determined.
Function GetVideoIdleAC(planGUID)
    Dim bs, wmi, items, item, instanceID
    bs = Chr(92)
    GetVideoIdleAC = -1
    On Error Resume Next

    Err.Clear
    Set wmi = GetObject("winmgmts:" & bs & bs & "." & bs & "root" & bs & "cimv2" & bs & "power")
    If Err.Number <> 0 Then Exit Function

    ' Backslashes are doubled because WQL string literals escape them.
    instanceID = "Microsoft:PowerSettingDataIndex" & bs & bs & "{" & planGUID & "}" & _
                 bs & bs & "AC" & bs & bs & "{" & VIDEOIDLE_GUID & "}"

    Err.Clear
    Set items = wmi.ExecQuery("SELECT * FROM Win32_PowerSettingDataIndex " & _
                              "WHERE InstanceID='" & instanceID & "'")
    If Err.Number <> 0 Then Exit Function

    For Each item In items
        Err.Clear
        GetVideoIdleAC = CLng(item.SettingIndexValue)
        If Err.Number <> 0 Then GetVideoIdleAC = -1
        Exit For
    Next
End Function

' Applies an AC display timeout, in seconds, to the active power scheme.
' Returns True only if both powercfg invocations succeed. A False return does
' not mean nothing changed: the first call may have written the value before the
' second one failed, so callers must restore rather than assume.
Function SetVideoIdleAC(seconds)
    Dim exitCode
    SetVideoIdleAC = False

    exitCode = WSHShell.Run("powercfg /setacvalueindex SCHEME_CURRENT SUB_VIDEO VIDEOIDLE " & seconds, 0, True)
    If exitCode <> 0 Then Exit Function

    exitCode = WSHShell.Run("powercfg /setactive SCHEME_CURRENT", 0, True)
    If exitCode <> 0 Then Exit Function

    SetVideoIdleAC = True
End Function

' Step 3: Run winddcutil to detect monitors and find the display index
Set objExec = WSHShell.Exec("powershell -Command ""(Invoke-Expression '.\winddcutil.exe detect') | Where-Object {$_ -like '1 ASUS PG32UCDM*'} | ForEach-Object {($_ -split ' ')[0]}""")
Do While objExec.Status = 0
    WScript.Sleep 100
Loop
monindex = Trim(objExec.StdOut.ReadLine)

If monindex = "" Then
    WScript.Echo "Monitor not found."
    WScript.Quit
End If

' Step 4: Run winddcutil to get the current value of register 0xFD
Set objExec = WSHShell.Exec("winddcutil.exe getvcp " & monindex & " 0xfd")
Do While objExec.Status = 0
    WScript.Sleep 100
Loop
output = objExec.StdOut.ReadAll()
currentValue = Trim(Split(output, " ")(2))

' Step 5: Calculate proposed values
proposedValue = CInt(currentValue) + 16

' Display all values for user confirmation
' WScript.Echo "Current Values:" & vbCrLf & _
'            "Original Monitor Timeout (Seconds): " & originalMonitorTimeoutSec & vbCrLf & _
'            "Current Value of Register 0xFD: " & currentValue & vbCrLf & _
'            "Proposed Value for Register 0xFD: " & proposedValue & vbCrLf & _
'            "Monitor Timeout will be changed to 10 minutes temporarily for the operation."

' Ask user for confirmation
userResponse = MsgBox("Do you want to proceed with the following changes?" & vbCrLf & _
    "1. Change Windows display timeout to 10 minutes." & vbCrLf & _
    "2. Start Pixel Cleaning that will take around six minutes" & vbCrLf & _
    "Click Yes to proceed or No to cancel.", vbYesNo + vbQuestion, "Confirm Changes")

If userResponse = vbNo Then
    WScript.Echo "Operation canceled by the user."
    WScript.Quit
End If

' Step 6: Raise the display timeout so pixel cleaning can run uninterrupted
If Not SetVideoIdleAC(TEMP_TIMEOUT_SEC) Then
    WScript.Echo "Error: could not change the Windows display timeout." & vbCrLf & _
                 "The setting may have been partially applied; restoring it now."
    RestoreOriginalMonitorTimeout()
    WScript.Quit
End If

' Step 7: Run winddcutil to set the pixel cleaning value to the calculated new value
rc = WSHShell.Run("winddcutil.exe setvcp " & monindex & " 0xfd " & proposedValue, 0, True)

If rc <> 0 Then
    WScript.Echo "Error: pixel cleaning could not be started (winddcutil exited with " & rc & ")."
    RestoreOriginalMonitorTimeout()
    WScript.Quit
End If

WScript.Sleep 1000
WScript.Echo "Done cleaning!." & vbCrLf & _
             "If " & originalMonitorTimeoutSec & " or more seconds have elapsed without user input, your display will likely enter standby" & vbCrLf & _
             "Original Windows display timeout will be restored to " & originalMonitorTimeoutSec & " seconds."

' Step 8: Wait for 6 minutes
WScript.Sleep 360000

' Step 9: Restore original monitor timeout value and exit
RestoreOriginalMonitorTimeout()
WScript.Quit
