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

  @override
  Future<void> clearScope(String? scope) async {
    _cache.removeWhere((key, value) {
      final result = value.hasValue ? value.value : null;
      final itemScope = result is HasData ? result.scope : null;

      return itemScope == scope;
    });
  }

  @override
  VoltPersistorResult<T> peak<T>(String key, VoltQuery<T> query) {
    final data = _cache[key]?.value;
    if (data is HasData<T>) return data;

    return NoData<T>();
  }
}
