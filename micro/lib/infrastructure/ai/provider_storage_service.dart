/// Provider Storage Service
///
/// Manages persistent storage of provider configurations
library;

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/logger.dart';
import 'provider_config_model.dart';

class ProviderStorageService {
  static final ProviderStorageService _instance =
      ProviderStorageService._internal();
  static const String _configKeyPrefix = 'provider_config_';
  static const String _apiKeyPrefix = 'provider_apikey_';

  final FlutterSecureStorage _secureStorage;
  final AppLogger _logger;

  factory ProviderStorageService() {
    return _instance;
  }

  ProviderStorageService._internal()
      : _secureStorage = const FlutterSecureStorage(),
        _logger = AppLogger();

  /// Save provider configuration
  Future<void> saveConfig(ProviderConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(config.toJson());

      await prefs.setString('$_configKeyPrefix${config.id}', json);
      await _secureStorage.write(
        key: '$_apiKeyPrefix${config.id}',
        value: config.apiKey,
      );

      _logger.info('Saved provider config: ${config.id}');
    } catch (e) {
      _logger.error('Failed to save provider config', error: e);
      rethrow;
    }
  }

  /// Load provider configuration
  Future<ProviderConfig?> loadConfig(String configId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('$_configKeyPrefix$configId');

      if (jsonString == null) {
        return null;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final apiKey = await _secureStorage.read(key: '$_apiKeyPrefix$configId');

      if (apiKey != null) {
        json['apiKey'] = apiKey;
      }

      return ProviderConfig.fromJson(json);
    } catch (e) {
      _logger.error('Failed to load provider config', error: e);
      return null;
    }
  }

  /// Get all provider configurations
  Future<List<ProviderConfig>> getAllConfigs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final configs = <ProviderConfig>[];

      for (final key in keys) {
        if (key.startsWith(_configKeyPrefix)) {
          final configId = key.replaceFirst(_configKeyPrefix, '');
          final config = await loadConfig(configId);
          if (config != null) {
            configs.add(config);
          }
        }
      }

      _logger.info('Loaded ${configs.length} provider configs');
      return configs;
    } catch (e) {
      _logger.error('Failed to load all configs', error: e);
      return [];
    }
  }

  /// Delete provider configuration
  Future<void> deleteConfig(String configId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_configKeyPrefix$configId');
      await _secureStorage.delete(key: '$_apiKeyPrefix$configId');
      _logger.info('Deleted provider config: $configId');
    } catch (e) {
      _logger.error('Failed to delete provider config', error: e);
      rethrow;
    }
  }

  /// Check if configuration exists
  Future<bool> configExists(String configId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey('$_configKeyPrefix$configId');
    } catch (e) {
      _logger.error('Failed to check config existence', error: e);
      return false;
    }
  }

  /// Get configurations for a specific provider
  Future<List<ProviderConfig>> getConfigsByProvider(String providerId) async {
    try {
      final allConfigs = await getAllConfigs();
      return allConfigs.where((c) => c.providerId == providerId).toList();
    } catch (e) {
      _logger.error('Failed to get configs by provider', error: e);
      return [];
    }
  }

  /// Get enabled configurations
  Future<List<ProviderConfig>> getEnabledConfigs() async {
    try {
      final allConfigs = await getAllConfigs();
      return allConfigs.where((c) => c.isEnabled).toList();
    } catch (e) {
      _logger.error('Failed to get enabled configs', error: e);
      return [];
    }
  }

  /// Get all favorite models across all enabled providers
  Future<List<String>> getAllFavoriteModels() async {
    try {
      final enabledConfigs = await getEnabledConfigs();
      final models = <String>[];
      for (final config in enabledConfigs) {
        models.addAll(config.favoriteModels);
      }
      return models;
    } catch (e) {
      _logger.error('Failed to get favorite models', error: e);
      return [];
    }
  }

  /// Get favorite models for a specific provider
  Future<List<String>> getFavoriteModelsByProvider(String providerId) async {
    try {
      final configs = await getConfigsByProvider(providerId);
      final models = <String>[];
      for (final config in configs.where((c) => c.isEnabled)) {
        models.addAll(config.favoriteModels);
      }
      return models;
    } catch (e) {
      _logger.error('Failed to get favorite models by provider', error: e);
      return [];
    }
  }

  /// Clear all configurations
  Future<void> clearAllConfigs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith(_configKeyPrefix)) {
          await prefs.remove(key);
          final configId = key.replaceFirst(_configKeyPrefix, '');
          await _secureStorage.delete(key: '$_apiKeyPrefix$configId');
        }
      }

      _logger.info('Cleared all provider configs');
    } catch (e) {
      _logger.error('Failed to clear all configs', error: e);
      rethrow;
    }
  }
}
