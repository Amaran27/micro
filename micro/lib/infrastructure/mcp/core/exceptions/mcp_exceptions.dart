import '../../../../core/exceptions/app_exception.dart';

/// Base exception for all MCP-related errors
class McpException extends AppException {
  final String? mcpErrorCode;
  final String? serverName;

  const McpException(
    super.message, {
    this.mcpErrorCode,
    this.serverName,
    super.code,
    super.originalError,
  });

  @override
  List<Object?> get props =>
      [message, code, originalError, mcpErrorCode, serverName];

  @override
  String toString() =>
      'McpException: $message${mcpErrorCode != null ? ' (MCP Error: $mcpErrorCode)' : ''}${serverName != null ? ' (Server: $serverName)' : ''}';
}

/// Exception thrown when MCP connection fails
class McpConnectionException extends McpException {
  final String? endpoint;
  final Duration? timeout;

  const McpConnectionException(
    super.message, {
    this.endpoint,
    this.timeout,
    super.mcpErrorCode,
    super.serverName,
    super.code,
    super.originalError,
  });

  @override
  List<Object?> get props => [
        ...super.props,
        endpoint,
        timeout,
      ];

  @override
  String toString() =>
      'McpConnectionException: $message${endpoint != null ? ' (Endpoint: $endpoint)' : ''}${timeout != null ? ' (Timeout: ${timeout!.inMilliseconds}ms)' : ''}';
}

/// Exception thrown when MCP tool execution fails
class McpToolExecutionException extends McpException {
  final String? toolName;
  final Map<String, dynamic>? parameters;

  const McpToolExecutionException(
    super.message, {
    this.toolName,
    this.parameters,
    super.mcpErrorCode,
    super.serverName,
    super.code,
    super.originalError,
  });

  @override
  List<Object?> get props => [
        ...super.props,
        toolName,
        parameters,
      ];

  @override
  String toString() =>
      'McpToolExecutionException: $message${toolName != null ? ' (Tool: $toolName)' : ''}${parameters != null ? ' (Params: ${parameters!.keys.join(', ')})' : ''}';
}

/// Exception thrown when MCP tool discovery fails
class McpToolDiscoveryException extends McpException {
  @override
  final String? serverName;

  const McpToolDiscoveryException(
    super.message, {
    this.serverName,
    super.mcpErrorCode,
    super.code,
    super.originalError,
  });

  @override
  List<Object?> get props => [
        ...super.props,
        serverName,
      ];

  @override
  String toString() =>
      'McpToolDiscoveryException: $message${serverName != null ? ' (Server: $serverName)' : ''}';
}

/// Exception thrown when MCP tool registration fails
class McpToolRegistrationException extends McpException {
  final String? toolName;
  final String? capability;

  const McpToolRegistrationException(
    super.message, {
    this.toolName,
    this.capability,
    super.mcpErrorCode,
    super.serverName,
    super.code,
    super.originalError,
  });

  @override
  List<Object?> get props => [
        ...super.props,
        toolName,
        capability,
      ];

  @override
  String toString() =>
      'McpToolRegistrationException: $message${toolName != null ? ' (Tool: $toolName)' : ''}${capability != null ? ' (Capability: $capability)' : ''}';
}

/// Exception thrown when MCP adapter fails
class McpAdapterException extends McpException {
  final String? adapterType;
  final String? targetTool;

  const McpAdapterException(
    super.message, {
    this.adapterType,
    this.targetTool,
    super.mcpErrorCode,
    super.serverName,
    super.code,
    super.originalError,
  });

  @override
  List<Object?> get props => [
        ...super.props,
        adapterType,
        targetTool,
      ];

  @override
  String toString() =>
      'McpAdapterException: $message${adapterType != null ? ' (Adapter: $adapterType)' : ''}${targetTool != null ? ' (Target: $targetTool)' : ''}';
}

/// Exception thrown when MCP resource limits are exceeded
class McpResourceLimitException extends McpException {
  final String? resourceType;
  final int? currentUsage;
  final int? limit;

