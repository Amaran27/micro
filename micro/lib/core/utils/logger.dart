import 'package:logger/logger.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../constants.dart';
import '../../config/app_config.dart';

class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  late Logger _logger;
  late File _logFile;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Get application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final logDir = Directory(path.join(appDir.path, 'logs'));

      // Create logs directory if it doesn't exist
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      // Create log file with timestamp
      final timestamp = DateTime.now().toIso8601String().split('T')[0];
      _logFile = File(
          path.join(logDir.path, '${AppConstants.logFileName}.$timestamp'));

      // Initialize logger with custom output
      _logger = Logger(
        level: _getLogLevel(),
        printer: PrettyPrinter(
          methodCount: 2,
          errorMethodCount: 8,
          lineLength: 120,
          colors: true,
          printEmojis: true,
          dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
        ),
        output: MultiOutput([
          ConsoleOutput(),
          FileOutput(file: _logFile),
        ]),
      );

      // Clean old log files
      await _cleanOldLogs();

      _initialized = true;
      _logger.i('Logger initialized successfully');
    } catch (e) {
      // Fallback to console-only logging if file initialization fails
      _logger = Logger(
        level: _getLogLevel(),
        printer: PrettyPrinter(
          methodCount: 2,
          errorMethodCount: 8,
          lineLength: 120,
          colors: true,
          printEmojis: true,
          dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
        ),
      );
      _logger.e('Failed to initialize file logging: $e');
    }
  }

  Level _getLogLevel() {
    switch (AppConfig.logLevel) {
      case LogLevel.debug:
        return Level.debug;
      case LogLevel.info:
        return Level.info;
      case LogLevel.warning:
        return Level.warning;
      case LogLevel.error:
        return Level.error;
      case LogLevel.fatal:
        return Level.fatal;
    }
  }

  Future<void> _cleanOldLogs() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logDir = Directory(path.join(appDir.path, 'logs'));

      if (!await logDir.exists()) return;

      final files = await logDir.list().toList();
      final logFiles = files
          .whereType<File>()
          .where((file) => file.path.endsWith('.log'))
          .toList();

      // Sort by modification time (newest first)
      logFiles.sort(
          (a, b) => b.statSync().modified.compareTo(a.statSync().modified));

      // Keep only the most recent files
      if (logFiles.length > AppConstants.maxLogFiles) {
        for (int i = AppConstants.maxLogFiles; i < logFiles.length; i++) {
          try {
            await logFiles[i].delete();
            _logger.d('Deleted old log file: ${logFiles[i].path}');
          } catch (e) {
            _logger.e('Failed to delete log file ${logFiles[i].path}: $e');
          }
        }
      }

      // Check file sizes and rotate if necessary
      for (final file in logFiles.take(AppConstants.maxLogFiles)) {
        final stat = file.statSync();
        final sizeKB = stat.size / 1024;

        if (sizeKB > AppConstants.maxLogFileSizeKB) {
          try {
            // Create backup and truncate
            final backupFile = File('${file.path}.old');
            if (await backupFile.exists()) {
              await backupFile.delete();
            }
            await file.rename(backupFile.path);
            _logger.d('Rotated log file: ${file.path}');
          } catch (e) {
            _logger.e('Failed to rotate log file ${file.path}: $e');
          }
        }
      }
    } catch (e) {
      _logger.e('Failed to clean old logs: $e');
    }
  }

  void debug(String message, {Object? error, StackTrace? stackTrace}) {
    if (!_initialized) {
      print('DEBUG: $message');
      return;
    }
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  void info(String message, {Object? error, StackTrace? stackTrace}) {
    if (!_initialized) {
      print('INFO: $message');
      return;
    }
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  void warning(String message, {Object? error, StackTrace? stackTrace}) {
    if (!_initialized) {
      print('WARNING: $message');
      return;
    }
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  void error(String message, {Object? error, StackTrace? stackTrace}) {
    if (!_initialized) {
      print('ERROR: $message');
      if (error != null) print('Error details: $error');
      return;
    }
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  void fatal(String message, {Object? error, StackTrace? stackTrace}) {
    if (!_initialized) {
      print('FATAL: $message');
      if (error != null) print('Error details: $error');
      return;
    }
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  void logSecurityEvent(String event, {Map<String, dynamic>? details}) {
    final message =
        'SECURITY: $event${details != null ? ' - ${details.toString()}' : ''}';
    warning(message);
  }

  void logPerformanceMetric(String metric, dynamic value, {String? unit}) {
    final message =
        'PERFORMANCE: $metric = $value${unit != null ? ' $unit' : ''}';
    info(message);
  }

  void logUserAction(String action, {Map<String, dynamic>? context}) {
    final message =
        'USER_ACTION: $action${context != null ? ' - ${context.toString()}' : ''}';
    info(message);
  }

  void logNetworkRequest(String method, String url,
      {int? statusCode, Duration? duration}) {
    final message =
        'NETWORK: $method $url${statusCode != null ? ' -> $statusCode' : ''}${duration != null ? ' (${duration.inMilliseconds}ms)' : ''}';
    info(message);
  }

  void logWorkflowEvent(String workflowId, String event,
      {Map<String, dynamic>? data}) {
    final message =
        'WORKFLOW: $workflowId - $event${data != null ? ' - ${data.toString()}' : ''}';
    info(message);
  }

  void logMcpEvent(String event, {Map<String, dynamic>? details}) {
    final message =
        'MCP: $event${details != null ? ' - ${details.toString()}' : ''}';
    info(message);
  }

  void logAgentEvent(String agentId, String event,
      {Map<String, dynamic>? data}) {
    final message =
        'AGENT: $agentId - $event${data != null ? ' - ${data.toString()}' : ''}';
    info(message);
  }

  Future<String?> getLogFilePath() async {
    if (!_initialized) return null;
    return _logFile.path;
  }

  Future<String?> getLogContents() async {
    if (!_initialized) return null;
    try {
      return await _logFile.readAsString();
    } catch (e) {
      error('Failed to read log file: $e');
      return null;
    }
  }

  Future<void> clearLogs() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logDir = Directory(path.join(appDir.path, 'logs'));

      if (await logDir.exists()) {
        await for (final entity in logDir.list()) {
          if (entity is File) {
            await entity.delete();
          }
        }
      }

      if (_initialized) {
        _logger.i('All logs cleared');
      }
    } catch (e) {
      if (_initialized) {
        _logger.e('Failed to clear logs: $e');
      }
    }
  }
}

class FileOutput extends LogOutput {
  final File file;
  late IOSink _sink;

  FileOutput({required this.file});

  @override
  Future<void> init() async {
    _sink = file.openWrite(mode: FileMode.append);
  }

  @override
  void output(OutputEvent event) {
    for (final line in event.lines) {
      _sink.writeln('${DateTime.now().toIso8601String()} $line');
    }
  }

  @override
  Future<void> destroy() async {
    await _sink.close();
  }
}

// Global logger instance
final logger = AppLogger();
