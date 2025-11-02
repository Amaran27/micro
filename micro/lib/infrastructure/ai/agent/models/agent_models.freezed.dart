// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'agent_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlanStep {
  String get id;
  String get description;
  String get action;
  Map<String, dynamic> get parameters;
  List<String> get requiredTools;
  int get estimatedDurationSeconds;
  ExecutionStatus get status;
  List<String> get dependencies;
  int? get sequenceNumber;
  String? get toolName;

  /// Create a copy of PlanStep
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PlanStepCopyWith<PlanStep> get copyWith =>
      _$PlanStepCopyWithImpl<PlanStep>(this as PlanStep, _$identity);

  /// Serializes this PlanStep to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PlanStep &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.action, action) || other.action == action) &&
            const DeepCollectionEquality()
                .equals(other.parameters, parameters) &&
            const DeepCollectionEquality()
                .equals(other.requiredTools, requiredTools) &&
            (identical(
                    other.estimatedDurationSeconds, estimatedDurationSeconds) ||
                other.estimatedDurationSeconds == estimatedDurationSeconds) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality()
                .equals(other.dependencies, dependencies) &&
            (identical(other.sequenceNumber, sequenceNumber) ||
                other.sequenceNumber == sequenceNumber) &&
            (identical(other.toolName, toolName) ||
                other.toolName == toolName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      description,
      action,
      const DeepCollectionEquality().hash(parameters),
      const DeepCollectionEquality().hash(requiredTools),
      estimatedDurationSeconds,
      status,
      const DeepCollectionEquality().hash(dependencies),
      sequenceNumber,
      toolName);

  @override
  String toString() {
    return 'PlanStep(id: $id, description: $description, action: $action, parameters: $parameters, requiredTools: $requiredTools, estimatedDurationSeconds: $estimatedDurationSeconds, status: $status, dependencies: $dependencies, sequenceNumber: $sequenceNumber, toolName: $toolName)';
  }
}

/// @nodoc
abstract mixin class $PlanStepCopyWith<$Res> {
  factory $PlanStepCopyWith(PlanStep value, $Res Function(PlanStep) _then) =
      _$PlanStepCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String description,
      String action,
      Map<String, dynamic> parameters,
      List<String> requiredTools,
      int estimatedDurationSeconds,
      ExecutionStatus status,
      List<String> dependencies,
      int? sequenceNumber,
      String? toolName});
}

/// @nodoc
class _$PlanStepCopyWithImpl<$Res> implements $PlanStepCopyWith<$Res> {
  _$PlanStepCopyWithImpl(this._self, this._then);

  final PlanStep _self;
  final $Res Function(PlanStep) _then;

  /// Create a copy of PlanStep
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? description = null,
    Object? action = null,
    Object? parameters = null,
    Object? requiredTools = null,
    Object? estimatedDurationSeconds = null,
    Object? status = null,
    Object? dependencies = null,
    Object? sequenceNumber = freezed,
    Object? toolName = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      action: null == action
          ? _self.action
          : action // ignore: cast_nullable_to_non_nullable
              as String,
      parameters: null == parameters
          ? _self.parameters
          : parameters // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      requiredTools: null == requiredTools
          ? _self.requiredTools
          : requiredTools // ignore: cast_nullable_to_non_nullable
              as List<String>,
      estimatedDurationSeconds: null == estimatedDurationSeconds
          ? _self.estimatedDurationSeconds
          : estimatedDurationSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as ExecutionStatus,
      dependencies: null == dependencies
          ? _self.dependencies
          : dependencies // ignore: cast_nullable_to_non_nullable
              as List<String>,
      sequenceNumber: freezed == sequenceNumber
          ? _self.sequenceNumber
          : sequenceNumber // ignore: cast_nullable_to_non_nullable
              as int?,
      toolName: freezed == toolName
          ? _self.toolName
          : toolName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [PlanStep].
extension PlanStepPatterns on PlanStep {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_PlanStep value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PlanStep() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_PlanStep value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlanStep():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_PlanStep value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlanStep() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String id,
            String description,
            String action,
            Map<String, dynamic> parameters,
            List<String> requiredTools,
            int estimatedDurationSeconds,
            ExecutionStatus status,
            List<String> dependencies,
            int? sequenceNumber,
            String? toolName)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PlanStep() when $default != null:
        return $default(
            _that.id,
            _that.description,
            _that.action,
            _that.parameters,
            _that.requiredTools,
            _that.estimatedDurationSeconds,
            _that.status,
            _that.dependencies,
            _that.sequenceNumber,
            _that.toolName);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String id,
            String description,
            String action,
            Map<String, dynamic> parameters,
            List<String> requiredTools,
            int estimatedDurationSeconds,
            ExecutionStatus status,
            List<String> dependencies,
            int? sequenceNumber,
            String? toolName)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlanStep():
        return $default(
            _that.id,
            _that.description,
            _that.action,
            _that.parameters,
            _that.requiredTools,
            _that.estimatedDurationSeconds,
            _that.status,
            _that.dependencies,
            _that.sequenceNumber,
            _that.toolName);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String id,
            String description,
            String action,
            Map<String, dynamic> parameters,
            List<String> requiredTools,
            int estimatedDurationSeconds,
            ExecutionStatus status,
            List<String> dependencies,
            int? sequenceNumber,
            String? toolName)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlanStep() when $default != null:
        return $default(
            _that.id,
            _that.description,
            _that.action,
            _that.parameters,
            _that.requiredTools,
            _that.estimatedDurationSeconds,
            _that.status,
            _that.dependencies,
            _that.sequenceNumber,
            _that.toolName);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _PlanStep implements PlanStep {
  const _PlanStep(
      {required this.id,
      required this.description,
      required this.action,
      required final Map<String, dynamic> parameters,
      required final List<String> requiredTools,
      required this.estimatedDurationSeconds,
      this.status = ExecutionStatus.pending,
      final List<String> dependencies = const [],
      this.sequenceNumber,
      this.toolName})
      : _parameters = parameters,
        _requiredTools = requiredTools,
        _dependencies = dependencies;
  factory _PlanStep.fromJson(Map<String, dynamic> json) =>
      _$PlanStepFromJson(json);

  @override
  final String id;
  @override
  final String description;
  @override
  final String action;
  final Map<String, dynamic> _parameters;
  @override
  Map<String, dynamic> get parameters {
    if (_parameters is EqualUnmodifiableMapView) return _parameters;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_parameters);
  }

  final List<String> _requiredTools;
  @override
  List<String> get requiredTools {
    if (_requiredTools is EqualUnmodifiableListView) return _requiredTools;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_requiredTools);
  }

  @override
  final int estimatedDurationSeconds;
  @override
  @JsonKey()
  final ExecutionStatus status;
  final List<String> _dependencies;
  @override
  @JsonKey()
  List<String> get dependencies {
    if (_dependencies is EqualUnmodifiableListView) return _dependencies;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_dependencies);
  }

  @override
  final int? sequenceNumber;
  @override
  final String? toolName;

  /// Create a copy of PlanStep
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PlanStepCopyWith<_PlanStep> get copyWith =>
      __$PlanStepCopyWithImpl<_PlanStep>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PlanStepToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PlanStep &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.action, action) || other.action == action) &&
            const DeepCollectionEquality()
                .equals(other._parameters, _parameters) &&
            const DeepCollectionEquality()
                .equals(other._requiredTools, _requiredTools) &&
            (identical(
                    other.estimatedDurationSeconds, estimatedDurationSeconds) ||
                other.estimatedDurationSeconds == estimatedDurationSeconds) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality()
                .equals(other._dependencies, _dependencies) &&
            (identical(other.sequenceNumber, sequenceNumber) ||
                other.sequenceNumber == sequenceNumber) &&
            (identical(other.toolName, toolName) ||
                other.toolName == toolName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      description,
      action,
      const DeepCollectionEquality().hash(_parameters),
      const DeepCollectionEquality().hash(_requiredTools),
      estimatedDurationSeconds,
      status,
      const DeepCollectionEquality().hash(_dependencies),
      sequenceNumber,
      toolName);

  @override
  String toString() {
    return 'PlanStep(id: $id, description: $description, action: $action, parameters: $parameters, requiredTools: $requiredTools, estimatedDurationSeconds: $estimatedDurationSeconds, status: $status, dependencies: $dependencies, sequenceNumber: $sequenceNumber, toolName: $toolName)';
  }
}

/// @nodoc
abstract mixin class _$PlanStepCopyWith<$Res>
    implements $PlanStepCopyWith<$Res> {
  factory _$PlanStepCopyWith(_PlanStep value, $Res Function(_PlanStep) _then) =
      __$PlanStepCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String description,
      String action,
      Map<String, dynamic> parameters,
      List<String> requiredTools,
      int estimatedDurationSeconds,
      ExecutionStatus status,
      List<String> dependencies,
      int? sequenceNumber,
      String? toolName});
}

/// @nodoc
class __$PlanStepCopyWithImpl<$Res> implements _$PlanStepCopyWith<$Res> {
  __$PlanStepCopyWithImpl(this._self, this._then);

  final _PlanStep _self;
  final $Res Function(_PlanStep) _then;

