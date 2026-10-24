# Copies the widget files from this folder to the installed copy (%LOCALAPPDATA%\ClaudeUsage) and restarts the widget,
# so the installed widget always runs the latest version. Settings and history in the installed folder are not touched.
# Run by hand, or automatically by the git post-commit and post-merge hooks (see README, "Automatic updates").
# Keep this file ASCII-only.
$src = Split-Path -Parent $MyInvocation.MyCommand.Path
$dest = Join-Path $env:LOCALAPPDATA 'ClaudeUsage'
if (-not (Test-Path $dest)) { exit 0 }   # not installed on this PC: nothing to update
$files = 'ClaudeUsageWidget.ps1', 'statusline.ps1', 'Launch.vbs', 'uninstall.ps1'
$changed = $false
foreach ($f in $files) {
    $a = Join-Path $src $f; $b = Join-Path $dest $f
    if (-not (Test-Path $a)) { continue }
    if (-not (Test-Path $b) -or (Get-FileHash $a).Hash -ne (Get-FileHash $b).Hash) { Copy-Item $a $b -Force; $changed = $true }
}
if (-not $changed) { exit 0 }
# Restart the widget (only if it was running), so the new version is the one on screen
$running = @(Get-CimInstance Win32_Process -Filter "Name = 'powershell.exe'" | Where-Object { $_.CommandLine -like '*ClaudeUsageWidget.ps1*' -and $_.ProcessId -ne $PID })
if ($running.Count) {
    $running | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    Start-Sleep -Milliseconds 700
    Start-Process wscript.exe ('"' + (Join-Path $dest 'Launch.vbs') + '"')
}
