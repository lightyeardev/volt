import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:volt/src/mutation.dart';

/// Creates a mutation for example to modify data on a server.
///
/// The mutation will automatically invalidate the given [invalidateQuery] if
/// it is provided or the listeners can be used to invalidate queries manually.
VoltMutation<T> useMutation<T>({
  required Future<bool> Function(T params) mutationFn,
  void Function(T? params)? onSuccess,
  void Function(T? params)? onError,
}) {
  final isLoading = useState(false);

  return VoltMutation(
    mutationFn: mutationFn,
    isLoading: isLoading,
    onSuccess: onSuccess,
    onError: onError,
  );
}