  /// Create a copy of PlanStep
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? description = null,
    Object? action = null,
    Object? parameters = null,
    Object? requiredTools = null,
    Object? estimatedDurationSeconds = null,
    Object? status = null,
    Object? dependencies = null,
    Object? sequenceNumber = freezed,
    Object? toolName = freezed,
  }) {
    return _then(_PlanStep(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      action: null == action
          ? _self.action
          : action // ignore: cast_nullable_to_non_nullable
              as String,
      parameters: null == parameters
          ? _self._parameters
          : parameters // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      requiredTools: null == requiredTools
          ? _self._requiredTools
          : requiredTools // ignore: cast_nullable_to_non_nullable
              as List<String>,
      estimatedDurationSeconds: null == estimatedDurationSeconds
          ? _self.estimatedDurationSeconds
          : estimatedDurationSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as ExecutionStatus,
      dependencies: null == dependencies
          ? _self._dependencies
          : dependencies // ignore: cast_nullable_to_non_nullable
              as List<String>,
      sequenceNumber: freezed == sequenceNumber
          ? _self.sequenceNumber
          : sequenceNumber // ignore: cast_nullable_to_non_nullable
              as int?,
      toolName: freezed == toolName
          ? _self.toolName
          : toolName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
mixin _$StepResult {
  String get stepId;
  ExecutionStatus get status;
  dynamic get result;
  String? get error;
  DateTime? get executedAt;
  int? get durationMilliseconds;
  Map<String, dynamic> get metadata;

  /// Create a copy of StepResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $StepResultCopyWith<StepResult> get copyWith =>
      _$StepResultCopyWithImpl<StepResult>(this as StepResult, _$identity);

  /// Serializes this StepResult to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is StepResult &&
            (identical(other.stepId, stepId) || other.stepId == stepId) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(other.result, result) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.executedAt, executedAt) ||
                other.executedAt == executedAt) &&
            (identical(other.durationMilliseconds, durationMilliseconds) ||
                other.durationMilliseconds == durationMilliseconds) &&
            const DeepCollectionEquality().equals(other.metadata, metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      stepId,
      status,
      const DeepCollectionEquality().hash(result),
      error,
      executedAt,
      durationMilliseconds,
      const DeepCollectionEquality().hash(metadata));

  @override
  String toString() {
    return 'StepResult(stepId: $stepId, status: $status, result: $result, error: $error, executedAt: $executedAt, durationMilliseconds: $durationMilliseconds, metadata: $metadata)';
  }
}

/// @nodoc
abstract mixin class $StepResultCopyWith<$Res> {
  factory $StepResultCopyWith(
          StepResult value, $Res Function(StepResult) _then) =
      _$StepResultCopyWithImpl;
  @useResult
  $Res call(
      {String stepId,
      ExecutionStatus status,
      dynamic result,
      String? error,
      DateTime? executedAt,
      int? durationMilliseconds,
      Map<String, dynamic> metadata});
}

/// @nodoc
class _$StepResultCopyWithImpl<$Res> implements $StepResultCopyWith<$Res> {
  _$StepResultCopyWithImpl(this._self, this._then);

  final StepResult _self;
  final $Res Function(StepResult) _then;

  /// Create a copy of StepResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stepId = null,
    Object? status = null,
    Object? result = freezed,
    Object? error = freezed,
    Object? executedAt = freezed,
    Object? durationMilliseconds = freezed,
    Object? metadata = null,
  }) {
    return _then(_self.copyWith(
      stepId: null == stepId
          ? _self.stepId
          : stepId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as ExecutionStatus,
      result: freezed == result
          ? _self.result
          : result // ignore: cast_nullable_to_non_nullable
              as dynamic,
      error: freezed == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      executedAt: freezed == executedAt
          ? _self.executedAt
          : executedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      durationMilliseconds: freezed == durationMilliseconds
          ? _self.durationMilliseconds
          : durationMilliseconds // ignore: cast_nullable_to_non_nullable
              as int?,
      metadata: null == metadata
          ? _self.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// Adds pattern-matching-related methods to [StepResult].
extension StepResultPatterns on StepResult {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_StepResult value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _StepResult() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_StepResult value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _StepResult():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_StepResult value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _StepResult() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String stepId,
            ExecutionStatus status,
            dynamic result,
            String? error,
            DateTime? executedAt,
            int? durationMilliseconds,
            Map<String, dynamic> metadata)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _StepResult() when $default != null:
        return $default(_that.stepId, _that.status, _that.result, _that.error,
            _that.executedAt, _that.durationMilliseconds, _that.metadata);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String stepId,
            ExecutionStatus status,
            dynamic result,
            String? error,
            DateTime? executedAt,
            int? durationMilliseconds,
            Map<String, dynamic> metadata)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _StepResult():
        return $default(_that.stepId, _that.status, _that.result, _that.error,
            _that.executedAt, _that.durationMilliseconds, _that.metadata);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String stepId,
            ExecutionStatus status,
            dynamic result,
            String? error,
            DateTime? executedAt,
            int? durationMilliseconds,
            Map<String, dynamic> metadata)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _StepResult() when $default != null:
        return $default(_that.stepId, _that.status, _that.result, _that.error,
            _that.executedAt, _that.durationMilliseconds, _that.metadata);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _StepResult implements StepResult {
  const _StepResult(
      {required this.stepId,
      required this.status,
      required this.result,
      this.error,
      this.executedAt,
      this.durationMilliseconds,
      final Map<String, dynamic> metadata = const {}})
      : _metadata = metadata;
  factory _StepResult.fromJson(Map<String, dynamic> json) =>
      _$StepResultFromJson(json);

  @override
  final String stepId;
  @override
  final ExecutionStatus status;
  @override
  final dynamic result;
  @override
  final String? error;
  @override
  final DateTime? executedAt;
  @override
  final int? durationMilliseconds;
  final Map<String, dynamic> _metadata;
  @override
  @JsonKey()
  Map<String, dynamic> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  /// Create a copy of StepResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$StepResultCopyWith<_StepResult> get copyWith =>
      __$StepResultCopyWithImpl<_StepResult>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$StepResultToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _StepResult &&
            (identical(other.stepId, stepId) || other.stepId == stepId) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality().equals(other.result, result) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.executedAt, executedAt) ||
                other.executedAt == executedAt) &&
            (identical(other.durationMilliseconds, durationMilliseconds) ||
                other.durationMilliseconds == durationMilliseconds) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      stepId,
      status,
      const DeepCollectionEquality().hash(result),
      error,
      executedAt,
      durationMilliseconds,
      const DeepCollectionEquality().hash(_metadata));

  @override
  String toString() {
    return 'StepResult(stepId: $stepId, status: $status, result: $result, error: $error, executedAt: $executedAt, durationMilliseconds: $durationMilliseconds, metadata: $metadata)';
  }
}

/// @nodoc
abstract mixin class _$StepResultCopyWith<$Res>
    implements $StepResultCopyWith<$Res> {
  factory _$StepResultCopyWith(
          _StepResult value, $Res Function(_StepResult) _then) =
      __$StepResultCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String stepId,
      ExecutionStatus status,
      dynamic result,
      String? error,
      DateTime? executedAt,
      int? durationMilliseconds,
      Map<String, dynamic> metadata});
}

/// @nodoc
class __$StepResultCopyWithImpl<$Res> implements _$StepResultCopyWith<$Res> {
  __$StepResultCopyWithImpl(this._self, this._then);

  final _StepResult _self;
  final $Res Function(_StepResult) _then;

  /// Create a copy of StepResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? stepId = null,
    Object? status = null,
    Object? result = freezed,
    Object? error = freezed,
    Object? executedAt = freezed,
    Object? durationMilliseconds = freezed,
    Object? metadata = null,
  }) {
    return _then(_StepResult(
      stepId: null == stepId
          ? _self.stepId
          : stepId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as ExecutionStatus,
      result: freezed == result
          ? _self.result
          : result // ignore: cast_nullable_to_non_nullable
              as dynamic,
      error: freezed == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      executedAt: freezed == executedAt
          ? _self.executedAt
          : executedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      durationMilliseconds: freezed == durationMilliseconds
          ? _self.durationMilliseconds
          : durationMilliseconds // ignore: cast_nullable_to_non_nullable
              as int?,
      metadata: null == metadata
          ? _self._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
mixin _$Verification {
  String get stepId;
  VerificationResult get result;
  String get reasoning;
  List<String> get issues;
  DateTime? get verifiedAt;
  Map<String, dynamic> get evidence;

  /// Create a copy of Verification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $VerificationCopyWith<Verification> get copyWith =>
      _$VerificationCopyWithImpl<Verification>(
          this as Verification, _$identity);

  /// Serializes this Verification to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Verification &&
            (identical(other.stepId, stepId) || other.stepId == stepId) &&
            (identical(other.result, result) || other.result == result) &&
            (identical(other.reasoning, reasoning) ||
                other.reasoning == reasoning) &&
            const DeepCollectionEquality().equals(other.issues, issues) &&
            (identical(other.verifiedAt, verifiedAt) ||
                other.verifiedAt == verifiedAt) &&
            const DeepCollectionEquality().equals(other.evidence, evidence));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      stepId,
      result,
      reasoning,
      const DeepCollectionEquality().hash(issues),
      verifiedAt,
      const DeepCollectionEquality().hash(evidence));

  @override
  String toString() {
    return 'Verification(stepId: $stepId, result: $result, reasoning: $reasoning, issues: $issues, verifiedAt: $verifiedAt, evidence: $evidence)';
  }
}

/// @nodoc
abstract mixin class $VerificationCopyWith<$Res> {
  factory $VerificationCopyWith(
          Verification value, $Res Function(Verification) _then) =
      _$VerificationCopyWithImpl;
  @useResult
  $Res call(
      {String stepId,
      VerificationResult result,
      String reasoning,
      List<String> issues,
      DateTime? verifiedAt,
      Map<String, dynamic> evidence});
}

/// @nodoc
class _$VerificationCopyWithImpl<$Res> implements $VerificationCopyWith<$Res> {
  _$VerificationCopyWithImpl(this._self, this._then);

  final Verification _self;
  final $Res Function(Verification) _then;

  /// Create a copy of Verification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stepId = null,
    Object? result = null,
    Object? reasoning = null,
    Object? issues = null,
    Object? verifiedAt = freezed,
    Object? evidence = null,
  }) {
    return _then(_self.copyWith(
      stepId: null == stepId
          ? _self.stepId
          : stepId // ignore: cast_nullable_to_non_nullable
              as String,
      result: null == result
          ? _self.result
          : result // ignore: cast_nullable_to_non_nullable
              as VerificationResult,
      reasoning: null == reasoning
          ? _self.reasoning
          : reasoning // ignore: cast_nullable_to_non_nullable
              as String,
      issues: null == issues
          ? _self.issues
          : issues // ignore: cast_nullable_to_non_nullable
              as List<String>,
      verifiedAt: freezed == verifiedAt
          ? _self.verifiedAt
          : verifiedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      evidence: null == evidence
          ? _self.evidence
          : evidence // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// Adds pattern-matching-related methods to [Verification].
extension VerificationPatterns on Verification {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_Verification value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Verification() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_Verification value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Verification():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_Verification value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Verification() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String stepId,
            VerificationResult result,
            String reasoning,
            List<String> issues,
            DateTime? verifiedAt,
            Map<String, dynamic> evidence)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Verification() when $default != null:
        return $default(_that.stepId, _that.result, _that.reasoning,
            _that.issues, _that.verifiedAt, _that.evidence);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String stepId,
            VerificationResult result,
            String reasoning,
            List<String> issues,
            DateTime? verifiedAt,
            Map<String, dynamic> evidence)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Verification():
        return $default(_that.stepId, _that.result, _that.reasoning,
            _that.issues, _that.verifiedAt, _that.evidence);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String stepId,
            VerificationResult result,
            String reasoning,
            List<String> issues,
            DateTime? verifiedAt,
            Map<String, dynamic> evidence)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Verification() when $default != null:
        return $default(_that.stepId, _that.result, _that.reasoning,
            _that.issues, _that.verifiedAt, _that.evidence);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Verification implements Verification {
  const _Verification(
      {required this.stepId,
      required this.result,
      required this.reasoning,
      final List<String> issues = const [],
      this.verifiedAt,
      final Map<String, dynamic> evidence = const {}})
      : _issues = issues,
        _evidence = evidence;
  factory _Verification.fromJson(Map<String, dynamic> json) =>
      _$VerificationFromJson(json);

  @override
  final String stepId;
  @override
  final VerificationResult result;
  @override
  final String reasoning;
  final List<String> _issues;
  @override
  @JsonKey()
  List<String> get issues {
    if (_issues is EqualUnmodifiableListView) return _issues;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_issues);
  }

  @override
  final DateTime? verifiedAt;
  final Map<String, dynamic> _evidence;
  @override
  @JsonKey()
  Map<String, dynamic> get evidence {
    if (_evidence is EqualUnmodifiableMapView) return _evidence;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_evidence);
  }

  /// Create a copy of Verification
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$VerificationCopyWith<_Verification> get copyWith =>
      __$VerificationCopyWithImpl<_Verification>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$VerificationToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Verification &&
            (identical(other.stepId, stepId) || other.stepId == stepId) &&
            (identical(other.result, result) || other.result == result) &&
            (identical(other.reasoning, reasoning) ||
                other.reasoning == reasoning) &&
            const DeepCollectionEquality().equals(other._issues, _issues) &&
            (identical(other.verifiedAt, verifiedAt) ||
                other.verifiedAt == verifiedAt) &&
            const DeepCollectionEquality().equals(other._evidence, _evidence));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      stepId,
      result,
      reasoning,
      const DeepCollectionEquality().hash(_issues),
      verifiedAt,
      const DeepCollectionEquality().hash(_evidence));

  @override
  String toString() {
    return 'Verification(stepId: $stepId, result: $result, reasoning: $reasoning, issues: $issues, verifiedAt: $verifiedAt, evidence: $evidence)';
  }
}

