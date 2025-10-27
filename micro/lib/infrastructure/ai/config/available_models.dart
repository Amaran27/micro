/// Configuration for LLM providers
/// Note: Models are now fetched dynamically from provider APIs
/// This file only contains provider metadata, not model lists
class AvailableModels {
  static const List<Map<String, dynamic>> providers = [
    {
      'name': 'OpenAI',
      'type': 'commercial',
      'strength': 10,
      'description': 'Advanced GPT models',
      'apiEndpoint': 'https://api.openai.com/v1',
      'modelsEndpoint': 'https://api.openai.com/v1/models',
      'models': [], // Models fetched dynamically
    },
    {
      'name': 'Google AI',
      'type': 'commercial',
      'strength': 8,
      'description': 'Google Gemini models',
      'apiEndpoint': 'https://generativelanguage.googleapis.com/v1beta',
      'modelsEndpoint':
          'https://generativelanguage.googleapis.com/v1beta/openai/models',
      'models': [], // Models fetched dynamically
    },
    {
      'name': 'Anthropic Claude',
      'type': 'commercial',
      'strength': 9,
      'description': 'Claude family models',
      'apiEndpoint': 'https://api.anthropic.com/v1',
      'modelsEndpoint': 'https://api.anthropic.com/v1/models',
      'models': [], // Models fetched dynamically
    },
    {
      'name': 'Azure OpenAI',
      'type': 'commercial',
      'strength': 10,
      'description': 'Microsoft-hosted OpenAI models',
      'apiEndpoint': 'https://YOUR_RESOURCE.openai.azure.com',
      'modelsEndpoint': '/openai/models?api-version=2024-02-15-preview',
      'models': [], // Models fetched dynamically
    },
    {
      'name': 'Cohere',
      'type': 'commercial',
      'strength': 8,
      'description': 'Cohere AI models',
      'apiEndpoint': 'https://api.cohere.ai/v1',
      'modelsEndpoint': 'https://api.cohere.ai/v1/models',
      'models': [], // Models fetched dynamically
    },
    {
      'name': 'Mistral AI',
      'type': 'commercial',
      'strength': 8,
      'description': 'Mistral AI models',
      'apiEndpoint': 'https://api.mistral.ai/v1',
      'modelsEndpoint': 'https://api.mistral.ai/v1/models',
      'models': [], // Models fetched dynamically
    },
    {
      'name': 'Stability AI',
      'type': 'commercial',
      'strength': 7,
      'description': 'Stability AI image generation models',
      'apiEndpoint': 'https://api.stability.ai/v1',
      'modelsEndpoint': 'https://api.stability.ai/v1/engines/list',
      'models': [], // Models fetched dynamically
    },
    {
      'name': 'Ollama',
      'type': 'open-source',
      'strength': 7,
      'description': 'Local LLM models',
      'apiEndpoint': 'http://localhost:11434',
      'modelsEndpoint': '/api/tags',
      'models': [], // Models fetched dynamically
    },
    {
      'name': 'Hugging Face',
      'type': 'community',
      'strength': 6,
      'description': 'Hugging Face models and spaces',
      'apiEndpoint': 'https://api-inference.huggingface.co',
      'modelsEndpoint': 'https://huggingface.co/api/models',
      'models': [], // Models fetched dynamically
    },
  ];

  /// Get provider by ID
  static Map<String, dynamic>? getProvider(String id) {
    for (final provider in providers) {
      for (final model in provider['models']) {
        if (model['id'] == id) {
          return provider;
        }
      }
    }
    return null;
  }

  /// Get model by ID
  static Map<String, dynamic>? getModel(String providerId, String modelId) {
    final provider = getProvider(providerId);
    if (provider != null) {
      for (final model in provider['models']) {
        if (model['id'] == modelId) {
          return model;
        }
      }
    }
    return null;
  }

  /// Get all providers
  static List<Map<String, dynamic>> getAllProviders() {
    return providers;
  }
}
