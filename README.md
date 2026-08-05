# Artificially Inteligent

A lightweight AI chatbot client for jailbroken iOS devices running iOS 3.0 through iOS 10+. 

## API Configurations

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

