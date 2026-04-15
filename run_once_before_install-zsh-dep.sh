#!/bin/sh
set -eu

OS="$(uname -s)"
ARCH="$(uname -m)"

install_debian() {
  sudo apt update
  sudo apt install -y zsh git curl tar unzip build-essential
}

install_macos() {
  if command -v brew >/dev/null 2>&1; then
    brew install zsh git curl neovim tree-sitter-cli
    brew upgrade neovim || true
    brew upgrade tree-sitter-cli || true
  fi
}

install_oh_my_zsh() {
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    git clone https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
  fi
}

install_powerlevel10k() {
  mkdir -p "$HOME/.oh-my-zsh/custom/themes"
  if [ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
    git clone --depth=1 \
      https://github.com/romkatv/powerlevel10k.git \
      "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
  fi
}

install_neovim_linux() {
  mkdir -p "$HOME/.local/bin" "$HOME/.local/opt"
  TMPDIR="$(mktemp -d)"
  trap 'rm -rf "$TMPDIR"' EXIT

  case "$ARCH" in
    x86_64)
      NVIM_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
      ;;
    aarch64|arm64)
      NVIM_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-arm64.tar.gz"
      ;;
    *)
      echo "Unsupported Linux architecture: $ARCH" >&2
      return 1
      ;;
  esac

  curl -fsSL "$NVIM_URL" -o "$TMPDIR/nvim.tar.gz"
  rm -rf "$HOME/.local/opt/nvim"
  tar -xzf "$TMPDIR/nvim.tar.gz" -C "$TMPDIR"

  EXTRACTED_DIR="$(find "$TMPDIR" -maxdepth 1 -type d -name 'nvim-*' | head -n 1)"
  if [ -z "$EXTRACTED_DIR" ]; then
    echo "Failed to find extracted Neovim directory" >&2
    return 1
  fi

  mv "$EXTRACTED_DIR" "$HOME/.local/opt/nvim"
  ln -sf "$HOME/.local/opt/nvim/bin/nvim" "$HOME/.local/bin/nvim"
}

install_tree_sitter_linux() {
  mkdir -p "$HOME/.local/bin" "$HOME/.local/opt"
  TMPDIR="$(mktemp -d)"
  trap 'rm -rf "$TMPDIR"' EXIT

  case "$ARCH" in
    x86_64)
      TS_URL="https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-cli-linux-x64.zip"
      ;;
    aarch64|arm64)
      TS_URL="https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-cli-linux-arm64.zip"
      ;;
    armv7l|armv6l)
      TS_URL="https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-cli-linux-arm.zip"
      ;;
    *)
      echo "Unsupported Linux architecture for tree-sitter: $ARCH" >&2
      return 1
      ;;
  esac

  curl -fsSL "$TS_URL" -o "$TMPDIR/tree-sitter.zip"
  rm -rf "$HOME/.local/opt/tree-sitter-cli"
  mkdir -p "$HOME/.local/opt/tree-sitter-cli"
  unzip -q "$TMPDIR/tree-sitter.zip" -d "$HOME/.local/opt/tree-sitter-cli"

  if [ ! -x "$HOME/.local/opt/tree-sitter-cli/tree-sitter" ]; then
    echo "Failed to install tree-sitter CLI" >&2
    return 1
  fi

  ln -sf "$HOME/.local/opt/tree-sitter-cli/tree-sitter" "$HOME/.local/bin/tree-sitter"
}

set_default_shell() {
  if command -v zsh >/dev/null 2>&1; then
    ZSH_PATH="$(command -v zsh)"
    CURRENT_SHELL="${SHELL:-}"
    if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
      if command -v chsh >/dev/null 2>&1; then
        chsh -s "$ZSH_PATH" || true
      fi
    fi
  fi
}

case "$OS" in
  Linux)
    if command -v apt >/dev/null 2>&1; then
      install_debian
      install_neovim_linux
      install_tree_sitter_linux
    fi
    ;;
  Darwin)
    install_macos
    ;;
  *)
    echo "Unsupported OS: $OS" >&2
    exit 1
    ;;
esac

install_oh_my_zsh
install_powerlevel10k
set_default_shell
