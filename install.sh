#!/usr/bin/env bash
#
# codify-install.sh — Install the Codify CLI from GitHub releases.
#
# Usage:
#   macOS / Linux / Git Bash:
#     curl -fsSL https://raw.githubusercontent.com/aayushpokhrel49/codify/main/install.sh | bash
#
#   Windows PowerShell:
#     irm https://raw.githubusercontent.com/aayushpokhrel49/codify/main/install.ps1 | iex
#
# Installs the `codify` binary to:
#   $HOME/.local/bin   (if writable and on PATH)
#   /usr/local/bin     (fallback, may require sudo)
#
# Options (env vars):
#   CODIFY_VERSION   Specific release tag, e.g. "v1.0.45" (default: latest)
#   CODIFY_PREFIX    Install directory (default: $HOME/.local/bin)
#   CODIFY_FORCE     Reinstall even if already present ("1")
set -euo pipefail

REPO="aayushpokhrel49/codify"
RAW_BASE="https://raw.githubusercontent.com/${REPO}/main"
API_BASE="https://api.github.com/repos/${REPO}"

BIN_NAME="codify"
DEFAULT_PREFIX="${HOME}/.local/bin"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log()  { printf '%s\n' "$*"; }
err()  { printf 'codify-install: error: %s\n' "$*" >&2; }
die()  { err "$*"; exit 1; }

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    die "required command not found: $1"
  fi
}

# Detect OS
detect_os() {
  case "$(uname -s | tr '[:upper:]' '[:lower:]')" in
    linux*)  echo "linux" ;;
    darwin*) echo "darwin" ;;
    msys*|mingw*|cygwin*) echo "windows" ;;
    *)       die "unsupported operating system: $(uname -s)" ;;
  esac
}

# Detect architecture
detect_arch() {
  local arch
  arch="$(uname -m | tr '[:upper:]' '[:lower:]')"
  case "$arch" in
    x86_64|amd64) echo "x86_64" ;;
    aarch64|arm64) echo "aarch64" ;;
    *) die "unsupported architecture: $arch" ;;
  esac
}

# Resolve the download URL for a given tag using the GitHub Releases API
resolve_asset_url() {
  local os="$1" arch="$2" tag="$3"
  local suffix ext
  case "$os" in
    linux)   suffix="linux-${arch}.tar.gz" ; ext="tar.gz" ;;
    darwin)  suffix="darwin-${arch}.tar.gz" ; ext="tar.gz" ;;
    windows) suffix="windows-${arch}.zip" ; ext="zip" ;;
  esac

  local asset_name="codify-${tag}-${suffix}"
  local release_api="${API_BASE}/releases/tags/${tag}"

  # Fetch release info and find the matching asset download URL
  local json
  json="$(curl -fsS --retry 3 --connect-timeout 10 "${release_api}" 2>/dev/null || true)"
  if [ -z "$json" ]; then
    die "release tag '${tag}' not found on GitHub"
  fi

  # Extract browser_download_url for the matching asset name using python3 if available,
  # otherwise fall back to grep/sed.
  if command -v python3 >/dev/null 2>&1; then
    local url
    url="$(printf '%s' "$json" | python3 -c "
import sys, json
data = json.load(sys.stdin)
name = '${asset_name}'
for a in data.get('assets', []):
    if a.get('name') == name:
        print(a.get('browser_download_url', ''))
        break
" 2>/dev/null || true)"
    if [ -n "$url" ]; then
      echo "$url"
      return
    fi
  fi

  # Fallback: grep for the asset name and URL on adjacent lines
  local url=""
  url="$(printf '%s' "$json" | grep -B1 "${asset_name}" | grep 'browser_download_url' | head -n1 | sed -n 's/.*"browser_download_url": *"\([^"]*\)".*/\1/p')"
  if [ -z "$url" ]; then
    die "no release asset found for ${os}-${arch} in tag ${tag}"
  fi
  echo "$url"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  need_cmd curl
  need_cmd tar
  need_cmd install

  local os arch tag prefix force version
  os="$(detect_os)"
  arch="$(detect_arch)"
  tag="${CODIFY_VERSION:-latest}"
  prefix="${CODIFY_PREFIX:-$DEFAULT_PREFIX}"
  force="${CODIFY_FORCE:-0}"

  log "Installing Codify (${os}/${arch}) ..."

  # Resolve version if "latest"
  if [ "$tag" = "latest" ]; then
    tag="$(curl -fsS --retry 3 --connect-timeout 10 \
      "${API_BASE}/releases/latest" 2>/dev/null | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -n1)"
    if [ -z "$tag" ]; then
      die "could not determine latest release tag"
    fi
    log "Latest release: ${tag}"
  fi

  local url
  url="$(resolve_asset_url "$os" "$arch" "$tag")"
  log "Downloading: ${url}"

  local tmpdir
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT

  local archive="${tmpdir}/codify-pkg"
  case "$os" in
    windows) archive="${archive}.zip" ;;
    *)       archive="${archive}.tar.gz" ;;
  esac

  curl -fSsL --retry 3 --connect-timeout 10 -o "$archive" "$url"

  # Extract
  case "$os" in
    windows)
      need_cmd unzip
      unzip -o -q "$archive" -d "$tmpdir"
      ;;
    *)
      tar -xzf "$archive" -C "$tmpdir"
      ;;
  esac

  # Find the binary inside the extracted archive
  local binary=""
  binary="$(find "$tmpdir" -maxdepth 3 -type f \( -name "$BIN_NAME" -o -name "${BIN_NAME}.exe" \) 2>/dev/null | head -n1)"
  if [ -z "$binary" ]; then
    die "could not find '${BIN_NAME}' binary in the downloaded package"
  fi

  # Install
  mkdir -p "$prefix"
  local dest="${prefix}/${BIN_NAME}"
  case "$os" in
    windows) dest="${dest}.exe" ;;
  esac

  if [ -f "$dest" ] && [ "$force" != "1" ]; then
    die "${dest} already exists. Set CODIFY_FORCE=1 to overwrite."
  fi

  install -m 0755 "$binary" "$dest"
  log "Installed Codify to ${dest}"

  # PATH check
  case ":${PATH}:" in
    *":${prefix}:"*) ;;
    *)
      log ""
      log "NOTE: ${prefix} is not on your PATH. Add it to your shell profile:"
      log "  export PATH=\"${prefix}:\$PATH\""
      log ""
      ;;
  esac

  log "Run: codify --version"
  log "Get started: codify agent --api-key <YOUR_API_KEY>"
}

main "$@"
