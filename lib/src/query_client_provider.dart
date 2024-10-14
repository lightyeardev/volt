import 'package:flutter/cupertino.dart';
import 'package:volt/src/query_client.dart';

/// Provides a [VoltQueryClient] to the widget tree.
///
/// This is used to provide a [VoltQueryClient] to the widget tree. This is useful
/// for providing a [VoltQueryClient] to the [useQuery] hook.
class VoltQueryClientProvider extends InheritedWidget {
  final VoltQueryClient client;

  const VoltQueryClientProvider({
    super.key,
    required this.client,
    required super.child,
  });

  static VoltQueryClient of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<VoltQueryClientProvider>();
    return provider?.client ?? _defaultQueryClient;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    if (oldWidget is! VoltQueryClientProvider) {
      return true;
    }

    return oldWidget.client != client;
  }
}

final _defaultQueryClient = VoltQueryClient();
