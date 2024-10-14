import 'package:volt/volt.dart';

import 'mock_persistor.dart';

class MockQueryClient extends QueryClient {
  MockQueryClient() : super(persistor: InMemoryPersistor());
}
