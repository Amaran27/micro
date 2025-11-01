╔══════════════════════════════════════════════════════════════════════════════╗
║                    REACTIVE CODE PATTERNS - COPY READY                        ║
║                                                                              ║
║         These patterns ensure reactivity works correctly throughout          ║
╚══════════════════════════════════════════════════════════════════════════════╝


═════════════════════════════════════════════════════════════════════════════════
PATTERN 1: WATCHING PROVIDERS IN UI
═════════════════════════════════════════════════════════════════════════════════

// In a ConsumerWidget
@override
Widget build(BuildContext context, WidgetRef ref) {
  // Watch all configured providers
  final allConfigs = ref.watch(providersConfigProvider);
  
  // Watch only enabled ones
  final enabledConfigs = ref.watch(enabledProviderConfigsProvider);
  
  // Watch all favorite models (used in Chat page)
  final allModels = ref.watch(allFavoriteModelsProvider);
  
  // Handle async states
  return allConfigs.when(
    loading: () => const LoadingWidget(),
    error: (err, stack) => ErrorWidget(error: err),
    data: (configs) => ListView(
      children: configs.map((config) => ProviderCard(config: config)).toList(),
    ),
  );
}

// ✅ Key: When data changes in storage → Riverpod notifies → Widget rebuilds


═════════════════════════════════════════════════════════════════════════════════
PATTERN 2: SAVING AND INVALIDATING
═════════════════════════════════════════════════════════════════════════════════

// When user clicks "Save" in Add/Edit dialog
Future<void> saveProvider(WidgetRef ref, ProviderConfig config) async {
  try {
    // Step 1: Call the notifier method
    await ref.read(providersNotifierProvider).addConfig(config);
    
    // Step 2: Invalidate the provider to force reload from storage
    ref.invalidate(providersConfigProvider);
    
    // Step 3: Dependent providers auto-invalidate:
    //   - enabledProviderConfigsProvider (depends on providersConfigProvider)
    //   - allFavoriteModelsProvider (depends on enabledProviderConfigsProvider)
    //   - Chat page watching allFavoriteModelsProvider → REBUILDS! ✨
    
    // Step 4: Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Provider added successfully!')),
    );
    
    // Step 5: Close dialog
    Navigator.of(context).pop();
  } catch (e) {
    // Error handling
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}

// ✅ Key: invalidate() tells Riverpod to reload, triggering watchers


═════════════════════════════════════════════════════════════════════════════════
PATTERN 3: TOGGLING ENABLE/DISABLE
═════════════════════════════════════════════════════════════════════════════════

// When user clicks the toggle button
void toggleProvider(WidgetRef ref, String configId) async {
  try {
    await ref.read(providersNotifierProvider).toggleConfig(configId);
    ref.invalidate(providersConfigProvider);
    
    // If disabled:
    //   - enabledProviderConfigsProvider filters it out
    //   - allFavoriteModelsProvider excludes its models
    //   - Chat dropdown automatically removes those models
    //
    // If enabled:
    //   - enabledProviderConfigsProvider includes it
    //   - allFavoriteModelsProvider includes its models
    //   - Chat dropdown automatically adds them back
  } catch (e) {
    debugPrint('Toggle failed: $e');
  }
}

// ✅ Key: Single toggle triggers cascading updates throughout app


═════════════════════════════════════════════════════════════════════════════════
PATTERN 4: DELETION WITH PROPAGATION
═════════════════════════════════════════════════════════════════════════════════

