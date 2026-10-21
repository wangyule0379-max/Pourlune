import 'dart:async';
import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pourlune_core/pourlune_core.dart';
import 'package:pourlune_dev/application/game_controller.dart';
import 'package:pourlune_dev/application/hint_worker.dart';
import 'package:pourlune_dev/data/content_library.dart';
import 'package:pourlune_dev/data/game_store.dart';

import 'store_test.dart' show fixture, sample, finish;

ContentLibrary testLibrary() {
  final daily = Puzzle.fromJson(
    fixture().toJson()
      ..['puzzle_id'] = 'daily-a'
      ..['mode'] = 'daily'
      ..['main_level'] = null,
  );
  return ContentLibrary(
    main: {
      for (final n in [1, 2, 3, 4, 5, 12, 20, 21, 40, 41, 60]) n: fixture(n),
    },
    daily: DailyCatalog.parse(
      '{"schema_version":1,"catalog_version":1,"epoch_date":"2026-10-21","puzzle_ids":["daily-a"]}',
      {'daily-a': daily},
      engineering: true,
    ),
    engineering: true,
  );
}

void main() {
  sqfliteFfiInit();
  late Directory dir;
  late GameStore store;
  setUp(() async {
    dir = Directory.systemTemp.createTempSync('b02-flow-');
    store = await GameStore.open(
      '${dir.path}/g.db',
      factory: databaseFactoryFfi,
    );
  });
  tearDown(() async {
    await store.close();
    dir.deleteSync(recursive: true);
  });
  test(
    'B02-01 home/locks/missing content and once-only Next/replay identity',
    () async {
      final c = GameController(store, library: testLibrary());
      addTearDown(c.dispose);
      await c.initialize();
      expect(c.progress.nextUnfinished, 1);
      expect(await c.startLevel(12), isFalse);
      await c.startLevel(1);
      await c.skipTutorial();
      for (final m in c.current!.puzzle.referenceMoves) {
        await c.pour(m.from, m.to);
      }
      final wonId = c.current!.id;
      await Future.wait([c.nextLevel(), c.nextLevel()]);
      expect(c.current!.puzzle.mainLevel, 2);
      final nextId = c.current!.id;
      expect(nextId, isNot(wonId));
      await c.nextLevel();
      expect(c.current!.id, nextId);
      expect(await c.startLevel(1), isFalse);
      expect(c.current!.id, nextId);
      await c.startLevel(1, replace: true);
      expect(c.current!.isReplay, isTrue);
      await c.goHome();
      expect(c.continueLabelIsReplay, isTrue);
      final missing = GameController(
        store,
        library: ContentLibrary(main: {1: fixture()}),
      );
      addTearDown(missing.dispose);
      await missing.initialize();
      expect(await missing.startLevel(2, replace: true), isFalse);
      expect(missing.ordinary!.id, c.current!.id);
    },
  );
  test('B02-01/08 every destination blocks pending save; Retry honors first intent once', () async {
    final c = GameController(store, library: testLibrary());
    addTearDown(c.dispose);
    await c.initialize();
    await c.start(sample('x').puzzle);
    c.failNextWrite();
    await c.pour(0, 2);
    expect(c.phase, SavePhase.failed);
    for (final page in [
      GamePage.settings,
      GamePage.daily,
      GamePage.collection,
      GamePage.chapters,
      GamePage.home,
    ]) {
      await c.navigate(page);
      expect(c.page, GamePage.board);
      c.stayHere();
    }
    var arrivals = 0;
    c.addListener(() {
      if (c.page == GamePage.settings) arrivals++;
    });
    await c.navigate(GamePage.settings);
    await c.navigate(GamePage.daily);
    await c.retry();
    expect(c.page, GamePage.settings);
    expect(arrivals, 1);
    await c.retry();
    expect(arrivals, 1);
  });
  test('B02-02 Skip failure retains memory/free play; retry commits global flag with current board', () async {
    final c = GameController(store, library: testLibrary());
    addTearDown(c.dispose);
    await c.initialize();
    await c.startLevel(1);
    await c.pour(0, 2);
    store.fault = (stage) {
      if (stage == 'tutorial') throw StateError('tutorial failure');
    };
    await c.skipTutorial();
    expect(c.phase, SavePhase.failed);
    expect(await store.tutorialDone(), isFalse);
    await c.pour(2, 3);
    expect(c.current!.moveCount, 2);
    store.fault = null;
    await c.retry();
    expect(await store.tutorialDone(), isTrue);
    expect(
      (await store.load('ordinary')).instance!.toJson(),
      c.current!.toJson(),
    );
  });
  test('B02-04 delayed/out-of-order hint, same instance revision, cancel/retry/background/new instance', () async {
    final pending = <Completer<HintResult>>[];
    HintTask launch(GameInstance s) {
      final p = Completer<HintResult>();
      pending.add(p);
      return (result: p.future, cancel: () {}, released: Future<void>.value());
    }

    final c = GameController(
      store,
      library: testLibrary(),
      hintLauncher: launch,
    );
    addTearDown(c.dispose);
    await c.initialize();
    await c.start(fixture());
    await c.tapBottle(1);
    final first = c.requestHint();
    expect(c.hintSearching, isTrue);
    await c.pour(0, 2);
    pending[0].complete(
      const HintResult(HintStatus.found, move: PourMove(0, 2)),
    );
    await first;
    expect(c.hint, isNull);
    expect(c.selectedSource, isNull);
    final old = c.requestHint();
    c.cancelHint();
    final fresh = c.requestHint();
    pending[2].complete(
      const HintResult(HintStatus.found, move: PourMove(1, 0)),
    );
    await fresh;
    expect(c.selectedSource, 1);
    expect(c.current!.moveCount, 1);
    pending[1].complete(
      const HintResult(HintStatus.found, move: PourMove(0, 3)),
    );
    await old;
    expect(c.selectedSource, 1);
    c.cancelHint();
    expect(c.selectedSource, isNull);
    final background = c.requestHint();
    c.setForeground(false);
    pending[3].complete(
      const HintResult(HintStatus.found, move: PourMove(1, 0)),
    );
    await background;
    expect(c.hint, isNull);
    c.setForeground(true);
    final replaced = c.requestHint();
    await c.start(fixture(12), replace: true);
    pending[4].complete(
      const HintResult(HintStatus.found, move: PourMove(1, 0)),
    );
    await replaced;
    expect(c.hint, isNull);
  });
  test('B02-05/06 crossday old continuation, replacement failure, old stamps, date rollback and catalog absence', () async {
    var today = LocalDay('2026-10-21', 'Zone A', 480);
    final c = GameController(store, library: testLibrary(), clock: () => today);
    addTearDown(c.dispose);
    await c.initialize();
    await c.start(fixture());
    await c.pour(0, 2);
    final main = c.current!;
    await c.startToday();
    final yesterday = c.current!;
    await c.pour(0, 2);
    today = LocalDay('2026-10-22', 'Zone B', -300);
    await c.goHome();
    expect(await c.startToday(), isFalse);
    expect(c.daily!.id, yesterday.id);
    await c.resumeSlot('daily');
    for (final m in c.current!.puzzle.referenceMoves.skip(1)) {
      await c.pour(m.from, m.to);
    }
    expect(c.progress.dailyStamps, ['2026-10-21']);
    store.fault = (stage) {
      if (stage == 'snapshot') throw StateError('replace failure');
    };
    await c.startToday();
    expect(c.phase, SavePhase.failed);
    expect((await store.load('daily')).instance!.id, yesterday.id);
    store.fault = null;
    await c.retry();
    expect(c.current!.puzzleDate, '2026-10-22');
    expect(c.current!.timeZone, 'Zone B');
    expect(c.current!.offsetMinutes, -300);
    for (final m in c.current!.puzzle.referenceMoves) {
      await c.pour(m.from, m.to);
    }
    expect(c.progress.dailyStamps, ['2026-10-21', '2026-10-22']);
    today = LocalDay('2026-10-21', 'Zone C', 0);
    await c.goHome();
    await c.startToday();
    expect(c.current!.isReplay, isTrue);
    expect((await store.load('ordinary')).instance!.toJson(), main.toJson());
    expect(c.progress.firstClears, 0);
    today = LocalDay('2026-10-22', 'Zone D', 60);
    final absent = GameController(
      store,
      library: ContentLibrary(main: {1: fixture()}),
      clock: () => today,
    );
    addTearDown(absent.dispose);
    await absent.initialize();
    expect(await absent.startToday(replace: true), isFalse);
    await absent.resumeSlot('daily');
    expect(absent.current!.isReplay, isTrue);
  });
  test(
    'B02-07 final/replay/collection branch and persisted all-complete home',
    () async {
      for (var n = 1; n <= 60; n++) {
        await store.settle(finish(sample('seed-$n', level: n)), replace: true);
      }
      final c = GameController(store, library: testLibrary());
      addTearDown(c.dispose);
      await c.initialize();
      expect(c.progress.storyComplete, isTrue);
      expect(c.canNext, isFalse);
      expect(c.settlementKind, SettlementKind.finalStory);
      await c.startLevel(1);
      expect(c.current!.isReplay, isTrue);
      expect(c.current!.tutorial, isNull);
      await c.goHome();
      expect(c.continueLabelIsReplay, isTrue);
      expect(c.progress.pieces.length, 15);
      expect(c.progress.qualifyingClears, 50);
    },
  );
  test('B02-07 failed reveal Next then Stay cancels navigation but preserves acknowledgement retry', () async {
    final c = GameController(store, library: testLibrary());
    addTearDown(c.dispose);
    await c.initialize();
    await c.start(fixture(4));
    for (final m in c.current!.puzzle.referenceMoves) {
      await c.pour(m.from, m.to);
    }
    await c.viewPatch();
    store.fault = (stage) {
      if (stage == 'reveal') throw StateError('reveal failed');
    };
    await c.nextLevel();
    expect(c.phase, SavePhase.failed);
    c.stayHere();
    store.fault = null;
    await c.retry();
    expect(c.page, GamePage.reward);
    expect(c.progress.revealedPieces, ['color_studio:1']);
    expect(c.notice, isNull);
  });
  for (final next in [false, true]) {
    test(
      'B02-07 reveal Retry honors first NEW destination after Stay next=$next',
      () async {
        final c = GameController(store, library: testLibrary());
        addTearDown(c.dispose);
        await c.initialize();
        await c.start(fixture(4));
        for (final m in c.current!.puzzle.referenceMoves) {
          await c.pour(m.from, m.to);
        }
        await c.viewPatch();
        store.fault = (stage) {
          if (stage == 'reveal') throw StateError('reveal failure');
        };
        await c.nextLevel();
        c.stayHere();
        if (next) {
          await c.nextLevel();
          await c.acknowledgeReveal(destination: GamePage.collection);
        } else {
          await c.acknowledgeReveal(destination: GamePage.collection);
          await c.nextLevel();
        }
        store.fault = null;
        await c.retry();
        expect(c.phase, SavePhase.clean);
        expect(c.page, next ? GamePage.board : GamePage.collection);
        expect(c.current!.puzzle.mainLevel, next ? 5 : 4);
        expect(c.progress.pieces, ['color_studio:1']);
        expect(c.progress.revealedPieces, ['color_studio:1']);
        expect(c.progress.firstClears, 1);
      },
    );
  }
  test('B02-07 failed settlement Next wins once over later Home; Retry saves before navigation', () async {
    final c = GameController(store, library: testLibrary());
    addTearDown(c.dispose);
    await c.initialize();
    await c.start(fixture());
    final moves = c.current!.puzzle.referenceMoves;
    for (final m in moves.take(moves.length - 1)) {
      await c.pour(m.from, m.to);
    }
    store.fault = (stage) {
      if (stage == 'receipt') throw StateError('settlement failure');
    };
    await c.pour(moves.last.from, moves.last.to);
    expect(c.phase, SavePhase.failed);
    await c.nextLevel();
    await c.goHome();
    store.fault = null;
    await c.retry();
    expect(c.page, GamePage.board);
    expect(c.current!.puzzle.mainLevel, 2);
    expect(c.progress.firstClears, 1);
    final id = c.current!.id;
    await c.retry();
    await c.nextLevel();
    expect(c.current!.id, id);
  });
  for (final level in [20, 40]) {
    test(
      'B02-07 chapter $level Continue acknowledges full scene before one Next, failure retries',
      () async {
        for (var n = 1; n <= level; n++) {
          await store.settle(
            finish(sample('chapter-$n', level: n)),
            replace: true,
          );
        }
        final c = GameController(store, library: testLibrary());
        addTearDown(c.dispose);
        await c.initialize();
        c.resume();
        expect(c.settlementKind, SettlementKind.chapter);
        store.fault = (stage) {
          if (stage == 'reveal') throw StateError('chapter reveal');
        };
        await c.nextLevel();
        expect(c.phase, SavePhase.failed);
        expect(c.page, GamePage.completion);
        store.fault = null;
        await c.retry();
        expect(c.page, GamePage.board);
        expect(c.current!.puzzle.mainLevel, level + 1);
        expect(
          c.progress.revealedPieces,
          contains('${level == 20 ? 'color_studio' : 'garden_nook'}:5'),
        );
        expect(c.progress.qualifyingClears, level - 10);
      },
    );
  }
  for (final identity in ['revision', 'instance']) {
    test(
      'B02-04 unchanged token still rejects mismatched $identity and finishes spinner',
      () async {
        final response = Completer<HintResult>();
        HintTask launch(GameInstance s) => (
          result: response.future,
          cancel: () {},
          released: Future<void>.value(),
        );
        final c = GameController(
          store,
          library: testLibrary(),
          hintLauncher: launch,
        );
        addTearDown(c.dispose);
        await c.initialize();
        await c.start(fixture());
        final pending = c.requestHint();
        // Simulates a result returning across a state boundary independently of cancellation.
        c.current = identity == 'revision'
            ? c.current!.pour(0, 2).state
            : GameInstance.create(id: 'different-instance', puzzle: fixture());
        response.complete(
          const HintResult(HintStatus.found, move: PourMove(0, 3)),
        );
        await pending;
        expect(c.hint, isNull);
        expect(c.selectedSource, isNull);
        expect(c.hintSearching, isFalse);
      },
    );
  }
  test('B02-04 quick repeated requests cancel prior job and found hint replaces manual source only', () async {
    final responses = <Completer<HintResult>>[];
    var cancellations = 0;
    HintTask launch(GameInstance s) {
      final p = Completer<HintResult>();
      responses.add(p);
      return (
        result: p.future,
        cancel: () {
          cancellations++;
        },
        released: Future<void>.value(),
      );
    }

    final c = GameController(
      store,
      library: testLibrary(),
      hintLauncher: launch,
    );
    addTearDown(c.dispose);
    await c.initialize();
    await c.start(fixture());
    await c.tapBottle(1);
    final first = c.requestHint(), second = c.requestHint();
    expect(cancellations, 1);
    responses[1].complete(
      const HintResult(HintStatus.found, move: PourMove(0, 2)),
    );
    await second;
    expect(c.selectedSource, 0);
    expect(c.current!.moveCount, 0);
    responses[0].complete(
      const HintResult(HintStatus.found, move: PourMove(1, 3)),
    );
    await first;
    expect(c.selectedSource, 0);
    c.cancelHint();
    expect(c.selectedSource, isNull);
  });
  test(
    'B02 stale feedback is cleared when switching an engineering instance',
    () async {
      final c = GameController(store, library: testLibrary());
      addTearDown(c.dispose);
      await c.initialize();
      await c.start(fixture());
      await c.pour(0, 1);
      expect(c.rejection, isNotNull);
      await c.start(fixture(12), replace: true);
      expect(c.rejection, isNull);
    },
  );
  test('B02-07 future ad check boundary is fresh Next only, never restored or after Home', () async {
    for (var n = 1; n <= 12; n++) {
      await store.settle(
        finish(sample('boundary-$n', level: n)),
        replace: true,
      );
    }
    final library = ContentLibrary(
      main: {for (var n = 1; n <= 14; n++) n: fixture(n)},
      engineering: true,
    );
    final c = GameController(store, library: library);
    addTearDown(c.dispose);
    await c.initialize();
    c.resume();
    expect(c.canCheckInterstitialOnNext, isFalse);
    await c.start(fixture(13));
    for (final m in c.current!.puzzle.referenceMoves) {
      await c.pour(m.from, m.to);
    }
    expect(c.canCheckInterstitialOnNext, isTrue);
    expect(c.progress.qualifyingClears, 3);
    await c.goHome();
    expect(c.canCheckInterstitialOnNext, isFalse);
    await c.resumeSlot('ordinary');
    expect(c.canCheckInterstitialOnNext, isFalse);
    expect(c.progress.qualifyingClears, 3);
    final restored = GameController(store, library: library);
    addTearDown(restored.dispose);
    await restored.initialize();
    restored.resume();
    expect(restored.canCheckInterstitialOnNext, isFalse);
  });
  test('B02-01 completed valid-backup recovery can continue Next without duplicate awards', () async {
    final won = finish(sample('backup-complete'));
    await store.settle(won);
    await store.db.update(
      'active_slots',
      {'payload': 'corrupt'},
      where: 'slot = ?',
      whereArgs: ['ordinary'],
    );
    final c = GameController(store, library: testLibrary());
    addTearDown(c.dispose);
    await c.initialize();
    c.resume();
    expect(c.recoveryNotice, 'recovered');
    await c.nextLevel();
    expect(c.phase, SavePhase.clean);
    expect(c.current!.puzzle.mainLevel, 2);
    expect(c.progress.firstClears, 1);
    expect(c.progress.receipts, 1);
  });
}
