"""
Micro Agent System - FastAPI Backend Server
Main entry point for the desktop agent backend.
"""
import logging
import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from config.settings import settings
from config.logging_config import setup_logging
from presentation.api.routes import router as api_router

# Setup logging
logger = setup_logging(settings.log_level)

# Create FastAPI app
app = FastAPI(
    title="Micro Agent System API",
    description="Backend API for autonomous agent task execution",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API routes
app.include_router(api_router, prefix="/api/v1")


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "micro-agent-backend",
        "version": "1.0.0"
    }


@app.on_event("startup")
async def startup_event():
    """Startup initialization"""
    logger.info("Starting Micro Agent System Backend")
    logger.info(f"Server: {settings.host}:{settings.port}")
    logger.info(f"Debug mode: {settings.debug}")


@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown"""
    logger.info("Shutting down Micro Agent System Backend")


def main():
    """Run the FastAPI server"""
    uvicorn.run(
        "main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug,
        log_level=settings.log_level.lower()
    )


if __name__ == "__main__":
    main()
