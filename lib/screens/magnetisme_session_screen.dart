import 'dart:async';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../services/bilan_energetique_pdf_service.dart';

import '../services/magnetisme_session_service.dart';
import '../services/magnetisme_library_service.dart';
import '../widgets/interactive_body.dart';

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

class _MagnetismeSessionScreenState extends State<MagnetismeSessionScreen> with WidgetsBindingObserver {
  void _updateScreenAwake(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _updateScreenAwake(state);
  }

  final _prenom = TextEditingController();
  final _nom = TextEditingController();
  final _observations = TextEditingController();
  final _debriefController = TextEditingController();
  final _vitalite = TextEditingController();
  final _vibratoire = TextEditingController();
  final _entites = TextEditingController();
  final _negatives = TextEditingController();
  final _sang = TextEditingController();
  final _bilanNotes = TextEditingController();
  final _traitements = TextEditingController();
  final _degagementNotes = TextEditingController();
  final _soinPenduleZone = TextEditingController();
  final _soinPenduleNotes = TextEditingController();
  final Set<String> _soinPenduleZones = <String>{};
  final Set<String> _zonesSoin = <String>{};
  bool _utiliserRaphael = false;

  late final Map<String, TextEditingController> _anamneseFields;

  late final Map<String, TextEditingController> _corpsFields;
  late final Map<String, TextEditingController> _teteCouFields;
  late final Map<String, TextEditingController> _troncOrganesFields;
  late final Map<String, TextEditingController> _troncOsseuxFields;
  late final Map<String, TextEditingController> _uroGenitalFields;
  late final Map<String, TextEditingController> _chakraFields;

  static const _anamneseNames = <String>[
    'Comment m’avez-vous connu ?',
    'Que puis-je faire pour vous ?',
    'Depuis quand souffrez-vous ?',
    'Avez-vous vu votre médecin ou spécialiste ? Quel est le diagnostic ?',
    'Est-ce qu’un événement a eu lieu avant les maux ?',
    'Comment se passent votre sommeil et votre digestion ?',
    'Quel est votre environnement professionnel ? Est-ce que votre travail se passe bien ?',
    'Avez-vous une autre source de stress ?',
    'Éléments recueillis / observations',
  ];

  static const _corpsNames = <String>['2', '3', '4', '5', '6', '7'];
  static const _teteCouNames = <String>[
    'Cerveau G et D', 'Oreille G et D',
    'Cervelet', 'Bouche',
    'Hypophyse', 'Gencives',
    'Hypothalamus', 'Dents',
    'Glande pinéale', 'Glandes salivaires',
    'Sinus frontal G et D', 'Gorge',
    'Œil G et D', 'Thyroïde',
    'Sinus maxillaire G et D', 'Thymus',
  ];
  static const _troncOrganesNames = <String>[
    'Cœur', 'Rate',
    'Poumon G et D', 'Pancréas',
    'Sein G et D', 'Intestin grêle',
    'Foie', 'Côlon ascendant',
    'Vésicule', 'Côlon descendant',
    'Estomac', 'Côlon transverse',
  ];
  static const _troncOsseuxNames = <String>[
    'Vertèbres cervicales (7)', 'Sacrum (5)',
    'Vertèbres thoraciques (12)', 'Coccyx (4 ou 5)',
    'Vertèbres lombaires (5)',
  ];
  static const _uroGenitalNames = <String>[
    'Rein G et D', 'Prostate',
    'Glande surrénale G et D', 'Utérus',
    'Vessie', 'Ovaire G et D',
  ];

  final Set<int> _etapesFaites = <int>{};
  final Set<int> _conventionsFaites = <int>{};
  final Set<int> _conventionsSupplementairesFaites = <int>{};
  final Set<String> _pathologies = <String>{};
  List<_Doc> _docs = <_Doc>[];
  String? _ftId;
  String _mode = 'Présentiel';
  int _etapeOuverte = 0;
  int _conventionOuverte = 0;
  Timer? _timerConventions;
  int _secondesRestantes = 60;
  bool _lectureAuto = false;
  bool _lectureSuspendue = false;
  bool _scanDetailVisible = false;
  int _dureePersonnalisee = 0;
  int _conventionSuppAuto = 0;
  bool _phaseSupplementaire = false;
  bool _loading = true;
  bool _saving = false;
  bool _degagementNecessaire = false;
  bool _soinPenduleNecessaire = false;
  bool _scanPenduleNecessaire = false;
  String _priereFeu = 'Prière contre le feu indisponible dans la bibliothèque.';
  final List<bool> _soinPenduleEtapes = List<bool>.filled(9, false);

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

