/// Assemblage sans classement des gestes par mots-clés.
/// Chaque fiche porte une liste d'actions explicites dans guideV33.
class GuideAction {
  final String id, kind, text, target, route, source, distanceText;
  const GuideAction({required this.id, required this.kind, required this.text,
    this.target = '', this.route = '', this.source = '', this.distanceText = ''});
  factory GuideAction.fromJson(Map<String, dynamic> j) => GuideAction(
    id: j['id'] as String, kind: j['kind'] as String, text: j['text'] as String,
    target: j['target'] as String? ?? '', route: j['route'] as String? ?? '',
    source: j['source'] as String? ?? '', distanceText:j['distanceText'] as String? ?? '');
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
  const PlanStep({required this.id, required this.title, required this.kind,
    this.text = '', this.ficheId = '', this.target = '', this.route = '',
    this.source = '', this.zones = const []});
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
  }) {
    if (fiches.length > 3) return const SessionPlan([], ['Maximum 3 soins par séance. Le nombre de prières n’est pas limité.']);
    final errors = <String>[];
    final nodes = <String,PlanStep>{};
    final deps = <String,Set<String>>{};
    void node(PlanStep s) { nodes[s.id] = s; deps.putIfAbsent(s.id, () => {}); }
    void link(String a, String b) { if (a != b) deps[b]!.add(a); }
    String? tail;
    bool hasFull = false;
    bool shortFor(GuideFiche f) => !distance && visits[f.id] == 'court' &&
      const {'ft-zona','ft-verrue'}.contains(f.id);
    bool radioFor(GuideFiche f) => distance && visits[f.id] == 'radio' && f.id == 'ft-traitements-lourds-aide-aux';
    hasFull = fiches.any((f) => !shortFor(f) && !radioFor(f));
    for (final entry in <String,String>{'contact':'Prise de contact',
      if (distance && hasFull) 'temoin':'Préparer le témoin vitalisé',
      if (hasFull) 'bilan':'Bilan énergétique',
      if (scan) 'scan':'Scan au pendule',
      if (hasFull) 'degagement':'Dégagement des entités / énergies négatives si nécessaire'}.entries) {
      node(PlanStep(id: entry.key, title:entry.value,kind:entry.key));
      if(tail!=null) link(tail!,entry.key);
      tail=entry.key;
    }
    final start=tail!;
    if(hasFull) node(const PlanStep(id:'communes',title:'14 conventions mentales',kind:'communes'));
    final lastIds=<String>[];
    for(final f in fiches) {
      if(f.actions.isEmpty) { errors.add('${f.title} : déroulé structuré absent.'); continue; }
      var prev=start;
      for(final a in f.actions) {
        if(distance && a.kind=='personnel') { errors.add('${f.title} : adaptation à distance de la fiche personnelle à préciser.'); continue; }
        if(shortFor(f) && !const {'priere','imposition'}.contains(a.kind)) continue;
        if(radioFor(f) && a.kind!='priere') continue;
        if(a.kind=='communes') { link(prev,'communes');prev='communes';continue; }
        if(const {'accueil','bilan','degagement','circulation','balayage','debrief'}.contains(a.kind)) continue;
        if(distance && const {'lente','flux'}.contains(a.kind)) continue;
        var kind=a.kind;
        if(distance && const {'rapide','imposition','visualisation','local'}.contains(kind)) kind='distance';
        final id='${f.id}:${a.id}';
        const labels={'priere':'Prière / formulation','intentions':'Conventions supplémentaires',
          'rapide':'Passes rapides','flux':'Contrôle des flux','lente':'Passes lentes',
          'imposition':'Imposition / intention','visualisation':'Visualisation',
          'distance':'Travail sur planche anatomique','local':'Travail spécifique'};
        node(PlanStep(id:id,title:'${f.title} — ${labels[kind] ?? 'Instruction spécifique'}',
          kind:kind,text:distance && kind=='distance' ? a.distanceText : a.text,ficheId:f.id,target:a.target,route:a.route,source:a.source,
          zones: a.target=='selection' ? (zones[f.title]?.toList() ?? []) : const []));
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
      final ready=nodes.values.where((n)=>!emitted.contains(n.id)&&deps[n.id]!.every(emitted.contains)).firstOrNull;
      if(ready==null) { errors.add('Conflit d’ordre : impossible de respecter toutes les dépendances.');break; }
      result.add(ready);emitted.add(ready.id);
    }
    return SessionPlan(result,errors);
  }
}
