from pathlib import Path
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]


def read(path: str, encoding: str = "utf-8") -> str:
    return (ROOT / path).read_text(encoding=encoding)


def main() -> None:
    mcm = read("gamedata/scripts/z_heatvision_mcm.script")
    runtime = read("gamedata/scripts/z_heatvision.script")
    shader = read("gamedata/shaders/r3/infrared.h")
    ru_path = ROOT / "gamedata/configs/text/rus/heatvision_tweaks_mcm.xml"
    en = read("gamedata/configs/text/eng/heatvision_tweaks_mcm.xml")
    ru_bytes = ru_path.read_bytes()
    assert not ru_bytes.startswith((b"\xef\xbb\xbf", b"\xff\xfe", b"\xfe\xff"))
    ru = ru_bytes.decode("cp1251")
    ET.fromstring(ru_bytes)
    ET.fromstring((ROOT / "gamedata/configs/text/eng/heatvision_tweaks_mcm.xml").read_bytes())

    key = "green_channel_weight_mcm"
    label = f"ui_mcm_heatvision_{key}"
    desc = f"{label}_desc"
    assert key in mcm
    assert 'min=0,max=1,step=0.05, def = 0.25' in mcm
    assert f'get_config("{key}")' in runtime
    assert "heatvision_params4.z" in shader
    assert "GREEN_CHANNEL_WEIGHT" not in shader
    assert 'encoding="windows-1251"' in ru
    assert 'encoding="utf-8"' in en
    for text in (ru, en):
        assert label in text
        assert desc in text
    assert "Рџ" not in ru and "Рµ" not in ru and "�" not in ru
    print("HeatVision Tweaks static checks: OK")


if __name__ == "__main__":
    main()

