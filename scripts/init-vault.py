#!/usr/bin/env python3
"""Create a safe, filesystem-first Obsidian vault from versioned templates."""
from __future__ import annotations

import argparse
import os
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SEED = ROOT / "vault-seed"
IGNORED_NAMES = {".DS_Store"}
FOLDERS = (
    "00 Inbox",
    "01 Projects",
    "02 Areas/Infrastructure",
    "02 Areas/Personal",
    "02 Areas/Learning",
    "03 Reference",
    "04 Operations",
    "90 Archive",
    "_templates",
)


def copy_if_missing(source: Path, target: Path) -> None:
    if target.exists():
        print(f"Kept existing {target}")
        return
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, target)
    print(f"Created {target}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--vault",
        type=Path,
        default=Path(os.environ.get("OBSIDIAN_VAULT_PATH", ROOT / "runtime" / "vault")),
        help="Target vault directory (default: OBSIDIAN_VAULT_PATH or ./runtime/vault)",
    )
    args = parser.parse_args()
    vault = args.vault.expanduser().resolve()
    vault.mkdir(parents=True, exist_ok=True)
    for folder in FOLDERS:
        (vault / folder).mkdir(parents=True, exist_ok=True)
    for source in SEED.rglob("*"):
        if source.is_file() and source.name not in IGNORED_NAMES:
            copy_if_missing(source, vault / source.relative_to(SEED))
    print(f"Vault ready: {vault}")


if __name__ == "__main__":
    main()
