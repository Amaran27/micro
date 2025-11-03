"""
Configuration settings for the Micro Agent System backend.
"""
import os
from typing import List
from pydantic_settings import BaseSettings
from dotenv import load_dotenv

load_dotenv()


class Settings(BaseSettings):
    """Application settings"""
    
    # Server Configuration
    host: str = os.getenv("HOST", "0.0.0.0")
    port: int = int(os.getenv("PORT", "8000"))
    debug: bool = os.getenv("DEBUG", "false").lower() == "true"
    log_level: str = os.getenv("LOG_LEVEL", "info")
    
    # LLM Provider Configuration
    openai_api_key: str = os.getenv("OPENAI_API_KEY", "")
    anthropic_api_key: str = os.getenv("ANTHROPIC_API_KEY", "")
    google_api_key: str = os.getenv("GOOGLE_API_KEY", "")
    zhipuai_api_key: str = os.getenv("ZHIPUAI_API_KEY", "")
    
    default_llm_provider: str = os.getenv("DEFAULT_LLM_PROVIDER", "openai")
    default_llm_model: str = os.getenv("DEFAULT_LLM_MODEL", "gpt-4-turbo-preview")
    
    # Agent Configuration
    max_replan_attempts: int = int(os.getenv("MAX_REPLAN_ATTEMPTS", "2"))
    step_timeout_seconds: int = int(os.getenv("STEP_TIMEOUT_SECONDS", "300"))
    max_parallel_steps: int = int(os.getenv("MAX_PARALLEL_STEPS", "3"))
    
    # Database (Phase 2+)
    database_url: str = os.getenv("DATABASE_URL", "sqlite+aiosqlite:///./agent_system.db")
    
    # Security
    api_key_header: str = os.getenv("API_KEY_HEADER", "X-API-Key")
    allowed_origins: List[str] = os.getenv("ALLOWED_ORIGINS", "http://localhost:*,app://").split(",")
    
    # Rate Limiting
    rate_limit_per_minute: int = int(os.getenv("RATE_LIMIT_PER_MINUTE", "60"))
    
    class Config:
        env_file = ".env"
        case_sensitive = False


# Global settings instance
settings = Settings()
