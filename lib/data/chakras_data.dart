import 'package:flutter/material.dart';

/// Un chakra : nom, couleur associée, emplacement sur le corps, et les
/// contenus de référence (signification, signes de blocage, conseils
/// d'harmonisation, prière et intention). Contenu de portée générale et
/// intemporelle (correspondances traditionnelles), pas propre à un patient.
class Chakra {
  final String nom;
  final String nomSanskrit;
  final Color couleur;
  final String emplacement;
  final String signification;
  final String blocages;
  final String harmonisation;

  /// Zones du bonhomme (voir symbolique_data.dart -> zonesCorps) les plus
  /// proches anatomiquement de ce chakra, à titre indicatif. Le corps
  /// dessiné dans l'app n'a pas une zone par chakra (pas de "gorge" ni de
  /// "bas-ventre" distinct de "Abdomen" par ex.) : cette liste peut donc
  /// être vide, ou partagée entre deux chakras.
  final List<String> zonesAssociees;

  /// Prière d'harmonisation (invocation), sur le même principe que les
  /// prières de symbolique_data.dart : [NOM] est remplacé par le prénom.
  final String priere;

  /// Intention prononcée par le praticien, adressée au patient (tutoiement),
  /// même convention que intentionsLateralisees dans symbolique_data.dart.
  final String intention;

  const Chakra({
    required this.nom,
    required this.nomSanskrit,
    required this.couleur,
    required this.emplacement,
    required this.signification,
    required this.blocages,
    required this.harmonisation,
    required this.zonesAssociees,
    required this.priere,
    required this.intention,
  });
}

