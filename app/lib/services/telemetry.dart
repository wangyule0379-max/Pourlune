import '../data/game_store.dart';
import 'firebase_gateway.dart';

enum ProductEvent {
  puzzleStart('puzzle_start'),
  puzzleComplete('puzzle_complete'),
  tutorialComplete('tutorial_complete'),
  tutorialSkip('tutorial_skip'),
  hintResult('hint_result'),
  interstitialCheck('interstitial_check'),
  adImpression('ad_impression'),
  adDismiss('ad_dismiss'),
  adContinue('ad_continue'),
  adError('ad_error'),
  rewardConfirmed('reward_confirmed'),
  rewardGranted('reward_granted'),
  saveFailed('save_failed'),
  saveRecovered('save_recovered'),
  pieceGranted('collection_piece_granted');

  const ProductEvent(this.wire);
  final String wire;
}

/// No free-text field; callbacks cannot accidentally send boards/errors/feedback.
bool validEventParameters(Map<String, Object> p) {
  const numbers = {
    'version',
    'first',
    'replay',
    'duration_ms',
    'moves',
    'hints',
    'undos',
    'restarts',
    'extra_bottles',
    'tutorial_version',
    'step',
    'qualifying',
  };
  const identifiers = {'instance_id', 'request_id', 'completion_id'};
  const results = {
    'found',
    'continued',
    'unsolvable',
    'timeout',
    'cancelled',
    'no_moves',
    'shown',
    'impression',
    'dismissed',
    'show_failed',
    'load_failed',
    'network',
    'no_fill',
    'invalid_request',
    'disposed',
    'unavailable',
    'save_failed',
    'stale',
    'disabled',
    'cooldown',
    'granted',
    'restored',
    'satisfied_completed',
    'snapshot',
    'candidate',
    'settings',
    'reveal',
    'reset',
    'storage',
  };
  for (final e in p.entries) {
    if (numbers.contains(e.key)) {
      if (e.value is! int ||
          (e.value as int) < 0 ||
          (e.value as int) > 604800000) {
        return false;
      }
    } else if (identifiers.contains(e.key)) {
      if (e.value is! String ||
          !RegExp(r'^[A-Za-z0-9:_-]{1,100}$').hasMatch(e.value as String)) {
        return false;
      }
    } else if (e.key == 'mode') {
      if (!{'main', 'daily', 'replay'}.contains(e.value)) return false;
    } else if (e.key == 'puzzle_id') {
      if (e.value is! String ||
          !RegExp(r'^(main|daily)-[0-9]{3}$').hasMatch(e.value as String)) {
        return false;
      }
    } else if (e.key == 'scene_id') {
      if (!{
        'color_studio',
        'garden_nook',
        'seaside_corner',
      }.contains(e.value)) {
        return false;
      }
    } else if (e.key == 'piece_id') {
      if (e.value is! String ||
          !RegExp(r'^(color_studio|garden_nook|seaside_corner):[1-5]$')
              .hasMatch(e.value as String)) {
        return false;
      }
    } else if (e.key == 'result' ||
        e.key == 'operation' ||
        e.key == 'error_category') {
      if (!results.contains(e.value)) return false;
    } else if (e.key == 'format') {
      if (!{'interstitial', 'rewarded'}.contains(e.value)) return false;
    } else {
      return false;
    }
  }
  return p.length <= 16;
}

class ProductTelemetry {
  ProductTelemetry(this.store, this.gateway, this.allowed);
  final GameStore store;
  final FirebaseGateway gateway;
  final bool Function() allowed;
  Future<void> log(
    ProductEvent event,
    String identity,
    Map<String, Object> fields,
  ) async {
    if (!allowed() || !validEventParameters(fields)) return;
    try {
      if (!await store.claimServiceEvent('${event.wire}:$identity') ||
          !allowed()) {
        return;
      }
      // Prefix separates business evidence from SDK automatic ad_impression.
      await gateway.event('pl_${event.wire}', fields);
    } catch (_) {
      /* Best effort; no retry/backfill of denied or claimed events. */
    }
  }
}
