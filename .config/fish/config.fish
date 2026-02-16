# ============================================================================
# 12-Factor Fish Configuration
# ============================================================================
# - Configuration via environment variables
# - Explicit dependency declarations
# - Portable across environments
# ============================================================================

# Environment Variables (12-Factor: Config)
# ============================================================================
# Set defaults only if not already defined in environment

# Editor configuration
set -q EDITOR; or set -gx EDITOR /usr/bin/nvim
set -q VISUAL; or set -gx VISUAL nvim

# Theme configuration
set -q GTK_THEME; or set -gx GTK_THEME BreezeDark

# Disable greeting by default
set -q fish_greeting; or set fish_greeting ''

# Path Management (12-Factor: Dependencies)
# ============================================================================
# Explicitly declare all binary paths

# User local binaries
test -d $HOME/.local/bin; and fish_add_path $HOME/.local/bin

# Bun runtime
set -q BUN_INSTALL; or set -gx BUN_INSTALL "$HOME/.bun"
test -d $BUN_INSTALL/bin; and fish_add_path $BUN_INSTALL/bin

# OpenCode
test -d $HOME/.opencode/bin; and fish_add_path $HOME/.opencode/bin

# Antigravity (conditional on OS/environment)
test -d /Users/shawalmbalire/.antigravity/antigravity/bin; and fish_add_path /Users/shawalmbalire/.antigravity/antigravity/bin

# Interactive Shell Configuration
# ============================================================================
if status is-interactive
    # VI Key Bindings
    fish_vi_key_bindings insert
    set fish_cursor_default block
    set fish_cursor_visual block

    # Tool Integrations (12-Factor: Dependencies)
    # Initialize only if tools are available
    type -q zoxide; and zoxide init fish | source
    type -q atuin; and atuin init fish | source

    # Abbreviations (12-Factor: Dev/Prod Parity)
    # Define shortcuts consistently across environments
    abbr --add --global vi nvim
    abbr --add --global vim nvim
    abbr --add --global gits 'git status'
    abbr --add --global gitc 'git commit'
    abbr --add --global gita 'git add'
    abbr --add --global gitd 'git diff'
    abbr --add --global gitl 'git log --oneline'
    abbr --add --global gitp 'git push'
    abbr --add --global gitpl 'git pull'
    abbr --add --global ll 'ls -la'

    ## aliases
    alias vim='nvim'

    # Prompt Configuration (12-Factor: Config)
    # Pure prompt colors - override via environment if needed
    set -q PURE_COLOR_PRIMARY; or set -g pure_color_primary blue
    set -q PURE_COLOR_INFO; or set -g pure_color_info cyan
    set -q PURE_COLOR_MUTE; or set -g pure_color_mute white
    set -q PURE_COLOR_SUCCESS; or set -g pure_color_success green
    set -q PURE_COLOR_DANGER; or set -g pure_color_danger red
    set -q PURE_COLOR_WARNING; or set -g pure_color_warning yellow
end
