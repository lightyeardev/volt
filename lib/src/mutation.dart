import 'package:flutter/widgets.dart';

class VoltMutation<T> {
  final Future<bool> Function(T params) mutationFn;
  final void Function(T? params)? _onSuccess;
  final void Function(T? params)? _onError;
  final ValueNotifier<VoltMutationState> _state;

  VoltMutation({
    required this.mutationFn,
    void Function(T?)? onSuccess,
    void Function(T?)? onError,
    required ValueNotifier<VoltMutationState> state,
  })  : _onSuccess = onSuccess,
        _onError = onError,
        _state = state;

  Future<bool> mutate(T params) async {
    assert(_state.value.isPending, 'Mutation is already in progress');

    if (_state.value.isPending) return false;

    _state.value = const VoltMutationState(isPending: true);

    try {
      final success = await mutationFn(params);
      if (success) {
        _onSuccess?.call(params);
      } else {
        _onError?.call(params);
      }
      _state.value = VoltMutationState(isPending: false, isSuccess: success);
      return success;
    } catch (error) {
      _state.value = const VoltMutationState(isPending: false, isError: true);
      _onError?.call(params);
      return false;
    } finally {
      _state.value = const VoltMutationState(isPending: false);
    }
  }

  VoltMutationState get state => _state.value;

  void reset() => _state.value = const VoltMutationState(isPending: false);
}

class VoltMutationState {
  final bool isPending;
  final bool isSuccess;
  final bool isError;

  const VoltMutationState({
    this.isPending = false,
    this.isSuccess = false,
    this.isError = false,
  });
}
