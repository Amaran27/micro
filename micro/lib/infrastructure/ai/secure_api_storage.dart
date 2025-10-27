import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Secure storage service for AI provider API keys and configurations
class SecureApiStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  /// Save API key for a provider
  static Future<void> saveApiKey(String providerId, String apiKey) async {
    try {
      await _storage.write(
        key: '${providerId}_api_key',
        value: apiKey,
      );
    } catch (e) {
      debugPrint('Failed to save API key for $providerId: $e');
      rethrow;
    }
  }

  /// Get API key for a provider
  static Future<String?> getApiKey(String providerId) async {
    try {
      return await _storage.read(key: '${providerId}_api_key');
    } catch (e) {
      debugPrint('Failed to get API key for $providerId: $e');
      return null;
    }
  }

  /// Remove API key for a provider
  static Future<void> removeApiKey(String providerId) async {
    try {
      await _storage.delete(key: '${providerId}_api_key');
    } catch (e) {
      debugPrint('Failed to remove API key for $providerId: $e');
      rethrow;
    }
  }

  /// Save provider configuration
  static Future<void> saveConfiguration(
      String providerId, Map<String, dynamic> config) async {
    try {
      await _storage.write(
        key: '${providerId}_config',
        value: _serializeConfig(config),
      );
    } catch (e) {
      debugPrint('Failed to save configuration for $providerId: $e');
      rethrow;
    }
  }

  /// Get provider configuration
  static Future<Map<String, dynamic>?> getConfiguration(
      String providerId) async {
    try {
      final configString = await _storage.read(key: '${providerId}_config');
      if (configString != null) {
        return _deserializeConfig(configString);
      }
      return null;
    } catch (e) {
      debugPrint('Failed to get configuration for $providerId: $e');
      return null;
    }
  }

  /// Remove provider configuration
  static Future<void> removeConfiguration(String providerId) async {
    try {
      await _storage.delete(key: '${providerId}_config');
    } catch (e) {
      debugPrint('Failed to remove configuration for $providerId: $e');
      rethrow;
    }
  }

  /// Get all configured providers
  static Future<List<String>> getConfiguredProviders() async {
    try {
      final allKeys = await _storage.readAll();
      return allKeys.keys
          .where((key) => key.endsWith('_api_key'))
          .map((key) => key.replaceAll('_api_key', ''))
          .toList();
    } catch (e) {
      debugPrint('Failed to get configured providers: $e');
      return [];
    }
  }

  /// Check if provider is configured
  static Future<bool> isProviderConfigured(String providerId) async {
    final apiKey = await getApiKey(providerId);
    return apiKey != null && apiKey.isNotEmpty;
  }

  /// Clear all stored data
  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('Failed to clear all stored data: $e');
      rethrow;
    }
  }

  /// Serialize configuration map to string
  static String _serializeConfig(Map<String, dynamic> config) {
    return config.entries.map((e) => '${e.key}:${e.value}').join('|');
  }

  /// Deserialize configuration string to map
  static Map<String, dynamic> _deserializeConfig(String configString) {
    final config = <String, dynamic>{};
    final entries = configString.split('|');
    for (final entry in entries) {
      final parts = entry.split(':');
      if (parts.length == 2) {
        config[parts[0]] = parts[1];
      }
    }
    return config;
  }

  /// Export all configurations (for backup/restore)
  static Future<Map<String, dynamic>> exportAllConfigurations() async {
    try {
      final allData = await _storage.readAll();
      return Map.from(allData);
    } catch (e) {
      debugPrint('Failed to export configurations: $e');
      return {};
    }
  }

  /// Import configurations (for backup/restore)
  static Future<void> importConfigurations(
      Map<String, String> configurations) async {
    try {
      for (final entry in configurations.entries) {
        await _storage.write(key: entry.key, value: entry.value);
      }
    } catch (e) {
      debugPrint('Failed to import configurations: $e');
      rethrow;
    }
  }
}
