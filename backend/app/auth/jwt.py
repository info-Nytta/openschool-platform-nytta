from datetime import UTC, datetime, timedelta

from jose import JWTError, jwt

from app.config import settings

ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30
REFRESH_TOKEN_EXPIRE_DAYS = 7


def create_access_token(user_id: int) -> str:
    expire = datetime.now(UTC) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    return jwt.encode(
        {"sub": str(user_id), "exp": expire},
        settings.secret_key,
        algorithm=ALGORITHM,
    )


def create_refresh_token(user_id: int) -> str:
    expire = datetime.now(UTC) + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
    return jwt.encode(
        {"sub": str(user_id), "exp": expire, "type": "refresh"},
        settings.secret_key,
        algorithm=ALGORITHM,
    )


def verify_token(token: str) -> dict:
    """Verify and decode a JWT token. Returns the payload dict with 'user_id' key."""
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[ALGORITHM])
        user_id = payload.get("sub")
        if user_id is None:
            raise ValueError("Token missing 'sub' claim")
        return {"user_id": int(user_id), "payload": payload}
    except JWTError as e:
        raise ValueError(f"Invalid token: {e}") from e
