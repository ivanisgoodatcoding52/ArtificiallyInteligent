# Artificially Inteligent

A lightweight AI chatbot client for jailbroken iOS devices running iOS 3.0 through iOS 10+. Connect to OpenAI-compatible APIs, a local Ollama server, VoidAI, or any custom JSON API, right from your legacy iPhone, iPod touch, or iPad.

## Project layout

```
ArtificiallyInteligent/
├── control                          # Debian package metadata
├── Makefile                         # Theos build rules (BUILD_ARCH tier selection + prefs subproject)
├── ArtificiallyInteligent.plist     # MobileSubstrate filter (SpringBoard only)
├── Tweak.xm                         # SpringBoard hook / launch entry points
├── Classes/
│   ├── Shared/                      # Used identically by every BUILD_ARCH tier
│   │   ├── AIJSONCompat.h/.m        # NSJSONSerialization wrapper + iOS 3-4 fallback parser
│   │   ├── AIAPIManager.h/.m        # Networking orchestrator (NSURLSession / NSURLConnection)
│   │   ├── AIProvider.h/.m          # Abstract provider base class
│   │   ├── AIOpenAIProvider.h/.m    # OpenAI-compatible backend
│   │   ├── AIOllamaProvider.h/.m    # Ollama backend
│   │   ├── AIVoidAIProvider.h/.m    # VoidAI backend
│   │   ├── AIGenericProvider.h/.m   # User-defined custom backend
│   │   ├── AISettingsManager.h/.m   # NSUserDefaults wrapper
│   │   └── AIConversationStore.h/.m # Local JSON-file chat history
│   ├── Legacy/                      # Linked by armv6 / armv7 / arm64 tiers
│   │   ├── AICompat.h/.m            # OS-version branching, legacy-safe alerts, text sizing
│   │   ├── AIChatViewController.h/.m # Main chat screen (manual frame layout)
│   │   └── AIMessageCell.h/.m       # Chat bubble table cell (manual frame layout)
│   └── Modern/                      # Linked by the modern (iOS7+) tier only
│       ├── AICompat.h/.m            # Real UIAlertController, iOS7-only UIActionSheet fallback
│       ├── AIChatViewController.h/.m # Main chat screen (Auto Layout, flat redesign)
│       └── AIMessageCell.h/.m       # Chat bubble table cell (Auto Layout, flat redesign)
├── Preferences/
│   ├── Makefile                     # Sub-project for the Settings.app bundle
│   ├── AIPrefsRootListController.h/.m
│   └── Resources/
│       ├── Root.plist               # Settings.app pane layout
│       ├── Info.plist               # Preference bundle metadata
│       └── Icon.png                 # Small icon shown in Settings list
├── Layout/
│   └── Library/PreferenceLoader/Preferences/ArtificiallyInteligent.plist
└── Resources/
    ├── Info.plist
    └── Icon*.png                    # Legacy glossy + iOS 7+ flat icon variants
```

## Installation

This project supports four build tiers, each requiring a different SDK (see "Multi-generation builds" below for why). Pick the tier that matches your target device and desired UI, and pass it as `BUILD_ARCH`:

