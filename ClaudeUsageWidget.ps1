# Claude usage desktop widget - reads local Claude Code logs (~/.claude/projects/*.jsonl)
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, Microsoft.VisualBasic

$dir     = Split-Path -Parent $MyInvocation.MyCommand.Path
$cfgPath = Join-Path $dir 'config.json'
$logRoot = Join-Path $env:USERPROFILE '.claude\projects'

$cfg = [ordered]@{ sessionLimit = 1000000; weeklyLimit = 15000000; topmost = $true; left = 100; top = 100 }
if (Test-Path $cfgPath) {
    try { (Get-Content $cfgPath -Raw | ConvertFrom-Json).psobject.Properties | ForEach-Object { $cfg[$_.Name] = $_.Value } } catch {}
}
function Save-Config { $cfg | ConvertTo-Json | Set-Content $cfgPath -Encoding UTF8 }

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
      <TextBlock Text="Claude usage" Foreground="#D97757" FontWeight="SemiBold" FontSize="13" Margin="0,0,0,6"/>
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
$el = @{}; 'sLabel','sBar','sSub','wLabel','wBar','wSub','upd' | ForEach-Object { $el[$_] = $win.FindName($_) }
$win.Left = $cfg.left; $win.Top = $cfg.top; $win.Topmost = [bool]$cfg.topmost
$script:last = $null

function Refresh {
    $u = Get-Usage; $script:last = $u
    $sp = [math]::Min(100, 100 * $u.session / [double]$cfg.sessionLimit)
    $wp = [math]::Min(100, 100 * $u.week / [double]$cfg.weeklyLimit)
    $el.sLabel.Text = "5-hour session: {0:0}%" -f $sp
    $el.sBar.Value = $sp
    $rem = [math]::Max(0, $cfg.sessionLimit - $u.session)
    $resetTxt = if ($u.reset) { $m = [int]($u.reset - (Get-Date).ToUniversalTime()).TotalMinutes; " · resets in {0}h {1:00}m" -f [math]::Floor($m/60), ($m % 60) } else { '' }
    $el.sSub.Text = "$(Fmt $u.session) used · $(Fmt $rem) left$resetTxt"
    $el.wLabel.Text = "Last 7 days: {0:0}%" -f $wp
    $el.wBar.Value = $wp
    $el.wSub.Text = "$(Fmt $u.week) used · $(Fmt ([math]::Max(0, $cfg.weeklyLimit - $u.week))) left"
    $el.upd.Text = "Updated $(Get-Date -Format t) · right-click for options"
}

function Ask($prompt, $default) { [Microsoft.VisualBasic.Interaction]::InputBox($prompt, 'Claude usage widget', "$default") }
function Calibrate($which) {
    $used = if ($which -eq 'session') { $script:last.session } else { $script:last.week }
    $p = Ask "Run /usage in Claude Code and enter the % shown for the $which limit:" ''
    if ($p -as [double] -and [double]$p -gt 0 -and $used -gt 0) {
        $cfg["$($which)Limit"] = [int64]($used * 100 / [double]$p); Save-Config; Refresh
    }
}
function SetLimit($which) {
    $v = Ask "Token limit for the $which window:" $cfg["$($which)Limit"]
    if ($v -as [int64]) { $cfg["$($which)Limit"] = [int64]$v; Save-Config; Refresh }
}

$menu = New-Object Windows.Controls.ContextMenu
function AddItem($text, $action) { $mi = New-Object Windows.Controls.MenuItem; $mi.Header = $text; $mi.Add_Click($action); [void]$menu.Items.Add($mi); $mi }
AddItem 'Refresh now' { Refresh } | Out-Null
AddItem 'Calibrate 5-hour limit from /usage %…' { Calibrate 'session' } | Out-Null
AddItem 'Calibrate weekly limit from /usage %…' { Calibrate 'weekly' } | Out-Null
AddItem 'Set 5-hour limit manually…' { SetLimit 'session' } | Out-Null
AddItem 'Set weekly limit manually…' { SetLimit 'weekly' } | Out-Null
$top = AddItem 'Always on top' { $win.Topmost = -not $win.Topmost; $this.IsChecked = $win.Topmost; $cfg.topmost = $win.Topmost; Save-Config }
$top.IsChecked = $win.Topmost
AddItem 'Close' { $win.Close() } | Out-Null
$win.ContextMenu = $menu

$win.Add_MouseLeftButtonDown({ $win.DragMove(); $cfg.left = $win.Left; $cfg.top = $win.Top; Save-Config })
$timer = New-Object Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds(60); $timer.Add_Tick({ Refresh }); $timer.Start()
Refresh
[void]$win.ShowDialog()
