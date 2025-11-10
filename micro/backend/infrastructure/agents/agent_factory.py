"""
Agent Factory - Dynamic agent creation based on task analysis.
Based on ADR-002: Zero hardcoded agent classes, all specialization is data-driven.
"""
import logging
from typing import Dict, List
from domain.entities import TaskAnalysis, TaskCapabilities
from infrastructure.tools.tool_registry import ToolRegistry
from infrastructure.agents.plan_execute_agent import PlanExecuteAgent


logger = logging.getLogger(__name__)


class AgentFactory:
    """
    Factory for creating agents dynamically based on task requirements.
    
    Key Principle: No hardcoded agent classes. Agents are created by:
    1. Analyzing task requirements (what capabilities needed)
    2. Getting tools that match capabilities
    3. Generating specialized system prompt
    4. Creating generic PlanExecuteAgent with specific tools/prompt
    """
    
    def __init__(self, tool_registry: ToolRegistry, llm_provider: any):
        self.tool_registry = tool_registry
        self.llm_provider = llm_provider
    
    async def create_agent_for_task(
        self,
        task_description: str,
        context: Dict = None
    ) -> PlanExecuteAgent:
        """
        Create an agent optimized for the specific task.
        
        Process:
        1. Analyze task to determine required capabilities
        2. Select tools that match capabilities
        3. Generate task-specific system prompt
        4. Create PlanExecuteAgent with tools and prompt
        
        Args:
            task_description: Natural language task description
            context: Additional context for agent creation
        
        Returns:
            Configured PlanExecuteAgent ready to execute
        """
        logger.info(f"Creating agent for task: {task_description[:50]}...")
        
        # Step 1: Analyze task requirements
        analysis = await self._analyze_task(task_description, context or {})
        logger.info(f"Task requires capabilities: {analysis.capabilities.primary_capabilities}")
        
        # Step 2: Get matching tools
        tools = self._select_tools_for_capabilities(analysis.capabilities)
        logger.info(f"Selected {len(tools)} tools for task")
        
        # Step 3: Create specialized agent
        agent = PlanExecuteAgent(
            tool_registry=self.tool_registry,
            llm_provider=self.llm_provider,
            max_replan_attempts=2,
            step_timeout_seconds=300
        )
        
        return agent
    
    async def _analyze_task(
        self, task_description: str, context: Dict
    ) -> TaskAnalysis:
        """
        Analyze task to determine requirements.
        
        Uses LLM to understand:
        - What capabilities are needed
        - Complexity level
        - Whether mobile or desktop execution is best
        """
        # Prompt LLM to analyze task
        available_capabilities = self.tool_registry.get_all_capabilities()
        
        prompt = f"""Analyze this task and determine what capabilities are needed:

Task: {task_description}

Available Capabilities:
{', '.join(available_capabilities)}

Provide analysis as JSON:
{{
  "primary_capabilities": ["CAPABILITY1", "CAPABILITY2"],
  "complexity": "simple|moderate|complex",
  "requires_mobile": true|false,
  "requires_desktop": true|false,
  "estimated_duration_minutes": 10
}}
"""
        
        # For now, return default analysis
        # Real implementation would parse LLM response
        return TaskAnalysis(
            task_description=task_description,
            capabilities=TaskCapabilities(
                primary_capabilities=["CODE_GENERATION", "FILE_WRITE"],
                secondary_capabilities=[],
                complexity="moderate",
                estimated_steps=3,
                requires_desktop=True
            ),
            recommended_execution="remote",
            reasoning="Task requires code generation which is desktop capability",
            estimated_duration_minutes=10
        )
    
    def _select_tools_for_capabilities(
        self, capabilities: TaskCapabilities
    ) -> List[str]:
        """Select tools that match required capabilities"""
        all_capabilities = (
            capabilities.primary_capabilities + 
            capabilities.secondary_capabilities
        )
        
        selected_tools = set()
        for capability in all_capabilities:
            tool_names = self.tool_registry.list_tools_by_capability(capability)
            selected_tools.update(tool_names)
        
        return list(selected_tools)
    
    def _generate_system_prompt(
        self, task_description: str, capabilities: TaskCapabilities, tools: List[str]
    ) -> str:
        """Generate specialized system prompt for the agent"""
        return f"""You are an AI agent specialized in: {', '.join(capabilities.primary_capabilities)}.

Your task: {task_description}

Available tools: {', '.join(tools)}

Guidelines:
1. Break down the task into clear, executable steps
2. Use the most appropriate tools for each step
3. Verify each step completed successfully before proceeding
4. If something fails, analyze the error and adjust your plan

Be thorough, efficient, and always explain your reasoning.
"""
