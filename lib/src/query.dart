import 'package:flutter/foundation.dart';

/// A query with a declarative data fetching and caching API
///
/// This is used to define a query that will be run to get data, and then cache that data
class VoltQuery<T> {
  /// The key to use for the query
  ///
  /// This is used to determine if the query is already in the cache
  final List<String> queryKey;

  /// The function to run the query
  ///
  /// This is the function that will be run to get the data for the query, generally a HTTP request
  final Future<dynamic> Function() queryFn;

  /// The function to select the data from the query
  ///
  /// This is the function that will be run to select the data from the query, generally a JSON deserialization
  final T Function(dynamic data) select;

  /// For extremely large queries run select in a [compute] isolate
  ///
  /// This is useful for operations that take longer than a few milliseconds, and
  /// which would therefore risk skipping frames.
  final bool useSelectCompute;

  const VoltQuery({
    required this.queryKey,
    required this.queryFn,
    required this.select,
    this.useSelectCompute = false,
  });
}
