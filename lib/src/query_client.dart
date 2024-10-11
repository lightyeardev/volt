import 'package:volt/src/query.dart';

class QueryClient {
  QueryClient({
    this.keyTransformer = _defaultKeyTransformer,
  });

  /// Transforms the keys
  ///
  /// This is useful to add environment and locale specific keys to the query
  /// to ensure that the cache is correctly segmented
  final List<String> Function(List<String> keys) keyTransformer;

  Stream<T> streamQuery<T>(VoltQuery<T> query, {Duration? staleTime}) {
    return Stream.empty();
  }

  Future<T> prefetchQuery<T>(VoltQuery<T> query) {
    return Future.value(null);
  }
}

List<String> _defaultKeyTransformer(List<String> keys) => keys;
