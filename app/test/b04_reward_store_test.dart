import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_dev/data/game_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'store_test.dart' show sample, finish, daily;

void main() {
  sqfliteFfiInit();
  late Directory dir;
  late GameStore store;
  late String path;
  setUp(() async {
    dir = Directory.systemTemp.createTempSync('b04-reward-');
    path = '${dir.path}/g.db';
    store = await GameStore.open(path, factory: databaseFactoryFfi);
  });
  tearDown(() async {
    await store.close();
    dir.deleteSync(recursive: true);
  });
  Future<void> reopen() async {
    await store.close();
    store = await GameStore.open(path, factory: databaseFactoryFfi);
  }

  for (final closeFirst in [false, true]) {
    test(
      'AC19 closure order=$closeFirst grants once to original, undo/restart retain and duplicate callbacks do not change revision',
      () async {
        var s = sample('origin', level: 12);
        await store.save(s);
        await store.beginReward('A', s);
        if (closeFirst) await store.closeReward('A');
        final result = await store.confirmReward('A');
        expect(result!.confirmed, isTrue);
        expect(result.status, 'done');
        s = (await store.load('ordinary')).instance!;
        expect(s.extraBottleGranted, isTrue);
        expect(s.board.length, 5);
        final revision = s.revision;
        await store.closeReward('A');
        await store.confirmReward('A');
        expect((await store.load('ordinary')).instance!.revision, revision);
        s = s.pour(0, 2).state;
        await store.save(s);
        s = s.undo();
        await store.save(s);
        s = s.restart();
        await store.save(s);
        expect(s.extraBottleGranted, isTrue);
        expect(s.board.length, 5);
        await reopen();
        expect(
          (await store.load('ordinary')).instance!.extraBottleGranted,
          isTrue,
        );
        expect(await store.db.query('reward_entitlements'), hasLength(1));
      },
    );
  }
  test('AC19 close without confirmation is not a grant; later request then old callback never grants two', () async {
    final s = sample('one');
    await store.save(s);
    await store.beginReward('A', s);
    await store.closeReward('A');
    expect(
      (await store.load('ordinary')).instance!.extraBottleGranted,
      isFalse,
    );
    await store.beginReward('B', s);
    await store.confirmReward('B');
    await store.closeReward('B');
    await store.confirmReward('A');
    expect((await store.load('ordinary')).instance!.board.length, 5);
    expect(await store.db.query('reward_entitlements'), hasLength(1));
    expect((await store.rewardAttempt('A'))!.confirmed, isTrue);
  });
  test('AC21 late origin confirmation retains latest moves, never overwrites new slot, and restore is explicitly guarded and idempotent', () async {
    var origin = sample('old');
    await store.save(origin);
    await store.beginReward('A', origin);
    await store.closeReward('A');
    origin = origin.pour(0, 2).state;
    await store.save(origin);
    final newer = sample('new');
    await store.save(newer, replace: true);
    final reward = await store.confirmReward('A');
    expect(reward!.needsRestore, isTrue);
    expect(reward.origin.moveCount, 1);
    expect(reward.origin.extraBottleGranted, isTrue);
    expect((await store.load('ordinary')).instance!.toJson(), newer.toJson());
    await reopen();
    expect((await store.pendingRewards()).single.needsRestore, isTrue);
    await expectLater(
      store.restoreReward('A', replacingInstance: 'wrong'),
      throwsStateError,
    );
    await store.restoreReward('A', replacingInstance: 'new');
    final restored = (await store.load('ordinary')).instance!;
    expect(restored.id, 'old');
    expect(restored.moveCount, 1);
    expect(restored.extraBottleGranted, isTrue);
    await store.save(sample('next'), replace: true);
    await store.restoreReward('A', replacingInstance: 'next');
    expect((await store.load('ordinary')).instance!.id, 'next');
  });
  test('AC19/21 historical late confirmation can be durably pending while a later original-slot request is already showing', () async {
    final old = sample('old');
    await store.save(old);
    await store.beginReward('A', old);
    await store.closeReward('A');
    final newer = sample('new');
    await store.save(newer, replace: true);
    await store.beginReward('B', newer);
    expect((await store.confirmReward('A'))!.needsRestore, isTrue);
    expect((await store.rewardAttempt('B'))!.status, 'open');
    expect((await store.load('ordinary')).instance!.toJson(), newer.toJson());
    await store.closeReward('B');
    await expectLater(store.beginReward('C', newer), throwsStateError);
  });
  test('AC21 completed origin only records entitlement, does not reopen or change first-clear rewards', () async {
    final s = sample('done', level: 4);
    await store.save(s);
    await store.beginReward('A', s);
    await store.closeReward('A');
    final solved = finish(s);
    await store.settle(solved);
    final before = await store.progress();
    await store.confirmReward('A');
    expect((await store.load('ordinary')).instance!.toJson(), solved.toJson());
    expect((await store.rewardAttempt('A'))!.status, 'done');
    expect((await store.progress()).receipts, before.receipts);
    expect((await store.progress()).pieces, before.pieces);
  });
  test('AC20 failed confirmation transaction rolls everything back; same request retry and reload grant once', () async {
    final s = sample('retry');
    await store.save(s);
    await store.beginReward('A', s);
    store.fault = (stage) {
      if (stage == 'reward_grant') throw StateError('disk fault');
    };
    await expectLater(store.confirmReward('A'), throwsStateError);
    expect((await store.rewardAttempt('A'))!.confirmed, isFalse);
    expect(await store.db.query('reward_entitlements'), isEmpty);
    expect((await store.load('ordinary')).instance!.toJson(), s.toJson());
    store.fault = null;
    await store.confirmReward('A');
    await reopen();
    await store.confirmReward('A');
    expect((await store.load('ordinary')).instance!.board.length, 5);
    expect(await store.db.query('reward_entitlements'), hasLength(1));
  });
  test('AC20 interrupted unconfirmed attempt needs explicit end; neither restart nor close invents reward; daily independent', () async {
    final s = sample('ordinary'), d = daily();
    await store.save(s);
    await store.save(d);
    await store.beginReward('A', s);
    await store.beginReward('D', d);
    await reopen();
    await store.recoverRewardIntents();
    expect(await store.pendingRewards(), hasLength(2));
    await expectLater(store.beginReward('B', s), throwsA(anything));
    await store.dismissUnconfirmedReward('A');
    await store.beginReward('B', s);
    await store.closeReward('B');
    expect(
      (await store.load('ordinary')).instance!.extraBottleGranted,
      isFalse,
    );
    await store.confirmReward('D');
    expect((await store.load('daily')).instance!.extraBottleGranted, isTrue);
    expect((await store.load('ordinary')).instance!.toJson(), s.toJson());
  });
  test('AC13/17/36 only actual shown id resets count; reward shares time and never clears qualification; show and event claims dedup', () async {
    for (var n = 1; n <= 13; n++) {
      await store.settle(finish(sample('level$n', level: n)), replace: true);
    }
    expect((await store.progress()).qualifyingClears, 3);
    expect(await store.lastFullscreenMillis(), isNull);
    await store.prepareFullscreen('R', 'rewarded');
    await store.recordFullscreen('R', 'rewarded', 1000);
    expect((await store.progress()).qualifyingClears, 3);
    expect(await store.lastFullscreenMillis(), 1000);
    await store.prepareFullscreen('I', 'interstitial');
    await store.recordFullscreen('I', 'interstitial', 2000);
    expect((await store.progress()).qualifyingClears, 0);
    await store.settle(finish(sample('level14', level: 14)), replace: true);
    await store.recordFullscreen('I', 'interstitial', 3000);
    expect((await store.progress()).qualifyingClears, 1);
    expect(await store.lastFullscreenMillis(), 2000);
    expect(await store.claimServiceEvent('event:instance'), isTrue);
    await reopen();
    expect(await store.claimServiceEvent('event:instance'), isFalse);
  });
  test(
    'AC19 reset or unknown callback cannot restore deleted old progress',
    () async {
      final s = sample('reset');
      await store.save(s);
      await store.beginReward('A', s);
      await store.resetProgress();
      expect(await store.confirmReward('A'), isNull);
      expect(await store.confirmReward('unknown'), isNull);
      expect((await store.progress()).firstClears, 0);
      expect((await store.load('ordinary')).instance, isNull);
    },
  );
}
