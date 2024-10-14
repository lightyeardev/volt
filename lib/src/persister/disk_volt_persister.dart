import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:volt/src/debug/volt_stats.dart';
import 'package:volt/src/persister/file_change_observer.dart';
import 'package:volt/src/persister/key_lock.dart';
import 'package:volt/src/persister/lru_cache.dart';
import 'package:volt/src/persister/persister.dart';
import 'package:volt/src/query.dart';

class FileVoltPersistor implements VoltPersistor {
  final FileChangeObserver observer = FileChangeObserver();
  final LruCache<String, HasData> cache = LruCache(
    200,
    VoltStats.setMemoryCacheCurrentSize,
    VoltStats.incrementMemoryCacheEvictions,
  );
  static final lock = KeyedLock();

  @override
  Stream<VoltPersistorResult<T>> listen<T>(String key, VoltQuery<T> query) {
    final relativePath = _getRelativeFilePathWithFileName(key, query.scope);
    return Rx.concat(
      [
        Stream.fromFuture(_readFile(
          relativePath,
          query.scope,
          query.select,
          query.disableDiskCache,
        )),
        observer.watch(relativePath).asyncMap((value) => _readFile(
              relativePath,
              query.scope,
              query.select,
              query.disableDiskCache,
              reportStats: false,
            )),
      ],
    );
  }

  @override
  Future<bool> put<T>(
    String key,
    VoltQuery<T> query,
    T dataObj,
    dynamic dataJson,
  ) async {
    final timestamp = DateTime.now().toUtc();
    final data = HasData(dataObj, timestamp, query.scope);
    final relativePath = _getRelativeFilePathWithFileName(key, query.scope);

    final record = (cache[relativePath], data);
    final useCompute = query.useComputeIsolate && !kDebugMode;
    final equals = useCompute ? await compute(_deepEquals, record) : _deepEquals(record);

    cache[relativePath] = data;

    if (equals) {
      unawaited(
        _writeMetadataFile(
          relativePath,
          data,
          query.disableDiskCache,
          query,
        ),
      );
      return false;
    }

    unawaited(
      _writeFile<T>(
        relativePath,
        dataJson,
        data,
        query.disableDiskCache,
        query,
      ),
    );
    observer.onFileChanged(relativePath);

    return true;
  }

  static bool _deepEquals<T>((Object?, T) record) =>
      const DeepCollectionEquality().equals(record.$1, record.$2);

  Future<void> _writeFile<T>(
    String relativePath,
    Object? json,
    HasData<T> data,
    bool disableDiskCache,
    VoltQuery query,
  ) async {
    if (disableDiskCache) {
      return;
    }

    await lock.synchronized(relativePath, () async {
      final file = await _getFile(relativePath, 'json');
      if (!(await file.exists())) {
        await file.create(recursive: true);
      }

      await Stream.value(json)
          .transform(const JsonEncoder().fuse(const Utf8Encoder()))
          .pipe(file.openWrite());

      await _writeMetadataFile(
        relativePath,
        data,
        disableDiskCache,
        query,
      );
    });
  }

  Future<void> _writeMetadataFile(
    String relativePath,
    HasData<dynamic> data,
    bool disableDiskCache,
    VoltQuery query,
  ) async {
    if (disableDiskCache) {
      return;
    }

    final metadataFile = await _getFile(relativePath, 'metadata');
    if (!(await metadataFile.exists())) {
      await metadataFile.create(recursive: true);
    }
    await metadataFile.writeAsString(jsonEncode({
      'queryKey': query.queryKey,
      'timestamp': data.timestamp.toIso8601String(),
    }));
  }

  Future<VoltPersistorResult<T>> _readFile<T>(
    String relativePath,
    String? scope,
    T Function(dynamic) deserialiser,
    bool disableDiskCache, {
    bool reportStats = true,
  }) async {
    return await lock.synchronized(relativePath, () async {
      final cachedItem = cache[relativePath];
      if (cachedItem != null) {
        if (reportStats) VoltStats.incrementMemoryCacheHits();
        return cachedItem as HasData<T>;
      }
      if (reportStats) VoltStats.incrementMemoryCacheMisses();

      if (disableDiskCache) {
        return NoData();
      }

      final dataFile = await _getFile(relativePath, 'json');
      final metadataFile = await _getFile(relativePath, 'metadata');
      try {
        if (!(await dataFile.exists())) {
          if (reportStats) VoltStats.incrementDiskCacheMisses();
          return NoData();
        }
        if (reportStats) VoltStats.incrementDiskCacheHits();

        final dynamicData = (await dataFile
            .openRead()
            .transform(const Utf8Decoder().fuse(const JsonDecoder()))
            .first);

        final metadataString = await metadataFile.readAsString();
        final jsonMetadata = jsonDecode(metadataString);

        final T data = deserialiser(dynamicData);
        final timestamp = DateTime.parse(jsonMetadata['timestamp']);
        final hasData = HasData<T>(data, timestamp, scope);

        cache[relativePath] = hasData;

        return hasData;
      } catch (e, _) {
        await dataFile.deleteSafely();
        await metadataFile.deleteSafely();
        cache.remove(relativePath);

        return NoData();
      }
    });
  }

  Future<File> _getFile(String relativePath, String extension) async {
    return File('${await _getSafeApplicationDirectoryPath()}/$relativePath.$extension');
  }

  String _getRelativeFilePathWithFileName(String key, String? scope) {
    return '${_getRelativeBucketPath(scope)}$key';
  }

  static String _getRelativeBucketPath(String? scope) {
    return 'persistor/${scope?.toLowerCase() ?? '_global'}/';
  }

  Future<void> clear(List<String?> scopes) async {
    await Future.wait(
      scopes.map(
        (scope) async {
          await _clearDirectory(scope);
          _clearCache(scope);
        },
      ),
    );
  }

  void _clearCache(String? scope) {
    cache.forEach((key, value) {
      if (value.scope == scope) {
        cache.remove(key);
      }
    });
  }

  static Future<String> _getSafeApplicationDirectoryPath() async =>
      (await getApplicationSupportDirectory()).path.replaceAll(' ', '\\ ');

  static Future<void> _clearDirectory(String? scope) async {
    final appDirectory = await _getSafeApplicationDirectoryPath();
    final directory = Directory('$appDirectory/${_getRelativeBucketPath(scope)}');
    await directory.deleteSafely();
  }
}

extension _FileSystemEntityEx on FileSystemEntity {
  Future<FileSystemEntity?> deleteSafely() async {
    try {
      if (await exists()) return await delete(recursive: true);
    } catch (_) {
      // ignore
    }
    return null;
  }
}
