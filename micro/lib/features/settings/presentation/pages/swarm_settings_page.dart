import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro/features/settings/presentation/providers/swarm_settings_providers.dart';

class SwarmSettingsPage extends ConsumerStatefulWidget {
  const SwarmSettingsPage({super.key});

  @override
  ConsumerState<SwarmSettingsPage> createState() => _SwarmSettingsPageState();
}

class _SwarmSettingsPageState extends ConsumerState<SwarmSettingsPage> {
  int? _currentValue; // local editing state
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Preload current value
    Future.microtask(() async {
      final service = ref.read(swarmSettingsServiceProvider);
      final value = await service.getMaxSpecialists();
      if (mounted) setState(() => _currentValue = value);
    });
  }

  Future<void> _save() async {
    if (_currentValue == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final service = ref.read(swarmSettingsServiceProvider);
      await service.setMaxSpecialists(_currentValue!);
      // Force provider refresh
      ref.invalidate(maxSpecialistsProvider);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncVal = ref.watch(maxSpecialistsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Swarm Settings')),
      body: asyncVal.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
        data: (value) {
          final effectiveValue = _currentValue ?? value;
          return LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 420;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configuration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Adjust swarm specialist capacity. Lower values reduce cost; higher values enable broader domain coverage.',
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Slider(
                                    min: 1,
                                    max: 10,
                                    divisions: 9,
                                    label: '$effectiveValue',
                                    value: effectiveValue.toDouble(),
                                    onChanged: (v) => setState(
                                        () => _currentValue = v.round()),
                                  ),
                                ),
                                Text('$effectiveValue',
                                    style: const TextStyle(fontSize: 16)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _PresetChip(
                                    label: 'Cost Saver (1-2)',
                                    onTap: () =>
                                        setState(() => _currentValue = 2)),
                                _PresetChip(
                                    label: 'Balanced (3-4)',
                                    onTap: () =>
                                        setState(() => _currentValue = 4)),
                                _PresetChip(
                                    label: 'Comprehensive (5-6)',
                                    onTap: () =>
                                        setState(() => _currentValue = 6)),
                                _PresetChip(
                                    label: 'Deep Analysis (7-8)',
                                    onTap: () =>
                                        setState(() => _currentValue = 8)),
                                _PresetChip(
                                    label: 'Maximum (9-10)',
                                    onTap: () =>
                                        setState(() => _currentValue = 10)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_error != null)
                              Text(_error!,
                                  style: const TextStyle(color: Colors.red)),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _saving ? null : _save,
                                  icon: const Icon(Icons.save),
                                  label: _saving
                                      ? const Text('Saving...')
                                      : const Text('Save'),
                                ),
                                const SizedBox(width: 16),
                                TextButton(
                                  onPressed: _saving
                                      ? null
                                      : () async {
                                          final service = ref.read(
                                              swarmSettingsServiceProvider);
                                          await service.reset();
                                          ref.invalidate(
                                              maxSpecialistsProvider);
                                          final resetVal =
                                              await service.getMaxSpecialists();
                                          if (mounted) {
                                            setState(
                                                () => _currentValue = resetVal);
                                          }
                                        },
                                  child: const Text('Reset'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _AnalysisPreview(value: effectiveValue),
                    SizedBox(height: isSmall ? 32 : 8),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PresetChip({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return ActionChip(label: Text(label), onPressed: onTap);
  }
}

class _AnalysisPreview extends StatelessWidget {
  final int value;
  const _AnalysisPreview({required this.value});

  @override
  Widget build(BuildContext context) {
    String mode;
    if (value <= 2) {
      mode = 'Cost Saver: Minimal specialists, fast & cheap.';
    } else if (value <= 4) {
      mode = 'Balanced: Good coverage with moderate cost.';
    } else if (value <= 6) {
      mode = 'Comprehensive: Multi-domain depth enabled.';
    } else if (value <= 8) {
      mode = 'Deep Analysis: High coverage, higher cost.';
    } else {
      mode = 'Maximum: Full swarm potential, highest cost.';
    }
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selection Impact',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(mode),
            const SizedBox(height: 8),
            Text(
                'Estimated token multiplier: x${(value / 3).toStringAsFixed(2)}'),
            Text(
                'Recommended for: ${value <= 4 ? 'General tasks' : value <= 8 ? 'Complex analysis' : 'Full diagnostic workflows'}'),
          ],
        ),
      ),
    );
  }
}
