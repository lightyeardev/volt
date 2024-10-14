import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:volt/src/conflate/conflate_future.dart';
import 'package:volt/src/conflate/conflate_stream.dart';
import 'package:volt/src/debug/logger.dart';
import 'package:volt/src/debug/volt_stats.dart';
import 'package:volt/src/persister/disk_volt_persister.dart';
import 'package:volt/src/persister/persister.dart';
import 'package:volt/src/query.dart';

class QueryClient {
  static const _minRetrySecondDuration = 4;
  static const _maxRetrySecondDuration = Duration.secondsPerMinute * 5;

  QueryClient({
    this.keyTransformer = _defaultKeyTransformer,
    VoltPersistor? persistor,
    this.staleDuration = const Duration(hours: 1),
    this.isDebug = false,
  })  : persistor = persistor ?? FileVoltPersistor(),
        _logger = isDebug ? const StdOutLogger() : const NoOpLogger() {
    if (isDebug) {
      VoltStats.enable();
    }
  }

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
    final key = _toStableKey(query);
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

  Future<bool> prefetchQuery<T>(VoltQuery<T> query) async {
    final key = _toStableKey(query);

    return await _sourceAndPersist(key, query) is! _Failure<T>;
  }

  Future<T> fetchQueryOrThrow<T>(VoltQuery<T> query) async {
    final key = _toStableKey(query);

    final (data, _) = await _sourceAndPersistOrThrow(key, query);
    return data;
  }

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
      VoltStats.incrementNetworkMisses();
      if (kDebugMode) {
        _logger.logInfo(
          'Failed to fetch from queryFn: $key',
          stackTrace: stackTrace,
        );
      }
      return _Failure(e);
    }
  }

  Future<(T, bool)> _sourceAndPersistOrThrow<T>(String key, VoltQuery<T> query) async {
    return await _conflateFuture.conflateByKey(key, () async {
      var json = await query.queryFn();
      VoltStats.incrementNetworkHits();
      // deserialize it before persisting it, in case source returns something unexpected
      final dynamic data;
      try {
        final useCompute = query.useComputeIsolate && !kDebugMode;
        data = useCompute ? await compute(query.select, json) : query.select(json);
      } catch (error, stackTrace) {
        VoltStats.incrementDeserializationErrors();
        if (isDebug) {
          _logger.logInfo('Failed to deserialize data from source: $json', stackTrace: stackTrace);
        } else {
          _logger.logInfo(error, stackTrace: stackTrace);
        }
        rethrow;
      }

      final persisted = await persistor.put<T>(key, query, data as T, json);
      return (data, persisted);
    });
  }

  String _toStableKey<T>(VoltQuery<T> query) =>
      sha256.convert(utf8.encode(keyTransformer(query.queryKey).join(','))).toString();
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
