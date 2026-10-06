@echo off
echo Installing Claude Usage widget...
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/saysphilippe/ClaudeUsage/main/install.ps1 | iex"
pause
