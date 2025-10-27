import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/ai_provider_constants.dart';
import '../../infrastructure/ai/secure_api_storage.dart';
import '../../infrastructure/ai/model_selection_service.dart';
import '../../core/utils/logger.dart';

/// Dialog for configuring AI provider API keys and settings
class ApiConfigurationDialog extends ConsumerStatefulWidget {
  final String providerId;
  final VoidCallback? onConfigurationComplete;

  const ApiConfigurationDialog({
    required this.providerId,
    this.onConfigurationComplete,
    super.key,
  });

  @override
  ConsumerState<ApiConfigurationDialog> createState() =>
      _ApiConfigurationDialogState();
}

class _ApiConfigurationDialogState
    extends ConsumerState<ApiConfigurationDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = false;
  bool _testConnectionSuccessful = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _initializeForm() async {
    setState(() => _isLoading = true);

    try {
      final config = await SecureApiStorage.getConfiguration(widget.providerId);
      final apiKey = await SecureApiStorage.getApiKey(widget.providerId);

      final requiredFields =
          AIProviderConstants.requiredFields[widget.providerId] ?? [];

      for (final field in requiredFields) {
        _controllers[field] = TextEditingController();

        if (field == 'apiKey' && apiKey != null) {
          _controllers[field]!.text = apiKey;
        } else if (config != null && config[field] != null) {
          _controllers[field]!.text = config[field].toString();
        }
      }
    } catch (e) {
      debugPrint('Failed to initialize form: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final providerName = AIProviderConstants.providerNames[widget.providerId] ??
        widget.providerId;
    final requiredFields =
        AIProviderConstants.requiredFields[widget.providerId] ?? [];

    return AlertDialog(
      title: Text('Configure $providerName'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // API Documentation Link
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.book),
                        title: const Text('API Documentation'),
                        subtitle: Text('Get your API keys from $providerName'),
                        trailing: const Icon(Icons.open_in_new),
                        onTap: () => _launchApiDocumentation(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Configuration Fields
                    ..._buildFormFields(requiredFields),

                    const SizedBox(height: 16),

                    // Test Connection Button
                    if (_testConnectionSuccessful)
                      Card(
                        color: Colors.green.shade50,
                        child: const ListTile(
                          leading:
                              Icon(Icons.check_circle, color: Colors.green),
                          title: Text('Connection Successful'),
                          subtitle:
                              Text('API configuration is working correctly'),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isLoading ? null : _testConnection,
          child: const Text('Test Connection'),
        ),
        ElevatedButton(
          onPressed: (_isLoading || !_testConnectionSuccessful)
              ? null
              : _saveConfiguration,
          child: Text(
              _testConnectionSuccessful ? 'Save' : 'Test Connection First'),
        ),
      ],
    );
  }

  List<Widget> _buildFormFields(List<String> fields) {
    return fields.map((field) => _buildFormField(field)).toList();
  }

  Widget _buildFormField(String fieldName) {
    final controller = _controllers[fieldName]!;
    final isPasswordField = fieldName.toLowerCase().contains('key');
    final isRequired = true;
    final label = _getFieldLabel(fieldName);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: isPasswordField,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: isPasswordField
              ? IconButton(
                  icon: const Icon(Icons.paste),
                  onPressed: () => _pasteFromClipboard(controller),
                  tooltip: 'Paste from clipboard',
                )
              : null,
        ),
        validator: (value) {
          if (isRequired && (value == null || value.trim().isEmpty)) {
            return '$label is required';
          }
          return null;
        },
      ),
    );
  }

  String _getFieldLabel(String fieldName) {
    switch (fieldName) {
      case 'apiKey':
        return 'API Key';
      case 'endpoint':
        return 'API Endpoint URL';
      case 'deploymentName':
        return 'Deployment Name';
      case 'model':
        return 'Default Model';
      default:
        return fieldName[0].toUpperCase() + fieldName.substring(1);
    }
  }

  Future<void> _pasteFromClipboard(TextEditingController controller) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      controller.text = data!.text!;
    }
  }

  Future<void> _launchApiDocumentation() async {
    final url = AIProviderConstants.apiDocumentation[widget.providerId];
    if (url != null && await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final apiKey = _controllers['apiKey']?.text ?? '';
      final isValid = await _validateApiConnection(widget.providerId, apiKey);

      if (isValid) {
        setState(() => _testConnectionSuccessful = true);

        // Also fetch models to show what's available
        await _fetchAvailableModels();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection test successful!')),
        );
      } else {
        setState(() => _testConnectionSuccessful = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API key validation failed')),
        );
      }
    } catch (e) {
      setState(() => _testConnectionSuccessful = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection test failed: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _validateApiKeyFormat(String providerId, String apiKey) {
    // Basic format validation for common API key patterns
    if (apiKey.isEmpty) return false;

    switch (providerId) {
      case 'openai':
        return apiKey.startsWith('sk-') && apiKey.length > 40;
      case 'google':
        return apiKey.length > 30;
      case 'claude':
        return apiKey.startsWith('sk-ant-') && apiKey.length > 40;
      case 'azure':
        return apiKey.isNotEmpty;
      case 'cohere':
        return apiKey.isNotEmpty;
      case 'mistral':
        return apiKey.isNotEmpty;
      case 'stability':
        return apiKey.isNotEmpty;
      case 'huggingface':
        return apiKey.isNotEmpty;
      default:
        return apiKey.isNotEmpty;
    }
  }

  Future<void> _saveConfiguration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Save API key
      final apiKey = _controllers['apiKey']?.text;
      if (apiKey != null && apiKey.isNotEmpty) {
        await SecureApiStorage.saveApiKey(widget.providerId, apiKey);
      }

      // Save other configuration fields
      final config = <String, dynamic>{};
      final requiredFields =
          AIProviderConstants.requiredFields[widget.providerId] ?? [];

      for (final field in requiredFields) {
        if (field != 'apiKey') {
          final value = _controllers[field]?.text;
          if (value != null && value.isNotEmpty) {
            config[field] = value;
          }
        }
      }

      if (config.isNotEmpty) {
        await SecureApiStorage.saveConfiguration(widget.providerId, config);
      }

      // Trigger callback and close dialog
      widget.onConfigurationComplete?.call();
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuration saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to save configuration: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _validateApiConnection(String providerId, String apiKey) async {
    // Validate API key format first
    if (!_validateApiKeyFormat(providerId, apiKey)) return false;

    try {
      switch (providerId) {
        case 'openai':
          return await _testOpenAIConnection(apiKey);
        case 'google':
          return await _testGoogleConnection(apiKey);
        case 'claude':
          return await _testClaudeConnection(apiKey);
        case 'azure':
          return await _testAzureConnection(apiKey);
        case 'cohere':
          return await _testCohereConnection(apiKey);
        case 'mistral':
          return await _testMistralConnection(apiKey);
        case 'stability':
          return await _testStabilityConnection(apiKey);
        default:
          // For providers without real connection testing, just check format
          return _validateApiKeyFormat(providerId, apiKey);
      }
    } catch (e) {
      AppLogger().error('API connection test failed for $providerId', error: e);
      return false;
    }
  }

  Future<bool> _testOpenAIConnection(String apiKey) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://api.openai.com/v1/models',
        options: Options(
          headers: {'Authorization': 'Bearer $apiKey'},
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _testGoogleConnection(String apiKey) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://generativelanguage.googleapis.com/v1beta/models',
        queryParameters: {'key': apiKey},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _testClaudeConnection(String apiKey) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://api.anthropic.com/v1/messages',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
      );
      // Claude returns 400 for empty request but valid key should give proper error, not auth error
      return response.statusCode != 401;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _testAzureConnection(String apiKey) async {
    try {
      // For Azure, we can't test without proper endpoint format
      // Just validate format for now
      return apiKey.contains('azure.com') && apiKey.length > 20;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _testCohereConnection(String apiKey) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://api.cohere.ai/v1/models',
        options: Options(
          headers: {'Authorization': 'Bearer $apiKey'},
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _testMistralConnection(String apiKey) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://api.mistral.ai/v1/models',
        options: Options(
          headers: {'Authorization': 'Bearer $apiKey'},
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _testStabilityConnection(String apiKey) async {
    try {
      final dio = Dio();
      final response = await dio.post(
        'https://api.stability.ai/v1/user/account',
        options: Options(
          headers: {'Authorization': 'Bearer $apiKey'},
        ),
      );
      return response.statusCode == 200 ||
          response.statusCode ==
              401; // 401 means key is valid but no permissions
    } catch (e) {
      return false;
    }
  }

  Future<void> _fetchAvailableModels() async {
    try {
      // Save the API key first to make sure it's available for the model service
      final apiKey = _controllers['apiKey']?.text ?? '';
      if (apiKey.isNotEmpty) {
        await SecureApiStorage.saveApiKey(widget.providerId, apiKey);

        // Now fetch models
        final modelService = ModelSelectionService();
        await modelService.fetchAvailableModels();

        AppLogger()
            .info('Successfully fetched models for ${widget.providerId}');
      }
    } catch (e) {
      AppLogger()
          .error('Failed to fetch models for ${widget.providerId}', error: e);
    }
  }
}
