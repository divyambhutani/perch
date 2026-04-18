# AGENTS.md — Perch

> Canonical project spec for AI coding agents working on Perch. Read this before writing code. Reference sections by number in PR descriptions. If you deviate from anything here, say so explicitly and why.

## Quick Facts

|                  |                                                |
| ---------------- | ---------------------------------------------- |
| Product          | **Perch**                                      |
| Platform         | macOS 14+                                      |
| Language         | Swift 6 (strict concurrency)                   |
| Primary UI       | SwiftUI + AppKit (NSPanel for notch)           |
| IPC              | Local HTTP server via `NWListener`             |
| Persistence      | GRDB (SQLite) cache over JSONL source of truth |
| Default familiar | **Seneca** the Stoic Owl                       |
| License          | Apache 2.0                                     |
| Distribution     | Signed + notarized DMG, Sparkle 2 auto-update  |

---

## 1. What Perch Is

Perch is a macOS companion app for Claude Code (and, later, other agentic CLI tools). It lives in the notch / menu-bar region and surfaces the state of one or more active sessions — permissions pending, tokens burning, session about to expire — without requiring a visible terminal tab.

Design intent: **recede into the background, surface only when human attention is genuinely required.** The app is not a chat viewer, not a dashboard, not a replacement for the terminal. It's a peripheral-vision indicator with a small overlay for approvals.

The thing the user sees is a single animated **familiar** — a mascot — that sits in the notch. The familiar has four states (`idle` / `watching` / `alert` / `working`) and communicates by animating between them. Clicking it opens the overlay: permission prompts, session list, quick actions.

---

## 2. Identity

### Product name: Perch

Named for the behavior, not the mascot — the product supports multiple familiars, so the name must be mascot-agnostic. "My Perch caught a permission" reads naturally regardless of which creature the user has selected.

### v1 familiar: Seneca the Stoic Owl

Grey plumage, yellow eyes, small gold beak and feet. Named for Seneca the Younger — the Roman Stoic whose surviving letters read like the original handbook for working under pressure.

**Personality**: archivist. Has been watching scribes make errors for two thousand years. Not going to perform delight at a successful `npm install`. The eyes are the only feature that moves; the rest of the sprite is stone-still. When Seneca raises a wing, it's a librarian holding up a catalogue card — polite, inevitable, slightly disappointed if ignored.

**Voice register for Seneca**:

- Short declarative sentences.
- No exclamation marks. No emoji. No "Hey!" openings.
- Verbs over adjectives.
- Assume the user is intelligent and knows what they asked for.
- Example: `"Permission required."` — not `"Hey! Claude needs your approval!"`

### Post-v1 familiars (planned)

Not implemented in v1, but the architecture must support them from day one.

| Familiar | Animal       | Vibe                  | Target user                                                     |
| -------- | ------------ | --------------------- | --------------------------------------------------------------- |
| Biscuit  | Corgi        | Enthusiastic intern   | Default-taste developer, wants warmth                           |
| Mochi    | Cat          | Aloof judge           | Developer who wants the tool to silently disapprove             |
| Inky     | Octopus      | Multi-session juggler | Heavy parallel-session user                                     |
| Pulse    | Abstract orb | No character          | Developer who finds mascots annoying but wants state visibility |

Each familiar implements the same four states and the same hook contract. Swapping familiars must not change any behavior except the sprite asset and the tone of UI copy.

### Theme model

Themes are **accent-only**. Each familiar sprite has two pixel categories: _body_ (invariant across themes) and _accent_ (themed). For Seneca: body is the grey plumage; accents are the eyes, beak, and feet.

Accent swap happens at render time via a color LUT — never bake theme variants into separate sprite sheets.

Six presets ship in v1:

| Theme          | Accent              | Use case                        |
| -------------- | ------------------- | ------------------------------- |
| `default`      | Yellow-gold         | Canonical Seneca look           |
| `midnight`     | Navy + cyan         | Dark environments, night coding |
| `teal`         | Teal                | Cool alternative                |
| `plum`         | Plum purple         | Warm alternative                |
| `pewter`       | Desaturated grey    | Minimal                         |
| `highContrast` | Pure yellow + black | Accessibility                   |

User-imported JSON themes ship in v1.1.

---

## 3. Architecture

