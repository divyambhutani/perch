# Perch Hook Notes

Perch installs a local shell hook at `~/.claude/hooks/perch-hook.sh` and updates `~/.claude/settings.json`
to forward Claude Code hook payloads to the app's local HTTP listener at `http://127.0.0.1:45321/hooks`.
