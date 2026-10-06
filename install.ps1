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
        statusAdded = 'Added a Claude Code status line. With Pro or Max the widget gets the exact /usage figures after your next reply in Claude Code - no calibration needed.'
        statusKept = 'You already have a Claude Code status line, so it was left as it is. The widget estimates usage from your logs instead.'
    }
    no = @{
        installing = 'Installerer Claude-forbruk-widgeten...'
        done = "Ferdig. Installert i $dest - widgeten kj${oe}rer n${aa} og starter automatisk ved innlogging."
        tip = "Tips: h${oe}yreklikk widgeten og bruk ""Kalibrer"" med prosenten fra /usage i Claude Code. Spr${aa}ket kan endres under ""Spr${aa}k""."
        statusAdded = "La til en statuslinje i Claude Code. Med Pro eller Max f${aa}r widgeten de n${oe}yaktige tallene fra /usage etter neste svar i Claude Code - ingen kalibrering trengs."
        statusKept = "Du har allerede en statuslinje i Claude Code, s${aa} den ble ikke endret. Widgeten ansl${aa}r i stedet forbruket fra loggene."
    }
    sv = @{
        installing = "Installerar widgeten Claude-anv${auml}ndning..."
        done = "Klart. Installerad i $dest - widgeten k${ouml}rs nu och startar automatiskt vid inloggning."
        tip = "Tips: h${ouml}gerklicka p${aa} widgeten och anv${auml}nd ""Kalibrera"" med procentsatsen fr${aa}n /usage i Claude Code. Spr${aa}ket kan ${auml}ndras under ""Spr${aa}k""."
        statusAdded = "Lade till en statusrad i Claude Code. Med Pro eller Max f${aa}r widgeten de exakta siffrorna fr${aa}n /usage efter n${auml}sta svar i Claude Code - ingen kalibrering beh${ouml}vs."
        statusKept = "Du har redan en statusrad i Claude Code, s${aa} den l${auml}mnades som den var. Widgeten uppskattar i st${auml}llet anv${auml}ndningen fr${aa}n loggarna."
    }
    da = @{
        installing = 'Installerer Claude-forbrug-widgetten...'
        done = "F${ae}rdig. Installeret i $dest - widgetten k${oe}rer nu og starter automatisk ved login."
        tip = "Tip: h${oe}jreklik p${aa} widgetten og brug ""Kalibrer"" med procenten fra /usage i Claude Code. Sproget kan ${ae}ndres under ""Sprog""."
        statusAdded = "Tilf${oe}jede en statuslinje i Claude Code. Med Pro eller Max f${aa}r widgetten de pr${ae}cise tal fra /usage efter n${ae}ste svar i Claude Code - ingen kalibrering n${oe}dvendig."
        statusKept = "Du har allerede en statuslinje i Claude Code, s${aa} den blev ikke ${ae}ndret. Widgetten vurderer i stedet forbruget ud fra logfilerne."
    }
}[$lang]

Write-Host $msg.installing -ForegroundColor Cyan
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
    Where-Object CommandLine -like '*ClaudeUsageWidget.ps1*' |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

New-Item -ItemType Directory -Force $dest | Out-Null
foreach ($f in 'ClaudeUsageWidget.ps1', 'Launch.vbs', 'uninstall.ps1', 'statusline.ps1') {
    # Run from a cloned copy: install those files; run via irm | iex: download them
    if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot $f))) { Copy-Item (Join-Path $PSScriptRoot $f) (Join-Path $dest $f) -Force }
    else { Invoke-WebRequest "$base/$f" -OutFile (Join-Path $dest $f) -UseBasicParsing }
}
$cfg | ConvertTo-Json | Set-Content $cfgPath -Encoding UTF8

# Claude Code status line: gives the widget the exact /usage figures (Pro and Max). Only added when
# no other status line is configured, so an existing one is never replaced.
$settingsPath = Join-Path $env:USERPROFILE '.claude\settings.json'
$slCommand = 'powershell -NoProfile -ExecutionPolicy Bypass -File "' + ((Join-Path $dest 'statusline.ps1') -replace '\\', '/') + '"'
$statusNote = $null
try {
    $settings = [ordered]@{}
    if (Test-Path $settingsPath) { (Get-Content $settingsPath -Raw | ConvertFrom-Json).psobject.Properties | ForEach-Object { $settings[$_.Name] = $_.Value } }
    if (-not $settings.Contains('statusLine') -or $settings.statusLine.command -like '*ClaudeUsage*statusline.ps1*') {
        $settings.statusLine = [ordered]@{ type = 'command'; command = $slCommand }
        New-Item -ItemType Directory -Force (Split-Path $settingsPath) | Out-Null
        [IO.File]::WriteAllText($settingsPath, ($settings | ConvertTo-Json -Depth 20), (New-Object Text.UTF8Encoding $false))
        $statusNote = 'added'
    } else { $statusNote = 'kept' }
} catch { $statusNote = 'failed' }

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
if ($statusNote -eq 'added') { Write-Host $msg.statusAdded } else { Write-Host $msg.tip; if ($statusNote -eq 'kept') { Write-Host $msg.statusKept } }
