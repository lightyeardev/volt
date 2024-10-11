import 'package:flutter/foundation.dart';

class VoltStats {
  static final ValueNotifier<VoltStats> _stats = ValueNotifier(const VoltStats());
  
  final bool enabled;

  final int memoryCacheHits;
  final int memoryCacheMisses;
  final int memoryCacheEvictions;
  final int memoryCacheCurrentSize;

  final int diskCacheHits;
  final int diskCacheMisses;

  final int networkHits;
  final int networkErrors;

  final int deserializationErrors;

  final int conflatedRequests;

  const VoltStats({
    this.enabled = false,
    this.memoryCacheHits = 0,
    this.memoryCacheMisses = 0,
    this.memoryCacheEvictions = 0,
    this.memoryCacheCurrentSize = 0,
    this.diskCacheHits = 0,
    this.diskCacheMisses = 0,
    this.networkHits = 0,
    this.networkErrors = 0,
    this.deserializationErrors = 0,
    this.conflatedRequests = 0,
  });

  VoltStats copyWith({
    bool? enabled,
    int? memoryCacheHits,
    int? memoryCacheMisses,
    int? memoryCacheEvictions,
    int? memoryCacheCurrentSize,
    int? diskCacheHits,
    int? diskCacheMisses,
    int? networkHits,
    int? networkErrors,
    int? deserializationErrors,
    int? activeStreams,
    int? conflatedRequests,
  }) {
    return VoltStats(
      enabled: enabled ?? this.enabled,
      memoryCacheHits: memoryCacheHits ?? this.memoryCacheHits,
      memoryCacheMisses: memoryCacheMisses ?? this.memoryCacheMisses,
      memoryCacheEvictions: memoryCacheEvictions ?? this.memoryCacheEvictions,
      memoryCacheCurrentSize: memoryCacheCurrentSize ?? this.memoryCacheCurrentSize,
      diskCacheHits: diskCacheHits ?? this.diskCacheHits,
      diskCacheMisses: diskCacheMisses ?? this.diskCacheMisses,
      networkHits: networkHits ?? this.networkHits,
      networkErrors: networkErrors ?? this.networkErrors,
      deserializationErrors: deserializationErrors ?? this.deserializationErrors,
      conflatedRequests: conflatedRequests ?? this.conflatedRequests,
    );
  }

  Map<String, int> toMap() {
    return {
      'memoryCacheHits': memoryCacheHits,
      'memoryCacheMisses': memoryCacheMisses,
      'memoryCacheEvictions': memoryCacheEvictions,
      'memoryCacheCurrentSize': memoryCacheCurrentSize,
      'diskCacheHits': diskCacheHits,
      'diskCacheMisses': diskCacheMisses,
      'networkHits': networkHits,
      'networkErrors': networkErrors,
      'deserializationErrors': deserializationErrors,
      'conflatedRequests': conflatedRequests,
    };
  }

  static ValueListenable<VoltStats> get listenable => _stats;

  static void incrementMemoryCacheHits() {
    if (!_stats.value.enabled) return;

    _stats.value = _stats.value.copyWith(
      memoryCacheHits: _stats.value.memoryCacheHits + 1,
    );
  }

  static void incrementMemoryCacheMisses() {
    if (!_stats.value.enabled) return;

    _stats.value = _stats.value.copyWith(
      memoryCacheMisses: _stats.value.memoryCacheMisses + 1,
    );
  }

  static void incrementMemoryCacheEvictions() {
    if (!_stats.value.enabled) return;

    _stats.value = _stats.value.copyWith(
      memoryCacheEvictions: _stats.value.memoryCacheEvictions + 1,
    );
  }

  static void setMemoryCacheCurrentSize(int size) {
    if (!_stats.value.enabled) return;

    _stats.value = _stats.value.copyWith(
      memoryCacheCurrentSize: _stats.value.memoryCacheCurrentSize,
    );
  }

  static void incrementDiskCacheHits() {
    if (!_stats.value.enabled) return;

    _stats.value = _stats.value.copyWith(
      diskCacheHits: _stats.value.diskCacheHits + 1,
    );
  }

  static void incrementDiskCacheMisses() {
    if (!_stats.value.enabled) return;

    _stats.value = _stats.value.copyWith(
      diskCacheMisses: _stats.value.diskCacheMisses + 1,
    );
  }

  static void incrementNetworkHits() {
    if (!_stats.value.enabled) return;

    _stats.value = _stats.value.copyWith(
      networkHits: _stats.value.networkHits + 1,
    );
  }

  static void incrementNetworkMisses() {
    if (!_stats.value.enabled) return;

    _stats.value = _stats.value.copyWith(
      networkErrors: _stats.value.networkErrors + 1,
    );
  }

  static void incrementDeserializationErrors() {
    if (!_stats.value.enabled) return;

    _stats.value = _stats.value.copyWith(
      deserializationErrors: _stats.value.deserializationErrors + 1,
    );
  }

  static void incrementConflatedRequests() {
    if (!_stats.value.enabled) return;

    _stats.value = _stats.value.copyWith(conflatedRequests: _stats.value.conflatedRequests + 1);
  }

  static void reset() {
    if (!_stats.value.enabled) return;

    _stats.value = const VoltStats();
  }
}
