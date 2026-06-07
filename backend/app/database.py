from sqlmodel import SQLModel, create_engine, Session
from fastapi import Depends

sqlite_file_name = "flagforge.db"
sqlite_url = f"sqlite:///{sqlite_file_name}"

# check_same_thread=False is essential for FastAPI's multi-threaded worker paths
connect_args = {"check_same_thread": False}
engine = create_engine(sqlite_url, echo=False, connect_args=connect_args)

def init_db():
    SQLModel.metadata.create_all(engine)

def get_session():
    with Session(engine) as session:
        yield session