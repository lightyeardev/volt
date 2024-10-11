class QueryClient {
  QueryClient({
    this.keyTransformer = _defaultKeyTransformer,
  });

  /// Transforms the keys
  ///
  /// This is useful to add environment and locale specific keys to the query
  /// to ensure that the cache is correctly segmented
  final List<String> Function(List<String> keys) keyTransformer;
}

List<String> _defaultKeyTransformer(List<String> keys) => keys;
