"""
Plan-Execute Agent - Core autonomous agent implementing Plan-Execute-Verify-Replan pattern.
Based on ADR-001: Plan-Execute pattern (not ReAct) for mobile efficiency.
"""
import asyncio
import logging
from datetime import datetime
from typing import Dict, List, Optional
from domain.entities import (
    AgentPlan, AgentResult, ExecutionStatus, PlanStep, 
    StepResult, Verification, VerificationResult
)
from infrastructure.tools.tool_registry import ToolRegistry


logger = logging.getLogger(__name__)


class PlanExecuteAgent:
    """
    Core agent implementing Plan-Execute-Verify-Replan cycle.
    
    Pattern:
    1. PLAN: Create structured plan from task description
    2. EXECUTE: Run steps sequentially, calling tools
    3. VERIFY: Check if each step completed successfully
    4. REPLAN: Adjust plan if verification fails
    
    This pattern is efficient for mobile environments and provides
    clear progress tracking and recovery mechanisms.
    """
    
    def __init__(
        self,
        tool_registry: ToolRegistry,
        llm_provider: any,  # LLM interface
        max_replan_attempts: int = 2,
        step_timeout_seconds: int = 300
    ):
        self.tool_registry = tool_registry
        self.llm = llm_provider
        self.max_replan_attempts = max_replan_attempts
        self.step_timeout_seconds = step_timeout_seconds
    
    async def execute_task(
        self,
        task_description: str,
        task_id: str,
        context: Optional[Dict] = None
    ) -> AgentResult:
        """
        Execute a task end-to-end: Plan -> Execute -> Verify -> (optionally Replan)
        
        Args:
            task_description: Natural language task description
            task_id: Unique task identifier
            context: Additional context for execution
        
        Returns:
            AgentResult with execution details and outputs
        """
        logger.info(f"Starting task execution: {task_description}")
        started_at = datetime.utcnow()
        context = context or {}
        
        result = AgentResult(
            task_id=task_id,
            task_description=task_description,
            status=ExecutionStatus.PLANNING,
            started_at=started_at,
            step_results=[],
            replan_count=0
        )
        
        try:
            # Phase 1: PLAN
            plan = await self._create_plan(task_description, context)
            result.plan = plan
            logger.info(f"Plan created with {len(plan.steps)} steps")
            
            # Phase 2: EXECUTE with VERIFY
            replan_count = 0
            while replan_count <= self.max_replan_attempts:
                result.status = ExecutionStatus.EXECUTING
                
                # Execute all steps
                step_results = await self._execute_plan(plan, context)
                result.step_results.extend(step_results)
                
                # Phase 3: VERIFY
                result.status = ExecutionStatus.VERIFYING
                verification = await self._verify_execution(
                    task_description, plan, step_results, context
                )
                
                if verification.task_complete:
                    # Success!
                    result.status = ExecutionStatus.COMPLETED
                    result.final_output = self._extract_final_output(step_results)
                    break
                
                elif verification.should_replan and replan_count < self.max_replan_attempts:
                    # Phase 4: REPLAN
                    logger.info(f"Replanning attempt {replan_count + 1}")
                    result.status = ExecutionStatus.REPLANNING
                    replan_count += 1
                    result.replan_count = replan_count
                    
                    plan = await self._replan(
                        task_description, plan, step_results, verification, context
                    )
                    result.plan = plan
                
                else:
                    # Failed - no more replan attempts
                    result.status = ExecutionStatus.FAILED
                    result.error_message = verification.reasoning
                    break
            
            result.completed_at = datetime.utcnow()
            result.total_execution_time_seconds = (
                result.completed_at - started_at
            ).total_seconds()
            
            logger.info(f"Task completed with status: {result.status}")
            return result
        
        except Exception as e:
            logger.error(f"Task execution error: {str(e)}", exc_info=True)
            result.status = ExecutionStatus.FAILED
            result.error_message = str(e)
            result.completed_at = datetime.utcnow()
            return result
    
    async def _create_plan(
        self, task_description: str, context: Dict
    ) -> AgentPlan:
        """
        Create execution plan using LLM.
        
        LLM is prompted to analyze the task and generate step-by-step plan.
        """
        logger.info("Creating execution plan")
        
        # Get available tools
        available_tools = self.tool_registry.get_all_tools()
        tool_descriptions = "\n".join([
            f"- {tool.metadata.name}: {tool.metadata.description} "
            f"(capabilities: {', '.join(tool.metadata.capabilities)})"
            for tool in available_tools
        ])
        
        # Prompt LLM to create plan
        prompt = f"""Create a step-by-step execution plan for this task:

Task: {task_description}

Available Tools:
{tool_descriptions}

Generate a detailed plan as JSON with this structure:
{{
  "steps": [
    {{
      "id": "step_1",
      "description": "What this step does",
      "action": "Specific action to take",
      "parameters": {{}},
      "required_tools": ["tool_name"],
      "estimated_duration_seconds": 60,
      "dependencies": []
    }}
  ]
}}

Rules:
1. Break down the task into clear, executable steps
2. Each step should use specific tools
3. Steps can depend on previous steps
4. Be realistic about duration estimates
"""
        
        # Call LLM (simplified - real implementation would parse JSON response)
        response = await self._call_llm(prompt)
        
        # Parse response into AgentPlan
        # For now, create a simple plan (real implementation would parse LLM JSON)
        plan = AgentPlan(
            task_description=task_description,
            steps=[
                PlanStep(
                    id="step_1",
                    description="Execute main task",
                    action="perform_task",
                    parameters={"task": task_description},
                    required_tools=[available_tools[0].metadata.name] if available_tools else [],
                    estimated_duration_seconds=60
                )
            ],
            step_dependencies={}
        )
        
        return plan
    
    async def _execute_plan(
        self, plan: AgentPlan, context: Dict
    ) -> List[StepResult]:
        """Execute all steps in the plan"""
        logger.info(f"Executing plan with {len(plan.steps)} steps")
        results = []
        
        for step in plan.steps:
            logger.info(f"Executing step: {step.id} - {step.description}")
            step_start = datetime.utcnow()
            
            try:
                # Check dependencies
                if not self._dependencies_satisfied(step, results, plan):
                    results.append(StepResult(
                        step_id=step.id,
                        status=ExecutionStatus.FAILED,
                        error_message="Dependencies not satisfied",
                        completed_at=datetime.utcnow()
                    ))
                    continue
                
                # Execute step with timeout
                output = await asyncio.wait_for(
                    self._execute_step(step, context),
                    timeout=self.step_timeout_seconds
                )
                
                step_end = datetime.utcnow()
                results.append(StepResult(
                    step_id=step.id,
                    status=ExecutionStatus.COMPLETED,
                    output=output,
                    execution_time_seconds=(step_end - step_start).total_seconds(),
                    completed_at=step_end
                ))
                
            except asyncio.TimeoutError:
                logger.error(f"Step {step.id} timed out")
                results.append(StepResult(
                    step_id=step.id,
                    status=ExecutionStatus.FAILED,
                    error_message="Step execution timeout",
                    completed_at=datetime.utcnow()
                ))
            
            except Exception as e:
                logger.error(f"Step {step.id} failed: {str(e)}")
                results.append(StepResult(
                    step_id=step.id,
                    status=ExecutionStatus.FAILED,
                    error_message=str(e),
                    completed_at=datetime.utcnow()
                ))
        
        return results
    
    async def _execute_step(self, step: PlanStep, context: Dict) -> any:
        """Execute a single step by calling appropriate tools"""
        outputs = {}
        
        for tool_name in step.required_tools:
            tool = self.tool_registry.get_tool(tool_name)
            if not tool:
                raise ValueError(f"Tool not found: {tool_name}")
            
            # Validate parameters
            if not tool.validate_parameters(step.parameters):
                raise ValueError(f"Invalid parameters for tool: {tool_name}")
            
            # Execute tool
            output = await tool.execute(step.parameters)
            outputs[tool_name] = output
        
        return outputs
    
    def _dependencies_satisfied(
        self, step: PlanStep, results: List[StepResult], plan: AgentPlan
    ) -> bool:
        """Check if all dependencies for a step are satisfied"""
        if not step.dependencies:
            return True
        
        completed_step_ids = {
            r.step_id for r in results if r.status == ExecutionStatus.COMPLETED
        }
        
        return all(dep_id in completed_step_ids for dep_id in step.dependencies)
    
    async def _verify_execution(
        self,
        task_description: str,
        plan: AgentPlan,
        results: List[StepResult],
        context: Dict
    ) -> Verification:
        """Verify if the execution achieved the task goal"""
        logger.info("Verifying execution results")
        
        # Check if all steps completed
        all_completed = all(r.status == ExecutionStatus.COMPLETED for r in results)
        
        if not all_completed:
            failed_steps = [r.step_id for r in results if r.status == ExecutionStatus.FAILED]
            return Verification(
                result=VerificationResult.FAILED,
                reasoning=f"Steps failed: {', '.join(failed_steps)}",
                task_complete=False,
                should_replan=True
            )
        
        # Use LLM to verify if task is complete
        prompt = f"""Verify if this task was completed successfully:

Task: {task_description}

Plan executed:
{self._format_plan_for_llm(plan)}

Results:
{self._format_results_for_llm(results)}

Answer:
1. Was the task completed successfully? (yes/no)
2. What is your reasoning?
3. Are there remaining steps needed?
"""
        
        response = await self._call_llm(prompt)
        
        # Parse LLM response (simplified)
        # Real implementation would parse structured response
        task_complete = "yes" in response.lower()
        
        return Verification(
            result=VerificationResult.SUCCESS if task_complete else VerificationResult.PARTIAL,
            reasoning=response,
            task_complete=task_complete,
            should_replan=not task_complete
        )
    
    async def _replan(
        self,
        task_description: str,
        original_plan: AgentPlan,
        results: List[StepResult],
        verification: Verification,
        context: Dict
    ) -> AgentPlan:
        """Create a new plan based on previous attempt"""
        logger.info("Creating revised plan")
        
        # Include information about what failed
        prompt = f"""The previous plan failed. Create a revised plan.

Original Task: {task_description}

Previous Plan:
{self._format_plan_for_llm(original_plan)}

What went wrong:
{verification.reasoning}

Create a NEW plan that addresses these issues.
"""
        
        # For now, return modified original plan
        # Real implementation would generate new plan from LLM
        return original_plan
    
    async def _call_llm(self, prompt: str) -> str:
        """Call LLM with prompt (simplified interface)"""
        # This is a placeholder - real implementation would call actual LLM
        # through langchain or direct API
        logger.debug(f"LLM call with prompt length: {len(prompt)}")
        return "LLM response placeholder"
    
    def _format_plan_for_llm(self, plan: AgentPlan) -> str:
        """Format plan for LLM readability"""
        return "\n".join([
            f"{i+1}. {step.description} (using {', '.join(step.required_tools)})"
            for i, step in enumerate(plan.steps)
        ])
    
    def _format_results_for_llm(self, results: List[StepResult]) -> str:
        """Format results for LLM readability"""
        return "\n".join([
            f"Step {r.step_id}: {r.status.value} - {r.output if r.status == ExecutionStatus.COMPLETED else r.error_message}"
            for r in results
        ])
    
    def _extract_final_output(self, results: List[StepResult]) -> any:
        """Extract final output from execution results"""
        if not results:
            return None
        
        # Return output from last successful step
        for result in reversed(results):
            if result.status == ExecutionStatus.COMPLETED and result.output:
                return result.output
        
        return None
