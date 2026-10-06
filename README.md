# Claude Usage widget

A small always-on-top Windows desktop widget that shows how much of your Claude Code usage you have spent:

- **5-hour session** – tokens used in the current 5-hour window, how much is left, and when it resets
- **Last 7 days** – tokens used over the past week
- **History tab** – charts of tokens per day (7, 30 or 90 days) and today by hour, plus your most-used models and projects

It reads the local Claude Code logs in `%USERPROFILE%\.claude\projects`. Nothing is sent anywhere, and no API key or login is needed.

**Your own account only:** the widget never signs in to Claude and contains no credentials. It only reads the logs Claude Code writes on *your* PC, so it always shows the usage of whoever is signed in to Claude Code on that Windows user account – never the author's or anyone else's.

The widget can show its text in **English**, **Norwegian (Norsk)**, **Swedish (Svenska)** or **Danish (Dansk)**. You choose the language during installation and can change it later from the right-click menu.

## Requirements

- Windows 10 or 11 (uses the built-in Windows PowerShell 5.1 – nothing extra to install)
- Claude Code, used on the same PC

## Install

### Option 1 – one-line install

Open PowerShell and run:

```powershell
irm https://raw.githubusercontent.com/saysphilippe/ClaudeUsage/main/install.ps1 | iex
```

Or download [`Install.cmd`](Install.cmd) and double-click it.

### Option 2 – install from a downloaded copy

1. Download the repository (**Code → Download ZIP**, then extract it) or clone it:
   ```powershell
   git clone https://github.com/saysphilippe/ClaudeUsage.git
   ```
2. In that folder, run:
   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
   ```

### What the installer does

1. Asks which language the widget should use:
   ```
   Choose display language / Velg språk / Välj språk / Vælg sprog:
     1) English
     2) Norsk
     3) Svenska
     4) Dansk
   ```
   To skip the question (for example in a script), set the language first: `$env:CLAUDEUSAGE_LANG = 'no'` (or `'en'`, `'sv'`, `'da'`).
2. Copies the widget to `%LOCALAPPDATA%\ClaudeUsage`.
3. Adds a **Claude Usage** shortcut to your Desktop and Startup folder, so the widget starts when you log in.
4. Starts the widget.

Running the installer again updates the widget and keeps your settings (limits, position, language).

## Using the widget

- **Move it:** drag it with the left mouse button.
- **Switch view:** click **Now** or **History** in the top-right corner.
- **Options:** right-click it.

### History tab

- **Tokens per day:** choose **7d**, **30d** or **90d**. Hover over a bar to see the date and exact amount. Today's bar is lighter.
- **Today by hour:** shows when you used Claude today. The current hour is lighter.
- **Models** and **Top projects:** the share of tokens per model (for example Opus 5.5 and Sonnet 5.5) and per project folder over the selected period. Sessions started outside a project – in the Windows folder (for example `C:\Windows\System32`, where an administrator terminal opens), your home folder or the root of a drive – are grouped as **No project**. To get them counted per project, start Claude Code from the project folder.

Claude Code deletes its own logs after 30 days by default. The widget therefore keeps a daily summary in `%LOCALAPPDATA%\ClaudeUsage\history.json`, so the history keeps growing beyond that. It only covers the time since you installed the widget, plus whatever logs Claude Code still had at that point.

| Menu item | What it does |
|---|---|
| Refresh now | Re-reads the logs (this also happens automatically every minute) |
| Calibrate 5-hour / weekly limit from /usage % | Run `/usage` in Claude Code and type the percentage it shows. The widget then works out your real limit, so its percentages match Claude's. |
| Set 5-hour / weekly limit manually | Enter a token limit directly |
| Always on top | Keeps the widget above other windows |
| Language | Switches between English, Norsk, Svenska and Dansk immediately |
| Close | Closes the widget until next login or until you start it from the Desktop shortcut |

Settings are saved in `%LOCALAPPDATA%\ClaudeUsage\config.json`. Reinstalling keeps both your settings and your history.

> The percentages are estimates based on your local logs. Calibrate them against `/usage` for the best accuracy.

**Over 100 %:** the percentage is not capped. Above the limit the bar turns red, the line shows how much you are *over* (for example "1.1M used · 98K over the limit") and a note explains why: you are using extra credits, or the real limit is higher than the one set in the widget. If `/usage` in Claude Code shows less than the widget, calibrate (right-click → Calibrate …) so the widget matches.

## Uninstall

Double-click [`Uninstall.cmd`](Uninstall.cmd), or run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\ClaudeUsage\uninstall.ps1"
```

This stops the widget and removes its files, shortcuts, settings and saved history.
