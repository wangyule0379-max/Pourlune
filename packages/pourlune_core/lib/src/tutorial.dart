import 'puzzle.dart';

enum TutorialStatus { active, completed, skipped }

class Tutorial {
  const Tutorial(this.step, this.status);
  const Tutorial.start() : this(0, TutorialStatus.active);
  final int step;
  final TutorialStatus status;
  bool get active => status == TutorialStatus.active;
  bool get finished => !active;
  Tutorial advance(int length) => Tutorial(
    step + 1,
    step + 1 >= length ? TutorialStatus.completed : TutorialStatus.active,
  );
  Tutorial skip() => Tutorial(step, TutorialStatus.skipped);
  Map<String, Object?> toJson() => {
    'version': 1,
    'step': step,
    'status': status.name,
  };
  factory Tutorial.fromJson(Object? raw, int length) {
    final m = object(raw);
    keys(m, {'version', 'step', 'status'});
    if (integer(m['version']) != 1) invalid('Unknown tutorial version');
    final step = integer(m['step']), name = text(m['status']);
    final statuses = TutorialStatus.values.where((s) => s.name == name);
    if (statuses.isEmpty) invalid('Unknown tutorial status');
    final status = statuses.single;
    if (step > length ||
        (status == TutorialStatus.active && step >= length) ||
        (status == TutorialStatus.completed && step != length)) {
      invalid('Invalid tutorial step');
    }
    return Tutorial(step, status);
  }
}
