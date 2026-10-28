import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gamemunchies_client/gamemunchies_client.dart';
import 'package:gamemunchies_client/src/preferences_store.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../integration_test/gamemunchies_api_native_app.dart'
    show QaAckLossClient;

void main() {
  test(
    'native QA persists delayed mixed retry ACK without losing original proof',
    () async {
      final dir = Directory.systemTemp.createTempSync('gm-delayed-ack-');
      final retryEntered = Completer<void>();
      final releaseRetry = Completer<void>();
      var calls = 0;
      final transport = QaAckLossClient(
        File('${dir.path}/lost-once'),
        inner: MockClient((request) async {
          calls++;
          if (calls == 2) {
            retryEntered.complete();
            await releaseRetry.future;
          }
          return http.Response(
            jsonEncode({
              'accepted': calls == 1 ? 2 : 1,
              'received': calls == 1 ? 2 : 3,
            }),
            200,
          );
        }),
      );
      addTearDown(() {
        transport.close();
        dir.deleteSync(recursive: true);
      });
      final originals = [
        for (final type in ['active', 'round_start'])
          {
            'id': 'unit-only-$type',
            'installationId': 'unit-only-installation',
            'type': type,
            'environment': 'test',
            'occurredAt': '2026-10-28T00:00:00.000Z',
          },
      ];
      http.Request request(List<Map<String, String>> events) =>
          http.Request('POST', Uri.parse('https://unit.invalid/events'))
            ..body = jsonEncode({'events': events});
      await expectLater(
        transport.send(request(originals)),
        throwsA(isA<SocketException>()),
      );
      final proof = File('${dir.path}/acks.json');
      expect(
        await proof.exists(),
        isTrue,
        reason:
            'The first real ACK must be durable before the controlled loss.',
      );
      final delayed = transport.send(
        request([
          ...originals,
          {...originals.first, 'id': 'unit-only-new-active'},
        ]),
      );
      await retryEntered.future;
      expect(
        (jsonDecode(await proof.readAsString())['acks'] as List).length,
        1,
      );
      releaseRetry.complete();
      await delayed;
      final finalProof = jsonDecode(await proof.readAsString()) as Map;
      expect((finalProof['acks'] as List).length, 2);
      expect(finalProof['originals_deduplicated'], isTrue);
      expect(finalProof['retry_kept_original_ids_and_first_times'], isTrue);
      expect(finalProof['original_batch_count'], 2);
      expect(await proof.readAsString(), isNot(contains('unit-only-')));
      expect(await proof.readAsString(), isNot(contains('occurredAt')));
    },
  );

  test('native QA loses one real ACK and SDK retry preserves original observations and headers', () async {
    final dir = Directory.systemTemp.createTempSync('gm-native-transport-');
    final bodies = <String>[];
    var now = DateTime.utc(2026, 10, 28).millisecondsSinceEpoch;
    final transport = QaAckLossClient(
      File('${dir.path}/lost-once'),
      inner: MockClient((request) async {
        if (request.method == 'GET') return http.Response('', 409);
        expect(request.headers['authorization'], isNull);
        expect(request.headers['cookie'], isNull);
        expect(request.headers['user-agent'], isNull);
        bodies.add(request.body);
        final count = (jsonDecode(request.body)['events'] as List).length;
        return http.Response(
          jsonEncode({
            'accepted': bodies.length == 1 ? count : 0,
            'received': count,
          }),
          200,
        );
      }),
    );
    final client = GameMunchiesClient(
      ClientOptions(
        baseUrl: 'https://api.gamemunchies.com',
        gameId: 'local-unit-only',
        platform: 'android',
        environment: 'test',
        defaultConfig: {'enabled': false},
      ),
      store: MemoryStore(),
      httpClient: transport,
      now: () => now,
      random: () => 0,
    );
    addTearDown(() async {
      await client.dispose();
      dir.deleteSync(recursive: true);
    });
    await client.track('round_start', id: 'unit-only-real-sdk-observation');
    expect((await client.flush())['pending'], 1);
    now += 3000;
    expect((await client.flush())['pending'], 0);
    expect(bodies.length, 2);
    expect(bodies[1], bodies[0]);
    expect(transport.acknowledgements, [
      {'status': 200, 'accepted': 1, 'received': 1},
      {'status': 200, 'accepted': 0, 'received': 1},
    ]);
    expect(transport.retryPreservedOriginalFields, isTrue);
  });
}
