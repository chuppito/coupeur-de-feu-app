import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:coupeur_de_feu_app/v4/models.dart';
import 'package:coupeur_de_feu_app/v4/engine.dart';
import 'package:coupeur_de_feu_app/v4/runner.dart';
import 'package:coupeur_de_feu_app/v4/store.dart';
import 'package:coupeur_de_feu_app/v4/screens.dart';
import 'package:coupeur_de_feu_app/widgets/interactive_body.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('v4-widget-');
    Hive.init(dir.path);
    await V4Store.open();
  });
  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });
  testWidgets('Schéma V4 respecte les côtés anatomiques face et dos',
      (tester) async {
    bool? front;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: InteractiveBody(
                anatomicalOrientation: true,
                selectedZones: const {},
                onViewChanged: (v) => front = v,
                onZoneTap: (_) {}))));
    expect(tester.getCenter(find.byTooltip('Main droite')).dx,
        lessThan(tester.getCenter(find.byTooltip('Main gauche')).dx));
    await tester.tap(find.text('Dos'));
    await tester.pump();
    expect(front, isFalse);
    expect(tester.getCenter(find.byTooltip('Main droite')).dx,
        greaterThan(tester.getCenter(find.byTooltip('Main gauche')).dx));
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'Aperçu puis lecteur V4 : minuteur, pause et début de prochaine étape',
      (tester) async {
    const id = 'patient-test';
    Json? savedSnapshot;
    final p = ProtocolDefinition(
        id: 'test',
        title: 'Test',
        category: 'test',
        blocks: [
          ProtocolBlock(id: 'b', actions: [
            for (var i = 0; i < 2; i++)
              ActionDefinition(
                  id: 'a$i',
                  title: i == 0 ? 'Première étape' : 'Deuxième étape',
                  instruction: 'Consigne de test. ' * 20,
                  kind: ActionKind.intention,
                  duration: const DurationSpec.exact(240),
                  autoAdvance: true,
                  sources: const [
                    SourceRef(
                        id: 's', lesson: 'test', url: 'https://example.org')
                  ])
          ])
        ]);
    final runner = SessionRunner(SessionEngine().build(
        mode: SessionMode.presentiel,
        selections: [ProtocolSelection(id: 'test', protocol: p)]));
    await tester.pumpWidget(MaterialApp(
        home: V4PlayerScreen(
            runner: runner,
            sessionId: 'test-session',
            persist: (r, n, a) async {
              savedSnapshot = r.toJson();
            },
            patientId: id,
            patientName: 'Anne A')));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)));
    });
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('4:00'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Terminer cette étape'), 300,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Terminer cette étape'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(runner.completed.length, 1);
    await tester.pump();
    expect(find.text('Deuxième étape'), findsOneWidget);
    expect(tester.getTopLeft(find.byKey(const ValueKey('v4-current-title'))).dy,
        lessThan(160));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(milliseconds: 300));
    expect(runner.paused, isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(SessionRunner.fromJson(savedSnapshot!).completed.length, 1);
  });
  testWidgets('Préparation lisible sur petit écran et zones conservées',
      (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final id =
        (await tester.runAsync(() => V4Store.createPatient('Anne', 'A')))!;
    final catalog = (await tester.runAsync(V4Store.catalog))!;
    await tester.pumpWidget(MaterialApp(
        home: V4SetupScreen(
            patientId: id,
            patientName: 'Anne A',
            catalog: Future.value(catalog))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entorse'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byType(InteractiveBody), 200);
    expect(find.byType(InteractiveBody), findsOneWidget);
    await tester.scrollUntilVisible(find.byTooltip('Genou droit'), 200);
    await tester.pump();
    expect(tester.getCenter(find.byTooltip('Genou droit')).dy, lessThan(720));
    await tester.tap(find.byTooltip('Genou droit'), warnIfMissed: true);
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Voir l’aperçu complet'), 300);
    await tester.tap(find.text('Voir l’aperçu complet'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
