import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:coupeur_de_feu_app/main.dart';
import 'package:coupeur_de_feu_app/v4/models.dart';
import 'package:coupeur_de_feu_app/v4/screens.dart';
import 'package:coupeur_de_feu_app/v4/store.dart';
import 'package:coupeur_de_feu_app/v4/runner.dart';

Future<void> settleIo(WidgetTester t, {bool Function()? until}) async {
  for (var i = 0; i < 1000; i++) {
    await t
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await t.pump(const Duration(milliseconds: 30));
    if (until != null ? until() : !t.binding.hasScheduledFrame) return;
  }
  if (until != null) {
    expect(until(), isTrue, reason: 'Transition ou écriture non terminée');
  }
}

Future<void> tapVisible(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pump();
  await t.tap(f);
  await settleIo(t);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  late String patient;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('v4-journey-');
    Hive.init(dir.path);
    await V4Store.open();
    patient = await V4Store.createPatient('Anne', 'Martin');
    await V4Store.catalog();
  });
  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });
  const scenarios = [
    ['ft-entorse'],
    ['ft-eczema'],
    ['ft-entorse', 'ft-eczema'],
    ['ft-entorse', 'ft-eczema', 'ft-arthrose'],
    ['ft-entorse', 'ft-eczema', 'ft-arthrose', 'ft-insuffisance-veineuse']
  ];
  for (var caseIndex = 0; caseIndex < 7; caseIndex++) {
    final ids = scenarios[caseIndex < 5 ? caseIndex : 1],
        distance = caseIndex == 6,
        multi = caseIndex == 5;
    testWidgets(
        'Parcours complet ${caseIndex + 1} : ${ids.join(' + ')} ${distance ? 'distance' : multi ? 'plusieurs zones' : 'présentiel'}',
        (t) async {
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(const MyApp());
      await settleIo(t,
          until: () => find.text('Anne Martin').evaluate().isNotEmpty);
      await tapVisible(t, find.text('Anne Martin'));
      await tapVisible(t, find.text('Nouvelle séance'));
      await settleIo(t,
          until: () => find
              .byKey(const ValueKey('motif-ft-entorse'))
              .evaluate()
              .isNotEmpty);
      if (distance) {
        await t.tap(find.text('Distance'));
        await settleIo(t);
      }
      for (final id in ids) {
        await tapVisible(t, find.byKey(ValueKey('motif-$id')));
      }
      for (final id in ids) {
        final row = find.byKey(ValueKey('zones-$id'));
        await t.scrollUntilVisible(row, 200,
            scrollable: find.byType(Scrollable).first);
        await t.pump();
        await t.tap(row);
        await settleIo(t);
        final label = id == 'ft-entorse' ? 'Cheville droite' : 'Genou droit';
        await tapVisible(t, find.byKey(ValueKey('zone-$label')));
        if (multi) {
          await tapVisible(t, find.byKey(const ValueKey('zone-Genou gauche')));
        }
        await t.tap(find.byKey(const ValueKey('confirm-zones')));
        await settleIo(t);
      }
      final preview = find.byKey(const ValueKey('session-preview'));
      expect(t.getCenter(preview).dy, lessThan(844));
      await t.tap(preview);
      await settleIo(t);
      expect(find.byKey(const ValueKey('chapter-commonIntentions')),
          findsOneWidget);
      expect(find.textContaining('points à vérifier conservés'), findsNothing);
      final start = find.byKey(const ValueKey('session-start'));
      expect(t.getCenter(start).dy, lessThan(844));
      expect(t.widget<FilledButton>(start).onPressed, isNotNull);
      await t.tap(start);
      await settleIo(t);
      final player = t.widget<V4PlayerScreen>(find.byType(V4PlayerScreen));
      final runner = player.runner;
      final common = runner.plan.actions
          .where((a) => a.definition.conventionNumber != null)
          .map((a) => a.definition.conventionNumber)
          .toSet();
      expect(common.length, 14);
      expect(
          runner.plan.actions
              .where((a) => a.definition.kind == ActionKind.accueil)
              .length,
          1);
      expect(
          runner.plan.actions
              .where((a) => a.definition.kind == ActionKind.debrief)
              .length,
          1);
      if (distance) {
        expect(
            runner.plan.actions.any((a) => [
                  ActionKind.rapidPasses,
                  ActionKind.slowPasses,
                  ActionKind.imposition,
                  ActionKind.circulation,
                  ActionKind.sweep
                ].contains(a.definition.kind)),
            isFalse);
      }
      if (ids.length == 1 && ids.single == 'ft-eczema') {
        expect(
            runner.plan.actions
                .any((a) => a.definition.prayerId == 'priere-contre-le-feu'),
            isFalse);
      }
      expect(
          runner.plan.actions
              .where((a) => a.definition.id == 'priere-commune')
              .length,
          ids.contains('ft-eczema') ? 1 : 0);
      for (final id in ids) {
        expect(
            runner.plan.actions
                .where((a) => a.origins.contains(id) && a.zones.isNotEmpty),
            isNotEmpty);
      }
      if (multi) {
        expect(
            runner.plan.actions
                .where((a) => a.definition.id == 'cutanee')
                .length,
            2);
      }
      await t.tap(find.byKey(const ValueKey('session-pause')));
      await t.pump();
      expect(runner.paused, isTrue);
      var steps = 0;
      while (!runner.finished) {
        if (runner.current!.definition.kind == ActionKind.prayer) {
          expect(find.byKey(const ValueKey('session-formulation')),
              findsOneWidget);
          expect(runner.current!.definition.formulation?.isNotEmpty, isTrue);
        }
        if (runner.current!.definition.kind == ActionKind.debrief) {
          await t.scrollUntilVisible(
              find.byKey(const ValueKey('session-notes')), 250,
              scrollable: find.byType(Scrollable).first);
          await t.pump();
          await t.enterText(find.byKey(const ValueKey('session-notes')),
              'Observation scénario ${caseIndex + 1}');
        }
        final before = runner.currentIndex;
        await t.tap(find.byKey(const ValueKey('session-next')));
        await t.pump();
        await t.pump();
        expect(runner.currentIndex, before + 1);
        if (++steps > 150) fail('Boucle de guidage');
      }
      expect(find.text('Séance terminée'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('session-finish')));
      await settleIo(t,
          until: () => find.byType(V4PlayerScreen).evaluate().isEmpty);
      expect(find.text('Magnétisme V4'), findsOneWidget);
      final history = V4Store.sessions(patient);
      expect(history.length, 1);
      expect(history.single['completed'], isTrue);
      expect(history.single['notes'], 'Observation scénario ${caseIndex + 1}');
      expect(SessionRunner.fromJson(jsonMap(history.single['runner'])).finished,
          isTrue);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      var closed = false;
      Hive.close().then((_) {
        closed = true;
      });
      await settleIo(t, until: () => closed);
    });
  }
}
