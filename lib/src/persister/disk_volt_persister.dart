import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:disk_space_2/disk_space_2.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:volt/src/persister/file_change_observer.dart';
import 'package:volt/src/persister/key_lock.dart';
import 'package:volt/src/persister/lru_cache.dart';
import 'package:volt/src/persister/persister.dart';
import 'package:volt/src/query.dart';
import 'package:volt/src/volt_listener.dart';

class FileVoltPersistor implements VoltPersistor {
  final FileChangeObserver observer = FileChangeObserver();
  final VoltListener? listener;
  double? _diskSpaceMemo;
  late final LruCache<String, HasData> cache = LruCache(
    200,
    listener?.onMemoryCacheSizeChanged,
    listener?.onMemoryCacheEviction,
  );
  static final lock = KeyedLock();
  FileVoltPersistor({this.listener});

  @override
  Stream<VoltPersistorResult<T>> listen<T>(String keyHash, VoltQuery<T> query) {
    final relativePath = _getRelativeFilePathWithFileName(keyHash, query.scope);
    return Rx.concat([
      Stream.fromFuture(_readFile(relativePath, query)),
      observer
          .watch(relativePath)
          .asyncMap((_) => _readFile(relativePath, query, reportStats: false)),
    ]);
  }

  @override
  Future<bool> put<T>(String keyHash, VoltQuery<T> query, T dataObj, dynamic dataJson) async {
    final timestamp = DateTime.now().toUtc();
    final data = HasData(dataObj, timestamp, query.scope);
    final relativePath = _getRelativeFilePathWithFileName(keyHash, query.scope);

    final record = (cache[relativePath], data);
    final useCompute = query.useComputeIsolate && !kDebugMode;
    final equals = useCompute ? await compute(_deepEquals, record) : _deepEquals(record);

    cache[relativePath] = data;

    if (equals) {
      unawaited(_writeMetadataFile(relativePath, data, query));
      return false;
    }

    unawaited(_writeFile<T>(relativePath, dataJson, data, query));
    observer.onFileChanged(relativePath);

    return true;
  }

  @override
  VoltPersistorResult<T> peak<T>(String key, VoltQuery<T> query) {
    final relativePath = _getRelativeFilePathWithFileName(key, query.scope);
    final cachedItem = cache[relativePath];

    if (cachedItem == null) return NoData<T>();

    return cachedItem as HasData<T>;
  }

  @override
  Future<void> clearScope(String? scope) async {
    await _clearDirectory(scope);
    _clearCache(scope);
  }

  @override
  Future<void> clearAll() async {
    final appDirectory = await _getSafeApplicationDirectoryPath();
    final directory = Directory('$appDirectory/persistor');
    await directory.deleteSafely();
    cache.evictAll();
  }

  static bool _deepEquals<T>((Object?, T) record) =>
      const DeepCollectionEquality().equals(record.$1, record.$2);

  Future<void> _writeFile<T>(
    String relativePath,
    Object? json,
    HasData<T> data,
    VoltQuery query,
  ) async {
    if (query.disableDiskCache || !(await hasEnoughDiskSpace)) {
      return;
    }

    await lock.synchronized(relativePath, () async {
      final file = await _getFile(relativePath, 'json');
      if (!(await file.exists())) {
        await file.create(recursive: true);
      }

      await Stream.value(
        json,
      ).transform(const JsonEncoder().fuse(const Utf8Encoder())).pipe(file.openWrite());

      await _writeMetadataFileUnlocked(relativePath, data, query);
    });
  }

  Future<void> _writeMetadataFile(
    String relativePath,
    HasData<dynamic> data,
    VoltQuery query,
  ) async {
    if (query.disableDiskCache) {
      return;
    }

    await lock.synchronized(
        relativePath, () => _writeMetadataFileUnlocked(relativePath, data, query));
  }

  Future<void> _writeMetadataFileUnlocked(
    String relativePath,
    HasData<dynamic> data,
    VoltQuery query,
  ) async {
    final metadataFile = await _getFile(relativePath, 'metadata');
    if (!(await metadataFile.exists())) {
      await metadataFile.create(recursive: true);
    }
    await metadataFile.writeAsString(
      jsonEncode({
        'queryKey': query.queryKey,
        'timestamp': data.timestamp.toIso8601String(),
        'staleDurationMs': query.staleDuration?.inMilliseconds,
      }),
    );
  }

