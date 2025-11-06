import 'dart:io';
import 'package:flutter/material.dart';
import 'package:micro/infrastructure/ai/mcp/models/mcp_models.dart';
import 'package:uuid/uuid.dart';

/// Dialog for adding or editing MCP server configurations
class MCPServerDialog extends StatefulWidget {
  final MCPServerConfig? config;
  final Function(MCPServerConfig) onSave;

  const MCPServerDialog({
    super.key,
    this.config,
    required this.onSave,
  });

  @override
  State<MCPServerDialog> createState() => _MCPServerDialogState();
}

class _MCPServerDialogState extends State<MCPServerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _urlController = TextEditingController();
  final _commandController = TextEditingController();
  final _argsController = TextEditingController();
  
  MCPTransportType _transportType = MCPTransportType.http;
  bool _autoConnect = false;
  final Map<String, String> _headers = {};
  final Map<String, String> _env = {};

  @override
  void initState() {
    super.initState();
    if (widget.config != null) {
      _nameController.text = widget.config!.name;
      _descriptionController.text = widget.config!.description;
      _transportType = widget.config!.transportType;
      _autoConnect = widget.config!.autoConnect;
      
      if (widget.config!.url != null) {
        _urlController.text = widget.config!.url!;
      }
      if (widget.config!.command != null) {
        _commandController.text = widget.config!.command!;
      }
      if (widget.config!.args != null) {
        _argsController.text = widget.config!.args!.join(' ');
      }
      if (widget.config!.headers != null) {
        _headers.addAll(widget.config!.headers!);
      }
      if (widget.config!.env != null) {
        _env.addAll(widget.config!.env!);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    _commandController.dispose();
    _argsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.config != null;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            AppBar(
              title: Text(isEditing ? 'Edit MCP Server' : 'Add MCP Server'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Basic Information
                    Text(
                      'Basic Information',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Server Name',
                        hintText: 'e.g., My Filesystem Server',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a server name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'What does this server do?',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    
                    // Transport Type
                    Text(
                      'Transport Type',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<MCPTransportType>(
                      value: _transportType,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: MCPTransportType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.name.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _transportType = value);
                        }
                      },
                    ),
                    
                    // Platform warning for stdio
                    if (_transportType == MCPTransportType.stdio &&
                        (Platform.isAndroid || Platform.isIOS)) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          border: Border.all(color: Colors.orange),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'stdio transport is not supported on mobile. Please use HTTP or SSE.',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Transport-specific fields
                    if (_transportType == MCPTransportType.stdio) ...[
                      Text(
                        'Stdio Configuration',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _commandController,
                        decoration: const InputDecoration(
                          labelText: 'Command',
                          hintText: 'e.g., npx, python, node',
                          border: OutlineInputBorder(),
                          helperText: 'The executable command to run',
                        ),
                        validator: (value) {
                          if (_transportType == MCPTransportType.stdio &&
                              (value == null || value.isEmpty)) {
                            return 'Please enter a command';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _argsController,
                        decoration: const InputDecoration(
                          labelText: 'Arguments',
                          hintText: 'e.g., -y @modelcontextprotocol/server-filesystem /path',
                          border: OutlineInputBorder(),
                          helperText: 'Space-separated command arguments',
                        ),
                        maxLines: 2,
                      ),
                      
                      const SizedBox(height: 16),
                      const Text(
                        'Examples:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildExample(
                        'Filesystem',
                        'npx',
                        '-y @modelcontextprotocol/server-filesystem /path/to/dir',
                      ),
                      _buildExample(
                        'Git',
                        'npx',
                        '-y @modelcontextprotocol/server-git',
                      ),
                    ] else ...[
                      Text(
                        'HTTP/SSE Configuration',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          labelText: 'Server URL',
                          hintText: 'e.g., http://localhost:8000/mcp',
                          border: OutlineInputBorder(),
                          helperText: 'The HTTP/SSE endpoint URL',
                        ),
                        validator: (value) {
                          if (_transportType != MCPTransportType.stdio) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a URL';
                            }
                            try {
                              Uri.parse(value);
                            } catch (e) {
                              return 'Please enter a valid URL';
                            }
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      const Text(
                        'Examples:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildExample(
                        'GitHub',
                        'http://localhost:3000/mcp',
                        'Add Authorization header with GitHub token',
                      ),
                      _buildExample(
                        'Brave Search',
                        'http://localhost:3001/mcp',
                        'Add X-Subscription-Token header with API key',
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Options
                    Text(
                      'Options',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    
                    SwitchListTile(
                      title: const Text('Auto-connect on startup'),
                      subtitle: const Text(
                        'Automatically connect to this server when the app starts',
                      ),
                      value: _autoConnect,
                      onChanged: (value) {
                        setState(() => _autoConnect = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _save,
                    child: Text(isEditing ? 'Update' : 'Add'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExample(String title, String value1, String value2) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            Text(
              '$value1 $value2',
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final config = MCPServerConfig(
      id: widget.config?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      transportType: _transportType,
      url: _transportType != MCPTransportType.stdio
          ? _urlController.text.trim()
          : null,
      command: _transportType == MCPTransportType.stdio
          ? _commandController.text.trim()
          : null,
      args: _transportType == MCPTransportType.stdio &&
              _argsController.text.trim().isNotEmpty
          ? _argsController.text.trim().split(' ')
          : null,
      headers: _headers.isNotEmpty ? _headers : null,
      env: _env.isNotEmpty ? _env : null,
      autoConnect: _autoConnect,
      enabled: true,
    );

    widget.onSave(config);
    Navigator.pop(context);
  }
}
