from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker

from app.config import settings

is_postgres = "postgresql" in settings.database_url
connect_args = {} if is_postgres else {"check_same_thread": False}

pool_kwargs = {}
if is_postgres:
    pool_kwargs = {
        "pool_size": 20,
        "max_overflow": 40,
        "pool_pre_ping": True,
        "pool_recycle": 3600,
    }

engine = create_engine(settings.database_url, connect_args=connect_args, echo=False, **pool_kwargs)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class Base(DeclarativeBase):
    pass


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