/// Liste ordonnée du 1er (Racine, bas du corps) au 7e (Couronne, sommet du
/// crâne) — l'ordre traditionnel d'ascension de l'énergie.
final List<Chakra> chakras = [
  Chakra(
    nom: "Racine",
    nomSanskrit: "Muladhara",
    couleur: const Color(0xFFD32F2F), // rouge
    emplacement: "Base de la colonne vertébrale, périnée",
    zonesAssociees: const ["Hanche droite", "Hanche gauche", "Pied droit", "Pied gauche"],
    signification: "Ancrage, survie, sécurité matérielle, sentiment de stabilité et d'appartenance au monde physique. "
        "C'est la fondation sur laquelle reposent tous les autres chakras.",
    blocages: "Anxiété chronique, sentiment d'insécurité, peur du manque (financier, matériel), difficulté à "
        "se sentir « à sa place », manque d'ancrage, douleurs dans le bas du dos, les jambes ou les pieds.",
    harmonisation: "Marcher pieds nus sur la terre ou l'herbe (ancrage). Postures de yoga debout, bien plantées. "
        "Aliments racines (carotte, betterave, pomme de terre). Couleur rouge portée ou visualisée. "
        "Pierres : grenat, hématite, jaspe rouge. Respiration lente et profonde, ventre relâché.",
    priere: "Force de la Terre, ancre [NOM] dans la matière et la sécurité. Que ses racines s'enfoncent "
        "profondément, que la peur du manque s'efface, que la stabilité revienne dans son corps et sa vie. "
        "Ainsi soit-il.",
    intention: "Je t'aide à retrouver ton ancrage. Tu es en sécurité ici et maintenant. Ton corps est solide, "
        "la terre te porte, tu as ta place dans ce monde.",
  ),
  Chakra(
    nom: "Sacré",
    nomSanskrit: "Svadhisthana",
    couleur: const Color(0xFFF57C00), // orange
    emplacement: "Bas-ventre, deux doigts sous le nombril",
    zonesAssociees: const ["Abdomen"],
    signification: "Créativité, sexualité, émotions, plaisir et capacité à accueillir le changement. "
        "Le siège de l'énergie vitale et du désir.",
    blocages: "Culpabilité, difficulté à exprimer ses émotions ou son désir, rigidité, dépendance affective, "
        "troubles liés à la sphère reproductive ou urinaire.",
    harmonisation: "Danse, mouvement libre du bassin, création artistique sans jugement. Contact avec l'eau "
        "(bain, rivière, mer). Pierres : cornaline, pierre de lune. Huiles essentielles : ylang-ylang, santal. "
        "Couleur orange.",
    priere: "Énergie de vie, réveille en [NOM] la fluidité et la créativité. Que les émotions retenues se "
        "libèrent en douceur, que le plaisir de vivre revienne couler librement. Ainsi soit-il.",
    intention: "Je t'invite à laisser circuler tes émotions sans les juger. Tu as le droit de ressentir, de "
        "créer, de désirer. Ton énergie vitale coule à nouveau librement.",
  ),
  Chakra(
    nom: "Plexus solaire",
    nomSanskrit: "Manipura",
    couleur: const Color(0xFFFBC02D), // jaune
    emplacement: "Au-dessus du nombril, sous le sternum",
    zonesAssociees: const ["Abdomen"],
    signification: "Confiance en soi, pouvoir personnel, volonté, capacité à agir et à s'affirmer dans le monde.",
    blocages: "Manque de confiance en soi, besoin excessif de contrôle, colère mal digérée, sentiment "
        "d'impuissance, troubles digestifs.",
    harmonisation: "Exposition au soleil, respiration « feu » (kapalabhati), activité physique dynamique. "
        "Affirmations de soi. Pierres : citrine, œil-de-tigre. Couleur jaune. Travailler sur les limites "
        "personnelles et le lâcher-prise du contrôle.",
    priere: "Lumière du soleil, ranime en [NOM] la confiance et la force intérieure. Que sa volonté s'affirme "
        "sans dureté, que le pouvoir d'agir lui soit rendu. Ainsi soit-il.",
    intention: "Je te rappelle ta propre force. Tu n'as pas besoin de tout contrôler pour être en sécurité. "
        "Tu as le droit d'agir et de t'affirmer avec confiance.",
  ),
  Chakra(
    nom: "Cœur",
    nomSanskrit: "Anahata",
    couleur: const Color(0xFF388E3C), // vert (parfois rose)
    emplacement: "Centre de la poitrine",
    zonesAssociees: const ["Torse"],
    signification: "Amour inconditionnel, compassion, pardon, capacité à donner et recevoir dans les relations. "
        "Point de bascule entre les chakras « matériels » (1-3) et « spirituels » (5-7).",
    blocages: "Difficulté à aimer ou à pardonner (à soi ou aux autres), jalousie, isolement affectif, besoin "
        "de se protéger derrière une carapace, tensions dans la poitrine ou troubles respiratoires/cardiaques.",
    harmonisation: "Méditation de gratitude, exercices de pardon. Contact avec la nature. Pierres : quartz rose, "
        "aventurine verte. Couleur verte ou rose. Ouvrir la poitrine (étirements, respiration ample).",
    priere: "Souffle d'amour, ouvre le cœur de [NOM]. Que le pardon dénoue les blessures anciennes, que "
        "l'amour circule à nouveau librement. Ainsi soit-il.",
    intention: "Je t'invite à ouvrir ton cœur, à toi-même d'abord. Tu mérites d'aimer et d'être aimé(e) sans "
        "condition. Le pardon est un cadeau que tu te fais à toi-même.",
  ),
  Chakra(
    nom: "Gorge",
    nomSanskrit: "Vishuddha",
    couleur: const Color(0xFF1976D2), // bleu
    emplacement: "Gorge",
    // Aucune zone dédiée sur le bonhomme actuellement ("Nuque" est l'arrière
    // du cou, pas la gorge) : laissé vide plutôt que de forcer une zone
    // approximative.
    zonesAssociees: const [],
    signification: "Communication, expression de soi, vérité intérieure, capacité à dire ce que l'on pense et "
        "ressent réellement.",
    blocages: "Difficulté à s'exprimer ou à dire non, paroles retenues ou au contraire mensonges répétés, "
        "maux de gorge fréquents, troubles thyroïdiens.",
    harmonisation: "Chant, lecture à voix haute, écriture (journal intime). Pierres : aigue-marine, lapis-lazuli. "
        "Couleur bleu clair/turquoise. Pratiquer à dire sa vérité avec douceur mais sans se taire.",
    priere: "Voix de vérité, libère la parole de [NOM]. Que ce qui doit être dit trouve enfin le chemin des "
        "mots, que sa voix retrouve sa juste place. Ainsi soit-il.",
    intention: "Je t'encourage à dire ta vérité, avec douceur mais sans te taire. Ta voix a le droit d'exister "
        "et d'être entendue.",
  ),
  Chakra(
    nom: "Troisième œil",
    nomSanskrit: "Ajna",
    couleur: const Color(0xFF512DA8), // indigo
    emplacement: "Entre les sourcils, légèrement au-dessus",
    zonesAssociees: const ["Tête"],
    signification: "Intuition, sagesse intérieure, clarté mentale, capacité à voir au-delà des apparences.",
    blocages: "Confusion mentale, manque de clarté ou de discernement, difficulté à faire confiance à son "
        "intuition, maux de tête récurrents, rumination.",
    harmonisation: "Méditation silencieuse, visualisation. Réduire les stimulations visuelles (écrans) avant "
        "de dormir. Obscurité et calme. Pierres : améthyste, lapis-lazuli. Couleur indigo.",
    priere: "Clarté intérieure, éclaire l'esprit de [NOM]. Que la confusion se dissipe, que son intuition "
        "retrouve sa justesse, que sa vision s'élargisse. Ainsi soit-il.",
    intention: "Je t'invite à faire confiance à ce que tu perçois intérieurement. Ta propre sagesse sait déjà "
        "beaucoup de choses ; prends le temps de l'écouter.",
  ),
  Chakra(
    nom: "Couronne",
    nomSanskrit: "Sahasrara",
    couleur: const Color(0xFF7B1FA2), // violet
    emplacement: "Sommet du crâne",
    zonesAssociees: const ["Tête"],
    signification: "Connexion spirituelle, conscience élargie, sentiment d'unité avec quelque chose de plus "
        "grand que soi. L'aboutissement du chemin des 7 chakras.",
    blocages: "Sentiment de déconnexion ou de vide existentiel, cynisme, rigidité mentale, difficulté à lâcher "
        "prise sur le contrôle rationnel.",
    harmonisation: "Méditation profonde, silence, prière ou pratique spirituelle régulière. Pierres : améthyste, "
        "cristal de roche. Couleur violette ou blanche. Temps passé dans le silence, sans objectif ni activité.",
    priere: "Esprit universel, relie [NOM] à ce qui dépasse le quotidien. Que la connexion spirituelle "
        "s'ouvre, que le sens revienne, que la paix profonde s'installe. Ainsi soit-il.",
    intention: "Je t'invite à te relier à quelque chose de plus grand que toi, à ta façon. Tu n'es pas "
        "seul(e) ; tu fais partie d'un tout plus vaste.",
  ),
];

