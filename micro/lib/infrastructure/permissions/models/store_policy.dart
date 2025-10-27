/// Store policy for permissions
enum StorePolicy {
  allowed,
  restricted,
  prohibited,
}

/// Store policy details
class StorePolicyDetails {
  final StorePolicy policy;
  final bool isAllowed;
  final bool isRestricted;
  final bool isProhibited;
  final List<String> requirements;
  final String? userGuidance;
  final Map<String, dynamic>? limits;
  final bool requiresUserInteraction;

  StorePolicyDetails({
    required this.policy,
    required this.isAllowed,
    required this.isRestricted,
    required this.isProhibited,
    required this.requirements,
    this.userGuidance,
    this.limits,
    this.requiresUserInteraction = false,
  });
}
