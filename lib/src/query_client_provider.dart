import 'package:flutter/cupertino.dart';
import 'package:volt/src/query_client.dart';

/// Provides a [QueryClient] to the widget tree.
///
/// This is used to provide a [QueryClient] to the widget tree. This is useful
/// for providing a [QueryClient] to the [useQuery] hook.
class QueryClientProvider extends InheritedWidget {
  final QueryClient client;

  const QueryClientProvider({
    super.key,
    required this.client,
    required super.child,
  });

  static QueryClient of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<QueryClientProvider>();
    if (provider == null) {
      throw Exception('No QueryClientProvider found in context');
    }
    return provider.client;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    if (oldWidget is! QueryClientProvider) {
      return true;
    }

    return oldWidget.client != client;
  }
}
