"""
Code Generator Tool - Generates code based on specifications.
"""
import logging
from typing import Dict
from domain.entities import ToolMetadata
from .tool_registry import Tool


logger = logging.getLogger(__name__)


class CodeGeneratorTool(Tool):
    """Tool for generating code"""
    
    def __init__(self):
        self._metadata = ToolMetadata(
            name="code_generator",
            description="Generates code based on specifications and requirements",
            capabilities=["CODE_GENERATION", "FLUTTER_WIDGETS", "DART_CODE"],
            domain="code_generation",
            parameters_schema={
                "type": "object",
                "properties": {
                    "language": {"type": "string", "enum": ["dart", "python", "javascript"]},
                    "specification": {"type": "string"},
                    "framework": {"type": "string", "optional": True},
                },
                "required": ["language", "specification"]
            },
            required_permissions=["file_write"],
            execution_timeout_seconds=120,
            cost_estimate="medium"
        )
    
    @property
    def metadata(self) -> ToolMetadata:
        return self._metadata
    
    async def execute(self, parameters: Dict) -> dict:
        """
        Generate code based on parameters.
        
        Args:
            parameters: Must include 'language' and 'specification'
        
        Returns:
            Dictionary with generated code and metadata
        """
        language = parameters.get("language")
        specification = parameters.get("specification")
        framework = parameters.get("framework", "")
        
        logger.info(f"Generating {language} code: {specification[:50]}...")
        
        # In a real implementation, this would use an LLM or code generation library
        # For now, return a placeholder
        generated_code = f"// Generated {language} code\n// Specification: {specification}\n\n"
        
        if framework:
            generated_code += f"// Framework: {framework}\n"
        
        generated_code += "// TODO: Implement actual code generation\n"
        
        return {
            "success": True,
            "code": generated_code,
            "language": language,
            "lines_of_code": generated_code.count("\n"),
            "framework": framework
        }
    
    def can_handle(self, action: str) -> bool:
        """Check if this tool can handle the action"""
        action_lower = action.lower()
        return any(keyword in action_lower for keyword in 
                   ["generate", "create", "code", "widget", "class", "function"])
    
    def validate_parameters(self, parameters: Dict) -> bool:
        """Validate parameters"""
        if "language" not in parameters or "specification" not in parameters:
            return False
        
        valid_languages = ["dart", "python", "javascript"]
        if parameters["language"] not in valid_languages:
            return False
        
        return True
