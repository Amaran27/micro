"""
Tool Registry - Dynamic tool discovery and management.
Based on ADR-002: Zero hardcoded agent classes.
"""
import logging
from typing import Dict, List, Optional, Set
from domain.entities import ToolMetadata


logger = logging.getLogger(__name__)


class Tool:
    """Base class for all tools"""
    
    @property
    def metadata(self) -> ToolMetadata:
        """Return tool metadata"""
        raise NotImplementedError
    
    async def execute(self, parameters: Dict) -> any:
        """Execute the tool with given parameters"""
        raise NotImplementedError
    
    def can_handle(self, action: str) -> bool:
        """Check if this tool can handle the given action"""
        raise NotImplementedError
    
    def get_required_permissions(self) -> List[str]:
        """Get required permissions for this tool"""
        return self.metadata.required_permissions
    
    def validate_parameters(self, parameters: Dict) -> bool:
        """Validate parameters before execution"""
        return True


class ToolRegistry:
    """
    Registry for dynamic tool discovery and selection.
    
    Key Features:
    - Capability-based tool indexing
    - Domain-based organization
    - Zero hardcoded agent classes
    """
    
    def __init__(self):
        self._tools: Dict[str, Tool] = {}
        self._capability_index: Dict[str, List[str]] = {}
        self._domain_index: Dict[str, List[str]] = {}
    
    def register(self, tool: Tool) -> None:
        """Register a new tool"""
        metadata = tool.metadata
        self._tools[metadata.name] = tool
        
        # Index by capabilities
        for capability in metadata.capabilities:
            if capability not in self._capability_index:
                self._capability_index[capability] = []
            self._capability_index[capability].append(metadata.name)
        
        # Index by domain
        domain = metadata.domain
        if domain not in self._domain_index:
            self._domain_index[domain] = []
        self._domain_index[domain].append(metadata.name)
        
        logger.info(f"Registered tool: {metadata.name} with capabilities {metadata.capabilities}")
    
    def unregister(self, tool_name: str) -> bool:
        """Unregister a tool"""
        if tool_name not in self._tools:
            return False
        
        tool = self._tools.pop(tool_name)
        metadata = tool.metadata
        
        # Remove from capability index
        for capability in metadata.capabilities:
            if capability in self._capability_index:
                self._capability_index[capability].remove(tool_name)
        
        # Remove from domain index
        if metadata.domain in self._domain_index:
            self._domain_index[metadata.domain].remove(tool_name)
        
        logger.info(f"Unregistered tool: {tool_name}")
        return True
    
    def get_tool(self, tool_name: str) -> Optional[Tool]:
        """Get a tool by name"""
        return self._tools.get(tool_name)
    
    def get_tools_for_capabilities(self, capabilities: List[str]) -> List[Tool]:
        """Get all tools that support given capabilities"""
        tool_names: Set[str] = set()
        
        for capability in capabilities:
            if capability in self._capability_index:
                tool_names.update(self._capability_index[capability])
        
        return [self._tools[name] for name in tool_names if name in self._tools]
    
    def get_tools_for_domain(self, domain: str) -> List[Tool]:
        """Get all tools in a domain"""
        if domain not in self._domain_index:
            return []
        
        return [self._tools[name] for name in self._domain_index[domain]]
    
    def get_all_capabilities(self) -> List[str]:
        """Get all available capabilities"""
        return list(self._capability_index.keys())
    
    def get_all_domains(self) -> List[str]:
        """Get all available domains"""
        return list(self._domain_index.keys())
    
    def get_all_tools(self) -> List[Tool]:
        """Get all registered tools"""
        return list(self._tools.values())
    
    def get_tool_metadata(self, tool_name: str) -> Optional[ToolMetadata]:
        """Get metadata for a tool"""
        tool = self.get_tool(tool_name)
        return tool.metadata if tool else None
    
    def list_tools_by_capability(self, capability: str) -> List[str]:
        """List tool names that support a capability"""
        return self._capability_index.get(capability, [])
