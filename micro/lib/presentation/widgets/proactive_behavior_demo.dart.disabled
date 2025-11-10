import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/autonomous/autonomous_action.dart';
import '../../presentation/providers/autonomous_provider.dart';

/// Demo widget for the Proactive Behavior Engine
/// Shows how to schedule and manage autonomous proactive actions
class ProactiveBehaviorDemo extends ConsumerStatefulWidget {
  const ProactiveBehaviorDemo({super.key});

  @override
  ConsumerState<ProactiveBehaviorDemo> createState() =>
      _ProactiveBehaviorDemoState();
}

class _ProactiveBehaviorDemoState extends ConsumerState<ProactiveBehaviorDemo> {
  bool _isInitialized = false;
  bool _notificationsEnabled = true;
  bool _resourceMonitoringEnabled = true;
  final TextEditingController _cronController = TextEditingController();
  final TextEditingController _delayController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeProactiveEngine();
  }

  @override
  void dispose() {
    _cronController.dispose();
    _delayController.dispose();
    super.dispose();
  }

  Future<void> _initializeProactiveEngine() async {
    try {
      final provider = ref.read(autonomousProviderProvider);
      await provider.proactiveBehaviorEngine.initialize();
      setState(() => _isInitialized = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initialize: $e')),
      );
    }
  }

  Future<void> _scheduleSampleAction({
    Duration? delay,
    String? cronExpression,
  }) async {
    final provider = ref.read(autonomousProviderProvider);

    // Create a sample proactive action
    final action = AutonomousAction.create(
      id: 'sample-proactive-${DateTime.now().millisecondsSinceEpoch}',
      actionType: ActionType.monitor,
      description: 'Sample proactive system maintenance action',
      parameters: {
        'maintenance_type': 'cleanup',
        'priority': 'low',
      },
      requiredPermissions: [],
      riskLevel: ActionRiskLevel.low,
    );

    try {
      final success = await provider.scheduleProactiveAction(
        action: action,
        delay: delay,
        cronExpression: cronExpression,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Proactive action scheduled successfully')),
        );
        ref.invalidate(scheduledProactiveActionsProvider);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to schedule proactive action')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _cancelAction(String actionId) async {
    final provider = ref.read(autonomousProviderProvider);

    try {
      final success = await provider.cancelProactiveAction(actionId);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Action cancelled successfully')),
        );
        ref.invalidate(scheduledProactiveActionsProvider);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to cancel action')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _updateConfiguration() async {
    final provider = ref.read(autonomousProviderProvider);

    try {
      await provider.proactiveBehaviorEngine.updateConfiguration(
        notificationsEnabled: _notificationsEnabled,
        resourceMonitoringEnabled: _resourceMonitoringEnabled,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuration updated')),
      );
      ref.invalidate(proactiveResourceUsageProvider);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating configuration: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduledActionsAsync = ref.watch(scheduledProactiveActionsProvider);
    final resourceUsageAsync = ref.watch(proactiveResourceUsageProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proactive Behavior Engine Demo'),
        actions: [
          if (_isInitialized)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.invalidate(scheduledProactiveActionsProvider);
                ref.invalidate(proactiveResourceUsageProvider);
              },
              tooltip: 'Refresh data',
            ),
        ],
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Configuration Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Configuration',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text('Enable Notifications'),
                            subtitle: const Text(
                                'Show user notifications for proactive actions'),
                            value: _notificationsEnabled,
                            onChanged: (value) =>
                                setState(() => _notificationsEnabled = value),
                          ),
                          SwitchListTile(
                            title: const Text('Enable Resource Monitoring'),
                            subtitle: const Text(
                                'Monitor system resources during execution'),
                            value: _resourceMonitoringEnabled,
                            onChanged: (value) => setState(
                                () => _resourceMonitoringEnabled = value),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _updateConfiguration,
                            child: const Text('Update Configuration'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Schedule Actions Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Schedule Proactive Actions',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _delayController,
                                  decoration: const InputDecoration(
                                    labelText: 'Delay (seconds)',
                                    hintText: 'e.g., 60',
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: () {
                                  final delaySeconds =
                                      int.tryParse(_delayController.text);
                                  if (delaySeconds != null &&
                                      delaySeconds > 0) {
                                    _scheduleSampleAction(
                                      delay: Duration(seconds: delaySeconds),
                                    );
                                  }
                                },
                                child: const Text('Schedule with Delay'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _cronController,
                                  decoration: const InputDecoration(
                                    labelText: 'Cron Expression',
                                    hintText: 'e.g., 0 9 * * * (daily at 9 AM)',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: () {
                                  if (_cronController.text.isNotEmpty) {
                                    _scheduleSampleAction(
                                      cronExpression: _cronController.text,
                                    );
                                  }
                                },
                                child: const Text('Schedule with Cron'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _scheduleSampleAction(),
                            child: const Text('Schedule Immediate Action'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Scheduled Actions Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Scheduled Actions',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          scheduledActionsAsync.when(
                            data: (actions) => actions.isEmpty
                                ? const Text('No scheduled actions')
                                : ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: actions.length,
                                    itemBuilder: (context, index) {
                                      final action = actions[index];
                                      return ListTile(
                                        title: Text(action.description),
                                        subtitle: Text('ID: ${action.id}'),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.cancel),
                                          onPressed: () =>
                                              _cancelAction(action.id),
                                          tooltip: 'Cancel action',
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

                  // Resource Usage Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Resource Usage',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          resourceUsageAsync.when(
                            data: (usage) => Column(
                              children: usage.entries.map((entry) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(entry.key.toUpperCase()),
                                      Text('${entry.value}'),
                                    ],
                                  ),
                                );
                              }).toList(),
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
                            'About Proactive Behavior Engine',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'The Proactive Behavior Engine enables autonomous actions to be scheduled '
                            'and executed based on various triggers. It includes:\n\n'
                            '• User notifications for proactive actions\n'
                            '• Resource monitoring and limits\n'
                            '• Cron-based scheduling\n'
                            '• Store compliance and privacy protection\n'
                            '• Audit logging for all activities\n\n'
                            'This demo shows basic scheduling functionality. In a real application, '
                            'proactive actions would be triggered by AI analysis of user behavior patterns.',
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
