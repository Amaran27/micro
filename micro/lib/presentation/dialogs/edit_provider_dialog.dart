import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:micro/infrastructure/ai/provider_config_model.dart';
import 'package:micro/infrastructure/ai/provider_registry.dart';
import 'package:micro/presentation/providers/provider_config_providers.dart';
import 'package:micro/presentation/widgets/custom_models_section.dart';
import 'package:micro/presentation/widgets/mcp_provider_config_widget.dart';

/// Dialog for editing an existing AI provider configuration
/// Allows updating API key, endpoint, deployment ID, models
/// Includes option to test connection again
class EditProviderDialog extends ConsumerStatefulWidget {
  final ProviderConfig config;

  const EditProviderDialog({
    super.key,
    required this.config,
  });

  @override
  ConsumerState<EditProviderDialog> createState() => _EditProviderDialogState();
}

class _EditProviderDialogState extends ConsumerState<EditProviderDialog> {
  late PageController _pageController;
  int _currentStep = 0;

  // Provider metadata
  ProviderMetadata? _providerMetadata;

  // API Key
  late TextEditingController _apiKeyController;
  bool _showApiKey = false;

  // Endpoint/Deployment
  late TextEditingController _endpointController;
  late TextEditingController _deploymentIdController;

  // Test connection state
  bool _isTesting = false;
  List<String> _availableModels = [];
  String? _testError;
  bool _testPassed = false;

  // Model selection
  late Set<String> _selectedModels;
  late Set<String> _customModels;

