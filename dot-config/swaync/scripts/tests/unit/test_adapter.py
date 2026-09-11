import json

from adapters.swaync_adapter import SwayncArtifactWriter
from domain.workflows import config as config_wf
from domain.workflows import theme as theme_wf

from tests.fixtures.fakes import base_config


def test_writer_persists_valid_config_and_style(tmp_path):
    config = base_config()
    config_path = tmp_path / "config.json"
    style_path = tmp_path / "style.css"
    writer = SwayncArtifactWriter(config_path, style_path)

    writer.write_config(config_wf.build(config))
    writer.write_style(theme_wf.build(config))

    payload = json.loads(config_path.read_text(encoding="utf-8"))
    assert payload["widgets"] == [
        "mpris",
        "buttons-grid",
        "volume",
        "backlight",
        "notifications",
        "buttons-grid#clearbar",
    ]
    assert payload["widget-config"]["buttons-grid"]["buttons-per-row"] == 3

    css = style_path.read_text(encoding="utf-8")
    assert "@define-color" in css
    assert ".widget-buttons-grid flowboxchild > button" in css


def test_writer_leaves_no_temporary_files(tmp_path):
    config = base_config()
    writer = SwayncArtifactWriter(tmp_path / "config.json", tmp_path / "style.css")
    writer.write_config(config_wf.build(config))
    writer.write_style(theme_wf.build(config))
    assert not list(tmp_path.glob("*.tmp"))
