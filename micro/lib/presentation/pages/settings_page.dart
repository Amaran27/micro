import 'package:flutter/material.dart';
import 'unified_provider_settings.dart';
import 'package:micro/features/mcp/presentation/pages/mcp_server_settings_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // AI Providers Section
          Card(
            child: ListTile(
              leading: const Icon(Icons.smart_toy),
              title: const Text('AI Providers'),
              subtitle:
                  const Text('Manage AI model providers and configurations'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UnifiedProviderSettings(),
                  ),
                );
              },
            ),
          ),

          // MCP Servers Section
          Card(
            child: ListTile(
              leading: const Icon(Icons.dns),
              title: const Text('MCP Servers'),
              subtitle:
                  const Text('Manage Model Context Protocol server connections'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MCPServerSettingsPage(),
                  ),
                );
              },
            ),
          ),

          // General Settings Section
          const Card(
            child: ListTile(
              leading: Icon(Icons.settings_applications),
              title: Text('General'),
              subtitle: Text('App preferences and settings'),
              trailing: Icon(Icons.arrow_forward_ios),
            ),
          ),

          // Privacy Section
          const Card(
            child: ListTile(
              leading: Icon(Icons.security),
              title: Text('Privacy & Security'),
              subtitle: Text('Privacy settings and security options'),
              trailing: Icon(Icons.arrow_forward_ios),
            ),
          ),

          // About Section
          const Card(
            child: ListTile(
              leading: Icon(Icons.info),
              title: Text('About'),
              subtitle: Text('App information and version details'),
              trailing: Icon(Icons.arrow_forward_ios),
            ),
          ),
        ],
      ),
    );
  }
}
