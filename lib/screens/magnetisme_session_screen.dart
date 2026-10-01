import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../services/magnetisme_session_service.dart';

class MagnetismeSessionScreen extends StatefulWidget {
  final String? prefillNom;
  final String? prefillNomFamille;

  const MagnetismeSessionScreen({
    super.key,
    this.prefillNom,
    this.prefillNomFamille,
  });

  @override
  State<MagnetismeSessionScreen> createState() => _MagnetismeSessionScreenState();
}

class _MagnetismeSessionScreenState extends State<MagnetismeSessionScreen> {
  final _prenom = TextEditingController();
  final _nom = TextEditingController();
  final _observations = TextEditingController();
  final _debriefController = TextEditingController();
  final _vitalite = TextEditingController();
  final _vibratoire = TextEditingController();
  final _corps = TextEditingController();
  final _entites = TextEditingController();
  final _negatives = TextEditingController();
  final _organes = TextEditingController();
  final _sang = TextEditingController();
  final _bilanNotes = TextEditingController();
  final _degagementNotes = TextEditingController();

  final Set<int> _etapesFaites = <int>{};
  final Set<int> _conventionsFaites = <int>{};
  final Map<String, String?> _chakras = <String, String?>{
    for (final name in _chakraNames) name: null,
  };

  List<_Doc> _docs = <_Doc>[];
  String? _ftId;
  String _mode = 'Présentiel';
  int _etapeOuverte = 0;
  bool _loading = true;
  bool _saving = false;
  bool _degagementNecessaire = false;

  static const _chakraNames = <String>[
    'Chakra racine',
    'Chakra sacré',
    'Chakra plexus solaire',
    'Chakra cœur',
    'Chakra gorge',
    'Chakra 3e œil',
    'Chakra couronne',
  ];

  static const _chakraChoices = <String>[
    'Déficience — G',
    'Déficience — I',
    'Déficience — F',
    'Équilibre',
    'Excès — F',
    'Excès — I',
    'Excès — G',
  ];

  static const _conventionNames = <String>[
    'Nettoyer les tensions présentes',
    'Nettoyer les blocages énergétiques',
    'Nettoyer les mauvaises mémoires de la vie actuelle',
    'Nettoyer les mauvaises mémoires de la vie intra-utérine',
    'Nettoyer les mauvaises mémoires transgénérationnelles',
    'Nettoyer les mauvaises mémoires des vies antérieures',
    'Nettoyer l’impact des métaux lourds',
    'Nettoyer la chimie des médicaments que le corps peine à éliminer',
    'Nettoyer les 7 corps',
    'Nettoyer et harmoniser les 7 chakras',
    'Recharger tous les organes',
    'Nettoyer les toxines hydrosolubles et liposolubles',
    'Magnétiser la raison pour laquelle la personne est venue',
    'Magnétisme général de la personne',
  ];

  @override
  void initState() {
    super.initState();
    _prenom.text = widget.prefillNom ?? '';
    _nom.text = widget.prefillNomFamille ?? '';
    _load();
  }

