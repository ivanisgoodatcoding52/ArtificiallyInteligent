# Artificially Inteligent

[![Release](https://img.shields.io/github/v/release/ivanisgoodatcoding52/ArtificiallyInteligent?include_prereleases)](https://github.com/ivanisgoodatcoding52/ArtificiallyInteligent/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/ivanisgoodatcoding52/ArtificiallyInteligent/blob/main/LICENSE)
[![iOS](https://img.shields.io/badge/iOS-4.0%2B-blue.svg)](#supported-devices--build-tiers)
[![Built with Theos](https://img.shields.io/badge/build-Theos-8A2BE2.svg)](#building-from-source)

> A lightweight AI chatbot client for **legacy jailbroken iOS devices (iOS 4.0+)** — no JavaScript, no web views, everything is native Objective-C that still compiles against the iOS 6.1 SDK.

The package ships three things at once:

| Component             | Path                                                                     | What it does                                                                       |
| ---------------------- | ------------------------------------------------------------------------ | ----------------------------------------------------------------------------------- |
| **SpringBoard tweak** | `/Library/MobileSubstrate/DynamicLibraries/ArtificiallyInteligent.dylib` | Presents the chat UI as a modal overlay above any screen                           |
| **Preference bundle** | `/Library/PreferenceBundles/ArtificiallyInteligentPrefs.bundle`          | Settings.app pane (via PreferenceLoader) for all provider/API configuration        |
| **Standalone app**    | `/Applications/ArtificiallyInteligentApp.app`                            | The same chat UI as a normal icon, plus the `artificiallyinteligent://` URL scheme |

---

## Features

- **Chat overlay** — long-press (~1.2 s) on the SpringBoard window from the home screen; the window is `UIWindowLevelAlert + 1`, so it floats above everything. Dismiss with the *Done* button.
- **Activator integration (optional)** — if [Activator](https://github.com/rpetrich/activator) is installed, the listener `com.rg.artificiallyinteligient.open` is registered so you can bind the chat to *any* gesture. It is a **soft dependency**: class lookups are dynamic, so the tweak works fine without it.
- **Four provider backends**:
  * **OpenAI-compatible** — any `/v1/chat/completions` endpoint (OpenAI, OpenRouter, LM Studio, llama.cpp server, …)
  * **Ollama** — newline-delimited JSON streaming responses
  * **VoidAI** — defaults to `https://voidai.app/v1/chat/completions`
  * **Custom / generic** — bring your own JSON body template with `{{message}}`, `{{history}}`, `{{model}}`, `{{system}}` placeholders, a configurable auth header (`Authorization: Bearer …` by default) and a dot-notation response path (`choices.0.message.content`)
- **Chat history** persisted to the app-support directory (can be disabled), system prompt, temperature, max tokens, request timeout, streaming flag.
- **URL scheme** — launch straight into a chat turn from Safari, another app, or a shortcut.
- **Cross-tweak Darwin-notification API** — other SpringBoard tweaks can ask for an AI reply without linking against this project at all (see [Cross-tweak bridge API](#cross-tweak-bridge-api)).
- **Two interchangeable UI tiers** — the same class names are implemented twice: a legacy look for iOS 4–6 and a from-scratch iOS 7+ redesign (`UIAlertController`, Auto Layout, flat visuals).
- **Old-iOS compatibility engineering** — `NSURLSession`/`NSJSONSerialization` are looked up dynamically and fall back to `NSURLConnection` / `AIJSONCompat` parsing on iOS 4.x–6.x, where those classes don't exist yet.

## Installation

1. Grab `com.rg.artificiallyinteligient_*_iphoneos-arm.deb` from the [Releases](https://github.com/ivanisgoodatcoding52/ArtificiallyInteligent/releases) page.
2. Install it with your package manager (Sileo, Zebra, Cydia) or over SSH:

   ```
   dpkg -i com.rg.artificiallyinteligient_1.0.0-3+debug_iphoneos-arm.deb
   ```

3. Respring (the package's `after-install` hook does it automatically when installed via Theos).

**Runtime dependencies:** `mobilesubstrate | com.saurik.substrate.safemode`, `firmware (>= 4.0)`, `preferenceloader`. **Optional:** `libactivator` — only needed if you want to bind a custom Activator gesture.

## Supported devices & build tiers

The project targets five separate build tiers, chosen on the command line with `BUILD_ARCH`:

| `BUILD_ARCH`          | ARCHS       | Target (SDK : min iOS) | Hardware / OS scope                        | Extra SDK needed                 |
| ---------------------- | ----------- | ------------------------ | -------------------------------------------- | ----------------------------------- |
| `armv6`               | armv6       | 4.3 : 4.0              | iPod touch 2G, iPhone 3G (iOS 4.0–4.2.1)   | iPhoneOS4.3/5.1.sdk              |
| `armv7` **(default)** | armv7       | 6.1 : 4.0              | iPhone 3GS → 5, iPad 1–4, iPod touch 4/5   | iPhoneOS6.1.sdk                  |
| `a4a6`                | armv7       | 6.1 : 5.0              | A4–A6 chips only (iPhone 4/5, iPad 1–3, …) | iPhoneOS6.1.sdk                  |
| `arm64`               | arm64       | latest : 7.0           | iPhone 5s and later                        | iOS 7.0+ SDK                     |
| `modern`              | armv7 arm64 | latest : 7.0           | iOS 7+ with the redesigned UI              | iOS 8+ SDK (`UIAlertController`) |

> **Why the floor is iOS 4.0 everywhere:** the codebase uses Objective-C blocks and GCD throughout (every `dispatch_once` singleton, `dispatch_async`, block-based completion handler). None of that exists below iOS 4.0 — not even as a compile-only feature, since the block/GCD runtime isn't in iOS 3.x's libSystem.

## Configuration (Settings.app → Artificially Inteligent)

All values are stored in the `com.rg.artificiallyinteligient` defaults suite and take effect on the next request.

| Setting                                     | Key                                                                             | Default                                         |
| --------------------------------------------- | ---------------------------------------------------------------------------------- | -------------------------------------------------- |
| Provider                                    | `AIActiveProviderType`                                                          | OpenAI-compatible                               |
| API URL                                     | `AIApiURL`                                                                      | *(empty — set your endpoint)*                   |
| API Key                                     | `AIApiKey`                                                                      | *(empty)*                                       |
| Model                                       | `AIModelName`                                                                   | `gpt-3.5-turbo`                                 |
| Temperature                                 | `AITemperature`                                                                 | `0.7`                                           |
| Max tokens                                  | `AIMaxTokens`                                                                   | `512`                                           |
| System prompt                               | `AISystemPrompt`                                                                | `You are a helpful assistant.`                  |
| Request timeout (s)                         | `AIRequestTimeout`                                                              | `30`                                            |
| Streaming responses                         | `AIStreamingEnabled`                                                            | off                                             |
| Save chat history                           | `AISaveHistoryEnabled`                                                          | on                                              |
| Custom provider name / auth header / format | `AIGenericProviderName`, `AIGenericAuthHeaderName`, `AIGenericAuthHeaderFormat` | `Custom Provider`, `Authorization`, `Bearer %@` |
| Custom request template / response path     | `AIGenericRequestTemplate`, `AIGenericResponsePath`                             | *(blank = default OpenAI-shaped body)*          |
| Ollama context length                       | `AIOllamaContextLength`                                                         | *(provider default)*                            |

## Launching the chat

Three entry points, all leading to the same UI:

1. **Long-press** (~1.2 s) on the SpringBoard window — always available, no dependencies.
2. **Activator gesture** — assign anything to the `com.rg.artificiallyinteligient.open` listener (requires Activator).
3. **URL scheme** — the standalone app handles:

   ```
   artificiallyinteligent://ask?text=<url-encoded message>
   ```

   which opens the chat *and* submits the turn, not just the screen.

## Cross-tweak bridge API

Other tweaks can request an AI response **without linking against this project** — it's a bare Darwin-notification protocol over a shared defaults suite, documented in `Classes/Shared/AIExternalBridge.h`.

- **Shared defaults suite:** `com.rg.artificiallyinteligient`
- **One request in flight at a time** (single-slot mailbox, not queued — fine for occasional calls, not for high-frequency use).

**To make a request:**

1. Generate a request ID (any unique string, a UUID is simplest).
2. Write a JSON string to `AIBridgePendingRequest`: `{"id": "<your id>", "text": "<the message>"}`
3. Post the Darwin notification `com.rg.artificiallyinteligient.bridge.request`.
4. Register for `com.rg.artificiallyinteligient.bridge.response`; when it fires, read `AIBridgeLastResponse` from the same suite: `{"id": "...", "reply": "...", "error": "..."}` (`error` is only present if the request failed).
5. Compare `id` with yours — a response you see may belong to another caller's concurrent request; ignore it if it doesn't match.

The reply is routed through whatever provider is currently configured in Settings.app.

## Building from source

### Prerequisites

- [Theos](https://theos.dev/) installed (e.g. `git clone --recursive https://github.com/theos/theos.git ~/theos`)
- An iOS toolchain (Theos' Linux installer gets you clang for iOS)
- **SDKs**: `iPhoneOS6.1.sdk` for the default `armv7` tier, an iOS 7+ SDK for `arm64`, an iOS 8+ SDK for `modern` — mirrored at [theos/sdks](https://github.com/theos/sdks) and [itsMaz1n/ios-sdk](https://github.com/itsMaz1n/ios-sdk) (older SDKs live in the latter)
- Standard tools: `perl`, `make`, `fakeroot`/`dpkg-deb` are *not* strictly required — Theos falls back to its own `dm.pl` packager

> ⚠️ **Theos does not support spaces in the project path.** Build from a path like `~/build/ArtificiallyInteligent`, not `~/My Projects/ArtificiallyInteligent`.

### Build

```
git clone https://github.com/ivanisgoodatcoding52/ArtificiallyInteligent.git
cd ArtificiallyInteligent

export THEOS=~/theos
make package BUILD_ARCH=armv7
```

Other tiers:

```
make package BUILD_ARCH=arm64
make package BUILD_ARCH=modern
make package BUILD_ARCH=a4a6
```

The `.deb` lands in `./packages/`.

> **Tip (Linux):** the default `lzma` compression needs the `lzma` binary, which most distros don't ship. Use `make package THEOS_PLATFORM_DEB_COMPRESSION_TYPE=xz` instead — `dpkg`/`apt`/Sileo all handle xz fine.

## Project layout

```
├── Tweak.xm                     # Logos: overlay window, long-press launcher, Activator listener, %ctor
├── Makefile                     # BUILD_ARCH tier selection (see table above)
├── control                      # Debian package metadata
├── ArtificiallyInteligent.plist # MobileSubstrate filter (com.apple.springboard)
├── Classes/
│   ├── Shared/                  # Compiled into every tier — identical logic
│   │   ├── AIAPIManager.*       # NSURLSession (iOS 7+) with NSURLConnection fallback
│   │   ├── AIProvider.*         # Base provider abstraction
│   │   ├── AIOpenAIProvider.*   # OpenAI-compatible /chat/completions
│   │   ├── AIOllamaProvider.*   # Ollama
│   │   ├── AIVoidAIProvider.*   # VoidAI
│   │   ├── AIGenericProvider.*  # User-defined JSON template provider
│   │   ├── AISettingsManager.*  # Typed NSUserDefaults wrapper
│   │   ├── AIConversationStore.*# History persistence
│   │   ├── AIExternalBridge.*   # Cross-tweak Darwin-notification API
│   │   └── AIJSONCompat.*       # JSON parsing fallback for pre-iOS 5
│   ├── Legacy/                  # UI for iOS 4–6 (wide compatibility)
│   └── Modern/                  # UI for iOS 7+ (UIAlertController, Auto Layout)
├── Preferences/                 # Settings.app pane (PreferenceLoader)
├── App/                         # Standalone app + artificiallyinteligent:// URL scheme
└── layout/                      # Files copied into the package as-is
```

`Legacy/` and `Modern/` expose the **same class and method names**, so nothing else in the project needs to know which UI tier it is linked against.

## License

[MIT](https://github.com/ivanisgoodatcoding52/ArtificiallyInteligent/blob/main/LICENSE) — © 2026 ivanisgood52.