```
┌──────────────────────┐        ┌─────────────────────────┐
│  Claude Code session │        │  ~/.claude/projects/    │
│  (one or many)       │        │  **/*.jsonl             │
└──────────┬───────────┘        └──────────┬──────────────┘
           │ hook events (HTTP POST)        │ append-only
           ▼                                ▼
┌─────────────────────────────────────────────────────────┐
│  Perch.app                                              │
│  ┌───────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ HookServer    │  │ JSONLParser  │  │ SessionStore │  │
│  │ (NWListener)  │→ │ + GRDB cache │→ │ (@Observable)│  │
│  └───────────────┘  └──────────────┘  └──────┬───────┘  │
│                                              │          │
│  ┌───────────────────────────────────────────▼───────┐  │
│  │  UI layer                                         │  │
│  │  ┌──────────┐  ┌───────────┐  ┌────────────────┐  │  │
│  │  │ MenuBar  │  │ NotchPanel│  │ Overlay(NSPanel│  │  │
│  │  │ Extra    │  │ (sprite)  │  │ + SwiftUI)     │  │  │
│  │  └──────────┘  └───────────┘  └────────────────┘  │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

Claude Code writes hook events as HTTP POSTs to Perch's local listener. Perch also watches the JSONL session logs directly (for features that need richer context than hooks provide, like token-burn trend). The two data paths converge in `SessionStore`, which is the single source of truth the UI consumes.

---

## 4. Tech Stack

### Required

- **Swift 6** with strict concurrency (`-strict-concurrency=complete`).
- **SwiftUI** as primary UI framework.
- **AppKit** for NSPanel-based notch overlay (SwiftUI windowing is not yet ready for this).
- **macOS 14+** deployment target (~40% broader install base than macOS 15).
- **GRDB** (SQLite wrapper) for JSONL cache.
- **Sparkle 2** for auto-update.
- **swift-testing** for all unit / integration tests.

### Apple frameworks in use

- `Network` (NWListener) — local HTTP server.
- `ServiceManagement` (`SMAppService`) — launch-at-login. **Not** the deprecated `SMLoginItemSetEnabled`.
- `AppKit.NSPanel` — notch overlay window.
- `CoreAnimation` — sprite animation.

### Explicitly rejected

- **Electron / Tauri** for the main app — weight, launch time, non-native feel.
- **Core Data / SwiftData** — GRDB is simpler, and JSONL rewrites make schema migrations in SwiftData expensive.
- **Analytics SDKs** (Mixpanel, Amplitude, etc.) — developers turn these off immediately. Not worth the trust cost.
- **RxSwift / Combine as primary state paradigm** — `@Observable` covers the surface.
- **Rust FFI core** — overkill. Swift 6 actors + GRDB handle the concurrency and storage needs.

---

## 5. Project Structure

```
Perch.xcodeproj
Perch/
├── App/
│   ├── PerchApp.swift              # @main entry
│   └── AppDelegate.swift           # lifecycle
├── Core/
│   ├── HookServer/                 # NWListener, HookEvent, dispatch
│   ├── Session/                    # SessionStore, Session, events
│   ├── Data/                       # JSONLParser, Database (GRDB)
│   ├── Installer/                  # HookInstaller (~/.claude/hooks)
│   ├── Familiars/                  # Familiar protocol, MascotID
│   │   └── Seneca/                 # Seneca metadata + copy tone
│   └── Theming/                    # PerchTheme, accent LUT, presets
├── Features/
│   ├── MenuBar/                    # MenuBarExtra + mascot icon
│   ├── Notch/                      # NSPanel overlay host
│   ├── Permissions/                # Permission prompt + diff preview
│   ├── SessionList/                # Multi-session view (⌃⌘C)
│   └── Settings/                   # Settings, familiar picker, theme picker
└── Resources/
    ├── Assets.xcassets/
    └── Mascots/
        └── Seneca/
            ├── idle.png
            ├── watching.png
            ├── alert.png
            └── working.png