/// @nodoc
abstract mixin class _$VerificationCopyWith<$Res>
    implements $VerificationCopyWith<$Res> {
  factory _$VerificationCopyWith(
          _Verification value, $Res Function(_Verification) _then) =
      __$VerificationCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String stepId,
      VerificationResult result,
      String reasoning,
      List<String> issues,
      DateTime? verifiedAt,
      Map<String, dynamic> evidence});
}

/// @nodoc
class __$VerificationCopyWithImpl<$Res>
    implements _$VerificationCopyWith<$Res> {
  __$VerificationCopyWithImpl(this._self, this._then);

  final _Verification _self;
  final $Res Function(_Verification) _then;

  /// Create a copy of Verification
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? stepId = null,
    Object? result = null,
    Object? reasoning = null,
    Object? issues = null,
    Object? verifiedAt = freezed,
    Object? evidence = null,
  }) {
    return _then(_Verification(
      stepId: null == stepId
          ? _self.stepId
          : stepId // ignore: cast_nullable_to_non_nullable
              as String,
      result: null == result
          ? _self.result
          : result // ignore: cast_nullable_to_non_nullable
              as VerificationResult,
      reasoning: null == reasoning
          ? _self.reasoning
          : reasoning // ignore: cast_nullable_to_non_nullable
              as String,
      issues: null == issues
          ? _self._issues
          : issues // ignore: cast_nullable_to_non_nullable
              as List<String>,
      verifiedAt: freezed == verifiedAt
          ? _self.verifiedAt
          : verifiedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      evidence: null == evidence
          ? _self._evidence
          : evidence // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
mixin _$AgentPlan {
  String get id;
  String get taskDescription;
  List<PlanStep> get steps;
  ExecutionStatus get status;
  DateTime? get createdAt;
  DateTime? get startedAt;
  DateTime? get completedAt;
  List<Verification> get verifications;
  List<StepResult> get results;
  int get replannedCount;
  String? get finalReasoning;

  /// Create a copy of AgentPlan
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AgentPlanCopyWith<AgentPlan> get copyWith =>
      _$AgentPlanCopyWithImpl<AgentPlan>(this as AgentPlan, _$identity);

  /// Serializes this AgentPlan to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AgentPlan &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.taskDescription, taskDescription) ||
                other.taskDescription == taskDescription) &&
            const DeepCollectionEquality().equals(other.steps, steps) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            const DeepCollectionEquality()
                .equals(other.verifications, verifications) &&
            const DeepCollectionEquality().equals(other.results, results) &&
            (identical(other.replannedCount, replannedCount) ||
                other.replannedCount == replannedCount) &&
            (identical(other.finalReasoning, finalReasoning) ||
                other.finalReasoning == finalReasoning));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      taskDescription,
      const DeepCollectionEquality().hash(steps),
      status,
      createdAt,
      startedAt,
      completedAt,
      const DeepCollectionEquality().hash(verifications),
      const DeepCollectionEquality().hash(results),
      replannedCount,
      finalReasoning);

  @override
  String toString() {
    return 'AgentPlan(id: $id, taskDescription: $taskDescription, steps: $steps, status: $status, createdAt: $createdAt, startedAt: $startedAt, completedAt: $completedAt, verifications: $verifications, results: $results, replannedCount: $replannedCount, finalReasoning: $finalReasoning)';
  }
}

/// @nodoc
abstract mixin class $AgentPlanCopyWith<$Res> {
  factory $AgentPlanCopyWith(AgentPlan value, $Res Function(AgentPlan) _then) =
      _$AgentPlanCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String taskDescription,
      List<PlanStep> steps,
      ExecutionStatus status,
      DateTime? createdAt,
      DateTime? startedAt,
      DateTime? completedAt,
      List<Verification> verifications,
      List<StepResult> results,
      int replannedCount,
      String? finalReasoning});
}

/// @nodoc
class _$AgentPlanCopyWithImpl<$Res> implements $AgentPlanCopyWith<$Res> {
  _$AgentPlanCopyWithImpl(this._self, this._then);

  final AgentPlan _self;
  final $Res Function(AgentPlan) _then;

  /// Create a copy of AgentPlan
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? taskDescription = null,
    Object? steps = null,
    Object? status = null,
    Object? createdAt = freezed,
    Object? startedAt = freezed,
    Object? completedAt = freezed,
    Object? verifications = null,
    Object? results = null,
    Object? replannedCount = null,
    Object? finalReasoning = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      taskDescription: null == taskDescription
          ? _self.taskDescription
          : taskDescription // ignore: cast_nullable_to_non_nullable
              as String,
      steps: null == steps
          ? _self.steps
          : steps // ignore: cast_nullable_to_non_nullable
              as List<PlanStep>,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as ExecutionStatus,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      startedAt: freezed == startedAt
          ? _self.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      completedAt: freezed == completedAt
          ? _self.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      verifications: null == verifications
          ? _self.verifications
          : verifications // ignore: cast_nullable_to_non_nullable
              as List<Verification>,
      results: null == results
          ? _self.results
          : results // ignore: cast_nullable_to_non_nullable
              as List<StepResult>,
      replannedCount: null == replannedCount
          ? _self.replannedCount
          : replannedCount // ignore: cast_nullable_to_non_nullable
              as int,
      finalReasoning: freezed == finalReasoning
          ? _self.finalReasoning
          : finalReasoning // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [AgentPlan].
extension AgentPlanPatterns on AgentPlan {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_AgentPlan value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AgentPlan() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_AgentPlan value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AgentPlan():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_AgentPlan value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AgentPlan() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String id,
            String taskDescription,
            List<PlanStep> steps,
            ExecutionStatus status,
            DateTime? createdAt,
            DateTime? startedAt,
            DateTime? completedAt,
            List<Verification> verifications,
            List<StepResult> results,
            int replannedCount,
            String? finalReasoning)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AgentPlan() when $default != null:
        return $default(
            _that.id,
            _that.taskDescription,
            _that.steps,
            _that.status,
            _that.createdAt,
            _that.startedAt,
            _that.completedAt,
            _that.verifications,
            _that.results,
            _that.replannedCount,
            _that.finalReasoning);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String id,
            String taskDescription,
            List<PlanStep> steps,
            ExecutionStatus status,
            DateTime? createdAt,
            DateTime? startedAt,
            DateTime? completedAt,
            List<Verification> verifications,
            List<StepResult> results,
            int replannedCount,
            String? finalReasoning)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AgentPlan():
        return $default(
            _that.id,
            _that.taskDescription,
            _that.steps,
            _that.status,
            _that.createdAt,
            _that.startedAt,
            _that.completedAt,
            _that.verifications,
            _that.results,
            _that.replannedCount,
            _that.finalReasoning);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String id,
            String taskDescription,
            List<PlanStep> steps,
            ExecutionStatus status,
            DateTime? createdAt,
            DateTime? startedAt,
            DateTime? completedAt,
            List<Verification> verifications,
            List<StepResult> results,
            int replannedCount,
            String? finalReasoning)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AgentPlan() when $default != null:
        return $default(
            _that.id,
            _that.taskDescription,
            _that.steps,
            _that.status,
            _that.createdAt,
            _that.startedAt,
            _that.completedAt,
            _that.verifications,
            _that.results,
            _that.replannedCount,
            _that.finalReasoning);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _AgentPlan implements AgentPlan {
  const _AgentPlan(
      {required this.id,
      required this.taskDescription,
      required final List<PlanStep> steps,
      this.status = ExecutionStatus.pending,
      this.createdAt,
      this.startedAt,
      this.completedAt,
      final List<Verification> verifications = const [],
      final List<StepResult> results = const [],
      this.replannedCount = 0,
      this.finalReasoning})
      : _steps = steps,
        _verifications = verifications,
        _results = results;
  factory _AgentPlan.fromJson(Map<String, dynamic> json) =>
      _$AgentPlanFromJson(json);

  @override
  final String id;
  @override
  final String taskDescription;
  final List<PlanStep> _steps;
  @override
  List<PlanStep> get steps {
    if (_steps is EqualUnmodifiableListView) return _steps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_steps);
  }

  @override
  @JsonKey()
  final ExecutionStatus status;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? startedAt;
  @override
  final DateTime? completedAt;
  final List<Verification> _verifications;
  @override
  @JsonKey()
  List<Verification> get verifications {
    if (_verifications is EqualUnmodifiableListView) return _verifications;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_verifications);
  }

  final List<StepResult> _results;
  @override
  @JsonKey()
  List<StepResult> get results {
    if (_results is EqualUnmodifiableListView) return _results;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_results);
  }

  @override
  @JsonKey()
  final int replannedCount;
  @override
  final String? finalReasoning;

  /// Create a copy of AgentPlan
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AgentPlanCopyWith<_AgentPlan> get copyWith =>
      __$AgentPlanCopyWithImpl<_AgentPlan>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$AgentPlanToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AgentPlan &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.taskDescription, taskDescription) ||
                other.taskDescription == taskDescription) &&
            const DeepCollectionEquality().equals(other._steps, _steps) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            const DeepCollectionEquality()
                .equals(other._verifications, _verifications) &&
            const DeepCollectionEquality().equals(other._results, _results) &&
            (identical(other.replannedCount, replannedCount) ||
                other.replannedCount == replannedCount) &&
            (identical(other.finalReasoning, finalReasoning) ||
                other.finalReasoning == finalReasoning));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      taskDescription,
      const DeepCollectionEquality().hash(_steps),
      status,
      createdAt,
      startedAt,
      completedAt,
      const DeepCollectionEquality().hash(_verifications),
      const DeepCollectionEquality().hash(_results),
      replannedCount,
      finalReasoning);

  @override
  String toString() {
    return 'AgentPlan(id: $id, taskDescription: $taskDescription, steps: $steps, status: $status, createdAt: $createdAt, startedAt: $startedAt, completedAt: $completedAt, verifications: $verifications, results: $results, replannedCount: $replannedCount, finalReasoning: $finalReasoning)';
  }
}

