import os
import socket
from contextlib import asynccontextmanager

import psycopg
from fastapi import FastAPI
from pydantic import BaseModel

DATABASE_URL = os.environ["DATABASE_URL"]


def connect():
    return psycopg.connect(DATABASE_URL, autocommit=True)


@asynccontextmanager
async def lifespan(_: FastAPI):
    with connect() as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS notes (
                id SERIAL PRIMARY KEY,
                body TEXT NOT NULL,
                created_at TIMESTAMPTZ NOT NULL DEFAULT now()
            )
            """
        )
    yield


app = FastAPI(lifespan=lifespan)


class NoteIn(BaseModel):
    body: str


@app.get("/")
def index():
    # The hostname is the Compose project name, i.e. the worktree folder.
    return {"stack": socket.gethostname(), "status": "ok"}


@app.get("/notes")
def list_notes():
    with connect() as conn:
        rows = conn.execute(
            "SELECT id, body, created_at FROM notes ORDER BY id DESC"
        ).fetchall()
    return [{"id": r[0], "body": r[1], "created_at": r[2]} for r in rows]


@app.post("/notes", status_code=201)
def create_note(note: NoteIn):
    with connect() as conn:
        row = conn.execute(
            "INSERT INTO notes (body) VALUES (%s) RETURNING id", (note.body,)
        ).fetchone()
    return {"id": row[0], "body": note.body}
