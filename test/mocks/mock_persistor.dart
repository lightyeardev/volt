import 'package:rxdart/rxdart.dart';
import 'package:volt/volt.dart';

class InMemoryPersistor extends VoltPersistor {
  InMemoryPersistor();

  final Map<String, BehaviorSubject<VoltPersistorResult>> _cache = {};

  @override
  Stream<VoltPersistorResult<T>> listen<T>(String key, VoltQuery<T> query) {
    final subject = _cache.putIfAbsent(key, BehaviorSubject.new);

    return Rx.concat([
      if (!subject.hasValue) Stream.value(NoData<T>()),
      _cache[key]!.stream.cast<VoltPersistorResult<T>>(),
    ]);
  }

  @override
  Future<bool> put<T>(String key, VoltQuery<T> query, T dataObj, data) {
    _cache
        .putIfAbsent(key, BehaviorSubject.new)
        .add(HasData<T>(dataObj, DateTime.now(), query.scope));
    return Future.value(true);
  }
}
