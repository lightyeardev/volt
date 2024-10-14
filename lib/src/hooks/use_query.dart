import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:volt/src/query.dart';
import 'package:volt/src/query_client_provider.dart';

/// Listen to a query for data and return the result
///
/// This hook listens to a query and returns the result. The query is automatically
/// run when the component is mounted, and the result is returned.
///
/// It returns data in the following order. When `staleTime` is shorter than the time the resource is
/// cached, the data is returned from the cache first, then an update is fetched from the `queryFn`.
T? useQuery<T>(
  VoltQuery<T> query, {
  Duration? staleTime,
  bool enabled = true,
}) {
  final context = useContext();
  final client = VoltQueryClientProvider.of(context);

  final stream = useMemoized(
    () => enabled ? client.streamQuery(query, staleDuration: staleTime) : const Stream.empty(),
    [client, ...query.queryKey, staleTime, enabled],
  );

  return useStream(stream).data;
}
