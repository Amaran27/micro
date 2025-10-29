import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/ai_provider_constants.dart';
import '../../infrastructure/ai/secure_api_storage.dart';
import '../../infrastructure/ai/ai_provider_config.dart';
import '../../infrastructure/ai/model_selection_service.dart';
import '../widgets/api_configuration_dialog.dart';
import '../widgets/provider_model_selection_dialog.dart';

class UnifiedProviderSettings extends ConsumerStatefulWidget {
  const UnifiedProviderSettings({super.key});

  @override
  ConsumerState<UnifiedProviderSettings> createState() =>
      _UnifiedProviderSettingsState();
}

class _UnifiedProviderSettingsState
    extends ConsumerState<UnifiedProviderSettings> {
  // Simple dynamic models storage
  final Map<String, List<String>> _providerModels = {};
  final AIProviderConfig _aiProviderConfig = AIProviderConfig();
  final Map<String, bool> _isConfigured = {};
  late final ModelSelectionService _modelSelectionService;

  @override
  void initState() {
    super.initState();
    _modelSelectionService = ModelSelectionService.instance;
    _initializeProviders();
    _fetchProviderModels();
    _checkConfiguredProviders();
  }

  Future<void> _initializeProviders() async {
    await _aiProviderConfig.initialize();
  }

  Future<void> _fetchProviderModels() async {
    // Use default models from constants
    setState(() {
      _providerModels.clear();
      _providerModels.addAll(AIProviderConstants.defaultModels);
    });
  }

  Future<void> _checkConfiguredProviders() async {
    try {
      for (final providerId in AIProviderConstants.providerNames.keys) {
        final isConfigured =
            await SecureApiStorage.isProviderConfigured(providerId);
        _isConfigured[providerId] = isConfigured;
      }
      setState(() {});
    } catch (e) {
      debugPrint('Failed to check configured providers: $e');
    }
  }

  void _showApiConfigurationDialog(
      BuildContext context, String providerId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ApiConfigurationDialog(
        providerId: providerId,
        onConfigurationComplete: () {
          _refreshProviderConfigs();
        },
      ),
    );

    if (result == true) {
      _checkConfiguredProviders();
    }
  }

  void _showProviderModelSelection(
      BuildContext context, String providerId, String providerName) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ProviderModelSelectionDialog(
        providerId: providerId,
        providerName: providerName,
      ),
    );

    if (result == true) {
      setState(() {}); // Refresh to show updated favorite count
    }
  }

  void _refreshProviderConfigs() async {
    try {
      await _aiProviderConfig.refreshProviders();
      await _checkConfiguredProviders();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Provider configurations refreshed!')),
      );
    } catch (e) {
      debugPrint('Failed to refresh provider configurations: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to refresh configurations')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Providers'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
            tooltip: 'Search providers',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddProviderDialog(context),
            tooltip: 'Add provider',
          ),
        ],
      ),
      body: _buildAllProvidersTab(),
    );
  }

  Widget _buildAllProvidersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Header
          Text(
            'AI Providers',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ).animate().fadeIn(duration: 500.ms),

          const SizedBox(height: 8),

          Text(
            'Dynamic model loading from provider APIs',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ).animate().fadeIn(duration: 500.ms, delay: 100.ms),

          const SizedBox(height: 24),

          // Configuration Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.settings,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Default Provider',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Set your preferred AI provider',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    initialValue: 'openai',
                    items: const [
                      DropdownMenuItem(value: 'openai', child: Text('OpenAI')),
                      DropdownMenuItem(
                          value: 'google', child: Text('Google AI')),
                      DropdownMenuItem(
                          value: 'claude', child: Text('Anthropic Claude')),
                      DropdownMenuItem(
                          value: 'zhipuai', child: Text('ZhipuAI GLM')),
                      DropdownMenuItem(
                          value: 'azure-openai', child: Text('Azure OpenAI')),
                      DropdownMenuItem(value: 'cohere', child: Text('Cohere')),
                      DropdownMenuItem(
                          value: 'mistral-ai', child: Text('Mistral AI')),
                      DropdownMenuItem(
                          value: 'stability-ai', child: Text('Stability AI')),
                      DropdownMenuItem(value: 'ollama', child: Text('Ollama')),
                      DropdownMenuItem(
                          value: 'huggingface', child: Text('Hugging Face')),
                    ],
                    onChanged: (value) {
                      // TODO: Update default provider
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        _showApiConfigurationDialog(context, 'openai');
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.key_outlined),
                          SizedBox(width: 8),
                          Text('Configure API Keys'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 200.ms),

          const SizedBox(height: 32),

          // Dynamic Provider Cards
          _buildDynamicProviderCard(
            providerId: 'openai',
            title: 'OpenAI',
            icon: Icons.smart_toy,
            color: const Color(0xFF10A37F),
            strength: 10,
          ),

          const SizedBox(height: 16),

          _buildDynamicProviderCard(
            providerId: 'google',
            title: 'Google AI',
            icon: Icons.language,
            color: const Color(0xFF4285F4),
            strength: 9,
          ),

          const SizedBox(height: 16),

          _buildDynamicProviderCard(
            providerId: 'claude',
            title: 'Anthropic Claude',
            icon: Icons.psychology,
            color: const Color(0xFFD4A373),
            strength: 9,
          ),

          const SizedBox(height: 16),

          _buildDynamicProviderCard(
            providerId: 'zhipuai',
            title: 'ZhipuAI GLM',
            icon: Icons.code,
            color: const Color(0xFF1E88E5),
            strength: 8,
          ),

          const SizedBox(height: 16),

          _buildDynamicProviderCard(
            providerId: 'azure-openai',
            title: 'Azure OpenAI',
            icon: Icons.cloud,
            color: const Color(0xFF0078D4),
            strength: 10,
          ),

          const SizedBox(height: 16),

          _buildDynamicProviderCard(
            providerId: 'cohere',
            title: 'Cohere',
            icon: Icons.chat,
            color: const Color(0xFF48A14E),
            strength: 8,
          ),

          const SizedBox(height: 16),

          _buildDynamicProviderCard(
            providerId: 'mistral-ai',
            title: 'Mistral AI',
            icon: Icons.auto_awesome,
            color: const Color(0xFFEE6C4D),
            strength: 8,
          ),

          const SizedBox(height: 16),

          _buildDynamicProviderCard(
            providerId: 'stability-ai',
            title: 'Stability AI',
            icon: Icons.image,
            color: const Color(0xFF9B59B6),
            strength: 7,
          ),

          const SizedBox(height: 16),

          _buildDynamicProviderCard(
            providerId: 'ollama',
            title: 'Ollama',
            icon: Icons.devices,
            color: const Color(0xFF0066CC),
            strength: 6,
          ),

          const SizedBox(height: 16),

          _buildDynamicProviderCard(
            providerId: 'huggingface',
            title: 'Hugging Face',
            icon: Icons.emoji_objects,
            color: const Color(0xFFFFD700),
            strength: 8,
          ),
        ],
      ),
    );
  }

  /// Build provider card with dynamic model loading
  Widget _buildDynamicProviderCard({
    required String providerId,
    required String title,
    required IconData icon,
    required Color color,
    required int strength,
  }) {
    final models = _providerModels[providerId] ?? [];
    final favoriteModels = _modelSelectionService.getFavoriteModels(providerId);

    final description = favoriteModels.isEmpty
        ? (providerId == 'openai'
            ? 'GPT-4, GPT-3.5, DALL-E'
            : providerId == 'google'
                ? 'Gemini Pro, Ultra, PaLM'
                : providerId == 'claude'
                    ? 'Claude 3, Claude 2, Claude Instant'
                    : providerId == 'zhipuai'
                        ? 'GLM-4, GLM-3, ChatGLM'
                        : providerId == 'azure-openai'
                        ? 'GPT-4, GPT-3.5 Turbo on Azure'
                        : providerId == 'cohere'
                            ? 'Command, Command Light, Nightly'
                            : providerId == 'mistral-ai'
                                ? 'Mistral Large, Medium, Small'
                                : providerId == 'stability-ai'
                                    ? 'Stable Diffusion XL, SD 2.1'
                                    : providerId == 'ollama'
                                        ? 'Local LLM deployment'
                                        : providerId == 'huggingface'
                                            ? 'Open source models'
                                            : 'AI models')
        : favoriteModels.length > 3
            ? '${favoriteModels.take(3).join(", ")} + ${favoriteModels.length - 3} more'
            : favoriteModels.join(", ");

    return _buildProviderCard(
      context: context,
      title: title,
      description: description,
      strength: strength,
      icon: icon,
      color: color,
      providerId: providerId,
      models: models.isNotEmpty
          ? models
          : (providerId == 'openai'
              ? ['gpt-4', 'gpt-4-turbo', 'gpt-3.5-turbo']
              : providerId == 'google'
                  ? ['gemini-pro', 'gemini-pro-vision', 'gemini-ultra']
                  : providerId == 'claude'
                      ? ['claude-3-opus', 'claude-3-sonnet', 'claude-3-haiku']
                      : providerId == 'zhipuai'
                          ? ['glm-4', 'glm-4-air', 'glm-4-flash']
                          : providerId == 'azure-openai'
                          ? ['gpt-4', 'gpt-35-turbo']
                          : providerId == 'cohere'
                              ? ['command', 'command-light', 'command-nightly']
                              : providerId == 'mistral-ai'
                                  ? [
                                      'mistral-large',
                                      'mistral-medium',
                                      'mistral-small'
                                    ]
                                  : providerId == 'stability-ai'
                                      ? [
                                          'stable-diffusion-xl',
                                          'stable-diffusion-2-1'
                                        ]
                                      : providerId == 'ollama'
                                          ? [
                                              'llama2',
                                              'llama3',
                                              'mistral',
                                              'codellama'
                                            ]
                                          : providerId == 'huggingface'
                                              ? [
                                                  'bert',
                                                  'gpt2',
                                                  't5',
                                                  'distilgpt2'
                                                ]
                                              : ['Coming soon']),
    ).animate().fadeIn(
        duration: const Duration(milliseconds: 500),
        delay: const Duration(milliseconds: 100));
  }

  Widget _buildProviderCard({
    required BuildContext context,
    required String title,
    required String description,
    required int strength,
    required IconData icon,
    required Color color,
    required String providerId,
    List<String>? models,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to provider detail
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isConfigured[providerId] == true) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.green.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Configured',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (_modelSelectionService
                                    .hasFavoriteModels(providerId)) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.model_training,
                                          color: Colors.blue,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_modelSelectionService.getFavoriteModels(providerId).length} Favorites',
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStrengthColor(strength)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$strength/10',
                                    style: TextStyle(
                                      color: _getStrengthColor(strength),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Control buttons for this provider
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showProviderModelSelection(
                          context, providerId, title),
                      icon: const Icon(Icons.model_training, size: 16),
                      label: Text(_modelSelectionService
                              .getFavoriteModels(providerId)
                              .isEmpty
                          ? 'Select Models'
                          : 'Edit Models'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Enable/Disable toggle
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Theme.of(context).colorScheme.outline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                            ),
                          ),
                          child: const Text('ON',
                              style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        // TODO: Add enable/disable toggle functionality
                      ],
                    ),
                  ),
                ],
              ),
              if (models?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: models!
                      .map((model) => Chip(
                            label: Text(
                              model,
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            side: BorderSide(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withValues(alpha: 0.3),
                            ),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () =>
                        _showApiConfigurationDialog(context, providerId),
                    child: const Text('Configure'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Test provider
                    },
                    child: const Text('Test'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStrengthColor(int strength) {
    if (strength >= 9) return Colors.green;
    if (strength >= 7) return Colors.yellow;
    return Colors.orange;
  }

  void _showSearchDialog(BuildContext context) {
    showSearch(
      context: context,
      delegate: ProviderSearchDelegate(),
    );
  }

  void _showAddProviderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Provider'),
        content: const Text('Select a provider to add:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Add Provider'),
          ),
        ],
      ),
    );
  }
}

