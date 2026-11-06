/// Display-only formatting. The source library and saved protocols are never rewritten.
class GuidanceText {
  static const blockedFlux='Contrôler chaque trajet séparément. Si le flux ne passe pas, reprendre les passes rapides sur le segment concerné, puis contrôler à nouveau.';
  static String clean(String text,{String kind=''}) {
    final lines=text.split('\n');
    final gestures=const {'rapide','flux','lente','imposition','visualisation','distance','local'}.contains(kind);
    var displayed=[for(var i=0;i<lines.length;i++)
      (kind!='personnel' && (i==0 || gestures))
        ? lines[i].replaceFirst(RegExp(r'^\s*(?:[-•]\s*)?\d{1,2}[.)]\s+'),'')
        : lines[i]];
    if(kind=='rapide' && displayed.length>1){
      // Drop a redundant work heading, never a patient position or a side.
      final heading=RegExp(r'^Travaillez? en passes[^:]*:\s*$',caseSensitive:false);
      final position=RegExp(r'patient|dos|ventre|devant|derrière|antérieur|postérieur|allong|assis',caseSensitive:false);
      displayed=displayed.where((line)=>!heading.hasMatch(line)||position.hasMatch(line)).toList();
    }
    return displayed.join('\n').trim();
  }
  /// Repères issus du « Protocole contrôle des flux », ebook p. 37.
  /// Les zones non décrites dans la source ne reçoivent pas de trajet inventé.
  static List<String> anatomicalRoutes(Iterable<String> zones) {
    final result=<String>[];
    for(final zone in zones.toSet()){
      final z=zone.toLowerCase();
      final side=z.contains('gauche')?'gauche':z.contains('droit')?'droit':null;
      final feminine=side=='droit'?'droite':side;
      if(z.contains('genou') && side!=null){
        result.add('1. Chakra mineur aine $feminine → chakra mineur genou $side');
        result.add('2. Chakra mineur genou $side → chakra mineur pied $side');
      }else if((z.contains('épaule')||z.contains('epaule'))&&side!=null){
        result.add('1. Chakra majeur couronne → chakra mineur épaule $feminine');
        result.add('2. Chakra mineur épaule $feminine → chakra mineur main $feminine');
      }else if(z.contains('coude')&&side!=null){
        result.add('1. Chakra mineur épaule $feminine → chakra mineur coude $side');
        result.add('2. Chakra mineur coude $side → chakra mineur main $feminine');
      }else if(z.contains('poignet')&&side!=null){
        result.add('Chakra mineur coude $side → chakra mineur main $feminine');
      }else if(z.contains('cheville')&&side!=null){
        result.add('Chakra mineur genou $side → chakra mineur pied $side');
      }else if(z.contains('abdomen')||z.contains('intestin')){
        result.add('Chakra majeur plexus devant → chakra majeur racine');
      }else if(z.contains('nuque')||z.contains('cervical')){
        result.add('Chakra majeur couronne → chakra majeur cœur derrière');
      }else if(z.contains('lombaire')||z.contains('bas du dos')){
        result.add('Chakra majeur plexus derrière → chakra majeur racine');
      }
    }
    return result;
  }
  static List<String> selectedRoutes(Iterable<String> zones) {
    final result=<String>[];
    for(final zone in (zones.toSet().toList()..sort())){
      final z=zone.toLowerCase();
      final side=z.contains('gauche')?'gauche':z.contains('droit')?'droit':null;
      if(side==null)continue;
      final f=side=='droit'?'droite':'gauche';
      if(z.contains('genou')){result.add('Genou $side : aine $f → genou $side → pied $side.');}
      else if(z.contains('coude')){result.add('Coude $side : épaule $f → coude $side → main $f.');}
      else if(z.contains('épaule')||z.contains('epaule')){result.add('Épaule $f : couronne → épaule $f → main $f.');}
      else if(z.contains('cheville')){result.add('Cheville $f : genou $side → pied $side.');}
      else if(z.contains('poignet')){result.add('Poignet $side : coude $side → main $f.');}
      else if(z.contains('cuisse')){result.add('Cuisse $f : aine $f → genou $side.');}
    }
    return result;
  }
  static String route(String text) {
    var s=clean(text,kind:'rapide');
    // Only remove presentation verbs; never infer anatomical endpoints.
    s=s.replaceFirst(RegExp(r'^.*?\b[Pp]asses rapides\s*(?:sur[^:]*:\s*)?'),'');
    s=s.replaceFirst(RegExp(r'^\s*:\s*'),'');
    s=s.replaceAll('du chakra ','chakra ').replaceAll('au chakra ','→ chakra ').replaceAll('aux chakras ','→ chakras ');
    return s.trim();
  }
  static String commonCues(String text)=>text.replaceAllMapped(
    RegExp(r'^([^:\n]+:\s*)\d{1,2}[.)]\s+',multiLine:true),(m)=>m.group(1)!);
  static List<String> fixedRoutes(String original,Iterable<String> zones,{bool sideAware=false}){
    final base=route(original);
    if(!sideAware)return [base];
    final sides=<String>{};
    for(final z in zones){
      if(z.toLowerCase().contains('droit'))sides.add('droit');
      if(z.toLowerCase().contains('gauche'))sides.add('gauche');
    }
    if(sides.isEmpty)return [base];
    return [for(final side in sides)
      'Côté $side : ${base.replaceAllMapped(RegExp(r'(aine|épaule|coude|main|genou|pied|oreille)\b',caseSensitive:false),(m){
        final feminine=const {'aine','épaule','main','oreille'}.contains(m.group(1)!.toLowerCase());
        return '${m.group(1)} ${side=='droit'&&feminine?'droite':side}';
      })}'];
  }
}
