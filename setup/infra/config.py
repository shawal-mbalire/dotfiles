from pathlib import Path
from dataclasses import dataclass
from domain.models.package import Package

HOME = Path.home()


@dataclass(frozen=True)
class CoprRepo:
    name: str
    owner: str

    @property
    def enable_cmd(self) -> str:
        return f"sudo dnf copr enable {self.owner}/{self.name} -y"


COPR_REPOS = {
    "swaync": CoprRepo(name="SwayNotificationCenter", owner="erikreider"),
    "hyprland": CoprRepo(name="Hyprland", owner="lionheartp"),
    "hyprlock": CoprRepo(name="Hyprland", owner="lionheartp"),
    "hypridle": CoprRepo(name="Hyprland", owner="lionheartp"),
    "hyprpaper": CoprRepo(name="Hyprland", owner="lionheartp"),
    "hyprpolkitagent": CoprRepo(name="Hyprland", owner="lionheartp"),
    "hyprsunset": CoprRepo(name="Hyprland", owner="lionheartp"),
}

PACKAGES = [
    # ── Core ────────────────────────────────────────────────────────────────
    Package(name="fish",      dnf="fish",      brew="fish"),
    Package(name="kitty",     dnf="kitty",     brew="kitty"),
    Package(name="tmux",      dnf="tmux",      brew="tmux"),
    Package(name="git",       dnf="git",       brew="git"),
    Package(name="lazygit",   dnf="lazygit",   brew="lazygit"),
    Package(name="neovim",    dnf="neovim",    brew="neovim"),
    Package(name="python3",   dnf="python3",   brew="python"),
    Package(name="just",      dnf="just",      brew="just"),
    Package(name="stow",      dnf="stow",      brew="stow"),

    # ── Hyprland ────────────────────────────────────────────────────────────
    Package(name="hyprland",        dnf="hyprland",        copr="lionheartp/Hyprland"),
    Package(name="hyprlock",        dnf="hyprlock",        copr="lionheartp/Hyprland"),
    Package(name="hypridle",        dnf="hypridle",        copr="lionheartp/Hyprland"),
    Package(name="hyprpaper",       dnf="hyprpaper",       copr="lionheartp/Hyprland",
             user="cargo install --git https://github.com/hyprwm/hyprpaper.git"),
    Package(name="hyprpolkitagent", dnf="hyprpolkitagent", copr="lionheartp/Hyprland"),
    Package(name="hyprsunset",      dnf="hyprsunset",      copr="lionheartp/Hyprland"),

    # ── Desktop ─────────────────────────────────────────────────────────────
    Package(name="waybar",      dnf="waybar"),
    Package(name="swaync",      dnf="swaync",      copr="erikreider/SwayNotificationCenter"),
    Package(name="fuzzel",      dnf="fuzzel"),
    Package(name="wl-clipboard", dnf="wl-clipboard", brew="wl-clipboard"),
    Package(name="cliphist",    dnf="cliphist"),
    Package(name="grimblast",   dnf="grimblast"),
    Package(name="gammastep",   dnf="gammastep",   brew="gammastep"),
    Package(name="brightnessctl", dnf="brightnessctl", brew="brightnessctl"),
    Package(name="playerctl",   dnf="playerctl",   brew="playerctl"),
    Package(name="pavucontrol", dnf="pavucontrol", brew="pavucontrol"),
    Package(name="NetworkManager-applet", dnf="network-manager-applet"),
    Package(name="blueman",     dnf="blueman"),
    Package(name="nautilus",    dnf="nautilus"),

    # ── Fonts ───────────────────────────────────────────────────────────────
    Package(name="jetbrains-mono", dnf="jetbrains-mono-fonts",
             brew="font-jetbrains-mono-nerd"),
    Package(name="sono", brew="font-sono"),

    # ── Dev ─────────────────────────────────────────────────────────────────
    Package(name="lua",        dnf="lua",        brew="lua"),
    Package(name="lua-devel",  dnf="lua-devel"),
    Package(name="luarocks",   dnf="luarocks",   brew="luarocks"),
    Package(name="go",         dnf="golang",     brew="go"),
    Package(name="nodejs",     dnf="nodejs",     brew="node"),
    Package(name="npm",        dnf="nodejs",     brew="npm"),

    # ── Utils ───────────────────────────────────────────────────────────────
    Package(name="jq",      dnf="jq",      brew="jq"),
    Package(name="ripgrep", dnf="ripgrep", brew="ripgrep",
             user="cargo install ripgrep", bin="rg"),
    Package(name="fd-find", dnf="fd-find", brew="fd",
             user="cargo install fd-find", bin="fd"),
    Package(name="unzip",   dnf="unzip",   brew="unzip"),
    Package(name="curl",    dnf="curl",    brew="curl"),
    Package(name="wget",    dnf="wget",    brew="wget"),

    # ── Flatpak-only apps ──────────────────────────────────────────────────
    Package(name="zen-browser", flatpak="app.zen_browser.zen"),
    Package(name="slack",       flatpak="com.slack.Slack"),
    Package(name="obsidian",    flatpak="md.obsidian.Obsidian"),

    # ── User / cargo / pipx / curl (no dnf/brew/flatpak) ──────────────────
    Package(name="rustup", bin="rustup",
             user="curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"),
    Package(name="starship", bin="starship",
             user="curl -sS https://starship.rs/install.sh | sh -s -- --yes"),
    Package(name="atuin", bin="atuin",
             user="curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh | bash"),
    Package(name="carapace", bin="carapace",
             user="curl -sS https://carapace.dev/setup.sh | bash"),
    Package(name="zoxide", bin="zoxide",
             user="curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh"),
    Package(name="fzf", bin="fzf",
             user=f"git clone --depth 1 https://github.com/junegunn/fzf.git {HOME}/.fzf && {HOME}/.fzf/install --bin"),
    Package(name="btop",   dnf="btop",   brew="btop",
             user="cargo install btop"),
    Package(name="dust",   dnf="du-dust", brew="du-dust",
             user="cargo install du-dust"),
    Package(name="bat",    dnf="bat",    brew="bat",
             user="cargo install bat"),
    Package(name="delta",  dnf="git-delta", brew="git-delta",
             user="cargo install git-delta"),
    Package(name="pipx",   dnf="pipx",   brew="pipx",
             user="pip3 install --user pipx && pipx ensurepath"),
    Package(name="yt-dlp", dnf="yt-dlp", brew="yt-dlp",
             user="pipx install yt-dlp"),
    Package(name="tldr",    dnf="tldr",    brew="tlrc",
             user="pipx install tlrc"),
]
