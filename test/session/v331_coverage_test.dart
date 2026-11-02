import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:coupeur_de_feu_app/session/session_plan.dart';

void main(){
  final raw=(jsonDecode(File('assets/data/magnetisme_protocoles.json').readAsStringSync()) as Map)['fiches'] as List;
  final guides=jsonDecode(File('assets/data/guide_v33.json').readAsStringSync()) as Map;
  final fiches=raw.where((f)=>f['type']=='fiche_technique').map((f)=>GuideFiche.fromJson({...Map<String,dynamic>.from(f as Map),'guideV33':guides[f['id']]})).toList();
  bool archived(GuideFiche f)=>f.actions.singleOrNull?.kind=='personnel';
  bool unsupported(GuideFiche f)=>archived(f)||f.id=='ft-couper-le-feu';
  test('57 fiches : 46 structurées et 11 archives explicitement non vérifiées',(){
    expect(fiches.length,57);expect(guides.length,57);
    expect(fiches.where(archived).length,11);
    for(final f in fiches.where(archived))expect(f.actions.single.documented,isFalse);
  });
  for(final f in fiches)for(final distance in [false,true]){
    test('${f.id} ${distance?'distance':'présentiel'} : couverture et pertes détectées',(){
      final p=SessionPlanner.build([f],distance:distance,zones:{f.title:{'Zone gauche','Zone droite'}});
      expect(p.canStart,!(distance&&unsupported(f)));
      if(!p.canStart)return;
      for(final a in f.actions){
        if(['accueil','bilan','degagement','circulation','balayage','debrief'].contains(a.kind))continue;
        if(a.kind=='communes'){
          expect(p.steps.singleWhere((s)=>s.kind=='communes').text,contains(a.text));continue;
        }
        if(distance&&['lente','flux'].contains(a.kind))continue;
        final s=p.steps.singleWhere((s)=>s.id=='${f.id}:${a.id}');
        expect(s.text,distance&&s.kind=='distance'?a.distanceText:a.text);
        expect(s.seconds,a.seconds);expect(s.repetitions,a.repetitions);
        expect(s.condition,a.condition);expect(s.zones,containsAll(['Zone gauche','Zone droite']));
      }
      if(distance)expect(p.steps.any((s)=>['rapide','lente','flux','imposition'].contains(s.kind)),isFalse);
    });
  }
  test('Toutes les combinaisons de 1 à 3 fiches : aucun travail propre perdu ni doublonné',(){
    for(var i=0;i<fiches.length;i++)for(var j=i;j<fiches.length;j++)for(var k=j;k<fiches.length;k++){
      final selected=<GuideFiche>{fiches[i],fiches[j],fiches[k]}.toList();
      for(final distance in [false,true]){
        final p=SessionPlanner.build(selected,distance:distance,thot:true);
        final blocked=selected.any(archived)&&selected.length>1 || distance&&selected.any(unsupported);
        expect(p.canStart,!blocked,reason:'${selected.map((f)=>f.id)} / $distance');
        if(!p.canStart)continue;
        expect(p.steps.map((s)=>s.id).toSet().length,p.steps.length);
        expect(p.steps.where((s)=>s.kind=='thot').length,1);
        for(final f in selected){
          final expected=f.actions.where((a)=>!['accueil','bilan','degagement','communes','circulation','balayage','debrief'].contains(a.kind)&&!(distance&&['lente','flux'].contains(a.kind))).map((a)=>'${f.id}:${a.id}').toList();
          expect(p.steps.where((s)=>s.ficheId==f.id).map((s)=>s.id).toList(),expected,reason:f.id);
        }
      }
    }
  },timeout:const Timeout(Duration(minutes:3)));
  test('Arthrite deux prières ; asthme sans passes dans une prière ; feu une minute',(){
    final ar=fiches.singleWhere((f)=>f.id=='ft-arthrite');
    expect(ar.actions.where((a)=>a.kind=='priere').length,2);
    final asthma=fiches.singleWhere((f)=>f.id=='ft-asthme');
    expect(asthma.actions.singleWhere((a)=>a.kind=='priere').text, isNot(contains('Passes rapides')));
    expect(asthma.actions.singleWhere((a)=>a.id=='poumons-rapides').route,'Couronne → plexus');
    expect(fiches.singleWhere((f)=>f.id=='ft-couper-le-feu').actions.last.seconds,60);
  });
  test('Radio : témoin et précondition de première visite obligatoires',(){
    final f=fiches.singleWhere((f)=>f.id=='ft-traitements-lourds-aide-aux');
    expect(SessionPlanner.build([f],distance:true,visits:{f.id:'radio'}).canStart,isFalse);
    final p=SessionPlanner.build([f],distance:true,visits:{f.id:'radio'},radioConnectionConfirmed:true);
    expect(p.canStart,isTrue);expect(p.steps.any((s)=>s.kind=='temoin'),isTrue);
    expect(p.steps.where((s)=>s.ficheId==f.id).every((s)=>s.kind=='priere'),isTrue);
  });
  test('57 fiches : aucun retour court implicite hors zona/verrue présentiels',(){
    for(final f in fiches)for(final distance in [false,true]){
      final p=SessionPlanner.build([f],distance:distance,visits:{f.id:'court'});
      final normal=SessionPlanner.build([f],distance:distance);
      if(!distance&&['ft-zona','ft-verrue'].contains(f.id)){
        expect(p.steps.any((s)=>s.kind=='communes'),isFalse);
        expect(p.steps.where((s)=>s.ficheId==f.id).every((s)=>['priere','imposition'].contains(s.kind)),isTrue);
      }else{
        expect(p.steps.map((s)=>s.id),normal.steps.map((s)=>s.id));
        expect(p.canStart,normal.canStart);
      }
    }
  });
  test('Durées locales : 5, 2 minutes et intentions séparées dans les sept fiches',(){
    const expected={'ft-acne':[300],'ft-eczema':[300],'ft-constipation':[120],
      'ft-herpes':[120,120],'ft-verrue':[120,120],'ft-zona':[120,120,120],'ft-psoriasis':[300,300]};
    for(final e in expected.entries){
      final f=fiches.singleWhere((f)=>f.id==e.key);
      expect(f.actions.where((a)=>a.seconds!=null).map((a)=>a.seconds).toList(),e.value,reason:e.key);
    }
  });
}
