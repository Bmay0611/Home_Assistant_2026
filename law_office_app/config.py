"""Application configuration. All paths are local to this folder."""

import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent

# .docx templates with {{ placeholders }}.
TEMPLATE_DIR = BASE_DIR / "doc_templates"

# Generated documents are written here.
OUTPUT_DIR = BASE_DIR / "generated"

# Local SQLite database (kept out of git -- see .gitignore).
DATA_DIR = BASE_DIR / "data"
DATABASE_PATH = DATA_DIR / "matters.db"

# Flask secret key for flash messages / sessions. Override in production
# by setting the LAW_OFFICE_SECRET environment variable.
SECRET_KEY = os.environ.get("LAW_OFFICE_SECRET", "dev-only-change-me")

# Bind to localhost only -- this app is intended to run locally.
HOST = os.environ.get("LAW_OFFICE_HOST", "127.0.0.1")
PORT = int(os.environ.get("LAW_OFFICE_PORT", "5000"))
