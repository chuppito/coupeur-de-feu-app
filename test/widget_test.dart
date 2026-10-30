import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:coupeur_de_feu_app/main.dart';
import 'package:coupeur_de_feu_app/models/patient_session.dart';
import 'package:coupeur_de_feu_app/v4/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('v4-app-');
    Hive.init(dir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PatientSessionAdapter());
    }
    await Hive.openBox<PatientSession>('sessions');
    for (final n in [
      'magnetisme_sessions',
      'body_scans',
      'energy_assessments',
      'pendulum_cares',
      'app_meta'
    ]) {
      await Hive.openBox(n);
    }
    await V4Store.open();
  });
  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });
  testWidgets('Accueil réel et accès V4 sans remplacer le parcours V3',
      (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.text('Magnétisme'), findsOneWidget);
    expect(find.byTooltip('Nouvelle séance'), findsOneWidget);
    await tester.tap(find.byTooltip('Parcours V4'));
    await tester.pumpAndSettle();
    expect(find.text('Magnétisme V4'), findsOneWidget);
    expect(find.text('Nouveau patient'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
