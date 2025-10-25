import 'package:equatable/equatable.dart';

abstract class AppException extends Equatable implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(
    this.message, {
    this.code,
    this.originalError,
  });

  @override
  List<Object?> get props => [message, code, originalError];

  @override
  String toString() =>
      'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.code,
    super.originalError,
  });

  @override
  String toString() => 'NetworkException: $message';
}

class ServerException extends AppException {
  final int? statusCode;

  const ServerException(
    super.message, {
    this.statusCode,
    super.code,
    super.originalError,
  });

  @override
  List<Object?> get props => [message, code, originalError, statusCode];

  @override
  String toString() =>
      'ServerException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}

class DatabaseException extends AppException {
  const DatabaseException(
    super.message, {
    super.code,
    super.originalError,
  });

  @override
  String toString() => 'DatabaseException: $message';
}

class SecurityException extends AppException {
  const SecurityException(
    super.message, {
    super.code,
    super.originalError,
  });

  @override
  String toString() => 'SecurityException: $message';
}

class AuthenticationException extends AppException {
  const AuthenticationException(
    super.message, {
    super.code,
    super.originalError,
  });

  @override
  String toString() => 'AuthenticationException: $message';
}

class AuthorizationException extends AppException {
  const AuthorizationException(
    super.message, {
    super.code,
    super.originalError,
  });

  @override
  String toString() => 'AuthorizationException: $message';
}

class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException(
    super.message, {
    this.fieldErrors,
    super.code,
    super.originalError,
  });

  @override
  List<Object?> get props => [message, code, originalError, fieldErrors];

  @override
  String toString() =>
      'ValidationException: $message${fieldErrors != null ? ' (Fields: ${fieldErrors!.keys.join(', ')})' : ''}';
}

class ResourceNotFoundException extends AppException {
  final String? resourceType;
  final String? resourceId;

  const ResourceNotFoundException(
    super.message, {
    this.resourceType,
    this.resourceId,
    super.code,
    super.originalError,
  });

  @override
  List<Object?> get props =>
      [message, code, originalError, resourceType, resourceId];

  @override
  String toString() =>
      'ResourceNotFoundException: $message${resourceType != null ? ' (Type: $resourceType)' : ''}${resourceId != null ? ' (ID: $resourceId)' : ''}';
}

class ConflictException extends AppException {
  const ConflictException(
    super.message, {
    super.code,
    super.originalError,
  });

  @override
  String toString() => 'ConflictException: $message';
}

class TimeoutException extends AppException {
  final Duration? timeout;

  const TimeoutException(
    super.message, {
    this.timeout,
    super.code,
    super.originalError,
  });

  @override
  List<Object?> get props => [message, code, originalError, timeout];

  @override
  String toString() =>
      'TimeoutException: $message${timeout != null ? ' (Timeout: ${timeout!.inSeconds}s)' : ''}';
}

class McpException extends AppException {
  final String? mcpErrorCode;

  const McpException(
    super.message, {
    this.mcpErrorCode,
    super.code,
    super.originalError,
  });

  @override
  List<Object?> get props => [message, code, originalError, mcpErrorCode];

  @override
  String toString() =>
      'McpException: $message${mcpErrorCode != null ? ' (MCP Error: $mcpErrorCode)' : ''}';
}

class WorkflowException extends AppException {
  final String? workflowId;
  final String? workflowState;

  const WorkflowException(
    super.message, {
    this.workflowId,
    this.workflowState,
    super.code,
    super.originalError,
  });

  @override
  List<Object?> get props =>
      [message, code, originalError, workflowId, workflowState];

  @override
  String toString() =>
      'WorkflowException: $message${workflowId != null ? ' (Workflow: $workflowId)' : ''}${workflowState != null ? ' (State: $workflowState)' : ''}';
}

class AgentException extends AppException {
  final String? agentId;
  final String? agentState;

  const AgentException(
    super.message, {
    this.agentId,
    this.agentState,
    super.code,
    super.originalError,
  });

  @override
  List<Object?> get props =>
      [message, code, originalError, agentId, agentState];

  @override
  String toString() =>
      'AgentException: $message${agentId != null ? ' (Agent: $agentId)' : ''}${agentState != null ? ' (State: $agentState)' : ''}';
}

class PermissionException extends AppException {
  final String? permission;

  const PermissionException(
    super.message, {
    this.permission,
    super.code,
    super.originalError,
  });

  @override
  List<Object?> get props => [message, code, originalError, permission];

  @override
  String toString() =>
      'PermissionException: $message${permission != null ? ' (Permission: $permission)' : ''}';
}

class StorageException extends AppException {
  const StorageException(
    super.message, {
    super.code,
    super.originalError,
  });

  @override
  String toString() => 'StorageException: $message';
}

class CacheException extends AppException {
  const CacheException(
    super.message, {
    super.code,
    super.originalError,
  });

  @override
  String toString() => 'CacheException: $message';
}

class ConfigurationException extends AppException {
  final String? configurationKey;

  const ConfigurationException(
    super.message, {
    this.configurationKey,
    super.code,
    super.originalError,
  });

  @override
  List<Object?> get props => [message, code, originalError, configurationKey];

  @override
  String toString() =>
      'ConfigurationException: $message${configurationKey != null ? ' (Key: $configurationKey)' : ''}';
}
