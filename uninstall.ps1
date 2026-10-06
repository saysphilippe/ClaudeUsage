# Removes the Claude Usage widget, its shortcuts and settings.
$dest = Join-Path $env:LOCALAPPDATA 'ClaudeUsage'
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
    Where-Object CommandLine -like '*ClaudeUsageWidget.ps1*' |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
foreach ($folder in [Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('Startup')) {
    Remove-Item (Join-Path $folder 'Claude Usage.lnk') -ErrorAction SilentlyContinue
}
# Remove the Claude Code status line, but only if it is the one the installer added
$settingsPath = Join-Path $env:USERPROFILE '.claude\settings.json'
try {
    $settings = [ordered]@{}
    (Get-Content $settingsPath -Raw | ConvertFrom-Json).psobject.Properties | ForEach-Object { $settings[$_.Name] = $_.Value }
    if ($settings.statusLine.command -like '*ClaudeUsage*statusline.ps1*') {
        $settings.Remove('statusLine')
        [IO.File]::WriteAllText($settingsPath, ($settings | ConvertTo-Json -Depth 20), (New-Object Text.UTF8Encoding $false))
    }
} catch {}
Remove-Item $dest -Recurse -Force -ErrorAction SilentlyContinue
Write-Host 'Claude Usage widget uninstalled.' -ForegroundColor Green
