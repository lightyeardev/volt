import 'package:volt/volt.dart';

/// A listener for query events in Volt
abstract class VoltListener {
  /// Called when a memory cache hit occurs
  void onMemoryCacheHit() {}

  /// Called when a memory cache miss occurs
  void onMemoryCacheMiss() {}

  /// Called when an item is evicted from memory cache
  void onMemoryCacheEviction() {}

  /// Called when memory cache size changes
  void onMemoryCacheSizeChanged(int size) {}

  /// Called when a disk cache hit occurs
  void onDiskCacheHit() {}

  /// Called when a disk cache miss occurs
  void onDiskCacheMiss() {}

  /// Called when a network request succeeds
  void onNetworkHit() {}

  /// Called when a network request fails
  void onNetworkError() {}

  /// Called when deserialization fails
  void onDeserializationError() {}

  /// Called when requests are conflated
  void onRequestConflated() {}

  /// Called when select is invoked
  void onQuerySelect(VoltQuery query, Duration duration) {}
}