/// Display-only formatting. The source library and saved protocols are never rewritten.
class GuidanceText {
  static const blockedFlux='Contrôler chaque trajet séparément. Si le flux ne passe pas, reprendre les passes rapides sur le segment concerné, puis contrôler à nouveau.';
  static String clean(String text,{String kind=''}) {
    final lines=text.split('\n');
    final gestures=const {'rapide','flux','lente','imposition','visualisation','distance','local'}.contains(kind);
    return [for(var i=0;i<lines.length;i++)
      (kind!='personnel' && (i==0 || gestures))
        ? lines[i].replaceFirst(RegExp(r'^\s*(?:[-•]\s*)?\d{1,2}[.)]\s+'),'')
        : lines[i]].join('\n').trim();
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
}
