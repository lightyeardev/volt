import 'package:flutter/widgets.dart';

class VoltMutation<T> {
  final Future<bool> Function(T params) mutationFn;
  final void Function(T? params)? onSuccess;
  final void Function(T? params)? onError;
  final ValueNotifier<bool> _isLoading;

  VoltMutation({
    required this.mutationFn,
    this.onSuccess,
    this.onError,
    required ValueNotifier<bool> isLoading,
  }) : _isLoading = isLoading;

  Future<bool> mutate(T params) async {
    assert(_isLoading.value, 'Mutation is already in progress');

    if (_isLoading.value) return false;

    _isLoading.value = true;

    try {
      final success = await mutationFn(params);
      if (success) {
        onSuccess?.call(params);
      } else {
        onError?.call(params);
      }
      return success;
    } catch (error) {
      onError?.call(params);
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  bool get isLoading => _isLoading.value;

  void reset() => _isLoading.value = false;
}
