"""
Database for Phase 2 - State persistence with SQLite.
Enables task history, checkpointing, and resume functionality.
"""
import asyncio
from datetime import datetime
from typing import List, Optional
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column
from sqlalchemy import String, DateTime, JSON, Text, Integer, select
import json as json_lib


class Base(DeclarativeBase):
    pass


class TaskRecord(Base):
    """Persisted task execution record"""
    __tablename__ = "tasks"
    
    task_id: Mapped[str] = mapped_column(String, primary_key=True)
    task_description: Mapped[str] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String)
    plan_json: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    context_json: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    result_json: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    error_message: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    replan_count: Mapped[int] = mapped_column(Integer, default=0)
    started_at: Mapped[datetime] = mapped_column(DateTime)
    completed_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    execution_time_seconds: Mapped[Optional[float]] = mapped_column(nullable=True)


class StepRecord(Base):
    """Persisted step execution record"""
    __tablename__ = "steps"
    
    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    task_id: Mapped[str] = mapped_column(String, index=True)
    step_id: Mapped[str] = mapped_column(String)
    step_index: Mapped[int] = mapped_column(Integer)
    description: Mapped[str] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String)
    output_json: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    error_message: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    started_at: Mapped[datetime] = mapped_column(DateTime)
    completed_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    execution_time_seconds: Mapped[Optional[float]] = mapped_column(nullable=True)


class Database:
    """Async database manager for task persistence"""
    
    def __init__(self, database_url: str = "sqlite+aiosqlite:///./agent_system.db"):
        self.engine = create_async_engine(database_url, echo=False)
        self.async_session = async_sessionmaker(
            self.engine, class_=AsyncSession, expire_on_commit=False
        )
    
    async def initialize(self):
        """Create tables"""
        async with self.engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
    
    async def save_task(self, task_record: TaskRecord):
        """Save or update a task"""
        async with self.async_session() as session:
            session.add(task_record)
            await session.commit()
    
    async def get_task(self, task_id: str) -> Optional[TaskRecord]:
        """Get a task by ID"""
        async with self.async_session() as session:
            result = await session.execute(
                select(TaskRecord).where(TaskRecord.task_id == task_id)
            )
            return result.scalar_one_or_none()
    
    async def list_tasks(self, limit: int = 100, offset: int = 0) -> List[TaskRecord]:
        """List recent tasks"""
        async with self.async_session() as session:
            result = await session.execute(
                select(TaskRecord)
                .order_by(TaskRecord.started_at.desc())
                .limit(limit)
                .offset(offset)
            )
            return list(result.scalars())
    
    async def save_step(self, step_record: StepRecord):
        """Save a step execution"""
        async with self.async_session() as session:
            session.add(step_record)
            await session.commit()
    
    async def get_task_steps(self, task_id: str) -> List[StepRecord]:
        """Get all steps for a task"""
        async with self.async_session() as session:
            result = await session.execute(
                select(StepRecord)
                .where(StepRecord.task_id == task_id)
                .order_by(StepRecord.step_index)
            )
            return list(result.scalars())
    
    async def delete_task(self, task_id: str):
        """Delete a task and its steps"""
        async with self.async_session() as session:
            # Delete steps
            await session.execute(
                select(StepRecord).where(StepRecord.task_id == task_id)
            )
            # Delete task
            task = await self.get_task(task_id)
            if task:
                await session.delete(task)
                await session.commit()
