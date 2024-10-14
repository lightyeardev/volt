import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:volt/volt.dart';

/// Returns the [QueryClient] instance from the nearest [QueryClientProvider] ancestor.
///
/// This hook allows access to the [QueryClient] within a Flutter widget using hooks.
/// It retrieves the client from the widget tree context for query operations.
///
/// Throws an error if no [QueryClientProvider] ancestor is found.
QueryClient useQueryClient() {
  final context = useContext();

  return QueryClientProvider.of(context);
}
