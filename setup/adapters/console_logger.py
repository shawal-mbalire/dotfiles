import sys


class ConsoleLogger:
    COLORS = {
        "info": "\033[36m",      # cyan
        "success": "\033[32m",   # green
        "warning": "\033[33m",   # yellow
        "error": "\033[31m",     # red
        "dry_run": "\033[90m",   # gray
        "reset": "\033[0m",
    }

    def info(self, message: str) -> None:
        print(f"{self.COLORS['info']}{message}{self.COLORS['reset']}")

    def success(self, message: str) -> None:
        print(f"{self.COLORS['success']}{message}{self.COLORS['reset']}")

    def warning(self, message: str) -> None:
        print(f"{self.COLORS['warning']}{message}{self.COLORS['reset']}")

    def error(self, message: str) -> None:
        print(f"{self.COLORS['error']}{message}{self.COLORS['reset']}", file=sys.stderr)

    def dry_run(self, message: str) -> None:
        print(f"{self.COLORS['dry_run']}{message}{self.COLORS['reset']}")