/// @nodoc
abstract mixin class _$AgentPlanCopyWith<$Res>
    implements $AgentPlanCopyWith<$Res> {
  factory _$AgentPlanCopyWith(
          _AgentPlan value, $Res Function(_AgentPlan) _then) =
      __$AgentPlanCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String taskDescription,
      List<PlanStep> steps,
      ExecutionStatus status,
      DateTime? createdAt,
      DateTime? startedAt,
      DateTime? completedAt,
      List<Verification> verifications,
      List<StepResult> results,
      int replannedCount,
      String? finalReasoning});
}

/// @nodoc
class __$AgentPlanCopyWithImpl<$Res> implements _$AgentPlanCopyWith<$Res> {
  __$AgentPlanCopyWithImpl(this._self, this._then);

  final _AgentPlan _self;
  final $Res Function(_AgentPlan) _then;

  /// Create a copy of AgentPlan
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? taskDescription = null,
    Object? steps = null,
    Object? status = null,
    Object? createdAt = freezed,
    Object? startedAt = freezed,
    Object? completedAt = freezed,
    Object? verifications = null,
    Object? results = null,
    Object? replannedCount = null,
    Object? finalReasoning = freezed,
  }) {
    return _then(_AgentPlan(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      taskDescription: null == taskDescription
          ? _self.taskDescription
          : taskDescription // ignore: cast_nullable_to_non_nullable
              as String,
      steps: null == steps
          ? _self._steps
          : steps // ignore: cast_nullable_to_non_nullable
              as List<PlanStep>,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as ExecutionStatus,
      createdAt: freezed == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      startedAt: freezed == startedAt
          ? _self.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      completedAt: freezed == completedAt
          ? _self.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      verifications: null == verifications
          ? _self._verifications
          : verifications // ignore: cast_nullable_to_non_nullable
              as List<Verification>,
      results: null == results
          ? _self._results
          : results // ignore: cast_nullable_to_non_nullable
              as List<StepResult>,
      replannedCount: null == replannedCount
          ? _self.replannedCount
          : replannedCount // ignore: cast_nullable_to_non_nullable
              as int,
      finalReasoning: freezed == finalReasoning
          ? _self.finalReasoning
          : finalReasoning // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
mixin _$AgentResult {
  String get planId;
  ExecutionStatus get finalStatus;
  dynamic get result;
  String? get error;
  DateTime? get completedAt;
  int? get totalDurationSeconds;
  int get stepsCompleted;
  int get stepsFailed;
  Map<String, dynamic> get metadata;

  /// Create a copy of AgentResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AgentResultCopyWith<AgentResult> get copyWith =>
      _$AgentResultCopyWithImpl<AgentResult>(this as AgentResult, _$identity);

  /// Serializes this AgentResult to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AgentResult &&
            (identical(other.planId, planId) || other.planId == planId) &&
            (identical(other.finalStatus, finalStatus) ||
                other.finalStatus == finalStatus) &&
            const DeepCollectionEquality().equals(other.result, result) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.totalDurationSeconds, totalDurationSeconds) ||
                other.totalDurationSeconds == totalDurationSeconds) &&
            (identical(other.stepsCompleted, stepsCompleted) ||
                other.stepsCompleted == stepsCompleted) &&
            (identical(other.stepsFailed, stepsFailed) ||
                other.stepsFailed == stepsFailed) &&
            const DeepCollectionEquality().equals(other.metadata, metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      planId,
      finalStatus,
      const DeepCollectionEquality().hash(result),
      error,
      completedAt,
      totalDurationSeconds,
      stepsCompleted,
      stepsFailed,
      const DeepCollectionEquality().hash(metadata));

  @override
  String toString() {
    return 'AgentResult(planId: $planId, finalStatus: $finalStatus, result: $result, error: $error, completedAt: $completedAt, totalDurationSeconds: $totalDurationSeconds, stepsCompleted: $stepsCompleted, stepsFailed: $stepsFailed, metadata: $metadata)';
  }
}

/// @nodoc
abstract mixin class $AgentResultCopyWith<$Res> {
  factory $AgentResultCopyWith(
          AgentResult value, $Res Function(AgentResult) _then) =
      _$AgentResultCopyWithImpl;
  @useResult
  $Res call(
      {String planId,
      ExecutionStatus finalStatus,
      dynamic result,
      String? error,
      DateTime? completedAt,
      int? totalDurationSeconds,
      int stepsCompleted,
      int stepsFailed,
      Map<String, dynamic> metadata});
}

/// @nodoc
class _$AgentResultCopyWithImpl<$Res> implements $AgentResultCopyWith<$Res> {
  _$AgentResultCopyWithImpl(this._self, this._then);

  final AgentResult _self;
  final $Res Function(AgentResult) _then;

  /// Create a copy of AgentResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? planId = null,
    Object? finalStatus = null,
    Object? result = freezed,
    Object? error = freezed,
    Object? completedAt = freezed,
    Object? totalDurationSeconds = freezed,
    Object? stepsCompleted = null,
    Object? stepsFailed = null,
    Object? metadata = null,
  }) {
    return _then(_self.copyWith(
      planId: null == planId
          ? _self.planId
          : planId // ignore: cast_nullable_to_non_nullable
              as String,
      finalStatus: null == finalStatus
          ? _self.finalStatus
          : finalStatus // ignore: cast_nullable_to_non_nullable
              as ExecutionStatus,
      result: freezed == result
          ? _self.result
          : result // ignore: cast_nullable_to_non_nullable
              as dynamic,
      error: freezed == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      completedAt: freezed == completedAt
          ? _self.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      totalDurationSeconds: freezed == totalDurationSeconds
          ? _self.totalDurationSeconds
          : totalDurationSeconds // ignore: cast_nullable_to_non_nullable
              as int?,
      stepsCompleted: null == stepsCompleted
          ? _self.stepsCompleted
          : stepsCompleted // ignore: cast_nullable_to_non_nullable
              as int,
      stepsFailed: null == stepsFailed
          ? _self.stepsFailed
          : stepsFailed // ignore: cast_nullable_to_non_nullable
              as int,
      metadata: null == metadata
          ? _self.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// Adds pattern-matching-related methods to [AgentResult].
extension AgentResultPatterns on AgentResult {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_AgentResult value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AgentResult() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_AgentResult value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AgentResult():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_AgentResult value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AgentResult() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String planId,
            ExecutionStatus finalStatus,
            dynamic result,
            String? error,
            DateTime? completedAt,
            int? totalDurationSeconds,
            int stepsCompleted,
            int stepsFailed,
            Map<String, dynamic> metadata)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AgentResult() when $default != null:
        return $default(
            _that.planId,
            _that.finalStatus,
            _that.result,
            _that.error,
            _that.completedAt,
            _that.totalDurationSeconds,
            _that.stepsCompleted,
            _that.stepsFailed,
            _that.metadata);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String planId,
            ExecutionStatus finalStatus,
            dynamic result,
            String? error,
            DateTime? completedAt,
            int? totalDurationSeconds,
            int stepsCompleted,
            int stepsFailed,
            Map<String, dynamic> metadata)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AgentResult():
        return $default(
            _that.planId,
            _that.finalStatus,
            _that.result,
            _that.error,
            _that.completedAt,
            _that.totalDurationSeconds,
            _that.stepsCompleted,
            _that.stepsFailed,
            _that.metadata);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String planId,
            ExecutionStatus finalStatus,
            dynamic result,
            String? error,
            DateTime? completedAt,
            int? totalDurationSeconds,
            int stepsCompleted,
            int stepsFailed,
            Map<String, dynamic> metadata)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AgentResult() when $default != null:
        return $default(
            _that.planId,
            _that.finalStatus,
            _that.result,
            _that.error,
            _that.completedAt,
            _that.totalDurationSeconds,
            _that.stepsCompleted,
            _that.stepsFailed,
            _that.metadata);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _AgentResult implements AgentResult {
  const _AgentResult(
      {required this.planId,
      required this.finalStatus,
      required this.result,
      this.error,
      this.completedAt,
      this.totalDurationSeconds,
      this.stepsCompleted = 0,
      this.stepsFailed = 0,
      final Map<String, dynamic> metadata = const {}})
      : _metadata = metadata;
  factory _AgentResult.fromJson(Map<String, dynamic> json) =>
      _$AgentResultFromJson(json);

  @override
  final String planId;
  @override
  final ExecutionStatus finalStatus;
  @override
  final dynamic result;
  @override
  final String? error;
  @override
  final DateTime? completedAt;
  @override
  final int? totalDurationSeconds;
  @override
  @JsonKey()
  final int stepsCompleted;
  @override
  @JsonKey()
  final int stepsFailed;
  final Map<String, dynamic> _metadata;
  @override
  @JsonKey()
  Map<String, dynamic> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  /// Create a copy of AgentResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AgentResultCopyWith<_AgentResult> get copyWith =>
      __$AgentResultCopyWithImpl<_AgentResult>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$AgentResultToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AgentResult &&
            (identical(other.planId, planId) || other.planId == planId) &&
            (identical(other.finalStatus, finalStatus) ||
                other.finalStatus == finalStatus) &&
            const DeepCollectionEquality().equals(other.result, result) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.totalDurationSeconds, totalDurationSeconds) ||
                other.totalDurationSeconds == totalDurationSeconds) &&
            (identical(other.stepsCompleted, stepsCompleted) ||
                other.stepsCompleted == stepsCompleted) &&
            (identical(other.stepsFailed, stepsFailed) ||
                other.stepsFailed == stepsFailed) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      planId,
      finalStatus,
      const DeepCollectionEquality().hash(result),
      error,
      completedAt,
      totalDurationSeconds,
      stepsCompleted,
      stepsFailed,
      const DeepCollectionEquality().hash(_metadata));

  @override
  String toString() {
    return 'AgentResult(planId: $planId, finalStatus: $finalStatus, result: $result, error: $error, completedAt: $completedAt, totalDurationSeconds: $totalDurationSeconds, stepsCompleted: $stepsCompleted, stepsFailed: $stepsFailed, metadata: $metadata)';
  }
}

