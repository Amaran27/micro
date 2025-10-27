/// Centralized configuration constants for all AI providers
class AIProviderConstants {
  // Provider Display Names
  static const Map<String, String> providerNames = {
    'openai': 'OpenAI',
    'google': 'Google AI',
    'claude': 'Claude/Anthropic',
    'azure': 'Azure OpenAI',
    'cohere': 'Cohere',
    'mistral': 'Mistral AI',
    'stability': 'Stability AI',
    'ollama': 'Ollama',
    'huggingface': 'Hugging Face',
  };

  // Provider API Endpoints
  static const Map<String, String> apiEndpoints = {
    'openai': 'https://api.openai.com/v1',
    'google': 'https://generativelanguage.googleapis.com/v1beta',
    'claude': 'https://api.anthropic.com/v1',
    'azure':
        'https://YOUR_RESOURCE.openai.azure.com/openai/deployments/YOUR_DEPLOYMENT',
    'cohere': 'https://api.cohere.com/v1',
    'mistral': 'https://api.mistral.ai/v1',
    'stability': 'https://api.stability.ai/v1',
    'ollama': 'http://localhost:11434',
    'huggingface': 'https://api-inference.huggingface.co',
  };

  // Models are now fetched dynamically from provider APIs
  // No more hardcoded models list
  static const Map<String, List<String>> defaultModels = {
    // Empty lists - models will be fetched dynamically
    'openai': [],
    'google': [],
    'claude': [],
    'azure': [],
    'cohere': [],
    'mistral': [],
    'stability': [],
    'ollama': [],
    'huggingface': [],
  };

  // Default Configuration Options
  // These will be dynamically adjusted based on model capabilities
  static const Map<String, Map<String, dynamic>> defaultOptions = {
    'openai': {
      'maxTokens': 1000, // Will be updated based on model context window
      'temperature': 0.7,
      'topP': 1.0,
      'frequencyPenalty': 0,
      'presencePenalty': 0,
    },
    'google': {
      'maxTokens': 1000, // Will be updated based on model context window
      'temperature': 0.7,
      'topP': 1.0,
      'topK': 40,
    },
    'claude': {
      'maxTokens': 1000, // Will be updated based on model context window
      'temperature': 0.7,
      'topP': 1.0,
      'topK': 40,
    },
    'azure': {
      'maxTokens': 1000, // Will be updated based on model context window
      'temperature': 0.7,
      'topP': 1.0,
      'apiVersion': '2024-02-01',
    },
    'cohere': {
      'maxTokens': 1000, // Will be updated based on model context window
      'temperature': 0.7,
      'topP': 1.0,
      'topK': 40,
    },
    'mistral': {
      'maxTokens': 1000, // Will be updated based on model context window
      'temperature': 0.7,
      'topP': 1.0,
    },
    'stability': {
      'width': 512,
      'height': 512,
      'steps': 20,
      'cfgScale': 7,
    },
    'ollama': {
      'maxTokens': 1000, // Will be updated based on model context window
      'temperature': 0.7,
      'topP': 1.0,
    },
    'huggingface': {
      'maxTokens': 1000, // Will be updated based on model context window
      'temperature': 0.7,
      'topP': 1.0,
    },
  };

  // API Documentation URLs
  static const Map<String, String> apiDocumentation = {
    'openai': 'https://platform.openai.com/api-keys',
    'google': 'https://aistudio.google.com/app/apikey',
    'claude': 'https://console.anthropic.com/',
    'azure': 'https://portal.azure.com/',
    'cohere': 'https://cohere.com/api',
    'mistral': 'https://console.mistral.ai/',
    'stability': 'https://platform.stability.ai/',
    'ollama': 'https://ollama.ai/',
    'huggingface': 'https://huggingface.co/settings/tokens',
  };

  // Required Configuration Fields
  static const Map<String, List<String>> requiredFields = {
    'openai': ['apiKey'],
    'google': ['apiKey'],
    'claude': ['apiKey'],
    'azure': ['apiKey', 'endpoint', 'deploymentName'],
    'cohere': ['apiKey'],
    'mistral': ['apiKey'],
    'stability': ['apiKey'],
    'ollama': ['endpoint'],
    'huggingface': ['apiKey'],
  };

  // Environment Variable Names
  static const Map<String, String> environmentVariables = {
    'openai': 'OPENAI_API_KEY',
    'google': 'GOOGLE_AI_API_KEY',
    'claude': 'ANTHROPIC_API_KEY',
    'azure': 'AZURE_OPENAI_API_KEY',
    'cohere': 'COHERE_API_KEY',
    'mistral': 'MISTRAL_API_KEY',
    'stability': 'STABILITY_API_KEY',
    'ollama': 'OLLAMA_ENDPOINT',
    'huggingface': 'HUGGINGFACE_API_KEY',
  };
}
