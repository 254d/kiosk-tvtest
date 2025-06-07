$ErrorActionPreference = 'Stop'
$Host.ui.RawUI.WindowTitle = 'Kiosk'

# ----------------------------------------------------------------------
# 定数
# ----------------------------------------------------------------------
$TVTestPath = 'C:\DTV\TVTest_64bit\TVTest.exe'
$TVTestArgs = '/f'

# ----------------------------------------------------------------------
# TVTest起動制御プロセス
# ----------------------------------------------------------------------
$TVTest = {
  while ($true) {
    $p = [System.Diagnostics.Process]
    $pi = [System.Diagnostics.ProcessStartInfo]
    $pi = New-Object System.Diagnostics.ProcessStartInfo
    $pi.FileName = $args[0]
    $pi.Arguments = $args[1]
    $pi.UseShellExecute = $false
    $pi.RedirectStandardOutput = $false

    $p = [System.Diagnostics.Process]::Start($pi)
    $p.WaitForExit()

    Start-Sleep -Seconds 2
  }
}

# ----------------------------------------------------------------------
# ディスプレイ変更イベント
# ----------------------------------------------------------------------
$EventType = [Microsoft.Win32.SystemEvents]
$EventName = 'DisplaySettingsChanged'

$Action = {
  $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
  Write-Host "[$Timestamp] Display settings have been changed."

  try {
    $ProcList = Get-Process TVTest
    foreach ($Proc in $ProcList) {
      $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
      Write-Host "[$Timestamp] Stop process" $Proc.Id
      Stop-Process $Proc.Id
    }
    Start-Sleep -Seconds 2
  }
  catch {
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    Write-Host "[$Timestamp] Process not found."
  }
}

$DisplayEventJob = Register-ObjectEvent -InputObject $EventType -EventName $EventName -Action $Action

# ----------------------------------------------------------------------
# メイン処理
# ----------------------------------------------------------------------
try {
  $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
  Write-Host "[$Timestamp] Start"

  $TVTestJob = Start-Job -ScriptBlock $TVTest -ArgumentList $TVTestPath, $TVTestArgs

  Wait-Event -SourceIdentifier DisplaySettingsChanged
} 
finally {
  $TVTestJob | Remove-Job -Force
  $DisplayEventJob | Remove-Job -Force
}
