# Claude usage desktop widget - reads local Claude Code logs (~/.claude/projects/*.jsonl)
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, Microsoft.VisualBasic

$dir     = Split-Path -Parent $MyInvocation.MyCommand.Path
$cfgPath = Join-Path $dir 'config.json'
$logRoot = Join-Path $env:USERPROFILE '.claude\projects'

$cfg = [ordered]@{ sessionLimit = 1000000; weeklyLimit = 15000000; topmost = $true; left = 100; top = 100; language = 'en' }
if (Test-Path $cfgPath) {
    try { (Get-Content $cfgPath -Raw | ConvertFrom-Json).psobject.Properties | ForEach-Object { $cfg[$_.Name] = $_.Value } } catch {}
}
function Save-Config { $cfg | ConvertTo-Json | Set-Content $cfgPath -Encoding UTF8 }

$strings = @{
    en = @{
        title = 'Claude usage'; session = '5-hour session: {0:0}%'; resets = ' · resets in {0}h {1:00}m'
        usedLeft = '{0} used · {1} left'; week = 'Last 7 days: {0:0}%'; updated = 'Updated {0} · right-click for options'
        askCal_session = 'Run /usage in Claude Code and enter the % shown for the 5-hour limit:'
        askCal_weekly = 'Run /usage in Claude Code and enter the % shown for the weekly limit:'
        askLimit_session = 'Token limit for the 5-hour window:'; askLimit_weekly = 'Token limit for the weekly window:'
        mRefresh = 'Refresh now'; mCalSession = 'Calibrate 5-hour limit from /usage %…'; mCalWeekly = 'Calibrate weekly limit from /usage %…'
        mSetSession = 'Set 5-hour limit manually…'; mSetWeekly = 'Set weekly limit manually…'
        mTopmost = 'Always on top'; mLanguage = 'Language'; mClose = 'Close'
    }
    no = @{
        title = 'Claude-forbruk'; session = '5-timers økt: {0:0}%'; resets = ' · nullstilles om {0}t {1:00}m'
        usedLeft = '{0} brukt · {1} igjen'; week = 'Siste 7 dager: {0:0}%'; updated = 'Oppdatert {0} · høyreklikk for valg'
        askCal_session = 'Kjør /usage i Claude Code og skriv inn prosenten som vises for 5-timersgrensen:'
        askCal_weekly = 'Kjør /usage i Claude Code og skriv inn prosenten som vises for ukegrensen:'
        askLimit_session = 'Tokengrense for 5-timersvinduet:'; askLimit_weekly = 'Tokengrense for ukevinduet:'
        mRefresh = 'Oppdater nå'; mCalSession = 'Kalibrer 5-timersgrensen fra /usage-%…'; mCalWeekly = 'Kalibrer ukegrensen fra /usage-%…'
        mSetSession = 'Angi 5-timersgrensen manuelt…'; mSetWeekly = 'Angi ukegrensen manuelt…'
        mTopmost = 'Alltid øverst'; mLanguage = 'Språk'; mClose = 'Lukk'
    }
    sv = @{
        title = 'Claude-användning'; session = '5-timmarssession: {0:0}%'; resets = ' · nollställs om {0}h {1:00}m'
        usedLeft = '{0} använt · {1} kvar'; week = 'Senaste 7 dagarna: {0:0}%'; updated = 'Uppdaterad {0} · högerklicka för alternativ'
        askCal_session = 'Kör /usage i Claude Code och ange procentsatsen som visas för 5-timmarsgränsen:'
        askCal_weekly = 'Kör /usage i Claude Code och ange procentsatsen som visas för veckogränsen:'
        askLimit_session = 'Tokengräns för 5-timmarsfönstret:'; askLimit_weekly = 'Tokengräns för veckofönstret:'
        mRefresh = 'Uppdatera nu'; mCalSession = 'Kalibrera 5-timmarsgränsen från /usage-%…'; mCalWeekly = 'Kalibrera veckogränsen från /usage-%…'
        mSetSession = 'Ange 5-timmarsgränsen manuellt…'; mSetWeekly = 'Ange veckogränsen manuellt…'
        mTopmost = 'Alltid överst'; mLanguage = 'Språk'; mClose = 'Stäng'
    }
    da = @{
        title = 'Claude-forbrug'; session = '5-timers session: {0:0}%'; resets = ' · nulstilles om {0}t {1:00}m'
        usedLeft = '{0} brugt · {1} tilbage'; week = 'Seneste 7 dage: {0:0}%'; updated = 'Opdateret {0} · højreklik for indstillinger'
        askCal_session = 'Kør /usage i Claude Code, og indtast den procent, der vises for 5-timersgrænsen:'
        askCal_weekly = 'Kør /usage i Claude Code, og indtast den procent, der vises for ugegrænsen:'
        askLimit_session = 'Tokengrænse for 5-timersvinduet:'; askLimit_weekly = 'Tokengrænse for ugevinduet:'
        mRefresh = 'Opdater nu'; mCalSession = 'Kalibrer 5-timersgrænsen fra /usage-%…'; mCalWeekly = 'Kalibrer ugegrænsen fra /usage-%…'
        mSetSession = 'Angiv 5-timersgrænsen manuelt…'; mSetWeekly = 'Angiv ugegrænsen manuelt…'
        mTopmost = 'Altid øverst'; mLanguage = 'Sprog'; mClose = 'Luk'
    }
}
$langNames = [ordered]@{ en = 'English'; no = 'Norsk'; sv = 'Svenska'; da = 'Dansk' }
function T($key) { $s = $strings[$cfg.language]; if (-not $s) { $s = $strings.en }; $s[$key] }