  // MCP Integration
  late bool _mcpEnabled;
  late List<String> _mcpServerIds;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    // Initialize from existing config
    _providerMetadata =
        ProviderRegistry().getProvider(widget.config.providerId);
    _apiKeyController = TextEditingController(text: widget.config.apiKey);
    _endpointController =
        TextEditingController(text: widget.config.endpoint ?? '');
    _deploymentIdController =
        TextEditingController(text: widget.config.deploymentId ?? '');
    _selectedModels = Set.from(widget.config.favoriteModels);
    _customModels = Set.from(widget.config.customModels);
    _testPassed = widget.config.testPassed;
    _availableModels = widget.config.favoriteModels;
    _mcpEnabled = widget.config.mcpEnabled;
    _mcpServerIds = List.from(widget.config.mcpServerIds);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _apiKeyController.dispose();
    _endpointController.dispose();
    _deploymentIdController.dispose();
    super.dispose();
  }

  bool _validateStep() {
    switch (_currentStep) {
      case 0:
        return _apiKeyController.text.isNotEmpty &&
            _apiKeyController.text.length > 5;
      case 1:
        return true;
      case 2:
        return _testPassed;
      case 3:
        return _selectedModels.isNotEmpty;
      case 4:
        return true; // MCP step is optional
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_validateStep()) {
      if (_currentStep < 4) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      _showValidationError();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showValidationError() {
    String message;
    switch (_currentStep) {
      case 0:
        message = 'API Key must be at least 6 characters';
        break;
      case 2:
        message = 'Please test connection first';
        break;
      case 3:
        message = 'Please select at least one model';
        break;
      default:
        message = 'Please fill in all required fields';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _testConnection() async {
    if (_apiKeyController.text.isEmpty) {
      setState(() {
        _testError = 'API Key is required';
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _testError = null;
      _availableModels = [];
      _testPassed = false;
    });

    try {
      final providerId = _providerMetadata!.id;
      final apiKey = _apiKeyController.text.trim();
      final dio = Dio();

      List<String> models = [];

      if (providerId == 'zhipu-ai') {
        // Real API call to ZhipuAI models endpoint (OpenAI-compatible)
        try {
          final resp = await dio.get(
            'https://api.z.ai/api/paas/v4/models',
            options: Options(
              headers: {
                'Authorization': 'Bearer $apiKey',
                'Content-Type': 'application/json',
                'Accept-Language': 'en-US,en',
              },
            ),
          );

          if (resp.statusCode == 200) {
            final data = resp.data;
            final List<dynamic> items = data['data'] as List<dynamic>? ?? [];
            models = items
                .map((m) => (m as Map<String, dynamic>)['id'] as String? ?? '')
                .where((id) => id.isNotEmpty)
                .toList();

            if (models.isEmpty) {
              setState(() {
                _testError =
                    'Connected to ZhipuAI, but no models were returned for this account.';
                _isTesting = false;
                _testPassed = false;
              });
              return;
            }

            setState(() {
              _availableModels = models;
              _testPassed = true;
              _isTesting = false;
            });
            return;
          } else {
            // Non-200
            setState(() {
              _testError =
                  'ZhipuAI responded with ${resp.statusCode}: ${resp.data}';
              _isTesting = false;
              _testPassed = false;
            });
            return;
          }
        } on DioException catch (e) {
          final status = e.response?.statusCode;
          final body = e.response?.data;
          String message = 'Connection failed';
          if (status == 401) {
            message = 'Authentication failed. Check your API key.';
          } else if (status == 429) {
            final code = (body is Map && body['error'] is Map)
                ? (body['error']['code'] as int?)
                : null;
            if (code == 1113 ||
                (body.toString().contains('Insufficient balance') ||
                    body.toString().contains('no resource package'))) {
              message =
                  'Insufficient balance or no resource package on your ZhipuAI account.';
            } else {
              message = 'Rate limited or service unavailable. Try again.';
            }
          } else if (status != null) {
            message = 'HTTP $status: $body';
          } else {
            message = e.message ?? 'Network error';
          }

          setState(() {
            _testError = message;
            _isTesting = false;
            _testPassed = false;
          });
          return;
        }
      }

      // Default: simple simulated lists for other providers (legacy behavior)
      switch (providerId) {
        case 'openai':
          models = [
            'gpt-4-turbo-preview',
            'gpt-4',
            'gpt-3.5-turbo',
            'gpt-3.5-turbo-16k',
          ];
          break;
        case 'anthropic':
          models = [
            'claude-3-opus-20240229',
            'claude-3-sonnet-20240229',
            'claude-3-haiku-20240307',
          ];
          break;
        case 'google':
          models = ['gemini-pro', 'gemini-pro-vision'];
          break;
        case 'azure':
          models = ['gpt-4', 'gpt-3.5-turbo', 'text-davinci-003'];
          break;
        case 'mistral':
          models = [
            'mistral-large-latest',
            'mistral-medium-latest',
            'mistral-small-latest',
          ];
          break;
        default:
          models = [];
      }

      setState(() {
        _availableModels = models;
        _testPassed = models.isNotEmpty;
        _testError =
            models.isEmpty ? 'No models found for this provider.' : null;
        _isTesting = false;
      });
    } catch (e) {
      setState(() {
        _testError = e.toString();
        _isTesting = false;
        _testPassed = false;
      });
    }
  }

  Future<void> _saveConfiguration() async {
    try {
      final updatedConfig = widget.config.copyWith(
        apiKey: _apiKeyController.text,
        endpoint: _endpointController.text.isNotEmpty
            ? _endpointController.text
            : null,
        deploymentId: _deploymentIdController.text.isNotEmpty
            ? _deploymentIdController.text
            : null,
        testPassed: _testPassed,
        favoriteModels: _selectedModels.toList(),
        lastTestedAt: DateTime.now(),
        mcpEnabled: _mcpEnabled,
        mcpServerIds: _mcpServerIds,
      );

      await ref.read(providerStorageServiceProvider).saveConfig(updatedConfig);
      ref.invalidate(providersConfigProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Provider updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating provider: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit ${_providerMetadata?.name ?? 'Provider'}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Step indicator
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) {
                  final isActive = index <= _currentStep;
                  return Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade300,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isActive ? Colors.white : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        if (index < 4)
                          Container(
                            height: 2,
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 4),
                            color: index < _currentStep
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade300,
                          ),
                      ],
                    ),
                  );
                }),
              ),
            ),

            // Content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentStep = index);
                },
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1_ApiKey(),
                  _buildStep2_Endpoint(),
                  _buildStep3_TestConnection(),
                  _buildStep4_ModelSelection(),
                  _buildStep5_MCPIntegration(),
                ],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: _currentStep > 0 ? _previousStep : null,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                  ),
                  if (_currentStep < 4)
                    ElevatedButton.icon(
                      onPressed: _nextStep,
                      label: const Text('Next'),
                      icon: const Icon(Icons.arrow_forward),
                    ),
                  if (_currentStep == 3)
                    ElevatedButton.icon(
                      onPressed: _saveConfiguration,
                      label: const Text('Save Changes'),
                      icon: const Icon(Icons.check),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1_ApiKey() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 1: Update API Key',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Update your ${_providerMetadata?.name} API key if needed:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _apiKeyController,
            obscureText: !_showApiKey,
            decoration: InputDecoration(
              labelText: 'API Key',
              hintText: 'sk-xxxxxxxx...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _showApiKey ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() => _showApiKey = !_showApiKey);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Leave blank to keep the current API key.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2_Endpoint() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 2: Configuration (Optional)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          if (_providerMetadata?.id == 'azure') ...[
            TextField(
              controller: _deploymentIdController,
              decoration: InputDecoration(
                labelText: 'Deployment ID',
                hintText: 'e.g., gpt-4-deployment',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _endpointController,
            decoration: InputDecoration(
              labelText: 'Custom Endpoint (Optional)',
              hintText: 'https://api.provider.com/v1',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'These fields are optional. Leave blank to use defaults.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3_TestConnection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 3: Test Connection',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          if (!_testPassed)
            ElevatedButton.icon(
              onPressed: _isTesting ? null : _testConnection,
              icon: _isTesting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_sync),
              label: Text(_isTesting ? 'Testing...' : 'Test Connection'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          if (_testPassed)
            ElevatedButton.icon(
              onPressed: _isTesting ? null : _testConnection,
              icon: _isTesting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(_isTesting ? 'Testing...' : 'Test Again'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          const SizedBox(height: 16),
          if (_testError != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _testError!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          if (_testPassed)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Connection successful! Found ${_availableModels.length} models.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                          ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStep4_ModelSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 4: Update Favorite Models',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Select models to use in chat:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),

          // Custom Models Section
          CustomModelsSection(
            customModels: _customModels,
            selectedModels: _selectedModels,
            availableModels: _availableModels,
            onAdd: (modelId) {
              setState(() {
                _customModels.add(modelId);
                _selectedModels.add(modelId);
              });
            },
            onRemove: (modelId) {
              setState(() {
                _customModels.remove(modelId);
                _selectedModels.remove(modelId);
              });
            },
          ),
          const SizedBox(height: 16), // Available Models Section
          Text(
            'Available Models (from API):',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          if (_availableModels.isEmpty && _customModels.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'No models available. Test connection to fetch models or add custom models above.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          else ...[
            // Show API models
            ..._availableModels.map((model) {
              return ModelSelectionTile(
                model: model,
                isSelected: _selectedModels.contains(model),
                isCustom: false,
                onChanged: (value) {
                  setState(() {
                    if (value ?? false) {
                      _selectedModels.add(model);
                    } else {
                      _selectedModels.remove(model);
                    }
                  });
                },
              );
            }),
            // Show custom models
            ..._customModels.map((model) {
              return ModelSelectionTile(
                model: model,
                isSelected: _selectedModels.contains(model),
                isCustom: true,
                onChanged: (value) {
                  setState(() {
                    if (value ?? false) {
                      _selectedModels.add(model);
                    } else {
                      _selectedModels.remove(model);
                    }
                  });
                },
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildStep5_MCPIntegration() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 5: MCP Integration (Optional)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Enable Model Context Protocol integration to extend this provider with additional tools',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          MCPProviderConfigWidget(
            mcpEnabled: _mcpEnabled,
            mcpServerIds: _mcpServerIds,
            onChanged: (enabled, serverIds) {
              setState(() {
                _mcpEnabled = enabled;
                _mcpServerIds = serverIds;
              });
            },
          ),
        ],
      ),
    );
  }
}
