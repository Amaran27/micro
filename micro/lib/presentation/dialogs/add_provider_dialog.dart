import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:micro/core/utils/logger.dart';
import 'package:micro/infrastructure/ai/provider_config_model.dart';
import 'package:micro/infrastructure/ai/provider_registry.dart';
import 'package:micro/infrastructure/ai/secure_api_storage.dart';
import 'package:micro/presentation/providers/provider_config_providers.dart';
import 'package:micro/presentation/widgets/custom_models_section.dart';

/// Multi-step dialog for adding a new AI provider configuration
/// Step 1: Select provider from registry
/// Step 2: Enter API key
/// Step 3: Enter optional endpoint/deployment ID
/// Step 4: Test connection and fetch available models
/// Step 5: Select favorite models
/// Step 6: Save configuration to storage
class AddProviderDialog extends ConsumerStatefulWidget {
  const AddProviderDialog({super.key});

  @override
  ConsumerState<AddProviderDialog> createState() => _AddProviderDialogState();
}

class _AddProviderDialogState extends ConsumerState<AddProviderDialog> {
  late PageController _pageController;
  int _currentStep = 0;

  // Step 1: Provider selection
  ProviderMetadata? _selectedProvider;

  // Step 2: API Key
  final _apiKeyController = TextEditingController();
  bool _showApiKey = false;

  // Step 3: Endpoint/Deployment
  final _endpointController = TextEditingController();
  final _deploymentIdController = TextEditingController();

  // Step 4: Test connection
  bool _isTesting = false;
  List<String> _availableModels = [];
  String? _testError;
  bool _testPassed = false;

  // Step 5: Model selection
  final Set<String> _selectedModels = {};
  final Set<String> _customModels = {};