// When user clicks [Delete]
void deleteProvider(WidgetRef ref, String configId) async {
  // Show confirmation first
  bool confirmed = await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Provider?'),
      content: const Text('This will remove the provider and its models.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  
  if (!confirmed) return;
  
  try {
    // Step 1: Delete from storage
    await ref.read(providersNotifierProvider).deleteConfig(configId);
    
    // Step 2: Invalidate provider
    ref.invalidate(providersConfigProvider);
    
    // Step 3: Cascade effect:
    //   If this was the only provider with certain models:
    //     - allFavoriteModelsProvider removes those models
    //     - Chat page dropdown updates
    //     - If no models left: dropdown shows empty state
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Provider deleted')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}

// ✅ Key: Deletion automatically updates all dependent UI


═════════════════════════════════════════════════════════════════════════════════
PATTERN 5: EDITING FAVORITE MODELS
═════════════════════════════════════════════════════════════════════════════════

// When user selects/deselects models in dialog
void saveFavoriteModels(WidgetRef ref, String configId, List<String> newModels) async {
  try {
    // Step 1: Update only the models
    await ref.read(providersNotifierProvider).setFavoriteModels(configId, newModels);
    
    // Step 2: Invalidate
    ref.invalidate(providersConfigProvider);
    
    // Step 3: allFavoriteModelsProvider recalculates:
    //   Old: [gpt-4, gpt-4-turbo, claude-3-opus, claude-3-sonnet]
    //   User removed: gpt-4-turbo
    //   New: [gpt-4, claude-3-opus, claude-3-sonnet]
    //
    //   Chat page immediately shows new list!
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${newModels.length} models selected')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}

// ✅ Key: Model changes cascade to chat page without refresh


═════════════════════════════════════════════════════════════════════════════════
PATTERN 6: LISTENING IN CHAT PAGE
═════════════════════════════════════════════════════════════════════════════════

// In enhanced_ai_chat_page.dart - ConsumerStatefulWidget

class EnhancedAIChatPage extends ConsumerStatefulWidget {
  const EnhancedAIChatPage({Key? key}) : super(key: key);

  @override
  ConsumerState<EnhancedAIChatPage> createState() =>
      _EnhancedAIChatPageState();
}

class _EnhancedAIChatPageState extends ConsumerState<EnhancedAIChatPage> {
  String? _selectedModel;

  @override
  Widget build(BuildContext context) {
    // Watch the provider
    final favoriteModels = ref.watch(allFavoriteModelsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          // Model dropdown that updates reactively
          Padding(
            padding: const EdgeInsets.all(16),
            child: favoriteModels.when(
              // Loading state
              loading: () => const SizedBox(
                height: 48,
                child: Center(child: CircularProgressIndicator()),
              ),
              
              // Error state
              error: (err, stack) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Error loading models: $err',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              
              // Data state
              data: (models) {
                // If no models available
                if (models.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              // Navigate to settings to add provider
                              Navigator.pushNamed(context, '/settings');
                            },
                            child: const Text(
                              'No models configured. Go to Settings to add providers.',
                              style: TextStyle(color: Colors.orange),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Initialize selected model if needed
                if (_selectedModel == null || !models.contains(_selectedModel)) {
                  _selectedModel = models.first;
                }

                // Dropdown
                return DropdownButtonFormField<String>(
                  value: _selectedModel,
                  decoration: InputDecoration(
                    labelText: 'AI Model',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: models
                      .map((model) => DropdownMenuItem(
                            value: model,
                            child: Text(model),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedModel = value);
                  },
                );
              },
            ),
          ),
          
          // Chat history and input
          Expanded(
            child: ListView(
              // ... existing chat UI
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ Key: ref.watch() triggers rebuild whenever models change


═════════════════════════════════════════════════════════════════════════════════
PATTERN 7: HANDLING ASYNC OPERATIONS IN DIALOGS
═════════════════════════════════════════════════════════════════════════════════

// In add_provider_dialog.dart
Future<void> testConnection() async {
  setState(() {
    _isLoading = true;
    _error = null;
    _availableModels = [];
  });

  try {
    // Simulate API call - replace with actual provider SDK
    await Future.delayed(const Duration(seconds: 2));

    // Fetch available models (mock data)
    List<String> models;
    if (_selectedProviderMeta!.id == 'openai') {
      models = [
        'gpt-4',
        'gpt-4-turbo-preview',
        'gpt-3.5-turbo',
        'gpt-3.5-turbo-16k',
      ];
    } else if (_selectedProviderMeta!.id == 'anthropic') {
      models = ['claude-3-opus', 'claude-3-sonnet', 'claude-3-haiku'];
    } else {
      models = [];
    }

    setState(() {
      _availableModels = models;
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Connection successful! Found ${models.length} models')),
    );
  } catch (e) {
    setState(() {
      _error = e.toString();
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Connection failed: $e')),
    );
  }
}

// ✅ Key: setState() for local state, then invalidate() for global state


═════════════════════════════════════════════════════════════════════════════════
PATTERN 8: READING VS WATCHING
═════════════════════════════════════════════════════════════════════════════════

// WRONG - This will not rebuild when provider changes
final models = ref.read(allFavoriteModelsProvider);
// Use .read() ONLY when you need one-time read, not listening

// CORRECT - Rebuilds when provider changes
final models = ref.watch(allFavoriteModelsProvider);
// Use .watch() when you want reactive updates

// EXAMPLE: In AddProvider Dialog
Future<void> addNewProvider(WidgetRef ref) async {
  final config = ProviderConfig(
    providerId: _selectedProviderMeta!.id,
    apiKey: _apiKey,
  );

  // ✓ Use .read() here - we're taking action, not listening
  await ref.read(providersNotifierProvider).addConfig(config);

  // ✓ Use .invalidate() to notify watchers
  ref.invalidate(providersConfigProvider);
}

// EXAMPLE: In Chat Page
@override
Widget build(BuildContext context, WidgetRef ref) {
  // ✓ Use .watch() here - we want to listen to changes
  final models = ref.watch(allFavoriteModelsProvider);
  
  return DropdownButton<String>(
    items: models.when(
      data: (items) => items.map((m) => DropdownMenuItem(
        value: m,
        child: Text(m),
      )).toList(),
      loading: () => [const DropdownMenuItem(child: Text('Loading...'))],
      error: (e, st) => [DropdownMenuItem(child: Text('Error: $e'))],
    ),
  );
}

// ✅ Key: read() for actions, watch() for UI


═════════════════════════════════════════════════════════════════════════════════
PATTERN 9: PROVIDER FAMILY - SINGLE PROVIDER OPERATIONS
═════════════════════════════════════════════════════════════════════════════════

// Get provider metadata by ID
final meta = ref.watch(providerMetadataProvider('openai'));
// Returns: ProviderMetadata or null

// Get favorite models for specific provider
final models = ref.watch(favoriteModelsByProviderProvider('openai'));
// Returns: AsyncValue<List<String>>

// Usage in UI
final openaiModels = ref.watch(favoriteModelsByProviderProvider('openai'));
return openaiModels.when(
  data: (models) => Text('OpenAI models: ${models.join(", ")}'),
  loading: () => const CircularProgressIndicator(),
  error: (e, st) => Text('Error: $e'),
);

// ✅ Key: .family allows parametrized watching


═════════════════════════════════════════════════════════════════════════════════
PATTERN 10: ERROR HANDLING AND USER FEEDBACK
═════════════════════════════════════════════════════════════════════════════════

// Comprehensive error handling pattern
Future<void> saveWithErrorHandling(
  WidgetRef ref,
  BuildContext context,
  ProviderConfig config,
) async {
  try {
    // Show loading indicator
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Execute operation
    await ref.read(providersNotifierProvider).addConfig(config);
    ref.invalidate(providersConfigProvider);

    // Dismiss loading
    if (context.mounted) {
      Navigator.of(context).pop();

      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Provider saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Close dialog
      Navigator.of(context).pop();
    }
  } on InvalidApiKeyException catch (e) {
    if (context.mounted) {
      Navigator.of(context).pop(); // Dismiss loading
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid API Key: ${e.message}'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'View Provider Docs',
            onPressed: () {
              // Open provider documentation
            },
          ),
        ),
      );
    }
  } on NetworkException catch (e) {
    if (context.mounted) {
      Navigator.of(context).pop(); // Dismiss loading
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network Error: ${e.message}'),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => saveWithErrorHandling(ref, context, config),
          ),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context).pop(); // Dismiss loading
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// ✅ Key: Always clean up UI, show user feedback, allow retries


═════════════════════════════════════════════════════════════════════════════════
PATTERN 11: INVALIDATING DEPENDENT PROVIDERS
═════════════════════════════════════════════════════════════════════════════════

// When you invalidate a provider, dependent providers auto-invalidate
// This is Riverpod's magic - you typically only invalidate the source

// Provider hierarchy:
providersConfigProvider (source)
  ├─ enabledProviderConfigsProvider (depends on source)
  │  └─ configuredProviderConfigsProvider (depends on enabled)
  │     └─ allFavoriteModelsProvider (depends on configured)
  │        └─ Chat page watch (rebuilds when this changes)
  └─ favoriteModelsByProviderProvider (depends on source)

// When to invalidate:
ref.invalidate(providersConfigProvider);  // ← Always start from source

// DON'T invalidate child providers:
// ref.invalidate(enabledProviderConfigsProvider);  // ← Wrong, won't cascade properly
// ref.invalidate(allFavoriteModelsProvider);       // ← Wrong, not the source

// ✅ Key: Invalidate source provider, children auto-update


═════════════════════════════════════════════════════════════════════════════════
PATTERN 12: PREVENTING DUPLICATE INVALIDATIONS
═════════════════════════════════════════════════════════════════════════════════

// GOOD: Single operation with one invalidation
Future<void> addMultipleProviders(
  WidgetRef ref,
  List<ProviderConfig> configs,
) async {
  try {
    // Add all providers
    for (final config in configs) {
      await ref.read(providersNotifierProvider).addConfig(config);
    }

    // Invalidate ONCE at the end
    ref.invalidate(providersConfigProvider);

    // All UI updates happen at once, not repeatedly
  } catch (e) {
    debugPrint('Error: $e');
  }
}

// BAD: Multiple invalidations cause unnecessary rebuilds
void badWay(WidgetRef ref, List<ProviderConfig> configs) {
  for (final config in configs) {
    ref.read(providersNotifierProvider).addConfig(config);
    ref.invalidate(providersConfigProvider);  // ← Rebuilds for each! Bad!
  }
}

// ✅ Key: Batch operations, invalidate once


═════════════════════════════════════════════════════════════════════════════════
SUMMARY: REACTIVE PATTERNS CHECKLIST
═════════════════════════════════════════════════════════════════════════════════

✅ In UI Widgets:
   └─ Use ref.watch() to listen to changes
   └─ Handle loading/error/data states
   └─ Widget rebuilds automatically when provider changes

✅ In Actions (Dialogs, Buttons):
   └─ Use ref.read() to get current value
   └─ Call notifier method to update storage
   └─ Call ref.invalidate() to notify watchers
   └─ Show user feedback (SnackBar)

✅ In Chat Page:
   └─ Watch allFavoriteModelsProvider
   └─ Rebuild dropdown when it changes
   └─ Handle empty/loading/error states

✅ Error Handling:
   └─ Show loading states during operations
   └─ Catch and display errors
   └─ Provide retry options
   └─ Keep UI responsive

✅ Performance:
   └─ Don't watch more than needed
   └─ Use .family for parameterized watching
   └─ Batch updates, invalidate once
   └─ Use mounted checks before context usage

This ensures your app is fully reactive, efficient, and responsive! ✨
