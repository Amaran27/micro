"""
Micro Agent System - FastAPI Backend Server
Main entry point for the desktop agent backend.
"""
import logging
import uvicorn
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from config.settings import settings
from config.logging_config import setup_logging
from presentation.api.routes import router as api_router
from infrastructure.communication.database import Database
from infrastructure.communication.websocket_handler import ConnectionManager
from infrastructure.communication.mcp_server import MCPServer

# Setup logging
logger = setup_logging(settings.log_level)

# Initialize components
database = Database()
connection_manager = ConnectionManager()
mcp_server = MCPServer()

# Create FastAPI app
app = FastAPI(
    title="Micro Agent System API",
    description="Backend API for autonomous agent task execution with multi-agent coordination",
    version="2.0.0",
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
        "version": "2.0.0",
        "features": {
            "multi_agent": True,
            "websocket": True,
            "mcp_protocol": True,
            "database": True
        }
    }


@app.websocket("/api/v1/agent/ws/{task_id}")
async def websocket_endpoint(websocket: WebSocket, task_id: str):
    """
    WebSocket endpoint for real-time agent communication.
    Streams task progress and results.
    """
    await connection_manager.connect(task_id, websocket)
    try:
        while True:
            # Keep connection alive and handle incoming messages
            data = await websocket.receive_text()
            logger.debug(f"Received WS message for task {task_id}: {data}")
            
            # Echo back for now (placeholder for bidirectional communication)
            await connection_manager.send_message(task_id, {
                "type": "echo",
                "data": data
            })
    except WebSocketDisconnect:
        connection_manager.disconnect(task_id)
        logger.info(f"WebSocket disconnected for task {task_id}")


@app.post("/api/v1/mcp/message")
async def mcp_message_handler(message: dict):
    """
    MCP (Model Context Protocol) message handler.
    Processes JSON-RPC 2.0 messages for tool discovery and execution.
    """
    try:
        response = await mcp_server.handle_message(message)
        return response
    except Exception as e:
        logger.error(f"MCP message handling error: {e}")
        return {
            "jsonrpc": "2.0",
            "error": {
                "code": -32603,
                "message": str(e)
            },
            "id": message.get("id")
        }


@app.on_event("startup")
async def startup_event():
    """Startup initialization"""
    logger.info("=" * 60)
    logger.info("Starting Micro Agent System Backend v2.0")
    logger.info("=" * 60)
    logger.info(f"Server: {settings.host}:{settings.port}")
    logger.info(f"Debug mode: {settings.debug}")
    
    # Initialize database
    try:
        await database.initialize()
        logger.info("✓ Database initialized successfully")
    except Exception as e:
        logger.error(f"✗ Database initialization failed: {e}")
    
    # Initialize MCP server
    try:
        mcp_server.initialize()
        logger.info("✓ MCP server initialized successfully")
    except Exception as e:
        logger.error(f"✗ MCP server initialization failed: {e}")
    
    logger.info("=" * 60)
    logger.info("Features enabled:")
    logger.info("  • Multi-agent coordination (LangGraph)")
    logger.info("  • WebSocket streaming")
    logger.info("  • MCP protocol")
    logger.info("  • Task persistence")
    logger.info("=" * 60)
    logger.info(f"API Docs: http://{settings.host}:{settings.port}/docs")
    logger.info("=" * 60)


@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown"""
    logger.info("Shutting down Micro Agent System Backend")
    
    # Close database connections
    try:
        await database.close()
        logger.info("✓ Database connections closed")
    except Exception as e:
        logger.error(f"✗ Database cleanup error: {e}")
    
    # Disconnect all WebSocket clients
    try:
        await connection_manager.disconnect_all()
        logger.info("✓ All WebSocket connections closed")
    except Exception as e:
        logger.error(f"✗ WebSocket cleanup error: {e}")


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
