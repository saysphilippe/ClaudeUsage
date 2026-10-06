# Claude usage desktop widget - reads local Claude Code logs (~/.claude/projects/*.jsonl)
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, Microsoft.VisualBasic, System.Windows.Forms, System.Drawing, System.Net.Http

$dir      = Split-Path -Parent $MyInvocation.MyCommand.Path
$cfgPath  = Join-Path $dir 'config.json'
$histPath = Join-Path $dir 'history.json'
$logRoot  = Join-Path $env:USERPROFILE '.claude\projects'
$inv      = [Globalization.CultureInfo]::InvariantCulture

$cfg = [ordered]@{ sessionLimit = 1000000; weeklyLimit = 15000000; topmost = $true; left = 100; top = 100; language = 'en'; tab = 'now'; historyRange = 30
                   creditLimit = 0; creditResetDay = 1; creditBase = $null; creditBaseAt = $null; fx = $null; fxDate = '' }
if (Test-Path $cfgPath) {
    try { (Get-Content $cfgPath -Raw | ConvertFrom-Json).psobject.Properties | ForEach-Object { $cfg[$_.Name] = $_.Value } } catch {}
}
function Save-Config { $cfg | ConvertTo-Json | Set-Content $cfgPath -Encoding UTF8 }

$strings = @{
    en = @{
        title = 'Claude usage'; session = '5-hour session: {0:0}%'; resets = ' · resets in {0}h {1:00}m'
        usedLeft = '{0} used · {1} left'; week = 'Last 7 days: {0:0}%'; updated = 'Updated {0} · right-click for options'
        usedOver = '{0} used · {1} over the limit'; overHint = 'Over the limit – you are using extra credits, or the real limit is higher than set here. Calibrate from /usage (right-click).'
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
        cLabel = 'Extra credits: {0} of {1}'; cSub = '{0} left · resets {1}'; cSubLocal = '{0} used · {1} left · resets {2}'
        cOk = 'Within your plan – no credits are being used.'; cOkEta = 'Within your plan. At this pace the 5-hour limit is reached in ~{0} (at {1}).'
        cUsing = 'Using credits now: ~{0}/hour.'; cEmpty = ' At this pace they run out in ~{0} (at {1}).'
        cResetFirst = ' The session resets first, in {0}.'; cOverIdle = 'Over the limit – new messages use credits.'
        cStopped = 'Credit limit reached – Claude stops until the {0} resets.'
        cForecast = 'Forecast for this period: {0}'; cSession = 'session'; cWeek = 'weekly limit'
        cTooHigh = 'Claude is still answering, so the estimate is too high. Enter the amount from claude.ai (right-click → Extra credits) and calibrate the limits from /usage.'
        calHint = 'The limits are not calibrated, so the credit estimate may be wrong. Right-click → Calibrate from /usage.'
        mCredit = 'Extra credits'; mCreditLimit = 'Set credit limit (USD)…'; mCreditSpent = 'Enter credits used from claude.ai…'; mCreditDay = 'Credit reset day…'
        askCreditLimit = 'Your monthly limit for extra credits in USD (0 hides the section):'
        askCreditSpent = 'Credits used this period in USD, as shown on claude.ai (Settings → Usage):'
        askCreditDay = 'Day of the month the credits reset (1–28):'
    }
    no = @{
        title = 'Claude-forbruk'; session = '5-timers økt: {0:0}%'; resets = ' · nullstilles om {0}t {1:00}m'
        usedLeft = '{0} brukt · {1} igjen'; week = 'Siste 7 dager: {0:0}%'; updated = 'Oppdatert {0} · høyreklikk for valg'
        usedOver = '{0} brukt · {1} over grensen'; overHint = 'Over grensen – du bruker ekstra kreditter, eller grensen er høyere enn satt her. Kalibrer med /usage (høyreklikk).'
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
        cLabel = 'Ekstra kreditter: {0} av {1}'; cSub = '{0} igjen · nullstilles {1}'; cSubLocal = '{0} brukt · {1} igjen · nullstilles {2}'
        cOk = 'Innenfor abonnementet – ingen kreditter brukes nå.'; cOkEta = 'Innenfor abonnementet. Med dette tempoet nås 5-timersgrensen om ~{0} (kl. {1}).'
        cUsing = 'Bruker kreditter nå: ~{0} per time.'; cEmpty = ' Med dette tempoet er de brukt opp om ~{0} (kl. {1}).'
        cResetFirst = ' Økten nullstilles før det, om {0}.'; cOverIdle = 'Over grensen – nye meldinger trekker kreditter.'
        cStopped = 'Kredittgrensen er nådd – Claude stopper til {0} nullstilles.'
        cForecast = 'Prognose for perioden: {0}'; cSession = 'økten'; cWeek = 'ukegrensen'
        cTooHigh = 'Claude svarer fortsatt, så anslaget er for høyt. Registrer beløpet fra claude.ai (høyreklikk → Ekstra kreditter) og kalibrer grensene fra /usage.'
        calHint = 'Grensene er ikke kalibrert, så kreditt-anslaget kan bli feil. Høyreklikk → Kalibrer fra /usage.'
        mCredit = 'Ekstra kreditter'; mCreditLimit = 'Angi kredittgrense (USD)…'; mCreditSpent = 'Angi brukte kreditter fra claude.ai…'; mCreditDay = 'Dag kredittene nullstilles…'
        askCreditLimit = 'Månedlig grense for ekstra kreditter i USD (0 skjuler seksjonen):'
        askCreditSpent = 'Kreditter brukt i denne perioden i USD, slik claude.ai viser (Innstillinger → Bruk):'
        askCreditDay = 'Dag i måneden kredittene nullstilles (1–28):'
    }
    sv = @{
        title = 'Claude-användning'; session = '5-timmarssession: {0:0}%'; resets = ' · nollställs om {0}h {1:00}m'
        usedLeft = '{0} använt · {1} kvar'; week = 'Senaste 7 dagarna: {0:0}%'; updated = 'Uppdaterad {0} · högerklicka för alternativ'
        usedOver = '{0} använt · {1} över gränsen'; overHint = 'Över gränsen – du använder extra krediter, eller så är gränsen högre än inställt här. Kalibrera med /usage (högerklicka).'
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
        cLabel = 'Extra krediter: {0} av {1}'; cSub = '{0} kvar · nollställs {1}'; cSubLocal = '{0} använt · {1} kvar · nollställs {2}'
        cOk = 'Inom abonnemanget – inga krediter används nu.'; cOkEta = 'Inom abonnemanget. I den här takten nås 5-timmarsgränsen om ~{0} (kl. {1}).'
        cUsing = 'Använder krediter nu: ~{0} per timme.'; cEmpty = ' I den här takten tar de slut om ~{0} (kl. {1}).'
        cResetFirst = ' Sessionen nollställs innan dess, om {0}.'; cOverIdle = 'Över gränsen – nya meddelanden drar krediter.'
        cStopped = 'Kreditgränsen är nådd – Claude stoppar tills {0} nollställs.'
        cForecast = 'Prognos för perioden: {0}'; cSession = 'sessionen'; cWeek = 'veckogränsen'
        cTooHigh = 'Claude svarar fortfarande, så uppskattningen är för hög. Ange beloppet från claude.ai (högerklicka → Extra krediter) och kalibrera gränserna från /usage.'
        calHint = 'Gränserna är inte kalibrerade, så kreditberäkningen kan bli fel. Högerklicka → Kalibrera från /usage.'
        mCredit = 'Extra krediter'; mCreditLimit = 'Ange kreditgräns (USD)…'; mCreditSpent = 'Ange använda krediter från claude.ai…'; mCreditDay = 'Dag krediterna nollställs…'
        askCreditLimit = 'Månadsgräns för extra krediter i USD (0 döljer avsnittet):'
        askCreditSpent = 'Krediter använda under perioden i USD, som claude.ai visar (Inställningar → Användning):'
        askCreditDay = 'Dag i månaden krediterna nollställs (1–28):'
    }
    da = @{
        title = 'Claude-forbrug'; session = '5-timers session: {0:0}%'; resets = ' · nulstilles om {0}t {1:00}m'
        usedLeft = '{0} brugt · {1} tilbage'; week = 'Seneste 7 dage: {0:0}%'; updated = 'Opdateret {0} · højreklik for indstillinger'
        usedOver = '{0} brugt · {1} over grænsen'; overHint = 'Over grænsen – du bruger ekstra kreditter, eller grænsen er højere end indstillet her. Kalibrér med /usage (højreklik).'
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
        cLabel = 'Ekstra kreditter: {0} af {1}'; cSub = '{0} tilbage · nulstilles {1}'; cSubLocal = '{0} brugt · {1} tilbage · nulstilles {2}'
        cOk = 'Inden for abonnementet – ingen kreditter bruges nu.'; cOkEta = 'Inden for abonnementet. I dette tempo nås 5-timersgrænsen om ~{0} (kl. {1}).'
        cUsing = 'Bruger kreditter nu: ~{0} i timen.'; cEmpty = ' I dette tempo er de brugt op om ~{0} (kl. {1}).'
        cResetFirst = ' Sessionen nulstilles før, om {0}.'; cOverIdle = 'Over grænsen – nye beskeder trækker kreditter.'
        cStopped = 'Kreditgrænsen er nået – Claude stopper, til {0} nulstilles.'
        cForecast = 'Prognose for perioden: {0}'; cSession = 'sessionen'; cWeek = 'ugegrænsen'
        cTooHigh = 'Claude svarer stadig, så overslaget er for højt. Angiv beløbet fra claude.ai (højreklik → Ekstra kreditter) og kalibrér grænserne fra /usage.'
        calHint = 'Grænserne er ikke kalibreret, så kreditoverslaget kan være forkert. Højreklik → Kalibrér fra /usage.'
        mCredit = 'Ekstra kreditter'; mCreditLimit = 'Angiv kreditgrænse (USD)…'; mCreditSpent = 'Angiv brugte kreditter fra claude.ai…'; mCreditDay = 'Dag kreditterne nulstilles…'
        askCreditLimit = 'Månedlig grænse for ekstra kreditter i USD (0 skjuler afsnittet):'
        askCreditSpent = 'Kreditter brugt i perioden i USD, som claude.ai viser (Indstillinger → Forbrug):'
        askCreditDay = 'Dag i måneden kreditterne nulstilles (1–28):'
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
# API list prices in USD per million tokens: input, output, cache read. Extra usage on a
# subscription is billed at these rates. Cache writes cost 1.25x input (5 min) or 2x input (1 hour).
$prices = @(
    @('fable|mythos', 10, 50, 0.25), @('opus-5-5', 4, 20, 0.20), @('opus', 5, 25, 0.50),
    @('sonnet-5', 2, 10, 0.20), @('sonnet', 3, 15, 0.30), @('haiku', 1, 5, 0.10)
)
function Get-Cost($model, $u) {
    $p = $prices[1]; foreach ($row in $prices) { if ($model -match $row[0]) { $p = $row; break } }
    $w1h = [double]$u.cache_creation.ephemeral_1h_input_tokens; $w5 = [double]$u.cache_creation_input_tokens - $w1h
    ([double]$u.input_tokens * $p[1] + [double]$u.output_tokens * $p[2] + [double]$u.cache_read_input_tokens * $p[3] + $w5 * $p[1] * 1.25 + $w1h * $p[1] * 2) / 1e6
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
                id = $o.message.id; n = $n; model = $model; project = $proj; cost = (Get-Cost $model $u)
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
    # Tokens used in the current window during the last hour, for the "limit reached in ..." forecast
    $hourTok = 0; if ($reset) { foreach ($i in $recent) { if ($i.t -ge $wStart -and $i.t -ge $now.AddHours(-1)) { $hourTok += $i.n } } }
    [pscustomobject]@{ session = $wTok; reset = $reset; week = $week; hourTok = $hourTok }
}

# --- Extra credits ----------------------------------------------------------
# Messages sent while the 5-hour window or the last 7 days are already over the limit are
# paid from extra credits. Their cost is estimated from the API prices above. If the user
# enters the amount claude.ai shows, that amount replaces the estimate up to that moment.
function Get-CreditPeriod {
    $now = Get-Date; $d = [math]::Max(1, [math]::Min(28, [int]$cfg.creditResetDay))
    $start = (Get-Date -Year $now.Year -Month $now.Month -Day $d).Date
    if ($start -gt $now) { $start = $start.AddMonths(-1) }
    @{ start = $start; end = $start.AddMonths(1) }
}
function Get-Credit($all) {
    $per = Get-CreditPeriod
    $startU = $per.start.ToUniversalTime(); $nowU = (Get-Date).ToUniversalTime()
    $baseAt = $null
    if ($cfg.creditBaseAt) { $baseAt = [datetime]::Parse($cfg.creditBaseAt, $inv, 'RoundtripKind').ToUniversalTime(); if ($baseAt -lt $startU) { $baseAt = $null } }
    $items = @($all | Where-Object { $_.t -ge $startU.AddDays(-7) })
    $wStart = $null; $wTok = 0; $weekTok = 0; $q = 0; $lastHour = 0.0
    $spent = if ($baseAt) { [double]$cfg.creditBase } else { 0.0 }
    # Claude stops once the credit limit is reached. Messages over the limit after the estimate
    # has passed it prove the estimate is too high (usually because the limits are not calibrated).
    $crossed = $spent -ge [double]$cfg.creditLimit; $afterCap = 0
    foreach ($i in $items) {
        if (-not $wStart -or $i.t -ge $wStart.AddHours(5)) { $wStart = $i.t; $wTok = 0 }
        while ($items[$q].t -lt $i.t.AddDays(-7)) { $weekTok -= $items[$q].n; $q++ }
        $extra = $wTok -ge $cfg.sessionLimit -or $weekTok -ge $cfg.weeklyLimit
        $wTok += $i.n; $weekTok += $i.n
        if (-not $extra -or $i.t -lt $startU) { continue }
        if ($i.t -ge $nowU.AddHours(-1)) { $lastHour += $i.cost }
        if ($baseAt -and $i.t -le $baseAt) { continue }
        if ($crossed) { $afterCap++ }
        $spent += $i.cost
        if ($spent -ge [double]$cfg.creditLimit) { $crossed = $true }
    }
    $elapsed = ((Get-Date) - $per.start).TotalDays; $length = ($per.end - $per.start).TotalDays
    $forecast = if ($elapsed -ge 1) { $spent * $length / $elapsed } else { $spent }
    [pscustomobject]@{ spent = $spent; perHour = $lastHour; forecast = $forecast; end = $per.end; estimated = -not $baseAt; tooHigh = $afterCap -ge 3 }
}

# Exchange rates from Norges Bank, fetched once a day. The download runs as a .NET task and
# Refresh (on the UI thread) picks up the result, so no PowerShell code runs on a worker thread.
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
$script:fxTask = $null; $script:http = $null
$localCurrency = @{ no = 'NOK'; sv = 'SEK'; da = 'DKK' }
function Update-Fx {
    $today = (Get-Date).ToString('yyyy-MM-dd', $inv)
    if ($script:fxTask -and $script:fxTask.IsCompleted) {
        try {
            $r = $script:fxTask.Result | ConvertFrom-Json; $st = $r.data.structure
            $dims = @($st.dimensions.series); $pos = [array]::IndexOf(@($dims | ForEach-Object { $_.id }), 'BASE_CUR')
            $curs = @($dims[$pos].values | ForEach-Object { $_.id })
            $multIdx = [array]::IndexOf(@($st.attributes.series | ForEach-Object { $_.id }), 'UNIT_MULT')
            $nok = @{ NOK = 1.0 }
            foreach ($p in $r.data.dataSets[0].series.psobject.Properties) {
                $obs = @($p.Value.observations.psobject.Properties | Sort-Object { [int]$_.Name })[-1].Value
                $mult = 0; if ($multIdx -ge 0 -and $null -ne $p.Value.attributes[$multIdx]) { $mult = [int]$st.attributes.series[$multIdx].values[$p.Value.attributes[$multIdx]].id }
                $nok[$curs[[int]($p.Name -split ':')[$pos]]] = [double]::Parse($obs[0], $inv) / [math]::Pow(10, $mult)
            }
            # Local currency per USD
            $cfg.fx = [pscustomobject]@{ NOK = $nok.USD; SEK = $nok.USD / $nok.SEK; DKK = $nok.USD / $nok.DKK }
            $cfg.fxDate = $today; Save-Config
        } catch {}
        $script:fxTask = $null
    }
    if (-not $script:fxTask -and $cfg.fxDate -ne $today -and $localCurrency[$cfg.language]) {
        if (-not $script:http) { $script:http = New-Object Net.Http.HttpClient; $script:http.Timeout = [TimeSpan]::FromSeconds(15) }
        $script:fxTask = $script:http.GetStringAsync('https://data.norges-bank.no/api/data/EXR/B.USD+SEK+DKK.NOK.SP?format=sdmx-json&lastNObservations=1')
    }
}
function Usd([double]$v) { '$' + $v.ToString('0.00', [Globalization.CultureInfo]::CurrentCulture) }
function Local([double]$v) {
    $c = $localCurrency[$cfg.language]; if (-not $c -or -not $cfg.fx -or -not $cfg.fx.$c) { return $null }
    '{0:N0} kr' -f ($v * $cfg.fx.$c)
}
function Duration([double]$minutes) {
    $m = [int][math]::Max(1, $minutes); $h = if ($cfg.language -in 'no', 'da') { 't' } else { 'h' }
    if ($m -ge 60) { '{0}{1} {2:00}m' -f [math]::Floor($m / 60), $h, ($m % 60) } else { "${m}m" }
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
  <Border Name="root" CornerRadius="10" Background="#E61E1E1E" Padding="16,12" Width="300">
    <StackPanel>
      <DockPanel Margin="0,0,0,6">
        <StackPanel Orientation="Horizontal" DockPanel.Dock="Right" VerticalAlignment="Center">
          <TextBlock Name="tabNow" FontSize="13" Cursor="Hand"/>
          <TextBlock Name="tabHist" FontSize="13" Cursor="Hand" Margin="8,0,0,0"/>
        </StackPanel>
        <TextBlock Name="title" Foreground="#D97757" FontWeight="SemiBold" FontSize="16"/>
      </DockPanel>
      <StackPanel Name="nowPanel">
        <TextBlock Name="sLabel" Foreground="#EEE" FontSize="14"/>
        <ProgressBar Name="sBar" Height="8" Maximum="100" Margin="0,3,0,2" Background="#333" BorderThickness="0" Foreground="#D97757"/>
        <TextBlock Name="sSub" Foreground="#999" FontSize="13" Margin="0,0,0,8" TextWrapping="Wrap"/>
        <TextBlock Name="wLabel" Foreground="#EEE" FontSize="14"/>
        <ProgressBar Name="wBar" Height="8" Maximum="100" Margin="0,3,0,2" Background="#333" BorderThickness="0" Foreground="#6A9BCC"/>
        <TextBlock Name="wSub" Foreground="#999" FontSize="13" TextWrapping="Wrap"/>
        <Border Name="cBox" Margin="0,10,0,0" Padding="0,8,0,0" BorderBrush="#3A3A3A" BorderThickness="0,1,0,0" Visibility="Collapsed">
          <StackPanel>
            <TextBlock Name="cLabel" Foreground="#EEE" FontSize="14"/>
            <!-- Solid part: used so far. Faint part: forecast for the whole period. -->
            <Grid Name="cTrack" Width="268" Height="9" Margin="0,3,0,2" Background="#333" HorizontalAlignment="Left">
              <Rectangle Name="cFore" HorizontalAlignment="Left" RadiusX="2" RadiusY="2"/>
              <Rectangle Name="cUsed" HorizontalAlignment="Left" RadiusX="2" RadiusY="2"/>
            </Grid>
            <TextBlock Name="cSub" Foreground="#999" FontSize="13" TextWrapping="Wrap"/>
            <TextBlock Name="cFc" Foreground="#999" FontSize="13" TextWrapping="Wrap"/>
            <TextBlock Name="cStatus" FontSize="13" TextWrapping="Wrap" Margin="0,4,0,0"/>
          </StackPanel>
        </Border>
        <TextBlock Name="overHint" Foreground="#E0B050" FontSize="13" TextWrapping="Wrap" Margin="0,8,0,0" Visibility="Collapsed"/>
      </StackPanel>
      <StackPanel Name="histPanel" Visibility="Collapsed">
        <DockPanel>
          <StackPanel Name="rangePanel" Orientation="Horizontal" DockPanel.Dock="Right"/>
          <TextBlock Name="hDaily" Foreground="#EEE" FontSize="14"/>
        </DockPanel>
        <Canvas Name="cDaily" Margin="0,4,0,0" ClipToBounds="False"/>
        <TextBlock Name="hTotal" Foreground="#999" FontSize="13" Margin="0,2,0,8"/>
        <TextBlock Name="hToday" Foreground="#EEE" FontSize="14"/>
        <Canvas Name="cToday" Margin="0,4,0,0"/>
        <TextBlock Name="hTodayTotal" Foreground="#999" FontSize="13" Margin="0,2,0,8"/>
        <TextBlock Name="hModels" Foreground="#EEE" FontSize="14"/>
        <StackPanel Name="pModels" Margin="0,2,0,8"/>
        <TextBlock Name="hProjects" Foreground="#EEE" FontSize="14"/>
        <StackPanel Name="pProjects" Margin="0,2,0,4"/>
        <TextBlock Name="hSince" Foreground="#666" FontSize="12"/>
      </StackPanel>
      <TextBlock Name="upd" Foreground="#666" FontSize="12" Margin="0,6,0,0"/>
    </StackPanel>
  </Border>
</Window>
'@
$win = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
$el = @{}
'root','title','tabNow','tabHist','nowPanel','histPanel','sLabel','sBar','sSub','wLabel','wBar','wSub','overHint','upd','cBox','cLabel','cTrack','cFore','cUsed','cSub','cFc','cStatus',
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
    $tb.Text = $text; $tb.FontSize = 11; $tb.Foreground = Brush '#777'
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
    $name.Text = $label; $name.Width = 135; $name.FontSize = 13; $name.Foreground = Brush '#CCC'; $name.TextTrimming = 'CharacterEllipsis'; $name.ToolTip = $label
    $val = New-Object Windows.Controls.TextBlock
    $val.Text = '{0} ({1:0}%)' -f (Fmt $value), ($share * 100); $val.Width = 98; $val.FontSize = 13; $val.Foreground = Brush '#999'; $val.TextAlignment = 'Right'
    [Windows.Controls.DockPanel]::SetDock($name, 'Left'); [Windows.Controls.DockPanel]::SetDock($val, 'Right')
    $bar = New-Object Windows.Shapes.Rectangle
    $bar.Height = 6; $bar.RadiusX = 2; $bar.RadiusY = 2; $bar.Fill = Brush $color
    $bar.Width = [math]::Max(2, ($width - 245) * $share); $bar.HorizontalAlignment = 'Left'; $bar.VerticalAlignment = 'Center'
    [void]$row.Children.Add($name); [void]$row.Children.Add($val); [void]$row.Children.Add($bar)
    [void]$panel.Children.Add($row)
}

$histWidth = 390; $chartW = $histWidth - 32
$rangeButtons = foreach ($days in 7, 30, 90) {
    $b = New-Object Windows.Controls.TextBlock
    $b.Text = "${days}d"; $b.Tag = $days; $b.FontSize = 13; $b.Cursor = 'Hand'; $b.Margin = New-Object Windows.Thickness 6, 0, 0, 0
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
    $c = $el.cDaily; $c.Children.Clear(); $c.Width = $chartW; $dayH = 64; $padTop = 16; $c.Height = $padTop + $dayH + 17
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
    $c = $el.cToday; $c.Children.Clear(); $c.Width = $chartW; $H2 = 38; $padTop = 16; $c.Height = $padTop + $H2 + 16
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
    $el.root.Width = $(if ($hist) { $histWidth } else { 300 })
    $el.tabNow.Foreground = Brush $(if ($hist) { '#777' } else { '#EEE' })
    $el.tabHist.Foreground = Brush $(if ($hist) { '#EEE' } else { '#777' })
    if ($hist) { Draw-History }
    if ($cfg.tab -ne $tab) { $cfg.tab = $tab; Save-Config }
}
$el.tabNow.Add_MouseLeftButtonDown({ param($s, $e) Show-Tab 'now'; $e.Handled = $true })
$el.tabHist.Add_MouseLeftButtonDown({ param($s, $e) Show-Tab 'history'; $e.Handled = $true })

function Get-UsedText($used, $limit) {
    if ($used -le $limit) { (T 'usedLeft') -f (Fmt $used), (Fmt ($limit - $used)) } else { (T 'usedOver') -f (Fmt $used), (Fmt ($used - $limit)) }
}
function Set-Meter($label, $bar, $sub, $text, $pct, $color) {
    $over = $pct -gt 100
    $label.Text = $text
    $bar.Value = [math]::Min(100, $pct)
    $bar.Foreground = Brush $(if ($over) { '#E5484D' } else { $color })
    $label.Foreground = Brush $(if ($over) { '#E5484D' } else { '#EEE' })
    $sub.Foreground = Brush $(if ($over) { '#EE8A8D' } else { '#999' })
}
function Draw-Credit($c, $u) {
    $limit = [double]$cfg.creditLimit; $spent = $c.spent; $left = [math]::Max(0.0, $limit - $spent); $frac = $spent / $limit
    $color = if ($c.tooHigh) { '#E0B050' } elseif ($frac -ge 1) { '#E5484D' } elseif ($frac -ge 0.75) { '#E0B050' } else { '#8FB573' }
    $el.cBox.Visibility = 'Visible'; $el.cSub.Visibility = 'Visible'
    # "≈" until the amount from claude.ai has been entered
    $el.cLabel.Text = (T 'cLabel') -f $(if ($c.estimated) { '≈ ' + (Usd $spent) } else { Usd $spent }), (Usd $limit)
    $el.cLabel.Foreground = Brush $(if ($frac -ge 1 -and -not $c.tooHigh) { '#E5484D' } else { '#EEE' })
    $w = $el.cTrack.Width
    $el.cUsed.Width = $w * [math]::Min(1, $frac); $el.cUsed.Fill = Brush $color
    $over = $c.forecast -gt $limit
    $el.cFore.Width = $w * [math]::Min(1, $c.forecast / $limit); $el.cFore.Fill = Brush $(if ($over) { '#E5484D' } else { $color }); $el.cFore.Opacity = 0.35
    $resetDate = $c.end.ToString('d. MMM')
    $leftTxt = Usd $left; $l = Local $left; if ($l) { $leftTxt += " (≈ $l)" }
    $el.cSub.Text = if (Local $spent) { (T 'cSubLocal') -f ('≈ ' + (Local $spent)), $leftTxt, $resetDate } else { (T 'cSub') -f $leftTxt, $resetDate }
    $fc = Usd $c.forecast; $l = Local $c.forecast; if ($l) { $fc += " (≈ $l)" }
    $el.cFc.Text = (T 'cForecast') -f $fc
    $el.cFc.Foreground = Brush $(if ($over) { '#EE8A8D' } else { '#999' })
    $el.cFc.Visibility = $(if ($spent -gt 0) { 'Visible' } else { 'Collapsed' })

    # What happens next, in plain words
    $nowL = Get-Date
    $sessOver = $u.session -ge $cfg.sessionLimit; $weekOver = $u.week -ge $cfg.weeklyLimit
    $toReset = if ($u.reset) { ($u.reset - $nowL.ToUniversalTime()).TotalMinutes } else { 0 }
    if ($c.tooHigh) {
        $status = T 'cTooHigh'; $sc = '#E0B050'; $el.cFc.Visibility = 'Collapsed'; $el.cSub.Visibility = 'Collapsed'
    } elseif ($left -le 0 -and ($sessOver -or $weekOver)) {
        $status = (T 'cStopped') -f $(if ($weekOver) { T 'cWeek' } else { T 'cSession' }); $sc = '#E5484D'
    } elseif ($sessOver -or $weekOver) {
        $sc = '#E0B050'
        if ($c.perHour -gt 0) {
            $toEmpty = 60 * $left / $c.perHour
            $status = (T 'cUsing') -f (Usd $c.perHour)
            if (-not $weekOver -and $u.reset -and $toReset -lt $toEmpty) { $status += (T 'cResetFirst') -f (Duration $toReset) }
            else { $status += (T 'cEmpty') -f (Duration $toEmpty), $nowL.AddMinutes($toEmpty).ToString('HH:mm') }
        } else { $status = T 'cOverIdle' }
    } else {
        $sc = '#8FB573'; $status = T 'cOk'
        if ($u.reset -and $u.hourTok -gt 0) {
            $toLimit = 60 * ($cfg.sessionLimit - $u.session) / $u.hourTok
            if ($toLimit -lt $toReset) { $status = (T 'cOkEta') -f (Duration $toLimit), $nowL.AddMinutes($toLimit).ToString('HH:mm') }
        }
    }
    $el.cStatus.Text = $status; $el.cStatus.Foreground = Brush $sc
}
function Refresh {
    Update-Fx
    $all = Update-Data
    Update-History $all
    $u = Get-Usage $all; $script:last = $u
    # Percentages are not capped: above 100 % you are either on extra credits, or the real limit is higher
    # than the one set here. The bar is then full and red, and "x over the limit" is shown instead of "0 left".
    $sp = 100 * $u.session / [double]$cfg.sessionLimit
    $wp = 100 * $u.week / [double]$cfg.weeklyLimit
    $el.title.Text = T 'title'
    $el.tabNow.Text = T 'tabNow'; $el.tabHist.Text = T 'tabHist'
    $resetTxt = if ($u.reset) { $m = [int]($u.reset - (Get-Date).ToUniversalTime()).TotalMinutes; (T 'resets') -f [math]::Floor($m/60), ($m % 60) } else { '' }
    $el.sSub.Text = (Get-UsedText $u.session $cfg.sessionLimit) + $resetTxt
    $el.wSub.Text = Get-UsedText $u.week $cfg.weeklyLimit
    Set-Meter $el.sLabel $el.sBar $el.sSub ((T 'session') -f $sp) $sp '#D97757'
    Set-Meter $el.wLabel $el.wBar $el.wSub ((T 'week') -f $wp) $wp '#6A9BCC'
    $uncalibrated = [int64]$cfg.sessionLimit -eq 1000000 -and [int64]$cfg.weeklyLimit -eq 15000000
    if ([double]$cfg.creditLimit -gt 0) {
        Draw-Credit (Get-Credit $all) $u
        $el.overHint.Text = T 'calHint'; $show = $uncalibrated
    } else {
        $el.cBox.Visibility = 'Collapsed'
        $el.overHint.Text = T 'overHint'; $show = $sp -gt 100 -or $wp -gt 100
    }
    $el.overHint.Visibility = $(if ($show) { 'Visible' } else { 'Collapsed' })
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
$creditMenu = AddItem 'mCredit' {}
AddItem 'mCreditLimit' {
    $v = Ask (T 'askCreditLimit') $cfg.creditLimit
    if ($null -ne ($v -replace ',', '.' -as [double])) { $cfg.creditLimit = [double]::Parse(($v -replace ',', '.'), $inv); Save-Config; Refresh }
} $creditMenu | Out-Null
AddItem 'mCreditSpent' {
    $v = Ask (T 'askCreditSpent') ''
    if ($v -and $null -ne ($v -replace ',', '.' -as [double])) {
        $cfg.creditBase = [double]::Parse(($v -replace ',', '.'), $inv); $cfg.creditBaseAt = (Get-Date).ToUniversalTime().ToString('o'); Save-Config; Refresh
    }
} $creditMenu | Out-Null
AddItem 'mCreditDay' {
    $v = Ask (T 'askCreditDay') $cfg.creditResetDay
    if ($v -as [int] -and [int]$v -ge 1 -and [int]$v -le 28) { $cfg.creditResetDay = [int]$v; Save-Config; Refresh }
} $creditMenu | Out-Null
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
