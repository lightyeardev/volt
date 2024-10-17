import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:volt/volt.dart';

import 'mocks/mock_query_client.dart';

void main() {
  test('when cache is empty, streamQuery emits the result of the query function', () async {
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

  test('when cache is stale, streamQuery emits the result of the query function', () async {
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

  test('invalidateScope clears the cache for the given scope', () async {
    final client = MockQueryClient();
    var result = 0;
    final query = VoltQuery(
      queryKey: ['test'],
      queryFn: () async => result++,
      select: (d) => d,
      scope: 'scope1',
    );

    await client.prefetchQuery(query);
    await client.invalidateScope('scope1');

    final stream = client.streamQuery(query);

    await expectLater(
      stream,
      emits(1),
    );
  });

  test('invalidateScope does not clear the cache for a different scope', () async {
    final client = MockQueryClient();
    var result = 0;
    final query = VoltQuery(
      queryKey: ['test'],
      queryFn: () async => result++,
      select: (d) => d,
      scope: 'scope1',
    );

    await client.prefetchQuery(query);
    await client.invalidateScope('scope2');

    final stream = client.streamQuery(query);

    await expectLater(
      stream,
      emits(0),
    );
  });

  test('streamQuery handles network errors by retrying with backoff', () async {
    final client = MockQueryClient();
    int callCount = 0;
    final query = VoltQuery<String>(
      queryKey: ['test'],
      queryFn: () async {
        callCount++;
        if (callCount < 2) {
          throw Exception('Network error');
        }
        return 'Success';
      },
      select: (data) => data,
    );

    final stream = client.streamQuery(query);

    await expectLater(
      stream,
      emitsInOrder([
        'Success',
      ]),
    );

    expect(callCount, 2);
  });

  test('fetchQueryOrThrow throws error on network failure', () async {
    final client = MockQueryClient();
    final query = VoltQuery<String>(
      queryKey: ['test'],
      queryFn: () async {
        throw Exception('Network error');
      },
      select: (data) => data,
    );

    await expectLater(
      () => client.fetchQueryOrThrow(query),
      throwsException,
    );
  });

  test('streamQuery handles select function errors gracefully', () async {
    final client = MockQueryClient();
    int callCount = 0;
    final query = VoltQuery<String>(
      queryKey: ['test'],
      queryFn: () async {
        callCount++;
        return 'Success $callCount';
      },
      select: (data) {
        if (callCount < 2) {
          throw Exception('Select error');
        }
        return 'Processed $data';
      },
    );

    final stream = client.streamQuery(query);

    await expectLater(
      stream,
      emitsInOrder([
        'Processed Success 2',
      ]),
    );

    expect(callCount, 2);
  });

  test('queryFn is not called unnecessarily when multiple subscribers exist', () async {
    final client = MockQueryClient();
    int callCount = 0;
    final query = VoltQuery<String>(
      queryKey: ['test'],
      queryFn: () async {
        await Future.delayed(const Duration(milliseconds: 50));
        callCount++;
        return 'Success $callCount';
      },
      select: (data) => data,
      staleDuration: Duration.zero,
    );

    final stream1 = client.streamQuery(query);
    final stream2 = client.streamQuery(query);

    await Future.wait([
      expectLater(
        stream1,
        emits('Success 1'),
      ),
      expectLater(
        stream2,
        emits('Success 1'),
      ),
    ]);

    expect(callCount, 1);
  });

  test('streamQuery respects polling interval', () async {
    final client = MockQueryClient();
    int callCount = 0;
    final query = VoltQuery<String>(
      queryKey: ['test'],
      queryFn: () async {
        callCount++;
        return 'Success $callCount';
      },
      select: (data) => data,
      pollingDuration: const Duration(milliseconds: 5),
    );

    final stream = client.streamQuery(query);

    await expectLater(
      stream,
      emitsInOrder([
        'Success 1',
        'Success 2',
        'Success 3',
      ]),
    );
  });
}