/// Comment s'ancrer, avant/pendant/après une séance — pour le praticien
/// autant que pour le patient si besoin.
const String conseilsAncrage =
    """Avant la séance : pieds bien à plat ou nus, respiration lente et profonde. Visualise des racines qui """
    """partent de tes pieds (ou de ta base) et s'enfoncent dans le sol. Demande mentalement la connexion à la """
    """terre avant de commencer.

Pendant la séance : si toi ou le patient vous sentez "parti(e)", trop dans le mental ou dissocié(e), reviens """
    """un instant sur le chakra racine (ou les pieds) avant de poursuivre.

Après la séance : lave-toi les mains à l'eau froide, secoue-les. Marche quelques minutes, mange ou bois """
    """quelque chose. Redemande mentalement l'ancrage. Ce sont des réflexes simples pour ne pas "garder" """
    """l'énergie du soin sur toi.""";

/// Méthode générale de travail énergétique sur les chakras : comment
/// scanner, repérer un déséquilibre, et harmoniser.
const String methodeScanEtHarmonisation =
    """Scanner : passe la main ouverte à quelques centimètres au-dessus de chaque point, du bas (Racine) vers """
    """le haut (Couronne) ou l'inverse selon ton ressenti. Sois attentif(ve) aux sensations : chaleur, froid, """
    """picotements, vide, résistance. Compare les 7 points entre eux — celui qui "sort du lot" (trop chaud, """
    """trop froid, comme absent) est souvent celui à travailler en priorité.

Harmoniser : positionne la main (ou les deux mains) au niveau du chakra concerné, paume face à la zone, à """
    """1-5 cm. Visualise la couleur du chakra affluer dans la zone, avec l'intention de rééquilibrer — apporter """
    """de l'énergie si tu sens un vide/du froid, apaiser et évacuer le surplus si tu sens une chaleur ou une """
    """agitation trop forte. Dis la prière et/ou l'intention associée. Reste 1 à 3 minutes, jusqu'à sentir un """
    """changement (chaleur qui s'égalise, sensation de calme qui s'installe).

Ordre : en général on remonte de la Racine vers la Couronne, pour "ouvrir" un chemin d'énergie ascendant — """
    """sauf si un chakra précis se démarque nettement au scan, auquel cas tu peux le travailler en priorité """
    """avant de reprendre l'ordre complet.""";
