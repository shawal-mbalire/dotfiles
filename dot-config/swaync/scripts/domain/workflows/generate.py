"""Generate workflow: orchestrate builders and artifact writers.

Pure orchestration over injected ports. The composition root supplies the
adapters; this workflow knows nothing about files or JSON.
"""

from __future__ import annotations

from domain.models import GenerationResult, StyleSheet, SwayncConfig
from domain.ports.artifacts import ConfigWriter, StyleWriter
from domain.ports.core import Logger, TimePort
from domain.workflows import config as config_wf
from domain.workflows import theme as theme_wf


def build_all(config: object) -> tuple[SwayncConfig, StyleSheet]:
    """Build both artifacts without writing them (used by check/generate)."""
    return config_wf.build(config), theme_wf.build(config)


def generate(
    config: object,
    config_writer: ConfigWriter,
    style_writer: StyleWriter,
    logger: Logger,
    time: TimePort,
) -> GenerationResult:
    start = time.now_ms()

    model, sheet = build_all(config)
    config_writer.write_config(model)
    style_writer.write_style(sheet)

    result = GenerationResult(
        widgets=len(model.widgets),
        components=theme_wf.component_count(sheet),
        elapsed_ms=time.elapsed_ms(start),
    )
    logger.info(
        f"generated {result.widgets} widgets, {result.components} style components "
        f"in {result.elapsed_ms}ms"
    )
    return result