  static const _conventionTitles = <String>[
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
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    _prenom.text = widget.prefillNom ?? '';
    _nom.text = widget.prefillNomFamille ?? '';
    _anamneseFields = _controllersFor(_anamneseNames);
    _corpsFields = _controllersFor(_corpsNames);
    _teteCouFields = _controllersFor(_teteCouNames);
    _troncOrganesFields = _controllersFor(_troncOrganesNames);
    _troncOsseuxFields = _controllersFor(_troncOsseuxNames);
    _uroGenitalFields = _controllersFor(_uroGenitalNames);
    _chakraFields = _controllersFor(_chakraNames);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    _timerConventions?.cancel();
    for (final controller in <TextEditingController>[
      _prenom, _nom, _observations, _debriefController, _vitalite, _vibratoire,
      _entites, _negatives, _sang, _bilanNotes,
      _traitements, _degagementNotes, _soinPenduleZone, _soinPenduleNotes,
      ..._anamneseFields.values,
      ..._corpsFields.values,
      ..._teteCouFields.values,
      ..._troncOrganesFields.values,
      ..._troncOsseuxFields.values,
      ..._uroGenitalFields.values,
      ..._chakraFields.values,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final fiches = await MagnetismeLibraryService.loadAll();
      final docs = fiches.map((item) => _Doc.fromJson(item)).toList();

      if (!mounted) return;
      setState(() {
        _docs = docs;
        _priereFeu = docs.where((d) => d.type == 'priere' && d.titre.trim().toUpperCase().contains('CONTRE LE FEU')).map((d) => d.contenu.trim()).where((t) => t.isNotEmpty).firstOrNull ?? _priereFeu;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Map<String, TextEditingController> _controllersFor(List<String> names) {
    return <String, TextEditingController>{
      for (final name in names) name: TextEditingController(),
    };
  }

  String _value(Map<String, TextEditingController> fields, String key) {
    return fields[key]?.text.trim() ?? '';
  }

  Widget _bilanResultField(
    String label,
    TextEditingController controller, {
    bool paired = false,
  }) {
    final choices = paired
        ? const <String>['G', 'D', 'G + D', 'Aucune faiblesse']
        : const <String>['Oui', 'Non'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: DropdownButtonFormField<String>(
        value: choices.contains(controller.text) ? controller.text : null,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          helperText: paired ? 'Côté : G / D' : 'Faiblesse énergétique',
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        items: choices.map((choice) => DropdownMenuItem<String>(
          value: choice,
          child: Text(choice),
        )).toList(),
        onChanged: (value) {
          if (value == null) return;
          setState(() => controller.text = value);
        },
      ),
    );
  }

  Widget _chakraEtatField(String label, TextEditingController controller) {
    const choix = <String>['Non évalué', 'Équilibré', 'Déficient', 'En excès'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<String>(
        value: choix.contains(controller.text) ? controller.text : 'Non évalué',
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          helperText: 'Axe tête-pieds : équilibré · droite du patient : déficient · gauche : excès',
          helperMaxLines: 2,
          border: const OutlineInputBorder(),
        ),
        items: choix.map((v) => DropdownMenuItem<String>(value: v, child: Text(v))).toList(),
        onChanged: (value) => setState(() => controller.text = value == 'Non évalué' ? '' : (value ?? '')),
      ),
    );
  }

  Widget _bilanSection(
    String title,
    Map<String, TextEditingController> fields, {
    required Color color,
  }) {
    final entries = fields.entries.toList();
    return Card(
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: Icon(Icons.fact_check_outlined, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(entries.where((e) => e.value.text.trim().isNotEmpty).length.toString() + ' résultat(s) renseigné(s)'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Column(
              children: [
                for (var i = 0; i < entries.length; i += 2)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _bilanResultField(
                          entries[i].key,
                          entries[i].value,
                          paired: entries[i].key.contains('G et D'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (i + 1 < entries.length)
                        Expanded(
                          child: _bilanResultField(
                            entries[i + 1].key,
                            entries[i + 1].value,
                            paired: entries[i + 1].key.contains('G et D'),
                          ),
                        )
                      else
                        const Expanded(child: SizedBox()),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
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

  _Doc? _find(String? id) {
    if (id == null) return null;
    for (final doc in _docs) {
      if (doc.id == id) return doc;
    }
    return null;
  }

  _Doc? get _prieresDoc => _docs.where((d) => d.type == 'priere').isEmpty ? null : _docs.firstWhere((d) => d.type == 'priere');

  String _clean(String value) {
    return value
        .replaceAll('\\u000c', '\\n\\n')
        .replaceAll('\\u0000', '')
        .replaceAll(RegExp(r'[ \\t]+'), ' ')
        .replaceAll(RegExp(r'\\n[ \\t]+'), '\\n')
        .replaceAll(RegExp(r'\\n{3,}'), '\\n\\n')
        .trim();
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

  bool get _isCouperLeFeu => _ft?.id == 'ft-couper-le-feu';

  String? _findPrayer(String title) {
    for (final doc in _docs) {
      if (doc.type == 'priere' && doc.titre.trim().toUpperCase() == title.trim().toUpperCase()) {
        return doc.contenu.trim();
      }
    }
    return null;
  }

  String get _patientOuPlaceholder => _patient.isEmpty ? '[Prénom NOM]' : _patient;

  void _onSoinPenduleZoneTap(String zone) {
    setState(() {
      if (_soinPenduleZones.contains(zone)) {
        _soinPenduleZones.remove(zone);
      } else {
        _soinPenduleZones.add(zone);
      }
      _soinPenduleZone.text = _soinPenduleZones.join(', ');
    });
  }

  void _onZoneSoinTap(String zone) {
    setState(() {
      if (_zonesSoin.contains(zone)) {
        _zonesSoin.remove(zone);
      } else {
        _zonesSoin.add(zone);
      }
    });
  }


  List<String> get _etapes {
    if (_isCouperLeFeu) {
      return <String>[
        'Accueil et prise de contact',
        if (_scanPenduleNecessaire) 'Scan au pendule',
        if (_soinPenduleNecessaire) 'Soin au pendule (1 soin)',
        'Prière contre le feu',
        if (_mode == 'Présentiel') 'Imposition des mains et intention',
        if (_mode == 'Présentiel') 'Balayage & débriefing' else 'Débriefing',
      ];
    }

    return <String>[
      'Prise de contact',
      'Bilan énergétique',
      if (_scanPenduleNecessaire) 'Scan au pendule',
      if (_soinPenduleNecessaire) 'Soin au pendule (1 soin)',
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
  }

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
      'zonesSoin': _zonesSoin.toList(),
      'utiliserRaphael': _utiliserRaphael,
      'etapes': _etapes,
      'anamnese': {for (final e in _anamneseFields.entries) e.key: e.value.text.trim()},
      'soinPenduleNecessaire': _soinPenduleNecessaire,
      'scanPenduleNecessaire': _scanPenduleNecessaire,
      'soinPendule': _soinPenduleNecessaire ? {
        'zone': _soinPenduleZone.text.trim(),
        'etapes': List<bool>.from(_soinPenduleEtapes),
        'notes': _soinPenduleNotes.text.trim(),
      } : null,
      'etapesFaites': _etapesFaites.toList()..sort(),
      'conventionsFaites': _conventionsFaites.toList()..sort(),
      'degagementNecessaire': _degagementNecessaire,
      'degagementNotes': _degagementNotes.text.trim(),
      'bilan': <String, dynamic>{
        'vitalite': _vitalite.text.trim(),
        'vibratoire': _vibratoire.text.trim(),
        'corpsEnergetiques': {for (final e in _corpsFields.entries) e.key: e.value.text},
        'chakras': {for (final e in _chakraFields.entries) e.key: e.value.text},
        'entites': _entites.text.trim(),
        'energiesNegatives': _negatives.text.trim(),
        'organesZones': {
          'teteCou': {for (final e in _teteCouFields.entries) e.key: e.value.text},
          'troncOrganes': {for (final e in _troncOrganesFields.entries) e.key: e.value.text},
          'troncOsseux': {for (final e in _troncOsseuxFields.entries) e.key: e.value.text},
          'uroGenital': {for (final e in _uroGenitalFields.entries) e.key: e.value.text},
        },
        'sang': _sang.text.trim(),
        'traitements': _traitements.text.trim(),
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
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Nouvelle séance magnétisme'),
          ],
        ),
      ),
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
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _scanPenduleNecessaire,
              title: const Text('Réaliser un scan au pendule'),
              subtitle: const Text('Vitalité, taux vibratoire, chakras et zones du corps.'),
              onChanged: (value) => setState(() {
                _scanPenduleNecessaire = value ?? false;
                _etapesFaites.clear();
              }),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _soinPenduleNecessaire,
              title: const Text(
                'Faire 1 soin au pendule pendant cette séance',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Ajoute automatiquement la fiche du soin au déroulé de la séance.',
              ),
              onChanged: (value) => setState(() {
                _soinPenduleNecessaire = value ?? false;
                if (!_soinPenduleNecessaire) {
                  for (var i = 0; i < _soinPenduleEtapes.length; i++) {
                    _soinPenduleEtapes[i] = false;
                  }
                }
              }),
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
                  _conventionsSupplementairesFaites.clear();
                  _zonesSoin.clear();
                  _utiliserRaphael = false;
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
            const SizedBox(height: 14),
            const Text('Zone(s) anatomique(s) à traiter', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text(
              'Sélectionnez la ou les zones une seule fois. Elles seront mémorisées et réutilisées automatiquement pendant le travail local.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            InteractiveBody(
              selectedZones: _zonesSoin,
              onZoneTap: _onZoneSoinTap,
            ),
            if (_zonesSoin.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _zonesSoin.map((zone) => Chip(
                  label: Text(zone),
                  onDeleted: () => _onZoneSoinTap(zone),
                )).toList(),
              ),
            ],
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
                'Parcours V3 — ' + faites.toString() + ' / ' + total.toString() + ' étapes',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: total == 0 ? 0 : faites / total),
          const SizedBox(height: 8),
          Text(
            'La V3 rassemble ici les informations utiles de la fiche pour guider la séance sans navigation inutile.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ]),
      ),
    );
  }

  final Map<int, GlobalKey> _stepKeys = <int, GlobalKey>{};

  Widget _stepCard(int index) {
    final title = _etapes[index];
    final open = _etapeOuverte == index;
    final done = _etapesFaites.contains(index);

    final stepKey = _stepKeys.putIfAbsent(index, () => GlobalKey());
    return Card(
      key: stepKey,
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: Column(children: <Widget>[
        InkWell(
          onTap: () {
            setState(() => _etapeOuverte = open ? -1 : index);
            if (!open) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                final target = _stepKeys[index];
                if (target?.currentContext != null) {
                  Scrollable.ensureVisible(
                    target!.currentContext!,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                    alignment: 0.04,
                  );
                }
              });
            }
          },
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
    if (_isCouperLeFeu) {
      if (index == 0) return _couperLeFeuStep(0);
      if (_scanPenduleNecessaire && index == 1) return _scanPenduleStep();
      if (_soinPenduleNecessaire && index == 1 + (_scanPenduleNecessaire ? 1 : 0)) return _soinPenduleStep();
      final baseIndex = index - (_scanPenduleNecessaire ? 1 : 0) - (_soinPenduleNecessaire ? 1 : 0);
      if (_mode == 'À distance' && baseIndex == 2) return _couperLeFeuStep(3);
      return _couperLeFeuStep(baseIndex);
    }

    if (index == 0) return _contactHelp();
    if (index == 1) return _bilan();
    if (_scanPenduleNecessaire && index == 2) return _scanPenduleStep();
    if (_soinPenduleNecessaire && index == 2 + (_scanPenduleNecessaire ? 1 : 0)) return _soinPenduleStep();
    final offset = (_soinPenduleNecessaire ? 1 : 0) + (_scanPenduleNecessaire ? 1 : 0);
    if (index == 2 + offset) return _degagement();
    if (index == 3 + offset) return _conventions();
    if (index == 4 + offset) return _specific();
    if (index == 5 + offset) return _prieres();
    if (index == _etapes.length - 1) return _debrief();
    return _technique(index);
  }

  Widget _couperLeFeuStep(int index) {
    switch (index) {
      case 0:
        return _stepLayout(
          help: 'Accueil et prise de contact.',
          source: _ft,
          doneIndex: 0,
          actionLabel: 'Revoir le protocole',
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _helpBox(
              'Faites un signe de croix sur la zone concernée et récitez la prière contre le feu à 3 reprises.',
              _ft,
            ),
            Card(
              color: Colors.indigo.withValues(alpha: 0.06),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  MagnetismeLibraryService.personalized(_priereFeu, prenom: _prenom.text, nom: _nom.text),
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'À répéter 3 fois.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            _checkStep(1),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _helpBox(
              'Imposez les mains sur la zone concernée et réalisez les intentions dans l’ordre indiqué.',
              _ft,
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.looks_one_outlined),
              title: Text('Guérir les terminaisons nerveuses'),
              subtitle: Text('2 minutes'),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.looks_two_outlined),
              title: Text('Stopper l’inflammation et l’échauffement'),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.looks_3_outlined),
              title: Text('Visualiser la zone qui se refroidit et s’apaise'),
            ),
            _checkStep(2),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _helpBox(
              _mode == 'À distance' ? 'Terminer par le débriefing, sans balayage ni imposition physique.' : 'Terminer par le balayage et le débriefing.',
              _ft,
            ),
            _compactText(
              'Observations / débriefing',
              _debriefController,
              minLines: 3,
            ),
            _checkStep(3),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _contactHelp() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _helpBox(
          'La prise de contact se déroule en deux phases : d’abord l’anamnèse du consultant, puis le bilan énergétique au pendule. Le manuel recommande de réserver environ 10 minutes à cet échange et de noter les éléments utiles pour la séance.',
          _reference('récap séance'),
        ),
        Card(
          color: Colors.indigo.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Column(
              children: _anamneseFields.entries.map((entry) {
                final isNotes = entry.key == 'Éléments recueillis / observations';
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextField(
                    controller: entry.value,
                    minLines: isNotes ? 4 : 2,
                    maxLines: isNotes ? 8 : 4,
                    decoration: InputDecoration(
                      labelText: entry.key == 'Quel est votre environnement professionnel ? Est-ce que votre travail se passe bien ?' ? 'Environnement professionnel' : entry.key,
                      helperText: entry.key == 'Quel est votre environnement professionnel ? Est-ce que votre travail se passe bien ?' ? 'Quel est votre environnement professionnel ? Est-ce que votre travail se passe bien ?' : null,
                      helperMaxLines: 3,
                      alignLabelWithHint: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _checkStep(0),
      ],
    );
  }

  Widget _bilan() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _aideMemoire('Lecture des chakras au pendule', _memoChakras),
        _helpBox(
          'Le bilan est rempli au fur et à mesure avec les résultats relevés sur tes cadrans papier. Les champs restent dans la séance et seront repris dans la fiche PDF finale.',
          _reference('bilan énergétique'),
        ),
        Row(
          children: [
            Expanded(child: _compactNumber('Taux de vitalité', _vitalite)),
            const SizedBox(width: 8),
            Expanded(child: _compactNumber('Taux vibratoire', _vibratoire)),
          ],
        ),
        const SizedBox(height: 4),
        _bilanSection('6 corps énergétiques (2 à 7)', _corpsFields, color: Colors.green),
        Card(child: ExpansionTile(
          leading: const Icon(Icons.fact_check_outlined, color: Colors.deepPurple),
          title: const Text('7 chakras', style: TextStyle(fontWeight: FontWeight.w700)),
          children: [Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: _chakraFields.entries.map((e) => _chakraEtatField(e.key, e.value)).toList()),
          )],
        )),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Row(
              children: [
                Expanded(
                  child: _bilanResultField('Entités bas astral', _entites, paired: false),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _bilanResultField('Magie noire', _negatives, paired: false),
                ),
              ],
            ),
          ),
        ),
        SwitchListTile(
          title: const Text('Examiner les zones anatomiques en détail'),
          subtitle: const Text('Facultatif : ouvrir uniquement pour approfondir le scan'),
          value: _scanDetailVisible,
          onChanged: (value) => setState(() => _scanDetailVisible = value),
        ),
        if (_scanDetailVisible) ...<Widget>[
        _bilanSection('Tête & cou', _teteCouFields, color: Colors.cyan),
        _bilanSection('Tronc organes', _troncOrganesFields, color: Colors.orange),
        _bilanSection('Tronc osseux', _troncOsseuxFields, color: Colors.amber.shade700),
        _bilanSection('Appareil uro-génital', _uroGenitalFields, color: Colors.teal),
        ],
        _compactNumber('Qualité énergétique du sang (0 à 100 %)', _sang),
        _compactText(
          'Notes du bilan',
          _bilanNotes,
          minLines: 3,
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _genererBilanPdf,
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Générer la fiche PDF du bilan'),
        ),
        const SizedBox(height: 4),
        _checkStep(1),
      ],
    );
  }

  Future<void> _genererBilanPdf() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final file = await BilanEnergetiquePdfService.generate(
        prenom: _prenom.text,
        nom: _nom.text,
        date: DateTime.now(),
        vitalite: _vitalite.text,
        vibratoire: _vibratoire.text,
        corps: {for (final e in _corpsFields.entries) e.key: e.value.text},
        chakras: {for (final e in _chakraFields.entries) e.key: e.value.text},
        entites: _entites.text,
        magieNoire: _negatives.text,
        teteCou: {for (final e in _teteCouFields.entries) e.key: e.value.text},
        troncOrganes: {for (final e in _troncOrganesFields.entries) e.key: e.value.text},
        troncOsseux: {for (final e in _troncOsseuxFields.entries) e.key: e.value.text},
        uroGenital: {for (final e in _uroGenitalFields.entries) e.key: e.value.text},
        sang: _sang.text,
        notes: _bilanNotes.text,
        anamnese: {for (final e in _anamneseFields.entries) e.key: e.value.text},
      );
      await SharePlus.instance.share(
        ShareParams(
          title: 'Bilan énergétique',
          text: 'Bilan énergétique au pendule — ' + _patient,
          files: [XFile(file.path)],
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fiche PDF du bilan générée.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de générer le PDF : ' + e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _scanPenduleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('Résultats du scan au pendule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _compactNumber('Taux de vitalité', _vitalite),
        _compactNumber('Taux vibratoire', _vibratoire),
        const SizedBox(height: 8),
        const Text('Évaluation des sept chakras', style: TextStyle(fontWeight: FontWeight.w600)),
        ..._chakraFields.entries.map((entry) => _chakraEtatField(entry.key, entry.value)),
        const SizedBox(height: 8),
        const Text('Scan général : sélectionne uniquement les zones utiles', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text('Pour un examen plus précis, utilise les planches anatomiques de la bibliothèque.'),
        const SizedBox(height: 8),
        const Text('Zones anatomiques observées', style: TextStyle(fontWeight: FontWeight.w600)),
        InteractiveBody(selectedZones: _zonesSoin, onZoneTap: _onZoneSoinTap),
        _compactText('Notes du scan', _bilanNotes, minLines: 3),
        _checkStep(2),
      ],
    );
  }

  Widget _soinPenduleStep() {
    final patient = _patientOuPlaceholder;
    final degagement = 'Je demande ici et maintenant que $patient soit libéré(e) de toutes les énergies qui ne lui appartiennent pas.\nQue les pensées négatives, les projections et les influences d’autrui soient dissoutes et renvoyées à la terre pour être transformées. Je ferme son champ énergétique à ce qui n’est pas aligné avec sa paix intérieure.\nIl récupère ainsi sa pleine souveraineté, sa clarté et sa sérénité. Que seul l’amour et la bienveillance puissent franchir cet espace. Ainsi soit-il.';
    final protection = 'Je demande que $patient soit entouré(e) d’une lumière de force et de protection.\nQue son énergie vitale soit maintenant restaurée, vibrante et alignée. Je renforce ses propres barrières naturelles pour que son espace personnel reste pur et inattaquable par les influences extérieures.\nDésormais $patient est ancré(e), centré(e), et protégé(e). Que cette lumière rayonne depuis son cœur vers l’extérieur, transformant chaque obstacle en force.';

    final distance = _mode == 'À distance';
    final steps = <({int id, String title, String? detail})>[
      if (!distance) (id: 0, title: '20 passes rapides', detail: null),
      (id: 1, title: 'Prendre le pendule : intention de dégagement, rotation négative', detail: 'Rotation négative du pendule. Formule : « Je veux retirer les énergies négatives de… »'),
      (id: 2, title: 'Lever le pendule lorsque le mouvement négatif est terminé', detail: null),
      (id: 3, title: 'Taper 2 fois pour retirer le négatif', detail: 'Rappel systématique : 2 frappes après avoir levé le pendule.'),
      if (!distance) (id: 4, title: '15 passes lentes', detail: null),
      (id: 5, title: 'Rotation positive du pendule : intention de soulager la zone', detail: 'Relancer dans le sens positif en gardant l’intention de soulager la zone.'),
      (id: 6, title: 'Prière contre le feu × 3', detail: MagnetismeLibraryService.personalized(_priereFeu, prenom: _prenom.text, nom: _nom.text)),
      (id: 7, title: 'Formulation de dégagement', detail: degagement),
      (id: 8, title: 'Formulation de protection et de renforcement', detail: protection),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _helpBox(
          'Cette fiche n’est ajoutée que si tu as coché « Faire 1 soin au pendule ». La prière est récupérée depuis la bibliothèque magnétisme.',
          _reference('récap séance'),
        ),
        _compactText('Zone à travailler / intention', _soinPenduleZone, minLines: 1),
        const SizedBox(height: 8),
        Card(
          color: Colors.teal.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Row(
                  children: <Widget>[
                    Icon(Icons.accessibility_new, color: Colors.teal),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Aide intuitive — sélectionner la zone',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Touchez directement la zone du petit bonhomme pour la faire apparaître dans « Zone à travailler / intention ». Vous pouvez choisir une ou plusieurs zones, de face ou de dos.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 10),
                InteractiveBody(
                  selectedZones: _soinPenduleZones,
                  onZoneTap: _onSoinPenduleZoneTap,
                ),
                if (_soinPenduleZones.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: _soinPenduleZones
                        .map(
                          (zone) => Chip(
                            label: Text(zone),
                            onDeleted: () => _onSoinPenduleZoneTap(zone),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: steps.map((step) => CheckboxListTile(
              value: _soinPenduleEtapes[step.id],
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(step.title),
              subtitle: step.detail == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: SelectableText(step.detail!, style: const TextStyle(height: 1.4)),
                    ),
              onChanged: (value) => setState(
                () => _soinPenduleEtapes[step.id] = value ?? false,
              ),
            )).toList(),
          ),
        ),
        const SizedBox(height: 6),
        _compactText('Notes du soin au pendule', _soinPenduleNotes, minLines: 3),
        _checkStep(2 + (_scanPenduleNecessaire ? 1 : 0)),
      ],
    );
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
      _checkStep(2 + (_soinPenduleNecessaire ? 1 : 0) + (_scanPenduleNecessaire ? 1 : 0)),
    ]);
  }

  void _arreterLecture() {
    _timerConventions?.cancel();
    setState(() { _lectureAuto = false; _lectureSuspendue = true; });
  }

  int _dureeConvention() {
    if (_dureePersonnalisee > 0) return _dureePersonnalisee;
    if (_phaseSupplementaire) return 60;
    if (_conventionOuverte == 11 && _sangBelow70()) return 120;
    return 60;
  }

  void _demarrerLecture() {
    _timerConventions?.cancel();
    setState(() {
      _lectureAuto = true;
      if (!_lectureSuspendue) _secondesRestantes = _dureeConvention();
      _lectureSuspendue = false;
    });
    _timerConventions = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondesRestantes > 1) {
          _secondesRestantes--;
          return;
        }
        if (!_phaseSupplementaire) {
          _conventionsFaites.add(_conventionOuverte);
          if (_conventionOuverte < 13) {
            _conventionOuverte++;
            _secondesRestantes = _dureeConvention();
            return;
          }
          _phaseSupplementaire = true;
          _conventionSuppAuto = 0;
        } else {
          _conventionsSupplementairesFaites.add(_conventionSuppAuto);
          _conventionSuppAuto++;
        }
        final extra = _specificConventions(_ft);
        if (_phaseSupplementaire && _conventionSuppAuto >= extra.length) {
          timer.cancel();
          _lectureAuto = false;
        } else {
          _secondesRestantes = _dureeConvention();
        }
      });
    });
  }

  Widget _lectureAutomatique() {
    final extra = _specificConventions(_ft);
    final supplement = _phaseSupplementaire && extra.isNotEmpty;
    final titre = supplement
        ? extra[_conventionSuppAuto.clamp(0, extra.length - 1)]
        : _conventionTitles[_conventionOuverte];
    final consigne = supplement ? titre : _conventionAction(_conventionOuverte);
    final total = _dureeConvention();
    final progress = total == 0 ? 0.0 : (1 - _secondesRestantes / total).clamp(0.0, 1.0);
    final minutes = (_secondesRestantes ~/ 60).toString().padLeft(2, '0');
    final secondes = (_secondesRestantes % 60).toString().padLeft(2, '0');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(children: <Widget>[
              const Expanded(child: Text('SÉANCE GUIDÉE · CONVENTIONS',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
              if (_lectureAuto) const Chip(label: Text('En cours')),
            ]),
            const SizedBox(height: 12),
            Text(supplement
                ? 'Convention supplémentaire ${_conventionSuppAuto + 1} / ${extra.length}'
                : 'Convention ${_conventionOuverte + 1} / 14',
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(titre, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 20),
            Center(child: SizedBox(
              width: 230, height: 230,
              child: Stack(alignment: Alignment.center, children: <Widget>[
                SizedBox.expand(child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 12,
                  backgroundColor: Colors.black12,
                  strokeCap: StrokeCap.round,
                )),
                Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                  Text('$minutes:$secondes',
                      style: const TextStyle(fontSize: 46, fontWeight: FontWeight.bold)),
                  const Text('restantes'),
                ]),
              ]),
            )),
            const SizedBox(height: 20),
            Text(consigne, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17, height: 1.5)),
            const SizedBox(height: 14),
            const Text('Sans son ni vibration', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Wrap(spacing: 6, alignment: WrapAlignment.center, children: <Widget>[
              for (final seconds in [0, 60, 120, 180])
                ChoiceChip(
                  label: Text(seconds == 0 ? 'Conseillée' : '${seconds ~/ 60} min'),
                  selected: _dureePersonnalisee == seconds,
                  onSelected: _lectureAuto ? null : (_) => setState(() {
                    _dureePersonnalisee = seconds;
                    _secondesRestantes = _dureeConvention();
                    _lectureSuspendue = false;
                  }),
                ),
            ]),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _lectureAuto ? _arreterLecture : _demarrerLecture,
              icon: Icon(_lectureAuto ? Icons.pause : Icons.play_arrow),
              label: Text(_lectureAuto ? 'Pause' : (_lectureSuspendue ? 'Reprendre' : 'Démarrer')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _conventions() {
    final index = _conventionOuverte;
    final done = _conventionsFaites.contains(index);
    final action = _conventionAction(index);
    final fullDoc = _reference('14 conventions — version complète') ?? _reference('14 conventions');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _lectureAutomatique(),
        _helpBox(
          'Une convention à la fois. Pendant la séance, seules la durée utile et l’intention sont affichées. Les explications complètes restent dans la bibliothèque.',
          fullDoc,
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
              action,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
          ),
        ),
        if (index == 7 && _traitements.text.trim().isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Aucun traitement signalé au bilan : cette convention peut être sautée.',
              style: TextStyle(
                color: Colors.orange.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (fullDoc != null)
          OutlinedButton.icon(
            onPressed: () => _openReader(fullDoc),
            icon: const Icon(Icons.menu_book_outlined),
            label: const Text('Voir la convention complète'),
          ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Les 14 conventions', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...List<Widget>.generate(14, (i) {
                  final active = i == index;
                  final doneConvention = _conventionsFaites.contains(i);
                  return InkWell(
                    onTap: () => setState(() => _conventionOuverte = i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            doneConvention ? Icons.check_circle : active ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            size: 19,
                            color: doneConvention ? Colors.green : active ? Theme.of(context).colorScheme.primary : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${i + 1}. ${_conventionTitles[i]}',
                              style: TextStyle(fontWeight: active ? FontWeight.bold : FontWeight.normal),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
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
        if (_conventionsFaites.length == 14) _checkStep(_soinPenduleNecessaire ? 4 : 3),
      ],
    );
  }

  String _conventionAction(int index) {
    final durations = <String>[
      '1 minute ou plus si la personne est très tendue ou stressée.',
      '1 minute ou plus si la personne est soumise à de nombreuses douleurs ou se sent bloquée.',
      '1 minute. Jusqu’à 3 minutes si l’histoire de vie est compliquée ou en cas de troubles émotionnels ou de l’humeur importants.',
      '1 minute.',
      '1 minute.',
      '1 minute.',
      '1 minute.',
      _traitements.text.trim().isEmpty
          ? 'À sauter si la personne ne prend pas de traitement.'
          : '1 minute.',
      _convention9Duration(),
      '1 minute.',
      '1 minute.',
      _sangBelow70() ? '2 minutes car la qualité énergétique du sang est inférieure à 70 %.' : '1 minute.',
      '1 minute.',
      '1 à 3 minutes.',
    ];

    final intentions = <String>[
      'Vos mains sur le chakra couronne du consultant, envoyez l’intention « Je nettoie toutes les tensions », puis laissez passer l’énergie.',
      'Vos mains sur le chakra couronne du consultant, envoyez l’intention « Je nettoie tous les blocages énergétiques », puis laissez passer l’énergie.',
      'Vos mains sur le chakra couronne du consultant, envoyez l’intention « Je nettoie toutes les mauvaises mémoires de sa vie actuelle », puis laissez passer l’énergie.',
      'Vos mains sur le chakra couronne du consultant, envoyez l’intention « Je nettoie toutes les mauvaises mémoires de sa vie intra-utérine », puis laissez passer l’énergie.',
      'Vos mains sur le chakra couronne du consultant, envoyez l’intention « Je nettoie toutes les mauvaises mémoires transgénérationnelles », puis laissez passer l’énergie.',
      'Vos mains sur le chakra couronne du consultant, envoyez l’intention « Je nettoie toutes les mauvaises mémoires de ses vies antérieures », puis laissez passer l’énergie.',
      'Vos mains sur le chakra couronne du consultant, envoyez l’intention « Je nettoie l’impact des métaux lourds », puis laissez passer l’énergie.',
      'Vos mains sur le chakra couronne du consultant, envoyez l’intention « Je nettoie la chimie des médicaments que son corps peine à éliminer », puis laissez passer l’énergie.',
      'Vos mains sur le chakra couronne du consultant, envoyez l’intention « Je nettoie ses 7 corps », puis laissez passer l’énergie.',
      'Vos mains sur le chakra couronne du consultant, envoyez l’intention « Je nettoie et harmonise ses 7 chakras majeurs », puis laissez passer l’énergie.',
      'Vos mains sur le chakra couronne du consultant, envoyez l’intention « Je recharge tous ses organes », puis laissez passer l’énergie.',
      'Vos mains sur le chakra couronne du consultant, envoyez l’intention « Je nettoie toutes les toxines hydrosolubles et liposolubles », puis laissez passer l’énergie.',
      'Vos mains sur le chakra couronne du consultant, envoyez l’intention « Je guéris [nom et prénom] de [nom de la maladie] », puis laissez passer l’énergie.',
      'Vos mains sur le chakra couronne du consultant, envoyez l’intention « Je te transmets de l’énergie », puis laissez passer l’énergie sans intention supplémentaire.',
    ];

    if (index == 7 && _traitements.text.trim().isEmpty) {
      return durations[index];
    }
    final intention = intentions[index]
        .replaceAll('[nom et prénom]', _patient)
        .replaceAll('[nom et prenom]', _patient)
        .replaceAll('[prénom nom]', _patient)
        .replaceAll('[prenom nom]', _patient)
        .replaceAll('[nom prénom]', _nom.text.trim() + ' ' + _prenom.text.trim())
        .replaceAll('[nom prenom]', _nom.text.trim() + ' ' + _prenom.text.trim())
        .replaceAll('[nom de la maladie]', _ft?.titre ?? '');
    if (_mode == 'À distance') {
      return durations[index] + '\n\n' + intention.replaceAll('Vos mains sur le chakra couronne du consultant, ', 'Sur la photo ou la planche anatomique, ').replaceAll('laissez passer l’énergie', 'maintenez votre intention');
    }
    return durations[index] + '\n\n' + intention;
  }

  String _convention9Duration() {
    final negative = (_negatives.text + ' ' + _bilanNotes.text + ' ' + _entites.text).toLowerCase();
    if (negative.contains('magie noire') || negative.contains('magie-noire')) {
      return '4 minutes — magie noire détectée au bilan. Couper la connexion avant la séance selon le protocole.';
    }
    if (negative.contains('seuil de vigilance') ||
        negative.contains('vigilance des énergies négatives') ||
        negative.contains('vigilance énergie négative')) {
      return '2 minutes — seuil de vigilance des énergies négatives détecté au bilan.';
    }
    return '1 minute.';
  }

  bool _sangBelow70() {
    final value = double.tryParse(
      _sang.text.replaceAll('%', '').replaceAll(',', '.').trim(),
    );
    return value != null && value < 70;
  }

  List<String> _specificConventions(_Doc? doc) {
    if (doc == null) return const <String>[];
    final lines = doc.contenu.split('\n');
    final result = <String>[];
    var inSection = false;
    for (final raw in lines) {
      final line = raw.trim();
      final lower = line.toLowerCase();
      if (RegExp(r'^5\.').hasMatch(line) &&
          lower.contains('convention') &&
          lower.contains('suppl')) {
        inSection = true;
        continue;
      }
      if (inSection && RegExp(r'^6\.').hasMatch(line)) break;
      if (!inSection) continue;
      final match = RegExp(r'^-\s*(?:\d+\.\s*)?(.+)$').firstMatch(line);
      if (match != null && match.group(1)!.trim().isNotEmpty) {
        result.add(match.group(1)!.trim());
      }
    }
    return result;
  }

  String? _protocolSection(int number) {
    final doc = _ft;
    if (doc == null) return null;
    final lines = doc.contenu.split('\n');
    final result = <String>[];
    var active = false;
    for (final raw in lines) {
      final line = raw.trimRight();
      if (RegExp('^' + number.toString() + r'\.').hasMatch(line.trimLeft())) {
        active = true;
        result.add(line.trim());
        continue;
      }
      if (active && RegExp(r'^\d+(?:\s*&\s*\d+)?\.').hasMatch(line.trimLeft())) break;
      if (active && line.trim().isNotEmpty) result.add(line.trim());
    }
    return result.isEmpty ? null : result.join('\n');
  }

  Widget _specific() {
    final zones = _zonesSoin.toList()..sort();
    final conventions = _specificConventions(_ft);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (conventions.isEmpty)
          _helpBox(
            'Cette fiche ne prévoit pas de conventions supplémentaires distinctes. Passez à l’étape suivante après les 14 conventions de base.',
            _ft,
          )
        else ...<Widget>[
          Text(
            conventions.length.toString() + ' convention(s) spécifique(s) — ' + (_ft?.titre ?? ''),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 6),
          ...List<Widget>.generate(conventions.length, (i) => CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _conventionsSupplementairesFaites.contains(i),
            title: Text(conventions[i]),
            onChanged: (value) => setState(() {
              if (value ?? false) {
                _conventionsSupplementairesFaites.add(i);
              } else {
                _conventionsSupplementairesFaites.remove(i);
              }
            }),
          )),
        ],
        if (zones.isNotEmpty)
          Card(
            color: Colors.teal.withValues(alpha: 0.06),
            child: ListTile(
              leading: const Icon(Icons.accessibility_new, color: Colors.teal),
              title: const Text('Zone(s) de travail mémorisée(s)'),
              subtitle: Text(zones.join(', ')),
            ),
          ),
        _checkStep(4 + (_soinPenduleNecessaire ? 1 : 0) + (_scanPenduleNecessaire ? 1 : 0)),
      ],
    );
  }

  Widget _prieres() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _helpBox(
          'Les prières viennent directement de la bibliothèque. Pour chaque motif sélectionné, l’application recherche les formulations correspondantes et personnalise le nom du patient.',
          _prieresDoc,
        ),
        if (_pathologies.isEmpty)
          const Text('Sélectionne au moins une pathologie / motif.'),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: _utiliserRaphael,
          title: const Text('Ajouter la demande de guérison — Archange Raphaël'),
          subtitle: const Text('Complément facultatif pour une pathologie lourde, à utiliser pendant l’imposition sur le chakra couronne.'),
          onChanged: (value) => setState(() => _utiliserRaphael = value ?? false),
        ),
        if (_utiliserRaphael && _findPrayer('PRIÈRE DE DEMANDE DE GUÉRISON (Archange Raphaël)') != null)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SelectableText(
                MagnetismeLibraryService.personalized(
                  _findPrayer('PRIÈRE DE DEMANDE DE GUÉRISON (Archange Raphaël)')!,
                  prenom: _prenom.text,
                  nom: _nom.text,
                  pathologie: _ft?.titre,
                ),
                style: const TextStyle(fontSize: 14, height: 1.45),
              ),
            ),
          ),
        ..._pathologies.expand((pathology) {
          final prayers = _findPrayers(pathology);
          if (prayers.isEmpty) {
            return <Widget>[Card(child:ListTile(
              title:Text(pathology),
              subtitle:const Text('Aucune prière correspondante dans la bibliothèque.'),
            ))];
          }
          return prayers.map((prayer) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ExpansionTile(
              title: Text(prayer.titre),
              subtitle: Text('Pour $pathology — ouvrir'),
              children: <Widget>[
                if (prayer.description.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                    child: Text(prayer.description, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  child: SelectableText(
                    MagnetismeLibraryService.personalized(
                      prayer.contenu,
                      prenom: _prenom.text,
                      nom: _nom.text,
                      pathologie: pathology,
                    ),
                    style: const TextStyle(fontSize: 14, height: 1.45),
                  ),
                ),
              ],
            ),
          ));
        }),
        _checkStep(5 + (_soinPenduleNecessaire ? 1 : 0) + (_scanPenduleNecessaire ? 1 : 0)),
      ],
    );
  }

  List<_Doc> _findPrayers(String pathology) {
    final q = pathology.trim().toLowerCase();
    return _docs.where((doc) {
      if (doc.type != 'priere') return false;
      final aliases = doc.aliases.map((x) => x.toLowerCase());
      return doc.titre.toLowerCase().contains(q) ||
          q.contains(doc.titre.toLowerCase()) ||
          aliases.any((a) => q.contains(a) || a.contains(q));
    }).toList();
  }

  Widget _aideMemoire(String titre, String contenu) {
    return Card(
      color: Colors.indigo.withValues(alpha: 0.05),
      child: ExpansionTile(
        leading: const Icon(Icons.menu_book_outlined, color: Colors.indigo),
        title: Text('Aide-mémoire : $titre'),
        subtitle: const Text('Appuyer pour afficher la méthode'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SelectableText(contenu, style: const TextStyle(height: 1.5)),
          ),
        ],
      ),
    );
  }

  static const _memoBalayage =
      'Selon le manuel : placez les mains à 10 à 15 cm au-dessus du corps. '
      'Effectuez des passages lents, pendant environ 30 secondes à 1 minute.\n\n'
      '1. Passage à deux mains sur le bras gauche.\n'
      '2. Passage à deux mains sur le tronc côté gauche et centre.\n'
      '3. Passage à deux mains sur le tronc côté droit et centre.\n'
      '4. Passage à deux mains sur le bras droit.\n'
      '5. Passage à deux mains sur la jambe gauche.\n'
      '6. Passage à deux mains sur la jambe droite.\n'
      '7. Recommencez cette série une deuxième fois pour terminer la séance.';

  static const _memoChakras =
      'Méthode de lecture au pendule décrite dans ton livre :\n\n'
      '1. Lancez une oscillation dans l’axe tête-pieds du patient.\n'
      '2. Si le mouvement reste dans cet axe : chakra équilibré.\n'
      '3. S’il dévie vers la droite du patient : déficience.\n'
      '4. S’il dévie vers la gauche du patient : excès.\n\n'
      'Les directions sont celles du patient, et non de l’observateur. '
      'Cette lecture relève de la pratique radiesthésique, pas d’une mesure médicale.';

  Widget _technique(int index) {
    final titreEtape = _etapes[index];
    final distance = _mode == 'À distance';
    final technique = _protocolSection(7);
    final zones = _zonesSoin.toList()..sort();

    if (distance) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        const Text(
          'Travail à distance',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 6),
        const Text('Travaillez sur photo / planches anatomiques en suivant les indications de la fiche technique.'),
        if (zones.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Text('Zone(s) : ' + zones.join(', '), style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
        const SizedBox(height: 10),
        const Text('Suivre les intentions et les formulations prévues par la fiche sur la photo ou les planches. Les passes rapides, passes lentes et impositions physiques ne sont pas réalisées à distance.'),
        _checkStep(index),
      ]);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      if (titreEtape == 'Balayage') _aideMemoire('Le balayage', _memoBalayage),
      if (titreEtape == 'Circulation énergétique entre les chakras') _aideMemoire('Contrôle des chakras', _memoChakras),
      if (technique != null) ...<Widget>[
        Text(
          'Technique prévue pour ' + (_ft?.titre ?? 'le soin'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        SelectableText(technique, style: const TextStyle(fontSize: 14, height: 1.5)),
      ] else
        const Text('Aucune technique spécifique n’est décrite à cette étape dans la fiche.'),
      if (zones.isNotEmpty) ...<Widget>[
        const SizedBox(height: 10),
        Card(
          color: Colors.teal.withValues(alpha: 0.06),
          child: ListTile(
            leading: const Icon(Icons.accessibility_new, color: Colors.teal),
            title: const Text('Zone(s) à traiter'),
            subtitle: Text(zones.join(', ')),
          ),
        ),
      ],
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
            if (index < _etapes.length - 1) {
              _etapeOuverte = index + 1;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                final next = _stepKeys[index + 1]?.currentContext;
                if (next != null) {
                  Scrollable.ensureVisible(next,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    alignment: 0.02,
                  );
                }
              });
            }
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
  final String description;
  final List<String> aliases;

  const _Doc({
    required this.id,
    required this.titre,
    required this.source,
    required this.type,
    required this.contenu,
    this.description = '',
    this.aliases = const <String>[],
  });

  factory _Doc.fromJson(Map<String, dynamic> json) {
    return _Doc(
      id: (json['id'] ?? '').toString(),
      titre: (json['titre'] ?? '').toString(),
      source: (json['source'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      contenu: (json['contenu'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      aliases: (json['aliases'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[],
    );
  }
}
