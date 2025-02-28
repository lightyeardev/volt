import 'package:flutter/foundation.dart';

/// A query with a declarative data fetching and caching API
///
/// This is used to define a query that will be run to get data, and then cache that data
class VoltQuery<T> {
  /// The key to use for the query
  ///
  /// This is used to determine if the query is already in the cache
  final List<String?> queryKey;

  /// The function to run the query
  ///
  /// This is the function that will be run to get the data for the query, generally a HTTP request
  final Future<dynamic> Function()? queryFn;

  /// The function to select the data from the query
  ///
  /// This is the function that will be run to select the data from the query, generally a JSON deserialization
  final T Function(dynamic data) select;

  /// For extremely large queries run select in a [compute] isolate
  ///
  /// This is useful for operations that take longer than a few milliseconds, and
  /// which would therefore risk skipping frames.
  final bool useComputeIsolate;

  /// Disables the disk cache for this query
  ///
  /// This is useful for queries that should not be persisted to disk
  final bool disableDiskCache;

  /// The scope to use for the query
  ///
  /// This is useful to segment the cache, for example by logged in vs logged out users
  final String? scope;

  /// The time to keep the data in the cache before it is considered stale
  ///
  /// When null the global default stale duration will be used
  final Duration? staleDuration;

  /// The duration to poll the query for
  ///
  /// When null the query will not be polled
  final Duration? pollingDuration;

  const VoltQuery({
    required this.queryKey,
    required this.queryFn,
    required this.select,
    this.staleDuration,
    this.useComputeIsolate = false,
    this.disableDiskCache = false,
    this.scope,
    this.pollingDuration,
  });
}
