import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:rxdart/rxdart.dart';
import 'package:volt/src/hooks/use_lifecycle_aware_stream.dart';
import 'package:volt/src/persister/persister.dart';
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
  bool keepPreviousData = true,
}) {
  final context = useContext();
  final client = QueryClientProvider.of(context);
  final enabledQuery = enabled && query.queryFn != null;

  final (stream, initialData) = useMemoized(
    () {
      if (!enabledQuery) return (Rx.never<T>(), null);

      final inMemoryData = client.persistor.peak(client.toStableKey(query), query);
      final hasData = inMemoryData is HasData<T>;
      final stream = client
          .streamQuery(query, staleDuration: staleTime)
          .where((data) => !hasData || !identical(data, inMemoryData.data));
      return (stream, hasData ? inMemoryData.data : null);
    },
    [client, ...query.queryKey, staleTime, enabledQuery],
  );

  return useLifecycleAwareStream(
    stream,
    initialData: initialData,
    keepPreviousData: keepPreviousData,
  );
}
