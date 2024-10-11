import 'package:volt/src/query.dart';

class QueryClient {
  QueryClient({
    this.keyTransformer = _defaultKeyTransformer,
    this.staleTime,
  });

  /// Transforms the keys
  ///
  /// This is useful to add environment and locale specific keys to the query
  /// to ensure that the cache is correctly segmented
  final List<String> Function(List<String> keys) keyTransformer;

  /// Global default stale time when it's not specified in [VoltQuery] or [useQuery]
  ///
  /// The time to keep the data in the cache before it is considered stale
  final Duration? staleTime;

  Stream<T> streamQuery<T>(VoltQuery<T> query, {Duration? staleTime}) {
    return Stream.empty();
  }

  Future<bool> prefetchQuery<T>(VoltQuery<T> query) {
    return Future.value(true);
  }

  Future<T> fetchQuery<T>(VoltQuery<T> query) {
    return Future.value(null);
  }
}

List<String> _defaultKeyTransformer(List<String> keys) => keys;
