import 'dart:async';
import 'dart:convert';
import '../models/permission_type.dart';
import '../models/permission_status.dart';
import '../../../core/utils/logger.dart';

/// Audit record for permission requests
class PermissionAuditRecord {
  final String id;
  final DateTime timestamp;
  final PermissionType permissionType;
  final PermissionStatus status;
  final String? justification;
  final Map<String, dynamic>? context;
  final String? errorMessage;
  final String? userId;

  PermissionAuditRecord({
    required this.id,
    required this.timestamp,
    required this.permissionType,
    required this.status,
    this.justification,
    this.context,
    this.errorMessage,
    this.userId,
  });

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'permissionType': permissionType.name,
      'status': status.name,
      'justification': justification,
      'context': context,
      'errorMessage': errorMessage,
      'userId': userId,
    };
  }

  /// Create from JSON
  factory PermissionAuditRecord.fromJson(Map<String, dynamic> json) {
    return PermissionAuditRecord(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      permissionType: PermissionType.values.firstWhere(
        (p) => p.name == json['permissionType'],
        orElse: () => PermissionType.location,
      ),
      status: PermissionStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => PermissionStatus.denied,
      ),
      justification: json['justification'] as String?,
      context: json['context'] as Map<String, dynamic>?,
      errorMessage: json['errorMessage'] as String?,
      userId: json['userId'] as String?,
    );
  }
}

/// Export format for audit data
enum AuditExportFormat {
  json,
  csv,
  xml,
}

/// Auditor for permission requests and compliance
class PermissionAuditor {
  final List<PermissionAuditRecord> _auditLog = [];
  final AppLogger _logger;
  final int _maxLogSize = 1000; // Maximum number of records to keep

  PermissionAuditor({AppLogger? logger}) : _logger = logger ?? AppLogger();

  /// Log a permission request
  Future<void> logPermissionRequest(PermissionRequestResult result) async {
    final record = PermissionAuditRecord(
      id: 'audit_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      permissionType: result.permissionType,
      status: result.status,
      justification: result.justification,
      context: result.context,
      errorMessage: result.errorMessage,
      userId: result.context?['userId'],
    );

    _auditLog.add(record);

    // Trim log if it gets too large
    if (_auditLog.length > _maxLogSize) {
      _auditLog.removeRange(0, _auditLog.length - _maxLogSize);
    }

    _logger.info(
        'Permission request audited: ${result.permissionType.displayName} - ${result.status.name}');
  }

