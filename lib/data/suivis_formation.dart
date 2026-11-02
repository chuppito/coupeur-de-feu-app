/// Repères documentaires des visites suivantes, d'après le relevé des
/// 37 leçons de Stéphane Langlade (02/11/2026). Non médicaux.
class SuivisFormation {
  static String typePour(String titre) {
    final t = titre.toLowerCase();
    if (t.contains('zona') || t.contains('verrue')) return 'court';
    return 'complet';
  }

  static String indication(String titre) {
    final t = titre.toLowerCase();
    if (t.contains('zona')) return 'Suivi présentiel : prière contre le feu et imposition seulement ; contact téléphonique à 48 h mentionné.';
    if (t.contains('verrue')) return 'Suivi présentiel : prière et imposition/rayon ; Thot facultatif. Suivi à distance non précisé de la même façon.';
    if (t.contains('eczéma') || t.contains('eczema')) return 'Séance complète renouvelée vers un mois ; troisième éventuelle.';
    if (t.contains('psoriasis')) return 'Séances complètes mensuelles ; au moins trois évoquées dans le cours.';
    if (t.contains('capsulite')) return 'Nouvelle séance complète à trois semaines / un mois si demandée.';
    if (t.contains('déprime') || t.contains('anxiété')) return 'Séance complète renouvelée, plutôt trois semaines à un mois selon le cours.';
    if (t.contains('endométriose')) return 'Nouveau cycle : séance renouvelée ; délais contradictoires dans le cours et le manuel.';
    if (t.contains('chirurg') || t.contains('opérat')) return 'Avant et après intervention : protocoles différents ; choisir la fiche correspondante.';
    if (t.contains('radiothér')) return 'Suivi ponctuel à distance par prière contre le feu décrit dans le cours ; ne pas étendre à la chimiothérapie.';
    if (t.contains('fibromyalgie')) return 'Retour à la demande ; réévaluer les zones douloureuses du jour.';
    if (t.contains('entorse')) return 'Retour éventuel vers quinze jours ; délai oral incertain, aucun verrou.';
    if (t.contains('sommeil')) return 'Troubles anciens : deux à trois séances mensuelles évoquées ; sinon à la demande.';
    if (t.contains('asthme')) return 'PDF : sous un mois ; oral : selon les besoins. Pas de protocole court distinct.';
    return 'Aucune variante courte documentée ici : conserver le protocole existant, sans imposer de délai.';
  }
}
