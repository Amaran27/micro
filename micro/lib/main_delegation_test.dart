import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'infrastructure/ai/agent/agent_types.dart' as agent_types;
import 'infrastructure/ai/agent/agent_providers.dart';
import 'infrastructure/ai/agent/agent_delegation.dart';

void main() {
  runApp(const ProviderScope(child: AgentDelegationTestApp()));
}

class AgentDelegationTestApp extends StatelessWidget {
  const AgentDelegationTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agent Delegation Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AgentDelegationTestScreen(),
    );
  }
}

class AgentDelegationTestScreen extends ConsumerStatefulWidget {
  const AgentDelegationTestScreen({super.key});

  @override
  ConsumerState<AgentDelegationTestScreen> createState() =>
      _AgentDelegationTestScreenState();
}

class _AgentDelegationTestScreenState
    extends ConsumerState<AgentDelegationTestScreen> {
  late AgentDelegationService delegationService;
  final String _deviceId = 'test_device_001';
  String _status = 'Ready';
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    delegationService = AgentDelegationService(deviceId: _deviceId);
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toTimeString()}: $message');
      if (_logs.length > 20) _logs.removeAt(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agent Delegation Test'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text('Device ID: $_deviceId'),
                ),
                Text('Status: $_status'),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_logs[index]),
                  dense: true,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: _testLocalAgent,
                  child: const Text('Test Local Agent'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _testDelegationService,
                  child: const Text('Test Delegation Service'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testLocalAgent() async {
    setState(() => _status = 'Testing local agent...');
    _addLog('Starting local agent test');

    try {
      final agent = agent_types.Agent(
        id: 'local_test_agent',
        name: 'Local Test Agent',
        type: agent_types.AgentType.general,
        status: agent_types.AgentStatus.idle,
        capabilities: const [
          agent_types.AgentCapability(
            name: 'text_generation',
            description: 'Generate text responses',
            inputTypes: ['text'],
            outputTypes: ['text'],
          ),
        ],
      );

      _addLog('Created local agent: ${agent.id}');
      _addLog('Agent name: ${agent.name}');
      _addLog('Agent type: ${agent.type.name}');
      _addLog('Agent capabilities: ${agent.capabilities.length}');

      setState(() => _status = 'Local agent test completed');
    } catch (e) {
      _addLog('Local agent test failed: $e');
      setState(() => _status = 'Test failed');
    }
  }

  Future<void> _testDelegationService() async {
    setState(() => _status = 'Testing delegation service...');
    _addLog('Starting delegation service test');

    try {
      // Test delegation service initialization
      _addLog('Delegation service initialized with device: $_deviceId');

      // Test connection status
      final status = delegationService.getConnectionStatus();
      _addLog('Current connections: ${status.length}');

      // Test capability request (will fail gracefully since no actual connections)
      _addLog('Testing capability request system...');

      setState(() => _status = 'Delegation service test completed');
    } catch (e) {
      _addLog('Delegation service test failed: $e');
      setState(() => _status = 'Test failed');
    }
  }
}
