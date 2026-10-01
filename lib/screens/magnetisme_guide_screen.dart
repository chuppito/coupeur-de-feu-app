import 'package:flutter/material.dart';

class MagnetismeGuideScreen extends StatefulWidget {
  const MagnetismeGuideScreen({super.key});

  @override
  State<MagnetismeGuideScreen> createState() => _MagnetismeGuideScreenState();
}

class _MagnetismeGuideScreenState extends State<MagnetismeGuideScreen> {
  final _recherche = TextEditingController();
  String _onglet = 'Fiches techniques';

  static const List<String> _fichesTechniques = [
    'Acné',
    'Arthrite',
    'Arthrose',
    'Asthme',
    'Bronchite',
    'Capsulite',
    'Cervicalgie',
    'Constipation',
    'Couper le feu',
    'Cruralgie',
    'Cystite',
    'Déchirure musculaire',
    'Déprime',
    'Eczéma',
    'Endométriose',
    'Entorse',
    'Fibromyalgie',
    'Gastro-entérite',
    'Goutte',
    'Grippe',
    'Hémorroïdes',
    'Herpès',
    'Insuffisance veineuse',
    'Lombalgie',
    'Maladie de Crohn',
    'Maladie de Lyme',
    'Maladie de Verneuil',
    'Migraine',
    'Névralgie d\'Arnold',
    'Otite',
    'Papillomavirus',
    'Psoriasis',
    'Rhinopharyngite',
    'Sciatique',
    'Sclérose en plaques',
    'Spondylarthrite ankylosante',
    'Tabac',
    'Tendinite',
    'Traitements lourds',
    'Troubles du sommeil',
    'Verrue',
    'Zona',
  ];

  static const List<_GuideEntry> _guides = [
    _GuideEntry(
      'Déroulé d\'une séance',
      'Prise de contact → bilan énergétique → conventions/intention → travail adapté à la fiche → observation et suivi. Les fiches fournies restent la référence du protocole à utiliser.',
    ),
    _GuideEntry(
      'Scan énergétique au pendule',
      '1. Installer la personne confortablement.\n2. Se placer dans ton état neutre habituel.\n3. Poser une question simple et précise.\n4. Explorer progressivement avec le pendule selon tes cadrans papier.\n5. Noter uniquement ce que tu observes.\n6. Recouper avec le bilan et la fiche technique avant la séance.',
    ),
    _GuideEntry(
      'Passes rapides',
      'Les fiches fournies décrivent les passes rapides comme des passes sans contact, main ouverte vers le corps, généralement du haut vers le bas. Pour une zone douloureuse, elles décrivent un travail entre un point en amont et un point en aval, suivi d’un contrôle avant de poursuivre.',
    ),
    _GuideEntry(
      'Passes lentes et imposition',
      'Après le travail prévu par la fiche, les passes lentes et l’imposition des mains sont utilisées selon le protocole concerné. Ne pas inventer une technique lorsqu’une fiche précise déjà la méthode.',
    ),
    _GuideEntry(
      'Chakras',
      'Le dossier fourni contient les fiches « chakras » et « mesure chakras ». Cette rubrique de l’application sert de mémo ; les cadrans et feuilles de mesure restent sur papier comme demandé.',
    ),
    _GuideEntry(
      'Conventions mentales',
      'Le dossier contient la fiche « 14 conventions ». Dans la méthode fournie, une convention est formulée mentalement avec une intention pour la personne. Les formulations détaillées restent dans les fiches papier.',
    ),
    _GuideEntry(
      'Soin à distance',
      'Le dossier contient un récapitulatif spécifique à la séance à distance. La trame est distincte d’une séance en présentiel et doit être suivie avec la fiche papier correspondante.',
    ),
    _GuideEntry(
      'Intervention chirurgicale',
      'Les fiches « intervention chirurgicale avant » et « après » sont disponibles dans ton dossier source. Pour une situation post-opératoire réelle, l’application ne remplace jamais les consignes de l’équipe médicale ni le suivi habituel.',
    ),
    _GuideEntry(
      'Règle V2',
      'Les fiches de radiesthésie restent volontairement hors de l’application. L’onglet Pendule sert uniquement de mémo de méthode, tandis que les cadrans papier restent ton outil de mesure.',
    ),
  ];

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _recherche.text.trim().toLowerCase();
    final fiches = _fichesTechniques.where((e) => e.toLowerCase().contains(q)).toList();
    final guides = _guides.where((e) => e.titre.toLowerCase().contains(q) || e.texte.toLowerCase().contains(q)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Pendule & magnétisme')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
          children: [
            Card(
              color: Colors.indigo.withValues(alpha: 0.08),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.self_improvement, color: Colors.indigo),
                      SizedBox(width: 8),
                      Expanded(child: Text('Le mémo de pratique', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                    ]),
                    SizedBox(height: 8),
                    Text('Les cadrans et fiches de radiesthésie restent sur papier. Ici, tu retrouves uniquement les rappels utiles pour le scan énergétique, le magnétisme, les passes et l’organisation d’une séance.'),
                    SizedBox(height: 8),
                    Text('Ces éléments décrivent ta pratique et les documents fournis ; ils ne constituent pas un diagnostic ou un traitement médical validé.', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _recherche,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Rechercher dans le mémo…',
              ),
            ),
            const SizedBox(height: 10),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Fiches techniques', label: Text('Fiches techniques'), icon: Icon(Icons.menu_book_outlined)),
                ButtonSegment(value: 'Mémo', label: Text('Mémo pratique'), icon: Icon(Icons.info_outline)),
              ],
              selected: {_onglet},
              onSelectionChanged: (v) => setState(() => _onglet = v.first),
            ),
            const SizedBox(height: 12),
            if (_onglet == 'Fiches techniques')
              ...fiches.map((titre) => Card(
                child: ListTile(
                  leading: const Icon(Icons.description_outlined, color: Colors.indigo),
                  title: Text(titre),
                  subtitle: const Text('Référence papier — fiche technique fournie'),
                ),
              ))
            else
              ...guides.map((guide) => Card(
                child: ExpansionTile(
                  leading: const Icon(Icons.auto_awesome_outlined, color: Colors.teal),
                  title: Text(guide.titre, style: const TextStyle(fontWeight: FontWeight.w600)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: SelectableText(guide.texte),
                    ),
                  ],
                ),
              )),
            if ((_onglet == 'Fiches techniques' && fiches.isEmpty) || (_onglet == 'Mémo' && guides.isEmpty))
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Aucun résultat.')),
              ),
          ],
        ),
      ),
    );
  }
}

class _GuideEntry {
  final String titre;
  final String texte;
  const _GuideEntry(this.titre, this.texte);
}
