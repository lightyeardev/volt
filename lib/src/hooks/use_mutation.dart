import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:volt/src/mutation.dart';

/// Creates and manages a mutation for performing side effects
///
/// This hook handles the lifecycle of mutations, including loading states,
/// error handling, and success callbacks.
///
/// Example:
/// ```dart
/// final mutation = useMutation<String>(
///   mutationFn: (photoId) => deletePhoto(photoId),
///   onSuccess: (photoId) => print('Deleted photo $photoId'),
///   onError: (error, photoId) => print('Error: $error'),
/// );
///
/// // Later, trigger the mutation
/// mutation.mutate('123');
/// ```
VoltMutation<T> useMutation<T>({
  required Future<void> Function(T variables) mutationFn,
  void Function(T variables)? onSuccess,
  void Function(Object error, T variables)? onError,
  void Function(Object? error, T variables)? onSettled,
}) {
  final state = useState(const MutationState.idle());

  final mutate = useCallback(
    (T variables) async {
      state.value = state.value.copyWith(status: MutationStatus.loading);

      try {
        await mutationFn(variables);
        state.value = const MutationState(
          status: MutationStatus.success,
        );

        try {
          onSuccess?.call(variables);
        } catch (e) {
          if (kDebugMode) {
            print('Error in onSuccess callback: $e');
          }
        }

        try {
          onSettled?.call(null, variables);
        } catch (e) {
          if (kDebugMode) {
            print('Error in onSettled callback: $e');
          }
        }
      } catch (error) {
        state.value = MutationState(
          status: MutationStatus.error,
          error: error,
        );

        try {
          onError?.call(error, variables);
        } catch (e) {
          if (kDebugMode) {
            print('Error in onError callback: $e');
          }
        }

        try {
          onSettled?.call(error, variables);
        } catch (e) {
          if (kDebugMode) {
            print('Error in onSettled callback: $e');
          }
        }
      }
    },
    [mutationFn, onSuccess, onError, onSettled],
  );

  final reset = useCallback(
    () {
      state.value = const MutationState.idle();
    },
    [],
  );

  return VoltMutation<T>(
    state: state.value,
    mutate: mutate,
    reset: reset,
  );
}