/// @nodoc
abstract mixin class _$AgentResultCopyWith<$Res>
    implements $AgentResultCopyWith<$Res> {
  factory _$AgentResultCopyWith(
          _AgentResult value, $Res Function(_AgentResult) _then) =
      __$AgentResultCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String planId,
      ExecutionStatus finalStatus,
      dynamic result,
      String? error,
      DateTime? completedAt,
      int? totalDurationSeconds,
      int stepsCompleted,
      int stepsFailed,
      Map<String, dynamic> metadata});
}

/// @nodoc
class __$AgentResultCopyWithImpl<$Res> implements _$AgentResultCopyWith<$Res> {
  __$AgentResultCopyWithImpl(this._self, this._then);

  final _AgentResult _self;
  final $Res Function(_AgentResult) _then;

  /// Create a copy of AgentResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? planId = null,
    Object? finalStatus = null,
    Object? result = freezed,
    Object? error = freezed,
    Object? completedAt = freezed,
    Object? totalDurationSeconds = freezed,
    Object? stepsCompleted = null,
    Object? stepsFailed = null,
    Object? metadata = null,
  }) {
    return _then(_AgentResult(
      planId: null == planId
          ? _self.planId
          : planId // ignore: cast_nullable_to_non_nullable
              as String,
      finalStatus: null == finalStatus
          ? _self.finalStatus
          : finalStatus // ignore: cast_nullable_to_non_nullable
              as ExecutionStatus,
      result: freezed == result
          ? _self.result
          : result // ignore: cast_nullable_to_non_nullable
              as dynamic,
      error: freezed == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      completedAt: freezed == completedAt
          ? _self.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      totalDurationSeconds: freezed == totalDurationSeconds
          ? _self.totalDurationSeconds
          : totalDurationSeconds // ignore: cast_nullable_to_non_nullable
              as int?,
      stepsCompleted: null == stepsCompleted
          ? _self.stepsCompleted
          : stepsCompleted // ignore: cast_nullable_to_non_nullable
              as int,
      stepsFailed: null == stepsFailed
          ? _self.stepsFailed
          : stepsFailed // ignore: cast_nullable_to_non_nullable
              as int,
      metadata: null == metadata
          ? _self._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
mixin _$ToolMetadata {
  String get name;
  String get description;
  List<String> get capabilities;
  List<String> get requiredPermissions;
  String get executionContext; // 'local', 'remote', or 'hybrid'
  Map<String, dynamic> get parameters;
  bool get isAsync;
  Duration? get timeout;

  /// Create a copy of ToolMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ToolMetadataCopyWith<ToolMetadata> get copyWith =>
      _$ToolMetadataCopyWithImpl<ToolMetadata>(
          this as ToolMetadata, _$identity);

  /// Serializes this ToolMetadata to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ToolMetadata &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality()
                .equals(other.capabilities, capabilities) &&
            const DeepCollectionEquality()
                .equals(other.requiredPermissions, requiredPermissions) &&
            (identical(other.executionContext, executionContext) ||
                other.executionContext == executionContext) &&
            const DeepCollectionEquality()
                .equals(other.parameters, parameters) &&
            (identical(other.isAsync, isAsync) || other.isAsync == isAsync) &&
            (identical(other.timeout, timeout) || other.timeout == timeout));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      name,
      description,
      const DeepCollectionEquality().hash(capabilities),
      const DeepCollectionEquality().hash(requiredPermissions),
      executionContext,
      const DeepCollectionEquality().hash(parameters),
      isAsync,
      timeout);

  @override
  String toString() {
    return 'ToolMetadata(name: $name, description: $description, capabilities: $capabilities, requiredPermissions: $requiredPermissions, executionContext: $executionContext, parameters: $parameters, isAsync: $isAsync, timeout: $timeout)';
  }
}

/// @nodoc
abstract mixin class $ToolMetadataCopyWith<$Res> {
  factory $ToolMetadataCopyWith(
          ToolMetadata value, $Res Function(ToolMetadata) _then) =
      _$ToolMetadataCopyWithImpl;
  @useResult
  $Res call(
      {String name,
      String description,
      List<String> capabilities,
      List<String> requiredPermissions,
      String executionContext,
      Map<String, dynamic> parameters,
      bool isAsync,
      Duration? timeout});
}

/// @nodoc
class _$ToolMetadataCopyWithImpl<$Res> implements $ToolMetadataCopyWith<$Res> {
  _$ToolMetadataCopyWithImpl(this._self, this._then);

  final ToolMetadata _self;
  final $Res Function(ToolMetadata) _then;

  /// Create a copy of ToolMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? description = null,
    Object? capabilities = null,
    Object? requiredPermissions = null,
    Object? executionContext = null,
    Object? parameters = null,
    Object? isAsync = null,
    Object? timeout = freezed,
  }) {
    return _then(_self.copyWith(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      capabilities: null == capabilities
          ? _self.capabilities
          : capabilities // ignore: cast_nullable_to_non_nullable
              as List<String>,
      requiredPermissions: null == requiredPermissions
          ? _self.requiredPermissions
          : requiredPermissions // ignore: cast_nullable_to_non_nullable
              as List<String>,
      executionContext: null == executionContext
          ? _self.executionContext
          : executionContext // ignore: cast_nullable_to_non_nullable
              as String,
      parameters: null == parameters
          ? _self.parameters
          : parameters // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      isAsync: null == isAsync
          ? _self.isAsync
          : isAsync // ignore: cast_nullable_to_non_nullable
              as bool,
      timeout: freezed == timeout
          ? _self.timeout
          : timeout // ignore: cast_nullable_to_non_nullable
              as Duration?,
    ));
  }
}

/// Adds pattern-matching-related methods to [ToolMetadata].
extension ToolMetadataPatterns on ToolMetadata {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ToolMetadata value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ToolMetadata() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ToolMetadata value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ToolMetadata():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ToolMetadata value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ToolMetadata() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String name,
            String description,
            List<String> capabilities,
            List<String> requiredPermissions,
            String executionContext,
            Map<String, dynamic> parameters,
            bool isAsync,
            Duration? timeout)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ToolMetadata() when $default != null:
        return $default(
            _that.name,
            _that.description,
            _that.capabilities,
            _that.requiredPermissions,
            _that.executionContext,
            _that.parameters,
            _that.isAsync,
            _that.timeout);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String name,
            String description,
            List<String> capabilities,
            List<String> requiredPermissions,
            String executionContext,
            Map<String, dynamic> parameters,
            bool isAsync,
            Duration? timeout)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ToolMetadata():
        return $default(
            _that.name,
            _that.description,
            _that.capabilities,
            _that.requiredPermissions,
            _that.executionContext,
            _that.parameters,
            _that.isAsync,
            _that.timeout);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String name,
            String description,
            List<String> capabilities,
            List<String> requiredPermissions,
            String executionContext,
            Map<String, dynamic> parameters,
            bool isAsync,
            Duration? timeout)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ToolMetadata() when $default != null:
        return $default(
            _that.name,
            _that.description,
            _that.capabilities,
            _that.requiredPermissions,
            _that.executionContext,
            _that.parameters,
            _that.isAsync,
            _that.timeout);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ToolMetadata implements ToolMetadata {
  const _ToolMetadata(
      {required this.name,
      required this.description,
      required final List<String> capabilities,
      required final List<String> requiredPermissions,
      this.executionContext = 'local',
      final Map<String, dynamic> parameters = const {},
      this.isAsync = false,
      this.timeout = null})
      : _capabilities = capabilities,
        _requiredPermissions = requiredPermissions,
        _parameters = parameters;
  factory _ToolMetadata.fromJson(Map<String, dynamic> json) =>
      _$ToolMetadataFromJson(json);

  @override
  final String name;
  @override
  final String description;
  final List<String> _capabilities;
  @override
  List<String> get capabilities {
    if (_capabilities is EqualUnmodifiableListView) return _capabilities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_capabilities);
  }

  final List<String> _requiredPermissions;
  @override
  List<String> get requiredPermissions {
    if (_requiredPermissions is EqualUnmodifiableListView)
      return _requiredPermissions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_requiredPermissions);
  }

  @override
  @JsonKey()
  final String executionContext;
