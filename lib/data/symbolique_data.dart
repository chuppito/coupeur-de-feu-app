// lib/data/symbolique_data.dart
//
// Système compositionnel : plutôt que de stocker une signification figée
// pour chaque combinaison (maladie × zone), on stocke deux petites bases
// indépendantes...
//   1) le "conflit type" propre à chaque maladie (conflitsTypes)
//   2) le "contexte de vie" propre à chaque zone, y compris la latéralité
//      (zoneContexte / zoneLocatif)
// ...et on les combine à la volée (voir genererSynthese) pour obtenir une
// phrase précise pour CHAQUE combinaison, à la façon du tableau
// "combinaisons symboliques" (Cuisse Droite + Eczéma, Tibia Gauche + Zona,
// etc.) sans avoir à écrire des dizaines de phrases à la main.

final List<String> typesMaladie = [
  "Eczéma", "Psoriasis", "Zona", "Brûlure", "Inflammation", "Aphtes",
  "Rhumatismes / Arthrose", "Urticaire", "Otite", "Infection",
];

final List<String> zonesCorps = [
  "Tête", "Oreille droite", "Oreille gauche", "Nuque", "Épaules", "Dos", "Torse", "Abdomen",
  "Bras droit", "Bras gauche", "Main droite", "Main gauche",
  "Hanche droite", "Hanche gauche",
  "Cuisse droite", "Cuisse gauche",
  "Genou droit", "Genou gauche",
  "Tibia droit", "Tibia gauche",
  "Pied droit", "Pied gauche",
];

/// Le "conflit type" d'une maladie : un intitulé court + une description,
/// indépendants de la zone touchée.
class ConflitType {
  final String label;
  final String description;
  const ConflitType(this.label, this.description);
}

final Map<String, ConflitType> conflitsTypes = {
  "Eczéma": const ConflitType(
    "Conflit de séparation",
    "Besoin ou peur de séparer quelque chose (ou quelqu'un) de soi. C'est une barrière que le corps érige.",
  ),
  "Psoriasis": const ConflitType(
    "Conflit de protection identitaire",
    "Besoin de se construire une armure émotionnelle face au monde, peur de la vulnérabilité.",
  ),
  "Zona": const ConflitType(
    "Conflit de souillure ou de culpabilité",
    "Sensation d'avoir été attaqué dans son intégrité, ou regret profond. Le feu sort pour \"nettoyer\" la zone.",
  ),
  "Brûlure": const ConflitType(
    "Conflit d'agression",
    "Réaction immédiate à une situation vécue comme une agression, physique ou symbolique.",
  ),
  "Inflammation": const ConflitType(
    "Conflit de colère contenue",
    "Besoin de calmer une colère ou une action trop vive.",
  ),
  "Aphtes": const ConflitType(
    "Conflit de parole non digérée",
    "Difficulté à digérer une parole reçue ou dite, des mots qui blessent intérieurement.",
  ),
  "Rhumatismes / Arthrose": const ConflitType(
    "Conflit de dévalorisation",
    "Sentiment de ne pas être assez performant ou souple face aux exigences de la vie.",
  ),
  "Urticaire": const ConflitType(
    "Conflit de refus",
    "Une situation ou une personne \"ne passe pas\" : sensation d'être piqué au vif par une remarque ou un événement.",
  ),
  "Otite": const ConflitType(
    "Conflit du refus d'entendre / saturation auditive",
    "Saturation face à ce que l'on entend, refus d'écouter certaines paroles, ou colère rentrée contre des bruits "
        "et des conflits environnants : l'oreille enflammée crie un « j'en ai plein les oreilles » et le besoin "
        "inconscient de couper le contact avec une ambiance toxique. Peut aussi traduire un sentiment d'exclusion "
        "(besoin d'être entendu, pleurs intérieurs non écoutés). Selon le type : otite externe = barrière dressée "
        "contre une intrusion verbale directe (« ne m'envahissez pas ! ») ; otite moyenne ou séreuse = tristesse "
        "refoulée, pleurs intérieurs bloqués derrière le tympan.",
  ),
  "Infection": const ConflitType(
    "Conflit d'intrusion",
    "Sentiment d'avoir été envahi par quelque chose ou quelqu'un ressenti comme sale, toxique ou menaçant : le "
        "corps mobilise ses défenses (fièvre, pus, rougeur, chaleur) pour combattre et expulser cet « intrus », au "
        "sens propre comme au figuré. Peut aussi traduire un conflit non réglé avec une personne associée dans "
        "l'inconscient à l'origine du mal (« cette personne m'a contaminé »), une auto-dévalorisation (« je suis "
        "sale », « je suis coupable de quelque chose »), ou une bataille intérieure entre deux forces qui reflète "
        "un conflit relationnel ou une lutte de pouvoir vécue dans la vie de la personne.",
  ),
};

