import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'agent_types.dart' as agent_types;

/// Agent delegation capabilities for device-to-device communication
class AgentDelegationService {
  final String _deviceId;
  final String _baseUrl;
  WebSocketChannel? _channel;
  final Map<String, AgentConnection> _connections = {};

  AgentDelegationService({
    required String deviceId,
    String baseUrl = 'wss://agent-microservice.com/ws',
  })  : _deviceId = deviceId,
        _baseUrl = baseUrl;

  /// Connect to another agent device
  Future<void> connectToDevice({
    required String targetDeviceId,
    required String targetAgentId,
    String? authenticationToken,
  }) async {
    try {
      final uri = Uri.parse(
          '$_baseUrl/connect?deviceId=$_deviceId&targetDeviceId=$targetDeviceId&targetAgentId=$targetAgentId');
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        (message) {
          _handleDelegationMessage(message);
        },
        onError: (error) {
          debugPrint('Delegation connection error: $error');
        },
        onDone: () {
          debugPrint('Delegation connection closed');
        },
      );

      // Send authentication if provided
      if (authenticationToken != null) {
        _channel!.sink.add(jsonEncode({
          'type': 'auth',
          'token': authenticationToken,
          'deviceId': _deviceId,
        }));
      }

      final connection = AgentConnection(
        deviceId: targetDeviceId,
        agentId: targetAgentId,
        channel: _channel!,
        status: AgentConnectionStatus.connected,
        connectedAt: DateTime.now(),
      );

      _connections['$targetDeviceId:$targetAgentId'] = connection;

      debugPrint('Connected to agent $targetAgentId on device $targetDeviceId');
    } catch (e) {
      debugPrint('Failed to connect to device: $e');
      rethrow;
    }
  }

  /// Delegate a task to another agent
  Future<agent_types.AgentResult> delegateTask({
    required String targetDeviceId,
    required String targetAgentId,
    required String task,
    Map<String, dynamic>? parameters,
    int? timeoutSeconds,
  }) async {
    final connectionKey = '$targetDeviceId:$targetAgentId';

    if (!_connections.containsKey(connectionKey)) {
      throw Exception('Not connected to target device/agent');
    }

    final connection = _connections[connectionKey]!;

    final delegationRequest = {
      'type': 'task_delegation',
      'taskId': _generateTaskId(),
      'task': task,
      'parameters': parameters ?? {},
      'timeout': timeoutSeconds ?? 300, // 5 minutes default
      'sourceDeviceId': _deviceId,
      'timestamp': DateTime.now().toIso8601String(),
    };

    connection.channel.sink.add(jsonEncode(delegationRequest));

    // Wait for response
    final response =
        await _waitForTaskResponse(delegationRequest['taskId'] as String);

    return agent_types.AgentResult(
      result: response['result'] ?? 'No result provided',
      success: response['success'] ?? false,
      steps: _parseSteps(response['steps'] ?? []),
      error: response['error']?.toString(),
      metadata: {
        'delegated_to': targetDeviceId,
        'delegated_agent': targetAgentId,
        'task_id': delegationRequest['taskId'],
        'execution_time_ms': response['executionTimeMs'],
        ...?parameters,
      },
    );
  }

  /// Request agent capabilities from another device
  Future<List<agent_types.AgentCapability>> requestCapabilities({
    required String targetDeviceId,
    required String targetAgentId,
  }) async {
    final connectionKey = '$targetDeviceId:$targetAgentId';

    if (!_connections.containsKey(connectionKey)) {
      throw Exception('Not connected to target device/agent');
    }

    final connection = _connections[connectionKey]!;

    final request = {
      'type': 'capabilities_request',
      'sourceDeviceId': _deviceId,
      'timestamp': DateTime.now().toIso8601String(),
    };

    connection.channel.sink.add(jsonEncode(request));

    // Wait for capabilities response
    final response = await _waitForResponse('capabilities_response');

    return (response['capabilities'] as List)
        .map((c) => agent_types.AgentCapability(
              name: c['name'],
              description: c['description'],
              inputTypes: List<String>.from(c['inputTypes'] ?? []),
              outputTypes: List<String>.from(c['outputTypes'] ?? []),
              parameters: Map<String, dynamic>.from(c['parameters'] ?? {}),
            ))
        .toList();
  }

  /// Share resources with another agent
  Future<void> shareResource({
    required String targetDeviceId,
    required String targetAgentId,
    required String resourceId,
    required dynamic resourceData,
    String? resourceType,
  }) async {
    final connectionKey = '$targetDeviceId:$targetAgentId';

    if (!_connections.containsKey(connectionKey)) {
      throw Exception('Not connected to target device/agent');
    }

    final connection = _connections[connectionKey]!;

    final shareRequest = {
      'type': 'resource_share',
      'resourceId': resourceId,
      'resourceType': resourceType ?? 'unknown',
      'resourceData': resourceData,
      'sourceDeviceId': _deviceId,
      'timestamp': DateTime.now().toIso8601String(),
    };

    connection.channel.sink.add(jsonEncode(shareRequest));
  }

  /// Create collaborative agent group
  Future<String> createAgentGroup({
    required List<AgentReference> agents,
    required String groupName,
    String? description,
  }) async {
    final groupId = _generateGroupId();

    // Connect to all agents in the group
    for (final agent in agents) {
      if (!_connections.containsKey('${agent.deviceId}:${agent.agentId}')) {
        await connectToDevice(
          targetDeviceId: agent.deviceId,
          targetAgentId: agent.agentId,
        );
      }
    }

    final groupCreation = {
      'type': 'group_creation',
      'groupId': groupId,
      'groupName': groupName,
      'description': description,
      'coordinatorDeviceId': _deviceId,
      'agents': agents.map((a) => a.toJson()).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Notify all agents about group creation
    for (final agent in agents) {
      final connection = _connections['${agent.deviceId}:${agent.agentId}']!;
      connection.channel.sink.add(jsonEncode(groupCreation));
    }

    return groupId;
  }

  /// Execute collaborative task across multiple agents
  Future<agent_types.AgentResult> executeCollaborativeTask({
    required String groupId,
    required String task,
    Map<String, dynamic>? parameters,
    required CollaborationStrategy strategy,
  }) async {
    final groupAgents = _getGroupAgents(groupId);

    switch (strategy) {
      case CollaborationStrategy.sequential:
        return await _executeSequentialTask(groupAgents, task, parameters);
      case CollaborationStrategy.parallel:
        return await _executeParallelTask(groupAgents, task, parameters);
      case CollaborationStrategy.hierarchical:
        return await _executeHierarchicalTask(groupAgents, task, parameters);
    }
  }

  /// Disconnect from a device
  Future<void> disconnect(String deviceId, String agentId) async {
    final connectionKey = '$deviceId:$agentId';
    final connection = _connections[connectionKey];

    if (connection != null) {
      connection.channel.sink.close();
      _connections.remove(connectionKey);
      debugPrint('Disconnected from agent $agentId on device $deviceId');
    }
  }

  /// Get current connection status
  Map<String, AgentConnectionStatus> getConnectionStatus() {
    return Map.fromEntries(
      _connections.entries
          .map((entry) => MapEntry(entry.key, entry.value.status)),
    );
  }

  void _handleDelegationMessage(dynamic message) {
    try {
      final data = jsonDecode(message);

      switch (data['type']) {
        case 'task_response':
          _completeTask(data['taskId'], data);
          break;
        case 'capabilities_response':
          _completeCapabilitiesRequest(data);
          break;
        case 'resource_share':
          _handleResourceShare(data);
          break;
        case 'group_creation':
          _handleGroupCreation(data);
          break;
        case 'heartbeat':
          _updateConnectionStatus(data['deviceId'], data['agentId'],
              AgentConnectionStatus.connected);
          break;
        default:
          debugPrint('Unknown message type: ${data['type']}');
      }
    } catch (e) {
      debugPrint('Error handling delegation message: $e');
    }
  }

  String _generateTaskId() {
    return 'task_${DateTime.now().millisecondsSinceEpoch}_${_deviceId.hashCode}';
  }

  String _generateGroupId() {
    return 'group_${DateTime.now().millisecondsSinceEpoch}_${_deviceId.hashCode}';
  }

  List<agent_types.AgentStep> _parseSteps(List<dynamic> stepsData) {
    return stepsData
        .map((step) => agent_types.AgentStep(
              stepId: step['stepId'],
              description: step['description'],
              type: _parseStepType(step['type']),
              input: step['input'] != null
                  ? Map<String, dynamic>.from(step['input'])
                  : null,
              output: step['output'] != null
                  ? Map<String, dynamic>.from(step['output'])
                  : null,
              timestamp: DateTime.parse(step['timestamp']),
              duration: Duration(milliseconds: step['durationMs'] ?? 0),
            ))
        .toList();
  }

  agent_types.AgentStepType _parseStepType(String typeStr) {
    switch (typeStr) {
      case 'planning':
        return agent_types.AgentStepType.planning;
      case 'reasoning':
        return agent_types.AgentStepType.reasoning;
      case 'toolExecution':
        return agent_types.AgentStepType.toolExecution;
      case 'reflection':
        return agent_types.AgentStepType.reflection;
      case 'errorRecovery':
        return agent_types.AgentStepType.errorRecovery;
      case 'finalization':
        return agent_types.AgentStepType.finalization;
      default:
        return agent_types.AgentStepType.planning;
    }
  }

  Future<Map<String, dynamic>> _waitForTaskResponse(String taskId) async {
    // Implementation for waiting task response
    // This would typically use a completer or similar mechanism
    return await Future.delayed(const Duration(seconds: 5), () {
      return {
        'result': 'Task completed',
        'success': true,
        'steps': [],
        'executionTimeMs': 1000,
      };
    });
  }

  Future<Map<String, dynamic>> _waitForResponse(String responseType) async {
    // Implementation for waiting response
    return await Future.delayed(const Duration(seconds: 2), () {
      return {'capabilities': []};
    });
  }

  Future<agent_types.AgentResult> _executeSequentialTask(
    List<AgentReference> agents,
    String task,
    Map<String, dynamic>? parameters,
  ) async {
    final steps = <agent_types.AgentStep>[];

    for (final agent in agents) {
      final result = await delegateTask(
        targetDeviceId: agent.deviceId,
        targetAgentId: agent.agentId,
        task: task,
        parameters: parameters,
      );

      steps.addAll(result.steps);

      if (!result.success) {
        return agent_types.AgentResult(
          result: result.result,
          success: false,
          steps: steps,
          error: result.error,
        );
      }
    }

    return agent_types.AgentResult(
      result: 'Sequential task completed successfully',
      success: true,
      steps: steps,
      metadata: {
        'strategy': 'sequential',
        'agents_involved': agents.length,
      },
    );
  }

  // Additional implementations for parallel and hierarchical execution...

  List<AgentReference> _getGroupAgents(String groupId) {
    // Return empty list - implementation would store group mappings
    return [];
  }

  Future<agent_types.AgentResult> _executeParallelTask(
    List<AgentReference> agents,
    String task,
    Map<String, dynamic>? parameters,
  ) async {
    final futures = agents.map((agent) => delegateTask(
          targetDeviceId: agent.deviceId,
          targetAgentId: agent.agentId,
          task: task,
          parameters: parameters,
        ));

    final results = await Future.wait(futures);

    return agent_types.AgentResult(
      result: 'Parallel task completed successfully',
      success: results.every((r) => r.success),
      steps: results.expand((r) => r.steps).toList(),
      metadata: {
        'strategy': 'parallel',
        'agents_involved': agents.length,
      },
    );
  }

  Future<agent_types.AgentResult> _executeHierarchicalTask(
    List<AgentReference> agents,
    String task,
    Map<String, dynamic>? parameters,
  ) async {
    if (agents.isEmpty) {
      return agent_types.AgentResult(
        result: 'No agents available',
        success: false,
        steps: [],
        error: 'Empty agent list',
      );
    }

    final result = await delegateTask(
      targetDeviceId: agents[0].deviceId,
      targetAgentId: agents[0].agentId,
      task: task,
      parameters: parameters,
    );

    return agent_types.AgentResult(
      result: result.result,
      success: result.success,
      steps: result.steps,
      metadata: {
        'strategy': 'hierarchical',
        'coordinator': agents[0].agentId,
      },
    );
  }

  void _completeTask(String taskId, Map<String, dynamic> data) {
    // Implementation would complete a pending completer
    debugPrint('Task $taskId completed');
  }

  void _completeCapabilitiesRequest(Map<String, dynamic> data) {
    // Implementation would complete a pending completer
    debugPrint('Capabilities request completed');
  }

  void _handleResourceShare(Map<String, dynamic> data) {
    // Implementation would handle resource sharing
    debugPrint('Resource shared: ${data['resourceId']}');
  }

  void _handleGroupCreation(Map<String, dynamic> data) {
    // Implementation would handle group creation
    debugPrint('Group created: ${data['groupId']}');
  }

  void _updateConnectionStatus(
    String deviceId,
    String agentId,
    AgentConnectionStatus status,
  ) {
    final connectionKey = '$deviceId:$agentId';
    final connection = _connections[connectionKey];
    if (connection != null) {
      _connections[connectionKey] = AgentConnection(
        deviceId: connection.deviceId,
        agentId: connection.agentId,
        channel: connection.channel,
        status: status,
        connectedAt: connection.connectedAt,
        lastHeartbeat: DateTime.now(),
      );
    }
  }
}

/// Reference to an agent on another device
class AgentReference {
  final String deviceId;
  final String agentId;
  final String? deviceName;
  final String? agentName;
  final List<String> capabilities;

  AgentReference({
    required this.deviceId,
    required this.agentId,
    this.deviceName,
    this.agentName,
    this.capabilities = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'agentId': agentId,
      'deviceName': deviceName,
      'agentName': agentName,
      'capabilities': capabilities,
    };
  }
}

/// Connection status with another agent
class AgentConnection {
  final String deviceId;
  final String agentId;
  final WebSocketChannel channel;
  final AgentConnectionStatus status;
  final DateTime connectedAt;
  final DateTime? lastHeartbeat;

  AgentConnection({
    required this.deviceId,
    required this.agentId,
    required this.channel,
    required this.status,
    required this.connectedAt,
    this.lastHeartbeat,
  });
}

/// Connection status enumeration
enum AgentConnectionStatus {
  connecting,
  connected,
  disconnected,
  error,
}

/// Collaboration strategies for multi-agent execution
enum CollaborationStrategy {
  sequential,
  parallel,
  hierarchical,
}
