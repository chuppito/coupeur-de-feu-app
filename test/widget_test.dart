import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:coupeur_de_feu_app/screens/magnetisme_session_screen.dart';
import 'package:coupeur_de_feu_app/services/magnetisme_library_service.dart';
import 'package:coupeur_de_feu_app/services/magnetisme_session_service.dart';

void regressionWidget(String name, WidgetTesterCallback callback) => testWidgets(name, callback, timeout: const Timeout(Duration(minutes:1)));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Les opérations Hive sur disque sont attendues hors du temps simulé.
  late Directory dir;
  setUp(() async {
    dir=await Directory.systemTemp.createTemp('v33-test-');Hive.init(dir.path);
    await Hive.openBox(MagnetismeLibraryService.boxName);
    await Hive.openBox(MagnetismeSessionService.boxName);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',(_ )async=>const StandardMessageCodec().encodeMessage([null]));
  });
  tearDown(() async {await Hive.close();await dir.delete(recursive:true);});
  Future<void> visible(WidgetTester t,Finder f) async {
    if(f.evaluate().isEmpty) {
      await t.scrollUntilVisible(f.first, 450, maxScrolls:100, scrollable:find.byType(Scrollable).first);
    }
    await t.ensureVisible(f.first);await t.pumpAndSettle();
  }
  Future<void> start(WidgetTester t,{bool follow=false}) async {
    await t.runAsync(() => MagnetismeLibraryService.loadAll());
    await t.pumpWidget(MaterialApp(home:MagnetismeSessionScreen(prefillNom:'Test',prefillNomFamille:'V33',demarrerSuivi:follow)));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds:100)));
    await t.pumpAndSettle();
  }
  Future<void> select(WidgetTester t,String title) async {
    final chip=find.widgetWithText(FilterChip,title);
    await visible(t,chip);await t.tap(chip);await t.pumpAndSettle();
  }
  Future<void> openStep(WidgetTester t,String title) async {
    final header=find.text(title).last;await visible(t,header);await t.tap(header);await t.pumpAndSettle();
  }
  regressionWidget('Préparer eczéma, conserver le trajet abdominal, puis enregistrer et retrouver', (t) async {
    await start(t);await select(t,'Eczéma');
    await openStep(t,'Eczéma — Passes rapides');
    expect(find.textContaining('chakra plexus au chakra racine'),findsWidgets);
    await openStep(t,'Débriefing / observation');
    final obs=find.widgetWithText(TextField,'Observations générales');
    await visible(t,obs);await t.enterText(obs,'Observation test conservée');
    await t.tap(find.text('Enregistrer la séance'));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds:100)));
    await t.pumpAndSettle();
    final saved=MagnetismeSessionService.getForPatient('Test V33');
    expect(saved.length,1);expect(saved.single['observations'],'Observation test conservée');
    expect(saved.single['versionGuide'],'3.3');expect(saved.single['etapesIds'],isNotEmpty);
  });
  regressionWidget('Minuteur visible, pause/reprise et durée documentée', (t) async {
    await start(t);await select(t,'Entorse');await openStep(t,'14 conventions mentales');
    expect(find.text('01:00'),findsOneWidget);
    await visible(t,find.text('Démarrer'));await t.tap(find.text('Démarrer'));await t.pump(const Duration(seconds:2));
    expect(find.text('00:58'),findsOneWidget);
    await t.tap(find.text('Pause'));await t.pump(const Duration(seconds:3));expect(find.text('00:58'),findsOneWidget);
    await t.tap(find.text('Reprendre'));await t.pump(const Duration(seconds:1));expect(find.text('00:57'),findsOneWidget);
    await t.pumpWidget(const SizedBox());await t.pump();
  });
  regressionWidget('Trois motifs admis, quatrième refusé sans limiter les prières', (t) async {
    await start(t);for(final s in ['Entorse','Eczéma','Arthrose']){await select(t,s);}
    await select(t,'Zona');
    expect(find.textContaining('Maximum 3 soins par séance'),findsOneWidget);
    expect((t.widget(find.widgetWithText(FilterChip,'Zona')) as FilterChip).selected,isFalse);
    await t.tap(find.text('Enregistrer la séance'));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds:100)));
    await t.pumpAndSettle();
    expect((MagnetismeSessionService.getForPatient('Test V33').single['ftTitres'] as List).length,3);
  });
  regressionWidget('Zona suivi court : contenu réel et validation de la bonne étape', (t) async {
    await t.runAsync(() => MagnetismeSessionService.save({'nomPatient':'Test','nomFamille':'V33','date':'2026-11-01','ftTitres':['Zona'],'ftTitre':'Zona','zonesParPathologie':{'Zona':['Tronc droit']}}));
    await start(t,follow:true);await openStep(t,'Zona — Prière / formulation');
    final check=find.widgetWithText(CheckboxListTile,'Étape réalisée');
    await visible(t,check);await t.tap(check);await t.pumpAndSettle();
    expect(find.textContaining('guérir les terminaisons nerveuses'),findsWidgets);
    await t.tap(find.text('Enregistrer la séance'));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds:100)));
    await t.pumpAndSettle();
    final saved=MagnetismeSessionService.getForPatient('Test V33').first;
    expect(saved['etapesFaites'],[1]);expect((saved['zonesParPathologie'] as Map)['Zona'],['Tronc droit']);
    expect((saved['etapesIds'] as List).contains('communes'),isFalse);
  });
  regressionWidget('Parcours entier entorse : préparation, conventions, gestes et historique', (t) async {
    await start(t);await select(t,'Entorse');
    // Les trois premières étapes sont accueillies, réalisées puis suivies automatiquement.
    for(var i=0;i<3;i++) {
      final done=find.widgetWithText(CheckboxListTile,'Étape réalisée');
      await visible(t,done);await t.tap(done);await t.pumpAndSettle();
    }
    // 13 conventions incluses (8 omise), plus les deux sous-intentions de CM9.
    for(var i=0;i<15;i++) {
      final next=find.text('Réalisée → suivante');await visible(t,next);await t.tap(next);await t.pumpAndSettle();
    }
    // Toutes les étapes suivantes jusqu'au débriefing conservent leur ordre.
    for(var i=0;i<15;i++) {
      final debrief=find.widgetWithText(TextField,'Observations générales');
      if(debrief.evaluate().isNotEmpty) break;
      final done=find.widgetWithText(CheckboxListTile,'Étape réalisée');
      await visible(t,done);await t.tap(done);await t.pumpAndSettle();
    }
    final obs=find.widgetWithText(TextField,'Observations générales');
    expect(obs,findsOneWidget);await visible(t,obs);await t.enterText(obs,'Parcours terminé');
    await t.tap(find.text('Enregistrer la séance'));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds:100)));
    await t.pumpAndSettle();
    expect(MagnetismeSessionService.getForPatient('Test V33').single['observations'],'Parcours terminé');
    expect(t.takeException(),isNull);
  });

}
