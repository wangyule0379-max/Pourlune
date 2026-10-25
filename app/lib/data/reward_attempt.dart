import 'dart:convert';

import 'package:pourlune_core/pourlune_core.dart';

/// SDK confirmation and presentation closure are independent durable facts.
class RewardAttempt {
  const RewardAttempt({
    required this.id,
    required this.origin,
    required this.status,
    required this.confirmed,
  });
  final String id, status;
  final GameInstance origin;
  final bool confirmed;
  bool get needsRestore => status == 'pending_restore';
  bool get unconfirmed => status == 'unconfirmed';
  factory RewardAttempt.row(Map<String, Object?> row) => RewardAttempt(
    id: row['attempt_id']! as String,
    origin: GameInstance.parse(row['snapshot']! as String),
    status: row['status']! as String,
    confirmed: row['confirmed'] == 1,
  );
  Map<String, Object?> toRow() => {
    'attempt_id': id,
    'instance_id': origin.id,
    'slot': origin.slot,
    'snapshot': jsonEncode(origin.toJson()),
    'status': status,
    'confirmed': confirmed ? 1 : 0,
  };
}
