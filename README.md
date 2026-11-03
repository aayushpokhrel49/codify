<div align="center">

<h1>
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://media.x.ai/v1/website/spacexai-symbol-white-transparent-0c31957f.png">
    <source media="(prefers-color-scheme: light)" srcset="https://media.x.ai/v1/website/spacexai-symbol-black-transparent-6435cf42.png">
    <img alt="SpaceXAI logo" src="https://media.x.ai/v1/website/spacexai-symbol-black-transparent-6435cf42.png" width="96">
  </picture>
  <br>
  Codify (<code>codify</code>)
</h1>

**Codify** is a terminal-based AI coding agent. It runs as a
full-screen TUI that understands your codebase, edits files, executes shell
commands, searches the web, and manages long-running tasks — interactively,
headlessly for scripting/CI, or embedded in editors via the Agent Client
Protocol (ACP).

[Installing the released binary](#installing-the-released-binary) ·
[Building from source](#building-from-source) ·
[Documentation](#documentation) ·
[Repository layout](#repository-layout) ·
[Development](#development) ·
[Contributing](#contributing) ·
[License](#license)

![Codify TUI](https://media.x.ai/v1/website/universe-tui-screenshot-6f7a0837.png)

**Learn more about Codify at [x.ai/cli](https://x.ai/cli)**

This repository contains the Rust source for the `codify` CLI/TUI and its agent
runtime. It is synced periodically from the upstream monorepo.

A small `SOURCE_REV` file at the root records the full monorepo commit SHA
for the version of the code present in this tree.

---

## Why "Codify" (was "Grok Build" / xAI / SpaceXAI)

This tree is a fork of the original **Grok Build** project, which was built by
**xAI / SpaceXAI**. You may still see `x.ai`, `xai`, `grok`, and `SpaceXAI`
references in some strings, URLs, and legacy code — those are remnants of the
original upstream that we have not yet renamed everywhere.

This fork has been rebranded to **Codify** (`codify` binary). The user-facing
command is now `codify` instead of `grok`, and new installs should use the
GitLab release URL above rather than `x.ai/cli`.

If you are looking for the original xAI distribution, see
https://x.ai/cli — this repository is an independent rebrand and is not
affiliated with xAI or SpaceXAI.

</div>

---

## Installing the released binary

Prebuilt binaries are published via GitLab Releases for macOS, Linux, and
Windows. Install with one curl command:

```sh
# macOS / Linux / Git Bash
curl -fsSL https://gitlab.com/aayushpokhrel49/codify/-/raw/main/install.sh | bash

# Windows PowerShell
irm https://gitlab.com/aayushpokhrel49/codify/-/raw/main/install.ps1 | iex

codify --version
```

Install a specific version:

```sh
CODIFY_VERSION=v1.0.45 curl -fsSL https://gitlab.com/aayushpokhrel49/codify/-/raw/main/install.sh | bash
```

The binary artifact is named `codify` and is installed to
`$HOME/.local/bin` (or `/usr/local/bin` as a fallback).

See the [GitLab Releases page](https://gitlab.com/aayushpokhrel49/codify/-/releases)
for the latest fixes, features, and improvements in each release.

## Building from source

Requirements:

- **Rust** — the toolchain is pinned by [`rust-toolchain.toml`](rust-toolchain.toml);
  `rustup` installs it automatically on first build.
- **[DotSlash](https://dotslash-cli.com)** — required so hermetic tools under
  [`bin/`](bin/) (notably [`bin/protoc`](bin/protoc)) can download and run.
  Install it and ensure `dotslash` is on your `PATH` **before** building:

  ```sh
  cargo install dotslash
  # or: prebuilt packages — https://dotslash-cli.com/docs/installation/
  /usr/bin/env dotslash --help   # sanity check
  ```

- **protoc** — proto codegen resolves [`bin/protoc`](bin/protoc) via DotSlash,
  or falls back to a `protoc` on `PATH` / `$PROTOC`.
- macOS and Linux are supported build hosts; Windows builds are best-effort
  and not currently tested from this tree.

```sh
cargo run -p codify-bin              # build + launch the TUI
cargo build -p codify-bin --release  # release binary: target/release/codify
cargo check -p codify-bin            # fast validation
```

The binary artifact is named `codify`.

CI builds run on every push/tag via [`.gitlab-ci.yml`](.gitlab-ci.yml) and
publish release assets to GitLab Releases.

## Quick start: use an API key (no login / no browser)

You do **not** need to run `codify login` to use the agent. Pass your API key directly:

```sh
# Interactive TUI (stdio agent) — just works with an API key, no browser
codify agent --api-key <YOUR_API_KEY>

# Headless (non-interactive, good for scripting/CI)
codify agent headless --api-key <YOUR_API_KEY> "your prompt"

# Or set the env var once instead of passing the flag each time
export XAI_API_KEY=<YOUR_API_KEY>
codify
```

Authentication precedence: `--api-key` flag > `XAI_API_KEY` env var > stored session (`codify login`).
With an API key, model selection is controlled by `--model` (default `grok-4.6`) and the model catalog
(`default_models.json`), which now includes Claude, GPT, o-series, Gemini, and DeepSeek models alongside Grok.

## Documentation

Full documentation ships with the pager crate:
[`crates/codegen/codify-pager/docs/user-guide/`](crates/codegen/codify-pager/docs/user-guide/)
— getting started, keyboard shortcuts, slash commands, configuration, theming,
MCP servers, skills, plugins, hooks, headless mode, sandboxing, and more.

Online reference: https://gitlab.com/aayushpokhrel49/codify/-/tree/main/crates/codegen/codify-pager/docs/user-guide

## Repository layout

| Path | Contents |
|------|----------|
| `crates/codegen/codify-bin` | Composition-root package; builds the `codify` binary |
| `crates/codegen/codify-pager` | The TUI: scrollback, prompt, modals, rendering |
| `crates/codegen/codify-shell` | Agent runtime + leader/stdio/headless entry points |
| `crates/codegen/codify-tools` | Tool implementations (terminal, file edit, search, ...) |
| `crates/codegen/codify-workspace` | Host filesystem, VCS, execution, checkpoints |
| `crates/codegen/...` | The rest of the CLI crate closure (config, MCP, markdown, sandbox, ...) |
| `crates/common/`, `crates/build/`, `prod/mc/` | Small shared leaf crates pulled in by the closure |
| `third_party/` | Vendored upstream source (Mermaid diagram stack) — see below |

> [!IMPORTANT]
> The root `Cargo.toml` (workspace members, dependency versions, lints,
> profiles) is **generated** — treat it as read-only. Prefer editing per-crate
> `Cargo.toml` files.

## Development

```sh
cargo check -p <crate>        # always target specific crates; full-workspace builds are slow
cargo test -p codify-config       # per-crate tests
cargo clippy -p <crate>       # lint config: clippy.toml at the repo root
cargo fmt --all               # rustfmt.toml at the repo root
```

## Contributing

> [!NOTE]
> External contributions are not accepted. See [`CONTRIBUTING.md`](CONTRIBUTING.md).

## License

First-party code in this repository is licensed under the **Apache License,
Version 2.0** — see [`LICENSE`](LICENSE).

Third-party and vendored code remains under its original licenses. See:

- [`THIRD-PARTY-NOTICES`](THIRD-PARTY-NOTICES) — crates.io / git dependencies,
  bundled UI themes, and **in-tree source ports** (including openai/codex and
  sst/opencode tool implementations)
- [`crates/codegen/codify-tools/THIRD_PARTY_NOTICES.md`](crates/codegen/codify-tools/THIRD_PARTY_NOTICES.md)
  — crate-local notice for the codex and opencode ports (license texts +
  Apache §4(b) change notice)
- [`third_party/NOTICE`](third_party/NOTICE) — vendored Mermaid-stack index
