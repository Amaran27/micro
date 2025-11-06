import 'models/mcp_models.dart';

/// List of recommended MCP servers for easy discovery and installation
final List<RecommendedMCPServer> recommendedMCPServers = [
  // Filesystem server - Desktop only
  RecommendedMCPServer(
    id: 'filesystem',
    name: 'Filesystem Access',
    description: 'Access and manipulate local files and directories. Provides tools for reading, writing, and managing files.',
    icon: '📁',
    transportType: MCPTransportType.stdio,
    supportedPlatforms: ['desktop'],
    platform: MCPServerPlatform.desktop,
    installCommand: 'npx -y @modelcontextprotocol/server-filesystem',
    defaultConfig: {
      'command': 'npx',
      'args': ['-y', '@modelcontextprotocol/server-filesystem', '/path/to/directory'],
    },
    documentationUrl: 'https://github.com/modelcontextprotocol/servers/tree/main/src/filesystem',
    docUrl: 'https://github.com/modelcontextprotocol/servers/tree/main/src/filesystem',
  ),
  
  // GitHub server - Both platforms
  RecommendedMCPServer(
    id: 'github',
    name: 'GitHub Integration',
    description: 'Interact with GitHub repositories, issues, and pull requests. Create branches, commits, and manage code reviews.',
    icon: '🐙',
    transportType: MCPTransportType.http,
    supportedPlatforms: ['desktop', 'mobile'],
    platform: MCPServerPlatform.both,
    defaultConfig: {
      'url': 'http://localhost:3000/mcp',
      'headers': {
        'Authorization': 'Bearer YOUR_GITHUB_TOKEN',
      },
    },
    documentationUrl: 'https://github.com/modelcontextprotocol/servers/tree/main/src/github',
    docUrl: 'https://github.com/modelcontextprotocol/servers/tree/main/src/github',
  ),
  
  // Brave Search - Both platforms
  RecommendedMCPServer(
    id: 'brave-search',
    name: 'Brave Search',
    description: 'Search the web using Brave Search API. Get up-to-date information from the internet.',
    icon: '🔍',
    transportType: MCPTransportType.http,
    supportedPlatforms: ['desktop', 'mobile'],
    platform: MCPServerPlatform.both,
    defaultConfig: {
      'url': 'http://localhost:3001/mcp',
      'headers': {
        'X-Subscription-Token': 'YOUR_BRAVE_SEARCH_API_KEY',
      },
    },
    documentationUrl: 'https://github.com/modelcontextprotocol/servers/tree/main/src/brave-search',
    docUrl: 'https://github.com/modelcontextprotocol/servers/tree/main/src/brave-search',
  ),
  
  // PostgreSQL - Desktop only
  RecommendedMCPServer(
    id: 'postgres',
    name: 'PostgreSQL Database',
    description: 'Connect to PostgreSQL databases. Query, insert, update, and manage database records.',
    icon: '🐘',
    transportType: MCPTransportType.stdio,
    supportedPlatforms: ['desktop'],
    platform: MCPServerPlatform.desktop,
    installCommand: 'npx -y @modelcontextprotocol/server-postgres',
    defaultConfig: {
      'command': 'npx',
      'args': ['-y', '@modelcontextprotocol/server-postgres', 'postgresql://user:password@localhost/dbname'],
    },
    documentationUrl: 'https://github.com/modelcontextprotocol/servers/tree/main/src/postgres',
    docUrl: 'https://github.com/modelcontextprotocol/servers/tree/main/src/postgres',
  ),
  
  // Slack - Both platforms
  RecommendedMCPServer(
    id: 'slack',
    name: 'Slack Integration',
    description: 'Send messages, read channels, and manage Slack workspaces. Automate team communication.',
    icon: '💬',
    transportType: MCPTransportType.http,
    supportedPlatforms: ['desktop', 'mobile'],
    platform: MCPServerPlatform.both,
    defaultConfig: {
      'url': 'http://localhost:3002/mcp',
      'headers': {
        'Authorization': 'Bearer xoxb-YOUR_SLACK_BOT_TOKEN',
      },
    },
    documentationUrl: 'https://github.com/modelcontextprotocol/servers/tree/main/src/slack',
    docUrl: 'https://github.com/modelcontextprotocol/servers/tree/main/src/slack',
  ),
  
  // Google Drive - Both platforms
  RecommendedMCPServer(
    id: 'google-drive',
    name: 'Google Drive',
    description: 'Access and manage files in Google Drive. Read, write, and organize documents and spreadsheets.',
    icon: '📊',
    transportType: MCPTransportType.http,
    supportedPlatforms: ['desktop', 'mobile'],
    platform: MCPServerPlatform.both,
    defaultConfig: {
      'url': 'http://localhost:3003/mcp',
      'headers': {
        'Authorization': 'Bearer YOUR_GOOGLE_OAUTH_TOKEN',
      },
    },
    documentationUrl: 'https://github.com/modelcontextprotocol/servers/tree/main/src/google-drive',
    docUrl: 'https://github.com/modelcontextprotocol/servers/tree/main/src/google-drive',
  ),
  
  // Git - Desktop only
  RecommendedMCPServer(
    id: 'git',
    name: 'Git Operations',
    description: 'Execute git commands and manage repositories. Clone, commit, push, pull, and manage branches.',
    icon: '🌿',
    transportType: MCPTransportType.stdio,
    supportedPlatforms: ['desktop'],
    platform: MCPServerPlatform.desktop,
    installCommand: 'npx -y @modelcontextprotocol/server-git',
    defaultConfig: {
      'command': 'npx',
      'args': ['-y', '@modelcontextprotocol/server-git'],
    },
    documentationUrl: 'https://github.com/modelcontextprotocol/servers/tree/main/src/git',
    docUrl: 'https://github.com/modelcontextprotocol/servers/tree/main/src/git',
  ),
  
  // Memory/Context - Both platforms
  RecommendedMCPServer(
    id: 'memory',
    name: 'Persistent Memory',
    description: 'Store and retrieve information across conversations. Create long-term memory for your AI assistant.',
    icon: '🧠',
    transportType: MCPTransportType.http,
    supportedPlatforms: ['desktop', 'mobile'],
    platform: MCPServerPlatform.both,
    defaultConfig: {
      'url': 'http://localhost:3004/mcp',
    },
    documentationUrl: 'https://github.com/modelcontextprotocol/servers/tree/main/src/memory',
    docUrl: 'https://github.com/modelcontextprotocol/servers/tree/main/src/memory',
  ),
  
  // Custom Server
  RecommendedMCPServer(
    id: 'custom',
    name: 'Custom Server',
    description: 'Connect to your own MCP server. Specify the connection details manually.',
    icon: '⚙️',
    transportType: MCPTransportType.http,
    supportedPlatforms: ['desktop', 'mobile'],
    platform: MCPServerPlatform.both,
    defaultConfig: {
      'url': 'http://localhost:8000/mcp',
    },
    documentationUrl: 'https://modelcontextprotocol.io/docs/servers/creating',
    docUrl: 'https://modelcontextprotocol.io/docs/servers/creating',
  ),
];

/// Get recommended servers filtered by platform
List<RecommendedMCPServer> getRecommendedServersForPlatform(String platform) {
  return recommendedMCPServers
      .where((server) => server.supportedPlatforms.contains(platform))
      .toList();
}

/// Get recommended servers filtered by transport type
List<RecommendedMCPServer> getRecommendedServersByTransport(MCPTransportType transport) {
  return recommendedMCPServers
      .where((server) => server.transportType == transport)
      .toList();
}
