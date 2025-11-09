"""
MCP (Model Context Protocol) Server for Phase 3.
Implements standardized tool discovery and execution protocol.

Based on Model Context Protocol specification:
- JSON-RPC 2.0 message format
- Standardized tool/resource discovery
- Server-side tool execution
- Client-side capability negotiation
"""
import json
import logging
from typing import Dict, List, Any, Optional
from enum import Enum


logger = logging.getLogger(__name__)


class MCPMessageType(str, Enum):
    """MCP message types"""
    REQUEST = "request"
    RESPONSE = "response"
    NOTIFICATION = "notification"
    ERROR = "error"


class MCPMethod(str, Enum):
    """Standard MCP methods"""
    # Initialization
    INITIALIZE = "initialize"
    INITIALIZED = "initialized"
    
    # Tool Discovery
    TOOLS_LIST = "tools/list"
    TOOLS_CALL = "tools/call"
    
    # Resource Discovery
    RESOURCES_LIST = "resources/list"
    RESOURCES_READ = "resources/read"
    
    # Server Info
    PING = "ping"
    SHUTDOWN = "shutdown"


class MCPMessage:
    """Base MCP message"""
    
    def __init__(
        self,
        jsonrpc: str = "2.0",
        id: Optional[str] = None,
        method: Optional[str] = None,
        params: Optional[Dict] = None,
        result: Optional[Any] = None,
        error: Optional[Dict] = None
    ):
        self.jsonrpc = jsonrpc
        self.id = id
        self.method = method
        self.params = params
        self.result = result
        self.error = error
    
    def to_dict(self) -> Dict:
        """Convert to dictionary"""
        msg = {"jsonrpc": self.jsonrpc}
        if self.id is not None:
            msg["id"] = self.id
        if self.method:
            msg["method"] = self.method
        if self.params:
            msg["params"] = self.params
        if self.result is not None:
            msg["result"] = self.result
        if self.error:
            msg["error"] = self.error
        return msg
    
    @classmethod
    def from_dict(cls, data: Dict) -> 'MCPMessage':
        """Create from dictionary"""
        return cls(
            jsonrpc=data.get("jsonrpc", "2.0"),
            id=data.get("id"),
            method=data.get("method"),
            params=data.get("params"),
            result=data.get("result"),
            error=data.get("error")
        )


class MCPServer:
    """
    MCP Protocol Server
    
    Provides standardized interface for:
    - Tool discovery (dynamic from ToolRegistry)
    - Tool execution
    - Resource access
    - Capability negotiation
    """
    
    def __init__(self, tool_registry, agent_factory):
        self.tool_registry = tool_registry
        self.agent_factory = agent_factory
        self.initialized = False
        self.client_capabilities = {}
    
    async def handle_message(self, message_dict: Dict) -> MCPMessage:
        """
        Handle incoming MCP message
        
        Args:
            message_dict: JSON-RPC 2.0 message
        
        Returns:
            MCPMessage response
        """
        try:
            message = MCPMessage.from_dict(message_dict)
            
            if not message.method:
                return self._error_response(
                    message.id, -32600, "Invalid Request: method required"
                )
            
            # Route to appropriate handler
            if message.method == MCPMethod.INITIALIZE:
                return await self._handle_initialize(message)
            elif message.method == MCPMethod.TOOLS_LIST:
                return await self._handle_tools_list(message)
            elif message.method == MCPMethod.TOOLS_CALL:
                return await self._handle_tools_call(message)
            elif message.method == MCPMethod.RESOURCES_LIST:
                return await self._handle_resources_list(message)
            elif message.method == MCPMethod.PING:
                return self._success_response(message.id, {"status": "pong"})
            else:
                return self._error_response(
                    message.id, -32601, f"Method not found: {message.method}"
                )
        
        except Exception as e:
            logger.error(f"MCP message handling error: {e}")
            return self._error_response(None, -32603, f"Internal error: {str(e)}")
    
    async def _handle_initialize(self, message: MCPMessage) -> MCPMessage:
        """Handle initialization handshake"""
        params = message.params or {}
        self.client_capabilities = params.get("capabilities", {})
        
        server_info = {
            "protocolVersion": "1.0",
            "capabilities": {
                "tools": {"listTools": True, "callTool": True},
                "resources": {"listResources": True, "readResource": True},
            },
            "serverInfo": {
                "name": "micro-agent-server",
                "version": "1.0.0"
            }
        }
        
        self.initialized = True
        logger.info("MCP server initialized")
        
        return self._success_response(message.id, server_info)
    
    async def _handle_tools_list(self, message: MCPMessage) -> MCPMessage:
        """List all available tools"""
        if not self.initialized:
            return self._error_response(message.id, -32002, "Server not initialized")
        
        tools = self.tool_registry.get_all_tools()
        
        tools_list = [
            {
                "name": tool.metadata.name,
                "description": tool.metadata.description,
                "capabilities": tool.metadata.capabilities,
                "domain": tool.metadata.domain,
                "inputSchema": tool.metadata.parameters_schema
            }
            for tool in tools
        ]
        
        return self._success_response(message.id, {"tools": tools_list})
    
    async def _handle_tools_call(self, message: MCPMessage) -> MCPMessage:
        """Execute a tool"""
        if not self.initialized:
            return self._error_response(message.id, -32002, "Server not initialized")
        
        params = message.params or {}
        tool_name = params.get("name")
        arguments = params.get("arguments", {})
        
        if not tool_name:
            return self._error_response(message.id, -32602, "Missing tool name")
        
        tool = self.tool_registry.get_tool(tool_name)
        if not tool:
            return self._error_response(message.id, -32602, f"Tool not found: {tool_name}")
        
        try:
            # Execute tool
            result = await tool.execute(arguments)
            
            return self._success_response(message.id, {
                "content": [{"type": "text", "text": json.dumps(result)}],
                "isError": False
            })
        
        except Exception as e:
            logger.error(f"Tool execution error: {e}")
            return self._success_response(message.id, {
                "content": [{"type": "text", "text": str(e)}],
                "isError": True
            })
    
    async def _handle_resources_list(self, message: MCPMessage) -> MCPMessage:
        """List available resources"""
        # Resources could include: tool registry, agent capabilities, etc.
        resources = [
            {
                "uri": "tool://registry",
                "name": "Tool Registry",
                "description": "Dynamic tool discovery system",
                "mimeType": "application/json"
            },
            {
                "uri": "agent://capabilities",
                "name": "Agent Capabilities",
                "description": "Available agent capabilities",
                "mimeType": "application/json"
            }
        ]
        
        return self._success_response(message.id, {"resources": resources})
    
    def _success_response(self, id: Optional[str], result: Any) -> MCPMessage:
        """Create success response"""
        return MCPMessage(jsonrpc="2.0", id=id, result=result)
    
    def _error_response(self, id: Optional[str], code: int, message: str) -> MCPMessage:
        """Create error response"""
        return MCPMessage(
            jsonrpc="2.0",
            id=id,
            error={"code": code, "message": message}
        )