/// Pour chaque zone : la façon d'en parler au génitif ("au niveau de ...")
/// et son contexte de vie symbolique (utilisé après "par rapport à ...").
/// Les zones latéralisées suivent la polarité Droit = masculin/action,
/// Gauche = féminin/émotionnel, cohérente avec le reste de la fiche.
final Map<String, String> zoneLocatif = {
  "Tête": "sa tête",
  "Oreille droite": "son oreille droite",
  "Oreille gauche": "son oreille gauche",
  "Nuque": "sa nuque",
  "Épaules": "ses épaules",
  "Dos": "son dos",
  "Torse": "son torse",
  "Abdomen": "son abdomen",
  "Bras droit": "son bras droit",
  "Bras gauche": "son bras gauche",
  "Main droite": "sa main droite",
  "Main gauche": "sa main gauche",
  "Hanche droite": "sa hanche droite",
  "Hanche gauche": "sa hanche gauche",
  "Cuisse droite": "sa cuisse droite",
  "Cuisse gauche": "sa cuisse gauche",
  "Genou droit": "son genou droit",
  "Genou gauche": "son genou gauche",
  "Tibia droit": "son tibia droit",
  "Tibia gauche": "son tibia gauche",
  "Pied droit": "son pied droit",
  "Pied gauche": "son pied gauche",
};

final Map<String, String> zoneContexte = {
  "Tête": "sa façon de gérer mentalement une situation actuelle, son besoin de lâcher-prise mental",
  // Exception à la convention droit=action/gauche=émotionnel utilisée pour
  // le reste du corps : pour les oreilles, Thomas situe le droit du côté
  // affectif/familial et le gauche du côté social/rationnel — polarité
  // inversée, mais conservée telle quelle car spécifique à cette zone.
  "Oreille droite": "les proches, la famille, ou des paroles intimes qui blessent (charge affective)",
  "Oreille gauche": "le travail, les obligations, les exigences extérieures ou des ordres subis (charge sociale/rationnelle)",
  "Nuque": "son inflexibilité face à une situation qui l'entête",
  "Épaules": "le poids des responsabilités portées en ce moment",
  "Dos": "le soutien ressenti (ou non) de la part de l'entourage face aux épreuves traversées",
  "Torse": "un conflit affectif ou une blessure du cœur",
  "Abdomen": "une peur liée à l'avenir ou à un changement à venir",
  "Bras droit": "son action, sa capacité à agir concrètement dans le monde extérieur (travail, projets)",
  "Bras gauche": "sa capacité à accueillir ou donner sur le plan affectif et familial",
  "Main droite": "son besoin de contrôle ou d'action sur un projet concret (travail/action)",
  "Main gauche": "sa capacité à lâcher-prise ou à recevoir sur le plan affectif",
  "Hanche droite": "sa direction dans ses projets d'action ou de travail",
  "Hanche gauche": "sa direction dans sa vie affective ou familiale",
  "Cuisse droite": "son avancée dans ses projets d'action ou de travail",
  "Cuisse gauche": "son avancée dans ses projets personnels ou émotionnels",
  "Genou droit": "sa flexibilité face à l'autorité ou au travail",
  "Genou gauche": "sa flexibilité face à ses émotions ou à sa famille",
  "Tibia droit": "son équilibre dans sa vie sociale ou professionnelle",
  "Tibia gauche": "son équilibre dans sa vie intérieure ou familiale",
  "Pied droit": "la direction choisie dans le monde extérieur, la peur de perdre pied",
  "Pied gauche": "sa place dans son chemin de vie émotionnel",
};

/// Combine le conflit type de la maladie et le contexte de la zone pour
/// produire une synthèse précise, centrée sur le PATIENT (et non le
/// praticien) : on utilise son prénom plutôt que "je/mon", avec des
/// tournures neutres qui ne présument pas de son genre.
String genererSynthese(String maladie, String zone, String nomPatient) {
  final conflit = conflitsTypes[maladie];
  final locatif = zoneLocatif[zone] ?? zone;
  final contexte = zoneContexte[zone];

  if (conflit == null) {
    return "Analyse en cours pour cette combinaison.";
  }

  final buffer = StringBuffer();
  buffer.write(
      "Le corps de $nomPatient réagit par $maladie au niveau de $locatif, pour lui indiquer un conflit de type « ${conflit.label} ». ");
  buffer.write(conflit.description);
  if (contexte != null) {
    buffer.write(
        "\nQuestion à explorer avec $nomPatient : quelle situation, dans sa vie actuelle, pourrait expliquer cette réaction en lien avec $contexte ?");
  }
  return buffer.toString();
}