  const McpResourceLimitException(
    super.message, {
    this.resourceType,
    this.currentUsage,
    this.limit,
    super.mcpErrorCode,
    super.serverName,
    super.code,
    super.originalError,
  });

  @override
  List<Object?> get props => [
        ...super.props,
        resourceType,
        currentUsage,
        limit,
      ];

  @override
  String toString() =>
      'McpResourceLimitException: $message${resourceType != null ? ' (Resource: $resourceType)' : ''}${currentUsage != null && limit != null ? ' (Usage: $currentUsage/$limit)' : ''}';
}

/// Exception thrown when MCP authentication fails
class McpAuthenticationException extends McpException {
  final String? authMethod;

  const McpAuthenticationException(
    super.message, {
    this.authMethod,
    super.mcpErrorCode,
    super.serverName,
    super.code,
    super.originalError,
  });

  @override
  List<Object?> get props => [
        ...super.props,
        authMethod,
      ];

  @override
  String toString() =>
      'McpAuthenticationException: $message${authMethod != null ? ' (Auth Method: $authMethod)' : ''}';
}

/// Exception thrown when MCP authorization fails
class McpAuthorizationException extends McpException {
  final String? requiredPermission;
  final String? requestedAction;

  const McpAuthorizationException(
    super.message, {
    this.requiredPermission,
    this.requestedAction,
    super.mcpErrorCode,
    super.serverName,
    super.code,
    super.originalError,
  });

  @override
  List<Object?> get props => [
        ...super.props,
        requiredPermission,
        requestedAction,
      ];

  @override
  String toString() =>
      'McpAuthorizationException: $message${requiredPermission != null ? ' (Required: $requiredPermission)' : ''}${requestedAction != null ? ' (Action: $requestedAction)' : ''}';
}

/// Exception thrown when MCP protocol error occurs
class McpProtocolException extends McpException {
  final String? protocolVersion;
  final String? expectedMessage;
  final String? receivedMessage;

  const McpProtocolException(
    super.message, {
    this.protocolVersion,
    this.expectedMessage,
    this.receivedMessage,
    super.mcpErrorCode,
    super.serverName,
    super.code,
    super.originalError,
  });

  @override
  List<Object?> get props => [
        ...super.props,
        protocolVersion,
        expectedMessage,
        receivedMessage,
      ];

  @override
  String toString() =>
      'McpProtocolException: $message${protocolVersion != null ? ' (Protocol: $protocolVersion)' : ''}${expectedMessage != null ? ' (Expected: $expectedMessage)' : ''}${receivedMessage != null ? ' (Received: $receivedMessage)' : ''}';
}

/// Exception thrown when MCP server is unavailable
class McpServerUnavailableException extends McpException {
  final String? serverAddress;
  final int? port;
  final DateTime? lastAvailable;

  const McpServerUnavailableException(
    super.message, {
    this.serverAddress,
    this.port,
    this.lastAvailable,
    super.mcpErrorCode,
    super.serverName,
    super.code,
    super.originalError,
  });

  @override
  List<Object?> get props => [
        ...super.props,
        serverAddress,
        port,
        lastAvailable,
      ];

  @override
  String toString() =>
      'McpServerUnavailableException: $message${serverAddress != null ? ' (Address: $serverAddress)' : ''}${port != null ? ' (Port: $port)' : ''}${lastAvailable != null ? ' (Last Available: ${lastAvailable!.toIso8601String()})' : ''}';
}

/// Exception thrown when MCP configuration is invalid
class McpConfigurationException extends McpException {
  final String? configKey;
  final dynamic configValue;

  const McpConfigurationException(
    super.message, {
    this.configKey,
    this.configValue,
    super.mcpErrorCode,
    super.serverName,
    super.code,
    super.originalError,
  });

  @override
  List<Object?> get props => [
        ...super.props,
        configKey,
        configValue,
      ];

  @override
  String toString() =>
      'McpConfigurationException: $message${configKey != null ? ' (Config: $configKey)' : ''}${configValue != null ? ' (Value: $configValue)' : ''}';
}
