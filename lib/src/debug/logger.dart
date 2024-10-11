import 'package:flutter/foundation.dart';

abstract class Logger {
  void logError(Object error, {StackTrace? stackTrace});

  void logInfo(Object info, {StackTrace? stackTrace});
}

class StdOutLogger implements Logger {
  const StdOutLogger();

  @override
  void logError(Object error, {StackTrace? stackTrace}) {
    if (kDebugMode) {
      print('Volt error: $error');

      if (stackTrace != null) {
        print(stackTrace);
      }
    }
  }

  @override
  void logInfo(Object info, {StackTrace? stackTrace}) {
    if (kDebugMode) {
      print('Volt info: $info');

      if (stackTrace != null) {
        print(stackTrace);
      }
    }
  }
}

class NoOpLogger implements Logger {
  const NoOpLogger();

  @override
  void logError(Object error, {StackTrace? stackTrace}) {}

  @override
  void logInfo(Object info, {StackTrace? stackTrace}) {}
}