function Get-Usage {
    $since = (Get-Date).ToUniversalTime().AddDays(-7)
    $seen = @{}; $items = New-Object System.Collections.Generic.List[object]
    Get-ChildItem $logRoot -Recurse -Filter *.jsonl -ErrorAction SilentlyContinue |
      Where-Object { $_.LastWriteTimeUtc -ge $since } | ForEach-Object {
        foreach ($line in [IO.File]::ReadLines($_.FullName)) {
            if ($line -notmatch '"usage"') { continue }
            try { $o = $line | ConvertFrom-Json } catch { continue }
            $u = $o.message.usage; if (-not $u -or -not $o.timestamp) { continue }
            $id = $o.message.id; if ($id) { if ($seen[$id]) { continue }; $seen[$id] = 1 }
            $t = [datetime]::Parse($o.timestamp, $null, 'RoundtripKind').ToUniversalTime()
            if ($t -lt $since) { continue }
            $n = [int64]$u.input_tokens + [int64]$u.output_tokens + [int64]$u.cache_creation_input_tokens
            $items.Add([pscustomobject]@{ t = $t; n = $n })
        }
    }
    $sorted = $items | Sort-Object t
    $now = (Get-Date).ToUniversalTime()
    # 5-hour windows start at the first message after the previous window ended
    $wStart = $null; $wTok = 0
    foreach ($i in $sorted) {
        if (-not $wStart -or $i.t -ge $wStart.AddHours(5)) { $wStart = $i.t; $wTok = 0 }
        $wTok += $i.n
    }
    if (-not $wStart -or $now -ge $wStart.AddHours(5)) { $wTok = 0; $reset = $null } else { $reset = $wStart.AddHours(5) }
    $week = ($sorted | Measure-Object n -Sum).Sum; if (-not $week) { $week = 0 }
    [pscustomobject]@{ session = $wTok; reset = $reset; week = $week }
}

function Fmt([double]$n) { if ($n -ge 1e6) { '{0:0.0}M' -f ($n/1e6) } elseif ($n -ge 1e3) { '{0:0}K' -f ($n/1e3) } else { "$n" } }

[xml]$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        ShowInTaskbar="False" SizeToContent="WidthAndHeight" ResizeMode="NoResize">
  <Border CornerRadius="10" Background="#E61E1E1E" Padding="14,10" Width="250">
    <StackPanel>
      <TextBlock Name="title" Foreground="#D97757" FontWeight="SemiBold" FontSize="13" Margin="0,0,0,6"/>
      <TextBlock Name="sLabel" Foreground="#EEE" FontSize="12"/>
      <ProgressBar Name="sBar" Height="6" Maximum="100" Margin="0,3,0,2" Background="#333" BorderThickness="0" Foreground="#D97757"/>
      <TextBlock Name="sSub" Foreground="#999" FontSize="11" Margin="0,0,0,8"/>
      <TextBlock Name="wLabel" Foreground="#EEE" FontSize="12"/>
      <ProgressBar Name="wBar" Height="6" Maximum="100" Margin="0,3,0,2" Background="#333" BorderThickness="0" Foreground="#6A9BCC"/>
      <TextBlock Name="wSub" Foreground="#999" FontSize="11"/>
      <TextBlock Name="upd" Foreground="#666" FontSize="10" Margin="0,6,0,0"/>
    </StackPanel>
  </Border>