// 'local', 'remote', or 'hybrid'
  final Map<String, dynamic> _parameters;
// 'local', 'remote', or 'hybrid'
  @override
  @JsonKey()
  Map<String, dynamic> get parameters {
    if (_parameters is EqualUnmodifiableMapView) return _parameters;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_parameters);
  }

  @override
  @JsonKey()
  final bool isAsync;
  @override
  @JsonKey()
  final Duration? timeout;

  /// Create a copy of ToolMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ToolMetadataCopyWith<_ToolMetadata> get copyWith =>
      __$ToolMetadataCopyWithImpl<_ToolMetadata>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ToolMetadataToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ToolMetadata &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality()
                .equals(other._capabilities, _capabilities) &&
            const DeepCollectionEquality()
                .equals(other._requiredPermissions, _requiredPermissions) &&
            (identical(other.executionContext, executionContext) ||
                other.executionContext == executionContext) &&
            const DeepCollectionEquality()
                .equals(other._parameters, _parameters) &&
            (identical(other.isAsync, isAsync) || other.isAsync == isAsync) &&
            (identical(other.timeout, timeout) || other.timeout == timeout));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      name,
      description,
      const DeepCollectionEquality().hash(_capabilities),
      const DeepCollectionEquality().hash(_requiredPermissions),
      executionContext,
      const DeepCollectionEquality().hash(_parameters),
      isAsync,
      timeout);

  @override
  String toString() {
    return 'ToolMetadata(name: $name, description: $description, capabilities: $capabilities, requiredPermissions: $requiredPermissions, executionContext: $executionContext, parameters: $parameters, isAsync: $isAsync, timeout: $timeout)';
  }
}

/// @nodoc
abstract mixin class _$ToolMetadataCopyWith<$Res>
    implements $ToolMetadataCopyWith<$Res> {
  factory _$ToolMetadataCopyWith(
          _ToolMetadata value, $Res Function(_ToolMetadata) _then) =
      __$ToolMetadataCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String name,
      String description,
      List<String> capabilities,
      List<String> requiredPermissions,
      String executionContext,
      Map<String, dynamic> parameters,
      bool isAsync,
      Duration? timeout});
}

/// @nodoc
class __$ToolMetadataCopyWithImpl<$Res>
    implements _$ToolMetadataCopyWith<$Res> {
  __$ToolMetadataCopyWithImpl(this._self, this._then);

  final _ToolMetadata _self;
  final $Res Function(_ToolMetadata) _then;

  /// Create a copy of ToolMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? name = null,
    Object? description = null,
    Object? capabilities = null,
    Object? requiredPermissions = null,
    Object? executionContext = null,
    Object? parameters = null,
    Object? isAsync = null,
    Object? timeout = freezed,
  }) {
    return _then(_ToolMetadata(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      capabilities: null == capabilities
          ? _self._capabilities
          : capabilities // ignore: cast_nullable_to_non_nullable
              as List<String>,
      requiredPermissions: null == requiredPermissions
          ? _self._requiredPermissions
          : requiredPermissions // ignore: cast_nullable_to_non_nullable
              as List<String>,
      executionContext: null == executionContext
          ? _self.executionContext
          : executionContext // ignore: cast_nullable_to_non_nullable
              as String,
      parameters: null == parameters
          ? _self._parameters
          : parameters // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      isAsync: null == isAsync
          ? _self.isAsync
          : isAsync // ignore: cast_nullable_to_non_nullable
              as bool,
      timeout: freezed == timeout
          ? _self.timeout
          : timeout // ignore: cast_nullable_to_non_nullable
              as Duration?,
    ));
  }
}

/// @nodoc
mixin _$TaskCapabilities {
  List<String> get requiredTools;
  List<String> get requiredPermissions;
  String get suggestedExecutionContext;
  Map<String, dynamic> get estimatedResources;

  /// Create a copy of TaskCapabilities
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TaskCapabilitiesCopyWith<TaskCapabilities> get copyWith =>
      _$TaskCapabilitiesCopyWithImpl<TaskCapabilities>(
          this as TaskCapabilities, _$identity);

  /// Serializes this TaskCapabilities to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TaskCapabilities &&
            const DeepCollectionEquality()
                .equals(other.requiredTools, requiredTools) &&
            const DeepCollectionEquality()
                .equals(other.requiredPermissions, requiredPermissions) &&
            (identical(other.suggestedExecutionContext,
                    suggestedExecutionContext) ||
                other.suggestedExecutionContext == suggestedExecutionContext) &&
            const DeepCollectionEquality()
                .equals(other.estimatedResources, estimatedResources));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(requiredTools),
      const DeepCollectionEquality().hash(requiredPermissions),
      suggestedExecutionContext,
      const DeepCollectionEquality().hash(estimatedResources));

  @override
  String toString() {
    return 'TaskCapabilities(requiredTools: $requiredTools, requiredPermissions: $requiredPermissions, suggestedExecutionContext: $suggestedExecutionContext, estimatedResources: $estimatedResources)';
  }
}

/// @nodoc
abstract mixin class $TaskCapabilitiesCopyWith<$Res> {
  factory $TaskCapabilitiesCopyWith(
          TaskCapabilities value, $Res Function(TaskCapabilities) _then) =
      _$TaskCapabilitiesCopyWithImpl;
  @useResult
  $Res call(
      {List<String> requiredTools,
      List<String> requiredPermissions,
      String suggestedExecutionContext,
      Map<String, dynamic> estimatedResources});
}

/// @nodoc
class _$TaskCapabilitiesCopyWithImpl<$Res>
    implements $TaskCapabilitiesCopyWith<$Res> {
  _$TaskCapabilitiesCopyWithImpl(this._self, this._then);

  final TaskCapabilities _self;
  final $Res Function(TaskCapabilities) _then;

  /// Create a copy of TaskCapabilities
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? requiredTools = null,
    Object? requiredPermissions = null,
    Object? suggestedExecutionContext = null,
    Object? estimatedResources = null,
  }) {
    return _then(_self.copyWith(
      requiredTools: null == requiredTools
          ? _self.requiredTools
          : requiredTools // ignore: cast_nullable_to_non_nullable
              as List<String>,
      requiredPermissions: null == requiredPermissions
          ? _self.requiredPermissions
          : requiredPermissions // ignore: cast_nullable_to_non_nullable
              as List<String>,
      suggestedExecutionContext: null == suggestedExecutionContext
          ? _self.suggestedExecutionContext
          : suggestedExecutionContext // ignore: cast_nullable_to_non_nullable
              as String,
      estimatedResources: null == estimatedResources
          ? _self.estimatedResources
          : estimatedResources // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// Adds pattern-matching-related methods to [TaskCapabilities].
extension TaskCapabilitiesPatterns on TaskCapabilities {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_TaskCapabilities value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TaskCapabilities() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_TaskCapabilities value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TaskCapabilities():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_TaskCapabilities value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TaskCapabilities() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            List<String> requiredTools,
            List<String> requiredPermissions,
            String suggestedExecutionContext,
            Map<String, dynamic> estimatedResources)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TaskCapabilities() when $default != null:
        return $default(_that.requiredTools, _that.requiredPermissions,
            _that.suggestedExecutionContext, _that.estimatedResources);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            List<String> requiredTools,
            List<String> requiredPermissions,
            String suggestedExecutionContext,
            Map<String, dynamic> estimatedResources)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TaskCapabilities():
        return $default(_that.requiredTools, _that.requiredPermissions,
            _that.suggestedExecutionContext, _that.estimatedResources);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            List<String> requiredTools,
            List<String> requiredPermissions,
            String suggestedExecutionContext,
            Map<String, dynamic> estimatedResources)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TaskCapabilities() when $default != null:
        return $default(_that.requiredTools, _that.requiredPermissions,
            _that.suggestedExecutionContext, _that.estimatedResources);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _TaskCapabilities implements TaskCapabilities {
  const _TaskCapabilities(
      {required final List<String> requiredTools,
      required final List<String> requiredPermissions,
      this.suggestedExecutionContext = 'local',
      final Map<String, dynamic> estimatedResources = const {}})
      : _requiredTools = requiredTools,
        _requiredPermissions = requiredPermissions,
        _estimatedResources = estimatedResources;
  factory _TaskCapabilities.fromJson(Map<String, dynamic> json) =>
      _$TaskCapabilitiesFromJson(json);

  final List<String> _requiredTools;
  @override
  List<String> get requiredTools {
    if (_requiredTools is EqualUnmodifiableListView) return _requiredTools;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_requiredTools);
  }

  final List<String> _requiredPermissions;
  @override
  List<String> get requiredPermissions {
    if (_requiredPermissions is EqualUnmodifiableListView)
      return _requiredPermissions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_requiredPermissions);
  }

  @override
  @JsonKey()
  final String suggestedExecutionContext;
  final Map<String, dynamic> _estimatedResources;
  @override
  @JsonKey()
  Map<String, dynamic> get estimatedResources {
    if (_estimatedResources is EqualUnmodifiableMapView)
      return _estimatedResources;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_estimatedResources);
  }

  /// Create a copy of TaskCapabilities
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TaskCapabilitiesCopyWith<_TaskCapabilities> get copyWith =>
      __$TaskCapabilitiesCopyWithImpl<_TaskCapabilities>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$TaskCapabilitiesToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TaskCapabilities &&
            const DeepCollectionEquality()
                .equals(other._requiredTools, _requiredTools) &&
            const DeepCollectionEquality()
                .equals(other._requiredPermissions, _requiredPermissions) &&
            (identical(other.suggestedExecutionContext,
                    suggestedExecutionContext) ||
                other.suggestedExecutionContext == suggestedExecutionContext) &&
            const DeepCollectionEquality()
                .equals(other._estimatedResources, _estimatedResources));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_requiredTools),
      const DeepCollectionEquality().hash(_requiredPermissions),
      suggestedExecutionContext,
      const DeepCollectionEquality().hash(_estimatedResources));

  @override
  String toString() {
    return 'TaskCapabilities(requiredTools: $requiredTools, requiredPermissions: $requiredPermissions, suggestedExecutionContext: $suggestedExecutionContext, estimatedResources: $estimatedResources)';
  }
}

