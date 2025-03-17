import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:volt/src/query.dart';
import 'package:volt/src/query_client_provider.dart';

/// Listens to a query and returns the result data
///
/// This hook manages the lifecycle of the query, including caching and refetching.
///
/// The data is returned in the following order:
/// 1. Cached data (if available and even if stale)
/// 2. Fresh data fetched from the `queryFn` if stale or not cached
T? useQuery<T>(
  VoltQuery<T> query, {
  Duration? staleTime,
  bool enabled = true,
}) {
  final context = useContext();
  final client = QueryClientProvider.of(context);
  final enabledQuery = enabled && query.queryFn != null;

  final (stream, initialData) = useMemoized(
    () {
      if (!enabledQuery) return (const Stream.empty(), null);

      final inMemoryData = client.persistor.peak(client.toStableKey(query), query);
      final stream = client
          .streamQuery(query, staleDuration: staleTime)
          .where((data) => inMemoryData == null || !identical(data, inMemoryData));
      return (stream, inMemoryData);
    },
    [client, ...query.queryKey, staleTime, enabledQuery],
  );

  return useStream(stream, initialData: initialData).data;
}