  Future<VoltPersistorResult<T>> _readFile<T>(
    String relativePath,
    VoltQuery query, {
    bool reportStats = true,
  }) async {
    final scope = query.scope;
    final deserialiser = query.select;
    final disableDiskCache = query.disableDiskCache;

    return await lock.synchronized(relativePath, () async {
      final cachedItem = cache[relativePath];
      if (cachedItem != null) {
        if (reportStats) listener?.onMemoryCacheHit();
        return cachedItem as HasData<T>;
      }
      if (reportStats) listener?.onMemoryCacheMiss();

      if (disableDiskCache || !(await hasEnoughDiskSpace)) {
        return NoData();
      }

      final dataFile = await _getFile(relativePath, 'json');
      final metadataFile = await _getFile(relativePath, 'metadata');
      try {
        if (!(await dataFile.exists())) {
          if (reportStats) listener?.onDiskCacheMiss();
          return NoData();
        }
        if (reportStats) listener?.onDiskCacheHit();

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
      scopes.map((scope) async {
        await _clearDirectory(scope);
        _clearCache(scope);
      }),
    );
  }

  void _clearCache(String? scope) {
    final keysToRemove = <String>[];
    cache.forEach((key, value) {
      if (value.scope == scope) {
        keysToRemove.add(key);
      }
    });
    for (final key in keysToRemove) {
      cache.remove(key);
    }
  }

  static Future<int> evictStaleFiles({Duration maxAge = const Duration(days: 7)}) async {
    final appDirectory = await _getSafeApplicationDirectoryPath();
    final persistorDir = Directory('$appDirectory/persistor');
    if (!await persistorDir.exists()) return 0;

    int deletedCount = 0;
    final now = DateTime.now().toUtc();

    await for (final entity in persistorDir.list(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.metadata')) continue;

      final relativePath = _getRelativePathForMetadataFile(appDirectory, entity.path);
      await lock.synchronized(relativePath, () async {
        if (!await entity.exists()) {
          return;
        }

        try {
          final content = await entity.readAsString();
          final json = jsonDecode(content);
          final timestamp = DateTime.parse(json['timestamp']);
          final fileStaleDuration = json['staleDurationMs'] != null
              ? Duration(milliseconds: json['staleDurationMs'])
              : Duration.zero;
          final effectiveMaxAge = maxAge > fileStaleDuration ? maxAge : fileStaleDuration;
          final cutoff = now.subtract(effectiveMaxAge);

          if (timestamp.isBefore(cutoff)) {
            await _deletePersistedFiles(entity);
            deletedCount++;
          }
        } catch (_) {
          await _deletePersistedFiles(entity);
          deletedCount++;
        }
      });
    }

    return deletedCount;
  }

  static Future<void> _deletePersistedFiles(File metadataFile) async {
    await File(_swapFileExtension(metadataFile.path, from: 'metadata', to: 'json')).deleteSafely();
    await metadataFile.deleteSafely();
  }

  static String _getRelativePathForMetadataFile(String appDirectory, String metadataPath) {
    final prefix = '$appDirectory/';
    final relativeMetadataPath =
        metadataPath.startsWith(prefix) ? metadataPath.substring(prefix.length) : metadataPath;
    const suffix = '.metadata';

    if (relativeMetadataPath.endsWith(suffix)) {
      return relativeMetadataPath.substring(0, relativeMetadataPath.length - suffix.length);
    }

    return relativeMetadataPath;
  }

  static String _swapFileExtension(
    String path, {
    required String from,
    required String to,
  }) {
    final fromSuffix = '.$from';
    if (!path.endsWith(fromSuffix)) {
      return path;
    }

    return '${path.substring(0, path.length - fromSuffix.length)}.$to';
  }

  Future<bool> get hasEnoughDiskSpace async {
    _diskSpaceMemo ??= await DiskSpace.getFreeDiskSpace;

    return _diskSpaceMemo != null && _diskSpaceMemo! > 1024; // 1GB
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
