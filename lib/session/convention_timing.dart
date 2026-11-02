/// Durées du manuel intégré, référence « 14 conventions ».
/// Les 30 s de CM9 viennent de ce manuel ; aucune variante vidéo n'est choisie implicitement.
class ConventionMoment {
  final int convention;
  final String label, intention;
  final int seconds;
  final bool last;
  const ConventionMoment(this.convention,this.label,this.intention,this.seconds,{this.last=true});
}
class ConventionTiming {
  static int cleaningSeconds(String observations) {
    final s=observations.toLowerCase();
    if(s.contains('magie noire')||s.contains('magie-noire')) return 240;
    if(s.contains('vigilance')) return 120;
    return 60;
  }
  static List<ConventionMoment> build({required bool medication, required String observations,
    required bool lowBlood, Map<String,String> weakBodies=const {}, List<String> events=const []}) {
    final out=<ConventionMoment>[];
    for(var i=0;i<14;i++) {
      if(i==7&&!medication)continue;
      out.add(ConventionMoment(i,'','', i==8 ? cleaningSeconds(observations) : i==11&&lowBlood ?120:60,last:i!=8 && !(i==2&&events.isNotEmpty)));
      if(i==2){
        for(var e=0;e<events.length;e++){
          out.add(ConventionMoment(2,'Événement particulier de la vie actuelle',
            'Je nettoie toutes les mauvaises mémoires liées à ${events[e]}',30,last:e==events.length-1));
        }
      }
      if(i==8) {
        out.add(const ConventionMoment(8,'Équilibrer les six corps énergétiques','Je rééquilibre ses 6 corps énergétiques autour de son corps physique',30,last:false));
        out.add(ConventionMoment(8,'Recharger les six corps énergétiques','Je recharge ses 6 corps énergétiques',30,last:weakBodies.isEmpty));
        var n=0;
        for(final body in weakBodies.values) {
          n++;
          out.add(ConventionMoment(8,'Recharger $body','Je recharge son corps $body',30,last:n==weakBodies.length));
        }
      }
    }
    return out;
  }
}
