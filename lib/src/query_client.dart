import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:volt/src/conflate/conflate_future.dart';
import 'package:volt/src/conflate/conflate_stream.dart';
import 'package:volt/src/debug/logger.dart';
import 'package:volt/src/persister/disk_volt_persister.dart';
import 'package:volt/src/persister/persister.dart';
import 'package:volt/src/query.dart';
import 'package:volt/src/volt_listener.dart';

class QueryClient {
  static const _minRetrySecondDuration = 4;
  static const _maxRetrySecondDuration = Duration.secondsPerMinute * 5;

  QueryClient({
    this.keyTransformer = _defaultKeyTransformer,
    VoltPersistor? persistor,
    this.staleDuration = const Duration(hours: 1),
    this.isDebug = false,
    this.listener,
  })  : persistor = persistor ?? FileVoltPersistor(listener: listener),
        _logger = isDebug ? const StdOutLogger() : const NoOpLogger();

  /// Transforms the keys
  ///
  /// This is useful to add environment and locale specific keys to the query
  /// to ensure that the cache is correctly segmented
  final List<String> Function(List<String> keys) keyTransformer;

  /// Global default stale duration when it's not specified in [VoltQuery] or [useQuery]
  ///
  /// The time to keep the data in the cache before it is considered stale
  final Duration staleDuration;

  /// The persistor to use for memory and disk caching
  ///
  /// This ships with a default [FileVoltPersistor] that persists to disk but can be overridden
  /// with a custom implementation
  final VoltPersistor persistor;

  /// A listener for query events
  ///
  /// This is useful for debugging and tracking the cache hit rate, miss rate, etc.
  final VoltListener? listener;

  /// Whether to use debug mode for extra logging and stats
  final bool isDebug;

  final Logger _logger;
  final ConflateFuture _conflateFuture = ConflateFuture();
  final ConflateStream _conflateStream = ConflateStream();

  /// Streams query results, managing caching, staleness, and polling.
  ///
  /// This method combines persisted data and polling streams, handling initial
  /// and subsequent data emissions. It checks data staleness, fetches fresh data
  /// when needed, and implements exponential backoff for failed requests.
  Stream<T> streamQuery<T>(VoltQuery<T> query, {Duration? staleDuration}) {
    int index = 0;
    final key = toStableKey(query);
    final threshold = staleDuration ?? query.staleDuration ?? this.staleDuration;

    return Rx.merge(
      [
        persistor.listen(key, query),
        _createPollingStream(key, query),
      ],
    ).switchMap<T>(
      (persistedValue) {
        if (index++ == 0) {
          if (persistedValue is HasData) {
            final entry = persistedValue as HasData<T>;
            if (entry.timestamp.add(threshold).isBefore(DateTime.now().toUtc())) {
              return _sourceWithExponentialBackoff(key, query).startWith(entry.data);
            } else {
              return Stream.value(entry.data);
            }
          } else if (persistedValue is NoData) {
            return _sourceWithExponentialBackoff(key, query);
          } else {
            throw 'Unexpected value: $persistedValue';
          }
        } else if (persistedValue is HasData) {
          return Stream.value((persistedValue as HasData<T>).data);
        }
        return const Stream.empty();
      },
    );
  }

  /// Prefetches and caches the result of a query.
  ///
  /// This method executes the given [query] and stores its result in the cache.
  /// It's useful for preloading data that will be needed soon, improving the user experience
  /// by reducing wait times.
  Future<bool> prefetchQuery<T>(VoltQuery<T> query) async {
    final key = toStableKey(query);

    return await _sourceAndPersist(key, query) is! _Failure<T>;
  }

  /// Fetches and caches the result of a query, throwing an error if the fetch fails.
  ///
  /// This method executes the given [query] and stores its result in the cache.
  /// If the query fails, it will throw an error instead of returning a default value.
  /// This is useful when you need to ensure that the data is successfully fetched,
  /// and want to handle errors at the call site.
  ///
  /// Returns a [Future] that completes with the fetched data of type [T].
  /// Throws an error if the fetch operation fails.
  Future<T> fetchQueryOrThrow<T>(VoltQuery<T> query) async {
    final key = toStableKey(query);

    final (data, _) = await _sourceAndPersistOrThrow(key, query);
    return data;
  }

