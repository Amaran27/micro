# Autonomous Agent System

The Autonomous Agent System provides a comprehensive framework for creating, managing, and executing AI agents with sophisticated capabilities including planning, reasoning, memory management, and tool execution.

## Overview

This system is built on top of LangChain.dart and integrates with the existing Model Context Protocol (MCP) infrastructure. It enables the creation of autonomous agents that can understand goals, create execution plans, reason through problems, and use available tools to accomplish complex tasks.

## Architecture

### Core Components

1. **Agent Types** (`agent_types.dart`)
   - Defines interfaces and data structures for all agent operations
   - Includes `AutonomousAgent` base interface, `AgentResult`, `AgentStep`, and other core types
   - Provides enums for agent status, step types, and memory types

2. **Autonomous Agent Implementation** (`autonomous_agent.dart`)
   - Main agent implementation with planning, reasoning, and execution capabilities
   - Handles multi-step execution with real-time monitoring
   - Integrates with memory system and MCP bridge for tool access

3. **Memory System** (`agent_memory.dart`)
   - Multi-type memory management: conversation, episodic, semantic, and working memory
   - Implements relevance scoring, search, and pruning strategies
   - Supports memory import/export and statistics

4. **MCP-LangChain Bridge** (`mcp_langchain_bridge.dart`)
   - Converts between MCP protocol and LangChain tool formats
   - Provides tool wrappers for different tool types
   - Handles result conversion and error mapping

5. **Service Layer** (`agent_service.dart`)
   - High-level agent management and execution service
   - Supports multiple agents and collaborative task execution
   - Provides agent lifecycle management and statistics

6. **State Management** (`agent_providers.dart`)
   - Riverpod providers for reactive agent state management
   - Includes execution notifiers, management notifiers, and real-time streaming
   - Supports agent creation, configuration, and monitoring

### UI Components

1. **Agent Status Widget** (`agent_status_widget.dart`)
   - Displays agent status, performance metrics, and execution history
   - Provides real-time monitoring with animated indicators
   - Shows detailed execution steps and results

2. **Agent Execution Widget** (`agent_execution_widget.dart`)
   - UI for executing agent goals with configuration options
   - Supports goal input, context specification, and parameter configuration
   - Shows real-time execution progress and results

3. **Agent Creation Dialog** (`agent_creation_dialog.dart`)
   - Dialog for creating new agents with various configuration options
   - Supports different agent types: general, specialized, and collaborative
   - Provides tool selection and advanced configuration options

4. **Agent Memory Widget** (`agent_memory_widget.dart`)
   - UI for viewing, searching, and managing agent memories
   - Supports memory search, filtering by type, and adding custom memories
   - Shows memory statistics and detailed memory information

5. **Agent Dashboard** (`agent_dashboard_page.dart`)
   - Main dashboard for agent management and monitoring
   - Provides tabs for overview, execution, and memory management
   - Includes performance analytics and quick action buttons

## Key Features

### 1. Agent Creation and Management

```dart
// Create a basic agent
final agentId = await service.createAgent(
  name: 'Research Assistant',
  model: 'gpt-4',
  temperature: 0.7,
  maxSteps: 15,
  enableMemory: true,
  enableReasoning: true,
);

// Create a specialized agent
final specializedId = await service.createSpecializedAgent(
  specialization: 'research',
  model: 'claude-3-opus-20240229',
  requiredTools: ['web-search', 'document-analysis'],
);
```

### 2. Agent Execution

```dart
// Execute a simple goal
final result = await service.executeGoal(
  goal: 'Research the latest developments in quantum computing',
  agentId: agentId,
);

// Execute with context and parameters
final result = await service.executeGoal(
  goal: 'Analyze the provided document',
  agentId: agentId,
  context: 'User is preparing for a research presentation',
  parameters: {
    'document_path': '/path/to/document.pdf',
    'analysis_depth': 'detailed',
  },
);
```

### 3. Collaborative Execution

```dart
// Execute collaborative task
final results = await service.executeCollaborativeTask(
  goal: 'Prepare a comprehensive market analysis',
  agentIds: ['research-agent', 'analysis-agent', 'writing-agent'],
  sharedContext: {
    'industry': 'technology',
    'timeframe': 'Q4 2023',
    'focus_areas': ['AI', 'cloud computing', 'mobile'],
  },
);
```

### 4. Memory Management

```dart
// Add custom memory
await service.addMemory(
  type: AgentMemoryType.semantic,
  content: 'User prefers concise summaries with bullet points',
  metadata: {
    'source': 'user_feedback',
    'priority': 'high',
  },
  agentId: agentId,
);

// Search memories
final relevantMemories = await service.searchMemories(
  query: 'user preferences for document format',
  agentId: agentId,
  limit: 5,
  types: [AgentMemoryType.semantic],
);
```

