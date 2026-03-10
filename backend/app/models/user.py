import enum
from datetime import datetime, timezone

from sqlalchemy import Column, DateTime, Enum, Integer, String

from app.database import Base


class UserRole(str, enum.Enum):
    student = "student"
    mentor = "mentor"
    admin = "admin"


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True)
    github_id = Column(Integer, unique=True, nullable=False)
    username = Column(String, unique=True, nullable=False)
    email = Column(String)
    avatar_url = Column(String)
    role = Column(Enum(UserRole), default=UserRole.student, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    last_login = Column(DateTime)
    github_token = Column(String)
