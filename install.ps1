# ClaudeUsage installer - downloads the widget, adds Desktop + Startup shortcuts, and starts it.
# Usage: irm https://raw.githubusercontent.com/__USER__/ClaudeUsage/main/install.ps1 | iex
$ErrorActionPreference = 'Stop'
$base = 'https://raw.githubusercontent.com/__USER__/ClaudeUsage/main'
$dest = Join-Path $env:LOCALAPPDATA 'ClaudeUsage'

Write-Host 'Installing Claude Usage widget...' -ForegroundColor Cyan
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
    Where-Object CommandLine -like '*ClaudeUsageWidget.ps1*' |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

New-Item -ItemType Directory -Force $dest | Out-Null
foreach ($f in 'ClaudeUsageWidget.ps1', 'Launch.vbs', 'uninstall.ps1') {
    Invoke-WebRequest "$base/$f" -OutFile (Join-Path $dest $f) -UseBasicParsing
}

$ws = New-Object -ComObject WScript.Shell
foreach ($folder in [Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('Startup')) {
    $lnk = $ws.CreateShortcut((Join-Path $folder 'Claude Usage.lnk'))
    $lnk.TargetPath = 'wscript.exe'
    $lnk.Arguments = "`"$dest\Launch.vbs`""
    $lnk.IconLocation = 'powershell.exe,0'
    $lnk.Save()
}

Start-Process wscript.exe "`"$dest\Launch.vbs`""
Write-Host "Done. Installed to $dest - the widget is now running and will start at login." -ForegroundColor Green
Write-Host 'Tip: right-click the widget and use "Calibrate" with the % from /usage in Claude Code.'
