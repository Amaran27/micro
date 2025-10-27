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
    return Consumer(
      builder: (context, ref, child) {
        final modelsAsync = ref.watch(
          cachedModelsProvider.select((models) => models[providerId]),
        );

        return modelsAsync.when(
          data: (models) => _buildProviderCard(
            context: context,
            title: title,
            description: 'Dynamic models loaded',
            strength: strength,
            icon: icon,
            color: color,
            providerId: providerId,
            models: models ?? ['No models available'],
          ),
          loading: () => _buildProviderCard(
            context: context,
            title: title,
            description: 'Loading models...',
            strength: strength,
            icon: icon,
            color: color,
            providerId: providerId,
            models: ['Loading...'],
          ),
          error: (_, __) => _buildProviderCard(
            context: context,
            title: title,
            description: 'Failed to load models',
            strength: strength,
            icon: icon,
            color: color,
            providerId: providerId,
            models: ['Error loading models'],
          ),
        );
      },
    ).animate().fadeIn(duration: 500.ms, delay: 100.ms);
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
