# Removes the Claude Usage widget, its shortcuts and settings.
$dest = Join-Path $env:LOCALAPPDATA 'ClaudeUsage'
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
    Where-Object CommandLine -like '*ClaudeUsageWidget.ps1*' |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
foreach ($folder in [Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('Startup')) {
    Remove-Item (Join-Path $folder 'Claude Usage.lnk') -ErrorAction SilentlyContinue
}
Remove-Item $dest -Recurse -Force -ErrorAction SilentlyContinue
Write-Host 'Claude Usage widget uninstalled.' -ForegroundColor Green
