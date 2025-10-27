import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/ai_provider_constants.dart';
import '../../infrastructure/ai/model_selection_service.dart';

/// Dialog for selecting preferred models from configured providers
class ModelSelectionDialog extends ConsumerStatefulWidget {
  const ModelSelectionDialog({super.key});

  @override
  ConsumerState<ModelSelectionDialog> createState() =>
      _ModelSelectionDialogState();
}

class _ModelSelectionDialogState extends ConsumerState<ModelSelectionDialog> {
  final ModelSelectionService _modelService = ModelSelectionService();
  final Map<String, List<String>> _availableModels = {};
  final Map<String, String> _activeModels = {};
  final Map<String, List<String>> _favoriteModels = {};
  bool _isLoading = true;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);

    try {
      await _modelService.initialize();

      // Load current selections
      final allActiveModels = _modelService.getAllActiveModels();
      setState(() {
        _activeModels.clear();
        _activeModels.addAll(allActiveModels);
      });

      // Load favorite models
      for (final providerId in AIProviderConstants.providerNames.keys) {
        final favorites = _modelService.getFavoriteModels(providerId);
        if (favorites.isNotEmpty) {
          _favoriteModels[providerId] = favorites;
        }
      }

      // Fetch available models
      await _fetchModels();
    } catch (e) {
      debugPrint('Failed to initialize model selection: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchModels() async {
    setState(() => _isFetching = true);

    try {
      await _modelService.fetchAvailableModels();

      // Update available models
      for (final providerId in AIProviderConstants.providerNames.keys) {
        final models = _modelService.getAvailableModels(providerId);
        if (models.isNotEmpty) {
          _availableModels[providerId] = models;
        }
      }

      setState(() {});
    } catch (e) {
      debugPrint('Failed to fetch models: $e');
    } finally {
      setState(() => _isFetching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Models'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Choose your preferred models from each provider',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (_isFetching)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                if (!_isFetching)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _fetchModels,
                    tooltip: 'Refresh models',
                  ),
              ],
            ),

            const Divider(),

            // Model selection list
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_availableModels.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No providers configured yet'),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _availableModels.length,
                  itemBuilder: (context, index) {
                    final providerId = _availableModels.keys.elementAt(index);
                    final models = _availableModels[providerId]!;
                    final providerName =
                        AIProviderConstants.providerNames[providerId] ??
                            providerId;
                    final activeModel = _activeModels[providerId];

                    return _buildProviderSection(
                      providerId: providerId,
                      providerName: providerName,
                      models: models,
                      activeModel: activeModel,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveSelections,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildProviderSection({
    required String providerId,
    required String providerName,
    required List<String> models,
    String? activeModel,
  }) {
    final favoriteModels = _favoriteModels[providerId] ?? [];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider header
            Row(
              children: [
                Text(
                  providerName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 8),
                if (favoriteModels.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${favoriteModels.length} favorites',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            if (favoriteModels.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: favoriteModels.map((model) {
                  final isActive = model == activeModel;
                  return Chip(
                    label: Text(
                      model,
                      style: TextStyle(
                        fontSize: 10,
                        color: isActive ? Colors.white : null,
                      ),
                    ),
                    backgroundColor: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.withValues(alpha: 0.2),
                    deleteIcon: Icon(
                      Icons.close,
                      size: 14,
                      color: isActive ? Colors.white : Colors.grey,
                    ),
                    onDeleted: () {
                      setState(() {
                        _favoriteModels[providerId]?.remove(model);
                      });
                    },
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 12),

            // Model selection dropdown
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Add to Favorites',
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              initialValue: null,
              items: models.map((model) {
                return DropdownMenuItem<String>(
                  value: model,
                  child: Text(
                    model,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null && !favoriteModels.contains(value)) {
                  setState(() {
                    _favoriteModels[providerId] = [...favoriteModels, value];
                  });
                }
              },
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
        duration: 300.ms,
        delay: (100 * _availableModels.keys.toList().indexOf(providerId)).ms);
  }

  Future<void> _saveSelections() async {
    try {
      // Save favorite models
      for (final entry in _favoriteModels.entries) {
        if (entry.value.isNotEmpty) {
          await _modelService.setFavoriteModels(entry.key, entry.value);
          // Set first favorite as active
          await _modelService.setActiveModel(entry.key, entry.value.first);
        }
      }

      Navigator.of(context).pop(true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Model selections saved!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save selections: ${e.toString()}')),
      );
    }
  }
}
