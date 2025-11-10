# Micro Agent System - Desktop Backend

Python/FastAPI backend for the Micro autonomous agent system.

## Features

- **Phase 1**: REST API for agent task execution
- **Phase 2**: WebSocket streaming for real-time updates  
- **Phase 3**: MCP protocol for standardized communication

## Setup

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env with your API keys

# Run server
python main.py
```

## API Endpoints (Phase 1)

- `POST /api/v1/agent/task` - Execute agent task
- `GET /api/v1/agent/task/{task_id}` - Get task status
- `GET /api/v1/agent/tools` - List available tools
- `GET /api/v1/health` - Health check

## Architecture

```
backend/
├── main.py                  # FastAPI application
├── config/                  # Configuration
├── domain/                  # Domain models
├── infrastructure/          # Implementation
│   ├── agents/              # Agent logic
│   ├── tools/               # Tool implementations
│   ├── llm/                 # LLM providers
│   └── communication/       # API/WS/MCP
└── tests/                   # Test suites
```

## Testing

```bash
pytest tests/ -v --cov=.
```