  /// Get audit log for a specific permission
  Future<List<PermissionAuditRecord>> getPermissionAuditLog(
    PermissionType permissionType, {
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var filteredLogs = _auditLog
        .where((record) => record.permissionType == permissionType)
        .toList();

    // Apply date filters
    if (startDate != null) {
      filteredLogs = filteredLogs
          .where((record) => record.timestamp.isAfter(startDate))
          .toList();
    }

    if (endDate != null) {
      filteredLogs = filteredLogs
          .where((record) => record.timestamp.isBefore(endDate))
          .toList();
    }

    // Sort by timestamp (newest first)
    filteredLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Apply limit
    if (limit != null && filteredLogs.length > limit) {
      filteredLogs = filteredLogs.take(limit).toList();
    }

    return filteredLogs;
  }

  /// Get full audit log
  Future<List<PermissionAuditRecord>> getFullAuditLog({
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var filteredLogs = List<PermissionAuditRecord>.from(_auditLog);

    // Apply date filters
    if (startDate != null) {
      filteredLogs = filteredLogs
          .where((record) => record.timestamp.isAfter(startDate))
          .toList();
    }

    if (endDate != null) {
      filteredLogs = filteredLogs
          .where((record) => record.timestamp.isBefore(endDate))
          .toList();
    }

    // Sort by timestamp (newest first)
    filteredLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Apply limit
    if (limit != null && filteredLogs.length > limit) {
      filteredLogs = filteredLogs.take(limit).toList();
    }

    return filteredLogs;
  }

  /// Export audit data
  Future<String> exportAuditData({
    AuditExportFormat format = AuditExportFormat.json,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final logs = await getFullAuditLog(
      startDate: startDate,
      endDate: endDate,
    );

    switch (format) {
      case AuditExportFormat.json:
        return _exportAsJson(logs);
      case AuditExportFormat.csv:
        return _exportAsCsv(logs);
      case AuditExportFormat.xml:
        return _exportAsXml(logs);
    }
  }

  /// Clear audit log
  Future<void> clearAuditLog() async {
    _auditLog.clear();
    _logger.info('Permission audit log cleared');
  }

  /// Generate compliance report
  Future<ComplianceReport> generateComplianceReport() async {
    final now = DateTime.now();
    final lastMonth = now.subtract(const Duration(days: 30));

    // Get recent logs
    final recentLogs = _auditLog
        .where((record) => record.timestamp.isAfter(lastMonth))
        .toList();

    // Calculate statistics
    final totalRequests = recentLogs.length;
    final grantedRequests =
        recentLogs.where((record) => record.status.isGranted).length;
    final deniedRequests = totalRequests - grantedRequests;

    // Check for violations
    final violations = <String>[];
    for (final record in recentLogs) {
      if (record.status == PermissionStatus.denied &&
          record.errorMessage?.contains('policy violation') == true) {
        violations.add(
            '${record.permissionType.displayName}: ${record.errorMessage}');
      }
    }

    return ComplianceReport(
      isFullyCompliant: violations.isEmpty,
      hasCriticalViolations: violations.isNotEmpty,
      summary:
          'Total requests: $totalRequests, Granted: $grantedRequests, Denied: $deniedRequests',
      violations: violations
          .map((v) => ComplianceViolation(
                permissionType: PermissionType.location, // Default
                description: v,
                severity: ViolationSeverity.medium,
              ))
          .toList(),
      warnings: [],
      compliantPermissions: PermissionType.values
          .where((p) => recentLogs
              .any((r) => r.permissionType == p && r.status.isGranted))
          .toList(),
    );
  }

  /// Export as JSON
  String _exportAsJson(List<PermissionAuditRecord> logs) {
    final auditData = {
      'exportedAt': DateTime.now().toIso8601String(),
      'totalRecords': logs.length,
      'records': logs.map((r) => r.toJson()).toList(),
    };

    return jsonEncode(auditData);
  }

  /// Export as CSV
  String _exportAsCsv(List<PermissionAuditRecord> logs) {
    final buffer = StringBuffer();

    // CSV header
    buffer.writeln(
      'timestamp,permissionType,status,justification,context,errorMessage,userId',
    );

    // CSV rows
    for (final log in logs) {
      buffer.writeln(
        '${log.timestamp.toIso8601String()},'
        '${log.permissionType.name},'
        '${log.status.name},'
        '"${log.justification ?? ''}",'
        '"${log.context?.toString() ?? ''}",'
        '"${log.errorMessage ?? ''}",'
        '"${log.userId ?? ''}"',
      );
    }

    return buffer.toString();
  }

  /// Export as XML
  String _exportAsXml(List<PermissionAuditRecord> logs) {
    final buffer = StringBuffer();

    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<auditLog>');
    buffer.writeln(
        '  <exportedAt>${DateTime.now().toIso8601String()}</exportedAt>');
    buffer.writeln('  <totalRecords>${logs.length}</totalRecords>');
    buffer.writeln('  <records>');

    for (final log in logs) {
      buffer.writeln('    <record>');
      buffer.writeln('      <id>${log.id}</id>');
      buffer.writeln(
          '      <timestamp>${log.timestamp.toIso8601String()}</timestamp>');
      buffer.writeln(
          '      <permissionType>${log.permissionType.name}</permissionType>');
      buffer.writeln('      <status>${log.status.name}</status>');
      buffer.writeln(
          '      <justification>${log.justification ?? ''}</justification>');
      buffer
          .writeln('      <context>${log.context?.toString() ?? ''}</context>');
      buffer.writeln(
          '      <errorMessage>${log.errorMessage ?? ''}</errorMessage>');
      buffer.writeln('      <userId>${log.userId ?? ''}</userId>');
      buffer.writeln('    </record>');
    }

    buffer.writeln('  </records>');
    buffer.writeln('</auditLog>');

    return buffer.toString();
  }
}

/// Compliance report
class ComplianceReport {
  final bool isFullyCompliant;
  final bool hasCriticalViolations;
  final String summary;
  final List<ComplianceViolation> violations;
  final List<String> warnings;
  final List<PermissionType> compliantPermissions;

  ComplianceReport({
    required this.isFullyCompliant,
    required this.hasCriticalViolations,
    required this.summary,
    required this.violations,
    required this.warnings,
    required this.compliantPermissions,
  });
}

/// Compliance violation
class ComplianceViolation {
  final PermissionType permissionType;
  final String description;
  final ViolationSeverity severity;

  ComplianceViolation({
    required this.permissionType,
    required this.description,
    required this.severity,
  });

  Map<String, dynamic> toJson() {
    return {
      'permissionType': permissionType.name,
      'description': description,
      'severity': severity.name,
    };
  }
}

/// Violation severity
enum ViolationSeverity {
  low,
  medium,
  high,
  critical,
}
