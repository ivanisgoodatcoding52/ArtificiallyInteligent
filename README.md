# Artificially Inteligent

A lightweight AI chatbot client for jailbroken iOS devices running iOS 3.0 through iOS 10+. Connect to OpenAI-compatible APIs, a local Ollama server, VoidAI, or any custom JSON API, right from your legacy iPhone, iPod touch, or iPad.

## Project layout

```
ArtificiallyInteligent/
├── control                          # Debian package metadata
├── Makefile                         # Theos build rules (tweak + prefs subproject)
├── ArtificiallyInteligent.plist     # MobileSubstrate filter (SpringBoard only)
├── Tweak.xm                         # SpringBoard hook / launch entry points
├── Classes/
│   ├── AICompat.h/.m                # OS-version branching, legacy-safe alerts, text sizing
│   ├── AIJSONCompat.h/.m            # NSJSONSerialization wrapper + iOS 3-4 fallback parser
│   ├── AIChatViewController.h/.m    # Main chat screen
│   ├── AIMessageCell.h/.m           # Chat bubble table cell
│   ├── AIAPIManager.h/.m            # Networking orchestrator (NSURLSession / NSURLConnection)
│   ├── AIProvider.h/.m              # Abstract provider base class
│   ├── AIOpenAIProvider.h/.m        # OpenAI-compatible backend
│   ├── AIOllamaProvider.h/.m        # Ollama backend
│   ├── AIVoidAIProvider.h/.m        # VoidAI backend
│   ├── AIGenericProvider.h/.m       # User-defined custom backend
│   ├── AISettingsManager.h/.m       # NSUserDefaults wrapper
│   └── AIConversationStore.h/.m     # Local JSON-file chat history
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

1. Install [Theos](https://theos.dev) on your build machine (macOS or Linux) and point `THEOS` at it.
2. From the project root:
   ```
   make package
   ```
   This produces a `.deb` in `packages/`.
3. Copy the `.deb` to your device (`scp`, or a jailbroken package manager's "install local .deb" option) and install it, or run:
   ```
   make package install
   ```
   with `THEOS_DEVICE_IP` set to your device's IP over SSH.
4. Respring. SpringBoard will restart automatically as part of `after-install`.

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
- **ARMv7-only build with this SDK.** The project targets ARMv7 (covering iPhone 3GS through the plain iPhone 5, iPad 1-4, iPod touch 4/5, and more). ARM64 is not included when building against `iPhoneOS6.1.sdk`, because that SDK predates Apple's arm64 support entirely (added around Xcode 5.0.1 / iOS 7.0.3, months after 6.1 shipped) — its headers have no arm64 definitions at all, which fails deep inside system headers before any of this project's own code is reached, and can't be worked around from the source side. **Practical consequence:** on 64-bit-only host processes (SpringBoard on iPhone 5s, iPhone 6, and later, all of which run natively as arm64), an armv7-only dylib cannot be injected at all, so this build as-is won't activate on those specific devices even though the OS itself still runs older armv7 apps. To restore arm64 support, install a newer SDK (iOS 7+) from the community [theos/sdks](https://github.com/theos/sdks) repo into `$THEOS/sdks`, then split `THEOS_DEVICE_TARGETS` per architecture, e.g.:
  ```
  THEOS_DEVICE_TARGETS = iphone:clang:6.1:3.0 iphone:clang:9.3:7.0
  ARCHS = armv7
  ARCHS_iphone:clang:9.3:7.0 = arm64
  ```
  so armv7 keeps building against 6.1 while arm64 builds against the newer SDK, giving you one package that covers both.

## Notes / things to double check before shipping

- Replace `com.yourname.artificiallyinteligent` in `control`, `AISettingsManager.m`, `Tweak.xm`, and the Preferences bundle files with your own reverse-DNS identifier.
- The generated icons in `Resources/` and `Preferences/Resources/Icon.png` are placeholder art — swap in real designs before distributing.
- `AIGenericProvider`'s template substitution does simple string replacement, not full JSON-templating; keep placeholders inside string values in your template (e.g. `"content": "{{message}}"`), not as bare JSON structure.
