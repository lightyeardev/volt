import 'package:volt/src/query.dart';

abstract class VoltPersistor {
  Stream<VoltPersistorResult<T>> listen<T>(
    String key,
    VoltQuery<T> query,
  );

  Future<bool> put<T>(
    String key,
    VoltQuery<T> query,
    T dataObj,
    dynamic data,
  );

  Future<void> clearScope(String? scope);
}

sealed class VoltPersistorResult<T> {}

class NoData<T> extends VoltPersistorResult<T> {
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is NoData<T> && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;
}

class HasData<T> extends VoltPersistorResult<T> {
  HasData(this.data, this.timestamp, this.scope);

  final T data;
  final DateTime timestamp;
  final String? scope;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HasData<T> &&
          runtimeType == other.runtimeType &&
          data == other.data &&
          timestamp == other.timestamp &&
          scope == other.scope;

  @override
  int get hashCode => data.hashCode ^ timestamp.hashCode ^ scope.hashCode;
}
