"""Desktop entry parsing — pure freedesktop.org helpers.

No I/O here: functions take text and return data, so they are trivially
testable. The launcher adapter owns reading files and spawning processes.
"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class RawEntry:
    entry_id: str
    name: str = ""
    generic_name: str = ""
    comment: str = ""
    keywords: tuple[str, ...] = ()
    icon: str = ""
    exec_line: str = ""
    terminal: bool = False
    type: str = ""
    no_display: bool = False
    hidden: bool = False
    try_exec: str = ""


def _parse_bool(value: str) -> bool:
    return value.strip().lower() == "true"


def parse_desktop_entry(text: str, entry_id: str) -> RawEntry | None:
    """Parse a ``.desktop`` file body. Returns None if not a desktop entry."""
    in_group = False
    found_group = False
    fields: dict[str, str] = {}
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("[") and line.endswith("]"):
            group = line[1:-1]
            in_group = group == "Desktop Entry"
            found_group = found_group or in_group
            continue
        if not in_group or "=" not in line:
            continue
        key, _, value = line.partition("=")
        fields[key.strip()] = value.strip()

    if not found_group:
        return None

    keywords = tuple(part for part in fields.get("Keywords", "").split(";") if part)
    return RawEntry(
        entry_id=entry_id,
        name=fields.get("Name", ""),
        generic_name=fields.get("GenericName", ""),
        comment=fields.get("Comment", ""),
        keywords=keywords,
        icon=fields.get("Icon", ""),
        exec_line=fields.get("Exec", ""),
        terminal=_parse_bool(fields.get("Terminal", "false")),
        type=fields.get("Type", ""),
        no_display=_parse_bool(fields.get("NoDisplay", "false")),
        hidden=_parse_bool(fields.get("Hidden", "false")),
        try_exec=fields.get("TryExec", ""),
    )


def is_displayable(entry: RawEntry) -> bool:
    """A launchable, visible application entry."""
    return (
        entry.type == "Application"
        and not entry.no_display
        and not entry.hidden
        and entry.name != ""
        and entry.exec_line != ""
    )


def tokenize_exec(exec_line: str) -> list[str]:
    """Split an Exec line into argv per the desktop-entry quoting rules.

    Handles double quotes and backslash escapes; field codes (``%f`` etc.) are
    dropped, and ``%%`` becomes a literal ``%``.
    """
    args: list[str] = []
    current: list[str] = []
    in_quotes = False
    index = 0
    length = len(exec_line)
    while index < length:
        char = exec_line[index]
        if char == "\\" and index + 1 < length:
            current.append(exec_line[index + 1])
            index += 2
            continue
        if char == '"':
            in_quotes = not in_quotes
            index += 1
            continue
        if char == "%" and index + 1 < length:
            code = exec_line[index + 1]
            if code == "%":
                current.append("%")
            index += 2
            continue
        if char.isspace() and not in_quotes:
            if current:
                args.append("".join(current))
                current = []
            index += 1
            continue
        current.append(char)
        index += 1
    if current:
        args.append("".join(current))
    return args


def build_launch_argv(
    exec_line: str, *, terminal: bool, terminal_command: tuple[str, ...]
) -> list[str]:
    """Build the argv used to launch an entry, applying the terminal wrapper."""
    argv = tokenize_exec(exec_line)
    if terminal and terminal_command:
        return [*terminal_command, *argv]
    return argv
