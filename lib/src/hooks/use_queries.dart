import 'package:collection/collection.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:rxdart/rxdart.dart';
import 'package:volt/src/hooks/use_lifecycle_aware_stream.dart';
import 'package:volt/volt.dart';

List<T>? useQueries<T>(
  List<VoltQuery<T>>? queries, {
  bool enabled = true,
  Duration? staleTime,
}) {
  final context = useContext();
  final client = QueryClientProvider.of(context);

  final queryKeys = queries?.map((q) => q.queryKey).flattened.toList() ?? [];
  final enabledQuery =
      queries != null && queries.every((q) => q.queryFn != null) && queries.isNotEmpty;

  final (stream, initialData) = useMemoized(
    () {
      if (!enabledQuery) return (Rx.never<List<T>>(), null);

      final inMemoryData =
          queries.map((query) => client.persistor.peak(client.toStableKey(query), query)).toList();

      final hasData = inMemoryData.every((data) => data is HasData);
      final initialData =
          hasData ? inMemoryData.map((data) => (data as HasData).data as T).toList() : null;

      final stream = Rx.combineLatestList(
        queries.map((query) => client.streamQuery(query, staleDuration: staleTime)),
      );

      return (stream, initialData);
    },
    [client, ...queryKeys, staleTime, enabledQuery],
  );

  return useLifecycleAwareStream(stream, initialData: initialData);
}

(T1, T2)? useQueries2<T1, T2>(
  VoltQuery<T1> query1,
  VoltQuery<T2> query2, {
  bool enabled = true,
  Duration? staleTime,
}) {
  final r1 = useQuery(query1, enabled: enabled, staleTime: staleTime);
  final r2 = useQuery(query2, enabled: enabled, staleTime: staleTime);

  if (r1 == null || r2 == null) {
    return null;
  }

  return (r1, r2);
}

(T1, T2, T3)? useQueries3<T1, T2, T3>(
  VoltQuery<T1> query1,
  VoltQuery<T2> query2,
  VoltQuery<T3> query3, {
  bool enabled = true,
  Duration? staleTime,
}) {
  final r1 = useQuery(query1, enabled: enabled, staleTime: staleTime);
  final r2 = useQuery(query2, enabled: enabled, staleTime: staleTime);
  final r3 = useQuery(query3, enabled: enabled, staleTime: staleTime);

  if (r1 == null || r2 == null || r3 == null) {
    return null;
  }

  return (r1, r2, r3);
}

(T1, T2, T3, T4)? useQueries4<T1, T2, T3, T4>(
  VoltQuery<T1> query1,
  VoltQuery<T2> query2,
  VoltQuery<T3> query3,
  VoltQuery<T4> query4, {
  bool enabled = true,
  Duration? staleTime,
}) {
  final r1 = useQuery(query1, enabled: enabled, staleTime: staleTime);
  final r2 = useQuery(query2, enabled: enabled, staleTime: staleTime);
  final r3 = useQuery(query3, enabled: enabled, staleTime: staleTime);
  final r4 = useQuery(query4, enabled: enabled, staleTime: staleTime);

  if (r1 == null || r2 == null || r3 == null || r4 == null) {
    return null;
  }

  return (r1, r2, r3, r4);
}

(T1, T2, T3, T4, T5)? useQueries5<T1, T2, T3, T4, T5>(
  VoltQuery<T1> query1,
  VoltQuery<T2> query2,
  VoltQuery<T3> query3,
  VoltQuery<T4> query4,
  VoltQuery<T5> query5, {
  bool enabled = true,
  Duration? staleTime,
}) {
  final r1 = useQuery(query1, enabled: enabled, staleTime: staleTime);
  final r2 = useQuery(query2, enabled: enabled, staleTime: staleTime);
  final r3 = useQuery(query3, enabled: enabled, staleTime: staleTime);
  final r4 = useQuery(query4, enabled: enabled, staleTime: staleTime);
  final r5 = useQuery(query5, enabled: enabled, staleTime: staleTime);

  if (r1 == null || r2 == null || r3 == null || r4 == null || r5 == null) {
    return null;
  }

  return (r1, r2, r3, r4, r5);
}

(T1, T2, T3, T4, T5, T6)? useQueries6<T1, T2, T3, T4, T5, T6>(
  VoltQuery<T1> query1,
  VoltQuery<T2> query2,
  VoltQuery<T3> query3,
  VoltQuery<T4> query4,
  VoltQuery<T5> query5,
  VoltQuery<T6> query6, {
  bool enabled = true,
  Duration? staleTime,
}) {
  final r1 = useQuery(query1, enabled: enabled, staleTime: staleTime);
  final r2 = useQuery(query2, enabled: enabled, staleTime: staleTime);
  final r3 = useQuery(query3, enabled: enabled, staleTime: staleTime);
  final r4 = useQuery(query4, enabled: enabled, staleTime: staleTime);
  final r5 = useQuery(query5, enabled: enabled, staleTime: staleTime);
  final r6 = useQuery(query6, enabled: enabled, staleTime: staleTime);

  if (r1 == null || r2 == null || r3 == null || r4 == null || r5 == null || r6 == null) {
    return null;
  }

  return (r1, r2, r3, r4, r5, r6);
}

