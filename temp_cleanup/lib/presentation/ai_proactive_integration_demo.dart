import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/autonomous/autonomous_action.dart';
import '../../domain/models/autonomous/context_analysis.dart';
import '../../presentation/providers/autonomous_provider.dart';

/// Demo widget for AI-Proactive Behavior Integration
/// Shows how AI context analysis can trigger proactive autonomous actions
class AIProactiveIntegrationDemo extends ConsumerStatefulWidget {
  const AIProactiveIntegrationDemo({super.key});

  @override
  ConsumerState<AIProactiveIntegrationDemo> createState() =>
      _AIProactiveIntegrationDemoState();
}

class _AIProactiveIntegrationDemoState
    extends ConsumerState<AIProactiveIntegrationDemo> {
  bool _aiConsent = false;
  bool _isAnalyzing = false;
  ContextAnalysis? _currentContext;
  List<Map<String, dynamic>> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _loadAIConsent();
  }

  Future<void> _loadAIConsent() async {
    try {
      final provider = ref.read(autonomousProviderProvider);
      // For demo purposes, we'll assume consent is managed elsewhere
      setState(() => _aiConsent = true);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _updateAIConsent(bool enabled) async {
    try {
      final provider = ref.read(autonomousProviderProvider);
      await provider.updateAIConsent(enabled);
      setState(() => _aiConsent = enabled);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('AI consent ${enabled ? 'enabled' : 'disabled'}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update AI consent: $e')),
      );
    }
  }

  Future<void> _simulateContextAnalysis() async {
    setState(() => _isAnalyzing = true);

    try {
      // Simulate different context scenarios for demo
      final scenarios = [
        // Scenario 1: Evening battery monitoring
        {
          'battery_checks': 5,
          'time_of_day': 'evening',
          'battery_level': 85,
        },
        // Scenario 2: Network issues
        {
          'network_issues': 3,
          'connection_type': 'wifi',
          'signal_strength': 'weak',
        },
        // Scenario 3: Feature usage patterns
        {
          'feature_usage': {
            'camera': 10,
            'location': 8,
            'notifications': 15,
            'storage': 5,
          },
          'app_usage_time': 45, // minutes
        },
      ];

      // Use the first scenario for demo
      final contextData = scenarios[0];

      // Create a mock context analysis
      final context = ContextAnalysis(
        id: 'demo-context-${DateTime.now().millisecondsSinceEpoch}',
        contextData: contextData,
        requiredPermissions: [],
        grantedPermissions: [],
        deniedPermissions: [],
        confidenceScore: 0.9,
        isCompliant: true,
        complianceIssues: [],
        timestamp: DateTime.now(),
        userId: 'demo-user',
      );

      setState(() => _currentContext = context);

      // Get AI recommendations
      final provider = ref.read(autonomousProviderProvider);
      final recommendations = await provider.getAIActionRecommendations(
        context: context,
        userId: 'demo-user',
      );

      setState(() => _recommendations = recommendations);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Analysis failed: $e')),
      );
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _scheduleRecommendedAction(
      Map<String, dynamic> recommendation) async {
    try {
      final provider = ref.read(autonomousProviderProvider);

      // Create action based on recommendation
      final action = AutonomousAction.create(
        id: 'ai-rec-${DateTime.now().millisecondsSinceEpoch}',
        actionType: recommendation['actionType'] as ActionType,
        description: 'AI Recommended: ${recommendation['reasoning']}',
        parameters: {
          'ai_reasoning': recommendation['reasoning'],
          'confidence': recommendation['confidence'],
          'expected_benefit': recommendation['expectedBenefit'],
        },
        requiredPermissions: [],
        riskLevel: recommendation['riskLevel'] as ActionRiskLevel,
      );

      // Parse timing
      Duration? delay;
      String? cronExpression;

      final timing = recommendation['suggestedTiming'] as String;
      if (timing.startsWith('delay:')) {
        final delayMs = int.tryParse(timing.substring(6));
        if (delayMs != null) {
          delay = Duration(milliseconds: delayMs);
        }
      } else if (timing.startsWith('cron:')) {
        cronExpression = timing.substring(5);
      }

      // Schedule the AI-recommended action
      final success = await provider.scheduleAIRecommendedAction(
        action: action,
        aiReasoning: recommendation['reasoning'] as String,
        confidenceScore: recommendation['confidence'] as double,
        suggestedDelay: delay,
        suggestedCronExpression: cronExpression,
        aiContext: {
          'recommendation': recommendation,
          'context_analysis': _currentContext?.toJson(),
        },
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI-recommended action scheduled!')),
        );
        ref.invalidate(scheduledProactiveActionsProvider);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to schedule AI action')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduledActionsAsync = ref.watch(scheduledProactiveActionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI-Proactive Integration Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(scheduledProactiveActionsProvider);
            },
            tooltip: 'Refresh data',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Consent Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Integration Consent',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Allow AI to analyze your usage patterns and suggest proactive actions?',
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('AI Proactive Suggestions'),
                      subtitle: const Text(
                          'Receive AI-powered recommendations for app optimization'),
                      value: _aiConsent,
                      onChanged: _updateAIConsent,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Context Analysis Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Context Analysis',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Simulate different usage patterns to see AI recommendations:',
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isAnalyzing ? null : _simulateContextAnalysis,
                      icon: _isAnalyzing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.analytics),
                      label: Text(_isAnalyzing
                          ? 'Analyzing...'
                          : 'Analyze Usage Patterns'),
                    ),
                    if (_currentContext != null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Current Context:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _currentContext!.contextData.toString(),
                          style: const TextStyle(
                              fontFamily: 'monospace', fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // AI Recommendations Section
            if (_recommendations.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Recommendations',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ..._recommendations.map((rec) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.blue.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.lightbulb,
                                      color: Colors.amber,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Confidence: ${(rec['confidence'] * 100).round()}%',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(rec['reasoning'] as String),
                                const SizedBox(height: 8),
                                Text(
                                  'Expected Benefit: ${rec['expectedBenefit']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade700,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _scheduleRecommendedAction(rec),
                                    child: const Text('Schedule Action'),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Scheduled Actions Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Scheduled AI Actions',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    scheduledActionsAsync.when(
                      data: (actions) => actions.isEmpty
                          ? const Text('No scheduled actions')
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: actions.length,
                              itemBuilder: (context, index) {
                                final action = actions[index];
                                final isAIAction = action.parameters
                                    .containsKey('ai_reasoning');

                                return Card(
                                  color:
                                      isAIAction ? Colors.blue.shade50 : null,
                                  child: ListTile(
                                    leading: Icon(
                                      isAIAction
                                          ? Icons.smart_toy
                                          : Icons.schedule,
                                      color: isAIAction ? Colors.blue : null,
                                    ),
                                    title: Text(action.description),
                                    subtitle: Text('ID: ${action.id}'),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.cancel),
                                      onPressed: () async {
                                        final provider = ref
                                            .read(autonomousProviderProvider);
                                        await provider
                                            .cancelProactiveAction(action.id);
                                        ref.invalidate(
                                            scheduledProactiveActionsProvider);
                                      },
                                      tooltip: 'Cancel action',
                                    ),
                                  ),
                                );
                              },
                            ),
                      loading: () => const CircularProgressIndicator(),
                      error: (error, stack) => Text('Error: $error'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Information Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'About AI-Proactive Integration',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'This demo shows how AI context analysis can drive proactive autonomous actions:\n\n'
                      '1. AI analyzes user behavior patterns\n'
                      '2. Identifies opportunities for optimization\n'
                      '3. Suggests proactive actions with confidence scores\n'
                      '4. User approves high-confidence recommendations\n'
                      '5. Actions are scheduled and executed autonomously\n\n'
                      'Key Benefits:\n'
                      '• Personalized app optimization\n'
                      '• Proactive problem prevention\n'
                      '• Store-compliant AI assistance\n'
                      '• User control and transparency',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
