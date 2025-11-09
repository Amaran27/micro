"""
WebSocket Handler for Phase 2 - Real-time streaming communication.
Enables token-by-token LLM response streaming and real-time progress updates.
"""
import asyncio
import json
import logging
from typing import Dict, Set
from fastapi import WebSocket, WebSocketDisconnect
from datetime import datetime


logger = logging.getLogger(__name__)


class ConnectionManager:
    """Manages WebSocket connections for real-time communication"""
    
    def __init__(self):
        # Active connections: task_id -> set of WebSocket connections
        self.active_connections: Dict[str, Set[WebSocket]] = {}
        self.connection_tasks: Dict[str, Set[str]] = {}  # websocket_id -> task_ids
    
    async def connect(self, websocket: WebSocket, task_id: str):
        """Accept a WebSocket connection for a task"""
        await websocket.accept()
        
        if task_id not in self.active_connections:
            self.active_connections[task_id] = set()
        
        self.active_connections[task_id].add(websocket)
        
        # Track which tasks this connection is subscribed to
        ws_id = id(websocket)
        if ws_id not in self.connection_tasks:
            self.connection_tasks[ws_id] = set()
        self.connection_tasks[ws_id].add(task_id)
        
        logger.info(f"WebSocket connected for task {task_id}")
    
    def disconnect(self, websocket: WebSocket, task_id: str):
        """Remove a WebSocket connection"""
        if task_id in self.active_connections:
            self.active_connections[task_id].discard(websocket)
            
            # Remove task if no more connections
            if not self.active_connections[task_id]:
                del self.active_connections[task_id]
        
        # Clean up connection tracking
        ws_id = id(websocket)
        if ws_id in self.connection_tasks:
            self.connection_tasks[ws_id].discard(task_id)
            if not self.connection_tasks[ws_id]:
                del self.connection_tasks[ws_id]
        
        logger.info(f"WebSocket disconnected for task {task_id}")
    
    async def send_message(self, task_id: str, message: Dict):
        """Send message to all connections for a task"""
        if task_id not in self.active_connections:
            return
        
        # Add timestamp
        message['timestamp'] = datetime.utcnow().isoformat()
        
        # Send to all connections
        disconnected = []
        for connection in self.active_connections[task_id]:
            try:
                await connection.send_json(message)
            except WebSocketDisconnect:
                disconnected.append(connection)
            except Exception as e:
                logger.error(f"Error sending WebSocket message: {e}")
                disconnected.append(connection)
        
        # Clean up disconnected
        for conn in disconnected:
            self.disconnect(conn, task_id)
    
    async def stream_token(self, task_id: str, token: str):
        """Stream a single token (for LLM responses)"""
        await self.send_message(task_id, {
            'type': 'token',
            'content': token
        })
    
    async def send_progress(self, task_id: str, step: int, total: int, message: str):
        """Send progress update"""
        await self.send_message(task_id, {
            'type': 'progress',
            'step': step,
            'total': total,
            'message': message,
            'progress_percent': (step / total * 100) if total > 0 else 0
        })
    
    async def send_status(self, task_id: str, status: str, data: Dict = None):
        """Send status update"""
        message = {
            'type': 'status',
            'status': status
        }
        if data:
            message['data'] = data
        
        await self.send_message(task_id, message)
    
    async def send_error(self, task_id: str, error: str):
        """Send error message"""
        await self.send_message(task_id, {
            'type': 'error',
            'error': error
        })
    
    async def send_completion(self, task_id: str, result: Dict):
        """Send task completion"""
        await self.send_message(task_id, {
            'type': 'completion',
            'result': result
        })


# Global connection manager
manager = ConnectionManager()


async def websocket_endpoint(websocket: WebSocket, task_id: str):
    """
    WebSocket endpoint for real-time task updates
    
    URL: ws://localhost:8000/api/v1/agent/ws/{task_id}
    
    Message types sent to client:
    - token: Individual LLM response tokens
    - progress: Task progress updates
    - status: Status changes
    - error: Error messages
    - completion: Task completion with results
    """
    await manager.connect(websocket, task_id)
    
    try:
        while True:
            # Keep connection alive and handle client messages
            data = await websocket.receive_text()
            
            # Handle ping/pong for keepalive
            if data == "ping":
                await websocket.send_text("pong")
            else:
                # Log any other client messages
                logger.debug(f"Received from client: {data}")
    
    except WebSocketDisconnect:
        manager.disconnect(websocket, task_id)
    except Exception as e:
        logger.error(f"WebSocket error: {e}")
        manager.disconnect(websocket, task_id)
