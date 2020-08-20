
Set wshShell = CreateObject( "WScript.Shell" )

MyPwd = wshShell.ExpandEnvironmentStrings( "%MYPWD%" )
'WScript.Echo MyPwd

Appnm = wshShell.ExpandEnvironmentStrings( "%APPBLDNM%" )
'WScript.Echo Appnm

Set objWMIService = GetObject("winmgmts:\\.\root\cimv2")

Set colItems = objWMIService.ExecQuery("Select * From Win32_Process")

For Each objItem in colItems
    If Instr(objItem.CommandLine, MyPwd) > 0 Then
      If Instr(objItem.CommandLine, Appnm) > 0 Then
        'Wscript.Echo objItem.CommandLine & objItem.ProcessId & " " & objItem.ParentProcessId
        'objItem.terminate
        'WScript.Echo " " & objItem.ParentProcessId
        MyPid = objItem.ProcessId
        MyParPid = objItem.ParentProcessId
        'WScript.Echo " " & MyPid & " " & MyParPid
      End If
    End If
Next

For Each objItem in colItems
  CurrPid = objItem.ProcessId
  If (CurrPid = MyPid) Then
    'WScript.Echo " Found MyPid " & objItem.ProcessId
    objItem.terminate
  End If
  If (CurrPid = MyParPid) Then
    'WScript.Echo " Found MyParPid " & objItem.ProcessId
    'objItem.terminate
  End If
Next

