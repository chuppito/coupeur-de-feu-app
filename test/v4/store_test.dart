import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:coupeur_de_feu_app/v4/models.dart';
import 'package:coupeur_de_feu_app/v4/store.dart';
import 'package:coupeur_de_feu_app/v4/engine.dart';
import 'package:coupeur_de_feu_app/v4/runner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('magnetisme-v4-');
    Hive.init(dir.path);
    await V4Store.open();
  });
  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });
  test('A11 homonymes ont deux identités et deux historiques distincts',
      () async {
    final a = await V4Store.createPatient('Anne', 'Éclair'),
        b = await V4Store.createPatient('Anne', 'Éclair');
    expect(a, isNot(b));
    expect(V4Store.patients(search: 'eclair').length, 2);
    await V4Store.renamePatient(a, 'Anne', 'Durand');
    expect(V4Store.patients(search: 'eclair').single['id'], b);
  });
  test('A12 import idempotent et refus des conflits sans écraser', () async {
    await V4Store.createPatient('Anne', 'A');
    final data = jsonMap(jsonDecode(jsonEncode(V4Store.exportData())));
    expect(await V4Store.importData(data), 0);
    final changed = jsonMap(jsonDecode(jsonEncode(data)));
    (changed['patients'] as List).first['firstName'] = 'Autre';
    await expectLater(V4Store.importData(changed), throwsFormatException);
    expect(V4Store.patients().single['firstName'], 'Anne');
  });
  test('Catalogue : cinq parcours valides avec sources, eczéma sans prière feu',
      () async {
    final catalog = await V4Store.catalog();
    expect(catalog.length, 5);
    for (final p in catalog) {
      expect(ProtocolValidator().validate(p).where((i) => i.blocking), isEmpty,
          reason: p.id);
    }
    final eczema = catalog.firstWhere((p) => p.id == 'ft-eczema');
    final plan =
        SessionEngine().build(mode: SessionMode.presentiel, selections: [
      ProtocolSelection(id: 'eczema', protocol: eczema, zones: const [
        BodyZone(id: 'bras', label: 'Bras gauche', side: 'gauche')
      ])
    ]);
    expect(plan.canStart, isTrue);
    expect(
        plan.actions
            .where((a) => a.definition.prayerId == 'priere-contre-le-feu'),
        isEmpty);
    final cut = plan.actions.indexWhere((a) => a.definition.id == 'cutanee');
    final abdomen =
        plan.actions.indexWhere((a) => a.definition.id == 'abdomen-rapides');
    expect(plan.actions[cut].duration.seconds, 300);
    expect(abdomen, greaterThan(cut));
  });
  test(
      'Distance : support explicite, deux frappes et absence de passes corporelles',
      () async {
    final p = (await V4Store.catalog()).firstWhere((p) => p.id == 'ft-entorse');
    final plan = SessionEngine().build(mode: SessionMode.distance, selections: [
      ProtocolSelection(
          id: 'd',
          protocol: p,
          zones: const [BodyZone(id: 'poignet', label: 'Poignet droit')])
    ]);
    expect(
        p.blocks
            .where((b) =>
                b.modes.contains(SessionMode.distance) &&
                b.phase != SessionPhase.preparation)
            .map((b) => b.phase)
            .toSet()
            .length,
        8);
    expect(plan.canStart, isTrue);
    expect(
        plan.actions.any(
            (a) => ProtocolValidator.physicalKinds.contains(a.definition.kind)),
        isFalse);
    expect(plan.actions.any((a) => a.definition.id == 'frappes'), isTrue);
  });
  test('Sauvegarde relue après fermeture de Hive et édition de fiche',
      () async {
    final id = await V4Store.createPatient('Anne', 'A');
    final p = (await V4Store.catalog()).firstWhere((p) => p.id == 'ft-eczema');
    final plan =
        SessionEngine().build(mode: SessionMode.presentiel, selections: [
      ProtocolSelection(
          id: 'e',
          protocol: p,
          zones: const [BodyZone(id: 'peau', label: 'Peau')])
    ]);
    final runner = SessionRunner(plan);
    runner.completeCurrent();
    await V4Store.saveSession(
        id: 's', patientId: id, runner: runner, notes: 'Observation');
    final data = p.toJson();
    data['title'] = 'Version personnelle';
    await V4Store.saveLocalProtocol(data);
    await Hive.close();
    Hive.init(dir.path);
    await V4Store.open();
    final saved = V4Store.sessions(id).single;
    expect(saved['notes'], 'Observation');
    final restored = SessionRunner.fromJson(jsonMap(saved['runner']));
    expect(restored.completed.length, 1);
    expect(restored.plan.selections.single['protocolId'], 'ft-eczema');
    expect(restored.plan.id, plan.id);
  });
  test('D export et restauration conservent les originaux V3 et associations',
      () async {
    await Hive.box(V4Store.metaBox).put('legacy-record:r', {
      'original': {'note': 'Personnel'},
      'id': 'legacy-record:r'
    });
    final backup = jsonMap(jsonDecode(jsonEncode(V4Store.exportData())));
    await Hive.close();
    final restoredDir = await Directory.systemTemp.createTemp('v4-restore-');
    try {
      Hive.init(restoredDir.path);
      await V4Store.open();
      expect(await V4Store.importData(backup), 1);
      expect(
          jsonMap(Hive.box(V4Store.metaBox).get('legacy-record:r'))['original'],
          {'note': 'Personnel'});
      expect(await V4Store.importData(backup), 0);
    } finally {
      await Hive.close();
      await restoredDir.delete(recursive: true);
    }
  });
  test(
      'Séance de quatre fiches : conventions supplémentaires puis prières puis travaux locaux',
      () async {
    final catalog = (await V4Store.catalog())
        .where((p) => p.modes.contains(SessionMode.presentiel));
    final selections = [
      for (final p in catalog)
        ProtocolSelection(id: p.id, protocol: p, zones: const [
          BodyZone(id: 'genou', label: 'Genou droit', side: 'droit')
        ])
    ];
    final plan = SessionEngine()
        .build(mode: SessionMode.presentiel, selections: selections);
    expect(plan.canStart, isTrue,
        reason: plan.issues.map((i) => i.message).join(' ; '));
    final supplementary =
        plan.actions.indexWhere((a) => a.definition.id == 'supplement');
    final lastSupplementary =
        plan.actions.lastIndexWhere((a) => a.definition.id == 'supplement');
    final firstPrayer =
        plan.actions.indexWhere((a) => a.definition.kind == ActionKind.prayer);
    final lastPrayer = plan.actions
        .lastIndexWhere((a) => a.definition.kind == ActionKind.prayer);
    final firstLocal = plan.actions.indexWhere((a) => [
          ActionKind.imposition,
          ActionKind.rapidPasses
        ].contains(a.definition.kind));
    expect(supplementary, greaterThan(0));
    expect(lastSupplementary, lessThan(firstPrayer));
    expect(lastPrayer, lessThan(firstLocal));
    expect(
        plan.actions
            .where((a) => a.definition.kind == ActionKind.circulation)
            .map((a) => a.definition.gesture?.end)
            .toList(),
        ['troisième œil', 'gorge', 'cœur', 'plexus', 'sacré', 'racine']);
    expect(
        plan.actions
            .where((a) => a.definition.kind == ActionKind.prayer)
            .length,
        5);
  });
  test('Import complet valide avant toute écriture', () async {
    final original = await V4Store.createPatient('Anne', 'A');
    final data = {
      'schemaVersion': 4,
      'patients': [
        {'id': 'new', 'firstName': 'New', 'lastName': 'A'}
      ],
      'sessions': [
        {'id': 'bad', 'patientId': 'absent', 'createdAt': 'x', 'updatedAt': 'x'}
      ],
      'customProtocols': []
    };
    await expectLater(V4Store.importData(data), throwsFormatException);
    expect(V4Store.patients().map((p) => p['id']).toList(), [original]);
  });
}
