import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:micro/presentation/providers_ui.dart';
import 'package:micro/presentation/providers/provider_config_providers.dart';

class UnifiedProviderSettings extends ConsumerWidget {
  const UnifiedProviderSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Providers'),
        elevation: 0,
      ),
      body: _buildBody(context, ref),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProviderDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Provider'),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final configsAsync = ref.watch(providersConfigProvider);
    return configsAsync.when(
      data: (configs) => _buildProvidersList(context, ref, configs),
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading providers...'),
          ],
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(providersConfigProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProvidersList(
      BuildContext context, WidgetRef ref, List configs) {
    if (configs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No providers configured',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Add your first AI provider to get started',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey[600])),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddProviderDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Provider'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Configured Providers (${configs.length})',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold))
              .animate()
              .fadeIn(duration: 500.ms),
          const SizedBox(height: 16),
          ...configs.map((config) => Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ProviderCard(config: config),
              )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showAddProviderDialog(BuildContext context) {
    showDialog(
        context: context, builder: (context) => const AddProviderDialog());
  }
}
