"""
Domain entities for the Micro Agent System.
Based on AGENT_TECHNICAL_SPECIFICATION.md
"""
from datetime import datetime
from enum import Enum
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field


class ExecutionStatus(str, Enum):
    """Status of plan/step execution"""
    PENDING = "pending"
    PLANNING = "planning"
    EXECUTING = "executing"
    VERIFYING = "verifying"
    COMPLETED = "completed"
    FAILED = "failed"
    REPLANNING = "replanning"
    CANCELLED = "cancelled"


class VerificationResult(str, Enum):
    """Result of step verification"""
    SUCCESS = "success"
    PARTIAL = "partial"
    FAILED = "failed"
    NEEDS_REPLANNING = "needs_replanning"


class PlanStep(BaseModel):
    """A single step in the execution plan"""
    id: str
    description: str
    action: str
    parameters: Dict[str, Any]
    required_tools: List[str]
    estimated_duration_seconds: int
    status: ExecutionStatus = ExecutionStatus.PENDING
    dependencies: List[str] = Field(default_factory=list)
    sequence_number: Optional[int] = None
    tool_name: Optional[str] = None


class StepResult(BaseModel):
    """Result of executing a step"""
    step_id: str
    status: ExecutionStatus
    output: Optional[Any] = None
    error_message: Optional[str] = None
    execution_time_seconds: Optional[float] = None
    completed_at: datetime


class Verification(BaseModel):
    """Verification result for a step or plan"""
    result: VerificationResult
    reasoning: str
    task_complete: bool
    remaining_steps: Optional[List[int]] = None
    should_replan: bool = False


class AgentPlan(BaseModel):
    """Complete execution plan"""
    task_description: str
    steps: List[PlanStep]
    step_dependencies: Dict[int, List[int]] = Field(default_factory=dict)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    estimated_total_duration_seconds: Optional[int] = None


class AgentResult(BaseModel):
    """Final result of agent execution"""
    task_id: str
    task_description: str
    status: ExecutionStatus
    plan: Optional[AgentPlan] = None
    step_results: List[StepResult] = Field(default_factory=list)
    final_output: Optional[Any] = None
    error_message: Optional[str] = None
    replan_count: int = 0
    started_at: datetime
    completed_at: Optional[datetime] = None
    total_execution_time_seconds: Optional[float] = None


class ToolMetadata(BaseModel):
    """Metadata describing a tool's capabilities"""
    name: str
    description: str
    capabilities: List[str]
    domain: str
    parameters_schema: Dict[str, Any]
    required_permissions: List[str] = Field(default_factory=list)
    execution_timeout_seconds: int = 60
    cost_estimate: Optional[str] = None


class TaskCapabilities(BaseModel):
    """Capabilities required for a task"""
    primary_capabilities: List[str]
    secondary_capabilities: List[str] = Field(default_factory=list)
    complexity: str  # "simple", "moderate", "complex"
    estimated_steps: int
    requires_mobile: bool = False
    requires_desktop: bool = False


class TaskAnalysis(BaseModel):
    """Analysis of a task"""
    task_description: str
    capabilities: TaskCapabilities
    recommended_execution: str  # "local", "remote", "hybrid"
    reasoning: str
    estimated_duration_minutes: int


class PlanningContext(BaseModel):
    """Context for planning"""
    task_description: str
    available_tools: List[ToolMetadata]
    previous_plan: Optional[AgentPlan] = None
    previous_failures: List[str] = Field(default_factory=list)
    max_steps: int = 10
    constraints: Dict[str, Any] = Field(default_factory=dict)
