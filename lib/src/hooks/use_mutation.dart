import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:volt/src/mutation.dart';

/// Creates a mutation for example to modify data on a server.
///
/// The mutation will automatically invalidate the given [invalidateQuery] if
/// it is provided or the listeners can be used to invalidate queries manually.
VoltMutation<D, P> useMutation<D, P>({
  required Future<bool> Function(P params) mutationFn,
  void Function(P? variables)? onSuccess,
  void Function(P? variables)? onError,
}) {
  final isLoading = useState(false);

  return VoltMutation(
    mutationFn: mutationFn,
    isLoading: isLoading,
    onSuccess: onSuccess,
    onError: onError,
  );
}
