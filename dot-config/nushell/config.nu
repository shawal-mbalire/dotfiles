# Nushell Configuration
# Migrated from Fish configuration

# =============================================================================
# Environment & Path Configuration
# =============================================================================

# Add directories to PATH if they exist
$env.PATH = ($env.PATH | split row (char esep) | prepend [
    ($env.HOME | path join ".local" "bin")
    ($env.HOME | path join ".bun" "bin")
    ($env.HOME | path join ".opencode" "bin")
    ($env.HOME | path join ".lmstudio" "bin")
    "/home/linuxbrew/.linuxbrew/bin"
    "/home/linuxbrew/.linuxbrew/sbin"
] | uniq)

# Conditional PATH additions
let antigravity_path = "/Users/shawalmbalire/.antigravity/antigravity/bin"
if ($antigravity_path | path exists) {
    $env.PATH = ($env.PATH | prepend $antigravity_path)
}

# Editor configuration
$env.EDITOR = "nvim"
$env.VISUAL = "nvim"

# Theme configuration
$env.GTK_THEME = "BreezeDark"

# =============================================================================
# Shell Configuration
# =============================================================================

$env.config = {
    show_banner: false,
    edit_mode: "vi",
    cursor_shape: {
        vi_insert: "line",
        vi_normal: "block",
    },
    # shell_integration: true, # removed as it requires a record in newer versions
    buffer_editor: "nvim",
    
    # Rich Color Configuration (Fish-like)
    color_config: {
        # Syntax Highlighting
        separator: white
        leading_trailing_space_bg: { attr: n }
        header: green_bold
        empty: blue
        bool: {|| if $in { 'light_cyan' } else { 'light_gray' } }
        int: white
        filesize: cyan
        duration: white
        date: {|| (date now) - $in |
            if $in < 1hr { 'purple'
            } else if $in < 6hr { 'red'
            } else if $in < 1day { 'yellow'
            } else { 'white' }
        }
        range: white
        float: white
        string: yellow
        nothing: white
        binary: white
        cellpath: white
        row_index: green_bold
        record: white
        list: white
        block: white
        hints: dark_gray
        search_result: { bg: red fg: white }

        # Command Line Syntax (Shapes)
        shape_and: purple_bold
        shape_binary: purple_bold
        shape_block: blue_bold
        shape_bool: light_cyan
        shape_closure: green_bold
        shape_custom: green
        shape_datetime: cyan_bold
        shape_directory: cyan
        shape_external: cyan
        shape_external_resolved: light_cyan_bold
        shape_filepath: cyan
        shape_flag: blue_bold
        shape_float: purple_bold
        shape_garbage: { fg: white bg: red attr: b }
        shape_globpattern: cyan_bold
        shape_int: purple_bold
        shape_internalcall: cyan_bold
        shape_keyword: purple_bold
        shape_list: cyan_bold
        shape_literal: blue
        shape_match_pattern: green
        shape_matching_brackets: { attr: u }
        shape_nothing: light_cyan
        shape_operator: yellow
        shape_or: purple_bold
        shape_pipe: purple_bold
        shape_range: yellow_bold
        shape_record: cyan_bold
        shape_redirection: purple_bold
        shape_signature: green_bold
        shape_string: yellow
        shape_string_interpolation: cyan_bold
        shape_table: blue_bold
        shape_variable: purple
        shape_vardecl: purple
    }
}

# =============================================================================
# Aliases & Abbreviations
# =============================================================================

alias vi = nvim
alias vim = nvim

# Git aliases
alias gits = git status
alias gitc = git commit
alias gita = git add
alias gitd = git diff
alias gitl = git log --oneline
alias gitp = git push
alias gitpl = git pull

# General aliases
alias ll = ls -la
alias la = ls -a
alias l = ls -l

# =============================================================================
# Prompt Configuration (Pure-inspired)
# =============================================================================

# Colors (local variables, not env vars)
let pure_color_primary = "blue"
let pure_color_info = "cyan"
let pure_color_mute = "white"
let pure_color_success = "green"
let pure_color_danger = "red"
let pure_color_warning = "yellow"

# Prompt function
$env.PROMPT_COMMAND = { ||
    let dir = (
        if ($env.PWD | str starts-with $env.HOME) {
            ($env.PWD | str replace $env.HOME "~")
        } else {
            $env.PWD
        }
    )
    
    let path_segment = $"(ansi $pure_color_primary)($dir)(ansi reset)"
    
    # Git branch logic with error handling
    let git_branch = (do -i { git branch --show-current err> /dev/null } | str trim)
    let git_segment = if ($git_branch != "") {
        $"(ansi $pure_color_info) ($git_branch)(ansi reset)"
    } else {
        ""
    }
    
    let user_host = if ("SSH_CONNECTION" in $env) {
        $"(ansi $pure_color_mute)($env.USER)@($env.HOSTNAME) (ansi reset)"
    } else {
        ""
    }
    
    $"($user_host)($path_segment)($git_segment) (ansi $pure_color_primary)❯(ansi $pure_color_info)❯(ansi $pure_color_mute)❯ (ansi reset)"
}

$env.PROMPT_COMMAND_RIGHT = { || "" }

# Remove default indicators to prevent extra characters (like colons in vi mode)
$env.PROMPT_INDICATOR = {|| "" }
$env.PROMPT_INDICATOR_VI_INSERT = {|| "" }
$env.PROMPT_INDICATOR_VI_NORMAL = {|| "" }
$env.PROMPT_MULTILINE_INDICATOR = {|| "::: " }

# =============================================================================
# Tool Integrations
# =============================================================================

# Zoxide
source ~/.config/nushell/zoxide.nu

# Carapace
source ~/.config/nushell/carapace.nu
