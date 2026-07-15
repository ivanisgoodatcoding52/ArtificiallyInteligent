# Artificially Inteligent

A lightweight AI chatbot client for jailbroken iOS devices running iOS 3.0 through iOS 10+. Connect to OpenAI-compatible APIs, a local Ollama server, VoidAI, or any custom JSON API, right from your iPhone, iPod touch, or iPad.

So far this project is in beta, expect bugs and fixes. 

## Using it

- **Open the chat UI**: long-press anywhere on the SpringBoard home screen for about a second, or bind a gesture to "Artificially Inteligent" in Activator's settings if you have libactivator installed (both are wired up in `Tweak.xm`; Activator support degrades gracefully if it's not installed).
- **Configure a provider**: Settings.app → Artificially Inteligent.
- **Clear a conversation**: "Clear" button in the chat's nav bar, or "Clear Stored Data" in Settings to wipe everything including preferences.
- **Copy a message**: long-press any bubble.
- **Export history**: conversations are saved as plain JSON at `~/Library/Application Support/ArtificiallyInteligent/conversation.json` on-device (if "Save Chat History" is on); `AIConversationStore.exportAsPlainText` is available for a future export/share-sheet button if you want to wire one in.

## Example API configurations

**OpenAI (or an OpenAI-compatible proxy)**
- Provider: `OpenAI`
- API URL: `https://api.openai.com` (the `/v1/chat/completions` path is appended automatically if you leave it off)
- API Key: `sk-...`
- Model: `gpt-3.5-turbo`

**Local llama.cpp / LM Studio server**
- Provider: `OpenAI`
- API URL: `http://192.168.1.50:8080/v1/chat/completions`
- API Key: (blank, or whatever the server expects)
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
