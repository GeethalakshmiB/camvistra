"""Process CPU/memory sampling interface (port of ISystemMetricsProvider.h)."""

from __future__ import annotations

import abc


class ISystemMetricsProvider(abc.ABC):
    @abc.abstractmethod
    def get_cpu_percent(self) -> float:
        """Process CPU usage since the previous call, normalised across all
        logical cores (0-100). The first call has no baseline and returns 0."""

    @abc.abstractmethod
    def get_memory_bytes(self) -> int:
        """Process resident/working-set memory, in bytes, at the time of call."""
