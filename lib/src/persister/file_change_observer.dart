import 'package:rxdart/rxdart.dart';

class FileChangeObserver {
  static final Map<String, PublishSubject<Void?>> listeners = {};

  Stream<Void?> watch<T>(String fileName) => _getSubject(fileName);

  void onFileChanged<T>(String fileName) => _getSubject(fileName).add(null);

  PublishSubject<Void?> _getSubject(String fileName) {
    listeners.putIfAbsent(fileName, PublishSubject.new);
    return listeners[fileName]!;
  }
}

abstract class Void {}
