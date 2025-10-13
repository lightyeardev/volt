import 'package:collection/collection.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:rxdart/rxdart.dart';
import 'package:volt/src/hooks/use_lifecycle_aware_stream.dart';
import 'package:volt/volt.dart';

List<T>? useQueries<T>(
  List<VoltQuery<T>>? queries, {
  Duration? staleTime,
  bool enabled = true,
  bool keepPreviousData = true,
  bool refetchOnResume = true,
}) {
  final context = useContext();
  final client = QueryClientProvider.of(context);
  final queryKeys = queries?.map((q) => q.queryKey).flattened.toList() ?? [];
  final enabledQuery =
      queries != null && queries.every((q) => q.queryFn != null) && queries.isNotEmpty;

  final (stream, initialData) = useMemoized<(Stream<List<T>>, List<T?>?)>(
    () {
      if (!enabledQuery) return (Rx.never<List<T>>(), null);

      final initialData = queries.map((query) {
        final inMemoryData = client.persistor.peak(client.toStableKey(query), query);
        final hasData = inMemoryData is HasData<T>;
        return hasData ? inMemoryData.data : null;
      }).toList();

      final stream = Rx.combineLatestList<T>(
        queries.map((query) {
          final inMemoryData = client.persistor.peak(client.toStableKey(query), query);
          final hasData = inMemoryData is HasData<T>;
          return client
              .streamQuery(query, staleDuration: staleTime)
              .where((data) => !hasData || !identical(data, inMemoryData.data));
        }),
      );
      return (stream, initialData);
    },
    [client, ...queryKeys, staleTime, enabledQuery],
  );

  final hasInitialData = initialData?.every((data) => data != null) ?? false;

  return useLifecycleAwareStream(
    stream,
    initialData: hasInitialData ? initialData!.cast<T>() : null,
    keepPreviousData: keepPreviousData,
    onResume: !enabledQuery || !refetchOnResume
        ? null
        : () {
            for (final query in queries) {
              final key = client.toStableKey(query);
              final persisted = client.persistor.peak<T>(key, query);
              final threshold = staleTime ?? query.staleDuration ?? client.staleDuration;
              if (persisted is HasData<T>) {
                final isStale = persisted.timestamp.add(threshold).isBefore(DateTime.now().toUtc());
                if (isStale) {
                  client.prefetchQuery<T>(query);
                }
              }
            }
          },
  );
}
