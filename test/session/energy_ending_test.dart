import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:coupeur_de_feu_app/session/session_plan.dart';
import 'package:coupeur_de_feu_app/widgets/energy_ending_guidance.dart';

void main() {
  final documents = (jsonDecode(File('assets/data/magnetisme_protocoles.json').readAsStringSync()) as Map)['fiches'] as List;
  final guides = jsonDecode(File('assets/data/guide_v33.json').readAsStringSync()) as Map;
  GuideFiche fiche(String id) {
    final raw = Map<String, dynamic>.from(documents.firstWhere((d) => d['id'] == id) as Map);
    raw['guideV33'] = guides[id];
    return GuideFiche.fromJson(raw);
  }

  for (final ids in [
    ['ft-entorse'],
    ['ft-entorse', 'ft-eczema'],
    ['ft-entorse', 'ft-eczema', 'ft-arthrose'],
  ]) {
    test('Fin unique, deux opérations distinctes et ordonnées : $ids', () {
      final plan = SessionPlanner.build(ids.map(fiche).toList(), thot: true);
      expect(plan.canStart, isTrue);
      final ending = plan.steps.where((s) => ['circulation', 'balayage'].contains(s.kind)).toList();
      expect(ending.map((s) => s.id), ['circulation', 'balayage']);
      expect(plan.steps.indexOf(ending[1]), plan.steps.indexOf(ending[0]) + 1);
      expect(plan.steps[plan.steps.indexOf(ending[1]) + 1].kind, 'debrief');
      expect(ending.every((s) => s.seconds == null), isTrue,
          reason: 'Les durées indicatives ne doivent pas valider automatiquement les gestes.');
      final distance = SessionPlanner.build(ids.map(fiche).toList(), distance: true, thot: true);
      expect(distance.steps.any((s) => ['circulation', 'balayage'].contains(s.kind)), isFalse);
    });
  }

  test('Ne pas ajouter la fin complète à un suivi court documenté', () {
    final plan = SessionPlanner.build([fiche('ft-zona')], visits: {'ft-zona': 'court'});
    expect(plan.steps.any((s) => ['circulation', 'balayage'].contains(s.kind)), isFalse);
  });

  for (final circulation in [true, false]) {
    testWidgets('Rubrique commune, instructions et validation indépendantes : $circulation', (tester) async {
      var validated = false;
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(
        child: EnergyEndingGuidance(
          circulation: circulation,
          instructions: const Text('Instructions de la technique ou contenu personnel conservé'),
          validation: TextButton(onPressed: () => validated = true, child: const Text('Valider les gestes')),
        ),
      ))));
      expect(find.text(EnergyEndingGuidance.heading), findsOneWidget);
      expect(find.textContaining(circulation ? 'Fiche L' : 'Fiche M'), findsWidgets);
      expect(find.textContaining(circulation ? 'environ 5 minutes' : '30 secondes à 1 minute'), findsOneWidget);
      expect(find.text('Instructions de la technique ou contenu personnel conservé'), findsOneWidget);
      expect(validated, isFalse);
      await tester.ensureVisible(find.text('Valider les gestes'));
      await tester.tap(find.text('Valider les gestes'));
      expect(validated, isTrue);
    });
  }
}
