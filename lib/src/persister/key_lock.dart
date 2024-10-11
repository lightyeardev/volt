import 'dart:async';

import 'package:synchronized/synchronized.dart';

class KeyedLock {
  static final Map<String, LockCounter> locks = {};

  Future<T> synchronized<T>(String key, FutureOr<T> Function() computation) async {
    final wrapper = locks.putIfAbsent(key, LockCounter.new);

    wrapper.watchers++;
    try {
      return await wrapper.lock.synchronized(computation);
    } finally {
      wrapper.watchers--;
      if (wrapper.watchers == 0) {
        locks.remove(key);
      }
    }
  }
}

class LockCounter {
  final Lock lock = Lock();
  int watchers = 0;
}