/// @nodoc
abstract mixin class _$TaskCapabilitiesCopyWith<$Res>
    implements $TaskCapabilitiesCopyWith<$Res> {
  factory _$TaskCapabilitiesCopyWith(
          _TaskCapabilities value, $Res Function(_TaskCapabilities) _then) =
      __$TaskCapabilitiesCopyWithImpl;
  @override
  @useResult
  $Res call(
      {List<String> requiredTools,
      List<String> requiredPermissions,
      String suggestedExecutionContext,
      Map<String, dynamic> estimatedResources});
}

/// @nodoc
class __$TaskCapabilitiesCopyWithImpl<$Res>
    implements _$TaskCapabilitiesCopyWith<$Res> {
  __$TaskCapabilitiesCopyWithImpl(this._self, this._then);

  final _TaskCapabilities _self;
  final $Res Function(_TaskCapabilities) _then;

  /// Create a copy of TaskCapabilities
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? requiredTools = null,
    Object? requiredPermissions = null,
    Object? suggestedExecutionContext = null,
    Object? estimatedResources = null,
  }) {
    return _then(_TaskCapabilities(
      requiredTools: null == requiredTools
          ? _self._requiredTools
          : requiredTools // ignore: cast_nullable_to_non_nullable
              as List<String>,
      requiredPermissions: null == requiredPermissions
          ? _self._requiredPermissions
          : requiredPermissions // ignore: cast_nullable_to_non_nullable
              as List<String>,
      suggestedExecutionContext: null == suggestedExecutionContext
          ? _self.suggestedExecutionContext
          : suggestedExecutionContext // ignore: cast_nullable_to_non_nullable
              as String,
      estimatedResources: null == estimatedResources
          ? _self._estimatedResources
          : estimatedResources // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
mixin _$PlanningContext {
  String get taskDescription;
  List<ToolMetadata> get availableTools;
  List<String> get availablePermissions;
  Map<String, dynamic> get environmentInfo;
  DateTime? get deadline;
  Map<String, dynamic> get constraints;

  /// Create a copy of PlanningContext
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PlanningContextCopyWith<PlanningContext> get copyWith =>
      _$PlanningContextCopyWithImpl<PlanningContext>(
          this as PlanningContext, _$identity);

  /// Serializes this PlanningContext to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PlanningContext &&
            (identical(other.taskDescription, taskDescription) ||
                other.taskDescription == taskDescription) &&
            const DeepCollectionEquality()
                .equals(other.availableTools, availableTools) &&
            const DeepCollectionEquality()
                .equals(other.availablePermissions, availablePermissions) &&
            const DeepCollectionEquality()
                .equals(other.environmentInfo, environmentInfo) &&
            (identical(other.deadline, deadline) ||
                other.deadline == deadline) &&
            const DeepCollectionEquality()
                .equals(other.constraints, constraints));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      taskDescription,
      const DeepCollectionEquality().hash(availableTools),
      const DeepCollectionEquality().hash(availablePermissions),
      const DeepCollectionEquality().hash(environmentInfo),
      deadline,
      const DeepCollectionEquality().hash(constraints));

  @override
  String toString() {
    return 'PlanningContext(taskDescription: $taskDescription, availableTools: $availableTools, availablePermissions: $availablePermissions, environmentInfo: $environmentInfo, deadline: $deadline, constraints: $constraints)';
  }
}

/// @nodoc
abstract mixin class $PlanningContextCopyWith<$Res> {
  factory $PlanningContextCopyWith(
          PlanningContext value, $Res Function(PlanningContext) _then) =
      _$PlanningContextCopyWithImpl;
  @useResult
  $Res call(
      {String taskDescription,
      List<ToolMetadata> availableTools,
      List<String> availablePermissions,
      Map<String, dynamic> environmentInfo,
      DateTime? deadline,
      Map<String, dynamic> constraints});
}

/// @nodoc
class _$PlanningContextCopyWithImpl<$Res>
    implements $PlanningContextCopyWith<$Res> {
  _$PlanningContextCopyWithImpl(this._self, this._then);

  final PlanningContext _self;
  final $Res Function(PlanningContext) _then;

  /// Create a copy of PlanningContext
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? taskDescription = null,
    Object? availableTools = null,
    Object? availablePermissions = null,
    Object? environmentInfo = null,
    Object? deadline = freezed,
    Object? constraints = null,
  }) {
    return _then(_self.copyWith(
      taskDescription: null == taskDescription
          ? _self.taskDescription
          : taskDescription // ignore: cast_nullable_to_non_nullable
              as String,
      availableTools: null == availableTools
          ? _self.availableTools
          : availableTools // ignore: cast_nullable_to_non_nullable
              as List<ToolMetadata>,
      availablePermissions: null == availablePermissions
          ? _self.availablePermissions
          : availablePermissions // ignore: cast_nullable_to_non_nullable
              as List<String>,
      environmentInfo: null == environmentInfo
          ? _self.environmentInfo
          : environmentInfo // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      deadline: freezed == deadline
          ? _self.deadline
          : deadline // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      constraints: null == constraints
          ? _self.constraints
          : constraints // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// Adds pattern-matching-related methods to [PlanningContext].
extension PlanningContextPatterns on PlanningContext {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_PlanningContext value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PlanningContext() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_PlanningContext value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlanningContext():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_PlanningContext value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlanningContext() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String taskDescription,
            List<ToolMetadata> availableTools,
            List<String> availablePermissions,
            Map<String, dynamic> environmentInfo,
            DateTime? deadline,
            Map<String, dynamic> constraints)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PlanningContext() when $default != null:
        return $default(
            _that.taskDescription,
            _that.availableTools,
            _that.availablePermissions,
            _that.environmentInfo,
            _that.deadline,
            _that.constraints);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String taskDescription,
            List<ToolMetadata> availableTools,
            List<String> availablePermissions,
            Map<String, dynamic> environmentInfo,
            DateTime? deadline,
            Map<String, dynamic> constraints)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlanningContext():
        return $default(
            _that.taskDescription,
            _that.availableTools,
            _that.availablePermissions,
            _that.environmentInfo,
            _that.deadline,
            _that.constraints);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String taskDescription,
            List<ToolMetadata> availableTools,
            List<String> availablePermissions,
            Map<String, dynamic> environmentInfo,
            DateTime? deadline,
            Map<String, dynamic> constraints)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PlanningContext() when $default != null:
        return $default(
            _that.taskDescription,
            _that.availableTools,
            _that.availablePermissions,
            _that.environmentInfo,
            _that.deadline,
            _that.constraints);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _PlanningContext implements PlanningContext {
  const _PlanningContext(
      {required this.taskDescription,
      required final List<ToolMetadata> availableTools,
      required final List<String> availablePermissions,
      final Map<String, dynamic> environmentInfo = const {},
      this.deadline = null,
      final Map<String, dynamic> constraints = const {}})
      : _availableTools = availableTools,
        _availablePermissions = availablePermissions,
        _environmentInfo = environmentInfo,
        _constraints = constraints;
  factory _PlanningContext.fromJson(Map<String, dynamic> json) =>
      _$PlanningContextFromJson(json);

  @override
  final String taskDescription;
  final List<ToolMetadata> _availableTools;
  @override
  List<ToolMetadata> get availableTools {
    if (_availableTools is EqualUnmodifiableListView) return _availableTools;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_availableTools);
  }

  final List<String> _availablePermissions;
  @override
  List<String> get availablePermissions {
    if (_availablePermissions is EqualUnmodifiableListView)
      return _availablePermissions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_availablePermissions);
  }

  final Map<String, dynamic> _environmentInfo;
  @override
  @JsonKey()
  Map<String, dynamic> get environmentInfo {
    if (_environmentInfo is EqualUnmodifiableMapView) return _environmentInfo;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_environmentInfo);
  }

  @override
  @JsonKey()
  final DateTime? deadline;
  final Map<String, dynamic> _constraints;
  @override
  @JsonKey()
  Map<String, dynamic> get constraints {
    if (_constraints is EqualUnmodifiableMapView) return _constraints;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_constraints);
  }

  /// Create a copy of PlanningContext
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PlanningContextCopyWith<_PlanningContext> get copyWith =>
      __$PlanningContextCopyWithImpl<_PlanningContext>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PlanningContextToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PlanningContext &&
            (identical(other.taskDescription, taskDescription) ||
                other.taskDescription == taskDescription) &&
            const DeepCollectionEquality()
                .equals(other._availableTools, _availableTools) &&
            const DeepCollectionEquality()
                .equals(other._availablePermissions, _availablePermissions) &&
            const DeepCollectionEquality()
                .equals(other._environmentInfo, _environmentInfo) &&
            (identical(other.deadline, deadline) ||
                other.deadline == deadline) &&
            const DeepCollectionEquality()
                .equals(other._constraints, _constraints));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      taskDescription,
      const DeepCollectionEquality().hash(_availableTools),
      const DeepCollectionEquality().hash(_availablePermissions),
      const DeepCollectionEquality().hash(_environmentInfo),
      deadline,
      const DeepCollectionEquality().hash(_constraints));

  @override
  String toString() {
    return 'PlanningContext(taskDescription: $taskDescription, availableTools: $availableTools, availablePermissions: $availablePermissions, environmentInfo: $environmentInfo, deadline: $deadline, constraints: $constraints)';
  }
}

