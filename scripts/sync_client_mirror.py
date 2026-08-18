"""Synchronize or verify the generated Skill mirror in the Windows client."""

from __future__ import annotations

import argparse
import shutil
from pathlib import Path

from validate_skill import REPO_ROOT, SKILL_RELATIVE_FILES, SKILL_ROOT, validate


def _resolve_client_root(value: str | None) -> Path:
    return (
        Path(value).expanduser().resolve()
        if value
        else (REPO_ROOT.parent / "WechatExporterWinClient-py").resolve()
    )


def _paths(client_root: Path) -> tuple[Path, Path]:
    mirror = client_root / ".agents" / "skills" / "wechat-exporter"
    digest_file = client_root / "tools" / "wechat_exporter_skill.sha256"
    for path in (mirror, digest_file):
        try:
            path.resolve().relative_to(client_root.resolve())
        except ValueError as exc:
            raise ValueError(f"target leaves client repository: {path}") from exc
    return mirror, digest_file


def _unexpected_files(mirror: Path) -> list[str]:
    if not mirror.exists():
        return []
    expected = {path.as_posix() for path in SKILL_RELATIVE_FILES}
    actual = {
        path.relative_to(mirror).as_posix()
        for path in mirror.rglob("*")
        if path.is_file()
    }
    return sorted(actual - expected)


def write_mirror(client_root: Path, digest: str) -> None:
    mirror, digest_file = _paths(client_root)
    unexpected = _unexpected_files(mirror)
    if unexpected:
        raise ValueError(
            "refusing to remove unexpected mirror files: " + ", ".join(unexpected)
        )
    for relative in SKILL_RELATIVE_FILES:
        source = SKILL_ROOT / relative
        target = mirror / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
    digest_file.parent.mkdir(parents=True, exist_ok=True)
    digest_file.write_text(digest + "\n", encoding="ascii")
    print(f"[ok] synchronized mirror: {mirror}")
    print(f"[ok] wrote digest: {digest_file}")


def check_mirror(client_root: Path, digest: str) -> None:
    mirror, digest_file = _paths(client_root)
    unexpected = _unexpected_files(mirror)
    if unexpected:
        raise ValueError("unexpected mirror files: " + ", ".join(unexpected))
    for relative in SKILL_RELATIVE_FILES:
        source = SKILL_ROOT / relative
        target = mirror / relative
        if not target.is_file():
            raise FileNotFoundError(target)
        if source.read_bytes() != target.read_bytes():
            raise ValueError(f"client mirror is stale: {relative.as_posix()}")
    if not digest_file.is_file():
        raise FileNotFoundError(digest_file)
    pinned = digest_file.read_text(encoding="ascii").strip().lower()
    if pinned != digest:
        raise ValueError(f"client mirror digest mismatch: expected {digest}, found {pinned}")
    print(f"[ok] client mirror matches canonical sha256={digest}")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Synchronize the canonical Skill into the WechatExporter Windows client build mirror"
    )
    action = parser.add_mutually_exclusive_group(required=True)
    action.add_argument("--check", action="store_true", help="verify without writing")
    action.add_argument("--write", action="store_true", help="update mirror and digest")
    parser.add_argument(
        "--client-root",
        help="override the sibling WechatExporterWinClient-py path",
    )
    options = parser.parse_args(argv)

    digest = validate()
    client_root = _resolve_client_root(options.client_root)
    if not (client_root / "pyproject.toml").is_file():
        raise FileNotFoundError(
            f"WechatExporter Windows client repository not found: {client_root}"
        )
    if options.write:
        write_mirror(client_root, digest)
    else:
        check_mirror(client_root, digest)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
