import os
from functools import lru_cache
from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    secret_key: str = "change-me-in-production-use-a-long-random-string"
    database_url: str = "sqlite:///./mess_ledger.db"
    token_hours: int = 12

    class Config:
        env_file = ".env"
        case_sensitive = False


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()