  // Search filter
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _apiKeyController.dispose();
    _endpointController.dispose();
    _deploymentIdController.dispose();
    super.dispose();
  }

  // Validate current step
  bool _validateStep() {
    switch (_currentStep) {
      case 0:
        return _selectedProvider != null;
      case 1:
        return _apiKeyController.text.isNotEmpty &&
            _apiKeyController.text.length > 5;
      case 2:
        // Optional step, always valid
        return true;
      case 3:
        // Test must pass
        return _testPassed;
      case 4:
        return _selectedModels.isNotEmpty;
      default:
        return false;
    }
  }

  // Move to next step
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

  // Move to previous step
  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Show validation error
  void _showValidationError() {
    String message;
    switch (_currentStep) {
      case 0:
        message = 'Please select a provider';
        break;
      case 1:
        message = 'API Key must be at least 6 characters';
        break;
      case 3:
        message = 'Please test connection first';
        break;
      case 4:
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

  // Test connection and fetch available models
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
      // Temporarily store API key for testing
      await SecureApiStorage.saveApiKey(
          _selectedProvider!.id, _apiKeyController.text);

      // Fetch models from actual provider API
      List<String> models = await _fetchModelsFromProvider(
        _selectedProvider!.id,
        _apiKeyController.text,
      );

      // Check if models were found
      if (models.isEmpty) {
        setState(() {
          _testError =
              'Connection succeeded but no models found. Please verify your API key.';
          _testPassed = false;
          _isTesting = false;
          _availableModels = [];
        });
        return;
      }

      setState(() {
        _availableModels = models;
        _testPassed = true;
        _isTesting = false;
        if (_availableModels.isNotEmpty) {
          _selectedModels.add(_availableModels.first);
        }
      });
    } catch (e) {
      setState(() {
        _testError = 'Connection failed: ${e.toString()}';
        _testPassed = false;
        _isTesting = false;
      });
    }
  }

  /// Fetch models from provider API
  Future<List<String>> _fetchModelsFromProvider(
      String providerId, String apiKey) async {
    final dio = Dio();

    try {
      switch (providerId) {
        case 'openai':
          return await _fetchOpenAIModels(dio, apiKey);
        case 'anthropic':
          return await _fetchAnthropicModels(dio, apiKey);
        case 'google':
          return await _fetchGoogleModels(dio, apiKey);
        case 'zhipu-ai':
          return await _fetchZhipuaiModels(dio, apiKey);
        case 'mistral':
          return await _fetchMistralModels(dio, apiKey);
        case 'cohere':
          return await _fetchCohereModels(dio, apiKey);
        default:
          throw Exception('Provider $providerId is not supported yet');
      }
    } catch (e) {
      AppLogger().error('Failed to fetch models for $providerId', error: e);
      rethrow;
    }
  }

  Future<List<String>> _fetchOpenAIModels(Dio dio, String apiKey) async {
    final response = await dio.get(
      'https://api.openai.com/v1/models',
      options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
    );

    if (response.statusCode == 200) {
      final models = response.data['data'] as List;
      return models
          .where((m) => (m['id'] as String).startsWith('gpt-'))
          .map((m) => m['id'] as String)
          .toList();
    }
    return [];
  }

  Future<List<String>> _fetchAnthropicModels(Dio dio, String apiKey) async {
    final response = await dio.get(
      'https://api.anthropic.com/v1/models',
      options: Options(headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      }),
    );

    if (response.statusCode == 200) {
      final models = response.data['data'] as List;
      return models.map((m) => m['id'] as String).toList();
    }
    return [];
  }

  Future<List<String>> _fetchGoogleModels(Dio dio, String apiKey) async {
    final response = await dio.get(
      'https://generativelanguage.googleapis.com/v1beta/models',
      queryParameters: {'key': apiKey},
    );

    if (response.statusCode == 200) {
      final models = response.data['models'] as List;
      return models
          .where((m) =>
              m['supportedGenerationMethods']?.contains('generateContent') ??
              false)
          .map((m) => (m['name'] as String).replaceFirst('models/', ''))
          .toList();
    }
    return [];
  }

  Future<List<String>> _fetchZhipuaiModels(Dio dio, String apiKey) async {
    final response = await dio.get(
      'https://api.z.ai/api/paas/v4/models',
      options: Options(headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      }),
    );

    if (response.statusCode == 200) {
      final models = response.data['data'] as List;
      return models.map((m) => m['id'] as String).toList();
    }
    return [];
  }

  Future<List<String>> _fetchMistralModels(Dio dio, String apiKey) async {
    final response = await dio.get(
      'https://api.mistral.ai/v1/models',
      options: Options(headers: {'Authorization': 'Bearer $apiKey'}),
    );

    if (response.statusCode == 200) {
      final models = response.data['data'] as List;
      return models.map((m) => m['id'] as String).toList();
    }
    return [];
  }

  Future<List<String>> _fetchCohereModels(Dio dio, String apiKey) async {
    // Cohere doesn't have a public models endpoint, return known models
    return [
      'command-r-plus',
      'command-r',
      'command',
      'command-light',
      'command-nightly',
    ];
  }

  // Save configuration to storage
  Future<void> _saveConfiguration() async {
    try {
      final config = ProviderConfig(
        id: '${_selectedProvider!.id}_${DateTime.now().millisecondsSinceEpoch}',
        providerId: _selectedProvider!.id,
        apiKey: _apiKeyController.text,
        endpoint: _endpointController.text.isNotEmpty
            ? _endpointController.text
            : null,
        deploymentId: _deploymentIdController.text.isNotEmpty
            ? _deploymentIdController.text
            : null,
        isEnabled: true,
        isConfigured: true,
        testPassed: _testPassed,
        favoriteModels: _selectedModels.toList(),
        customModels: _customModels.toList(),
        createdAt: DateTime.now(),
        lastTestedAt: DateTime.now(),
      );

      // Save to storage
      await ref.read(providerStorageServiceProvider).saveConfig(config);

      // Invalidate provider to trigger UI updates
      ref.invalidate(providersConfigProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Provider added successfully!'),
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
            content: Text('Error saving provider: $e'),
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
                    'Add AI Provider',
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
                  _buildStep1_ProviderSelection(),
                  _buildStep2_ApiKey(),
                  _buildStep3_Endpoint(),
                  _buildStep4_TestConnection(),
                  _buildStep5_ModelSelection(),
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
                  if (_currentStep == 4)
                    ElevatedButton.icon(
                      onPressed: _saveConfiguration,
                      label: const Text('Save'),
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

  // Step 1: Select provider from registry
  Widget _buildStep1_ProviderSelection() {
    final providersMap = ProviderRegistry().getAllProviders();

    // Sort providers alphabetically by name
    final sortedProviders = providersMap.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    // Filter by search query
    final filteredProviders = _searchQuery.isEmpty
        ? sortedProviders
        : sortedProviders.where((p) {
            final query = _searchQuery.toLowerCase();
            return p.name.toLowerCase().contains(query) ||
                p.description.toLowerCase().contains(query) ||
                p.id.toLowerCase().contains(query);
          }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Step 1: Select Provider',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Search providers',
                  hintText: 'e.g., OpenAI, Claude, Google...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
              const SizedBox(height: 8),
              Text(
                '${filteredProviders.length} provider${filteredProviders.length != 1 ? 's' : ''} available',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredProviders.length,
            itemBuilder: (context, index) {
              final provider = filteredProviders[index];
              final isSelected = _selectedProvider?.id == provider.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  color: isSelected
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : null,
                  child: ListTile(
                    leading: Icon(
                      Icons.cloud,
                      color: provider.color,
                    ),
                    title: Text(provider.name),
                    subtitle: Text(provider.description),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(context).primaryColor,
                          )
                        : null,
                    onTap: () {
                      setState(() => _selectedProvider = provider);
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Step 2: Enter API Key
  Widget _buildStep2_ApiKey() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 2: API Key',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Enter your ${_selectedProvider?.name} API key:',
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
                    'Your API key is stored securely on this device only.',
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

  // Step 3: Endpoint/Deployment (optional)
  Widget _buildStep3_Endpoint() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 3: Configuration (Optional)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          if (_selectedProvider?.id == 'azure') ...[
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

  // Step 4: Test connection and fetch models
  Widget _buildStep4_TestConnection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 4: Test Connection',
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

  // Step 5: Select favorite models
  Widget _buildStep5_ModelSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 5: Select Models',
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
          const SizedBox(height: 16),

          // Available Models Section
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
}
