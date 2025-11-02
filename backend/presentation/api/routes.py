"""
REST API Routes for Phase 1 - HTTP Communication
"""
import logging
import uuid
from datetime import datetime
from typing import Dict, Optional
from fastapi import APIRouter, HTTPException, BackgroundTasks
from pydantic import BaseModel
from domain.entities import AgentResult, ExecutionStatus
from infrastructure.agents.agent_factory import AgentFactory
from infrastructure.tools.tool_registry import ToolRegistry
from infrastructure.tools.code_generator_tool import CodeGeneratorTool
from infrastructure.tools.file_operation_tool import FileOperationTool


logger = logging.getLogger(__name__)

# Create router
router = APIRouter()

# Initialize components (in production, use dependency injection)
tool_registry = ToolRegistry()
tool_registry.register(CodeGeneratorTool())
tool_registry.register(FileOperationTool())

# Simple LLM placeholder (real implementation would use LangChain)
class SimpleLLM:
    async def call(self, prompt: str) -> str:
        return "LLM placeholder response"

llm_provider = SimpleLLM()
agent_factory = AgentFactory(tool_registry, llm_provider)

# In-memory task storage (Phase 2 will use database)
task_results: Dict[str, AgentResult] = {}


# Request/Response Models
class TaskRequest(BaseModel):
    """Request to execute a task"""
    task: str
    context: Optional[Dict] = None


class TaskResponse(BaseModel):
    """Response with task ID"""
    task_id: str
    status: str
    message: str


class TaskStatusResponse(BaseModel):
    """Task status response"""
    task_id: str
    status: ExecutionStatus
    task_description: str
    started_at: datetime
    completed_at: Optional[datetime] = None
    step_count: Optional[int] = None
    completed_steps: Optional[int] = None
    final_output: Optional[any] = None
    error_message: Optional[str] = None


@router.post("/agent/task", response_model=TaskResponse)
async def execute_task(request: TaskRequest, background_tasks: BackgroundTasks):
    """
    Execute an agent task (Phase 1: Async with polling)
    
    POST /api/v1/agent/task
    Body: {
        "task": "Generate Flutter login form",
        "context": {"optional": "context"}
    }
    
    Returns task_id for status polling.
    """
    try:
        task_id = str(uuid.uuid4())
        logger.info(f"Received task: {request.task} (ID: {task_id})")
        
        # Store initial status
        task_results[task_id] = AgentResult(
            task_id=task_id,
            task_description=request.task,
            status=ExecutionStatus.PENDING,
            started_at=datetime.utcnow(),
            step_results=[]
        )
        
        # Execute task in background
        background_tasks.add_task(
            _execute_task_background,
            task_id,
            request.task,
            request.context or {}
        )
        
        return TaskResponse(
            task_id=task_id,
            status="accepted",
            message=f"Task accepted and executing. Poll /agent/task/{task_id} for status."
        )
    
    except Exception as e:
        logger.error(f"Error accepting task: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/agent/task/{task_id}", response_model=TaskStatusResponse)
async def get_task_status(task_id: str):
    """
    Get status of a task
    
    GET /api/v1/agent/task/{task_id}
    
    Returns current execution status and results if completed.
    """
    if task_id not in task_results:
        raise HTTPException(status_code=404, detail="Task not found")
    
    result = task_results[task_id]
    
    return TaskStatusResponse(
        task_id=result.task_id,
        status=result.status,
        task_description=result.task_description,
        started_at=result.started_at,
        completed_at=result.completed_at,
        step_count=len(result.plan.steps) if result.plan else None,
        completed_steps=len([r for r in result.step_results if r.status == ExecutionStatus.COMPLETED]),
        final_output=result.final_output,
        error_message=result.error_message
    )


@router.get("/agent/tools")
async def list_tools():
    """
    List all available tools
    
    GET /api/v1/agent/tools
    
    Returns list of tool metadata.
    """
    tools = tool_registry.get_all_tools()
    return {
        "tools": [
            {
                "name": tool.metadata.name,
                "description": tool.metadata.description,
                "capabilities": tool.metadata.capabilities,
                "domain": tool.metadata.domain
            }
            for tool in tools
        ],
        "count": len(tools)
    }


@router.get("/agent/capabilities")
async def list_capabilities():
    """
    List all available capabilities
    
    GET /api/v1/agent/capabilities
    """
    capabilities = tool_registry.get_all_capabilities()
    domains = tool_registry.get_all_domains()
    
    return {
        "capabilities": capabilities,
        "domains": domains,
        "tools_by_capability": {
            cap: tool_registry.list_tools_by_capability(cap)
            for cap in capabilities
        }
    }


async def _execute_task_background(task_id: str, task_description: str, context: Dict):
    """Background task execution"""
    try:
        logger.info(f"Executing task in background: {task_id}")
        
        # Create agent
        agent = await agent_factory.create_agent_for_task(task_description, context)
        
        # Execute task
        result = await agent.execute_task(task_description, task_id, context)
        
        # Store result
        task_results[task_id] = result
        
        logger.info(f"Task completed: {task_id} with status {result.status}")
    
    except Exception as e:
        logger.error(f"Background task error: {str(e)}", exc_info=True)
        task_results[task_id].status = ExecutionStatus.FAILED
        task_results[task_id].error_message = str(e)
        task_results[task_id].completed_at = datetime.utcnow()
