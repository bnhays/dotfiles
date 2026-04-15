#!/bin/sh
set -eu

OS="$(uname -s)"
ARCH="$(uname -m)"

install_debian() {
  sudo apt update
  sudo apt install -y zsh git curl tar
}

install_macos() {
  if command -v brew >/dev/null 2>&1; then
    brew install zsh git curl
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

install_neovim() {
  mkdir -p "$HOME/.local/bin" "$HOME/.local/opt"
  TMPDIR="$(mktemp -d)"
  trap 'rm -rf "$TMPDIR"' EXIT

  case "$OS" in
    Linux)
      case "$ARCH" in
        x86_64) NVIM_URL="https://github.com/neovim/neovim-releases/releases/latest/download/nvim-linux-x86_64.tar.gz" ;;
        aarch64|arm64) NVIM_URL="https://github.com/neovim/neovim-releases/releases/latest/download/nvim-linux-arm64.tar.gz" ;;
        *) echo "Unsupported Linux architecture: $ARCH" >&2; return 1 ;;
      esac
      ;;
    Darwin)
      # Detect Apple Silicon even if the shell is running under Rosetta
      if sysctl -n hw.optional.arm64 2>/dev/null | grep -q '^1$'; then
        NVIM_URL="https://github.com/neovim/neovim-releases/releases/latest/download/nvim-macos-arm64.tar.gz"
      else
        NVIM_URL="https://github.com/neovim/neovim-releases/releases/latest/download/nvim-macos-x86_64.tar.gz"
      fi
      ;;
    *)
      echo "Unsupported OS: $OS" >&2
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

case "$OS" in
  Linux)
    if command -v apt >/dev/null 2>&1; then
      install_debian
    fi
    ;;
  Darwin)
    install_macos
    ;;
esac

install_oh_my_zsh
install_powerlevel10k
install_neovim
set_default_shell
