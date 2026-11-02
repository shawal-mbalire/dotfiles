#!/usr/bin/env nu
# Fedora/macOS + dev cleaner (mole-like). `nu clean.nu` = report only, `nu clean.nu --run` = delete.
def sz [p: string] { if ($p | path exists) { try { du $p | get apparent | math sum } catch { 0b } } else { 0b } }
def main [--run (-r)] {
  let h = $env.HOME
  let dirs = [
    ".cache" ".local/share/Trash/files" ".local/share/Trash/info" ".npm/_cacache" ".bun/install/cache"
    ".gradle/caches" ".gradle/daemon" ".cargo/registry" ".cargo/git" "go/pkg/mod/cache" ".m2/repository"
    ".gemini/tmp" ".gemini/antigravity-cli/brain/scratch" ".claude/shell-snapshots" ".claude/statsig" ".claude/todos"
    ".codex/log" ".codex/tmp" ".cursor/extensions/.obsolete" ".config/Cursor/Cache" ".config/Cursor/CachedData"
    ".config/Code/Cache" ".config/Code/CachedData" ".config/Code/logs" ".config/opencode/cache"
  ] ++ (if $nu.os-info.name == "macos" { ["Library/Caches" "Library/Logs" ".Trash" "Library/Developer/Xcode/DerivedData" "Library/Developer/Xcode/Archives"] } else { [] }) | each {|d| $h | path join $d }
  let found = $dirs | each {|d| {path: $d, size: (sz $d)} } | where size > 0b | sort-by size -r
  print $found
  print $"Reclaimable in user dirs: ($found | get size | math sum)"
  print "Largest files (>200MB) in ~:"; try { (^find $h -xdev -type f -size +200M | complete | get stdout) | lines | each {|f| {size: (ls -D $f | get 0.size), file: $f} } | sort-by size -r | first 15 | print }
  if not $run { print "Dry run. Re-run with --run to clean (also dnf, journal, docker, podman, flatpak)."; return }
  $found | get path | each {|d| try { rm -rf $d } }
  if $nu.os-info.name == "linux" {
    sudo -v; print "Cleaning dnf, coredumps & journal..."
    sudo dnf clean all -q; sudo dnf autoremove -y -q; sudo rm -rf /var/lib/systemd/coredump/* /var/tmp/abrt/*
    sudo journalctl --vacuum-time=7d o+e> /dev/null
  }
  if (which docker | is-not-empty) { print "Pruning docker..."; docker system prune -af o+e> /dev/null }
  if (which podman | is-not-empty) { print "Pruning podman..."; podman system prune -af o+e> /dev/null }
  if (which flatpak | is-not-empty) { print "Pruning flatpak..."; flatpak uninstall --unused -y o+e> /dev/null }
  if (which brew | is-not-empty) { print "Pruning brew..."; brew cleanup --prune=all -s -q o+e> /dev/null }
  print "Done."
}
