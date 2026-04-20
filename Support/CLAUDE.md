# Perch Hook Integration

Perch forwards Claude Code hook events to a local HTTP listener inside the Perch
app so the menu-bar familiar can react to permission prompts, tool calls, and
session lifecycle.

## What Perch installs

- `~/.claude/hooks/perch-hook.sh` — a small zsh shim. Reads the hook JSON payload
  from stdin and POSTs it to Perch's local server. Contents are idempotent; safe
  to re-install.
- Entries in `~/.claude/settings.json` under the `hooks` block for:
  `Notification`, `SessionStart`, `SessionEnd`, `PreToolUse`, `PostToolUse`.
  Each installed entry carries `"_perch": true` so uninstall removes only the
  entries Perch owns and leaves user-authored hooks intact.

## Endpoint

Default listener: `http://127.0.0.1:45321/hooks`. Port falls back up to +20 if
occupied; the installer always writes the actually-bound port, not the default.

## Uninstall

From Perch → Settings → Hooks → **Uninstall hooks**. This strips Perch-owned
entries from `~/.claude/settings.json` and removes the shim script. Your own
hook entries are untouched.

## Privacy

Payloads never leave the machine — the listener binds to loopback only. Perch
does not ship analytics SDKs.
