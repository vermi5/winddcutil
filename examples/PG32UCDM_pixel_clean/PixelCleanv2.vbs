Dim WSHShell, objExec, activePlanGUID, regKey, originalMonitorTimeoutHex, originalMonitorTimeoutDec
Dim monindex, currentValue, proposedValue, output, lines, line, i, userResponse
Dim originalTimeoutDetermined

On Error Resume Next ' Enable error handling

Set WSHShell = CreateObject("WScript.Shell")

' Initialize flag
originalTimeoutDetermined = False

' Define a cleanup function to restore the original monitor timeout
Sub RestoreOriginalMonitorTimeout()
    On Error Resume Next ' Continue if an error occurs during cleanup
    If originalTimeoutDetermined Then
        WSHShell.Run "powercfg -change -monitor-timeout-ac " & originalMonitorTimeoutDec, 0, True
        If Err.Number <> 0 Then
            WScript.Echo "Error restoring original Windows display timeout: " & Err.Description
        Else
            WScript.Echo "Original Windows display timeout restored to " & originalMonitorTimeoutDec & " minutes."
        End If
    Else
        WScript.Echo "Original monitor timeout could not be determined. Please restore it manually."
    End If
End Sub

' Step 1: Get the GUID of the currently active power plan
Set objExec = WSHShell.Exec("reg query ""HKLM\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes"" /v ActivePowerScheme")
Do While objExec.Status = 0
    WScript.Sleep 100
Loop
output = objExec.StdOut.ReadAll()

If InStr(output, "ActivePowerScheme") > 0 Then
    activePlanGUID = Trim(Split(output, " ")(UBound(Split(output, " "))))
Else
    WScript.Echo "Error: Could not find ActivePowerScheme."
    WScript.Quit
End If

' Step 2: Construct the registry key for the monitor's timeout value
regKey = "HKLM\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\" & activePlanGUID & _
"\7516b95f-f776-4464-8c53-06167f40cc99\3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e"

' Combine the lines properly without line breaks
regKey = Replace(regKey, vbCrLf, "")

' Debug: Print the constructed registry key
' WScript.Echo "Constructed Registry Key: " & regKey

' Step 3: Query the registry to retrieve the monitor's timeout value for AC power
Set objExec = WSHShell.Exec("reg query """ & regKey & """ /v ACSettingIndex")
Do While objExec.Status = 0
    WScript.Sleep 100
Loop
output = objExec.StdOut.ReadAll()

' Debug: Print the output of the registry query
' WScript.Echo "Registry Query Output: " & vbCrLf & output

If InStr(output, "ACSettingIndex") > 0 Then
    lines = Split(output, vbCrLf)
    For i = 0 To UBound(lines)
        line = Trim(lines(i))
        If InStr(line, "ACSettingIndex") > 0 Then
            originalMonitorTimeoutHex = Trim(Split(line, " ")(UBound(Split(line, " "))))
            
            ' Debug: Print the retrieved ACSettingIndex value before conversion
            ' WScript.Echo "Retrieved ACSettingIndex (Hex): " & originalMonitorTimeoutHex
            
            ' Convert the hexadecimal value to decimal
            On Error Resume Next ' Prevent script from breaking if conversion fails
            originalMonitorTimeoutDec = CLng("&H" & Replace(originalMonitorTimeoutHex, "0x", "")) / 60
            If Err.Number <> 0 Then
                WScript.Echo "Error converting ACSettingIndex to decimal: " & Err.Description
                WScript.Quit
            End If
            On Error GoTo 0
            originalTimeoutDetermined = True
            Exit For
        End If
    Next
Else
    WScript.Echo "Error: Could not find ACSettingIndex in the registry."
    WScript.Quit
End If

' Step 4: Run winddcutil to detect monitors and find the display index
Set objExec = WSHShell.Exec("powershell -Command ""(Invoke-Expression '.\winddcutil.exe detect') | Where-Object {$_ -like '1 ASUS PG32UCDM*'} | ForEach-Object {($_ -split ' ')[0]}""")
Do While objExec.Status = 0
    WScript.Sleep 100
Loop
monindex = Trim(objExec.StdOut.ReadLine)

If monindex = "" Then
    WScript.Echo "Monitor not found."
    WScript.Quit
End If

' Step 5: Run winddcutil to get the current value of register 0xFD
Set objExec = WSHShell.Exec("winddcutil.exe getvcp " & monindex & " 0xfd")
Do While objExec.Status = 0
    WScript.Sleep 100
Loop
output = objExec.StdOut.ReadAll()
currentValue = Trim(Split(output, " ")(2))

' Step 6: Calculate proposed values
proposedValue = CInt(currentValue) + 16

' Display all values for user confirmation
' WScript.Echo "Current Values:" & vbCrLf & _
'            "Original Monitor Timeout (Decimal): " & originalMonitorTimeoutDec & " minutes" & vbCrLf & _
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

' Step 7: Change monitor's timeout to 10 minutes to ensure pixel cleaning can complete
WSHShell.Run "powercfg -change -monitor-timeout-ac 10", 0, True

' Step 8: Run winddcutil to set the pixel cleaning value to the calculated new value
WSHShell.Run "winddcutil.exe setvcp " & monindex & " 0xfd " & proposedValue, 0, True
WScript.Sleep 1000
WScript.Echo "Done cleaning!." & vbCrLf & _
             "If " & originalMonitorTimeoutDec & " or more minutes have elapse without user input, your display will likely enter standby" & vbCrLf & _
			 "Original Windows display timeout will be restored to " & originalMonitorTimeoutDec & " minutes." 
			 
' Step 9: Wait for 6 minutes
WScript.Sleep 360000

' Step 10: Restore original monitor timeout value and exit
WSHShell.Run "powercfg -change -monitor-timeout-ac " & originalMonitorTimeoutDec, 0, True
WScript.Quit
