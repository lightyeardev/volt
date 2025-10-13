import 'package:flutter/foundation.dart';

/// A mutation for performing side effects like create, update, or delete operations
///
/// This is used to define a mutation that will be executed when [mutate] is called
class VoltMutation<T> {
  /// The current state of the mutation
  final MutationState state;

  /// The function to execute the mutation with the provided variables
  final Future<void> Function(T variables) mutate;

  /// Resets the mutation state back to idle
  final VoidCallback reset;

  const VoltMutation({
    required this.state,
    required this.mutate,
    required this.reset,
  });
}

/// The state of a mutation
class MutationState {
  /// The status of the mutation
  final MutationStatus status;

  /// The error that occurred during the mutation, if any
  final Object? error;

  const MutationState({
    required this.status,
    this.error,
  });

  /// Whether the mutation is currently idle (not started)
  bool get isIdle => status == MutationStatus.idle;

  /// Whether the mutation is currently loading
  bool get isLoading => status == MutationStatus.loading;

  /// Whether the mutation was successful
  bool get isSuccess => status == MutationStatus.success;

  /// Whether the mutation encountered an error
  bool get isError => status == MutationStatus.error;

  const MutationState.idle()
      : status = MutationStatus.idle,
        error = null;

  MutationState copyWith({
    MutationStatus? status,
    Object? error,
  }) {
    return MutationState(
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }
}

/// The status of a mutation
enum MutationStatus {
  /// The mutation has not been executed yet
  idle,

  /// The mutation is currently executing
  loading,

  /// The mutation completed successfully
  success,

  /// The mutation encountered an error
  error,
}
