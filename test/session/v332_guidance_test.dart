import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:coupeur_de_feu_app/session/session_plan.dart';
import 'package:coupeur_de_feu_app/session/guidance_text.dart';

void main(){
  final guides=jsonDecode(File('assets/data/guide_v33.json').readAsStringSync()) as Map;
  final raw=(jsonDecode(File('assets/data/magnetisme_protocoles.json').readAsStringSync()) as Map)['fiches'] as List;
  GuideFiche f(String id)=>GuideFiche.fromJson({...Map<String,dynamic>.from(raw.firstWhere((f)=>f['id']==id) as Map),'guideV33':guides[id]});
  test('Tous les contrôles sont suivis immédiatement du Thot concerné, avant la suite',(){
    for(final ids in [['ft-eczema','ft-entorse'],['ft-arthrose'],['ft-tabac-arret-du'],['ft-eczema','ft-entorse','ft-arthrose']]){
      final p=SessionPlanner.build(ids.map(f).toList(),thot:true,zones:{'Arthrose':{'Genou droit','Genou gauche'},'Entorse':{'Cheville droite'},'Eczéma':{'Coude gauche'}});
      expect(p.canStart,isTrue);
      for(var i=0;i<p.steps.length;i++){
        final step=p.steps[i];
        if(step.kind!='flux')continue;
        final next=p.steps[i+1];expect(next.kind,'thot');expect(next.ficheId,step.ficheId);
        expect(next.target,step.target);expect(next.route,step.route);expect(next.zones,step.zones);
      }
      final without=SessionPlanner.build(ids.map(f).toList());
      expect(without.steps.any((s)=>s.kind=='thot'),isFalse);
      for(final id in ids){
        expect(p.steps.where((s)=>s.ficheId==id&&s.kind!='thot').map((s)=>s.id),without.steps.where((s)=>s.ficheId==id).map((s)=>s.id));
      }
    }
  });
  test('Distance : Thot sur support avant l’intention, sans réintroduire de passes',(){
    final p=SessionPlanner.build([f('ft-eczema'),f('ft-entorse')],thot:true,distance:true);
    expect(p.canStart,isTrue);
    expect(p.steps.any((s)=>['flux','rapide','lente','imposition'].contains(s.kind)),isFalse);
    expect(p.steps.where((s)=>s.kind=='thot').length,3);
    for(final s in p.steps.where((s)=>s.kind=='thot')){expect(s.ficheId,isNotEmpty);}
    final skin=p.steps.firstWhere((s)=>s.ficheId=='ft-eczema'&&s.kind=='support');
    final thot=p.steps[p.steps.indexOf(skin)+1];expect(thot.kind,'thot');
    final intention=p.steps[p.steps.indexOf(skin)+2];expect(intention.kind,'distance');
    expect(p.needsSupportPreparation(intention),isFalse);
    expect(p.needsSupportPreparation(skin),isTrue);
  });
  test('Genoux : trajets séparés avec départs et arrivées, sans consignes de passes',(){
    expect(GuidanceText.selectedRoutes(['Genou droit','Genou gauche']),[
      'Genou droit : aine droite → genou droit → pied droit.',
      'Genou gauche : aine gauche → genou gauche → pied gauche.',
    ]);
    expect(GuidanceText.route('- 1. Passes rapides du chakra couronne au chakra sacré.'),'chakra couronne → chakra sacré.');
  });
  test('Nettoyage d’affichage sur les 57 fiches : seuls les préfixes parasites disparaissent',(){
    expect(GuidanceText.commonCues('Entorse : 4. Posez les 14 conventions\n\nEczéma : Posez les 14 conventions'),
      'Entorse : Posez les 14 conventions\n\nEczéma : Posez les 14 conventions');
    expect(guides.length,57);
    for(final aa in guides.values){for(final a in aa as List){
      final cleaned=GuidanceText.clean(a['text'] as String,kind:a['kind'] as String);
      if(a['kind']=='personnel'){expect(cleaned,(a['text'] as String).trim());continue;}
      expect(RegExp(r'^\s*(?:-\s*)?\d+[.)]\s').hasMatch(cleaned),isFalse);
    }}
    expect(GuidanceText.clean('6. 14 conventions, 20 passes rapides, 15 passes lentes, 2 minutes et 3 répétitions.',kind:'rapide'),'14 conventions, 20 passes rapides, 15 passes lentes, 2 minutes et 3 répétitions.');
    expect(GuidanceText.clean('6. Travaillez en passes sur les poumons et la trachée :\n- 1. Passes rapides du chakra couronne au chakra sacré.',kind:'rapide'),
      'Passes rapides du chakra couronne au chakra sacré.');
    expect(GuidanceText.clean('6. Travaillez en passes sur le dos, patient sur le ventre :\n- 1. Passes rapides.',kind:'rapide'),contains('patient sur le ventre'));
    expect(GuidanceText.clean('5. Intentions\n- 1. Première intention\n- 2. Seconde intention',kind:'intentions'),contains('- 2. Seconde intention'));
  });
  test('Tabac : deux régions et leurs deux séquences conservées et distinguées',(){
    final p=SessionPlanner.build([f('ft-tabac-arret-du')],thot:true);
    expect(p.steps.where((s)=>s.kind=='flux').length,2);
    expect(p.steps.where((s)=>s.kind=='thot').length,2);
    final titles=p.steps.where((s)=>s.kind=='rapide').map((s)=>s.title).toList();
    expect(titles.toSet().length,2);expect(titles.first,contains('Poumons'));expect(titles.last,contains('Abdomen'));
  });
  test('Régions paires : latéralité explicite, sans appliquer un côté aux travaux abdominaux',(){
    final route='Passes rapides du chakra aine au chakra genou, puis du chakra genou au chakra pied.';
    final paired=GuidanceText.fixedRoutes(route,['Genou droit','Genou gauche'],sideAware:true);
    expect(paired.length,2);expect(paired.first,contains('aine droite'));expect(paired.last,contains('pied gauche'));
    expect(GuidanceText.fixedRoutes('Couronne → plexus',['Coude droit','Coude gauche']),['Couronne → plexus']);
    expect(f('ft-insuffisance-veineuse').actions.where((a)=>a.kind=='flux').every((a)=>a.sideAware),isTrue);
  });
  test('Conseils sourcés, sans recommandations inventées pour les onze archives',(){
    final advice=jsonDecode(File('assets/data/advice_v332.json').readAsStringSync()) as Map;
    expect(advice.length,46);
    for(final entries in advice.values){for(final a in entries as List){expect(a['text'],isNotEmpty);expect(a['source'],isNotEmpty);expect(a['method'],isNotEmpty);}}
    expect(advice['ft-eczema'].first['time'],contains('05:36'));
    expect(advice['ft-tabac-arret-du'].first['time'],contains('06:39'));
    expect(advice['ft-infection'],isNull);
  });
}
