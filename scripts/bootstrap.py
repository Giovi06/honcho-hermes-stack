#!/usr/bin/env python3
"""Create a local .env from the safe template with unique database secrets."""
from __future__ import annotations

import secrets
import os
from pathlib import Path

root = Path(__file__).resolve().parents[1]
target = root / ".env"
source = root / ".env.example"
if target.exists():
    raise SystemExit(f"Refusing to overwrite {target}. Delete it deliberately to regenerate.")

content = source.read_text()
content = content.replace("REPLACE_WITH_A_LONG_RANDOM_SECRET", secrets.token_urlsafe(32))
content = content.replace("LOCAL_UID", str(os.getuid()))
content = content.replace("LOCAL_GID", str(os.getgid()))
target.write_text(content)
target.chmod(0o600)
print(f"Created {target} with mode 0600.")
print("For macOS, start native Ollama then pull the two models before starting Compose.")
