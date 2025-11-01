/// Provider Registry
///
/// Centralized registry of all supported LLM and AI providers
/// This maps provider IDs to their metadata and default configurations
library;

import 'package:flutter/material.dart';

class ProviderMetadata {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final int strengthRating; // 1-10
  final String category; // cloud, self-hosted, local
  final List<String> defaultModels;
  final String? apiKeyFormat; // Hint for API key format
  final bool requiresDeploymentId; // For Azure
  final bool requiresEndpoint;

  ProviderMetadata({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.strengthRating,
    required this.category,
    required this.defaultModels,
    this.apiKeyFormat,
    this.requiresDeploymentId = false,
    this.requiresEndpoint = false,
  });
}

class ProviderRegistry {
  static final ProviderRegistry _instance = ProviderRegistry._internal();

  factory ProviderRegistry() {
    return _instance;
  }

  ProviderRegistry._internal();

  // Cloud / API-access providers
  static final cloudProviders = <String, ProviderMetadata>{
    'openai': ProviderMetadata(
      id: 'openai',
      name: 'OpenAI',
      description: 'GPT-4, GPT-4 Turbo, GPT-3.5 Turbo',
      icon: Icons.smart_toy,
      color: const Color(0xFF10A37F),
      strengthRating: 10,
      category: 'cloud',
      defaultModels: ['gpt-4', 'gpt-4-turbo-preview', 'gpt-3.5-turbo'],
      apiKeyFormat: 'sk-...',
    ),
    'anthropic': ProviderMetadata(
      id: 'anthropic',
      name: 'Anthropic Claude',
      description: 'Claude 3 Opus, Claude 3 Sonnet, Claude 3 Haiku',
      icon: Icons.psychology,
      color: const Color(0xFFD4A373),
      strengthRating: 9,
      category: 'cloud',
      defaultModels: ['claude-3-opus', 'claude-3-sonnet', 'claude-3-haiku'],
      apiKeyFormat: 'sk-ant-...',
    ),
    'google': ProviderMetadata(
      id: 'google',
      name: 'Google AI (Gemini)',
      description: 'Gemini Pro, Gemini Ultra, PaLM',
      icon: Icons.language,
      color: const Color(0xFF4285F4),
      strengthRating: 9,
      category: 'cloud',
      defaultModels: ['gemini-pro', 'gemini-pro-vision'],
      apiKeyFormat: 'APIKEY-...',
    ),
    'azure-openai': ProviderMetadata(
      id: 'azure-openai',
      name: 'Microsoft Azure OpenAI',
      description: 'Azure-hosted OpenAI models with enterprise support',
      icon: Icons.cloud,
      color: const Color(0xFF0078D4),
      strengthRating: 10,
      category: 'cloud',
      defaultModels: ['gpt-4', 'gpt-35-turbo'],
      requiresDeploymentId: true,
      requiresEndpoint: true,
    ),
    'amazon-bedrock': ProviderMetadata(
      id: 'amazon-bedrock',
      name: 'Amazon Bedrock',
      description: 'Claude, Llama 2, Jurassic, Cohere, Mistral',
      icon: Icons.cloud_queue,
      color: const Color(0xFFFF9900),
      strengthRating: 8,
      category: 'cloud',
      defaultModels: ['claude-v1', 'llama2-13b', 'jurassic-2-mid'],
    ),
    'ibm-watsonx': ProviderMetadata(
      id: 'ibm-watsonx',
      name: 'IBM Watson.ai',
      description: 'Enterprise AI with fine-tuning capabilities',
      icon: Icons.hub,
      color: const Color(0xFF0F62FE),
      strengthRating: 8,
      category: 'cloud',
      defaultModels: ['foundation-model-1', 'granite-13b'],
    ),
    'oracle-ai': ProviderMetadata(
      id: 'oracle-ai',
      name: 'Oracle AI',
      description: 'Oracle Cloud AI services',
      icon: Icons.storage,
      color: const Color(0xFFF80000),
      strengthRating: 7,
      category: 'cloud',
      defaultModels: ['oracle-gen-ai-model'],
    ),
    'salesforce-einstein': ProviderMetadata(
      id: 'salesforce-einstein',
      name: 'Salesforce Einstein',
      description: 'AI-powered CRM and business applications',
      icon: Icons.business,
      color: const Color(0x00A1E0FF),
      strengthRating: 7,
      category: 'cloud',
      defaultModels: ['einstein-model-1'],
    ),
    'baidu-ernie': ProviderMetadata(
      id: 'baidu-ernie',
      name: 'Baidu ERNIE Bot',
      description: 'Chinese LLM with excellent CN understanding',
      icon: Icons.language,
      color: const Color(0xFFE6005C),
      strengthRating: 8,
      category: 'cloud',
      defaultModels: ['ernie-4', 'ernie-3.5'],
    ),
    'alibaba-qwen': ProviderMetadata(
      id: 'alibaba-qwen',
      name: 'Alibaba Qwen',
      description: 'Multi-language LLM from Alibaba',
      icon: Icons.language,
      color: const Color(0xFFFF6B00),
      strengthRating: 8,
      category: 'cloud',
      defaultModels: ['qwen-max', 'qwen-plus'],
    ),
    'tencent-hunyuan': ProviderMetadata(
      id: 'tencent-hunyuan',
      name: 'Tencent Hunyuan',
      description: 'Tencent Cloud AI services',
      icon: Icons.language,
      color: const Color(0xFF0052D9),
      strengthRating: 7,
      category: 'cloud',
      defaultModels: ['hunyuan-std', 'hunyuan-lite'],
    ),
    'huawei-cloud': ProviderMetadata(
      id: 'huawei-cloud',
      name: 'Huawei Cloud AI',
      description: 'Huawei Cloud services including Pangu models',
      icon: Icons.cloud,
      color: const Color(0xFFED1C24),
      strengthRating: 7,
      category: 'cloud',
      defaultModels: ['pangu-2.0', 'pangu-lite'],
    ),
    'zhipu-ai': ProviderMetadata(
      id: 'zhipu-ai',
      name: 'Zhipu AI (ChatGLM)',
      description: 'ChatGLM-4, ChatGLM-3 Chinese language models',
      icon: Icons.language,
      color: const Color(0xFF0066CC),
      strengthRating: 8,
      category: 'cloud',
      defaultModels: ['glm-4', 'glm-3-turbo'],
    ),
    'cohere': ProviderMetadata(
      id: 'cohere',
      name: 'Cohere',
      description: 'Command, Command R+, Specialized models',
      icon: Icons.format_quote,
      color: const Color(0xFF1F2937),
      strengthRating: 8,
      category: 'cloud',
      defaultModels: ['command', 'command-r', 'command-r-plus'],
      apiKeyFormat: 'cohere_...',
    ),
    'ai21-labs': ProviderMetadata(
      id: 'ai21-labs',
      name: 'AI21 Labs',
      description: 'Jurassic models for enterprise',
      icon: Icons.auto_awesome,
      color: const Color(0xFF9B59B6),
      strengthRating: 7,
      category: 'cloud',
      defaultModels: ['j2-mid', 'j2-ultra'],
    ),
    'mistral-ai': ProviderMetadata(
      id: 'mistral-ai',
      name: 'Mistral AI',
      description: 'Mistral, Mixtral, Open source quality',
      icon: Icons.auto_awesome,
      color: const Color(0xFF7B2CBF),
      strengthRating: 9,
      category: 'cloud',
      defaultModels: ['mistral-large', 'mistral-medium', 'mistral-small'],
    ),
    'stability-ai': ProviderMetadata(
      id: 'stability-ai',
      name: 'Stability AI',
      description: 'Stable Diffusion, StableLM',
      icon: Icons.image,
      color: const Color(0xFF1E88E5),
      strengthRating: 7,
      category: 'cloud',
      defaultModels: ['stable-diffusion-xl', 'stable-diffusion-3'],
    ),
    'aleph-alpha': ProviderMetadata(
      id: 'aleph-alpha',
      name: 'Aleph Alpha',
      description: 'Luminous models with explainability',
      icon: Icons.lightbulb,
      color: const Color(0xFFFFA500),
      strengthRating: 7,
      category: 'cloud',
      defaultModels: ['luminous-base', 'luminous-extended'],
    ),
    'cerebras': ProviderMetadata(
      id: 'cerebras',
      name: 'Cerebras Systems',
      description: 'Fast inference with large language models',
      icon: Icons.speed,
      color: const Color(0xFF6366F1),
      strengthRating: 8,
      category: 'cloud',
      defaultModels: ['llama2-70b'],
    ),
    'mosaicml': ProviderMetadata(
      id: 'mosaicml',
      name: 'MosaicML',
      description: 'MPT and specialized models',
      icon: Icons.blur_on,
      color: const Color(0xFF00D084),
      strengthRating: 7,
      category: 'cloud',
      defaultModels: ['mpt-30b', 'mpt-7b'],
    ),
    'together-ai': ProviderMetadata(
      id: 'together-ai',
      name: 'Together AI',
      description: 'Unified API for multiple open source models',
      icon: Icons.group,
      color: const Color(0xFF673FF7),
      strengthRating: 8,
      category: 'cloud',
      defaultModels: ['meta-llama/Llama-2-70b', 'mistralai/Mistral-7B'],
    ),
    'xai-grok': ProviderMetadata(
      id: 'xai-grok',
      name: 'xAI Grok',
      description: 'Grok models with internet access',
      icon: Icons.trending_up,
      color: const Color(0xFF000000),
      strengthRating: 8,
      category: 'cloud',
      defaultModels: ['grok-1', 'grok-1.5'],
    ),
    'inflection-ai': ProviderMetadata(
      id: 'inflection-ai',
      name: 'Inflection AI',
      description: 'Inflection-2.5 conversational model',
      icon: Icons.chat,
      color: const Color(0xFF4A90E2),
      strengthRating: 7,
      category: 'cloud',
      defaultModels: ['inflection-2.5'],
    ),
    'perplexity': ProviderMetadata(
      id: 'perplexity',
      name: 'Perplexity AI',
      description: 'Online search-enabled LLM',
      icon: Icons.search,
      color: const Color(0xFF0084FF),
      strengthRating: 8,
      category: 'cloud',
      defaultModels: ['perplexity-pro'],
    ),
    'elevenlabs': ProviderMetadata(
      id: 'elevenlabs',
      name: 'ElevenLabs',
      description: 'Voice and generative audio AI',
      icon: Icons.volume_up,
      color: const Color(0xFFFFAD32),
      strengthRating: 8,
      category: 'cloud',
      defaultModels: ['eleven-monolog-eng'],
    ),
    'runpod': ProviderMetadata(
      id: 'runpod',
      name: 'RunPod',
      description: 'Serverless GPU cloud for AI workloads',
      icon: Icons.cloud_download,
      color: const Color(0xFF621CF0),
      strengthRating: 7,
      category: 'cloud',
      defaultModels: ['custom-models'],
    ),
    'coreweave': ProviderMetadata(
      id: 'coreweave',
      name: 'CoreWeave',
      description: 'Specialized GPU cloud for AI/ML',
      icon: Icons.storage,
      color: const Color(0xFF00D9FF),
      strengthRating: 7,
      category: 'cloud',
      defaultModels: ['llm-deploy'],
    ),
    'lambda-labs': ProviderMetadata(
      id: 'lambda-labs',
      name: 'Lambda Labs',
      description: 'On-demand GPU cloud',
      icon: Icons.bolt,
      color: const Color(0xFF5E5BE8),
      strengthRating: 7,
      category: 'cloud',
      defaultModels: ['gpu-cluster'],
    ),
    'byteplus': ProviderMetadata(
      id: 'byteplus',
      name: 'BytePlus',
      description: 'Byte Dance Cloud services',
      icon: Icons.cloud,
      color: const Color(0xFF000000),
      strengthRating: 7,
      category: 'cloud',
      defaultModels: ['douyin-gpt'],
    ),
  };

