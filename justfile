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

# ──────────────────────────────────────────────
# Hyprland
# ──────────────────────────────────────────────

# Lint the Hyprland config (luacheck, else syntax check)
hypr-lint:
  just -f dot-config/hypr/justfile lint

# Run Hyprland config tests (unit + integration)
hypr-test:
  just -f dot-config/hypr/justfile test

# Apply the Hyprland config to the running compositor
hypr-reload:
  just -f dot-config/hypr/justfile reload

# Full Hyprland pre-commit check
hypr-check:
  just -f dot-config/hypr/justfile check

# ──────────────────────────────────────────────
# SwayNC
# ──────────────────────────────────────────────

# Regenerate swaync config.json + style.css from the domain models
swaync-generate:
  just -f dot-config/swaync/Justfile generate

# Full swaync pre-commit check (lint + typecheck + tests)
swaync-check:
  just -f dot-config/swaync/Justfile check
