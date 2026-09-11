# Dotfiles Justfile — install, configure, manage

# List all available recipes
default:
  @just --list

# ──────────────────────────────────────────────
# Full setup
# ──────────────────────────────────────────────

# Full Fedora setup: stow + deps + setup
fedora: stow deps setup

# Full macOS setup: stow + deps + setup
macos: stow deps setup

# ──────────────────────────────────────────────
# Deployment
# ──────────────────────────────────────────────

# Symlink all configs via GNU Stow (removes conflicts)
stow:
  uv run python setup/main.py stow

# ──────────────────────────────────────────────
# Dependencies
# ──────────────────────────────────────────────

# Install all dependencies (auto-detects platform)
deps:
  uv run python setup/main.py install

# Show what would be installed (dry-run)
deps-dry:
  uv run python setup/main.py install --dry-run

# Check which deps are installed vs missing
deps-check:
  uv run python setup/main.py check

# List all managed deps
deps-list:
  uv run python setup/main.py list

# Platform-specific setup (nushell init, symlinks, etc.)
setup:
  uv run python setup/main.py setup

# Update all package managers
deps-update:
  uv run python setup/main.py update

# ──────────────────────────────────────────────
# Ansible (Fedora only)
# ──────────────────────────────────────────────

# Full provision via Ansible
provision:
  ansible-playbook -i inventory.yml playbook.yml --ask-become-pass

# Provision only specific tags
provision-tags tags:
  ansible-playbook -i inventory.yml playbook.yml --tags {{ tags }} --ask-become-pass

# ──────────────────────────────────────────────
# Services
# ──────────────────────────────────────────────

# Restart waybar
waybar-restart:
  pkill waybar; sleep 0.5; waybar &

# Reload waybar config
waybar-reload:
  pkill -USR1 waybar

# Restart swaync
swaync-restart:
  swaync-client -R && swaync-client -rs
