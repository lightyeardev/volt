import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:volt/volt.dart';

import 'mocks/mock_query_client.dart';

void main() {
  test(
      'when cache is empty, streamQuery emits the result of the query function',
      () async {
    final randomNumber = Random().nextInt(100);
    final client = MockQueryClient();
    final query = VoltQuery(
      queryKey: ['test'],
      queryFn: () async => randomNumber,
      select: (d) => d,
    );

    final stream = client.streamQuery(query);

    await expectLater(
      stream,
      emits(randomNumber),
    );
  });

  test('when cache is not empty, streamQuery emits the cached value', () async {
    final randomNumber = Random().nextInt(100);
    final client = MockQueryClient();
    final query = VoltQuery(
      queryKey: ['test'],
      queryFn: () async => randomNumber,
      select: (d) => d,
    );

    await client.prefetchQuery(query);

    final stream = client.streamQuery(query);

    await expectLater(
      stream,
      emits(randomNumber),
    );
  });

  test(
      'when cache is stale, streamQuery emits the result of the query function',
      () async {
    final randomNumber1 = Random().nextInt(10000);
    final randomNumber2 = Random().nextInt(10000);
    final client = MockQueryClient();
    final setupQuery = VoltQuery(
      queryKey: ['test'],
      queryFn: () async => randomNumber1,
      select: (d) => d,
    );
    await client.prefetchQuery(setupQuery);

    final actualQuery = VoltQuery(
      queryKey: ['test'],
      queryFn: () async => randomNumber2,
      select: (d) => d,
      staleDuration: Duration.zero,
    );

    final stream = client.streamQuery(actualQuery);

    await expectLater(
      stream,
      emitsInOrder([randomNumber1, randomNumber2]),
    );
  });

  test(
      'when select function throws an exception, streamQuery reloads data from queryFn without emitting an error',
      () async {
    final randomNumber = Random().nextInt(100);
    final client = MockQueryClient();
    var selectCallCount = 0;
    var queryFnCallCount = 0;
    final query = VoltQuery(
      queryKey: ['test'],
      queryFn: () async {
        queryFnCallCount++;
        return randomNumber;
      },
      select: (d) {
        selectCallCount++;
        if (selectCallCount == 1) {
          throw Exception('Select error');
        }
        return d;
      },
    );

    final stream = client.streamQuery(query);

    await expectLater(
      stream,
      emits(randomNumber),
    );

    expect(selectCallCount, 2);
    expect(queryFnCallCount, 2);
  });
}
