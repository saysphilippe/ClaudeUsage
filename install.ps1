# ClaudeUsage installer - downloads the widget, adds Desktop + Startup shortcuts, and starts it.
# Usage: irm https://raw.githubusercontent.com/saysphilippe/ClaudeUsage/main/install.ps1 | iex
# Keep this file ASCII-only: Invoke-Expression chokes on a UTF-8 BOM, so Norwegian letters are built with [char].
$ErrorActionPreference = 'Stop'
$base = 'https://raw.githubusercontent.com/saysphilippe/ClaudeUsage/main'
$dest = Join-Path $env:LOCALAPPDATA 'ClaudeUsage'
$cfgPath = Join-Path $dest 'config.json'
$oe = [char]0xF8; $aa = [char]0xE5

$cfg = [ordered]@{}
if (Test-Path $cfgPath) {
    try { (Get-Content $cfgPath -Raw | ConvertFrom-Json).psobject.Properties | ForEach-Object { $cfg[$_.Name] = $_.Value } } catch {}
}

$lang = $env:CLAUDEUSAGE_LANG
if ($lang -notin 'en', 'no') {
    Write-Host ''
    Write-Host "Choose display language / Velg spr${aa}k:" -ForegroundColor Cyan
    Write-Host '  1) English'
    Write-Host '  2) Norsk'
    $default = if ($cfg.language -eq 'no') { '2' } else { '1' }
    $answer = Read-Host "[1/2] (default $default)"
    if (-not $answer) { $answer = $default }
    $lang = if ($answer -eq '2' -or $answer -match '^n') { 'no' } else { 'en' }
}
$no = $lang -eq 'no'
$cfg.language = $lang

Write-Host $(if ($no) { 'Installerer Claude-forbruk-widgeten...' } else { 'Installing Claude Usage widget...' }) -ForegroundColor Cyan
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
    Where-Object CommandLine -like '*ClaudeUsageWidget.ps1*' |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

New-Item -ItemType Directory -Force $dest | Out-Null
foreach ($f in 'ClaudeUsageWidget.ps1', 'Launch.vbs', 'uninstall.ps1') {
    # Run from a cloned copy: install those files; run via irm | iex: download them
    if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot $f))) { Copy-Item (Join-Path $PSScriptRoot $f) (Join-Path $dest $f) -Force }
    else { Invoke-WebRequest "$base/$f" -OutFile (Join-Path $dest $f) -UseBasicParsing }
}
$cfg | ConvertTo-Json | Set-Content $cfgPath -Encoding UTF8

$ws = New-Object -ComObject WScript.Shell
foreach ($folder in [Environment]::GetFolderPath('Desktop'), [Environment]::GetFolderPath('Startup')) {
    $lnk = $ws.CreateShortcut((Join-Path $folder 'Claude Usage.lnk'))
    $lnk.TargetPath = 'wscript.exe'
    $lnk.Arguments = "`"$dest\Launch.vbs`""
    $lnk.IconLocation = 'powershell.exe,0'
    $lnk.Save()
}

Start-Process wscript.exe "`"$dest\Launch.vbs`""
if ($no) {
    Write-Host "Ferdig. Installert i $dest - widgeten kj${oe}rer n${aa} og starter automatisk ved innlogging." -ForegroundColor Green
    Write-Host "Tips: h${oe}yreklikk widgeten og bruk ""Kalibrer"" med prosenten fra /usage i Claude Code. Spr${aa}ket kan endres under ""Spr${aa}k""."
} else {
    Write-Host "Done. Installed to $dest - the widget is now running and will start at login." -ForegroundColor Green
    Write-Host 'Tip: right-click the widget and use "Calibrate" with the % from /usage in Claude Code. Change language under "Language".'
}