// Provider search delegate
class ProviderSearchDelegate extends SearchDelegate<String> {
  // List of all providers
  final List<Map<String, dynamic>> _allProviders = [
    {
      'id': 'openai',
      'name': 'OpenAI',
      'description': 'GPT-4, GPT-3.5, DALL-E',
      'icon': Icons.smart_toy,
      'color': Color(0xFF10A37F),
    },
    {
      'id': 'google',
      'name': 'Google AI',
      'description': 'Gemini Pro, Ultra, PaLM',
      'icon': Icons.language,
      'color': Color(0xFF4285F4),
    },
    {
      'id': 'claude',
      'name': 'Anthropic Claude',
      'description': 'Claude 3, Claude 2, Claude Instant',
      'icon': Icons.psychology,
      'color': Color(0xFFD4A373),
    },
    {
      'id': 'zhipuai',
      'name': 'ZhipuAI GLM',
      'description': 'GLM-4, GLM-3, ChatGLM',
      'icon': Icons.code,
      'color': Color(0xFF1E88E5),
    },
    {
      'id': 'azure-openai',
      'name': 'Azure OpenAI',
      'description': 'GPT-4, GPT-3.5 Turbo, DALL-E',
      'icon': Icons.cloud,
      'color': Color(0xFF0078D4),
    },
    {
      'id': 'cohere',
      'name': 'Cohere',
      'description': 'Command, Command Light, Command Nightly',
      'icon': Icons.chat,
      'color': Color(0xFF48A14E),
    },
    {
      'id': 'mistral-ai',
      'name': 'Mistral AI',
      'description': 'Mistral Large, Medium, Small',
      'icon': Icons.auto_awesome,
      'color': Color(0xFFEE6C4D),
    },
    {
      'id': 'stability-ai',
      'name': 'Stability AI',
      'description': 'Stable Diffusion XL, SD 2.1',
      'icon': Icons.image,
      'color': Color(0xFF9B59B6),
    },
    {
      'id': 'ollama',
      'name': 'Ollama',
      'description': 'Local LLM deployment',
      'icon': Icons.devices,
      'color': Color(0xFF0066CC),
    },
    {
      'id': 'huggingface',
      'name': 'Hugging Face',
      'description': 'Open source models',
      'icon': Icons.emoji_objects,
      'color': Color(0xFFFFD700),
    },
  ];

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = _allProviders
        .where((provider) =>
            provider['name'].toLowerCase().contains(query.toLowerCase()) ||
            provider['description'].toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final provider = results[index];
        return ListTile(
          leading: Icon(
            provider['icon'],
            color: provider['color'],
          ),
          title: Text(provider['name']),
          subtitle: Text(provider['description']),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              // Handle menu actions
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('$value selected for ${provider['name']}')),
              );
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'Configure',
                child: Text('Configure'),
              ),
              const PopupMenuItem(
                value: 'Test',
                child: Text('Test'),
              ),
              const PopupMenuItem(
                value: 'Delete',
                child: Text('Delete'),
              ),
            ],
          ),
          onTap: () {
            close(context, provider['id']);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = _allProviders
        .where((provider) =>
            provider['name'].toLowerCase().contains(query.toLowerCase()) ||
            provider['description'].toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final provider = suggestions[index];
        return ListTile(
          leading: Icon(
            provider['icon'],
            color: provider['color'],
          ),
          title: Text(provider['name']),
          subtitle: Text(provider['description']),
          onTap: () {
            query = provider['name'];
          },
        );
      },
    );
  }
}
