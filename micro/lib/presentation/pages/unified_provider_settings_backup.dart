import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/dynamic_model_provider.dart';

class UnifiedProviderSettings extends ConsumerStatefulWidget {
  const UnifiedProviderSettings({super.key});

  @override
  ConsumerState<UnifiedProviderSettings> createState() =>
      _UnifiedProviderSettingsState();
}

class _UnifiedProviderSettingsState
    extends ConsumerState<UnifiedProviderSettings> {
  @override
  void initState() {
    super.initState();
    // Start fetching models for key providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(cachedModelsProvider.notifier).fetchModels('openai');
        ref.read(cachedModelsProvider.notifier).fetchModels('google');
        ref.read(cachedModelsProvider.notifier).fetchModels('claude');
      }
    });
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
            'All available AI language model providers',
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
                  OutlinedButton(
                    onPressed: () {
                      // TODO: Navigate to API key configuration
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
                ],
              ),
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 200.ms),

          const SizedBox(height: 32),

          // All Provider Cards (Dynamic)
          Consumer(
            builder: (context, ref, child) {
              final modelsAsync = ref.watch(cachedModelsProvider);

              return Column(
                children: [
                  // OpenAI Card
                  modelsAsync.when(
                    data: (models) => _buildDynamicProviderCard(
                        context: context,
                        title: 'OpenAI',
                        providerId: 'openai',
                        strength: 10,
                        icon: Icons.smart_toy,
                        color: const Color(0xFF10A37F),
                        models: models['openai'] ?? ['gpt-4', 'gpt-3.5'],
                        onRefresh: () => ref.read(cachedModelsProvider.notifier).clearCache('openai'),
                      ),
                    loading: () => _buildDynamicProviderCard(
                        context: context,
                        title: 'OpenAI',
                        providerId: 'openai',
                        strength: 10,
                        icon: Icons.smart_toy,
                        color: const Color(0xFF10A37F),
                        models: ['Loading models...'],
                        onRefresh: () => ref.read(cachedModelsProvider.notifier).clearCache('openai'),
                      ),
                    error: (_, __) => _buildDynamicProviderCard(
                      context: context,
                      title: 'OpenAI',
                      providerId: 'openai',
                      strength: 10,
                      icon: Icons.smart_toy,
                      color: const Color(0xFF10A37F),
                      models: ['Unable to load models'],
                      onRefresh: () => ref.read(cachedModelsProvider.notifier).clearCache('openai'),
                  ),
                  const SizedBox(height: 16),

                  // Google AI Card
                  modelsAsync.when(
                    data: (models) => _buildDynamicProviderCard(
                        context: context,
                        title: 'Google AI',
                        providerId: 'google',
                        strength: 9,
                        icon: Icons.language,
                        color: const Color(0xFF4285F4),
                        models: models['google'] ?? ['gemini-pro'],
                        onRefresh: () => ref.read(cachedModelsProvider.notifier).clearCache('google'),
                      ),
                    loading: () => _buildDynamicProviderCard(
                        context: context,
                        title: 'Google AI',
                        providerId: 'google',
                        strength: 9,
                        icon: Icons.language,
                        color: const Color(0xFF4285F4),
                        models: ['Loading models...'],
                        onRefresh: () => ref.read(cachedModelsProvider.notifier).clearCache('google'),
                      ),
                    child: _buildDynamicProviderCard(
                    context: context,
                    title: 'Google AI',
                    providerId: 'google',
                    strength: 9,
                    icon: Icons.language,
                    color: const Color(0xFF4285F4),
                    models: ['Unable to load models'],
                    onRefresh: () => ref.read(cachedModelsProvider.notifier).clearCache('google'),
                  ),
                ],
              ),
            },

          // Additional provider cards (original hardcoded versions for now)
          _buildProviderCard(
            context: context,
            title: 'Anthropic Claude',
            description: 'Claude 3, Claude 2, Claude Instant',
            strength: 9,
            icon: Icons.psychology,
            color: const Color(0xFFD4A373),
            providerId: 'claude',
          ),

          _buildProviderCard(
            context: context,
            title: 'Google AI',
            description: 'Gemini Pro, Ultra, PaLM',
            strength: 9,
            icon: Icons.language,
            color: const Color(0xFF4285F4),
            providerId: 'google',
          ),

          const SizedBox(height: 16),

          _buildProviderCard(
            context: context,
            title: 'Anthropic Claude',
            description: 'Claude 3, Claude 2, Claude Instant',
            strength: 9,
            icon: Icons.psychology,
            color: const Color(0xFFD4A373),
            providerId: 'claude',
          ),

          const SizedBox(height: 16),

          _buildProviderCard(
            context: context,
            title: 'Azure OpenAI',
            description: 'Microsoft Azure-hosted OpenAI',
            strength: 10,
            icon: Icons.cloud,
            color: const Color(0xFF0078D4),
            providerId: 'azure-openai',
          ),

          const SizedBox(height: 16),

          _buildProviderCard(
            context: context,
            title: 'Cohere',
            description: 'Command, Command R+',
            strength: 8,
            icon: Icons.format_quote,
            color: const Color(0xFF1F2937),
            providerId: 'cohere',
          ),

          const SizedBox(height: 16),

          _buildProviderCard(
            context: context,
            title: 'Mistral AI',
            description: 'Mistral 7B, Mixtral 8x7B',
            strength: 9,
            icon: Icons.auto_awesome,
            color: const Color(0xFF7B2CBF),
            providerId: 'mistral-ai',
          ),

          const SizedBox(height: 16),

          _buildProviderCard(
            context: context,
            title: 'Stability AI',
            description: 'Stable Diffusion XL, SDXL Turbo',
            strength: 7,
            icon: Icons.image,
            color: const Color(0xFF1E88E5),
            providerId: 'stability-ai',
          ),

          const SizedBox(height: 16),

          _buildProviderCard(
            context: context,
            title: 'Ollama',
            description: 'Run LLMs locally on your machine',
            strength: 7,
            icon: Icons.computer,
            color: const Color(0xFFFF5722),
            providerId: 'ollama',
          ),

          const SizedBox(height: 16),

          _buildProviderCard(
            context: context,
            title: 'Hugging Face',
            description: 'Transformers and models library',
            strength: 8,
            icon: Icons.psychology_alt,
            color: const Color(0xFFFFD21E),
            providerId: 'huggingface',
          ),
        ],
      ),
    );
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
                    onPressed: () {
                      // TODO: Configure provider
                    },
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
    ).animate().fadeIn(duration: 500.ms, delay: 100.ms);
  }

  /// Build provider card with dynamic models
  Widget _buildDynamicProviderCard({
    required BuildContext context,
    required String title,
    required String providerId,
    required int strength,
    required IconData icon,
    required Color color,
    required List<String> models,
    required VoidCallback onRefresh,
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
                            IconButton(
                              icon: const Icon(Icons.refresh, size: 20),
                              onPressed: onRefresh,
                              tooltip: 'Refresh models',
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dynamic model loading enabled',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontStyle: FontStyle.italic,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (models.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: models
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
              ] else ...[
                Text(
                  'No models available',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      // TODO: Configure provider
                    },
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
    ).animate().fadeIn(duration: 500.ms, delay: 100.ms);
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
      'id': 'azure-openai',
      'name': 'Azure OpenAI',
      'description': 'Microsoft Azure-hosted OpenAI',
      'icon': Icons.cloud,
      'color': Color(0xFF0078D4),
    },
    {
      'id': 'cohere',
      'name': 'Cohere',
      'description': 'Command, Command R+',
      'icon': Icons.format_quote,
      'color': Color(0xFF1F2937),
    },
    {
      'id': 'mistral-ai',
      'name': 'Mistral AI',
      'description': 'Mistral 7B, Mixtral 8x7B',
      'icon': Icons.auto_awesome,
      'color': Color(0xFF7B2CBF),
    },
    {
      'id': 'stability-ai',
      'name': 'Stability AI',
      'description': 'Stable Diffusion XL, SDXL Turbo',
      'icon': Icons.image,
      'color': Color(0xFF1E88E5),
    },
    {
      'id': 'ollama',
      'name': 'Ollama',
      'description': 'Run LLMs locally on your machine',
      'icon': Icons.computer,
      'color': Color(0xFFFF5722),
    },
    {
      'id': 'huggingface',
      'name': 'Hugging Face',
      'description': 'Transformers and models library',
      'icon': Icons.psychology_alt,
      'color': Color(0xFFFFD21E),
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
    final results = _allProviders.where((provider) {
      return provider['name']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()) ||
          provider['description']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final provider = results[index];
        return ListTile(
          leading: Icon(
            provider['icon'] as IconData,
            color: provider['color'] as Color,
          ),
          title: Text(provider['name'] as String),
          subtitle: Text(provider['description'] as String),
          onTap: () {
            // Navigate to provider configuration
            close(context, provider['id'] as String);
          },
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              // Handle menu actions
              switch (value) {
                case 'configure':
                  // Navigate to configuration
                  break;
                case 'test':
                  // Test provider
                  break;
                case 'delete':
                  // Delete provider
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'configure',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Configure'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'test',
                child: Row(
                  children: [
                    Icon(Icons.play_arrow),
                    SizedBox(width: 8),
                    Text('Test'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = _allProviders.where((provider) {
      return provider['name']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()) ||
          provider['description']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final provider = suggestions[index];
        return ListTile(
          leading: Icon(
            provider['icon'] as IconData,
            color: provider['color'] as Color,
          ),
          title: Text(provider['name'] as String),
          subtitle: Text(provider['description'] as String),
          onTap: () {
            query = provider['name'] as String;
          },
        );
      },
    );
  }
}
