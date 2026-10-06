# ClaudeUsage installer - downloads the widget, adds Desktop + Startup shortcuts, and starts it.
# Usage: irm https://raw.githubusercontent.com/saysphilippe/ClaudeUsage/main/install.ps1 | iex
# Keep this file ASCII-only: Invoke-Expression chokes on a UTF-8 BOM, so Nordic letters are built with [char].
$ErrorActionPreference = 'Stop'
$base = 'https://raw.githubusercontent.com/saysphilippe/ClaudeUsage/main'
$dest = Join-Path $env:LOCALAPPDATA 'ClaudeUsage'
$cfgPath = Join-Path $dest 'config.json'
$ae = [char]0xE6; $oe = [char]0xF8; $aa = [char]0xE5; $auml = [char]0xE4; $ouml = [char]0xF6

$cfg = [ordered]@{}
if (Test-Path $cfgPath) {
    try { (Get-Content $cfgPath -Raw | ConvertFrom-Json).psobject.Properties | ForEach-Object { $cfg[$_.Name] = $_.Value } } catch {}
}

$langs = 'en', 'no', 'sv', 'da'
$lang = $env:CLAUDEUSAGE_LANG
if ($lang -notin $langs) {
    Write-Host ''
    Write-Host "Choose display language / Velg spr${aa}k / V${auml}lj spr${aa}k / V${ae}lg sprog:" -ForegroundColor Cyan
    Write-Host '  1) English'
    Write-Host '  2) Norsk'
    Write-Host '  3) Svenska'
    Write-Host '  4) Dansk'
    $default = [array]::IndexOf($langs, [string]$cfg.language) + 1
    if ($default -lt 1) { $default = 1 }
    $answer = Read-Host "[1-4] (default $default)"
    if ($answer -notmatch '^[1-4]$') { $answer = $default }
    $lang = $langs[[int]$answer - 1]
}
$cfg.language = $lang

$msg = @{
    en = @{
        installing = 'Installing Claude Usage widget...'
        done = "Done. Installed to $dest - the widget is now running and will start at login."
        tip = 'Tip: right-click the widget and use "Calibrate" with the % from /usage in Claude Code. Change language under "Language".'
    }
    no = @{
        installing = 'Installerer Claude-forbruk-widgeten...'
        done = "Ferdig. Installert i $dest - widgeten kj${oe}rer n${aa} og starter automatisk ved innlogging."
        tip = "Tips: h${oe}yreklikk widgeten og bruk ""Kalibrer"" med prosenten fra /usage i Claude Code. Spr${aa}ket kan endres under ""Spr${aa}k""."
    }
    sv = @{
        installing = "Installerar widgeten Claude-anv${auml}ndning..."
        done = "Klart. Installerad i $dest - widgeten k${ouml}rs nu och startar automatiskt vid inloggning."
        tip = "Tips: h${ouml}gerklicka p${aa} widgeten och anv${auml}nd ""Kalibrera"" med procentsatsen fr${aa}n /usage i Claude Code. Spr${aa}ket kan ${auml}ndras under ""Spr${aa}k""."
    }
    da = @{
        installing = 'Installerer Claude-forbrug-widgetten...'
        done = "F${ae}rdig. Installeret i $dest - widgetten k${oe}rer nu og starter automatisk ved login."
        tip = "Tip: h${oe}jreklik p${aa} widgetten og brug ""Kalibrer"" med procenten fra /usage i Claude Code. Sproget kan ${ae}ndres under ""Sprog""."
    }
}[$lang]

Write-Host $msg.installing -ForegroundColor Cyan
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
Write-Host $msg.done -ForegroundColor Green
Write-Host $msg.tip
