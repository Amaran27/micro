# Micro App - Complete Navigation & Feature Guide

## Overview
**Micro** is a privacy-first personal assistant app with autonomous agent capabilities. The app has been completely restructured to focus on autonomous agent management while maintaining support for chat, tools, and workflows.

---

## Main Navigation (Bottom Navigation Bar)

The app has 6 main sections accessible from the bottom navigation bar:

### 1. 🏠 **Home** (`/home`)
**Purpose**: Central hub and quick access dashboard

**Components**:
- **Welcome Header**: Displays "Welcome to Micro - Your privacy-first personal assistant"
- **Quick Actions Grid** (2x2):
  - **Chat Button** → Navigate to Chat page for direct conversations
  - **Dashboard Button** → View insights and analytics
  - **Tools Button** → Access available tools
  - **Agents Button** → Manage autonomous agents

**Use Case**: Starting point for users to quickly access major features of the app

---

### 2. 💬 **Chat** (`/chat`)
**Purpose**: AI-powered conversational interface with streaming responses

**Key Features**:
- **Dynamic Model Selection**: Automatically loads available AI models (ChatGPT, Claude, etc.)
- **Streaming Text Support**: Real-time AI responses display as they're generated
- **Markdown Rendering**: Responses are formatted with proper markdown support
- **Message History**: View and maintain conversation history
- **Responsive Design**: Works on mobile and tablet layouts
- **Agent Mode** (Optional): Toggle to enable autonomous agent capabilities within chat

**Buttons/Controls**:
- **Model Selector Dropdown**: Change AI model provider mid-conversation
- **Send Button**: Submit user prompts
- **Settings Icon**: Access chat preferences
- **Agent Mode Toggle**: Enable autonomous agent features
- **Message List**: View chat history

**Use Case**: Have natural conversations with AI, ask questions, generate content, and optionally enable autonomous agents to handle complex tasks

---

### 3. 📊 **Dashboard** (`/dashboard`)
**Purpose**: Monitor activity and get insights

**Displays (Stats Cards)**:
1. **Conversations Card**: Shows "12 conversations this week"
2. **Tools Used Card**: Shows "8 tools used this week"
3. **Workflows Card**: Shows "3 active workflows"
4. **Tasks Completed Card**: Shows "24 tasks completed"

**Additional Features**:
- Activity graphs and trends
- Usage statistics
- Performance metrics

**Use Case**: Track your usage patterns, monitor agent performance, and get insights into your app activity

---

### 4. 🤖 **Agents** (`/agents` → redirects to `/agent-dashboard`)
**Purpose**: Create and manage autonomous agents

**Main Interface**: Agent Dashboard with multiple sections

#### Agent Dashboard Components:

**Top Bar Actions**:
- **Refresh Button**: Refresh all agent data
- **Menu Button** with options:
  - "Create Agent" - Launch agent creation dialog
  - "Settings" - Access agent configuration
  - "Help" - Get usage information

**Tab 1: Active Agents**
- Shows list of currently running agents
- Each agent displays:
  - Agent name and ID
  - Current status (running/idle/error)
  - Start time and execution history
  - Actions: View details, pause, stop, delete

**Tab 2: Agent Execution**
- Monitor real-time agent execution
- Displays:
  - Current goals/tasks
  - Execution steps and progress
  - Resource usage
  - Tool execution logs
  - Memory state

**Tab 3: Agent Memory**
- View agent's learned experiences
- Shows:
  - Short-term memory (current session)
  - Long-term memory (persisted learnings)
  - Semantic memory (conceptual relationships)
  - Memory management tools (clear, export)

**Agent Creation Dialog** (from "Create Agent" button):
- **Agent Name**: Text field for custom agent name
- **Model Selection**: Choose AI model (GPT-4, Claude, etc.)
- **Agent Type**: Select specialization:
  - General Purpose
  - Research & Analysis
  - Code Generation
  - Content Creation
  - Task Automation
- **Configuration Options**:
  - Max Steps: Limit iterations
  - Temperature: Control creativity
  - Enable Memory: Toggle learning
  - Enable Reasoning: Toggle step-by-step reasoning
- **Create Button**: Instantiate new agent

**Use Case**: Create specialized autonomous agents to handle complex multi-step tasks, research projects, code generation, or automate workflows

---

### 5. 🔧 **Tools** (`/tools`)
**Purpose**: Browse and manage available tools

**Features**:
- **Tool List**: Shows all available tools with:
  - Tool name
  - Description
  - Mobile optimization indicator (mobile or desktop icon)
  - Category tags
  
- **Refresh Button**: Update tool list from available sources

- **Tool Categories** (planned):
  - File operations
  - Data processing
  - API integrations
  - Web utilities
  - System tools

- **Tap to View**: Click any tool to see:
  - Full description
  - Parameters and inputs
  - Usage examples
  - Integration guide

**Use Case**: Discover what tools are available to use within agents or workflows, understand capabilities, and integrate external services

---

### 6. ⚙️ **Settings** (`/settings`)
**Purpose**: Configure app preferences and integrations

**Current Options**:

1. **AI Providers** (Primary Configuration)
   - Navigate to dedicated provider settings page
   - Configure API keys for:
     - OpenAI (ChatGPT models)
     - Google (Gemini models)
     - Anthropic (Claude models)
     - Ollama (local models)
     - Other providers
   - Test connections
   - Set default provider
   - Manage model preferences

2. **General** (Coming Soon)
   - App theme preferences
   - Language selection
   - Notification settings
   - Auto-save preferences

3. **Privacy & Security** (Coming Soon)
   - Permission management
   - Data retention policies
   - Encryption settings
   - Privacy compliance options

