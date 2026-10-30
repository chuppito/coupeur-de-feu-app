import 'package:flutter_test/flutter_test.dart';
import 'package:coupeur_de_feu_app/v4/models.dart';
import 'package:coupeur_de_feu_app/v4/engine.dart';
import 'package:coupeur_de_feu_app/v4/runner.dart';

SessionPlan plan({int? seconds = 240, bool auto = true}) =>
    SessionEngine().build(mode: SessionMode.presentiel, selections: [
      ProtocolSelection(
          id: 'a',
          protocol: ProtocolDefinition(
              id: 'a',
              title: 'a',
              category: 'test',
              blocks: [
                ProtocolBlock(id: 'b', actions: [
                  for (var i = 0; i < 2; i++)
                    ActionDefinition(
                        id: 'x$i',
                        title: 'x$i',
                        instruction: 'Test',
                        kind: ActionKind.intention,
                        duration: seconds == null
                            ? const DurationSpec()
                            : DurationSpec.exact(seconds),
                        autoAdvance: auto,
                        sources: const [
                          SourceRef(
                              id: 's', lesson: 's', url: 'https://example.org')
                        ])
                ])
              ]))
    ]);
void main() {
  test('A01 le minuteur respecte les 240 secondes affichées', () {
    final r = SessionRunner(plan());
    r.play();
    r.elapse(const Duration(seconds: 239));
    expect(r.remainingSeconds, 1);
    expect(r.current!.definition.id, 'x0');
    r.elapse(const Duration(seconds: 1));
    expect(r.current!.definition.id, 'x1');
    expect(r.remainingSeconds, 240);
  });
  test('Pause et reprise ne consomment pas le temps absent', () {
    final r = SessionRunner(plan());
    r.play();
    r.elapse(const Duration(milliseconds: 1500));
    r.pause();
    r.elapse(const Duration(hours: 2));
    expect(r.remainingMilliseconds, 238500);
    final restored = SessionRunner.fromJson(r.toJson());
    expect(restored.paused, isTrue);
    expect(restored.remainingMilliseconds, 238500);
    restored.play();
    restored.elapse(const Duration(milliseconds: 500));
    expect(restored.remainingSeconds, 238);
  });
  test('Un délai ne saute pas une chaîne entière de conventions', () {
    final r = SessionRunner(plan(seconds: 1));
    r.play();
    r.elapse(const Duration(hours: 1));
    expect(r.completed.length, 1);
    expect(r.remainingSeconds, 1);
  });
  test('Une durée inconnue exige progression manuelle', () {
    final r = SessionRunner(plan(seconds: null));
    r.play();
    r.elapse(const Duration(days: 1));
    expect(r.completed, isEmpty);
    expect(r.remainingSeconds, isNull);
    r.completeCurrent();
    expect(r.completed.length, 1);
  });
  test('La fin du minuteur ne valide pas une étape manuelle', () {
    final r = SessionRunner(plan(seconds: 1, auto: false));
    r.play();
    r.elapse(const Duration(seconds: 2));
    expect(r.remainingSeconds, 0);
    expect(r.completed, isEmpty);
  });
  test('Import refuse progression corrompue et minuteur hors limite', () {
    final r = SessionRunner(plan());
    expect(
        () => SessionRunner.fromJson({
              ...r.toJson(),
              'completedIds': ['inconnu']
            }),
        throwsFormatException);
    expect(
        () => SessionRunner.fromJson(
            {...r.toJson(), 'remainingMilliseconds': 999999}),
        throwsFormatException);
  });
  test('Une séance terminée peut être restaurée sans réexécution', () {
    final r = SessionRunner(plan());
    r.completeCurrent();
    r.completeCurrent();
    final restored = SessionRunner.fromJson(r.toJson());
    expect(restored.finished, isTrue);
    expect(restored.current, isNull);
    restored.play();
    expect(restored.paused, isTrue);
  });
}
