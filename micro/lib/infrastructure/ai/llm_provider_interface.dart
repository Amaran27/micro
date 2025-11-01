/// LLM Provider Interface
///
/// This file defines the abstract interface for LLM providers
/// without any langchain dependencies.
library;

/// MDO Provider Interface
abstract class LLMMDProvider {
  String get providerId;
  String get providerName;

  Future<void> initialize();

  List<Map<String, dynamic>> getAvailableModels();

  Map<String, dynamic>? getModel(String modelId);

  Map<String, dynamic>? getBestModel();

  Future<String> generateCompletion(String prompt,
      {Map<String, dynamic>? options});

  Stream<String> generateStreamingCompletion(String prompt,
      {Map<String, dynamic>? options});
}
