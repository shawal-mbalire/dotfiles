"""Wall-clock ``TimePort`` adapter."""

from __future__ import annotations

import time
from datetime import datetime


class SystemTime:
    def now_ms(self) -> int:
        return int(time.time() * 1000)

    def elapsed_ms(self, start_ms: int) -> int:
        return self.now_ms() - start_ms

    def now(self) -> datetime:
        return datetime.now()
