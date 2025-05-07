import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

T useLifecycleAwareStream<T>(Stream<T> stream, {required T initialData}) =>
    use(_LifecyleAwareStreamHook<T>(stream, initialData: initialData, keys: [stream]));

class _LifecyleAwareStreamHook<T> extends Hook<T> {
  const _LifecyleAwareStreamHook(
    this.stream, {
    required this.initialData,
    super.keys,
  });

  final T initialData;
  final Stream stream;

  @override
  _DataStreamHookState<T> createState() => _DataStreamHookState<T>(initialData);
}

class _DataStreamHookState<T> extends HookState<T, _LifecyleAwareStreamHook<T>>
    with WidgetsBindingObserver {
  T _data;
  StreamSubscription? _subscription;
  bool hasEmitted = false;

  _DataStreamHookState(this._data);

  @override
  void initHook() {
    super.initHook();
    _subscribe();
  }

  @override
  void didUpdateHook(_LifecyleAwareStreamHook<T> oldHook) {
    super.didUpdateHook(oldHook);
    if (oldHook.stream != hook.stream) {
      if (_subscription != null) {
        _unsubscribe();
        if (!hasEmitted) _data = hook.initialData;
      }
      _subscribe();
    }
  }

  @override
  T build(BuildContext context) => _data;

  @override
  void dispose() {
    super.dispose();
    _unsubscribe();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final subscription = _subscription;
    if (subscription == null) return;
    if (state == AppLifecycleState.paused && !subscription.isPaused) {
      subscription.pause();
    } else if (state == AppLifecycleState.resumed && subscription.isPaused) {
      subscription.resume();
    }
  }

  void _unsubscribe() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _subscription = null;
  }

  void _subscribe() {
    _subscription = hook.stream.listen(
      (event) {
        hasEmitted = true;
        setState(() => _data = event);
      },
      cancelOnError: true,
    );
    WidgetsBinding.instance.addObserver(this);
  }
}
