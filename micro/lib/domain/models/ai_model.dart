import 'package:equatable/equatable.dart';

class AIModel extends Equatable {
  final String provider;
  final String modelId;
  final String displayName;
  final String? description;
  final Map<String, dynamic>? metadata;

  const AIModel({
    required this.provider,
    required this.modelId,
    required this.displayName,
    this.description,
    this.metadata,
  });

  factory AIModel.fromJson(Map<String, dynamic> json) {
    return AIModel(
      provider: json['provider'] as String,
      modelId: json['modelId'] as String,
      displayName: json['displayName'] as String,
      description: json['description'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'modelId': modelId,
      'displayName': displayName,
      'description': description,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props =>
      [provider, modelId, displayName, description, metadata];

  @override
  String toString() {
    return 'AIModel(provider: $provider, modelId: $modelId, displayName: $displayName)';
  }
}
