import 'package:flutter/widgets.dart';

class VoltMutation<D, P> {
  final Future<bool> Function(P variables) mutationFn;
  final void Function(P? variables)? onSuccess;
  final void Function(P? variables)? onError;
  final ValueNotifier<bool> _isLoading;

  VoltMutation({
    required this.mutationFn,
    this.onSuccess,
    this.onError,
    required ValueNotifier<bool> isLoading,
  }) : _isLoading = isLoading;

  Future<bool> mutate(P params) async {
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
