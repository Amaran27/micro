import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../infrastructure/ai/model_selection_service.dart';

/// Dialog for selecting models from a specific provider
class ProviderModelSelectionDialog extends ConsumerStatefulWidget {
  final String providerId;
  final String providerName;

  const ProviderModelSelectionDialog({
    super.key,
    required this.providerId,
    required this.providerName,
  });

  @override
  ConsumerState<ProviderModelSelectionDialog> createState() =>
      _ProviderModelSelectionDialogState();
}

class _ProviderModelSelectionDialogState
    extends ConsumerState<ProviderModelSelectionDialog> {
  final ModelSelectionService _modelService = ModelSelectionService();
  List<String> _availableModels = [];
  List<String> _selectedModels = [];
  bool _isLoading = true;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);

    try {
      await _modelService.initialize();

      // Load current favorites for this provider
      final currentFavorites =
          _modelService.getFavoriteModels(widget.providerId);
      setState(() {
        _selectedModels = List.from(currentFavorites);
      });

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
      final models = _modelService.getAvailableModels(widget.providerId);
      setState(() {
        _availableModels = models;
      });
    } catch (e) {
      debugPrint('Failed to fetch models: $e');
    } finally {
      setState(() => _isFetching = false);
    }
  }

  void _toggleModel(String model) {
    setState(() {
      if (_selectedModels.contains(model)) {
        _selectedModels.remove(model);
      } else {
        _selectedModels.add(model);
      }
    });
  }

  Future<void> _saveSelections() async {
    try {
      await _modelService.setFavoriteModels(widget.providerId, _selectedModels);

      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${_selectedModels.length} models saved for ${widget.providerName}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save selections: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Text(widget.providerName),
          const SizedBox(width: 8),
          if (_selectedModels.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_selectedModels.length} selected',
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            // Loading indicator
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            // Model list
            else ...[
              // Refresh button
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Available Models (${_availableModels.length})',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  if (_isFetching)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    IconButton(
                      onPressed: _fetchModels,
                      icon: const Icon(Icons.refresh),
                      iconSize: 20,
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Search box
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Search models...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  // TODO: Implement search functionality
                },
              ),

              const SizedBox(height: 12),

              // Model list with checkboxes
              Expanded(
                child: _availableModels.isEmpty
                    ? Center(
                        child: Text(
                          'No models available.\nPlease configure API key first.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _availableModels.length,
                        itemBuilder: (context, index) {
                          final model = _availableModels[index];
                          final isSelected = _selectedModels.contains(model);

                          return CheckboxListTile(
                            title: Text(
                              model,
                              style: const TextStyle(fontSize: 14),
                            ),
                            value: isSelected,
                            onChanged: (value) {
                              _toggleModel(model);
                            },
                            activeColor: Theme.of(context).colorScheme.primary,
                            controlAffinity: ListTileControlAffinity.leading,
                          );
                        },
                      ),
              ),
            ],
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
          child: const Text('Save Selection'),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }
}