/// Textes d'intention prononcés par le praticien, adressés directement au
/// patient (tutoiement) — à dire après/avec la prière, contrairement à la
/// prière elle-même qui invoque le divin. Utile quand une maladie a une
/// nuance différente selon la latéralité : ici, Otite droite = charge
/// affective/familiale, Otite gauche = charge sociale/professionnelle
/// (cohérent avec zoneContexte ci-dessus).
/// Structure : maladie -> {zone -> texte}. La clé spéciale "*" sert pour une
/// intention générale, valable quelle que soit la zone (ex: Infection, qui
/// n'a pas de logique droite/gauche) ; elle sert de repli si la zone exacte
/// n'a pas d'entrée dédiée (voir son utilisation dans home_screen.dart).
/// Vide/absent = pas d'intention spécifique pour cette combinaison, la
/// fiche n'affiche alors que la synthèse symbolique et la prière habituelles.
final Map<String, Map<String, String>> intentionsLateralisees = {
  "Otite": {
    "Oreille droite":
        """J'entends ta colère et ta tristesse face à ce qui a été dit ou non-dit dans ton espace intime. """
        """Je choisis aujourd'hui de libérer ton oreille droite de ce poids. Je pose des limites saines """
        """autour de ce que tu acceptes d'entendre. Ton cœur est en paix, ton oreille s'apaise, tu retrouves """
        """ton calme intérieur.""",
    "Oreille gauche":
        """J'accueille et je libère la frustration liée à ce que tu te sens obligé(e) d'entendre, d'exécuter """
        """ou de subir dans ton quotidien extérieur. Je refuse que les exigences ou les jugements des """
        """autres polluent ton espace mental. Je réaffirme ta souveraineté : tu as le droit de ne pas tout """
        """accepter, tu écoutes ta propre vérité et tu retrouves ta sérénité.""",
  },
  "Infection": {
    "*":
        """Je reconnais ce que tu n'as pas digéré, cette intrusion ressentie dans ton espace. Je choisis de """
        """renforcer tes défenses et d'expulser ce qui ne t'appartient pas. Ton corps retrouve sa capacité à """
        """se défendre et à guérir. Tu redeviens propre et fort(e).""",
  },
};

final Map<String, String> prieres = {
  "Brûlure": """Feu, je te coupe +
Feu, je te bloque +
Tu n'as pas lieu d'être sur le corps de [NOM].
Le feu ne brûle pas les chairs,
Les chairs deviennent normales,
La peau s'assouplit, s'adoucit, ne devient pas dure,
Mais reste telle qu'elle était avant la brûlure.""",

  "Eczéma": """Je te panse +
Que tu ne croisses plus +
Que tu n'augmentes pas plus que la rosée sur le pré +
Au soleil levant +
(À faire avec le signe de croix au-dessus de la partie la plus atteinte)""",

  "Aphtes": """Saint Yves, je te remercie de venir guérir les aphtes de [NOM], qu’ils ne le fassent plus souffrir et qu’ils disparaissent pour de bon.""",
  
  "Zona": """Grand Saint Roch, je te demande de stopper ce feu qui dévore la peau de [NOM]. 
Que la douleur s'apaise, que le nerf se calme, et que la peau retrouve son équilibre naturel. 
Au nom de la guérison, je te libère du mal.""",

  "Inflammation": """Esprit de paix, souffle sur cette inflammation de [NOM]. 
Apaise la chaleur, calme la rougeur, rétablis la fluidité dans les chairs. 
Que le calme revienne, ici et maintenant.""",

  "Psoriasis": """Psoriasis, je te demande de te calmer. 
Que la peau de [NOM] retrouve sa souplesse et sa douceur. 
Que les tensions se dissipent et que l'équilibre soit rétabli pour le bien-être de [NOM].""",

  "Rhumatismes / Arthrose": """Sainte Anne, toi qui veilles sur ceux qui souffrent, je me tiens devant [NOM] avec humilité.
Par le souffle de la guérison, je demande à ce que la douleur soit apaisée et que le feu de l'inflammation soit éteint.
Que les blocages dans ses articulations se dénouent, que la raideur s'efface devant la fluidité,
et que la paix recouvre cette zone endolorie.
Je suis le canal de cet apaisement pour [NOM]. Que la souplesse lui soit rendue. Qu'il en soit ainsi.""",

  "Urticaire": """Je t'ordonne de disparaître +
Que la piqûre s'efface du corps de [NOM] +
Que la peau redevienne calme et lisse comme avant +
Que le refus se dénoue, que le passage se fasse en paix +
Qu'il en soit ainsi.""",

  "Otite": """Feu de l'inflammation, mal d'oreille, détresse du tympan,
Par le souffle de vie, je te commande de t'arrêter.
Que la douleur se dissipe, que le conduit s'apaise,
Que le calme et l'harmonie reviennent dans cette oreille.
Ainsi soit-il.""",

  "Infection": """Grand Saint Roch, toi qui as soigné les pestiférés et repoussé la maladie, je t'invoque pour """
      """combattre cette infection qui touche le corps de [NOM]. Que les forces de vie chassent ce qui ne doit """
      """pas y être, que le pus se résorbe, que la fièvre tombe, que la chair guérisse saine et propre. Par la """
      """force du feu qui purifie et non qui détruit, je chasse l'intrus. Ainsi soit-il.""",
};
