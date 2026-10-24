"""Escribe el esquema OpenAPI de la app en un archivo JSON (default: openapi.json)."""

import json
import sys
from pathlib import Path

from app.main import app


def main() -> None:
    target = Path(sys.argv[1] if len(sys.argv) > 1 else "openapi.json")
    target.write_text(json.dumps(app.openapi(), indent=2) + "\n", encoding="utf-8")
    print(f"OpenAPI escrito en {target}")


if __name__ == "__main__":
    main()
