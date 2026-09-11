#!/usr/bin/python3 -S
"""SwayNC config generator — composition root.

Reads config, creates adapters, verifies them against the domain ports and runs
the generate workflow. SwayNC reads the static files this produces; the hexagon
is the code that writes them.

Usage:
  main.py generate [--reload]   Write config.json and style.css
  main.py check                 Fail if the on-disk artifacts are stale
  main.py reload                Reload the running swaync session
  main.py print <config|style>  Print a generated artifact to stdout
"""

# ruff: noqa: E402
# Imports below intentionally follow the sys.path bootstrap so the script is
# importable both as `python scripts/main.py` and as `import main` in tests.

from __future__ import annotations

import os
import sys

SCRIPTS_DIR = os.path.dirname(os.path.abspath(__file__))
if SCRIPTS_DIR not in sys.path:
    sys.path.insert(0, SCRIPTS_DIR)

from adapters import swaync_mappings as mappings
from adapters.console_logger import ConsoleLogger
from adapters.subprocess_commands import SubprocessCommands
from adapters.swaync_adapter import SwayncArtifactWriter
from adapters.system_time import SystemTime
from domain import errors
from domain.ports import verify
from domain.workflows import generate as generate_wf
from infra.config import Config, load_config

CONFIG_NAME = "config.json"
STYLE_NAME = "style.css"


def _wire(
    config: Config,
) -> tuple[SwayncArtifactWriter, ConsoleLogger, SystemTime, SubprocessCommands]:
    logger = ConsoleLogger(config.log_level)
    time = SystemTime()
    commands = SubprocessCommands()
    writer = SwayncArtifactWriter(
        config.output_dir / CONFIG_NAME,
        config.output_dir / STYLE_NAME,
    )

    # Fail loud if any adapter drifts from its port contract.
    verify.assert_port(logger, verify.Logger)
    verify.assert_port(time, verify.TimePort)
    verify.assert_port(writer, verify.ConfigWriter)
    verify.assert_port(writer, verify.StyleWriter)
    verify.assert_port(commands, verify.CommandRunner)

    return writer, logger, time, commands


def cmd_generate(argv: list[str]) -> int:
    reload = "--reload" in argv or "-r" in argv
    config = load_config()
    writer, logger, time, commands = _wire(config)

    generate_wf.generate(config, writer, writer, logger, time)
    logger.debug(f"wrote {config.output_dir / CONFIG_NAME} and {config.output_dir / STYLE_NAME}")

    if reload:
        code = commands.run(config.reload_command)
        if code != 0:
            logger.error(f"reload failed with exit code {code}: {config.reload_command}")
            return 1
        logger.info("swaync reloaded")
    return 0


def cmd_check(_argv: list[str]) -> int:
    config = load_config()
    model, sheet = generate_wf.build_all(config)
    expected = {
        CONFIG_NAME: mappings.config_to_json(model),
        STYLE_NAME: mappings.stylesheet_to_css(sheet),
    }

    failed = 0
    for name, text in expected.items():
        path = config.output_dir / name
        if not path.exists():
            print(f"missing: {path}")
            failed += 1
            continue
        if path.read_text(encoding="utf-8") != text:
            print(f"stale:   {path} (run 'just generate')")
            failed += 1
            continue
        print(f"ok:      {path}")
    return 1 if failed else 0


def cmd_reload(_argv: list[str]) -> int:
    config = load_config()
    commands = SubprocessCommands()
    code = commands.run(config.reload_command)
    if code != 0:
        print(f"reload failed with exit code {code}", file=sys.stderr)
    return code


def cmd_print(argv: list[str]) -> int:
    target = argv[0] if argv else ""
    config = load_config()
    model, sheet = generate_wf.build_all(config)
    if target == "config":
        print(mappings.config_to_json(model), end="")
        return 0
    if target == "style":
        print(mappings.stylesheet_to_css(sheet), end="")
        return 0
    print("usage: main.py print {config|style}", file=sys.stderr)
    return 1


HANDLERS = {
    "generate": cmd_generate,
    "build": cmd_generate,
    "check": cmd_check,
    "reload": cmd_reload,
    "print": cmd_print,
}


def main(argv: list[str]) -> int:
    if len(argv) < 2 or argv[1] in ("-h", "--help", "help"):
        print(__doc__.strip())
        return 0 if len(argv) > 1 else 1

    handler = HANDLERS.get(argv[1])
    if handler is None:
        print(f"Unknown command: {argv[1]}", file=sys.stderr)
        return 1

    try:
        return handler(argv[2:])
    except errors.SwayncError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