### 5. Agent Monitoring

```dart
// Get agent statistics
final stats = await service.getAgentStatistics(agentId: agentId);
print('Success rate: ${stats['success_rate']}');
print('Average steps: ${stats['average_steps']}');
print('Total executions: ${stats['execution_count']}');

// Get execution history
final history = service.getExecutionHistory(agentId: agentId);
for (final execution in history) {
  print('${execution.goal}: ${execution.result.success ? 'SUCCESS' : 'FAILED'}');
}
```

## Configuration

### Agent Configuration Options

```dart
class AgentConfig {
  final String model;
  final double temperature;
  final int maxSteps;
  final bool enableMemory;
  final bool enableReasoning;
  final bool enableCollaboration;
  final List<String> preferredTools;
  final Map<String, dynamic> customParameters;
}
```

### Memory System Configuration

```dart
class MemoryConfig {
  final int maxMemoriesPerType;
  final double relevanceThreshold;
  final Duration memoryLifetime;
  final bool enablePersistence;
  final String storagePath;
}
```

### Available Agent Types

1. **General Purpose Agent**
   - Versatile agent for general tasks
   - Can use all available tools
   - Suitable for everyday assistance tasks

2. **Specialized Agent**
   - Optimized for specific domains
   - Pre-configured tools and parameters
   - Examples: research, analysis, planning, writing

3. **Collaborative Agent**
   - Designed to work with other agents
   - Shares context and results
   - Supports multi-agent workflows

## Integration with Existing Systems

### MCP Integration

The agent system seamlessly integrates with the existing MCP infrastructure:

```dart
// MCP tools are automatically converted and made available
final tools = await service.getAvailableTools();
// Returns: ['web-search', 'file-read', 'file-write', 'database-query', ...]
```

### Provider Integration

Agents work with existing AI providers:

```dart
// Supported providers
final supportedModels = [
  'gpt-4', 'gpt-4-turbo', 'gpt-3.5-turbo',
  'claude-3-sonnet-20240229', 'claude-3-opus-20240229',
  'gemini-pro', 'llama2-70b-chat', 'mistral-7b',
];
```

### State Management Integration

Uses Riverpod for reactive state management:

```dart
// Watch agent status
final agentStatus = ref.watch(defaultAgentStatusProvider);

// Watch execution results
final executionResult = ref.watch(agentExecutionProvider);

// Manage agents
final agentManagement = ref.watch(agentManagementProvider);
```

## Best Practices

### 1. Agent Design

- **Start Simple**: Begin with general purpose agents before creating specialized ones
- **Define Clear Goals**: Agents work best with specific, achievable goals
- **Use Context Effectively**: Provide relevant context to improve agent performance
- **Monitor Performance**: Track success rates and execution times

### 2. Memory Management

- **Regular Pruning**: Set appropriate memory limits and pruning strategies
- **Relevance Scoring**: Use appropriate relevance thresholds for your use case
- **Memory Types**: Choose appropriate memory types for different information

### 3. Tool Usage

- **Tool Selection**: Provide agents with relevant tools for their tasks
- **Tool Safety**: Ensure tools have appropriate safety measures
- **Tool Testing**: Test tools with agents before deployment

### 4. Performance Optimization

- **Batch Operations**: Use batch operations for multiple goals
- **Concurrent Execution**: Leverage concurrent execution for independent tasks
- **Memory Optimization**: Monitor memory usage and adjust configurations

## Troubleshooting

### Common Issues

1. **Agent Not Responding**
   - Check if the agent is properly initialized
   - Verify the LLM connection and API keys
   - Review agent logs for error messages

2. **Memory Issues**
   - Check memory configuration limits
   - Verify storage permissions and space
   - Review memory relevance scoring

3. **Tool Execution Failures**
   - Verify tool configuration and permissions
   - Check MCP bridge status
   - Review tool-specific error messages

4. **Performance Problems**
   - Monitor agent execution times
   - Check memory usage patterns
   - Review LLM response times

### Debug Mode

Enable debug mode for detailed logging:

```dart
final service = AgentService(ref, debugMode: true);
```

## Examples

### Example 1: Research Assistant

```dart
// Create a research assistant agent
final researchAgentId = await service.createAgent(
  name: 'Research Assistant',
  model: 'gpt-4',
  temperature: 0.3, // Lower temperature for more focused responses
  maxSteps: 20,
  enableMemory: true,
  preferredTools: ['web-search', 'document-analysis', 'citation-extraction'],
);

// Research a topic
final researchResult = await service.executeGoal(
  goal: 'Research recent advances in quantum computing and prepare a summary',
  agentId: researchAgentId,
  parameters: {
    'search_depth': 'comprehensive',
    'include_citations': true,
    'focus_areas': ['quantum algorithms', 'hardware developments'],
  },
);
```