(T1, T2, T3, T4, T5, T6, T7)? useQueries7<T1, T2, T3, T4, T5, T6, T7>(
  VoltQuery<T1> query1,
  VoltQuery<T2> query2,
  VoltQuery<T3> query3,
  VoltQuery<T4> query4,
  VoltQuery<T5> query5,
  VoltQuery<T6> query6,
  VoltQuery<T7> query7, {
  bool enabled = true,
  Duration? staleTime,
}) {
  final r1 = useQuery(query1, enabled: enabled, staleTime: staleTime);
  final r2 = useQuery(query2, enabled: enabled, staleTime: staleTime);
  final r3 = useQuery(query3, enabled: enabled, staleTime: staleTime);
  final r4 = useQuery(query4, enabled: enabled, staleTime: staleTime);
  final r5 = useQuery(query5, enabled: enabled, staleTime: staleTime);
  final r6 = useQuery(query6, enabled: enabled, staleTime: staleTime);
  final r7 = useQuery(query7, enabled: enabled, staleTime: staleTime);

  if (r1 == null ||
      r2 == null ||
      r3 == null ||
      r4 == null ||
      r5 == null ||
      r6 == null ||
      r7 == null) {
    return null;
  }

  return (r1, r2, r3, r4, r5, r6, r7);
}

(T1, T2, T3, T4, T5, T6, T7, T8)? useQueries8<T1, T2, T3, T4, T5, T6, T7, T8>(
  VoltQuery<T1> query1,
  VoltQuery<T2> query2,
  VoltQuery<T3> query3,
  VoltQuery<T4> query4,
  VoltQuery<T5> query5,
  VoltQuery<T6> query6,
  VoltQuery<T7> query7,
  VoltQuery<T8> query8, {
  bool enabled = true,
  Duration? staleTime,
}) {
  final r1 = useQuery(query1, enabled: enabled, staleTime: staleTime);
  final r2 = useQuery(query2, enabled: enabled, staleTime: staleTime);
  final r3 = useQuery(query3, enabled: enabled, staleTime: staleTime);
  final r4 = useQuery(query4, enabled: enabled, staleTime: staleTime);
  final r5 = useQuery(query5, enabled: enabled, staleTime: staleTime);
  final r6 = useQuery(query6, enabled: enabled, staleTime: staleTime);
  final r7 = useQuery(query7, enabled: enabled, staleTime: staleTime);
  final r8 = useQuery(query8, enabled: enabled, staleTime: staleTime);

  if (r1 == null ||
      r2 == null ||
      r3 == null ||
      r4 == null ||
      r5 == null ||
      r6 == null ||
      r7 == null ||
      r8 == null) {
    return null;
  }

  return (r1, r2, r3, r4, r5, r6, r7, r8);
}

(T1, T2, T3, T4, T5, T6, T7, T8, T9)? useQueries9<T1, T2, T3, T4, T5, T6, T7, T8, T9>(
  VoltQuery<T1> query1,
  VoltQuery<T2> query2,
  VoltQuery<T3> query3,
  VoltQuery<T4> query4,
  VoltQuery<T5> query5,
  VoltQuery<T6> query6,
  VoltQuery<T7> query7,
  VoltQuery<T8> query8,
  VoltQuery<T9> query9, {
  bool enabled = true,
  Duration? staleTime,
}) {
  final r1 = useQuery(query1, enabled: enabled, staleTime: staleTime);
  final r2 = useQuery(query2, enabled: enabled, staleTime: staleTime);
  final r3 = useQuery(query3, enabled: enabled, staleTime: staleTime);
  final r4 = useQuery(query4, enabled: enabled, staleTime: staleTime);
  final r5 = useQuery(query5, enabled: enabled, staleTime: staleTime);
  final r6 = useQuery(query6, enabled: enabled, staleTime: staleTime);
  final r7 = useQuery(query7, enabled: enabled, staleTime: staleTime);
  final r8 = useQuery(query8, enabled: enabled, staleTime: staleTime);
  final r9 = useQuery(query9, enabled: enabled, staleTime: staleTime);

  if (r1 == null ||
      r2 == null ||
      r3 == null ||
      r4 == null ||
      r5 == null ||
      r6 == null ||
      r7 == null ||
      r8 == null ||
      r9 == null) {
    return null;
  }

  return (r1, r2, r3, r4, r5, r6, r7, r8, r9);
}