  @override
  void dispose() {
    for (final controller in <TextEditingController>[
      _prenom, _nom, _observations, _debriefController, _vitalite, _vibratoire,
      _corps, _entites, _negatives, _organes, _sang, _bilanNotes,
      _degagementNotes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString('assets/data/magnetisme_protocoles.json');
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final fiches = data['fiches'];
      if (fiches is! List) throw const FormatException('Fiches absentes');

      final docs = fiches.whereType<Map>().map((item) {
        return _Doc.fromJson(Map<String, dynamic>.from(item));
      }).toList();

      if (!mounted) return;
      setState(() {
        _docs = docs;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String get _patient {
    final prenom = _prenom.text.trim();
    final nom = _nom.text.trim();
    if (nom.isEmpty) return prenom;
    if (prenom.isEmpty) return nom;
    return prenom + ' ' + nom;
  }

  _Doc? get _ft {
    for (final doc in _docs) {
      if (doc.id == _ftId) return doc;
    }
    return null;
  }

  _Doc? _reference(String contains) {
    final query = contains.toLowerCase();
    for (final doc in _docs) {
      final haystack = (doc.id + ' ' + doc.titre + ' ' + doc.source).toLowerCase();
      if (haystack.contains(query)) return doc;
    }
    return null;
  }

  List<_Doc> get _fts {
    final result = _docs.where((doc) => doc.type == 'fiche_technique').toList();
    result.sort((a, b) => a.titre.toLowerCase().compareTo(b.titre.toLowerCase()));
    return result;
  }

  List<String> get _etapes => <String>[
        'Prise de contact',
        'Bilan énergétique',
        'Dégagement des entités / énergies négatives si nécessaire',
        '14 conventions mentales',
        'Conventions mentales supplémentaires de la fiche technique',
        'Prières / formulations prévues par le protocole',
        if (_mode == 'Présentiel') ...<String>[
          'Passes et impositions selon la fiche',
          'Circulation énergétique entre les chakras',
          'Balayage',
        ] else ...<String>[
          'Travail sur photo / planches anatomiques selon la fiche',
          'Renforcement de l’intention, notamment lors de la convention n°10',
        ],
        'Débriefing / observation',
      ];

  Future<void> _enregistrer() async {
    if (_saving || _patient.isEmpty || _ft == null) return;

    setState(() => _saving = true);

    await MagnetismeSessionService.save(<String, dynamic>{
      'date': DateTime.now().toIso8601String(),
      'nomPatient': _prenom.text.trim(),
      'nomFamille': _nom.text.trim(),
      'mode': _mode,
      'ftId': _ft!.id,
      'ftTitre': _ft!.titre,
      'etapes': _etapes,
      'etapesFaites': _etapesFaites.toList()..sort(),
      'conventionsFaites': _conventionsFaites.toList()..sort(),
      'degagementNecessaire': _degagementNecessaire,
      'degagementNotes': _degagementNotes.text.trim(),
      'bilan': <String, dynamic>{
        'vitalite': _vitalite.text.trim(),
        'vibratoire': _vibratoire.text.trim(),
        'corpsEnergetiques': _corps.text.trim(),
        'chakras': Map<String, String?>.from(_chakras),
        'entites': _entites.text.trim(),
        'energiesNegatives': _negatives.text.trim(),
        'organesZones': _organes.text.trim(),
        'sang': _sang.text.trim(),
        'notes': _bilanNotes.text.trim(),
      },
      'observations': _observations.text.trim(),
      'debrief': _debriefController.text.trim(),
    });

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Séance de magnétisme enregistrée.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final total = _etapes.length;
    final faites = _etapesFaites.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle séance magnétisme')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: FilledButton.icon(
          onPressed: _saving || _patient.isEmpty || _ft == null ? null : _enregistrer,
          icon: const Icon(Icons.save_outlined),
          label: Text(_saving ? 'Enregistrement…' : 'Enregistrer la séance'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        children: <Widget>[
          _patientCard(),
          const SizedBox(height: 10),
          _ftCard(),
          if (_ft != null) ...<Widget>[
            const SizedBox(height: 10),
            _progressCard(faites, total),
            const SizedBox(height: 10),
            ...List<Widget>.generate(_etapes.length, _stepCard),
          ],
        ],
      ),
    );
  }

  Widget _patientCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(children: <Widget>[
              const Icon(Icons.person_outline, color: Colors.indigo),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _patient.isEmpty ? 'Nouveau patient' : _patient,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            TextField(
              controller: _prenom,
              decoration: const InputDecoration(labelText: 'Prénom', isDense: true),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nom,
              decoration: const InputDecoration(labelText: 'Nom', isDense: true),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            const Text('Type de séance', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            SegmentedButton<String>(
              segments: const <ButtonSegment<String>>[
                ButtonSegment(value: 'Présentiel', label: Text('Présentiel'), icon: Icon(Icons.person)),
                ButtonSegment(value: 'À distance', label: Text('À distance'), icon: Icon(Icons.phone_in_talk)),
              ],
              selected: <String>{_mode},
              onSelectionChanged: (selection) {
                setState(() => _mode = selection.first);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _ftCard() {
    final pathologyNames = _fts.map((doc) => doc.titre).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Row(children: <Widget>[
              Icon(Icons.menu_book_outlined, color: Colors.indigo),
              SizedBox(width: 8),
              Text('Préparer le soin', style: TextStyle(fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _ftId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Fiche technique principale',
                border: OutlineInputBorder(),
              ),
              items: _fts.map((doc) => DropdownMenuItem<String>(
                value: doc.id,
                child: Text(doc.titre, overflow: TextOverflow.ellipsis),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _ftId = value;
                  final doc = _find(value);
                  _pathologies.clear();
                  if (doc != null) _pathologies.add(doc.titre);
                  _etapeOuverte = 0;
                  _conventionOuverte = 0;
                  _etapesFaites.clear();
                  _conventionsFaites.clear();
                });
              },
            ),
            const SizedBox(height: 12),
            const Text('Pathologies / motifs du soin', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Tu peux en sélectionner plusieurs : les prières et FT correspondantes seront proposées dans le déroulé.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: pathologyNames.map((name) => FilterChip(
                label: Text(name),
                selected: _pathologies.contains(name),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _pathologies.add(name);
                    } else {
                      _pathologies.remove(name);
                    }
                  });
                },
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressCard(int faites, int total) {
    return Card(
      color: Colors.indigo.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Row(children: <Widget>[
            const Icon(Icons.route_outlined, color: Colors.indigo),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Déroulé du soin — ' + faites.toString() + ' / ' + total.toString() + ' étapes',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: total == 0 ? 0 : faites / total),
          const SizedBox(height: 8),
          Text(
            'Les cadrans restent sur papier : l’application sert de guide et de mémoire.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ]),
      ),
    );
  }

  Widget _stepCard(int index) {
    final title = _etapes[index];
    final open = _etapeOuverte == index;
    final done = _etapesFaites.contains(index);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: Column(children: <Widget>[
        InkWell(
          onTap: () => setState(() => _etapeOuverte = open ? -1 : index),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(children: <Widget>[
              CircleAvatar(radius: 17, child: Text((index + 1).toString())),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
              Icon(done ? Icons.check_circle : Icons.chevron_right,
                  color: done ? Colors.green : Colors.grey),
            ]),
          ),
        ),
        if (open)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: _stepContent(index),
          ),
      ]),
    );
  }

  Widget _stepContent(int index) {
    if (index == 0) return _contactHelp();
    if (index == 1) return _bilan();
    if (index == 2) return _degagement();
    if (index == 3) return _conventions();
    if (index == 4) return _specific();
    if (index == 5) return _prieres();
    if (index == _etapes.length - 1) return _debrief();
    return _technique(index);
  }

  Widget _contactHelp() {
    return _stepLayout(
      help: 'Cerner la personne et être à son écoute. Prendre les notes utiles avant le bilan énergétique.',
      source: _reference('récap séance'),
      doneIndex: 0,
    );
  }

  Widget _bilan() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      _helpBox(
        'Le bilan est systématique. Les mesures se font avec tes cadrans papier. Ici, tu notes uniquement les résultats.',
        _reference('bilan énergétique'),
      ),
      _compactNumber('Vitalité', _vitalite),
      _compactNumber('Taux vibratoire', _vibratoire),
      _compactText('Corps énergétiques', _corps),
      _resultField('Entités', _entites, 'Contrôle au pendule'),
      _resultField('Énergies négatives', _negatives, 'Contrôle au pendule'),
      _resultField('Organes / zones', _organes, 'Zones ou organes ressortant du bilan'),
      _resultField('Qualité énergétique du sang', _sang, 'Résultat du cadran'),
      ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: const Text('7 chakras', style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: const Text('Développer uniquement pour renseigner les résultats'),
        children: _chakraNames.map((name) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DropdownButtonFormField<String>(
              value: _chakras[name],
              isExpanded: true,
              decoration: InputDecoration(
                labelText: name,
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              items: _chakraChoices.map((choice) {
                return DropdownMenuItem<String>(value: choice, child: Text(choice));
              }).toList(),
              onChanged: (value) => setState(() => _chakras[name] = value),
            ),
          );
        }).toList(),
      ),
      _compactText('Notes du bilan', _bilanNotes, minLines: 2),
      _checkStep(1),
    ]);
  }

  Widget _degagement() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      _helpBox(
        'Cette étape n’est pas systématique. Elle est réalisée si quelque chose a été détecté au bilan et avant le travail de magnétisme.',
        _reference('récap séance'),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Dégagement nécessaire'),
        value: _degagementNecessaire,
        onChanged: (value) => setState(() => _degagementNecessaire = value),
      ),
      if (_degagementNecessaire)
        _compactText('Notes / formulation utilisée', _degagementNotes, minLines: 2),
      _checkStep(2),
    ]);
  }

  Widget _conventions() {
    final index = _conventionOuverte;
    final done = _conventionsFaites.contains(index);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _helpBox(
          'Une convention à la fois. Ouvre-la, lis le rappel, réalise-la, coche-la, puis passe directement à la suivante.',
          source,
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Convention ' + (index + 1).toString() + ' / 14',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              done ? 'Réalisée' : 'À faire',
              style: TextStyle(
                color: done ? Colors.green : Colors.orange.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          color: Colors.indigo.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              _extractConvention(index),
              style: const TextStyle(fontSize: 14, height: 1.45),
            ),
          ),
        ),
        Row(
          children: <Widget>[
            OutlinedButton.icon(
              onPressed: index == 0
                  ? null
                  : () => setState(() => _conventionOuverte--),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Précédente'),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _conventionsFaites.add(index);
                  if (index < 13) {
                    _conventionOuverte++;
                  }
                });
              },
              icon: Icon(index == 13 ? Icons.check : Icons.arrow_forward),
              label: Text(index == 13 ? '14 réalisée' : 'Réalisée → suivante'),
            ),
          ],
        ),
        if (_conventionsFaites.length == 14) _checkStep(3),
      ],
    );
  }

  String _extractConvention(int index) {
    final doc = _reference('14 conventions');
    if (doc == null) return _conventionTitles[index];
    final text = _clean(doc.contenu);
    final lines = text.split('\n');
    final title = _conventionTitles[index].toUpperCase();
    var start = -1;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim().toUpperCase();
      if (line == title || line.contains(title)) {
        start = i;
        break;
      }
    }
    if (start < 0) {
      final marker = '(' + (index + 1).toString() + ')';
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].trim().startsWith(marker)) {
          start = i;
          break;
        }
      }
    }
    if (start < 0) return _conventionTitles[index];
    var end = lines.length;
    for (var i = start + 1; i < lines.length; i++) {
      final line = lines[i].trim();
      final upper = line.toUpperCase();
      if (i > start + 2 &&
          (_conventionTitles.any((item) => upper == item.toUpperCase()) ||
           RegExp(r'^\(\d+\)').hasMatch(line))) {
        end = i;
        break;
      }
    }
    return lines.sublist(start, end).join('\n').trim();
  }

  Widget _specific() {
    return _stepLayout(
      help: 'Les conventions supplémentaires viennent de la FT choisie. Ne rien inventer : ouvrir la FT et suivre uniquement ce qui y est indiqué.',
      source: _ft,
      doneIndex: 4,
      actionLabel: 'Ouvrir la FT',
    );
  }

  Widget _prieres() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _helpBox(
          'Les prières sont prises dans prières.pdf. Sélectionne une ou plusieurs pathologies dans Préparer le soin : les formulations correspondantes apparaissent directement ici.',
        ),
        if (_pathologies.isEmpty)
          const Text('Sélectionne au moins une pathologie / motif.'),
        ..._pathologies.map((pathology) {
          final prayer = _extractPrayer(pathology);
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ExpansionTile(
              title: Text(pathology),
              subtitle: Text(
                prayer.isEmpty
                    ? 'Aucune prière dédiée trouvée dans prières.pdf'
                    : 'Prière disponible — ouvrir',
              ),
              children: prayer.isEmpty
                  ? <Widget>[]
                  : <Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                        child: Text(
                          prayer,
                          style: const TextStyle(fontSize: 14, height: 1.45),
                        ),
                      ),
                    ],
            ),
          );
        }),
        _checkStep(5),
      ],
    );
  }

  String _extractPrayer(String pathology) {
    final doc = _prieresDoc;
    if (doc == null) return '';
    const aliases = <String, String>{
      'Couper le feu': 'CONTRE LE FEU',
      'Verrue': 'VERRUES',
      'Eczéma': 'ECZÉMA',
      'Arthrite': 'ARTHRITE, POLYARTHRITE',
      'Déprime': 'DÉPRESSION & ANGOISSE',
      'Allergie': 'ALLERGIE',
      'Hémorragie': 'HÉMORRAGIE',
      'Coupure': 'COUPURES',
      'Aphtes': 'APHTES',
      'Maux de ventre': 'MAUX DE VENTRE & CONSTIPATION',
      'Constipation': 'MAUX DE VENTRE & CONSTIPATION',
    };
    final alias = aliases[pathology];
    if (alias == null) return '';
    final lines = _clean(doc.contenu).split('\n');
    var start = -1;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim().toUpperCase();
      if (line == alias || line.contains(alias)) {
        start = i;
        break;
      }
    }
    if (start < 0) return '';
    const headings = <String>[
      'CONTRE LE FEU',
      'HÉMORRAGIE',
      'VERRUES',
      'PLAIES & ULCÈRES',
      'ECZÉMA',
      'COUPURES',
      'MAUX DE DOS',
      'CIRCULATION SANGUINE',
      'MAUX DE VENTRE & CONSTIPATION',
      'APHTES',
      'ARTHRITE, POLYARTHRITE',
      'DÉPRESSION & ANGOISSE',
      'ALLERGIE',
      'PRIÈRE DE DEMANDE DE GUÉRISON',
    ];
    var end = lines.length;
    for (var i = start + 1; i < lines.length; i++) {
      if (headings.contains(lines[i].trim().toUpperCase())) {
        end = i;
        break;
      }
    }
    return lines.sublist(start, end).join('\n').trim();
  }

  Widget _technique(int index) {
    final distance = _mode == 'À distance';
    final source = _reference(distance ? 'récap séance à distance' : 'récap séance présentiel');
    final items = distance
        ? <String>[
            'Travail sur photo / planches anatomiques selon la FT',
            'Renforcement de l’intention lors de la convention n°10',
          ]
        : <String>[
            'Passes et impositions selon la FT',
            'Circulation énergétique entre les chakras',
            'Balayage',
          ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      _helpBox(
        distance
            ? 'À distance : pas de passes ni d’impositions au-dessus de la personne. Le protocole fourni prévoit le travail sur photo / planches anatomiques et une intention renforcée, notamment à la convention n°10.'
            : 'En présentiel : suivre les passes et impositions prévues par la FT, puis la circulation énergétique entre les chakras et le balayage selon le récapitulatif fourni.',
        source,
      ),
      ...items.map((item) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.check_box_outline_blank),
        title: Text(item),
      )),
      if (_ft != null)
        OutlinedButton.icon(
          onPressed: () => _openReader(_ft!),
          icon: const Icon(Icons.description_outlined),
          label: const Text('Revoir la FT'),
        ),
      _checkStep(index),
    ]);
  }

  Widget _debrief() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      _helpBox(
        'Terminer par l’observation et le débriefing. Noter ce qui est utile pour retrouver le déroulement lors d’une prochaine séance.',
        _reference('récap séance'),
      ),
      _compactText('Observations générales', _observations, minLines: 3),
      _compactText('Débriefing', _debriefController, minLines: 3),
      _checkStep(_etapes.length - 1),
    ]);
  }

  Widget _stepLayout({
    required String help,
    required _Doc? source,
    required int doneIndex,
    String actionLabel = 'Ouvrir le document source',
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      _helpBox(help, source),
      if (source != null)
        OutlinedButton.icon(
          onPressed: () => _openReader(source),
          icon: const Icon(Icons.menu_book_outlined),
          label: Text(actionLabel),
        ),
      _checkStep(doneIndex),
    ]);
  }

  Widget _helpBox(String text, _Doc? source) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.indigo.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          const Icon(Icons.lightbulb_outline, color: Colors.indigo),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ]),
      ),
    );
  }

  Widget _checkStep(int index) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Étape réalisée', style: TextStyle(fontWeight: FontWeight.w600)),
      value: _etapesFaites.contains(index),
      onChanged: (value) {
        setState(() {
          if (value == true) {
            _etapesFaites.add(index);
            if (index < _etapes.length - 1) _etapeOuverte = index + 1;
          } else {
            _etapesFaites.remove(index);
          }
        });
      },
    );
  }

  Widget _compactNumber(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
      ),
    );
  }

  Widget _compactText(String label, TextEditingController controller, {int minLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        minLines: minLines,
        maxLines: minLines + 3,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), alignLabelWithHint: true),
      ),
    );
  }

  Widget _resultField(String label, TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        minLines: 1,
        maxLines: 3,
        decoration: InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder(), isDense: true),
      ),
    );
  }

  Future<void> _openReader(_Doc doc) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => _MagnetismeDocumentScreen(doc: doc)),
    );
  }
}