### Example 2: Data Analysis Agent

```dart
// Create a data analysis agent
final analysisAgentId = await service.createSpecializedAgent(
  specialization: 'analysis',
  model: 'claude-3-opus-20240229',
  requiredTools: ['data-analysis', 'visualization', 'statistical-modeling'],
);

// Analyze dataset
final analysisResult = await service.executeGoal(
  goal: 'Analyze the sales dataset and identify key trends',
  agentId: analysisAgentId,
  context: 'Monthly sales data for 2023, focus on regional performance',
  parameters: {
    'dataset_path': '/data/sales_2023.csv',
    'analysis_types': ['trend', 'comparison', 'forecast'],
    'visualizations': true,
  },
);
```

### Example 3: Multi-Agent Collaboration

```dart
// Create specialized agents
final researchId = await service.createSpecializedAgent(
  specialization: 'research',
  model: 'gpt-4',
);

final writingId = await service.createSpecializedAgent(
  specialization: 'writing',
  model: 'claude-3-opus-20240229',
);

// Collaborative content creation
final collaborativeResult = await service.executeCollaborativeTask(
  goal: 'Create a comprehensive guide about machine learning',
  agentIds: [researchId, writingId],
  sharedContext: {
    'target_audience': 'technical beginners',
    'required_sections': ['introduction', 'algorithms', 'applications'],
    'word_count': 5000,
  },
);
```

## API Reference

### Core Classes

#### `AgentService`

Main service class for agent management.

```dart
class AgentService {
  // Agent management
  Future<String> createAgent({...});
  Future<String> createSpecializedAgent({...});
  Future<void> removeAgent(String agentId);
  List<String> listAgents();

  // Execution
  Future<AgentResult> executeGoal({...});
  Future<Map<String, AgentResult>> executeCollaborativeTask({...});
  Future<void> cancelExecution();

  // Memory
  Future<void> addMemory({...});
  Future<List<AgentMemoryEntry>> searchMemories({...});
  Map<String, dynamic> getMemoryStatistics({String? agentId});

  // Statistics and history
  List<AgentExecution> getExecutionHistory({String? agentId});
  Future<Map<String, dynamic>> getAgentStatistics({String? agentId});
}
```

#### `AutonomousAgent`

Core agent interface.

```dart
abstract class AutonomousAgent {
  Future<AgentResult> execute({...});
  AgentStatus get status;
  List<AgentExecution> get executionHistory;
  Future<void> cancel();
  List<AgentCapability> get capabilities;
}
```

### Data Types

#### `AgentResult`

Result of agent execution.

```dart
class AgentResult {
  final String result;
  final bool success;
  final List<AgentStep> steps;
  final String? error;
  final Map<String, dynamic>? metadata;
}
```

#### `AgentStep`

Single step in agent execution.

```dart
class AgentStep {
  final String stepId;
  final String description;
  final AgentStepType type;
  final Map<String, dynamic>? input;
  final Map<String, dynamic>? output;
  final DateTime timestamp;
  final Duration duration;
}
```

#### `AgentMemoryEntry`

Entry in agent memory.

```dart
class AgentMemoryEntry {
  final String content;
  final AgentMemoryType type;
  final Map<String, dynamic>? metadata;
  final double relevance;
  final DateTime timestamp;
}
```

## Development and Testing

### Running Tests

```bash
# Run all agent tests
flutter test test/agent_system_test.dart

# Run specific test groups
flutter test test/agent_system_test.dart --tags="memory"
flutter test test/agent_system_test.dart --tags="execution"
```

### Adding New Agent Types

1. Extend `AgentCapability` enum
2. Update agent configuration options
3. Implement specialized behavior
4. Add appropriate tests
5. Update documentation

### Adding New Tools

1. Implement the tool in the MCP system
2. Add tool conversion logic to the bridge
3. Update tool selection UI
4. Add tool-specific tests
5. Update tool documentation

## Contributing

When contributing to the agent system:

1. **Follow the architecture**: Maintain separation between core, service, and UI layers
2. **Write tests**: Ensure comprehensive test coverage for new features
3. **Update documentation**: Keep README and code comments current
4. **Performance considerations**: Monitor agent performance and memory usage
5. **Error handling**: Implement proper error handling and logging

## Future Enhancements

Planned improvements include:

1. **Enhanced Memory Systems**: Vector-based memory with semantic search
2. **Multi-Agent Framework**: More sophisticated collaboration patterns
3. **Agent Learning**: Self-improvement capabilities based on execution results
4. **Performance Optimization**: Caching, batching, and parallel execution
5. **Advanced UI**: More sophisticated visualization and monitoring tools
6. **Security Features**: Agent authentication, authorization, and audit logging

## License

This agent system is part of the Micro project and follows the same license terms.