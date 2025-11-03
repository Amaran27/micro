"""
File Operation Tool - Handles file system operations.
"""
import logging
import os
from pathlib import Path
from typing import Dict
from domain.entities import ToolMetadata
from .tool_registry import Tool


logger = logging.getLogger(__name__)


class FileOperationTool(Tool):
    """Tool for file system operations"""
    
    def __init__(self, workspace_dir: str = "./workspace"):
        self.workspace_dir = Path(workspace_dir)
        self.workspace_dir.mkdir(parents=True, exist_ok=True)
        
        self._metadata = ToolMetadata(
            name="file_operation",
            description="Performs file system operations (read, write, list, delete)",
            capabilities=["FILE_READ", "FILE_WRITE", "FILE_LIST", "FILE_DELETE"],
            domain="file_system",
            parameters_schema={
                "type": "object",
                "properties": {
                    "operation": {"type": "string", "enum": ["read", "write", "list", "delete", "exists"]},
                    "path": {"type": "string"},
                    "content": {"type": "string", "optional": True},
                },
                "required": ["operation", "path"]
            },
            required_permissions=["file_read", "file_write"],
            execution_timeout_seconds=30,
            cost_estimate="low"
        )
    
    @property
    def metadata(self) -> ToolMetadata:
        return self._metadata
    
    async def execute(self, parameters: Dict) -> dict:
        """Execute file operation"""
        operation = parameters.get("operation")
        path = parameters.get("path", "")
        content = parameters.get("content", "")
        
        # Resolve path within workspace
        full_path = self.workspace_dir / path
        
        # Ensure path is within workspace (security)
        try:
            full_path = full_path.resolve()
            self.workspace_dir.resolve()
            if not str(full_path).startswith(str(self.workspace_dir)):
                return {"success": False, "error": "Path outside workspace"}
        except Exception as e:
            return {"success": False, "error": f"Invalid path: {str(e)}"}
        
        try:
            if operation == "read":
                if not full_path.exists():
                    return {"success": False, "error": "File not found"}
                
                content = full_path.read_text()
                return {
                    "success": True,
                    "content": content,
                    "size_bytes": len(content),
                    "path": str(path)
                }
            
            elif operation == "write":
                full_path.parent.mkdir(parents=True, exist_ok=True)
                full_path.write_text(content)
                return {
                    "success": True,
                    "bytes_written": len(content),
                    "path": str(path)
                }
            
            elif operation == "list":
                if not full_path.exists():
                    return {"success": False, "error": "Directory not found"}
                
                items = []
                for item in full_path.iterdir():
                    items.append({
                        "name": item.name,
                        "is_dir": item.is_dir(),
                        "size": item.stat().st_size if item.is_file() else 0
                    })
                
                return {
                    "success": True,
                    "items": items,
                    "count": len(items)
                }
            
            elif operation == "delete":
                if full_path.exists():
                    if full_path.is_file():
                        full_path.unlink()
                    else:
                        import shutil
                        shutil.rmtree(full_path)
                
                return {"success": True, "path": str(path)}
            
            elif operation == "exists":
                return {
                    "success": True,
                    "exists": full_path.exists(),
                    "is_file": full_path.is_file() if full_path.exists() else False,
                    "is_dir": full_path.is_dir() if full_path.exists() else False
                }
            
            else:
                return {"success": False, "error": f"Unknown operation: {operation}"}
        
        except Exception as e:
            logger.error(f"File operation error: {str(e)}")
            return {"success": False, "error": str(e)}
    
    def can_handle(self, action: str) -> bool:
        """Check if this tool can handle the action"""
        action_lower = action.lower()
        return any(keyword in action_lower for keyword in 
                   ["file", "read", "write", "save", "load", "list", "delete"])
    
    def validate_parameters(self, parameters: Dict) -> bool:
        """Validate parameters"""
        if "operation" not in parameters or "path" not in parameters:
            return False
        
        valid_operations = ["read", "write", "list", "delete", "exists"]
        if parameters["operation"] not in valid_operations:
            return False
        
        if parameters["operation"] == "write" and "content" not in parameters:
            return False
        
        return True
