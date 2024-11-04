import 'dart:async';

import 'package:volt/src/volt_listener.dart';

class ConflateStream {
  static final Map<String, _StreamWrapper> _streams = {};

  Stream<T> conflateByKey<T>(
    String key,
    StreamSubscription Function() createStream,
    VoltListener? listener,
  ) {
    late final StreamController<T> controller;
    controller = StreamController<T>(
      sync: true,
      onListen: () {
        bool conflated = true;

        final wrapper = _streams.putIfAbsent(
          key,
          () {
            conflated = false;
            return _StreamWrapper(createStream());
          },
        );

        if (conflated) {
          listener?.onRequestConflated();
        }

        wrapper.subscribed.add(controller);
      },
      onCancel: () {
        final registration = _streams[key]!;
        registration.subscribed.remove(controller);
        registration.paused.remove(controller);
        if (registration.subscribed.isEmpty) {
          registration.subscription.cancel();
          _streams.remove(key);
        }
      },
      onPause: () {
        final registration = _streams[key]!;
        registration.paused.add(controller);
        final allPaused = registration.paused.length == registration.subscribed.length;
        if (allPaused) {
          registration.subscription.pause();
        }
      },
      onResume: () {
        final registration = _streams[key]!;
        registration.paused.remove(controller);
        registration.subscription.resume();
      },
    );
    return controller.stream;
  }
}

class _StreamWrapper {
  final StreamSubscription subscription;
  final Set<StreamController> subscribed = {};
  final Set<StreamController> paused = {};

  _StreamWrapper(this.subscription);
}