</Window>
'@
$win = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
$el = @{}; 'title','sLabel','sBar','sSub','wLabel','wBar','wSub','upd' | ForEach-Object { $el[$_] = $win.FindName($_) }
$win.Left = $cfg.left; $win.Top = $cfg.top; $win.Topmost = [bool]$cfg.topmost
$script:last = $null

function Refresh {
    $u = Get-Usage; $script:last = $u
    $sp = [math]::Min(100, 100 * $u.session / [double]$cfg.sessionLimit)
    $wp = [math]::Min(100, 100 * $u.week / [double]$cfg.weeklyLimit)
    $el.title.Text = T 'title'
    $el.sLabel.Text = (T 'session') -f $sp
    $el.sBar.Value = $sp
    $rem = [math]::Max(0, $cfg.sessionLimit - $u.session)
    $resetTxt = if ($u.reset) { $m = [int]($u.reset - (Get-Date).ToUniversalTime()).TotalMinutes; (T 'resets') -f [math]::Floor($m/60), ($m % 60) } else { '' }
    $el.sSub.Text = ((T 'usedLeft') -f (Fmt $u.session), (Fmt $rem)) + $resetTxt
    $el.wLabel.Text = (T 'week') -f $wp
    $el.wBar.Value = $wp
    $el.wSub.Text = (T 'usedLeft') -f (Fmt $u.week), (Fmt ([math]::Max(0, $cfg.weeklyLimit - $u.week)))
    $el.upd.Text = (T 'updated') -f (Get-Date -Format t)
}

function Ask($prompt, $default) { [Microsoft.VisualBasic.Interaction]::InputBox($prompt, (T 'title'), "$default") }
function Calibrate($which) {
    $used = if ($which -eq 'session') { $script:last.session } else { $script:last.week }
    $p = Ask (T "askCal_$which") ''
    if ($p -as [double] -and [double]$p -gt 0 -and $used -gt 0) {
        $cfg["$($which)Limit"] = [int64]($used * 100 / [double]$p); Save-Config; Refresh
    }
}
function SetLimit($which) {
    $v = Ask (T "askLimit_$which") $cfg["$($which)Limit"]
    if ($v -as [int64]) { $cfg["$($which)Limit"] = [int64]$v; Save-Config; Refresh }
}

$menu = New-Object Windows.Controls.ContextMenu
$menuItems = @{}
function AddItem($key, $action, $parent = $menu) { $mi = New-Object Windows.Controls.MenuItem; $mi.Add_Click($action); [void]$parent.Items.Add($mi); if ($key) { $menuItems[$key] = $mi }; $mi }
AddItem 'mRefresh' { Refresh } | Out-Null
AddItem 'mCalSession' { Calibrate 'session' } | Out-Null
AddItem 'mCalWeekly' { Calibrate 'weekly' } | Out-Null
AddItem 'mSetSession' { SetLimit 'session' } | Out-Null
AddItem 'mSetWeekly' { SetLimit 'weekly' } | Out-Null
$top = AddItem 'mTopmost' { $win.Topmost = -not $win.Topmost; $this.IsChecked = $win.Topmost; $cfg.topmost = $win.Topmost; Save-Config }
$top.IsChecked = $win.Topmost
$langMenu = AddItem 'mLanguage' {}
$langItems = @{}
foreach ($code in $langNames.Keys) {
    $li = AddItem $null { $cfg.language = $this.Tag; Save-Config; Set-MenuText; Refresh } $langMenu
    $li.Tag = $code; $li.Header = $langNames[$code]; $langItems[$code] = $li
}
AddItem 'mClose' { $win.Close() } | Out-Null
function Set-MenuText {
    foreach ($k in $menuItems.Keys) { $menuItems[$k].Header = T $k }
    foreach ($c in $langItems.Keys) { $langItems[$c].IsChecked = ($c -eq $cfg.language) }
}
Set-MenuText
$win.ContextMenu = $menu

$win.Add_MouseLeftButtonDown({ $win.DragMove(); $cfg.left = $win.Left; $cfg.top = $win.Top; Save-Config })
$timer = New-Object Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds(60); $timer.Add_Tick({ Refresh }); $timer.Start()
Refresh
[void]$win.ShowDialog()
