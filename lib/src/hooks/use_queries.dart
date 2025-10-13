import 'package:collection/collection.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:rxdart/rxdart.dart';
import 'package:volt/src/hooks/use_lifecycle_aware_stream.dart';
import 'package:volt/volt.dart';

List<T>? useQueries<T>(
  List<VoltQuery<T>>? queries, {
  Duration? staleDuration,
  bool enabled = true,
  bool keepPreviousData = true,
  bool refetchOnResume = true,
}) {
  final context = useContext();
  final client = QueryClientProvider.of(context);
  final queryKeys = queries?.map((q) => q.queryKey).flattened.toList() ?? [];
  final enabledQuery =
      queries != null && queries.every((q) => q.queryFn != null) && queries.isNotEmpty;

  final (stream, initialData) = useMemoized<(Stream<List<T>>, List<T>?)>(
    () {
      if (!enabledQuery) return (Rx.never<List<T>>(), null);

      final initialData = queries.map((query) {
        final inMemoryData = client.persistor.peak(client.toStableKey(query), query);
        final hasData = inMemoryData is HasData<T>;
        return hasData ? inMemoryData.data : null;
      }).toList();

      final hasInitialData = initialData.every((data) => data != null);
      final stream = Rx.combineLatestList<T>(
        queries.mapIndexed((index, query) {
          return client
              .streamQuery(query, staleDuration: staleDuration)
              .where((data) => !hasInitialData || !identical(data, initialData[index]));
        }),
      );
      return (stream, hasInitialData ? initialData.cast<T>() : null);
    },
    [client, ...queryKeys, staleDuration, enabledQuery],
  );

  return useLifecycleAwareStream(
    stream,
    initialData: initialData,
    keepPreviousData: keepPreviousData,
    onResume: !enabledQuery || !refetchOnResume
        ? null
        : () {
            for (final query in queries) {
              final key = client.toStableKey(query);
              final persisted = client.persistor.peak<T>(key, query);
              final threshold = staleDuration ?? query.staleDuration ?? client.staleDuration;
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