  // Self-hosted / Local providers
  static final selfHostedProviders = <String, ProviderMetadata>{
    'huggingface': ProviderMetadata(
      id: 'huggingface',
      name: 'Hugging Face',
      description: 'Open source models, hosted API or local',
      icon: Icons.psychology_alt,
      color: const Color(0xFFFFD21E),
      strengthRating: 8,
      category: 'self-hosted',
      defaultModels: ['meta-llama/Llama-2-70b', 'mistralai/Mistral-7B'],
    ),
    'ollama': ProviderMetadata(
      id: 'ollama',
      name: 'Ollama',
      description: 'Run LLMs locally on your machine',
      icon: Icons.computer,
      color: const Color(0xFFFF5722),
      strengthRating: 7,
      category: 'local',
      defaultModels: ['llama2', 'mistral', 'neural-chat'],
      requiresEndpoint: true,
    ),
    'lm-studio': ProviderMetadata(
      id: 'lm-studio',
      name: 'LM Studio',
      description: 'Desktop app for local LLM inference',
      icon: Icons.laptop,
      color: const Color(0xFF673AB7),
      strengthRating: 7,
      category: 'local',
      defaultModels: ['neural-chat', 'mistral'],
      requiresEndpoint: true,
    ),
    'gpt4all': ProviderMetadata(
      id: 'gpt4all',
      name: 'GPT4All',
      description: 'Free, offline, open-source LLMs',
      icon: Icons.desktop_mac,
      color: const Color(0xFF009688),
      strengthRating: 6,
      category: 'local',
      defaultModels: ['mistral-7b', 'neural-chat-7b'],
      requiresEndpoint: true,
    ),
    'oobabooga': ProviderMetadata(
      id: 'oobabooga',
      name: 'Oobabooga / Ooba',
      description: 'Text generation web UI',
      icon: Icons.web,
      color: const Color(0xFF3F51B5),
      strengthRating: 7,
      category: 'local',
      defaultModels: ['custom-models'],
      requiresEndpoint: true,
    ),
    'vllm': ProviderMetadata(
      id: 'vllm',
      name: 'vLLM',
      description: 'High-throughput LLM inference engine',
      icon: Icons.speed,
      color: const Color(0xFF00BCD4),
      strengthRating: 8,
      category: 'local',
      defaultModels: ['llama-2-70b', 'mistral-7b'],
      requiresEndpoint: true,
    ),
    'text-generation-inference': ProviderMetadata(
      id: 'text-generation-inference',
      name: 'Text Generation Inference (TGI)',
      description: 'Hugging Face TGI for local inference',
      icon: Icons.text_fields,
      color: const Color(0xFFFFD21E),
      strengthRating: 8,
      category: 'local',
      defaultModels: ['meta-llama/Llama-2-70b', 'mistralai/Mistral-7B'],
      requiresEndpoint: true,
    ),
  };

  // Get all providers
  Map<String, ProviderMetadata> getAllProviders() {
    return {...cloudProviders, ...selfHostedProviders};
  }

  // Get provider by ID
  ProviderMetadata? getProvider(String providerId) {
    return getAllProviders()[providerId];
  }

  // Get providers by category
  List<ProviderMetadata> getProvidersByCategory(String category) {
    return getAllProviders()
        .values
        .where((p) => p.category == category)
        .toList();
  }

  // Get all categories
  List<String> getAllCategories() {
    final categories = <String>{};
    getAllProviders().values.forEach((p) {
      categories.add(p.category);
    });
    return categories.toList();
  }
}
