import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro/infrastructure/ai/swarm_settings_service.dart';

final swarmSettingsServiceProvider = Provider<SwarmSettingsService>((ref) {
  return SwarmSettingsService();
});

/// Loads the current max specialists value from persistence.
final maxSpecialistsProvider = FutureProvider<int>((ref) async {
  final service = ref.read(swarmSettingsServiceProvider);
  return service.getMaxSpecialists();
});
