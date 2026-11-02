import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:coupeur_de_feu_app/session/session_plan.dart';
import 'package:coupeur_de_feu_app/session/convention_timing.dart';

void main() {
  final raw=(jsonDecode(File('assets/data/magnetisme_protocoles.json').readAsStringSync()) as Map)['fiches'] as List;
  final guides=jsonDecode(File('assets/data/guide_v33.json').readAsStringSync()) as Map;
  for(final d in raw) { d['guideV33']=guides[d['id']]; }
  GuideFiche f(String id)=>GuideFiche.fromJson(Map<String,dynamic>.from(raw.firstWhere((d)=>d['id']==id) as Map));
  SessionPlan plan(List<String> ids,{bool distance=false,bool thot=false,Map<String,String> visits=const {}})=>SessionPlanner.build(ids.map(f).toList(),distance:distance,thot:thot,visits:visits,zones:{'Eczéma':{'Coude droit · antérieure'},'Entorse':{'Cheville gauche','Cheville droite'}});
  test('Trois SOINS maximum ; les prières ne sont pas limitées',(){
    final p=plan(['ft-eczema','ft-goutte','ft-hemorroides']);
    expect(p.canStart,isTrue);expect(p.steps.where((s)=>s.kind=='priere').length,greaterThan(3));
    expect(plan(['ft-eczema','ft-zona','ft-entorse','ft-arthrose']).canStart,isFalse);
  });
  for(final ids in [ ['ft-entorse'],['ft-eczema'],['ft-entorse','ft-eczema'],['ft-entorse','ft-eczema','ft-arthrose'] ]) {
    test('Trame unique ${ids.join('+')}',(){final p=plan(ids);expect(p.canStart,isTrue);for(final k in ['contact','bilan','communes','circulation','balayage','debrief']){expect(p.steps.where((s)=>s.kind==k).length,1);} });
  }
  test('Eczéma : peau puis abdomen complet, sans trajet du coude sur abdomen',(){
    final p=plan(['ft-eczema']);final a=p.steps.where((s)=>s.ficheId=='ft-eczema').toList();
    expect(a.map((s)=>s.kind),['priere','imposition','rapide','flux','lente','imposition']);
    expect(a[1].zones,contains('Coude droit · antérieure'));
    expect(a[3].target,'Abdomen et système intestinal');expect(a[3].route,contains('plexus'));expect(a[3].zones,contains('Coude droit · antérieure'));
  });
  test('Sciatique : toutes les actions lombaires avant la jambe',(){
    final a=plan(['ft-sciatique']).steps.where((s)=>s.ficheId=='ft-sciatique').toList();
    expect(a.map((s)=>s.kind),['intentions','rapide','flux','lente','imposition','rapide','flux','lente']);
    expect(a[4].target,'Bas du dos');expect(a[5].target,contains('postérieure'));
  });
  for(final ids in [['ft-eczema','ft-zona'],['ft-zona','ft-eczema']]){
    test('Exception zona avant conventions, indépendamment du premier motif $ids',(){
      final p=plan(ids);final c=p.steps.indexWhere((s)=>s.kind=='communes');
      expect(p.steps.indexWhere((s)=>s.ficheId=='ft-zona'&&s.kind=='priere'),lessThan(c));
      expect(p.steps.indexWhere((s)=>s.ficheId=='ft-zona'&&s.kind=='imposition'),lessThan(c));
      expect(p.steps.indexWhere((s)=>s.ficheId=='ft-eczema'&&s.kind=='priere'),greaterThan(c));
    });
  }
  test('Distance : témoin et travaux sur support pour chaque région, aucune passe',(){
    for(final ids in [['ft-eczema'],['ft-sciatique'],['ft-entorse','ft-eczema','ft-arthrose']]) {
      final p=plan(ids,distance:true);expect(p.canStart,isTrue);
      expect(p.steps.any((s)=>s.kind=='temoin'),isTrue);
      expect(p.steps.where((s)=>['rapide','lente','imposition','flux','balayage','circulation'].contains(s.kind)),isEmpty);
      for(final id in ids)expect(p.steps.any((s)=>s.ficheId==id&&s.kind=='distance'),isTrue);
      expect(p.steps.where((s)=>s.kind=='distance').every((s)=>s.text.isNotEmpty),isTrue);
    }
  });
  test('Zona et verrue en suivi : prière et imposition de la vraie fiche',(){
    for(final id in ['ft-zona','ft-verrue']) {
      final p=plan([id],visits:{id:'court'});
      expect(p.steps.map((s)=>s.kind),id=='ft-zona'?['contact','priere','imposition','imposition','imposition','debrief']:['contact','priere','imposition','imposition','debrief']);
      expect(p.steps[1].text,contains(id=='ft-zona'?'Prière contre le feu':'je t\'enlève tes verrues'));
    }
  });
  test('Suivi court zona + eczéma complet : garder les besoins des deux',(){
    final p=plan(['ft-zona','ft-eczema'],visits:{'ft-zona':'court'});
    expect(p.steps.where((s)=>s.kind=='communes').length,1);
    expect(p.steps.where((s)=>s.ficheId=='ft-zona').map((s)=>s.kind),['priere','imposition','imposition','imposition']);
    expect(p.steps.where((s)=>s.ficheId=='ft-eczema'&&s.kind=='imposition').length,2);
  });
  test('Pas de raccourci inventé à distance pour les verrues',(){
    expect(plan(['ft-verrue'],distance:true,visits:{'ft-verrue':'court'}).steps.any((s)=>s.kind=='communes'),isTrue);
  });
  test('Radio : choix explicite uniquement à distance, pas chimio automatique',(){
    const id='ft-traitements-lourds-aide-aux';
    expect(plan([id],distance:true,visits:{id:'radio'}).steps.map((s)=>s.kind),['contact','temoin','priere','debrief']);
    expect(plan([id],distance:true).steps.any((s)=>s.kind=='communes'),isTrue);
  });
  test('Pendule sélectionné conservé une fois, en présentiel et distance',(){
    for(final distance in [true,false]) {final p=plan(['ft-entorse','ft-eczema'],thot:true,distance:distance);expect(p.steps.where((s)=>s.kind=='thot').length,1);}
  });
  test('Zones multiples conservées par motif',(){
    final a=plan(['ft-entorse','ft-eczema']).steps.firstWhere((s)=>s.ficheId=='ft-entorse'&&s.kind=='rapide');
    expect(a.zones,containsAll(['Cheville gauche','Cheville droite']));
  });
  test('Toutes les fiches structurées préservent leurs actions dans l’ordre',(){
    for(final j in raw.where((d)=>(d['guideV33'] as List? ?? []).isNotEmpty && (d['guideV33'] as List).first['kind']!='personnel')){
      final fiche=GuideFiche.fromJson(Map<String,dynamic>.from(j as Map));
      final p=SessionPlanner.build([fiche]);expect(p.canStart,isTrue,reason:fiche.id);
      final expected=fiche.actions.where((a)=>!['accueil','bilan','degagement','circulation','balayage','debrief','communes'].contains(a.kind)).map((a)=>'${fiche.id}:${a.id}');
      expect(p.steps.where((s)=>s.ficheId==fiche.id).map((s)=>s.id),expected,reason:fiche.id);
    }
  });
  test('Cruralgie : jambe antérieure sur le dos',(){expect(f('ft-cruralgie').actions.firstWhere((a)=>a.kind=='rapide'&&a.target.contains('Jambe')).text,contains('sur le dos'));});
  test('CM9 : minuteur 4 minutes puis deux sous-intentions de 30 s',(){
    final a=ConventionTiming.build(medication:true,observations:'magie noire',lowBlood:false).where((m)=>m.convention==8).toList();
    expect(a.map((m)=>m.seconds),[240,30,30]);expect(a[1].intention,contains('rééquilibre'));expect(a[2].intention,contains('recharge'));
  });
  test('CM8 réellement omise ; toxines et corps défaillants documentés',(){
    final a=ConventionTiming.build(medication:false,observations:'vigilance',lowBlood:true,weakBodies:{'2':'éthérique'});
    expect(a.any((m)=>m.convention==7),isFalse);expect(a.firstWhere((m)=>m.convention==8).seconds,120);
    expect(a.where((m)=>m.convention==8).last.intention,'Je recharge son corps éthérique');
    expect(a.firstWhere((m)=>m.convention==11).seconds,120);
  });
  test('Conflit d’ordre détecté au lieu de réordonner silencieusement',(){
    const fiche=GuideFiche('test','Test',[
      GuideAction(id:'c1',kind:'communes',text:'Communes'),
      GuideAction(id:'p',kind:'priere',text:'Prière'),
      GuideAction(id:'c2',kind:'communes',text:'Communes'),
    ]);
    final p=SessionPlanner.build([fiche]);expect(p.canStart,isFalse);expect(p.conflicts.single,contains('Conflit'));
  });

}
