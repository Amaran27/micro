# MCP Integration for Micro

This directory contains the Model Context Protocol (MCP) integration for the Micro AI assistant.

## Architecture

### Core Components

1. **MCP Client Adapter** (`mcp_client_adapter.dart`)
   - Bridges MCP protocol with existing AI provider infrastructure
   - Handles multiple server connections
   - Manages MCP tools, resources, and prompts
   - Supports STDIO, SSE, and HTTP transports

2. **MCP AI Provider** (`mcp_ai_provider.dart`)
   - Riverpod provider for MCP AI functionality
   - Integrates with existing LangChain tools
   - Provides state management for MCP connections
   - Handles tool execution and AI responses

3. **MCP Server Discovery** (`mcp_server_discovery.dart`)
   - Discovers MCP servers automatically
   - Manages server configurations
   - Tests server connections
   - Supports multiple transport types

4. **MCP Service** (`mcp_service.dart`)
   - Coordinates all MCP functionality
   - Provides unified API for MCP operations
   - Includes UI for server management
   - Handles service lifecycle

## Usage

### Basic Setup

```dart
// Initialize MCP service
final mcpService = ref.read(mcpServiceProvider);
await mcpService.initialize();

// Get available tools
final tools = await mcpService.adapter?.listTools();

// Call a tool
final result = await mcpService.adapter?.callTool('calculator', {
  'operation': 'add',
  'a': 5,
  'b': 3,
});
```

### Server Configuration

```dart
// Add a new MCP server
await mcpService.addServer(MCPServerConfig(
  id: 'my-server',
  name: 'My MCP Server',
  transportType: MCPTransportType.stdio,
  url: '',
  command: 'npx',
  args: ['@modelcontextprotocol/server-filesystem'],
));

// Or HTTP/SSE server
await mcpService.addServer(MCPServerConfig(
  id: 'http-server',
  name: 'HTTP MCP Server',
  transportType: MCPTransportType.http,
  url: 'http://localhost:8080/mcp',
));
```

### AI Integration

```dart
// Use MCP tools with AI
final response = await mcpService.aiProvider?.executeRequest(
  prompt: 'Calculate 2+2 using the calculator tool',
  model: 'gpt-4-turbo',
);

// The provider will automatically:
// 1. Discover available MCP tools
// 2. Format them for LangChain
// 3. Execute AI request with tools
// 4. Handle tool calls and responses
```

## Features

### Supported Transport Types

1. **STDIO** - For local process communication
2. **SSE** (Server-Sent Events) - For HTTP-based streaming
3. **HTTP** - For REST-like API communication

### MCP Capabilities

- **Tools**: Execute functions on MCP servers
- **Resources**: Access data from MCP servers
- **Prompts**: Use templates from MCP servers
- **Sampling**: Request LLM text generation
- **Roots**: Manage filesystem boundaries

### Auto-Discovery

The system automatically discovers MCP servers:

- From configuration files (`mcp_servers.json`)
- Common installation directories
- NPM packages (`mcp-*`)
- Python packages (`pip list`)
- Executable files

## Configuration

### Server Config File

Create `mcp_servers.json` in your app documents directory:

```json
[
  {
    "id": "filesystem",
    "name": "Filesystem Access",
    "transportType": "stdio",
    "command": "npx",
    "args": ["@modelcontextprotocol/server-filesystem", "/path/to/directory"],
    "autoConnect": true
  },
  {
    "id": "github",
    "name": "GitHub Integration",
    "transportType": "http",
    "url": "http://localhost:3000/mcp",
    "headers": {
      "Authorization": "Bearer token"
    }
  }
]
```

### Provider Integration

```dart
// In your provider setup
final mcpConfig = MCPClientConfig(
  clientName: 'micro-assistant',
  clientVersion: '1.0.0',
  servers: [
    MCPServerConfig(...),
    // Add more servers
  ],
);

await ref.read(mcpAIProvider.notifier).initialize(mcpConfig);
```

## UI Integration

### Server Management Widget

```dart
MCPServerManagementWidget()
```

This provides:
- List of configured servers
- Connection status indicators
- Add/remove server functionality
- Test connection capabilities
- Auto-refresh of server list

## Error Handling

The MCP integration includes comprehensive error handling:

- Connection failures
- Transport errors
- Tool execution failures
- Server timeouts
- JSON parsing errors

All errors are logged and can be accessed through the state management system.

## Security

- API keys are stored securely using `flutter_secure_storage`
- Server connections are authenticated
- Filesystem access is sandboxed where possible
- Network connections use HTTPS/TLS when available

## Testing

Run tests with:
```bash
flutter test test/ai_proactive_integration_test.dart
```

## Future Enhancements

1. **More Transport Types**: WebSocket, gRPC
2. **Enhanced Security**: OAuth 2.1, token management
3. **Performance Monitoring**: Metrics and logging
4. **Offline Support**: Local tool caching
5. **Background Processing**: Async tool execution