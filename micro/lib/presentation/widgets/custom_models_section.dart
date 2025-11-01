import 'package:flutter/material.dart';

/// Reusable widget for adding and managing custom models
/// Used in both Add and Edit provider dialogs
class CustomModelsSection extends StatefulWidget {
  final Set<String> customModels;
  final Set<String> selectedModels;
  final List<String> availableModels;
  final Function(String) onAdd;
  final Function(String) onRemove;

  const CustomModelsSection({
    super.key,
    required this.customModels,
    required this.selectedModels,
    required this.availableModels,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  State<CustomModelsSection> createState() => _CustomModelsSectionState();
}

class _CustomModelsSectionState extends State<CustomModelsSection> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addModel() {
    final modelId = _controller.text.trim();
    if (modelId.isEmpty) return;

    if (widget.customModels.contains(modelId) ||
        widget.availableModels.contains(modelId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Model "$modelId" already exists'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    widget.onAdd(modelId);
    _controller.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Custom model "$modelId" added'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.add_box_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Add Custom Model',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Add models not listed by the API (e.g., beta models, custom deployments, hidden models like glm-4.5-flash)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Model ID (e.g., glm-4.5-flash)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addModel(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _addModel,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            if (widget.customModels.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.customModels.map((model) {
                  return Chip(
                    label: Text(model),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => widget.onRemove(model),
                    avatar: Icon(
                      Icons.star,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Helper widget to display a model in the selection list with custom badge
class ModelSelectionTile extends StatelessWidget {
  final String model;
  final bool isSelected;
  final bool isCustom;
  final ValueChanged<bool?> onChanged;

  const ModelSelectionTile({
    super.key,
    required this.model,
    required this.isSelected,
    required this.isCustom,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        color: isCustom
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
            : null,
        child: CheckboxListTile(
          value: isSelected,
          title: Row(
            children: [
              Expanded(child: Text(model)),
              if (isCustom)
                Chip(
                  label: const Text(
                    'Custom',
                    style: TextStyle(fontSize: 10),
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
