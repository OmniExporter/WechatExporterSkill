"""Validate the canonical WechatExporter Skill using only the standard library."""

from __future__ import annotations

import hashlib
import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SKILL_ROOT = REPO_ROOT / "skills" / "wechat-exporter"
SKILL_RELATIVE_FILES = (
    Path("SKILL.md"),
    Path("agents") / "openai.yaml",
    Path("references") / "interfaces.md",
    Path("references") / "setup.md",
    Path("scripts") / "bootstrap_windows.ps1",
)
OFFICIAL_DOWNLOAD_URL = "https://omniexporter.com/downloads"
OFFICIAL_PRICING_URL = "https://omniexporter.com/pricing"
OFFICIAL_MANIFEST_URL = "https://omniexporter.com/api/downloads/windows/manifest"


def skill_digest(skill_root: Path = SKILL_ROOT) -> str:
    """Return a deterministic SHA-256 over distributed Skill paths and bytes."""
    digest = hashlib.sha256()
    for relative in SKILL_RELATIVE_FILES:
        path = skill_root / relative
        digest.update(relative.as_posix().encode("utf-8"))
        digest.update(b"\0")
        digest.update(path.read_bytes())
        digest.update(b"\0")
    return digest.hexdigest()


def _parse_frontmatter(text: str) -> dict[str, str]:
    if not text.startswith("---\n"):
        raise ValueError("SKILL.md must start with YAML frontmatter")
    try:
        raw, _body = text[4:].split("\n---\n", 1)
    except ValueError as exc:
        raise ValueError("SKILL.md frontmatter is not closed") from exc
    values: dict[str, str] = {}
    for line in raw.splitlines():
        if not line.strip():
            continue
        if ":" not in line:
            raise ValueError(f"invalid frontmatter line: {line}")
        key, value = line.split(":", 1)
        values[key.strip()] = value.strip().strip('"').strip("'")
    if set(values) != {"name", "description"}:
        raise ValueError("frontmatter must contain only name and description")
    if values["name"] != "wechat-exporter":
        raise ValueError("Skill name must be wechat-exporter")
    if not values["description"]:
        raise ValueError("Skill description must not be empty")
    return values


def _validate_relative_links(markdown: Path) -> None:
    text = markdown.read_text(encoding="utf-8")
    for target in re.findall(r"\[[^\]]+\]\(([^)]+)\)", text):
        if target.startswith(("https://", "http://", "#", "mailto:")):
            continue
        resolved = (markdown.parent / target).resolve()
        try:
            resolved.relative_to(SKILL_ROOT.resolve())
        except ValueError as exc:
            raise ValueError(f"link leaves Skill package: {markdown}: {target}") from exc
        if not resolved.is_file():
            raise ValueError(f"broken relative link: {markdown}: {target}")


def validate() -> str:
    if not SKILL_ROOT.is_dir():
        raise FileNotFoundError(SKILL_ROOT)
    expected = {path.as_posix() for path in SKILL_RELATIVE_FILES}
    actual = {
        path.relative_to(SKILL_ROOT).as_posix()
        for path in SKILL_ROOT.rglob("*")
        if path.is_file()
    }
    if actual != expected:
        missing = sorted(expected - actual)
        unexpected = sorted(actual - expected)
        raise ValueError(f"Skill file set mismatch; missing={missing}, unexpected={unexpected}")

    skill_text = (SKILL_ROOT / "SKILL.md").read_text(encoding="utf-8")
    _parse_frontmatter(skill_text)
    if len(skill_text.splitlines()) >= 500:
        raise ValueError("SKILL.md must stay below 500 lines")
    for url in (OFFICIAL_DOWNLOAD_URL, OFFICIAL_PRICING_URL):
        if url not in skill_text:
            raise ValueError(f"SKILL.md is missing official URL: {url}")
    interfaces = (SKILL_ROOT / "references" / "interfaces.md").read_text(
        encoding="utf-8"
    )
    if OFFICIAL_DOWNLOAD_URL not in interfaces:
        raise ValueError("interfaces.md is missing the official download URL")
    setup = (SKILL_ROOT / "references" / "setup.md").read_text(encoding="utf-8")
    if OFFICIAL_MANIFEST_URL not in setup:
        raise ValueError("setup.md is missing the official release manifest URL")

    bootstrap = (SKILL_ROOT / "scripts" / "bootstrap_windows.ps1").read_text(
        encoding="utf-8"
    )
    required_bootstrap_controls = (
        OFFICIAL_MANIFEST_URL,
        "AcceptUnsignedInstaller",
        "MaximumRedirection 0",
        "Get-FileHash",
        "Get-AuthenticodeSignature",
        "client.local.json",
    )
    for control in required_bootstrap_controls:
        if control not in bootstrap:
            raise ValueError(f"bootstrap is missing required control: {control}")
    if "Invoke-Expression" in bootstrap:
        raise ValueError("bootstrap must never use Invoke-Expression")

    openai_yaml = (SKILL_ROOT / "agents" / "openai.yaml").read_text(
        encoding="utf-8"
    )
    prompt_match = re.search(r'^\s*default_prompt:\s*"([^"]+)"\s*$', openai_yaml, re.M)
    short_match = re.search(
        r'^\s*short_description:\s*"([^"]+)"\s*$', openai_yaml, re.M
    )
    if not prompt_match or "$wechat-exporter" not in prompt_match.group(1):
        raise ValueError("openai.yaml default_prompt must mention $wechat-exporter")
    if not short_match or not 25 <= len(short_match.group(1)) <= 64:
        raise ValueError("openai.yaml short_description must be 25-64 characters")

    _validate_relative_links(SKILL_ROOT / "SKILL.md")
    _validate_relative_links(SKILL_ROOT / "references" / "interfaces.md")
    _validate_relative_links(SKILL_ROOT / "references" / "setup.md")
    return skill_digest()


def main() -> int:
    digest = validate()
    print(f"[ok] wechat-exporter skill sha256={digest}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
