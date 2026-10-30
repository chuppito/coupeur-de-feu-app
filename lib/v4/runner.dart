import 'models.dart';
import 'engine.dart';

/// Clock-independent runner; the UI supplies monotonic foreground elapsed time.
class SessionRunner {
  final SessionPlan plan;
  final Set<String> _completed = <String>{};
  int _index = 0;
  int? _remainingMilliseconds;
  bool paused = true;
  SessionRunner(this.plan) {
    if (!plan.canStart) {
      throw ArgumentError('Plan incomplet ou contradictoire.');
    }
    final ids = <String>{};
    for (final a in plan.actions) {
      if (!ids.add(a.id) || a.id.isEmpty || a.origins.isEmpty) {
        throw const FormatException(
            'Identité d’action invalide dans l’instantané.');
      }
      final raw = a.definition.toJson();
      raw['duration'] = a.duration.toJson();
      final errors = ProtocolValidator().validate(ProtocolDefinition(
          id: 'snapshot',
          title: 'Instantané',
          category: 'Séance',
          modes: {
            plan.mode
          },
          blocks: [
            ProtocolBlock(
                id: 'snapshot',
                modes: {plan.mode},
                actions: [ActionDefinition.fromJson(raw)])
          ]));
      if (errors.any((e) => e.blocking)) {
        throw const FormatException('Action invalide dans l’instantané.');
      }
    }
    _resetDuration();
  }
  PlannedAction? get current => finished ? null : plan.actions[_index];
  bool get finished => _index >= plan.actions.length;
  Set<String> get completed => Set.unmodifiable(_completed);
  int? get remainingMilliseconds => _remainingMilliseconds;
  int? get remainingSeconds => _remainingMilliseconds == null
      ? null
      : (_remainingMilliseconds! / 1000).ceil();
  void _resetDuration() => _remainingMilliseconds = finished
      ? null
      : current!.duration.seconds == null
          ? null
          : current!.duration.seconds! * 1000;
  void play() {
    if (!finished) paused = false;
  }

  void pause() => paused = true;
  void elapse(Duration elapsed) {
    if (elapsed.isNegative) throw ArgumentError('Temps négatif.');
    if (paused || finished || _remainingMilliseconds == null) return;
    _remainingMilliseconds = (_remainingMilliseconds! - elapsed.inMilliseconds)
        .clamp(0, _remainingMilliseconds!);
    if (_remainingMilliseconds == 0 && current!.definition.autoAdvance) {
      completeCurrent();
    }
  }

  void completeCurrent() {
    if (finished) return;
    _completed.add(current!.id);
    _index++;
    _resetDuration();
    if (finished) paused = true;
  }

  Json toJson() => {
        'schemaVersion': 4,
        'plan': plan.toJson(),
        'completedIds': _completed.toList(),
        'activeActionId': current?.id,
        'remainingMilliseconds': _remainingMilliseconds,
        'paused': paused
      };
  factory SessionRunner.fromJson(Json j) {
    if (j['schemaVersion'] != 4) {
      throw const FormatException('Version de progression inconnue.');
    }
    final runner = SessionRunner(SessionPlan.fromJson(jsonMap(j['plan'])));
    final ids = strings(j['completedIds']);
    final expected =
        runner.plan.actions.take(ids.length).map((a) => a.id).toList();
    if (ids.length > runner.plan.actions.length ||
        fingerprint(ids) != fingerprint(expected)) {
      throw const FormatException('Progression incohérente.');
    }
    runner._completed.addAll(ids);
    runner._index = ids.length;
    if (j['activeActionId'] != runner.current?.id) {
      throw const FormatException('Action active incohérente.');
    }
    final milliseconds = j['remainingMilliseconds'] as int?;
    final total = runner.current?.duration.seconds;
    if ((total == null && milliseconds != null) ||
        (total != null &&
            (milliseconds == null ||
                milliseconds < 0 ||
                milliseconds > total * 1000))) {
      throw const FormatException('Minuteur incohérent.');
    }
    runner._remainingMilliseconds = milliseconds;
    // Resume always requires an explicit tap; background time is never counted.
    runner.paused = true;
    return runner;
  }
}
