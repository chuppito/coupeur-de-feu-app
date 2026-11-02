/// Assemblage sans classement des gestes par mots-clés.
/// Chaque fiche porte une liste d'actions explicites dans guideV33.
class GuideAction {
  final String id, kind, text, target, route, source, distanceText, condition;
  final int? seconds;
  final int repetitions;
  final bool standalone, documented;
  final bool selectedRoute;
  const GuideAction({required this.id, required this.kind, required this.text,
    this.target = '', this.route = '', this.source = '', this.distanceText = '', this.selectedRoute=false,
    this.seconds, this.repetitions=1, this.condition='', this.standalone=false, this.documented=true});
  factory GuideAction.fromJson(Map<String, dynamic> j) => GuideAction(
    id: j['id'] as String, kind: j['kind'] as String, text: j['text'] as String,
    target: j['target'] as String? ?? '', route: j['route'] as String? ?? '',
    source: j['source'] as String? ?? '', distanceText:j['distanceText'] as String? ?? '', selectedRoute:j['selectedRoute']==true,
    seconds:j['seconds'] as int?, repetitions:j['repetitions'] as int? ?? 1,
    condition:j['condition'] as String? ?? '', standalone:j['standalone']==true, documented:j['documented']!=false);
}
class GuideFiche {
  final String id, title;
  final List<GuideAction> actions;
  const GuideFiche(this.id, this.title, this.actions);
  factory GuideFiche.fromJson(Map<String, dynamic> j) => GuideFiche(
    j['id'] as String, j['titre'] as String,
    (j['guideV33'] as List? ?? []).map((a) => GuideAction.fromJson(Map<String,dynamic>.from(a as Map))).toList());
}
class PlanStep {
  final String id, title, text, kind, ficheId, target, route, source;
  final List<String> zones;
  final int? seconds;
  final int repetitions;
  final String condition;
  final bool selectedRoute;
  const PlanStep({required this.id, required this.title, required this.kind,
    this.text = '', this.ficheId = '', this.target = '', this.route = '',
    this.source = '', this.zones = const [],this.selectedRoute=false,
    this.seconds,this.repetitions=1,this.condition=''});
}
class SessionPlan {
  final List<PlanStep> steps;
  final List<String> conflicts;
  const SessionPlan(this.steps, this.conflicts);
  bool get canStart => conflicts.isEmpty;
}
class SessionPlanner {
  static SessionPlan build(List<GuideFiche> fiches, {
    bool distance = false, bool scan = false, bool thot = false,
    Map<String,String> visits = const {}, Map<String,Set<String>> zones = const {},
    bool radioConnectionConfirmed=false,
  }) {
    if (fiches.length > 3) return const SessionPlan([], ['Maximum 3 soins par séance. Le nombre de prières n’est pas limité.']);
    final errors = <String>[];
    if(distance && fiches.any((f)=>f.id=='ft-traitements-lourds-aide-aux'&&visits[f.id]=='radio') && !radioConnectionConfirmed){
      errors.add('Suivi radiothérapie : confirmer une première séance complète et la connexion/photo déjà établie.');
    }
    final nodes = <String,PlanStep>{};
    final deps = <String,Set<String>>{};
    void node(PlanStep s) { nodes[s.id] = s; deps.putIfAbsent(s.id, () => {}); }
    void link(String a, String b) { if (a != b) deps[b]!.add(a); }
    String? tail;
    bool hasFull = false;
    bool shortFor(GuideFiche f) => !distance && visits[f.id] == 'court' &&
      const {'ft-zona','ft-verrue'}.contains(f.id);
    bool radioFor(GuideFiche f) => distance && visits[f.id] == 'radio' && f.id == 'ft-traitements-lourds-aide-aux';
    bool manualFor(GuideFiche f) => f.actions.length==1 && f.actions.single.kind=='personnel';
    bool standaloneFor(GuideFiche f) => f.actions.isNotEmpty && f.actions.first.standalone;
    hasFull = fiches.any((f) => !shortFor(f) && !radioFor(f) && !manualFor(f) && !standaloneFor(f));
    for (final entry in <String,String>{'contact':'Prise de contact',
      if (distance) 'temoin':'Préparer le témoin vitalisé / vérifier la connexion existante',
      if (hasFull) 'bilan':'Bilan énergétique',
      if (scan) 'scan':'Scan au pendule',
      if (hasFull) 'degagement':'Dégagement des entités / énergies négatives si nécessaire'}.entries) {
      node(PlanStep(id: entry.key, title:entry.value,kind:entry.key));
      if(tail!=null) link(tail!,entry.key);
      tail=entry.key;
    }
    final start=tail!;
    final cues=fiches.where((f)=>!shortFor(f)&&!radioFor(f)).expand((f)=>f.actions.where((a)=>a.kind=='communes').map((a)=>'${f.title} : ${a.text}')).toList();
    if(hasFull) node(PlanStep(id:'communes',title:'14 conventions mentales',kind:'communes',text:cues.join('\n\n')));
    final lastIds=<String>[];
    for(final f in fiches) {
      if(manualFor(f) && fiches.length>1) errors.add('${f.title} : fiche personnelle à vérifier avant une fusion de plusieurs soins.');
      if(f.actions.isEmpty) { errors.add('${f.title} : déroulé structuré absent.'); continue; }
      final actionIds=<String>{};
      for(final a in f.actions){
        if(!actionIds.add(a.id))errors.add('${f.title} : identifiant d’action dupliqué ${a.id}.');
        if((a.seconds!=null&&a.seconds!<=0)||a.repetitions<1)errors.add('${f.title} : durée ou répétitions invalides pour ${a.id}.');
      }
      var prev=start;
      for(final a in f.actions) {
        if(distance && a.kind=='personnel') { errors.add('${f.title} : adaptation à distance de la fiche personnelle à préciser.'); continue; }
        if(shortFor(f) && !const {'priere','imposition'}.contains(a.kind)) continue;
        if(radioFor(f) && a.kind!='priere') continue;
        if(a.kind=='communes') { if(hasFull){link(prev,'communes');prev='communes';}continue; }
        if(const {'accueil','bilan','degagement','circulation','balayage','debrief'}.contains(a.kind)) continue;
        if(distance && const {'lente','flux'}.contains(a.kind)) continue;
        var kind=a.kind;
        if(distance && const {'rapide','imposition','visualisation','local'}.contains(kind)) kind='distance';
        if(kind=='distance' && a.distanceText.trim().isEmpty) {
          errors.add('${f.title} : adaptation sur support non documentée pour ${a.id}.');
        }
        final id='${f.id}:${a.id}';
        const labels={'priere':'Prière / formulation','intentions':'Conventions supplémentaires',
          'rapide':'Passes rapides','flux':'Contrôle des flux','lente':'Passes lentes',
          'imposition':'Imposition / intention','visualisation':'Visualisation',
          'distance':'Travail sur planche anatomique','local':'Travail spécifique'};
        node(PlanStep(id:id,title:'${f.title} — ${labels[kind] ?? 'Instruction spécifique'}',
          kind:kind,text:distance && kind=='distance' ? a.distanceText : a.text,ficheId:f.id,target:a.target,route:a.route,source:a.source,selectedRoute:a.selectedRoute,
          zones: (zones[f.title]?.toList() ?? []),seconds:a.seconds,repetitions:a.repetitions,condition:a.condition));
        link(prev,id); prev=id;
      }
      // Une fiche courte ne fait pas hériter ses conventions aux autres motifs.
      if(hasFull && (shortFor(f)||radioFor(f))) {
        final first=nodes.values.where((n)=>n.ficheId==f.id).firstOrNull;
        if(first!=null) link('communes',first.id);
      }
      lastIds.add(prev);
    }
    if(thot) {
      node(const PlanStep(id:'thot',title:'Pendule de Thot',kind:'thot'));
      for(final id in lastIds) link(id,'thot');
      lastIds..clear()..add('thot');
    }
    if(!distance && hasFull) {
      node(const PlanStep(id:'circulation',title:'Circulation énergétique entre les chakras',kind:'circulation'));
      for(final id in lastIds) link(id,'circulation');
      node(const PlanStep(id:'balayage',title:'Balayage',kind:'balayage'));
      link('circulation','balayage');lastIds..clear()..add('balayage');
    }
    node(const PlanStep(id:'debrief',title:'Débriefing / observation',kind:'debrief'));
    for(final id in lastIds) link(id,'debrief');
    if(lastIds.isEmpty) link(start,'debrief');
    final result=<PlanStep>[]; final emitted=<String>{};
    while(result.length<nodes.length) {
      int phase(PlanStep n) {
        if(const ['contact','temoin','bilan','scan','degagement'].contains(n.kind))return 0;
        if(n.kind=='communes')return 4;
        if(n.kind=='intentions')return 5;
        if(n.kind=='priere')return 6;
        if(n.kind=='thot')return 8;
        if(n.kind=='circulation')return 9;
        if(n.kind=='balayage')return 10;
        if(n.kind=='debrief')return 11;
        return 7;
      }
      final available=nodes.values.where((n)=>!emitted.contains(n.id)&&deps[n.id]!.every(emitted.contains)).toList();
      // Stable priority within the available nodes. Dependencies always take precedence.
      PlanStep? ready;
      for(final candidate in available){if(ready==null || phase(candidate)<phase(ready))ready=candidate;}
      if(ready==null) { errors.add('Conflit d’ordre : impossible de respecter toutes les dépendances.');break; }
      result.add(ready);emitted.add(ready.id);
    }
    return SessionPlan(result,errors);
  }
}