  /// Invalidates all queries within the specified scope.
  ///
  /// This method clears the cache for all queries associated with the given [scope].
  /// If [scope] is null, it will invalidate all queries regardless of their scope.
  ///
  /// Use this method when you want to force a refresh of all data within a particular scope,
  /// or when you want to clear all cached data if no scope is specified.
  ///
  /// Returns a [Future] that completes when the invalidation process is finished.
  Future<void> invalidateScope(String? scope) async {
    await persistor.clearScope(scope);
  }

  Stream<T> _createPollingStream<T>(String key, VoltQuery<T> query) {
    final pollingDuration = query.pollingDuration;
    if (pollingDuration == null) {
      return const Stream.empty();
    }
    return _conflateStream.conflateByKey(
      key,
      () => Stream.periodic(pollingDuration)
          .switchMap((value) => _sourceAndPersist(key, query).asStream())
          .listen(null),
      listener,
    );
  }

  Stream<T> _sourceWithExponentialBackoff<T>(
    String key,
    VoltQuery<T> query, {
    Duration? retryDuration,
  }) {
    final localRetryDuration = retryDuration ?? Duration.zero;
    return Rx.timer(key, localRetryDuration)
        .asyncMap((_) => _sourceAndPersist(key, query))
        .flatMap((result) {
      if (result is _Success || result is _NoChange) {
        return const Stream.empty();
      } else if (result is _Failure) {
        return _sourceWithExponentialBackoff(
          key,
          query,
          retryDuration: Duration(
            seconds: (localRetryDuration.inSeconds * 1.5)
                .round()
                .clamp(_minRetrySecondDuration, _maxRetrySecondDuration),
          ),
        );
      } else {
        throw 'Unexpected value: $result';
      }
    });
  }

  Future<_VoltResult<T>> _sourceAndPersist<T>(String key, VoltQuery<T> query) async {
    try {
      final (data, persisted) = await _sourceAndPersistOrThrow(key, query);
      return persisted ? _Success(data) : _NoChange();
    } catch (e, stackTrace) {
      listener?.onNetworkError();
      if (kDebugMode) {
        _logger.logInfo(
          'Failed to fetch from queryFn: $key',
          error: e,
          stackTrace: stackTrace,
        );
      }
      return _Failure(e);
    }
  }

  Future<(T, bool)> _sourceAndPersistOrThrow<T>(String key, VoltQuery<T> query) async {
    return await _conflateFuture.conflateByKey(
      key,
      () async {
        var json = await query.queryFn!();
        listener?.onNetworkHit();
        // deserialize it before persisting it, in case source returns something unexpected
        final dynamic data;
        try {
          final useCompute = query.useComputeIsolate && !kDebugMode;
          data = useCompute ? await compute(query.select, json) : query.select(json);
        } catch (error, stackTrace) {
          listener?.onDeserializationError();
          if (isDebug) {
            _logger.logInfo('Failed to deserialize data from source: $json',
                stackTrace: stackTrace);
          } else {
            _logger.logInfo(error, stackTrace: stackTrace);
          }
          rethrow;
        }

        final persisted = await persistor.put<T>(key, query, data as T, json);
        return (data, persisted);
      },
      listener,
    );
  }

  String toStableKey<T>(VoltQuery<T> query) {
    return sha256
        .convert(utf8.encode(keyTransformer(query.queryKey.map((e) => e ?? '').toList()).join(',')))
        .toString();
  }
}

sealed class _VoltResult<S> {
  _VoltResult._();
}

class _Failure<T> extends _VoltResult<T> {
  final Object exception;

  _Failure(this.exception) : super._();
}

class _Success<T> extends _VoltResult<T> {
  final T data;

  _Success(this.data) : super._();
}

class _NoChange<T> extends _VoltResult<T> {
  _NoChange() : super._();
}

List<String> _defaultKeyTransformer(List<String> keys) => keys;