1. Install [Theos](https://theos.dev) on your build machine (macOS or Linux) and point `THEOS` at it.
2. From the project root, build the tier you need:
   ```
   make package BUILD_ARCH=armv6   # iPod touch 2G, iPod touch 1G, iPhone 3G (iOS 3.0-4.2.1)
   make package BUILD_ARCH=armv7   # iPhone 3GS-5, iPad 1-4, iPod touch 4/5 (default if omitted)
   make package BUILD_ARCH=arm64   # iPhone 5s and later, legacy-compatible UI
   make package BUILD_ARCH=modern  # iPhone 4 and later on iOS 7+, refreshed flat UI
   ```
   Each produces its own `.deb` in `packages/`. `armv6`, `arm64`, and `modern` each need an SDK you likely don't have installed yet — see below.
3. Copy the `.deb` to your device (`scp`, or a jailbroken package manager's "install local .deb" option) and install it, or run:
   ```
   make package install BUILD_ARCH=<tier>
   ```
   with `THEOS_DEVICE_IP` set to your device's IP over SSH.
4. Respring. SpringBoard will restart automatically as part of `after-install`.

Since a device only ever needs one tier, install only the `.deb` matching its hardware and preferred UI — installing the wrong one won't crash anything, but it also won't load (a mismatched-architecture dylib is simply never activated by MobileSubstrate). Note `arm64` and `modern` overlap in hardware support (both can run on an iPhone 5s+) — the difference is UI: `arm64` keeps the same legacy-compatible look as `armv6`/`armv7`, while `modern` is the from-scratch iOS7+ redesign. `modern` also builds for `armv7`, so an iPhone 4/4S/5 user on iOS 7+ can choose it over the `armv7` tier if they'd rather have the newer look.

### Rootless vs rootful

Theos detects your target automatically based on `THEOS_DEVICE_ROOTLESS` / the toolchain you're building against. No project changes are needed either way — install paths for the tweak binary and Settings bundle are resolved by Theos' standard `_INSTALL_PATH` conventions.

## Using it

- **Open the chat UI**: long-press anywhere on the SpringBoard home screen for about a second, or bind a gesture to "Artificially Inteligent" in Activator's settings if you have libactivator installed (both are wired up in `Tweak.xm`; Activator support degrades gracefully if it's not installed).
- **Configure a provider**: Settings.app → Artificially Inteligent.
- **Clear a conversation**: "Clear" button in the chat's nav bar, or "Clear Stored Data" in Settings to wipe everything including preferences.
- **Copy a message**: long-press any bubble.
- **Export history**: conversations are saved as plain JSON at `~/Library/Application Support/ArtificiallyInteligent/conversation.json` on-device (if "Save Chat History" is on); `AIConversationStore.exportAsPlainText` is available for a future export/share-sheet button if you want to wire one in.

## Example API configurations

**OpenAI (or an OpenAI-compatible proxy)**
- Provider: `OpenAI Compatible`
- API URL: `https://api.openai.com` (the `/v1/chat/completions` path is appended automatically if you leave it off)
- API Key: `sk-...`
- Model: `gpt-3.5-turbo`

**Local llama.cpp / LM Studio server**
- Provider: `OpenAI Compatible`
- API URL: `http://192.168.1.50:8080/v1/chat/completions`
- API Key: (blank, or whatever your server expects)
- Model: whatever your server reports, e.g. `llama-3-8b-instruct`

**Ollama on your LAN**
- Provider: `Ollama`
- API URL: `http://192.168.1.100:11434`
- Model: `llama2` (or any model you've pulled with `ollama pull`)
- Temperature / context length: adjustable in Settings

**VoidAI**
- Provider: `VoidAI`
- API URL: leave blank to use `https://voidai.app/v1/chat/completions`, or override
- API Key + Model: from your VoidAI account

**Fully custom API**
- Provider: `Custom API`
- API URL: your endpoint
- Auth Header Name / Format: e.g. `Authorization` / `Bearer %@`
- Request Template: a JSON string using `{{message}}`, `{{history}}`, `{{model}}`, `{{system}}` placeholders. Leave blank to fall back to a default OpenAI-shaped body.
- Response Path: dot-notation path to the reply text, e.g. `choices.0.message.content` or `data.reply`

## Compatibility decisions

- **Objective-C + UIKit only, no Swift.** Swift's runtime wasn't viable on iOS 3-6 devices at all, and staying pure Obj-C keeps one code path instead of a bridging layer.
- **Manual frame layout in `AIMessageCell`, not Auto Layout.** Auto Layout exists from iOS 6 on but is meaningfully slower on early ARMv7 hardware; manual `layoutSubviews` math is cheap and predictable on an iPhone 3GS.
- **`NSURLSession` when available, `NSURLConnection` delegate-based fallback otherwise** (`AIAPIManager`), since `NSURLSession` doesn't exist before iOS 7.
- **`NSJSONSerialization` when available (iOS 5+), hand-rolled fallback parser otherwise** (`AIJSONCompat`), since the built-in JSON APIs don't exist on iOS 3-4.
- **`UIAlertController` on iOS 8+, `UIActionSheet`/`UIAlertView` before that** (`AICompat`'s `AIPresentConfirm`/`AIPresentAlert`), since `UIAlertController` fully deprecates the older classes and using it exclusively would break iOS 3-7.
- **`boundingRectWithSize:` on iOS 7+, `sizeWithFont:` before that** for computing bubble heights, since the former didn't exist pre-iOS 7 and the latter is deprecated (but still functional) after.
- **Flat-file JSON conversation storage instead of SQLite/CoreData.** Personal chat history at the scale a single device will accumulate doesn't need a database engine; a JSON file keeps the binary smaller and avoids owning a CoreData stack on constrained RAM.
- **Activator integration is a soft, weakly-linked dependency.** The tweak works standalone (long-press gesture) with zero required dependencies beyond MobileSubstrate/PreferenceLoader; Activator, if present, is detected via `NSClassFromString` and never assumed.
- **Streaming defaults to off.** True token streaming is straightforward on the `NSURLSession` path but awkward to do well on `NSURLConnection`'s delegate callbacks; defaulting non-streaming keeps behavior identical and predictable across the entire iOS 3-10 range, with streaming available as an opt-in for iOS 7+ devices where it's cheap.
- **Four separate per-tier builds instead of one universal fat binary.** Each hardware generation needs a different SDK, and no single SDK spans all four: Apple's SDKs from the armv6 era (iOS 4.x and earlier) don't know about arm64 at all, and modern SDKs (iOS 7+) no longer ship armv6 system-library slices. Rather than fight Theos' multi-SDK-per-architecture mechanism to produce one fat binary, this project builds four independent `.deb`s via `BUILD_ARCH` (see Installation above):
  - **`armv6`** — iPod touch 1G/2G, iPhone 3G. Max OS iOS 4.2.1. Needs an SDK from that era (e.g. iPhoneOS4.3.sdk) — Apple dropped armv6 library slices from its SDKs starting around Xcode 4.5.
  - **`armv7`** — iPhone 3GS through the plain iPhone 5, iPad 1-4, iPod touch 4/5. Builds against the `iPhoneOS6.1.sdk` this project was developed and verified against.
  - **`arm64`** — iPhone 5s and later, same legacy-compatible UI as the two tiers above. Needs an iOS 7+ SDK, since Apple's toolchain had no arm64 support at all until Xcode 5.0.1/iOS 7.0.3 (several months after 6.1 shipped).
  - **`modern`** — iPhone 4 and later running iOS 7+, with a from-scratch UI redesign (see below). Builds for both armv7 and arm64. Needs an iOS 8+ SDK so `UIAlertController` is actually declared in the headers (same requirement as `arm64` above).

  Additional SDKs are free and community-mirrored at [theos/sdks](https://github.com/theos/sdks) — drop the `.sdk` folder you need directly into `$THEOS/sdks`. Only the `armv7` tier has actually been build-and-link verified so far; the other three use the same shared business-logic source (nothing in `Classes/Shared/` is architecture-specific — compatibility is handled by the runtime checks in `AICompat.m`, not compile-time branching) but haven't been tested against their respective SDKs yet.

- **Source layout: `Classes/Shared/`, `Classes/Legacy/`, `Classes/Modern/`.** The `armv6`/`armv7`/`arm64` tiers all link `Classes/Legacy/` (the wide-compatibility UI and compat-shim implementation covered by the rest of this section); `modern` links `Classes/Modern/` instead. Both expose identical class and function names (`AIChatViewController`, `AIMessageCell`, `AIPresentConfirm`, etc.), so the Makefile just swaps which directory is on the header search path and file list per `BUILD_ARCH` — nothing else in the project needs to know which one it's linked against. Business logic (`AIJSONCompat`, `AIAPIManager`, the providers, settings, conversation store) lives once in `Classes/Shared/` and is used unmodified by every tier.

### The `modern` tier's redesign

Where the other three tiers optimize for running identically on hardware from 2009 through 2015, `modern`'s floor is iOS 7.0 and it leans into what that unlocks:

- **Real `UIAlertController`** on iOS 8+ (with a `UIActionSheet`/`UIAlertView` fallback only for iOS 7 itself, the one version in this tier's range that predates it) — no `NSClassFromString`/`performSelector` dynamic dispatch needed, since this tier's SDK genuinely declares the class.
- **Auto Layout throughout** (`AIChatViewController`, `AIMessageCell`) instead of the Legacy tier's manual `layoutSubviews` frame math — safe to lean on here since Auto Layout's iOS 6+ minimum is comfortably under this tier's iOS 7.0 floor, and the performance concern that ruled it out for the `armv7`/`armv6` tiers (older, slower hardware) doesn't apply to iOS 7+ devices.
- **Refreshed flat visual design**: a hairline-separator input bar instead of `UIToolbar` chrome, shadowed message bubbles with more generous padding and a proper flat iOS-blue/light-gray palette, `UIButtonTypeSystem` and `barTintColor` used directly and unconditionally (both are safe assumptions once the floor is iOS 7.0, unlike the Legacy tier which has to dance around their absence pre-iOS 7).
- **No legacy fallbacks needed** for `NSURLSession`, `NSJSONSerialization`, or text-measurement APIs — all have existed since iOS 5–7, comfortably inside this tier's floor, so the shared business-logic code's runtime checks simply always take their "modern" branch here.

## Notes / things to double check before shipping

- Replace `com.yourname.artificiallyinteligent` in `control`, `AISettingsManager.m`, `Tweak.xm`, and the Preferences bundle files with your own reverse-DNS identifier.
- The generated icons in `Resources/` and `Preferences/Resources/Icon.png` are placeholder art — swap in real designs before distributing.
- `AIGenericProvider`'s template substitution does simple string replacement, not full JSON-templating; keep placeholders inside string values in your template (e.g. `"content": "{{message}}"`), not as bare JSON structure.
