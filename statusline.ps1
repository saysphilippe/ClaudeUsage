# Claude Code status line for the Claude Usage widget.
# Claude Code sends session data as JSON on stdin after each reply. For Pro and Max subscribers it
# includes rate_limits: the exact 5-hour and weekly usage (the same figures as /usage) and when they
# reset. This script saves them to live.json for the widget and prints a short status line.
# Keep this file ASCII-only; other characters are built with [char].
[Console]::InputEncoding = [Text.Encoding]::UTF8
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
try { $d = [Console]::In.ReadToEnd() | ConvertFrom-Json } catch { exit 0 }

$lang = 'en'
try { $lang = (Get-Content (Join-Path $dir 'config.json') -Raw | ConvertFrom-Json).language } catch {}
$words = @{
    en = @{ s = '5h'; w = 'week'; c = 'context' }
    no = @{ s = '5t'; w = 'uke'; c = 'kontekst' }
    sv = @{ s = '5h'; w = 'vecka'; c = 'kontext' }
    da = @{ s = '5t'; w = 'uge'; c = 'kontekst' }
}[$lang]
if (-not $words) { $words = @{ s = '5h'; w = 'week'; c = 'context' } }

$esc = [char]27
function Paint($pct, $text) {
    $code = if ($pct -ge 90) { 31 } elseif ($pct -ge 70) { 33 } else { 32 }
    "$esc[${code}m$text$esc[0m"
}
function Clock($epoch) { [DateTimeOffset]::FromUnixTimeSeconds([int64]$epoch).LocalDateTime.ToString('HH:mm') }

$parts = @()
if ($d.model.display_name) { $parts += $d.model.display_name }
$r = $d.rate_limits
if ($r) {
    $live = [ordered]@{ at = (Get-Date).ToUniversalTime().ToString('o') }
    foreach ($k in 'five_hour', 'seven_day') {
        if ($null -ne $r.$k.used_percentage) { $live[$k] = [ordered]@{ pct = [double]$r.$k.used_percentage; resets_at = [int64]$r.$k.resets_at } }
    }
    try {
        $tmp = Join-Path $dir 'live.json.tmp'
        $live | ConvertTo-Json | Set-Content $tmp -Encoding UTF8
        Move-Item $tmp (Join-Path $dir 'live.json') -Force
    } catch {}
    # Log each new weekly percentage, so the widget can draw the week as Claude counted it.
    # A new reset time means a new week, and the log starts over.
    if ($live.seven_day) {
        try {
            $logPath = Join-Path $dir 'live-log.csv'
            $inv = [Globalization.CultureInfo]::InvariantCulture
            $pct = $live.seven_day.pct.ToString($inv); $reset = $live.seven_day.resets_at
            $row = '{0},{1},{2}' -f [DateTimeOffset]::UtcNow.ToUnixTimeSeconds(), $pct, $reset
            $prev = if (Test-Path $logPath) { @(Get-Content $logPath -Tail 1)[0] }
            $f = if ($prev) { $prev.Split(',') }
            if (-not $f -or $f.Count -lt 3 -or [math]::Abs([int64]$f[2] - $reset) -gt 3600) { Set-Content $logPath $row -Encoding ASCII }
            elseif ($f[1] -ne $pct) { Add-Content $logPath $row -Encoding ASCII }
        } catch {}
    }
    $arrow = [char]0x2192
    if ($live.five_hour) { $p = $live.five_hour.pct; $parts += Paint $p ('{0} {1:0}% ({2}{3})' -f $words.s, $p, $arrow, (Clock $live.five_hour.resets_at)) }
    if ($live.seven_day) { $p = $live.seven_day.pct; $parts += Paint $p ('{0} {1:0}%' -f $words.w, $p) }
}
$ctx = $d.context_window.used_percentage
if ($null -ne $ctx) { $parts += '{0} {1:0}%' -f $words.c, [double]$ctx }
$parts -join ([string][char]0x00B7).PadLeft(2).PadRight(3)
