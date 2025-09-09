import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

T useLifecycleAwareStream<T>(
  Stream<T> stream, {
  required T initialData,
  required bool keepPreviousData,
  void Function()? onResume,
}) {
  return use(_LifecyleAwareStreamHook<T>(
    stream,
    initialData: initialData,
    keepPreviousData: keepPreviousData,
    onResume: onResume,
  ));
}

class _LifecyleAwareStreamHook<T> extends Hook<T> {
  const _LifecyleAwareStreamHook(
    this.stream, {
    required this.initialData,
    required this.keepPreviousData,
    this.onResume,
    super.keys,
  });

  final T initialData;
  final bool keepPreviousData;
  final Stream stream;
  final void Function()? onResume;

  @override
  _DataStreamHookState<T> createState() => _DataStreamHookState<T>(initialData);
}

class _DataStreamHookState<T> extends HookState<T, _LifecyleAwareStreamHook<T>>
    with WidgetsBindingObserver {
  T _data;
  StreamSubscription? _subscription;

  _DataStreamHookState(this._data);

  @override
  void initHook() {
    super.initHook();
    _subscribe();
  }

  @override
  void didUpdateHook(_LifecyleAwareStreamHook<T> oldHook) {
    super.didUpdateHook(oldHook);
    if (identical(oldHook.stream, hook.stream)) return;

    if (_subscription != null) {
      _unsubscribe();
      if (hook.initialData != null && !identical(hook.initialData, _data) ||
          !hook.keepPreviousData) {
        setState(() => _data = hook.initialData);
      }
    }
    _subscribe();
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
      final callback = hook.onResume;
      if (callback != null) callback();
    }
  }

  void _unsubscribe() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _subscription = null;
  }

  void _subscribe() {
    _subscription = hook.stream.listen(
      (event) => setState(() => _data = event),
      cancelOnError: true,
    );
    WidgetsBinding.instance.addObserver(this);
  }
}
