# Claude Usage widget

A small always-on-top Windows desktop widget that shows how much of your Claude Code usage you have spent:

- **5-hour session** – tokens used in the current 5-hour window, how much is left, and when it resets
- **Last 7 days** – tokens used over the past week

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
- **Options:** right-click it.

| Menu item | What it does |
|---|---|
| Refresh now | Re-reads the logs (this also happens automatically every minute) |
| Calibrate 5-hour / weekly limit from /usage % | Run `/usage` in Claude Code and type the percentage it shows. The widget then works out your real limit, so its percentages match Claude's. |
| Set 5-hour / weekly limit manually | Enter a token limit directly |
| Always on top | Keeps the widget above other windows |
| Language | Switches between English, Norsk, Svenska and Dansk immediately |
| Close | Closes the widget until next login or until you start it from the Desktop shortcut |

Settings are saved in `%LOCALAPPDATA%\ClaudeUsage\config.json`.

> The percentages are estimates based on your local logs. Calibrate them against `/usage` for the best accuracy.

## Uninstall

Double-click [`Uninstall.cmd`](Uninstall.cmd), or run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\ClaudeUsage\uninstall.ps1"
```

This stops the widget and removes its files, shortcuts and settings.

---

## Norsk

Claude Usage er en liten widget for Windows-skrivebordet som viser hvor mye av Claude Code-kvoten din du har brukt: den nåværende 5-timers økten og de siste 7 dagene. Den leser bare de lokale loggfilene til Claude Code og sender ingenting noe sted. Widgeten logger aldri inn på Claude og inneholder ingen påloggingsdata, så den viser alltid forbruket til den som er logget inn i Claude Code på din egen PC – aldri utviklerens eller andres.

**Installering:** Kjør `irm https://raw.githubusercontent.com/saysphilippe/ClaudeUsage/main/install.ps1 | iex` i PowerShell, eller last ned og dobbeltklikk `Install.cmd`. Du kan også laste ned repoet og kjøre `powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1` i mappen. Velg **2) Norsk** når installasjonsprogrammet spør om språk (eller **3) Svenska** / **4) Dansk**).

**Bruk:** Dra widgeten for å flytte den, og høyreklikk den for å se valgene. Velg «Kalibrer … fra /usage-%» og skriv inn prosenten som `/usage` viser i Claude Code, så stemmer tallene med Claude sine. Under «Språk» kan du bytte mellom norsk, svensk, dansk og engelsk.

**Avinstallering:** Dobbeltklikk `Uninstall.cmd`.
