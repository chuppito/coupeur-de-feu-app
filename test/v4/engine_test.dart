import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:coupeur_de_feu_app/v4/models.dart';
import 'package:coupeur_de_feu_app/v4/engine.dart';

const source = SourceRef(
    id: 'test-source', lesson: 'test', url: 'https://example.org/source');
ActionDefinition action(String id,
        {ActionKind kind = ActionKind.intention,
        int? seconds = 60,
        ReviewState review = ReviewState.documented,
        String? prayer,
        String text = 'Instruction de test'}) =>
    ActionDefinition(
        id: id,
        title: id,
        instruction: text,
        kind: kind,
        duration: seconds == null
            ? const DurationSpec()
            : DurationSpec.exact(seconds),
        review: review,
        sources: const [source],
        prayerId: prayer);
ProtocolBlock shared(String id, {int seconds = 60}) => ProtocolBlock(
    id: id, shareKey: id, actions: [action(id, seconds: seconds)]);
ProtocolBlock local(String id, {List<ActionDefinition>? actions}) =>
    ProtocolBlock(
        id: id,
        target: 'selected',
        repeatPerZone: true,
        modes: const {SessionMode.presentiel},
        actions: actions ?? [action(id, kind: ActionKind.imposition)]);
ProtocolDefinition protocol(String id, List<ProtocolBlock> blocks,
        {List<OrderConstraint> constraints = const []}) =>
    ProtocolDefinition(
        id: id,
        title: id,
        category: 'test',
        blocks: blocks,
        constraints: constraints);
const ankle = BodyZone(id: 'cheville', label: 'Cheville', side: 'droite');
const wrist = BodyZone(id: 'poignet', label: 'Poignet', side: 'gauche');
ProtocolSelection pick(ProtocolDefinition p,
        {List<BodyZone> zones = const [ankle]}) =>
    ProtocolSelection(id: p.id, protocol: p, zones: zones);
SessionPlan build(List<ProtocolSelection> picks,
        {SessionMode mode = SessionMode.presentiel,
        Map<String, bool> facts = const {},
        Set<String> optional = const {}}) =>
    SessionEngine().build(
        mode: mode,
        selections: picks,
        facts: facts,
        enabledOptionalBlocks: optional);
