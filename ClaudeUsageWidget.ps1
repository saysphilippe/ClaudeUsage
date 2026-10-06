# Claude usage desktop widget - reads local Claude Code logs (~/.claude/projects/*.jsonl)
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, Microsoft.VisualBasic, System.Windows.Forms, System.Drawing

$dir      = Split-Path -Parent $MyInvocation.MyCommand.Path
$cfgPath  = Join-Path $dir 'config.json'
$histPath = Join-Path $dir 'history.json'
$logRoot  = Join-Path $env:USERPROFILE '.claude\projects'
$inv      = [Globalization.CultureInfo]::InvariantCulture

$cfg = [ordered]@{ sessionLimit = 1000000; weeklyLimit = 15000000; topmost = $true; left = 100; top = 100; language = 'en'; tab = 'now'; historyRange = 30 }
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
        tabNow = 'Now'; tabHist = 'History'; hDaily = 'Tokens per day'; hToday = 'Today by hour'
        hModels = 'Models'; hProjects = 'Top projects'; hTotal = 'Total {0} · avg {1}/day'
        hNoData = 'No data for this period yet'; hSince = 'History since {0}'; noProject = 'No project'
        hTodayTotal = 'Today {0} · busiest {1:00}:00–{2:00}:00'
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
        tabNow = 'Nå'; tabHist = 'Historikk'; hDaily = 'Tokens per dag'; hToday = 'I dag per time'
        hModels = 'Modeller'; hProjects = 'Mest brukte prosjekter'; hTotal = 'Totalt {0} · snitt {1}/dag'
        hNoData = 'Ingen data for denne perioden ennå'; hSince = 'Historikk siden {0}'; noProject = 'Uten prosjekt'
        hTodayTotal = 'I dag {0} · mest brukt kl. {1:00}–{2:00}'
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
        tabNow = 'Nu'; tabHist = 'Historik'; hDaily = 'Tokens per dag'; hToday = 'I dag per timme'
        hModels = 'Modeller'; hProjects = 'Mest använda projekt'; hTotal = 'Totalt {0} · snitt {1}/dag'
        hNoData = 'Ingen data för perioden ännu'; hSince = 'Historik sedan {0}'; noProject = 'Inget projekt'
        hTodayTotal = 'I dag {0} · mest använt kl. {1:00}–{2:00}'
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
        tabNow = 'Nu'; tabHist = 'Historik'; hDaily = 'Tokens pr. dag'; hToday = 'I dag pr. time'
        hModels = 'Modeller'; hProjects = 'Mest brugte projekter'; hTotal = 'I alt {0} · gns. {1}/dag'
        hNoData = 'Ingen data for perioden endnu'; hSince = 'Historik siden {0}'; noProject = 'Intet projekt'
        hTodayTotal = 'I dag {0} · mest brugt kl. {1:00}–{2:00}'
    }
}
$langNames = [ordered]@{ en = 'English'; no = 'Norsk'; sv = 'Svenska'; da = 'Dansk' }
function T($key) { $s = $strings[$cfg.language]; if (-not $s) { $s = $strings.en }; $s[$key] }

