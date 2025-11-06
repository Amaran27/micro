import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro/infrastructure/ai/mcp/recommended_servers.dart';
import 'package:micro/infrastructure/ai/mcp/models/mcp_models.dart';
import 'package:micro/infrastructure/ai/mcp/mcp_providers.dart';
import 'package:micro/features/mcp/presentation/widgets/mcp_server_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

/// MCP Server Discovery Page - Browse and install recommended servers
class MCPServerDiscoveryPage extends ConsumerStatefulWidget {
  const MCPServerDiscoveryPage({super.key});

  @override
  ConsumerState<MCPServerDiscoveryPage> createState() =>
      _MCPServerDiscoveryPageState();
}

class _MCPServerDiscoveryPageState extends ConsumerState<MCPServerDiscoveryPage> {
  String _searchQuery = '';
  String _platformFilter = 'all'; // all, desktop, mobile

  @override
  Widget build(BuildContext context) {
    final currentPlatform = Platform.isAndroid || Platform.isIOS ? 'mobile' : 'desktop';
    
    // Filter servers based on search and platform
    final filteredServers = recommendedMCPServers.where((server) {
      // Platform filter
      if (_platformFilter != 'all') {
        if (!server.supportedPlatforms.contains(_platformFilter)) {
          return false;
        }
      }
      
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return server.name.toLowerCase().contains(query) ||
            server.description.toLowerCase().contains(query);
      }
      
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover MCP Servers'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search servers...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),
              
              // Platform filter chips
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _platformFilter == 'all',
                      onSelected: (selected) {
                        setState(() => _platformFilter = 'all');
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Desktop'),
                      selected: _platformFilter == 'desktop',
                      onSelected: (selected) {
                        setState(() => _platformFilter = 'desktop');
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Mobile'),
                      selected: _platformFilter == 'mobile',
                      onSelected: (selected) {
                        setState(() => _platformFilter = 'mobile');
                      },
                    ),
                    const Spacer(),
                    Text(
                      '${filteredServers.length} servers',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: filteredServers.isEmpty
          ? _buildEmptyState()
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
                childAspectRatio: 0.85,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: filteredServers.length,
              itemBuilder: (context, index) {
                final server = filteredServers[index];
                final isCompatible = server.supportedPlatforms.contains(currentPlatform);
                return _buildServerCard(server, isCompatible);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No servers found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your search or filters',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildServerCard(RecommendedMCPServer server, bool isCompatible) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and compatibility badge
          Container(
            padding: const EdgeInsets.all(16),
            color: isCompatible
                ? Colors.blue.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            child: Row(
              children: [
                Text(
                  server.icon,
                  style: const TextStyle(fontSize: 40),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        server.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          ...server.supportedPlatforms.map((platform) =>
                              _buildPlatformBadge(platform)),
                          _buildTransportBadge(server.transportType),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Description
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                server.description,
                style: const TextStyle(color: Colors.grey),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          
          // Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (server.documentationUrl != null)
                  TextButton.icon(
                    onPressed: () => _openDocumentation(server.documentationUrl!),
                    icon: const Icon(Icons.help_outline, size: 16),
                    label: const Text('Docs'),
                  ),
                const Spacer(),
                if (!isCompatible)
                  Tooltip(
                    message: 'Not compatible with current platform',
                    child: ElevatedButton(
                      onPressed: null,
                      child: const Text('Install'),
                    ),
                  )
                else if (server.id == 'custom')
                  ElevatedButton.icon(
                    onPressed: () => _showCustomServerDialog(server),
                    icon: const Icon(Icons.settings),
                    label: const Text('Configure'),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () => _installServer(server),
                    icon: const Icon(Icons.download),
                    label: const Text('Install'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformBadge(String platform) {
    final icon = platform == 'desktop' ? Icons.computer : Icons.phone_android;
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(
        platform,
        style: const TextStyle(fontSize: 10),
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildTransportBadge(MCPTransportType transport) {
    return Chip(
      label: Text(
        transport.name.toUpperCase(),
        style: const TextStyle(fontSize: 10),
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: Colors.blue.withOpacity(0.2),
    );
  }

  Future<void> _openDocumentation(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open URL: $url')),
        );
      }
    }
  }

  void _installServer(RecommendedMCPServer server) {
    if (server.transportType == MCPTransportType.stdio) {
      _showStdioInstallDialog(server);
    } else {
      _showHttpServerDialog(server);
    }
  }

  void _showStdioInstallDialog(RecommendedMCPServer server) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Install ${server.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This server requires installation via command line:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
              ),
              child: SelectableText(
                server.installCommand ?? 'npm install -g ${server.id}',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'After installation, configure the server with:',
            ),
            const SizedBox(height: 8),
            Text(
              'Command: ${server.defaultConfig['command']}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'Args: ${server.defaultConfig['args']?.join(' ') ?? ''}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showConfigureDialog(server);
            },
            child: const Text('Configure Now'),
          ),
        ],
      ),
    );
  }

  void _showHttpServerDialog(RecommendedMCPServer server) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Install ${server.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(server.description),
            const SizedBox(height: 16),
            const Text(
              'Server URL:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              server.defaultConfig['url'] ?? 'http://localhost:8000/mcp',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Note: Make sure the server is running before connecting.',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showConfigureDialog(server);
            },
            child: const Text('Configure'),
          ),
        ],
      ),
    );
  }

  void _showConfigureDialog(RecommendedMCPServer server) {
    final config = MCPServerConfig(
      id: server.id,
      name: server.name,
      description: server.description,
      transportType: server.transportType,
      url: server.defaultConfig['url'],
      command: server.defaultConfig['command'],
      args: server.defaultConfig['args'] != null
          ? List<String>.from(server.defaultConfig['args'])
          : null,
      headers: server.defaultConfig['headers'] != null
          ? Map<String, String>.from(server.defaultConfig['headers'])
          : null,
      autoConnect: false,
    );

    showDialog(
      context: context,
      builder: (context) => MCPServerDialog(
        config: config,
        onSave: (finalConfig) async {
          try {
            await ref.read(mcpOperationsProvider.notifier).addServer(finalConfig);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Server "${finalConfig.name}" added')),
              );
              // Navigate back to settings
              Navigator.pop(context);
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to add server: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showCustomServerDialog(RecommendedMCPServer server) {
    showDialog(
      context: context,
      builder: (context) => MCPServerDialog(
        onSave: (config) async {
          try {
            await ref.read(mcpOperationsProvider.notifier).addServer(config);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Server "${config.name}" added')),
              );
              // Navigate back to settings
              Navigator.pop(context);
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to add server: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }
}
