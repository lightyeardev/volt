import 'package:volt/volt.dart';

import 'mock_persistor.dart';

class MockQueryClient extends VoltQueryClient {
  MockQueryClient() : super(persistor: InMemoryPersistor());
}