/// @nodoc
abstract mixin class _$PlanningContextCopyWith<$Res>
    implements $PlanningContextCopyWith<$Res> {
  factory _$PlanningContextCopyWith(
          _PlanningContext value, $Res Function(_PlanningContext) _then) =
      __$PlanningContextCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String taskDescription,
      List<ToolMetadata> availableTools,
      List<String> availablePermissions,
      Map<String, dynamic> environmentInfo,
      DateTime? deadline,
      Map<String, dynamic> constraints});
}

/// @nodoc
class __$PlanningContextCopyWithImpl<$Res>
    implements _$PlanningContextCopyWith<$Res> {
  __$PlanningContextCopyWithImpl(this._self, this._then);

  final _PlanningContext _self;
  final $Res Function(_PlanningContext) _then;

  /// Create a copy of PlanningContext
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? taskDescription = null,
    Object? availableTools = null,
    Object? availablePermissions = null,
    Object? environmentInfo = null,
    Object? deadline = freezed,
    Object? constraints = null,
  }) {
    return _then(_PlanningContext(
      taskDescription: null == taskDescription
          ? _self.taskDescription
          : taskDescription // ignore: cast_nullable_to_non_nullable
              as String,
      availableTools: null == availableTools
          ? _self._availableTools
          : availableTools // ignore: cast_nullable_to_non_nullable
              as List<ToolMetadata>,
      availablePermissions: null == availablePermissions
          ? _self._availablePermissions
          : availablePermissions // ignore: cast_nullable_to_non_nullable
              as List<String>,
      environmentInfo: null == environmentInfo
          ? _self._environmentInfo
          : environmentInfo // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      deadline: freezed == deadline
          ? _self.deadline
          : deadline // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      constraints: null == constraints
          ? _self._constraints
          : constraints // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
mixin _$TaskAnalysis {
  String get taskDescription;
  int get estimatedComplexity; // 1-10 scale
  List<String> get requiredCapabilities;
  bool get shouldRunRemotely;
  String get reasoning;

  /// Create a copy of TaskAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TaskAnalysisCopyWith<TaskAnalysis> get copyWith =>
      _$TaskAnalysisCopyWithImpl<TaskAnalysis>(
          this as TaskAnalysis, _$identity);

  /// Serializes this TaskAnalysis to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TaskAnalysis &&
            (identical(other.taskDescription, taskDescription) ||
                other.taskDescription == taskDescription) &&
            (identical(other.estimatedComplexity, estimatedComplexity) ||
                other.estimatedComplexity == estimatedComplexity) &&
            const DeepCollectionEquality()
                .equals(other.requiredCapabilities, requiredCapabilities) &&
            (identical(other.shouldRunRemotely, shouldRunRemotely) ||
                other.shouldRunRemotely == shouldRunRemotely) &&
            (identical(other.reasoning, reasoning) ||
                other.reasoning == reasoning));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      taskDescription,
      estimatedComplexity,
      const DeepCollectionEquality().hash(requiredCapabilities),
      shouldRunRemotely,
      reasoning);

  @override
  String toString() {
    return 'TaskAnalysis(taskDescription: $taskDescription, estimatedComplexity: $estimatedComplexity, requiredCapabilities: $requiredCapabilities, shouldRunRemotely: $shouldRunRemotely, reasoning: $reasoning)';
  }
}

/// @nodoc
abstract mixin class $TaskAnalysisCopyWith<$Res> {
  factory $TaskAnalysisCopyWith(
          TaskAnalysis value, $Res Function(TaskAnalysis) _then) =
      _$TaskAnalysisCopyWithImpl;
  @useResult
  $Res call(
      {String taskDescription,
      int estimatedComplexity,
      List<String> requiredCapabilities,
      bool shouldRunRemotely,
      String reasoning});
}

/// @nodoc
class _$TaskAnalysisCopyWithImpl<$Res> implements $TaskAnalysisCopyWith<$Res> {
  _$TaskAnalysisCopyWithImpl(this._self, this._then);

  final TaskAnalysis _self;
  final $Res Function(TaskAnalysis) _then;

  /// Create a copy of TaskAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? taskDescription = null,
    Object? estimatedComplexity = null,
    Object? requiredCapabilities = null,
    Object? shouldRunRemotely = null,
    Object? reasoning = null,
  }) {
    return _then(_self.copyWith(
      taskDescription: null == taskDescription
          ? _self.taskDescription
          : taskDescription // ignore: cast_nullable_to_non_nullable
              as String,
      estimatedComplexity: null == estimatedComplexity
          ? _self.estimatedComplexity
          : estimatedComplexity // ignore: cast_nullable_to_non_nullable
              as int,
      requiredCapabilities: null == requiredCapabilities
          ? _self.requiredCapabilities
          : requiredCapabilities // ignore: cast_nullable_to_non_nullable
              as List<String>,
      shouldRunRemotely: null == shouldRunRemotely
          ? _self.shouldRunRemotely
          : shouldRunRemotely // ignore: cast_nullable_to_non_nullable
              as bool,
      reasoning: null == reasoning
          ? _self.reasoning
          : reasoning // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [TaskAnalysis].
extension TaskAnalysisPatterns on TaskAnalysis {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_TaskAnalysis value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TaskAnalysis() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_TaskAnalysis value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TaskAnalysis():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_TaskAnalysis value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TaskAnalysis() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String taskDescription,
            int estimatedComplexity,
            List<String> requiredCapabilities,
            bool shouldRunRemotely,
            String reasoning)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TaskAnalysis() when $default != null:
        return $default(
            _that.taskDescription,
            _that.estimatedComplexity,
            _that.requiredCapabilities,
            _that.shouldRunRemotely,
            _that.reasoning);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String taskDescription,
            int estimatedComplexity,
            List<String> requiredCapabilities,
            bool shouldRunRemotely,
            String reasoning)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TaskAnalysis():
        return $default(
            _that.taskDescription,
            _that.estimatedComplexity,
            _that.requiredCapabilities,
            _that.shouldRunRemotely,
            _that.reasoning);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String taskDescription,
            int estimatedComplexity,
            List<String> requiredCapabilities,
            bool shouldRunRemotely,
            String reasoning)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TaskAnalysis() when $default != null:
        return $default(
            _that.taskDescription,
            _that.estimatedComplexity,
            _that.requiredCapabilities,
            _that.shouldRunRemotely,
            _that.reasoning);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _TaskAnalysis implements TaskAnalysis {
  const _TaskAnalysis(
      {required this.taskDescription,
      required this.estimatedComplexity,
      required final List<String> requiredCapabilities,
      required this.shouldRunRemotely,
      required this.reasoning})
      : _requiredCapabilities = requiredCapabilities;
  factory _TaskAnalysis.fromJson(Map<String, dynamic> json) =>
      _$TaskAnalysisFromJson(json);

  @override
  final String taskDescription;
  @override
  final int estimatedComplexity;
// 1-10 scale
  final List<String> _requiredCapabilities;
// 1-10 scale
  @override
  List<String> get requiredCapabilities {
    if (_requiredCapabilities is EqualUnmodifiableListView)
      return _requiredCapabilities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_requiredCapabilities);
  }

  @override
  final bool shouldRunRemotely;
  @override
  final String reasoning;

  /// Create a copy of TaskAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TaskAnalysisCopyWith<_TaskAnalysis> get copyWith =>
      __$TaskAnalysisCopyWithImpl<_TaskAnalysis>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$TaskAnalysisToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TaskAnalysis &&
            (identical(other.taskDescription, taskDescription) ||
                other.taskDescription == taskDescription) &&
            (identical(other.estimatedComplexity, estimatedComplexity) ||
                other.estimatedComplexity == estimatedComplexity) &&
            const DeepCollectionEquality()
                .equals(other._requiredCapabilities, _requiredCapabilities) &&
            (identical(other.shouldRunRemotely, shouldRunRemotely) ||
                other.shouldRunRemotely == shouldRunRemotely) &&
            (identical(other.reasoning, reasoning) ||
                other.reasoning == reasoning));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      taskDescription,
      estimatedComplexity,
      const DeepCollectionEquality().hash(_requiredCapabilities),
      shouldRunRemotely,
      reasoning);

  @override
  String toString() {
    return 'TaskAnalysis(taskDescription: $taskDescription, estimatedComplexity: $estimatedComplexity, requiredCapabilities: $requiredCapabilities, shouldRunRemotely: $shouldRunRemotely, reasoning: $reasoning)';
  }
}

/// @nodoc
abstract mixin class _$TaskAnalysisCopyWith<$Res>
    implements $TaskAnalysisCopyWith<$Res> {
  factory _$TaskAnalysisCopyWith(
          _TaskAnalysis value, $Res Function(_TaskAnalysis) _then) =
      __$TaskAnalysisCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String taskDescription,
      int estimatedComplexity,
      List<String> requiredCapabilities,
      bool shouldRunRemotely,
      String reasoning});
}

/// @nodoc
class __$TaskAnalysisCopyWithImpl<$Res>
    implements _$TaskAnalysisCopyWith<$Res> {
  __$TaskAnalysisCopyWithImpl(this._self, this._then);

  final _TaskAnalysis _self;
  final $Res Function(_TaskAnalysis) _then;

  /// Create a copy of TaskAnalysis
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? taskDescription = null,
    Object? estimatedComplexity = null,
    Object? requiredCapabilities = null,
    Object? shouldRunRemotely = null,
    Object? reasoning = null,
  }) {
    return _then(_TaskAnalysis(
      taskDescription: null == taskDescription
          ? _self.taskDescription
          : taskDescription // ignore: cast_nullable_to_non_nullable
              as String,
      estimatedComplexity: null == estimatedComplexity
          ? _self.estimatedComplexity
          : estimatedComplexity // ignore: cast_nullable_to_non_nullable
              as int,
      requiredCapabilities: null == requiredCapabilities
          ? _self._requiredCapabilities
          : requiredCapabilities // ignore: cast_nullable_to_non_nullable
              as List<String>,
      shouldRunRemotely: null == shouldRunRemotely
          ? _self.shouldRunRemotely
          : shouldRunRemotely // ignore: cast_nullable_to_non_nullable
              as bool,
      reasoning: null == reasoning
          ? _self.reasoning
          : reasoning // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
