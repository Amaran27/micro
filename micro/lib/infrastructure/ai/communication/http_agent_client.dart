/// HTTP Client for desktop agent communication (Phase 1: REST)
/// 
/// This client enables the mobile app to delegate tasks to the desktop agent
/// backend via REST API.
library;

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:micro/core/utils/logger.dart';

/// Request model for task execution
class AgentTaskRequest {
  final String task;
  final Map<String, dynamic>? context;

  AgentTaskRequest({required this.task, this.context});

  Map<String, dynamic> toJson() => {
        'task': task,
        if (context != null) 'context': context,
      };
}

/// Response when task is submitted
class AgentTaskResponse {
  final String taskId;
  final String status;
  final String message;

  AgentTaskResponse({
    required this.taskId,
    required this.status,
    required this.message,
  });

  factory AgentTaskResponse.fromJson(Map<String, dynamic> json) {
    return AgentTaskResponse(
      taskId: json['task_id'] as String,
      status: json['status'] as String,
      message: json['message'] as String,
    );
  }
}

/// HTTP client for desktop agent communication
class HttpAgentClient {
  final String baseUrl;
  final Dio _dio;
  final AppLogger _logger = AppLogger();

  HttpAgentClient({
    required this.baseUrl,
    Dio? dio,
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 30),
                headers: {'Content-Type': 'application/json'},
              ),
            );

  /// Submit a task to the desktop agent
  Future<AgentTaskResponse> submitTask(AgentTaskRequest request) async {
    try {
      _logger.info('Submitting task to desktop agent: ${request.task}');
      final response = await _dio.post('/api/v1/agent/task', data: request.toJson());
      final taskResponse = AgentTaskResponse.fromJson(response.data);
      _logger.info('Task submitted: ${taskResponse.taskId}');
      return taskResponse;
    } on DioException catch (e) {
      _logger.error('Failed to submit task: ${e.message}');
      throw Exception('Failed to submit task: ${_mapDioError(e)}');
    }
  }

  /// Submit a task with multi-agent coordination (Phase 3)
  Future<AgentTaskResponse> submitMultiAgentTask(AgentTaskRequest request) async {
    try {
      _logger.info('Submitting multi-agent task: ${request.task}');
      final response = await _dio.post('/api/v1/agent/multi-agent/task', data: request.toJson());
      final taskResponse = AgentTaskResponse.fromJson(response.data);
      _logger.info('Multi-agent task submitted: ${taskResponse.taskId}');
      return taskResponse;
    } on DioException catch (e) {
      _logger.error('Failed to submit multi-agent task: ${e.message}');
      throw Exception('Failed to submit multi-agent task: ${_mapDioError(e)}');
    }
  }

  /// Get multi-agent system information (Phase 3)
  Future<Map<String, dynamic>> getMultiAgentInfo() async {
    try {
      _logger.info('Fetching multi-agent system info');
      final response = await _dio.get('/api/v1/agent/multi-agent/info');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _logger.error('Failed to get multi-agent info: ${e.message}');
      throw Exception('Failed to get multi-agent info: ${_mapDioError(e)}');
    }
  }

  /// Health check
  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get('/health');
      return response.data['status'] == 'healthy';
    } catch (e) {
      return false;
    }
  }

  String _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout';
    } else if (e.type == DioExceptionType.unknown) {
      return 'Cannot connect to desktop agent at $baseUrl';
    }
    return e.message ?? 'Unknown error';
  }
}
