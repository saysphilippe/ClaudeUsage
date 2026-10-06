@echo off
echo Installing Claude Usage widget...
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/__USER__/ClaudeUsage/main/install.ps1 | iex"
pause
