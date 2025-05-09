import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:volt/src/mutation.dart';

/// Creates a mutation for example to modify data on a server.
///
/// The mutation does not automatically invalidate any queries. To invalidate queries,
/// use the [useQueryClient] hook and call [QueryClient.prefetchQuery] in the
/// [onSuccess] callback. This allows for manual and flexible query invalidation.
VoltMutation<T> useMutationState<T>({
  required Future<bool> Function(T params) mutationFn,
  void Function(T? params)? onSuccess,
  void Function(T? params)? onError,
}) {
  final state = useState(const VoltMutationState());

  return VoltMutation(
    mutationFn: mutationFn,
    state: state,
    onSuccess: onSuccess,
    onError: onError,
  );
}