class _MagnetismeDocumentScreen extends StatefulWidget {
  final _Doc doc;
  const _MagnetismeDocumentScreen({required this.doc});

  @override
  State<_MagnetismeDocumentScreen> createState() => _MagnetismeDocumentScreenState();
}

class _MagnetismeDocumentScreenState extends State<_MagnetismeDocumentScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _clean(String value) {
    var text = value
        .replaceAll('\u000c', '\n\n')
        .replaceAll('\u0000', '')
        .replaceAll('+?', 'é')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n[ \t]+'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }

  @override
  Widget build(BuildContext context) {
    final sourceText = _clean(widget.doc.contenu);
    final query = _search.text.trim().toLowerCase();
    final visible = query.isEmpty ? sourceText : _excerpt(sourceText, query);
    final paragraphs = visible
        .split(RegExp(r'\n{2,}'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.doc.titre)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
        children: <Widget>[
          Card(
            color: Colors.indigo.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Source : ' + widget.doc.source,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Rechercher dans le document…',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ...paragraphs.map((paragraph) {
            final heading = paragraph.length < 100 &&
                (paragraph == paragraph.toUpperCase() ||
                    RegExp(r'^\(\d+\)').hasMatch(paragraph));
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SelectableText(
                paragraph,
                style: TextStyle(
                  fontSize: heading ? 16 : 15,
                  height: 1.45,
                  fontWeight:
                      heading ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _excerpt(String text, String query) {
    final lower = text.toLowerCase();
    final index = lower.indexOf(query);
    if (index < 0) return 'Aucun résultat pour « ' + query + ' ».';

    final start = index > 500 ? index - 500 : 0;
    final end = index + query.length + 1000;
    final excerpt = text.substring(start, end > text.length ? text.length : end);
    return (start > 0 ? '… ' : '') + excerpt + (end < text.length ? ' …' : '');
  }
}

class _Doc {
  final String id;
  final String titre;
  final String source;
  final String type;
  final String contenu;

  const _Doc({
    required this.id,
    required this.titre,
    required this.source,
    required this.type,
    required this.contenu,
  });

  factory _Doc.fromJson(Map<String, dynamic> json) {
    return _Doc(
      id: (json['id'] ?? '').toString(),
      titre: (json['titre'] ?? '').toString(),
      source: (json['source'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      contenu: (json['contenu'] ?? '').toString(),
    );
  }
}
