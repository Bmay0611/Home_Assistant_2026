"""Local SQLite storage for generated matter submissions.

Stores a record of every document generated: which template, the client
name (for the history list), the full form data as JSON, and the output
filename. Nothing leaves the local machine.
"""

import json
import sqlite3
from datetime import datetime

import config

_SCHEMA = """
CREATE TABLE IF NOT EXISTS submissions (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    matter_type     TEXT NOT NULL,
    client_name     TEXT,
    data_json       TEXT NOT NULL,
    output_filename TEXT NOT NULL,
    created_at      TEXT NOT NULL
);
"""


def _connect():
    config.DATA_DIR.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(config.DATABASE_PATH))
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    with _connect() as conn:
        conn.executescript(_SCHEMA)


def save_submission(matter_type, client_name, data, output_filename):
    """Persist one generated document and return its row id."""
    with _connect() as conn:
        cursor = conn.execute(
            "INSERT INTO submissions "
            "(matter_type, client_name, data_json, output_filename, created_at) "
            "VALUES (?, ?, ?, ?, ?)",
            (
                matter_type,
                client_name,
                json.dumps(data),
                output_filename,
                datetime.now().isoformat(timespec="seconds"),
            ),
        )
        return cursor.lastrowid


def list_submissions(limit=100):
    with _connect() as conn:
        rows = conn.execute(
            "SELECT id, matter_type, client_name, output_filename, created_at "
            "FROM submissions ORDER BY id DESC LIMIT ?",
            (limit,),
        ).fetchall()
    return [dict(row) for row in rows]


def get_submission(submission_id):
    with _connect() as conn:
        row = conn.execute(
            "SELECT * FROM submissions WHERE id = ?", (submission_id,)
        ).fetchone()
    if row is None:
        return None
    record = dict(row)
    record["data"] = json.loads(record.pop("data_json"))
    return record