4. **About** (Coming Soon)
   - App version information
   - Changelog
   - Developer information
   - License details

**Use Case**: Set up AI provider credentials, customize app behavior, and ensure privacy compliance

---

## Special Pages

### Onboarding Page (`/onboarding`)
**Purpose**: First-time user setup experience

**Flow**:
- Welcome introduction
- Feature overview
- AI provider setup wizard
- Permission requests
- Completion

**Auto-Redirects**: After onboarding is complete, users are automatically redirected to `/home`

---

### Error Page (`/error`)
**Purpose**: Handle and display errors gracefully

**Shows**:
- Error icon and message
- Detailed error information (when available)
- "Go Home" button
- "Go Back" button

---

## Key Features Explained

### 🤖 **Autonomous Agent System**
- **Self-Directed Execution**: Agents can break down complex tasks into steps
- **Memory System**: Agents learn from experiences across sessions
- **Tool Integration**: Agents can use tools to accomplish goals
- **Multi-Agent Collaboration**: Multiple agents can work together
- **Resource Management**: Built-in limits to prevent runaway execution
- **Reasoning Capabilities**: Step-by-step problem solving with transparency

### 💾 **Agent Memory Types**
1. **Short-term Memory**: Current execution context and session data
2. **Long-term Memory**: Persisted learnings and past experiences
3. **Semantic Memory**: Conceptual knowledge and relationships

### 🔐 **Privacy & Compliance**
- **Store-Compliant**: Follows app store policies
- **Permission Auditing**: Tracks all permission usage
- **Privacy First**: No data collection by default
- **Local Processing**: Prefers local models when available

### 🎯 **Workflow Support** (Coming Soon)
- Automate repeated tasks
- Chain tools together
- Schedule execution
- Monitor progress
- Create templates

---

## Navigation Flow Diagram

```
Entry
  ↓
Onboarding ←→ (First Time Users)
  ↓
Home (Landing Page)
  ├→ Chat (Conversational AI)
  ├→ Dashboard (Analytics)
  ├→ Tools (Tool Browser)
  ├→ Agents (Agent Management)
  │   ├→ Create Agent
  │   ├→ View Active Agents
  │   ├→ Monitor Execution
  │   └→ Review Memory
  ├→ Workflows (Automation - Coming Soon)
  └→ Settings
      ├→ AI Providers (Configure)
      ├→ General (Preferences)
      ├→ Privacy & Security
      └→ About
```

---

## Button Quick Reference

| Button/Control | Page | Action |
|---|---|---|
| Chat Card | Home | Navigate to Chat page |
| Dashboard Card | Home | Navigate to Dashboard |
| Tools Card | Home | Navigate to Tools page |
| Agents Card | Home | Navigate to Agents dashboard |
| Send Button | Chat | Submit message to AI |
| Model Selector | Chat | Change AI model |
| Refresh | Dashboard | Refresh analytics |
| Create Agent | Agents | Open agent creation dialog |
| Pause/Stop/Delete | Agents | Control agent execution |
| View Details | Agents/Tools | Open detail page |
| Settings Card | Settings | Open section (varies) |
| AI Providers | Settings | Configure AI credentials |

---

## Common User Workflows

### Workflow 1: Quick Chat Question
1. Tap **Chat** from home or nav bar
2. Type your question
3. Select model if needed
4. Tap Send
5. View streaming response with markdown formatting

### Workflow 2: Create Autonomous Agent
1. Tap **Agents** from nav bar
2. Tap menu → "Create Agent"
3. Name your agent
4. Select AI model
5. Choose agent type (e.g., Research, Code Generation)
6. Configure options
7. Tap Create
8. Monitor execution in the Active Agents tab

### Workflow 3: Check Usage Stats
1. Tap **Dashboard** from nav bar or home card
2. View conversation, tool, and workflow statistics
3. Tap any stat for detailed breakdown
4. Export data if needed

### Workflow 4: Configure AI Provider
1. Tap **Settings** from nav bar
2. Tap "AI Providers"
3. Select provider (OpenAI, Google, etc.)
4. Enter API key
5. Test connection
6. Set as default (optional)
7. Save

---

## Architecture Summary

**Tech Stack**:
- **Flutter**: UI framework
- **Riverpod**: State management
- **GoRouter**: Navigation
- **LangChain**: AI/Agent orchestration
- **WebSocket**: Real-time communication for agents

**Data Flow**:
1. User interaction → UI Layer
2. UI triggers Providers (Riverpod)
3. Providers call Services/Infrastructure
4. AI models or Agents process requests
5. Results update UI via reactive providers

---

## Notes for Developers

- **Disabled Modules**: Several AI provider integrations (langchain_openai, langchain_google) were temporarily disabled to resolve build issues. These can be re-enabled when packages are added to pubspec.yaml
- **MCP Adapter**: Model Context Protocol adapter files are currently disabled but infrastructure is in place for future integration
- **Workflows**: Coming soon - infrastructure is partially built
- **Future Enhancements**: Real workflow editor, advanced analytics, multi-user support

---

## Troubleshooting

**Problem**: Can't find AI models in dropdown
- **Solution**: Go to Settings → AI Providers and configure at least one provider with valid credentials

**Problem**: Agents not executing
- **Solution**: Check that memory is enabled and agent has access to necessary tools

**Problem**: Chat not responding
- **Solution**: Verify internet connection and check Settings for active AI provider

**Problem**: Tools list empty
- **Solution**: Refresh tools list using the refresh button; ensure necessary permissions are granted

---

For more information, check the CRUSH.md and project documentation files.
