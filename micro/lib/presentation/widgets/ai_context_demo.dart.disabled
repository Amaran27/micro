import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

/// Example widget demonstrating AI-powered context analysis
class AIContextAnalysisDemo extends ConsumerWidget {
  const AIContextAnalysisDemo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiStatus = ref.watch(aiEnhancementStatusProvider);
    final contextAnalysisAsync = ref.watch(contextAnalysisProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Context Analysis Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Enhancement Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          aiStatus ? Icons.check_circle : Icons.cancel,
                          color: aiStatus ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          aiStatus
                              ? 'AI Enhancement Available'
                              : 'AI Enhancement Unavailable',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Context Analysis Results
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Context Analysis Results',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    contextAnalysisAsync.when(
                      data: (analysis) => _buildAnalysisResults(analysis),
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (error, stack) => Text(
                        'Error: $error',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action Button
            ElevatedButton(
              onPressed: () {
                // Refresh the analysis
                ref.invalidate(contextAnalysisProvider);
              },
              child: const Text('Refresh Analysis'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisResults(analysis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildResultRow('Analysis ID', analysis.id),
        _buildResultRow('Compliant', analysis.isCompliant ? 'Yes' : 'No'),
        _buildResultRow('Confidence',
            '${(analysis.confidenceScore * 100).toStringAsFixed(1)}%'),
        _buildResultRow('AI Enhanced',
            analysis.anonymizedData?['aiEnhanced'] ?? false ? 'Yes' : 'No'),
        if (analysis.anonymizedData?['aiInsights'] != null) ...[
          const SizedBox(height: 16),
          Text(
            'AI Insights:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            analysis.anonymizedData['aiInsights']['rawInsights'] ??
                'No insights available',
            style: const TextStyle(fontSize: 12),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'Granted Permissions:',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        ...analysis.grantedPermissions.map((p) => Text('• ${p.displayName}')),
        if (analysis.deniedPermissions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Denied Permissions:',
            style:
                const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          ...analysis.deniedPermissions.map((p) => Text(
                '• ${p.displayName}',
                style: const TextStyle(color: Colors.red),
              )),
        ],
      ],
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}