Tests/
├── CoreTests/
└── FeaturesTests/
Support/
├── CLAUDE.md                       # hook install template shipped into ~/.claude
└── scripts/                        # build, sign, notarize, release
```

---

## 6. Key Technical Decisions

### 6.1 HTTP over Unix socket, not raw Unix socket

Why: easier to debug with `curl`, matches Claude Code's HTTP hook transport directly, and makes a future Windows port nearly free — the hook contract stays identical across platforms.

### 6.2 JSONL is the source of truth; GRDB is the index

Rebuilding the GRDB cache from JSONL must always be a valid recovery path. If the user deletes `~/Library/Application Support/Perch/cache.sqlite`, nothing important is lost. Never write data to GRDB that doesn't have a JSONL origin.

### 6.3 NSPanel for notch overlay, not SwiftUI floating window

SwiftUI's windowing APIs don't yet support panel-style non-activating floating windows reliably. The right compromise is `NSPanel` hosting an `NSHostingView` of a SwiftUI body. Panel behaviors come from AppKit; content from SwiftUI.

### 6.4 Pluggable familiar from day one

Even though v1 ships only Seneca, the `Familiar` protocol, `MascotID` enum, and sprite-loading pipeline must all exist and route through the full theme engine. Adding a familiar post-v1 must be:

1. Drop sprites into `Resources/Mascots/<name>/{idle,watching,alert,working}.png`.
2. Add a case to `MascotID`.
3. Register a `CopyTone` and `Familiar` instance.

**No code in `Features/` should know which familiar is active.** Any `if mascot == .seneca` in a feature view is a red flag.

### 6.5 Accent-only theming via runtime LUT

Each sprite has two palette categories: body (invariant) and accent (themed). Accent swap is a runtime color lookup, not separate sprite sheets per theme. One sprite × N themes = N rendered outputs from a single asset.

Consequence: sprites must be authored with a strict two-palette discipline. Any pixel that's not in the body palette or the accent palette is a bug.

### 6.6 Tone metadata per familiar

Each familiar ships with a `CopyTone` struct. The UI layer consults it when rendering any user-facing string:

```swift
PerchStrings.permissionRequired(tone: currentFamiliar.tone)
// Seneca → "Permission required."
// Biscuit (future) → "Quick check needed!"
```

Hardcoded strings in views are prohibited. All copy flows through `PerchStrings`.

---

## 7. Features Roadmap

### v1 (ship target)

- Menu-bar icon + notch overlay with Seneca sprite
- Hook installer (writes to `~/.claude/hooks/`)
- Permission approvals with diff preview
- Multi-session list (⌃⌘C hotkey) — clicking a row raises the terminal window hosting that session (Terminal.app / iTerm2 via AppleScript; other emulators via `NSRunningApplication` activation or a new-window-at-cwd fallback)
- Context-window % indicator
- 5-hour session countdown
- 4 states, 2-frame animations per state
- 6 preset themes (accent-only, runtime swap)
- Launch-at-login via `SMAppService`
- Sparkle 2 auto-update
- Signed + notarized DMG

### v1.1

- **Second familiar: Biscuit the Corgi**
- Burn-rate prediction (tokens/hour forecast from JSONL history)
- Weekly quota gauge
- Blast-radius warnings (`rm -rf`, `.env` edits, etc.)
- Slash-command palette (⌘K)
- Prompt snippets (⌥1–9)
- User-imported JSON themes

### v1.2

- Mochi the Cat, Inky the Octopus, Pulse the Orb
- Familiar picker UI with live preview

### v2

- Codex CLI support (hook contract is already compatible via HTTP)
- Focus mode
- Slack / Discord webhook notifications
- iOS companion
- Windows port via Tauri, sharing the same HTTP hook contract

### Non-goals (explicit)

- Full chat viewer
- Team dashboards
- Model routing / LLM selection UI
- Anything that requires a login or server-side account

---

## 8. Design System

| Token        | Value                                                                     |
| ------------ | ------------------------------------------------------------------------- |
| Typography   | SF Pro (system). Body 13pt, captions 11pt, headers 15pt semibold.         |
| Spacing unit | 4pt. All padding/margins in multiples of 4.                               |
| Radius       | 8pt panels, 4pt inline, 0pt sprite cells.                                 |
| Motion       | 180ms ease-out for state transitions. Sprite frames at 500ms. No springs. |
| Dark mode    | First-class. All accents pass WCAG AA on both appearances.                |

---

## 9. Coding Conventions

**Concurrency**: Swift 6 strict. Actors for all shared mutable state. `@MainActor` on UI types. **No `DispatchQueue.main.async` in new code.**

**State**: `@Observable` (not `ObservableObject`). Environment injection over singletons. Every view gets a mock environment for previews.

**Naming**: Types in PascalCase. Protocols describe a role (`Familiar`, not `FamiliarProtocol`). Enum cases in lowerCamelCase.

**SwiftUI**: small views. If a `body` exceeds 40 lines, extract a subview. Use `@ViewBuilder` for branching, not long if-else chains inside `body`.

**Errors**: typed errors per module (`PerchError.hookInstallFailed(reason)`). Don't use `Error.localizedDescription` as primary control flow.

**Comments**: explain _why_, never _what_. If the code needs a comment to explain what it does, the code is wrong.

**Tests**: every module ships with tests. UI features get at least one integration test that boots the NSPanel and asserts the render.

---

## 10. Build & Release

- **CI**: GitHub Actions on macOS 14 runner. Build + test every PR. Notarize + sign on tagged releases.
- **Signing**: Developer ID Application cert + hardened runtime.
- **Notarization**: `xcrun notarytool` in CI, stapled to DMG before publishing.
- **Distribution**: Sparkle 2 appcast on GitHub Pages; DMG on GitHub Releases.
- **Versioning**: SemVer. Tag releases as `v1.0.0`.

---

## 11. Rules for AI Coding Agents

### Always

- Use Swift 6 strict concurrency patterns (actors, Sendable, `@MainActor`).
- Route every user-facing string through `PerchStrings.<key>(tone: familiar.tone)`. Never hardcode copy in a view.
- Preserve the `Familiar` protocol's mascot-agnostic surface. Any new feature must work with all planned familiars, not just Seneca.
- Write a swift-testing test in the same PR as the implementation.
- Reference AGENTS.md section numbers in PR descriptions.
- **All code must be optimized, modular, and aesthetical.** Thorough review and e2e testing will be done by Antigravity (Gemini 3.1 Pro) and Codex (GPT 5.4). A tech lead and expert reviewer are always in the loop — they will criticize any deviation from the conventions in this document.

### Never

- Use `DispatchQueue.main.async` in new code. Use `@MainActor` instead.
- Import RxSwift, Combine as a primary state solution, or any analytics SDK.
- Add a dependency without flagging it in Section 13 and in the PR description.
- Bake theme colors into sprite assets. All theming is runtime accent-swap.
- Use `NotificationCenter` for cross-module communication. Use protocol-based dependency injection.
- Write UI copy in Biscuit's (future) cheerful register when the active familiar is Seneca. Copy tone follows the familiar.
- Branch on `mascot == .seneca` in feature code. Feature code must be familiar-blind.

### When in doubt

- Consult Section 6 (Technical Decisions). If the ambiguity isn't resolved there, add it to Section 13 in the same PR rather than guessing.
- If you deviated from this document, say so explicitly in the PR description and justify it.

---

## 12. PR Discipline

Every PR description must include:

- Summary (1–3 sentences).
- Which AGENTS.md sections the change touches.
- Any new Section 13 entries added.
- Test plan: what you tested, what you didn't, what remains unverified.

---

## 13. Open Questions

- Resource loading must work in both SwiftPM tests and the Xcode app target. The current implementation uses a shared bundle accessor that resolves to `Bundle.module` under SwiftPM and `Bundle.main` in the app target.
- The first generated Xcode project relies on `GENERATE_INFOPLIST_FILE = YES`. Keep this unless a hand-authored `Info.plist` becomes necessary for release-specific metadata.
- The current scaffold supports a buildable app shell, but the Seneca runtime asset pipeline is still waiting on the real `idle`, `watching`, `alert`, and `working` PNGs.
- Theme picker UI should expose user-facing display names, not raw internal theme identifiers.
- Notch and menu surfaces must stay accessibility-safe under larger text sizes, so fixed panel dimensions should be treated as minimums rather than absolutes.

---

## 14. References

- Claude Island (Farouq Aldori): `https://github.com/farouqaldori/claude-island` — architectural reference, Apache 2.0.
- engels74 Swift 6 fork — reference for strict-concurrency patterns.
- Claude Code hooks: `https://docs.claude.com/en/docs/claude-code/hooks`
- GRDB: `https://github.com/groue/GRDB.swift`
- Sparkle 2: `https://sparkle-project.org`
- Seneca (Roman Stoic): _Letters from a Stoic_, Penguin Classics, trans. Robin Campbell — personality reference for the default familiar.
