#!/usr/bin/env bash
#
# codify-install.sh — Install the Codify CLI from GitLab releases.
#
# Usage:
#   macOS / Linux / Git Bash:
#     curl -fsSL https://gitlab.com/aayushpokhrel49/codify/-/raw/main/install.sh | bash
#
#   Windows PowerShell:
#     irm https://gitlab.com/aayushpokhrel49/codify/-/raw/main/install.ps1 | iex
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
GITLAB_URL="https://gitlab.com/${REPO}"
RAW_BASE="${GITLAB_URL}/-/raw/main"
API_BASE="https://gitlab.com/api/v4/projects/aayushpokhrel49%2Fcodify"

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

# Resolve the download URL for a given tag
resolve_asset_url() {
  local os="$1" arch="$2" tag="$3"
  local suffix
  case "$os" in
    linux)   suffix="tar.gz" ;;
    darwin)  suffix="tar.gz" ;;
    windows) suffix="zip" ;;
  esac

  # Try assets named: codify-<tag>-<os>-<arch>.<suffix>
  # GitLab release assets are fetched via the releases API.
  local release_api="${API_BASE}/releases/${tag}"
  local assets
  assets="$(curl -fsS --retry 3 --connect-timeout 10 "${release_api}" 2>/dev/null || true)"
  if [ -z "$assets" ]; then
    # Fallback: construct a direct generic URL
    echo "${GITLAB_URL}/-/releases/${tag}/downloads/codify-${tag}-${os}-${arch}.${suffix}"
    return
  fi

  # Extract the matching asset URL from the JSON (name + url fields)
  local name url found=""
  # Very small JSON parse: grep for asset objects whose name matches our suffix
  while IFS= read -r line; do
    case "$line" in
      *'"name"*:*'"codify-${tag}-${os}-${arch}."* )
        name="$(printf '%s' "$line" | sed -n 's/.*"name": *"\([^"]*\)".*/\1/p')"
        ;;
      *'"url"*:* )
        url="$(printf '%s' "$line" | sed -n 's/.*"url": *"\([^"]*\)".*/\1/p')"
        if [ -n "$name" ] && [ -n "$url" ]; then
          case "$name" in
            "codify-${tag}-${os}-${arch}."*) found="$url"; break ;;
          esac
          name=""
          url=""
        fi
        ;;
    esac
  done <<< "$assets"

  if [ -z "$found" ]; then
    die "no release asset found for ${os}-${arch} in tag ${tag}"
  fi
  echo "$found"
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
      "${API_BASE}/releases" 2>/dev/null | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -n1)"
    if [ -z "$tag" ]; then
      die "could not determine latest release tag"
    fi
    log "Latest release: ${tag}"
  fi

  # Strip leading 'v' if present for binary naming, but keep for API
  version="$tag"
  case "$version" in
    v*) version="${version#v}" ;;
  esac

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
  binary="$(find "$tmpdir" -maxdepth 3 -type f -name "$BIN_NAME" -o -name "${BIN_NAME}.exe" 2>/dev/null | head -n1)"
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
