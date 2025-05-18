# Dotfiles
## Installation

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/jufeic/dotfiles/refs/heads/main/install.sh)"
```

## SSH configuration
```bash
ssh-keygen -t ed25519 -f '<path_to_private_key>' -C "$(id -un)@$(hostname -s)"
git config --file ~/.gitconfig.local user.signingkey '<path_to_private_key>'
```

## Supported platforms
- macOS
- Linux (WSL)

## Prerequisites for macOS
- VS Code
- git
- curl

## Prerequisites for WSL
- VS Code
- git
- curl
- permissions to create symlinks for non-admin user
- WSL 2
- auto-mount of fixed drives enabled
