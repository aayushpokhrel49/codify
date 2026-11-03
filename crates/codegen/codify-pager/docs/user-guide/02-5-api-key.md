# API Key Quick Start (No Login Required)

You do **not** need to run `codify login` or open a browser to use Codify. Pass your API key directly and start coding immediately.

---

## One-liner: Interactive TUI

```bash
codify agent --api-key "xai-..."
```

Codify launches as a full-screen TUI. Your API key authenticates every request — no `auth.json`, no session token, no browser.

---

## Headless / Scripting (CI/CD)

```bash
codify agent headless --api-key "xai-..." "Explain the code in src/main.rs"
```

Use this in scripts, CI pipelines, or editor integrations. Output formats (`--output-format plain|json|streaming-messages-json`) make it easy to parse.

---

## Using the Environment Variable (Recommended for Daily Use)

Set it once in your shell profile instead of passing the flag every time:

```bash
# ~/.bashrc, ~/.zshrc, or $PROFILE (Windows PowerShell)
export XAI_API_KEY="xai-..."
```

Then just run Codify:

```bash
codify                    # TUI
codify -p "Hello"         # headless, single turn
codify agent stdio        # stdio agent for ACP / IDE
```

When both `--api-key` and `XAI_API_KEY` are set, the flag wins.

---

## Authentication Precedence

Codify resolves credentials for each request in this order (highest to lowest):

| Priority | Source | Notes |
|----------|--------|-------|
| 1 | Per-model `api_key` / `env_key` in `[model.<name>]` | Wins whenever present; see [Custom Models](11-custom-models.md) |
| 2 | `--api-key` flag | CLI override |
| 3 | `XAI_API_KEY` environment variable | Global fallback |
| 4 | Stored session token (`~/.grok/auth.json`) | From `codify login` — only if no API key is configured |

If you have previously signed in with `codify login` but want to use an API key instead, either pass `--api-key`, set `XAI_API_KEY`, or run `codify logout` / delete `~/.grok/auth.json` so the API key path is used.

> **Tip:** API key auth never triggers a browser. Use it on SSH boxes, Docker containers, CI runners, and any machine without a browser.

---

## Selecting a Model

With an API key, model selection is controlled by `--model` (default `grok-4.6`) and the built-in model catalog:

```bash
# Interactive TUI — pick a model at launch
codify agent --api-key "xai-..." -m grok-4.6

# Headless — specific model
codify agent headless --api-key "xai-..." -m claude-3-7-sonnet "Write a Rust function"

# List every available model
codify models
```

Switch models mid-session in the TUI with `/model <name>` or `Ctrl+M` from the scrollback pane.

See [Custom Models](11-custom-models.md) for the full model catalog, third-party providers (Anthropic, OpenAI, Google, DeepSeek, Ollama, etc.), and how to add your own endpoints.

---

## Configuring Endpoints (Optional)

Codify defaults to the xAI API. To point at a custom or proxy endpoint:

```bash
codify agent --api-key "xai-..." \
  --codify-api-base-url "https://grok-proxy.acme.com/v1" \
  "Hello"
```

Or in `~/.grok/config.toml`:

```toml
[endpoints]
codify_api_base_url = "https://grok-proxy.acme.com/v1"
```

The model-list fetch and inference requests both use your API key as `Authorization: Bearer`.

---

## Security

- `XAI_API_KEY` is read from the environment at process startup; it is never written to disk by Codify.
- Treat your API key like a password: do not commit it to version control, paste it into tickets, or print it to logs.
- On multi-user hosts, keep shell profiles and environment files (`~/.bashrc`, `~/.zshrc`, `.env`) private to your account (owner-only permissions).
- Prefer per-model `env_key` in `config.toml` for provider-specific keys (e.g. `ANTHROPIC_API_KEY`) so they are scoped to one model rather than global.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `401 Unauthorized` | Your API key is invalid or expired. Generate a new one at your provider's console and re-set `XAI_API_KEY`. |
| `model does not exist` | The model isn't available to your key or isn't in the catalog. Run `codify models` to see what's selectable. |
| Browser still opens | A stored session token is taking precedence. Run `codify logout` or unset `XAI_API_KEY` / omit `--api-key` only if you intend to use session auth. |
| `codify: command not found` | Install Codify: see [Installing](01-getting-started.md#installation), or build from source with `cargo build -p codify-bin --release`. |

---

## Related Guides

- [Authentication](02-authentication.md) — browser login, OIDC/SSO, external auth providers, device code
- [Custom Models](11-custom-models.md) — built-in catalog, third-party providers, `[model.*]` config
- [Headless Mode](14-headless-mode.md) — scripting, CI/CD, output formats
- [Configuration](05-configuration.md) — `config.toml`, environment variables, file locations
