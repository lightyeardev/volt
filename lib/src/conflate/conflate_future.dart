import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:volt/src/volt_listener.dart';

class ConflateFuture {
  static final Map<String, BehaviorSubject<dynamic>> _subjects = {};

  Future<dynamic> conflateByKey(
    String key,
    Future<dynamic> Function() source,
    VoltListener? listener,
  ) {
    bool conflated = true;
    final subject = _subjects.putIfAbsent(
      key,
      () {
        conflated = false;
        final subject = BehaviorSubject<dynamic>();
        source()
            .then(subject.add, onError: subject.addError)
            .whenComplete(() => _subjects.remove(key));

        return subject;
      },
    );

    if (conflated) {
      listener?.onRequestConflated();
    }

    return subject.first;
  }
}
