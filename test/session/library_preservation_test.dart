import 'dart:convert';
import 'test_assets.dart';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:coupeur_de_feu_app/services/magnetisme_library_service.dart';
import 'package:coupeur_de_feu_app/services/magnetisme_session_service.dart';
import 'package:coupeur_de_feu_app/session/session_plan.dart';
void main(){
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  setUp(()async{dir=await Directory.systemTemp.createTemp('v33-preserve-');Hive.init(dir.path);await Hive.openBox(MagnetismeLibraryService.boxName);await Hive.openBox(MagnetismeSessionService.boxName);});
  tearDown(()async{await Hive.close();await dir.delete(recursive:true);});
  test('Prières séparées sans perte du texte articulaire',(){
    final guides=jsonDecode(File('assets/data/guide_v33.json').readAsStringSync()) as Map;
    final actions=guides['ft-arthrite'] as List;
    final prayers=actions.where((a)=>a['kind']=='priere').toList();
    expect(prayers.length,2);
    expect(prayers.first['text'],contains('CONTRE LE FEU'));
    expect(prayers.last['text'],contains('Cher Saint Thibault'));
    expect(prayers.last['text'],contains('Amen.'));
  });
  test('Une fiche personnelle reste stockée et son contenu prime sur le guide intégré',()async{
    const custom={'id':'ft-eczema','titre':'Eczéma','type':'fiche_technique','contenu':'Texte personnel conservé'};
    await MagnetismeLibraryService.saveLocal(custom);
    final docs=await MagnetismeLibraryService.loadAll(assets:TestAssets());final d=docs.firstWhere((d)=>d['id']=='ft-eczema');
    expect(d['contenu'],custom['contenu']);expect((d['guideV33'] as List).first['text'],custom['contenu']);
    expect(Hive.box(MagnetismeLibraryService.boxName).get('ft-eczema')['contenu'],custom['contenu']);
    expect(SessionPlanner.build([GuideFiche.fromJson(d)],distance:true).canStart,isFalse);
  });
  test('Historique et zones des anciennes séances ne sont pas modifiés par une nouvelle séance',()async{
    final old={'date':'2026-10-01','nomPatient':'Test','nomFamille':'V33','zonesParPathologie':{'Entorse':['Cheville gauche']},'champPersonnel':'à préserver'};
    await MagnetismeSessionService.save(old);await MagnetismeSessionService.save({'date':'2026-11-02','nomPatient':'Test','nomFamille':'V33','versionGuide':'3.3'});
    final history=MagnetismeSessionService.getForPatient('Test V33');expect(history.length,2);
    expect(history.last['zonesParPathologie'],old['zonesParPathologie']);expect(history.last['champPersonnel'],'à préserver');
  });
  test('Personnalisation des noms sans réécrire les prières stockées',(){
    const original='[Nom et prénom], je t’enlève tes verrues. [nom prénom]';
    expect(MagnetismeLibraryService.personalized(original,prenom:'Test',nom:'V33'),'Test V33, je t’enlève tes verrues. V33 Test');
    expect(original,contains('[Nom et prénom]'));
  });

}