# --- Reading the logs -------------------------------------------------------
# Parsed entries are cached per file and only re-read when the file changes.
$script:fileCache = @{}
# Sessions started outside a project (Windows folder, home folder, drive root) are grouped as '~' = "No project"
$noProject = '~'
function Get-ProjectName($cwd) {
    $p = $cwd.TrimEnd('\', '/')
    if ($p -match '^[A-Za-z]:$' -or $p -eq $env:USERPROFILE.TrimEnd('\') -or
        $p -eq $env:windir -or $p.StartsWith("$env:windir\", [StringComparison]::OrdinalIgnoreCase)) { return $noProject }
    Split-Path $p -Leaf
}
function Read-LogFile($f) {
    $list = New-Object System.Collections.Generic.List[object]
    try {
        foreach ($line in [IO.File]::ReadLines($f.FullName)) {
            if ($line -notmatch '"usage"') { continue }
            try { $o = $line | ConvertFrom-Json } catch { continue }
            $u = $o.message.usage; if (-not $u -or -not $o.timestamp) { continue }
            $n = [int64]$u.input_tokens + [int64]$u.output_tokens + [int64]$u.cache_creation_input_tokens
            if ($n -le 0) { continue }
            $proj = if ($o.cwd) { Get-ProjectName $o.cwd } else { $f.Directory.Name }
            $model = if ($o.message.model) { [string]$o.message.model } else { 'unknown' }
            $list.Add([pscustomobject]@{
                id = $o.message.id; n = $n; model = $model; project = $proj
                t = [datetime]::Parse($o.timestamp, $null, 'RoundtripKind').ToUniversalTime()
            })
        }
    } catch {}
    , $list
}
function Update-Data {
    $live = @{}
    foreach ($f in Get-ChildItem $logRoot -Recurse -Filter *.jsonl -ErrorAction SilentlyContinue) {
        $live[$f.FullName] = 1
        $stamp = "$($f.LastWriteTimeUtc.Ticks)-$($f.Length)"
        $c = $script:fileCache[$f.FullName]
        if (-not $c -or $c.stamp -ne $stamp) { $script:fileCache[$f.FullName] = @{ stamp = $stamp; items = (Read-LogFile $f) } }
    }
    foreach ($k in @($script:fileCache.Keys)) { if (-not $live[$k]) { $script:fileCache.Remove($k) } }
    $seen = @{}; $all = New-Object System.Collections.Generic.List[object]
    foreach ($c in $script:fileCache.Values) {
        foreach ($i in $c.items) {
            if ($i.id) { if ($seen[$i.id]) { continue }; $seen[$i.id] = 1 }
            $all.Add($i)
        }
    }
    @($all | Sort-Object t)
}

function Get-Usage($all) {
    $now = (Get-Date).ToUniversalTime()
    $recent = @($all | Where-Object { $_.t -ge $now.AddDays(-7) })
    # 5-hour windows start at the first message after the previous window ended
    $wStart = $null; $wTok = 0
    foreach ($i in $recent) {
        if (-not $wStart -or $i.t -ge $wStart.AddHours(5)) { $wStart = $i.t; $wTok = 0 }
        $wTok += $i.n
    }
    if (-not $wStart -or $now -ge $wStart.AddHours(5)) { $wTok = 0; $reset = $null } else { $reset = $wStart.AddHours(5) }
    $week = ($recent | Measure-Object n -Sum).Sum; if (-not $week) { $week = 0 }
    [pscustomobject]@{ session = $wTok; reset = $reset; week = $week }
}

# --- History ----------------------------------------------------------------
# Claude Code deletes old logs (30 days by default), so daily totals are kept in
# history.json. A day is only overwritten when the logs show more usage for it.
function ConvertTo-Counts($o) { $h = @{}; if ($o) { $o.psobject.Properties | ForEach-Object { $h[$_.Name] = [int64]$_.Value } }; $h }
$script:history = @{}
if (Test-Path $histPath) {
    try {
        (Get-Content $histPath -Raw | ConvertFrom-Json).days.psobject.Properties | ForEach-Object {
            $v = $_.Value
            $hours = if ($v.hours.value) { $v.hours.value } else { $v.hours }
            $projects = ConvertTo-Counts $v.projects
            # Older versions stored the Windows folder name itself
            foreach ($old in 'system32', 'SysWOW64') {
                if ($projects.ContainsKey($old)) { $projects[$noProject] = [int64]$projects[$noProject] + $projects[$old]; $projects.Remove($old) }
            }
            $script:history[$_.Name] = @{ total = [int64]$v.total; hours = [int64[]]@($hours); models = (ConvertTo-Counts $v.models); projects = $projects }
        }
    } catch {}
}
function Update-History($all) {
    $agg = @{}
    foreach ($i in $all) {
        $lt = $i.t.ToLocalTime(); $k = $lt.ToString('yyyy-MM-dd', $inv)
        # [int64[]]::new, not New-Object: a PSObject-wrapped array serializes as {"value":[...],"Count":24} in PS 5.1
        if (-not $agg[$k]) { $agg[$k] = @{ total = [int64]0; hours = [int64[]]::new(24); models = @{}; projects = @{} } }
        $d = $agg[$k]
        $d.total += $i.n; $d.hours[$lt.Hour] += $i.n
        $d.models[$i.model] = [int64]$d.models[$i.model] + $i.n
        $d.projects[$i.project] = [int64]$d.projects[$i.project] + $i.n
    }
    $changed = $false
    foreach ($k in $agg.Keys) {
        $old = $script:history[$k]
        if (-not $old -or $agg[$k].total -gt $old.total) { $script:history[$k] = $agg[$k]; $changed = $true }
    }
    $cutoff = (Get-Date).AddDays(-400).ToString('yyyy-MM-dd', $inv)
    foreach ($k in @($script:history.Keys)) { if ($k -lt $cutoff) { $script:history.Remove($k); $changed = $true } }
    if ($changed) { @{ version = 1; days = $script:history } | ConvertTo-Json -Depth 5 -Compress | Set-Content $histPath -Encoding UTF8 }
}

function Fmt([double]$n) { if ($n -ge 1e6) { '{0:0.0}M' -f ($n/1e6) } elseif ($n -ge 1e3) { '{0:0}K' -f ($n/1e3) } else { "$n" } }
function ModelName($m) {
    if ($m -match '^claude-([a-z]+)-(\d+)-(\d{1,2})(-|$)') { (Get-Culture).TextInfo.ToTitleCase($matches[1]) + " $($matches[2]).$($matches[3])" }
    elseif ($m -match '^claude-([a-z]+)-(\d+)(-|$)') { (Get-Culture).TextInfo.ToTitleCase($matches[1]) + " $($matches[2])" }
    else { $m }
}

[xml]$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        ShowInTaskbar="False" SizeToContent="WidthAndHeight" ResizeMode="NoResize">
  <Border Name="root" CornerRadius="10" Background="#E61E1E1E" Padding="14,10" Width="250">
    <StackPanel>
      <DockPanel Margin="0,0,0,6">
        <StackPanel Orientation="Horizontal" DockPanel.Dock="Right" VerticalAlignment="Center">
          <TextBlock Name="tabNow" FontSize="11" Cursor="Hand"/>
          <TextBlock Name="tabHist" FontSize="11" Cursor="Hand" Margin="8,0,0,0"/>
        </StackPanel>
        <TextBlock Name="title" Foreground="#D97757" FontWeight="SemiBold" FontSize="13"/>
      </DockPanel>
      <StackPanel Name="nowPanel">
        <TextBlock Name="sLabel" Foreground="#EEE" FontSize="12"/>
        <ProgressBar Name="sBar" Height="6" Maximum="100" Margin="0,3,0,2" Background="#333" BorderThickness="0" Foreground="#D97757"/>
        <TextBlock Name="sSub" Foreground="#999" FontSize="11" Margin="0,0,0,8"/>
        <TextBlock Name="wLabel" Foreground="#EEE" FontSize="12"/>
        <ProgressBar Name="wBar" Height="6" Maximum="100" Margin="0,3,0,2" Background="#333" BorderThickness="0" Foreground="#6A9BCC"/>
        <TextBlock Name="wSub" Foreground="#999" FontSize="11"/>
      </StackPanel>
      <StackPanel Name="histPanel" Visibility="Collapsed">
        <DockPanel>
          <StackPanel Name="rangePanel" Orientation="Horizontal" DockPanel.Dock="Right"/>
          <TextBlock Name="hDaily" Foreground="#EEE" FontSize="12"/>
        </DockPanel>
        <Canvas Name="cDaily" Margin="0,4,0,0" ClipToBounds="False"/>
        <TextBlock Name="hTotal" Foreground="#999" FontSize="11" Margin="0,2,0,8"/>
        <TextBlock Name="hToday" Foreground="#EEE" FontSize="12"/>
        <Canvas Name="cToday" Margin="0,4,0,0"/>
        <TextBlock Name="hTodayTotal" Foreground="#999" FontSize="11" Margin="0,2,0,8"/>
        <TextBlock Name="hModels" Foreground="#EEE" FontSize="12"/>
        <StackPanel Name="pModels" Margin="0,2,0,8"/>
        <TextBlock Name="hProjects" Foreground="#EEE" FontSize="12"/>
        <StackPanel Name="pProjects" Margin="0,2,0,4"/>
        <TextBlock Name="hSince" Foreground="#666" FontSize="10"/>
      </StackPanel>
      <TextBlock Name="upd" Foreground="#666" FontSize="10" Margin="0,6,0,0"/>
    </StackPanel>
  </Border>
</Window>
'@
$win = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
$el = @{}
'root','title','tabNow','tabHist','nowPanel','histPanel','sLabel','sBar','sSub','wLabel','wBar','wSub','upd',
'rangePanel','hDaily','cDaily','hTotal','hToday','cToday','hTodayTotal','hModels','pModels','hProjects','pProjects','hSince' | ForEach-Object { $el[$_] = $win.FindName($_) }
$win.Left = $cfg.left; $win.Top = $cfg.top; $win.Topmost = [bool]$cfg.topmost
$script:last = $null

# --- Chart helpers ----------------------------------------------------------
$brushConv = New-Object Windows.Media.BrushConverter
function Brush($c) { $brushConv.ConvertFromString($c) }
function Add-Bar($canvas, $x, $w, $h, $areaH, $color, $tip, $y0 = 0) {
    $r = New-Object Windows.Shapes.Rectangle
    $r.Width = [math]::Max(1, $w); $r.Height = $h; $r.Fill = Brush $color
    [Windows.Controls.Canvas]::SetLeft($r, $x); [Windows.Controls.Canvas]::SetTop($r, $y0 + $areaH - $h)
    [void]$canvas.Children.Add($r)
    # Full-height transparent strip so small bars are still easy to hover
    $hit = New-Object Windows.Shapes.Rectangle
    $hit.Width = [math]::Max(1, $w); $hit.Height = $areaH; $hit.Fill = [Windows.Media.Brushes]::Transparent; $hit.ToolTip = $tip
    [Windows.Controls.Canvas]::SetLeft($hit, $x); [Windows.Controls.Canvas]::SetTop($hit, $y0)
    [void]$canvas.Children.Add($hit)
}
function Add-Label($canvas, $text, $x, $y, $align = 'left') {
    $tb = New-Object Windows.Controls.TextBlock
    $tb.Text = $text; $tb.FontSize = 9; $tb.Foreground = Brush '#777'
    $tb.Measure((New-Object Windows.Size ([double]::PositiveInfinity), ([double]::PositiveInfinity)))
    $w = $tb.DesiredSize.Width
    if ($align -eq 'right') { $x -= $w } elseif ($align -eq 'center') { $x -= $w / 2 }
    $x = [math]::Max(0, [math]::Min($x, $canvas.Width - $w))
    [Windows.Controls.Canvas]::SetLeft($tb, $x); [Windows.Controls.Canvas]::SetTop($tb, $y)
    [void]$canvas.Children.Add($tb)
}
function Add-ShareRow($panel, $label, $value, $share, $color, $width) {
    $row = New-Object Windows.Controls.DockPanel; $row.Margin = New-Object Windows.Thickness 0, 2, 0, 0
    $name = New-Object Windows.Controls.TextBlock
    $name.Text = $label; $name.Width = 110; $name.FontSize = 11; $name.Foreground = Brush '#CCC'; $name.TextTrimming = 'CharacterEllipsis'; $name.ToolTip = $label
    $val = New-Object Windows.Controls.TextBlock
    $val.Text = '{0} ({1:0}%)' -f (Fmt $value), ($share * 100); $val.Width = 78; $val.FontSize = 11; $val.Foreground = Brush '#999'; $val.TextAlignment = 'Right'
    [Windows.Controls.DockPanel]::SetDock($name, 'Left'); [Windows.Controls.DockPanel]::SetDock($val, 'Right')
    $bar = New-Object Windows.Shapes.Rectangle
    $bar.Height = 6; $bar.RadiusX = 2; $bar.RadiusY = 2; $bar.Fill = Brush $color
    $bar.Width = [math]::Max(2, ($width - 196) * $share); $bar.HorizontalAlignment = 'Left'; $bar.VerticalAlignment = 'Center'
    [void]$row.Children.Add($name); [void]$row.Children.Add($val); [void]$row.Children.Add($bar)
    [void]$panel.Children.Add($row)
}

$histWidth = 320; $chartW = $histWidth - 28
$rangeButtons = foreach ($days in 7, 30, 90) {
    $b = New-Object Windows.Controls.TextBlock
    $b.Text = "${days}d"; $b.Tag = $days; $b.FontSize = 11; $b.Cursor = 'Hand'; $b.Margin = New-Object Windows.Thickness 6, 0, 0, 0
    $b.Add_MouseLeftButtonDown({ param($s, $e) $cfg.historyRange = [int]$s.Tag; Save-Config; Draw-History; $e.Handled = $true })
    [void]$el.rangePanel.Children.Add($b); $b
}

function Draw-History {
    $N = [int]$cfg.historyRange; if ($N -notin 7, 30, 90) { $N = 30 }
    $today = (Get-Date).Date
    foreach ($b in $rangeButtons) { $b.Foreground = Brush $(if ([int]$b.Tag -eq $N) { '#D97757' } else { '#777' }) }
    foreach ($k in 'hDaily', 'hToday', 'hModels', 'hProjects') { $el[$k].Text = T $k }

    # Tokens per day
    $keys = for ($j = $N - 1; $j -ge 0; $j--) { $today.AddDays(-$j).ToString('yyyy-MM-dd', $inv) }
    $vals = foreach ($k in $keys) { if ($script:history[$k]) { [int64]$script:history[$k].total } else { [int64]0 } }
    $max = ($vals | Measure-Object -Maximum).Maximum
    $c = $el.cDaily; $c.Children.Clear(); $c.Width = $chartW; $dayH = 56; $padTop = 13; $c.Height = $padTop + $dayH + 14
    $bw = $chartW / $N; $gap = [math]::Max(1, $bw * 0.2)
    for ($j = 0; $j -lt $N; $j++) {
        $date = [datetime]::ParseExact($keys[$j], 'yyyy-MM-dd', $inv)
        $h = if ($max -gt 0) { $dayH * $vals[$j] / $max } else { 0 }; if ($vals[$j] -gt 0 -and $h -lt 2) { $h = 2 }
        Add-Bar $c ($j * $bw) ($bw - $gap) $h $dayH $(if ($j -eq $N - 1) { '#F0A07F' } else { '#D97757' }) ('{0}: {1}' -f $date.ToString('ddd d. MMM'), (Fmt $vals[$j])) $padTop
    }
    if ($max -gt 0) { Add-Label $c (Fmt $max) $chartW 0 'right' }
    Add-Label $c ([datetime]::ParseExact($keys[0], 'yyyy-MM-dd', $inv).ToString('d. MMM')) 0 ($padTop + $dayH + 1)
    Add-Label $c ($today.ToString('d. MMM')) $chartW ($padTop + $dayH + 1) 'right'

    $total = ($vals | Measure-Object -Sum).Sum
    $first = @($script:history.Keys | Sort-Object)[0]
    $span = $N
    if ($first) { $span = [math]::Min($N, ($today - [datetime]::ParseExact($first, 'yyyy-MM-dd', $inv)).Days + 1) }
    $el.hTotal.Text = if ($total -gt 0) { (T 'hTotal') -f (Fmt $total), (Fmt ($total / [math]::Max(1, $span))) } else { T 'hNoData' }

    # Today by hour
    $td = $script:history[$today.ToString('yyyy-MM-dd', $inv)]
    $hours = if ($td) { $td.hours } else { [int64[]]::new(24) }
    $hmax = ($hours | Measure-Object -Maximum).Maximum
    $c = $el.cToday; $c.Children.Clear(); $c.Width = $chartW; $H2 = 32; $padTop = 13; $c.Height = $padTop + $H2 + 13
    $hw = $chartW / 24; $now = (Get-Date).Hour
    for ($j = 0; $j -lt 24; $j++) {
        $h = if ($hmax -gt 0) { $H2 * $hours[$j] / $hmax } else { 0 }; if ($hours[$j] -gt 0 -and $h -lt 2) { $h = 2 }
        Add-Bar $c ($j * $hw) ($hw - 2) $h $H2 $(if ($j -eq $now) { '#9DBEE0' } else { '#6A9BCC' }) ('{0:00}:00–{1:00}:00: {2}' -f $j, ($j + 1), (Fmt $hours[$j])) $padTop
    }
    foreach ($j in 0, 6, 12, 18) { Add-Label $c ('{0:00}' -f $j) ($j * $hw) ($padTop + $H2 + 1) }
    Add-Label $c '24' $chartW ($padTop + $H2 + 1) 'right'
    if ($hmax -gt 0) {
        Add-Label $c (Fmt $hmax) $chartW 0 'right'
        $peak = [array]::IndexOf($hours, [int64]$hmax)
        $el.hTodayTotal.Text = (T 'hTodayTotal') -f (Fmt ($hours | Measure-Object -Sum).Sum), $peak, ($peak + 1)
    } else { $el.hTodayTotal.Text = T 'hNoData' }

    # Models and projects over the selected range
    $models = @{}; $projects = @{}
    foreach ($k in $keys) {
        $d = $script:history[$k]; if (-not $d) { continue }
        foreach ($m in $d.models.Keys) { $name = ModelName $m; $models[$name] = [int64]$models[$name] + $d.models[$m] }
        foreach ($p in $d.projects.Keys) { $projects[$p] = [int64]$projects[$p] + $d.projects[$p] }
    }
    $palette = '#D97757', '#6A9BCC', '#8FB573', '#C9A44C', '#A78BCF'
    $el.pModels.Children.Clear(); $el.pProjects.Children.Clear()
    $j = 0
    foreach ($e in ($models.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 5)) {
        Add-ShareRow $el.pModels $e.Key $e.Value ($e.Value / [double][math]::Max(1, $total)) $palette[$j % 5] $chartW; $j++
    }
    foreach ($e in ($projects.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 5)) {
        $none = $e.Key -eq $noProject
        Add-ShareRow $el.pProjects $(if ($none) { T 'noProject' } else { $e.Key }) $e.Value ($e.Value / [double][math]::Max(1, $total)) $(if ($none) { '#777' } else { '#6A9BCC' }) $chartW
    }
    $el.hModels.Visibility = $el.pModels.Visibility = $(if ($models.Count) { 'Visible' } else { 'Collapsed' })
    $el.hProjects.Visibility = $el.pProjects.Visibility = $(if ($projects.Count) { 'Visible' } else { 'Collapsed' })
    $el.hSince.Text = if ($first) { (T 'hSince') -f [datetime]::ParseExact($first, 'yyyy-MM-dd', $inv).ToString('d') } else { '' }
}

function Show-Tab($tab) {
    $hist = $tab -eq 'history'
    $el.nowPanel.Visibility = $(if ($hist) { 'Collapsed' } else { 'Visible' })
    $el.histPanel.Visibility = $(if ($hist) { 'Visible' } else { 'Collapsed' })
    $el.root.Width = $(if ($hist) { $histWidth } else { 250 })
    $el.tabNow.Foreground = Brush $(if ($hist) { '#777' } else { '#EEE' })
    $el.tabHist.Foreground = Brush $(if ($hist) { '#EEE' } else { '#777' })
    if ($hist) { Draw-History }
    if ($cfg.tab -ne $tab) { $cfg.tab = $tab; Save-Config }
}
$el.tabNow.Add_MouseLeftButtonDown({ param($s, $e) Show-Tab 'now'; $e.Handled = $true })
$el.tabHist.Add_MouseLeftButtonDown({ param($s, $e) Show-Tab 'history'; $e.Handled = $true })

function Refresh {
    $all = Update-Data
    Update-History $all
    $u = Get-Usage $all; $script:last = $u
    $sp = [math]::Min(100, 100 * $u.session / [double]$cfg.sessionLimit)
    $wp = [math]::Min(100, 100 * $u.week / [double]$cfg.weeklyLimit)
    $el.title.Text = T 'title'
    $el.tabNow.Text = T 'tabNow'; $el.tabHist.Text = T 'tabHist'
    $el.sLabel.Text = (T 'session') -f $sp
    $el.sBar.Value = $sp
    $rem = [math]::Max(0, $cfg.sessionLimit - $u.session)
    $resetTxt = if ($u.reset) { $m = [int]($u.reset - (Get-Date).ToUniversalTime()).TotalMinutes; (T 'resets') -f [math]::Floor($m/60), ($m % 60) } else { '' }
    $el.sSub.Text = ((T 'usedLeft') -f (Fmt $u.session), (Fmt $rem)) + $resetTxt
    $el.wLabel.Text = (T 'week') -f $wp
    $el.wBar.Value = $wp
    $el.wSub.Text = (T 'usedLeft') -f (Fmt $u.week), (Fmt ([math]::Max(0, $cfg.weeklyLimit - $u.week)))
    $el.upd.Text = (T 'updated') -f (Get-Date -Format t)
    if ($cfg.tab -eq 'history') { Draw-History }
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

# The History tab is larger than Now. Place the window at the position the user chose
# (cfg.left/top), shifted only as far as needed to stay inside that monitor's work area.
# The shifted position is not saved, so switching back to Now returns to the chosen spot.
function Keep-OnScreen {
    $src = [Windows.PresentationSource]::FromVisual($win)
    $sx = 1.0; $sy = 1.0
    if ($src) { $m = $src.CompositionTarget.TransformToDevice; $sx = $m.M11; $sy = $m.M22 }
    $pt = New-Object Drawing.Point ([int]($cfg.left * $sx)), ([int]($cfg.top * $sy))
    $wa = [Windows.Forms.Screen]::FromPoint($pt).WorkingArea
    $left = [math]::Max($wa.Left / $sx, [math]::Min([double]$cfg.left, $wa.Right / $sx - $win.ActualWidth))
    $top  = [math]::Max($wa.Top / $sy,  [math]::Min([double]$cfg.top,  $wa.Bottom / $sy - $win.ActualHeight))
    if ($win.Left -ne $left) { $win.Left = $left }
    if ($win.Top -ne $top) { $win.Top = $top }
}
$win.Add_SizeChanged({ Keep-OnScreen })
$timer = New-Object Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds(60); $timer.Add_Tick({ Refresh }); $timer.Start()
Refresh
Show-Tab $cfg.tab
[void]$win.ShowDialog()
