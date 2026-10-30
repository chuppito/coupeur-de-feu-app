import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:coupeur_de_feu_app/v4/store.dart';
import 'package:coupeur_de_feu_app/v4/migration.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('v4-migration-');
    Hive.init(dir.path);
    await V4Store.open();
    await Hive.openBox('magnetisme_sessions');
  });
  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });
  test('D sauvegarde avant migration, répétition idempotente et V3 inchangée',
      () async {
    final box = Hive.box('magnetisme_sessions');
    await box
        .put(2, {'nomPatient': 'Anne', 'nomFamille': 'A', 'note': 'original'});
    final before = box.toMap();
    final snapshot = LegacyMigration.captureOpenV3Boxes();
    expect(await LegacyMigration.stage(snapshot), 1);
    expect(await LegacyMigration.stage(snapshot), 0);
    expect(box.toMap(), before);
    expect(LegacyMigration.records().single['review'], 'needsReview');
    expect(
        Hive.box(V4Store.metaBox)
            .keys
            .where((k) => k.toString().startsWith('legacy-backup:'))
            .length,
        1);
  });
  test('D homonymes non regroupés, associations explicites et non écrasées',
      () async {
    final a = await V4Store.createPatient('Anne', 'A'),
        b = await V4Store.createPatient('Anne', 'A');
    await LegacyMigration.stage({
      'magnetisme_sessions': {
        '1': {'nomPatient': 'Anne'},
        '2': {'nomPatient': 'Anne'}
      }
    });
    final rows = LegacyMigration.records();
    expect(rows.length, 2);
    expect(LegacyMigration.linkedPatient(rows.first['id'] as String), isNull);
    await LegacyMigration.link(rows.first['id'] as String, a);
    await LegacyMigration.link(rows.last['id'] as String, b);
    await expectLater(
        LegacyMigration.link(rows.first['id'] as String, b), throwsStateError);
  });
  test('D version personnelle conservée comme original, pas interprétée',
      () async {
    await LegacyMigration.stage({
      'magnetisme_library_custom': {
        'x': {'id': 'ft-eczema', 'contenu': 'Ma prière personnelle'}
      }
    });
    expect(LegacyMigration.records().single['original']['contenu'],
        'Ma prière personnelle');
    expect(Hive.box(V4Store.customBox).isEmpty, isTrue);
  });
  test('D nouvelle version historique conservée sans remplacer la précédente',
      () async {
    await LegacyMigration.stage({
      'x': {
        '1': {'note': 'avant'}
      }
    });
    await LegacyMigration.stage({
      'x': {
        '1': {'note': 'après'}
      }
    });
    expect(LegacyMigration.records().length, 2);
  });
}
