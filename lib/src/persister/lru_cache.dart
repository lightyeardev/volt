/// A basic LRU Cache.
///
/// source: https://github.com/dart-lang/build/blob/master/build_runner_core/lib/src/asset/lru_cache.dart
class LruCache<K, V> {
  _Link<K, V>? _head;
  _Link<K, V>? _tail;

  final void Function(int)? _onSizeChanged;
  final void Function()? _onEntryEvicted;

  int _currentItemsTotal = 0;
  final int _totalMaxItems;

  final _entries = <K, _Link<K, V>>{};

  LruCache(
    this._totalMaxItems,
    this._onSizeChanged,
    this._onEntryEvicted,
  );

  V? operator [](K key) {
    var entry = _entries[key];
    if (entry == null) return null;

    _promote(entry);
    return entry.value;
  }

  void operator []=(K key, V value) {
    var entry = _Link(key, value, 1);
    // Don't cache at all if above the individual weight max.

    remove(key);

    _entries[key] = entry;
    _currentItemsTotal += entry.weight;
    _promote(entry);

    _onSizeChanged?.call(_currentItemsTotal);

    while (_currentItemsTotal > _totalMaxItems) {
      remove(_tail!.key);
      _onEntryEvicted?.call();
    }
  }

  void forEach(void Function(K key, V value) f) {
    var current = _head;
    while (current != null) {
      f(current.key, current.value);
      current = current.previous;
    }
  }

  /// Removes the value at [key] from the cache, and returns the value if it
  /// existed.
  V? remove(K key) {
    var entry = _entries[key];
    if (entry == null) return null;

    _currentItemsTotal -= entry.weight;
    _entries.remove(key);

    if (entry == _tail) {
      _tail = entry.next;
      _tail?.previous = null;
    } else if (entry == _head) {
      _head = entry.previous;
      _head?.next = null;
    } else {
      entry.remove();
    }

    _onSizeChanged?.call(_currentItemsTotal);

    return entry.value;
  }

  int get length => _entries.length;

  int get maxLength => _totalMaxItems;

  void evictAll() {
    _head = null;
    _tail = null;
    _currentItemsTotal = 0;
    _entries.clear();
  }

  /// Moves [link] to the [_head] of the list.
  void _promote(_Link<K, V> link) {
    if (link == _head) return;

    if (link == _tail) {
      _tail = link.next;
    }

    if (link.previous != null) {
      link.previous!.next = link.next;
    }
    if (link.next != null) {
      link.next!.previous = link.previous;
    }

    _head?.next = link;
    link.previous = _head;
    _head = link;
    _tail ??= link;
    link.next = null;
  }
}

/// A [MapEntry] which is also a part of a doubly linked list.
class _Link<K, V> implements _CustomMapEntry<K, V> {
  _Link<K, V>? next;
  _Link<K, V>? previous;

  final int weight;

  @override
  final K key;

  @override
  final V value;

  _Link(this.key, this.value, this.weight);

  void remove() {
    previous?.next = next;
    next?.previous = previous;
  }
}

class _CustomMapEntry<K, V> {
  final K key;
  final V value;

  const factory _CustomMapEntry(K key, V value) = _CustomMapEntry<K, V>._;

  const _CustomMapEntry._(this.key, this.value);
}
