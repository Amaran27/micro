import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'model_selection_service.dart';

ModelSelectionService? _sharedService;

/// Provider for ModelSelectionService (singleton pattern)
final modelSelectionServiceProvider = Provider<ModelSelectionService>((ref) {
  // Use the singleton instance
  _sharedService ??= ModelSelectionService.instance;
  // Initialize the service if not already initialized
  final future = _sharedService!.initialize();
  return _sharedService!;
});

/// Provider for initialized ModelSelectionService
final initializedModelSelectionServiceProvider = FutureProvider<ModelSelectionService>((ref) async {
  final service = ref.watch(modelSelectionServiceProvider);
  await service.initialize();
  return service;
});