void main() {
  test('A10 quatre motifs partagent accueil et fin, gardent toutes les cibles',
      () {
    final ps = [
      for (var i = 0; i < 4; i++)
        pick(
            protocol('p$i', [shared('accueil'), local('local'), shared('fin')]),
            zones: [BodyZone(id: 'z$i', label: 'Zone $i')])
    ];
    final p = build(ps);
    expect(p.canStart, isTrue);
    expect(p.actions.length, 6);
    expect(p.actions.first.origins.length, 4);
    expect(
        p.actions
            .where((a) => a.zones.isNotEmpty)
            .map((a) => a.zones.single.id)
            .toSet(),
        {'z0', 'z1', 'z2', 'z3'});
  });
  test('Les actions locales identiques ne fusionnent pas par leur texte', () {
    final p = build([
      pick(protocol('a', [local('a')])),
      pick(protocol('b', [local('a')]))
    ]);
    expect(p.actions.length, 2);
    expect(p.actions.map((a) => a.id).toSet().length, 2);
  });
  test('Répétition du bloc entier par zone : prière puis imposition', () {
    final p = build([
      pick(
          protocol('a', [
            local('local', actions: [
              action('priere', kind: ActionKind.prayer, prayer: 'eczema'),
              action('imposition', kind: ActionKind.imposition)
            ])
          ]),
          zones: [ankle, wrist])
    ]);
    expect(p.actions.map((a) => a.definition.id).toList(),
        ['priere', 'imposition', 'priere', 'imposition']);
    expect(p.actions[0].zones.single.key, p.actions[1].zones.single.key);
    expect(p.actions[2].zones.single.key, p.actions[3].zones.single.key);
  });
  test('A07 ordres contradictoires bloquent le plan et conservent aperçu', () {
    final p = build([
      pick(protocol('a', [shared('conventions'), shared('priere')])),
      pick(protocol('b', [shared('priere'), shared('conventions')]))
    ]);
    expect(p.canStart, isFalse);
    expect(p.issues.any((x) => x.code == 'orderConflict'), isTrue);
    expect(p.actions.length, 2);
  });
  test('A01 durées divergentes gardées séparées, aucune fusion', () {
    final p = build([
      pick(protocol('a', [shared('convention9', seconds: 60)])),
      pick(protocol('b', [shared('convention9', seconds: 240)]))
    ]);
    expect(p.actions.map((a) => a.duration.seconds).toSet(), {60, 240});
    expect(p.issues.any((x) => x.code == 'incompatibleShare'), isTrue);
  });
  test('A06 un parcours distance ne reçoit aucun geste corporel', () {
    final p = build([
      pick(protocol('a', [
        local('passes'),
        ProtocolBlock(
            id: 'support',
            modes: const {SessionMode.distance},
            actions: [action('support', kind: ActionKind.support)])
      ]))
    ], mode: SessionMode.distance);
    expect(p.canStart, isTrue);
    expect(p.actions.single.definition.kind, ActionKind.support);
  });
  test('Les gestes physiques annoncés à distance sont rejetés', () {
    final p = build([
      pick(protocol('a', [
        ProtocolBlock(
            id: 'erreur', actions: [action('p', kind: ActionKind.rapidPasses)])
      ]))
    ], mode: SessionMode.distance);
    expect(p.canStart, isFalse);
    expect(p.issues.any((x) => x.code == 'distancePhysical'), isTrue);
  });
  test('Source contradictoire ne devient pas certitude', () {
    expect(
        build([
          pick(protocol('a', [
            ProtocolBlock(
                id: 'b',
                actions: [action('c', review: ReviewState.conflicting)])
          ]))
        ]).canStart,
        isFalse);
  });
  test(
      'Durée inconnue reste nulle ; plage exige choix explicite dans les bornes',
      () {
    const t =
        DurationSpec(minSeconds: 90, maxSeconds: 100, precision: 'environ');
    expect(t.seconds, isNull);
    expect(t.choose(95).seconds, 95);
    expect(t.choose(95).origin, 'personal');
    expect(() => t.choose(60), throwsArgumentError);
    expect(const DurationSpec().seconds, isNull);
  });
  test('Le choix de durée modifie le snapshot sans déplacer son action', () {
    final p = build([
      pick(protocol('a', [
        ProtocolBlock(id: 'b', actions: [action('a', seconds: null)])
      ]))
    ]);
    final selected = p.chooseDuration(p.actions.single.id, 90);
    expect(selected.actions.single.id, p.actions.single.id);
    expect(selected.id, isNot(p.id));
    expect(p.actions.single.duration.seconds, isNull);
    expect(selected.actions.single.duration.seconds, 90);
  });
  test('A09 options ne déplacent pas identifiants stables des autres actions',
      () {
    final p = protocol('a', [
      ProtocolBlock(id: 'scan', optional: true, actions: [action('scan')]),
      shared('conventions')
    ]);
    final a = build([pick(p)]);
    final b = build([pick(p)], optional: {'scan'});
    expect(a.actions.single.id, b.actions.last.id);
  });
  test('Condition inconnue bloque sans supposer faux', () {
    final p = protocol('a', [
      ProtocolBlock(id: 'b', condition: 'declared', actions: [action('a')])
    ]);
    expect(build([pick(p)]).canStart, isFalse);
    expect(build([pick(p)], facts: {'declared': true}).actions.length, 1);
    expect(build([pick(p)], facts: {'declared': false}).actions, isEmpty);
  });
  test('Cible sélectionnée manquante bloque sans côté inventé', () {
    expect(
        build([
          pick(protocol('a', [local('local')]), zones: [])
        ]).canStart,
        isFalse);
  });
  test('Dépendance vers bloc inconnu rejetée', () {
    expect(
        build([
          pick(protocol('a', [shared('a')],
              constraints: [const OrderConstraint('a', 'missing')]))
        ]).canStart,
        isFalse);
  });
  test('Toutes les références des étapes partagées sont conservées', () {
    ProtocolDefinition f(String id) => protocol(id, [
          ProtocolBlock(id: 'b', shareKey: 'b', actions: [
            ActionDefinition(
                id: 'x',
                title: 'x',
                instruction: 'x',
                kind: ActionKind.intention,
                sources: [
                  SourceRef(id: id, lesson: id, url: 'https://example.org/$id')
                ])
          ])
        ]);
    final p = build([pick(f('a')), pick(f('b'))]);
    expect(p.actions.single.sources.map((s) => s.id).toSet(), {'a', 'b'});
    expect(p.actions.single.origins, ['a', 'b']);
  });
  test('A12 snapshot autonome survit au JSON sans relire un catalogue', () {
    final p = build([
      pick(protocol('a', [shared('a'), local('b')]))
    ]);
    final copy =
        SessionPlan.fromJson(jsonMap(jsonDecode(jsonEncode(p.toJson()))));
    expect(copy.toJson(), p.toJson());
    expect(copy.id, p.id);
  });
  test('Même demande, même plan, aucune entrée mutée', () {
    final selections = [
      pick(protocol('a', [shared('a'), local('b')]))
    ];
    final before = jsonEncode(selections.single.protocol.toJson());
    expect(build(selections).id, build(selections).id);
    expect(jsonEncode(selections.single.protocol.toJson()), before);
  });
  test('A18 budget signale mais ne raccourcit aucun temps', () {
    final p = build([
      pick(
          protocol('a', [
            local('l', actions: [
              action('x', kind: ActionKind.imposition, seconds: 300)
            ])
          ]),
          zones: [for (var i = 0; i < 7; i++) BodyZone(id: '$i', label: '$i')])
    ]);
    expect(p.timedSeconds, 2100);
    expect(p.issues.any((x) => x.code == 'localTimeBudget' && !x.blocking),
        isTrue);
  });
  test('Validation refuse durée négative, doublons et source absente', () {
    final p = protocol('a', [
      ProtocolBlock(id: 'b', actions: [
        action('x', seconds: -1),
        ActionDefinition(
            id: 'x', title: 'x', instruction: 'x', kind: ActionKind.intention)
      ])
    ]);
    expect(ProtocolValidator().validate(p).where((x) => x.blocking).length,
        greaterThanOrEqualTo(3));
  });
  test('Schéma de fiche explicite est réversible et versionné', () {
    final p = protocol('a', [shared('a')]);
    expect(ProtocolDefinition.fromJson(p.toJson()).toJson(), p.toJson());
    expect(
        () => ProtocolDefinition.fromJson({...p.toJson(), 'schemaVersion': 3}),
        throwsFormatException);
  });
  test('Instantané protégé contre les mutations des cibles imbriquées', () {
    final p = build([pick(protocol('a', [local('b')]))]);
    expect(() => (p.selections.first['zones'] as List).clear(), throwsUnsupportedError);
    expect(() => p.actions.first.zones.clear(), throwsUnsupportedError);
    expect(() => p.actions.first.origins.clear(), throwsUnsupportedError);
  });
}
