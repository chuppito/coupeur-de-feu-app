import '../widgets/energy_ending_guidance.dart';
import 'dart:async';
import 'dart:convert';
import '../session/session_plan.dart';
import '../session/convention_timing.dart';
import '../widgets/protocol_timer.dart';
import '../widgets/trainer_advice.dart';
import '../session/guidance_text.dart';
import '../data/protocoles_pdf_45.dart';
import '../data/suivis_formation.dart';

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
  final bool demarrerSuivi;
  final Future<List<Map<String,dynamic>>> Function()? loadLibrary;

  const MagnetismeSessionScreen({
    super.key,
    this.prefillNom,
    this.prefillNomFamille,
    this.demarrerSuivi = false,
    this.loadLibrary,
  });

  @override
  State<MagnetismeSessionScreen> createState() => _MagnetismeSessionScreenState();
}

class _MagnetismeSessionScreenState extends State<MagnetismeSessionScreen> with WidgetsBindingObserver {
  void _updateScreenAwake(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WakelockPlus.enable();
    } else {
      if (_lectureAuto && mounted) _arreterLecture();
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
  final _evenementsCM3 = TextEditingController();
  final _degagementNotes = TextEditingController();
  final _soinPenduleZone = TextEditingController();
  final _soinPenduleNotes = TextEditingController();
  final Set<String> _zonesSoin = <String>{};
  final Map<String, Set<String>> _zonesParPathologie = <String, Set<String>>{};
  String? _pathologieZoneActive;

  Set<String> _zonesPour(String titre) => _zonesParPathologie.putIfAbsent(titre, () => <String>{});

  void _onZonePathologieTap(String titre, String zone) {
    setState(() {
      final zones = _zonesPour(titre);
      if (!zones.add(zone)) zones.remove(zone);
      final ficheId=_selectedFts.where((f)=>f.titre==titre).firstOrNull?.id;
      if(ficheId!=null)_thotClassique.removeWhere((key,value)=>key.startsWith('thot:$ficheId:'));
      _zonesSoin.clear();
      for (final values in _zonesParPathologie.values) { _zonesSoin.addAll(values); }
    });
  }

  bool _utiliserRaphael = false;
  bool _zonesSuiviConfirmees = false;
  bool _radioConnexionConfirmee = false;
  final Map<String,int> _tempsLocaux = {};
  final Set<String> _conditionsConfirmees = {};
  final Set<String> _etapesNonApplicables = {};
  bool _cm9Vigilance = false;
  bool _chirurgieSuiviConfirmee = false;

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
  final Map<String, String> _typesSuivi = <String, String>{};
  Map<String, dynamic>? _seancePrecedente;
  List<_Doc> _docs = <_Doc>[];
  String? _ftId;
  String _mode = 'Présentiel';
  int _etapeOuverte = 0;
  int _conventionOuverte = 0;
  Timer? _timerConventions;
  Timer? _timerConventionsSpecifiques;
  int _indexConventionSpecifique = 0;
  int _secondesConventionSpecifique = 0;
  bool _lectureConventionsSpecifiques = false;
  bool _pauseConventionsSpecifiques = false;
  int _secondesRestantes = 60;
  bool _lectureAuto = false;
  bool _lectureSuspendue = false;
  bool _scanDetailVisible = false;
  int _dureePersonnalisee = 0;
  bool _loading = true;
  bool _saving = false;
  bool _degagementNecessaire = false;
  bool _soinPenduleNecessaire = false;
  bool _scanPenduleNecessaire = false;
  String _priereFeu = 'Prière contre le feu indisponible dans la bibliothèque.';
  final Map<String,List<bool>> _thotClassique = {};

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
    _timerConventionsSpecifiques?.cancel();
    _timerIntentionsPlanifiees?.cancel();
    for (final controller in <TextEditingController>[
      _prenom, _nom, _observations, _debriefController, _vitalite, _vibratoire,
      _entites, _negatives, _sang, _bilanNotes,
      _traitements, _evenementsCM3, _degagementNotes, _soinPenduleZone, _soinPenduleNotes,
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
      final fiches = await (widget.loadLibrary?.call() ?? MagnetismeLibraryService.loadAll());
      final docs = fiches.map((item) => _Doc.fromJson(item)).toList();

      if (!mounted) return;
      setState(() {
        _docs = docs;
        if (widget.demarrerSuivi) {
          final anciennes = MagnetismeSessionService.getForPatient(_patient);
          if (anciennes.isNotEmpty) {
            _seancePrecedente = anciennes.first;
            final titres = anciennes.first['ftTitres'];
            final candidats = titres is List ? titres.map((v) => v.toString()).toList() : <String>[(anciennes.first['ftTitre'] ?? '').toString()];
            for (final titre in candidats.take(3)) {
              final matches = docs.where((d) => d.titre == titre && d.type == 'fiche_technique');
              if (matches.isNotEmpty) {
                _pathologies.add(titre);
                _typesSuivi[titre] = SuivisFormation.typePour(titre);
                _ftId ??= matches.first.id;
              }
            }
            final anciennesZones = anciennes.first['zonesParPathologie'];
            if (anciennesZones is Map) {
              for (final entry in anciennesZones.entries) {
                if (_pathologies.contains(entry.key) && entry.value is List) {
                  _zonesParPathologie[entry.key.toString()] = (entry.value as List).map((e) => e.toString()).toSet();
                }
              }
              for (final zones in _zonesParPathologie.values) { _zonesSoin.addAll(zones); }
            }
            _pathologieZoneActive = _pathologies.isEmpty ? null : _pathologies.first;
          }
        }
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
        .replaceAll('\\u000c', '\n\n')
        .replaceAll('\\u0000', '')
        .replaceAll(RegExp(r'[ \\t]+'), ' ')
        .replaceAll(RegExp(r'\\n[ \\t]+'), '\n')
        .replaceAll(RegExp(r'\\n{3,}'), '\n\n')
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

  List<_Doc> get _choixSoin => [
    ..._fts,
    ..._docs.where((doc) => doc.type == 'protocole' &&
      (doc.id == 'ft-couper-le-feu' || doc.id == 'ft-coup-de-soleil')),
  ];

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

  List<_Doc> get _selectedFts {
    // L'ordre de sélection est la priorité : 1, 2 puis 3.
    final selected = <_Doc>[];
    for (final titre in _pathologies) {
      final matches = _fts.where((doc) => doc.titre == titre);
      if (matches.isNotEmpty) selected.add(matches.first);
    }
    if (_pathologies.isEmpty && _ft != null && _ft!.type == 'fiche_technique' && !selected.any((doc) => doc.id == _ft!.id)) {
      selected.insert(0, _ft!);
    }
    return selected;
  }

  bool _anyFtMatches(String pattern) => _selectedFts.any(
    (doc) => RegExp(pattern, caseSensitive: false).hasMatch(doc.contenu),
  );

  List<String> get _allSpecificConventions {
    final result = <String>[];
    final seen = <String>{};
    for (final doc in _selectedFts) {
      for (final item in _specificConventions(doc)) {
        if (seen.add(item.toLowerCase().trim())) {
          result.add('${doc.titre} — $item');
        }
      }
    }
    return result;
  }

  bool get _ftHasFirePrayer => _anyFtMatches(r'prière contre le feu|priere contre le feu|signe de croix');

  bool get _ftHasPasses => _anyFtMatches(r'passes rapides|passes lentes|imposition|apposition');

  bool get _ftHasCirculation => _anyFtMatches(r'circulation énergétique entre les chakras');

  bool get _ftHasBalayage => _anyFtMatches(r'balayage');


  // V3.2 : séquencer les gestes de chaque fiche plutôt que les fusionner.
  List<String> _gestes(_Doc doc) {
    final section = _protocolSectionFor(doc, 7);
    if (section == null) return <String>[];
    return section.split('\n').where((line) =>
      RegExp(r'passe|imposition|apposition|visualis|chakra|circulation|intention',
        caseSensitive: false).hasMatch(line)).toList();
  }

  List<String> get _gestesFiches {
    final result = <String>[];
    for (final doc in _selectedFts) {
      for (var i = 0; i < _gestes(doc).length; i++) {
        result.add('Geste fiche : ' + doc.id + ' : ' + i.toString() + ' · ' + _gestes(doc)[i].trim());
      }
    }
    return result;
  }

  Widget _gesteFiche(int index) {
    final parts = _etapes[index].split(' : ');
    if (parts.length != 3) return _technique(index);
    final docs = _selectedFts.where((d) => d.id == parts[1]).toList();
    if (docs.isEmpty) return _technique(index);
    final gestures = _gestes(docs.first);
    final n = int.tryParse(parts[2].split(' · ').first) ?? -1;
    if (n < 0 || n >= gestures.length) return _technique(index);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Text(docs.first.titre, style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      SelectableText(gestures[n], style: const TextStyle(fontSize: 17, height: 1.4)),
      if (_zonesSoin.isNotEmpty)
        Text('Zone(s) : ' + (_zonesSoin.toList()..sort()).join(', ')),
      _checkStep(index),
    ]);
  }


  // Les 45 fiches sont indexées sur le PDF de formation, sans créer de fiches.
  static final Map<String, dynamic> _protocolesPdf =
      jsonDecode(protocolesPdf45Json) as Map<String, dynamic>;

  String _normaliserTitre(String value) {
    var s = value.toLowerCase().trim();
    const accents = <String, String>{
      'à':'a', 'â':'a', 'ä':'a', 'é':'e', 'è':'e', 'ê':'e',
      'ë':'e', 'î':'i', 'ï':'i', 'ô':'o', 'ö':'o',
      'ù':'u', 'û':'u', 'ü':'u', 'ç':'c', 'œ':'oe',
    };
    accents.forEach((a, b) => s = s.replaceAll(a, b));
    return s.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  Map<String, dynamic>? _protocolePdfPour(_Doc doc) {
    final title = _normaliserTitre(doc.titre);
    const aliases = <String, String>{
      'tabacarretdu': 'Arrêt du tabac',
      'traitementslourdsaideaux': 'Traitements lourds',
      'interventionchirurgicale5joursavant': 'Intervention chirurgicale avant',
      'interventionchirurgicaleapreslintervention': 'Intervention chirurgicale après',
      'troublesdusommeil': 'Trouble du sommeil',
      'maladiedecrohn': 'Crohn',
      'maladiedelyme': 'Lyme',
      'maladiedeverneuil': 'Verneuil',
      'spondylarthriteankylosante': 'Spondylarthrite',
    };
    final canonical = _normaliserTitre(aliases[title] ?? doc.titre);
    // Correspondance exacte prioritaire : évite Arthrite dans Spondylarthrite.
    final exact = _protocolesPdf.entries
        .where((entry) => _normaliserTitre(entry.key) == canonical).toList();
    final matches = exact.isNotEmpty ? exact : _protocolesPdf.entries.where((entry) {
      final key = _normaliserTitre(entry.key);
      return key.length >= 6 && canonical.startsWith(key);
    }).toList();
    return matches.length == 1
        ? Map<String, dynamic>.from(matches.single.value as Map)
        : null;
  }

  // Séance fusionnée : la première fiche sélectionnée est prioritaire.
  // Chaque famille de gestes suit l'ordre de la fiche prioritaire.
  // Le guide suit les étapes textuelles originales de la fiche V3,
  // sans inférer de gestes à partir d'un simple mot-clé du PDF.
  // Découpe les travaux mixtes : une seule fiche peut contenir passes
  // rapides, lentes, imposition et visualisation dans un même paragraphe.
  List<String> _trajetsZones(Iterable<String> zones) {
    final selectedZones = zones.toSet().toList()..sort();
      final routes = <String>[];
      for (final zone in selectedZones) {
        final z = zone.toLowerCase().trim();
        final side = z.contains('gauche') ? 'gauche' : z.contains('droit') ? 'droit' : null;
        if (side == null) continue;
        final handSide = side == 'droit' ? 'droite' : 'gauche';
        if (z.contains('cuisse')) {
          routes.add('Cuisse $handSide : chakra mineur aine $handSide → chakra mineur genou $side');
        } else if (z.contains('poignet')) {
          routes.add('Poignet $side : chakra mineur coude $side → chakra mineur main $handSide');
        } else if (z.contains('cheville')) {
          routes.add('Cheville $handSide : chakra mineur genou $side → chakra mineur pied $side');
        } else if (z.contains('coude')) {
          routes.add('Coude $side : épaule $handSide → coude $side, puis coude $side → main $handSide');
        } else if (z.contains('genou')) {
          routes.add('Genou $side : aine $handSide → genou $side, puis genou $side → pied $side');
        } else if (z.contains('épaule') || z.contains('epaule')) {
          routes.add('Épaule $handSide : couronne → épaule $handSide, puis épaule $handSide → main $handSide');
        }
      }
    return routes;
  }

  List<String> _gestesDeFiche(String texte, String phase) {
    final lignes = texte.split(RegExp(r'\n|\s+/\s+'));
    final fragments = <String>[];
    for (final ligne in lignes) {
      final morceaux = ligne.split(RegExp(r'(?=\s*-\s*[1-9]\.\s*)'));
      for (final morceau in morceaux) {
        final m = morceau.trim();
        if (m.isEmpty) continue;
        final rapide = RegExp(r'passes? rapides?', caseSensitive: false).hasMatch(m);
        final lente = RegExp(r'passes? lentes?', caseSensitive: false).hasMatch(m);
        final autre = RegExp(r'imposition|imposez|visualisation|visualisez', caseSensitive: false).hasMatch(m);
        if ((phase == 'rapide' && rapide) ||
            (phase == 'lente' && lente) ||
            (phase == 'specifique' && autre && !rapide && !lente)) {
          fragments.add(m);
        }
      }
    }
    return fragments;
  }

  SessionPlan get _planV33 => SessionPlanner.build(
    _selectedFts.map((d) => GuideFiche.fromJson(d.raw)).toList(),
    distance: _mode == 'À distance', scan: _scanPenduleNecessaire,
    thot: _soinPenduleNecessaire,
    visits: {for (final d in _selectedFts) d.id: _typesSuivi[d.titre] ?? 'complet'},
    zones: _zonesParPathologie,
    radioConnectionConfirmed:_radioConnexionConfirmee,
  );

  bool get _usesPlanV33 => _selectedFts.isNotEmpty &&
      _selectedFts.any((d) => (d.raw['guideV33'] as List? ?? []).isNotEmpty);

  List<String> get _parcoursFichesStructurees => !_usesPlanV33 ? [] :
      _planV33.steps.map((step) => 'V33 · ${step.id}').toList();

  PlanStep _plannedStep(String title) => _planV33.steps.firstWhere((s) => 'V33 · ${s.id}' == title);

  Widget _plannedContent(int index) {
    final step = _plannedStep(_etapes[index]);
    switch(step.kind) {
      case 'contact': return _contactHelp();
      case 'bilan': return _bilan();
      case 'scan': return _scanPenduleStep();
      case 'degagement': return _degagement();
      case 'communes': return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(GuidanceText.commonCues(step.text),style:const TextStyle(fontWeight:FontWeight.w600)),
        const SizedBox(height:12),_conventions(),
      ]);
      case 'thot': return _soinPenduleStep(step:step);
      case 'support': return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('Support : ${step.target=='selection'?step.zones.join(', '):step.target}'),
        SelectableText(_find('planches_anatomiques_distance')?.contenu ?? 'Préparer la planche anatomique correspondant à la zone mémorisée, reliée au témoin.'),
        _checkStep(index),
      ]);
      case 'debrief': return _debrief();
      case 'temoin':
        final doc = _find('temoin_distance');
        final source = doc ?? _docs.where((d) => d.titre.startsWith('CHOISIR, CRÉER')).firstOrNull;
        return Column(crossAxisAlignment: CrossAxisAlignment.start,children:[
          SelectableText(source?.contenu ?? 'Préparer et vitaliser le témoin selon la fiche de la bibliothèque.'),
          _checkStep(index),
        ]);
      case 'circulation': return EnergyEndingGuidance(
        circulation: true,
        instructions: SelectableText(_find('circulation-energetique-entre-les-chakras')?.contenu ?? _memoCirculation),
        validation: _checkStep(index),
      );
      case 'balayage': return EnergyEndingGuidance(
        circulation: false,
        instructions: const Text(_memoBalayage),
        validation: _checkStep(index),
      );
    }
    final newSupport = _planV33.needsSupportPreparation(step);
    var text = GuidanceText.clean(step.text,kind:step.kind);
    text = text.replaceAll(RegExp(r'Prière contre le feu \(voir la fiche « CONTRE LE FEU »\)',caseSensitive:false),_priereFeu);
    text = MagnetismeLibraryService.personalized(text,prenom:_prenom.text,nom:_nom.text);
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      if(step.zones.isNotEmpty && const {'rapide','lente','imposition','visualisation','flux','distance'}.contains(step.kind))
        Text('À travailler : ${step.zones.join(', ')}',style:const TextStyle(fontWeight:FontWeight.bold))
      else if(step.target != 'selection' && step.target.isNotEmpty)
        Text('Zone : ${step.target}',style:const TextStyle(fontWeight:FontWeight.bold))
      else if(step.zones.isNotEmpty)
        Text('Zone(s) : ${step.zones.join(', ')}',style:const TextStyle(fontWeight:FontWeight.bold)),
      if(step.kind=='rapide' && step.route.isNotEmpty && !step.route.toLowerCase().contains('chakra entrant') && !step.route.toLowerCase().contains('chakra sortant'))
        Text('Départ → arrivée : ${step.route}',style:const TextStyle(fontWeight:FontWeight.bold)),
      if(step.kind=='rapide' && (step.route.toLowerCase().contains('chakra entrant') || step.route.toLowerCase().contains('chakra sortant'))) ...[
        if(GuidanceText.anatomicalRoutes(step.zones).isNotEmpty)
          ...GuidanceText.anatomicalRoutes(step.zones).map((route)=>Text(route,style:const TextStyle(fontWeight:FontWeight.bold)))
        else
          const Text('Trajet non précisé pour cette zone dans le tableau de référence.',style:TextStyle(fontWeight:FontWeight.bold)),
      ],
      if(step.condition.isNotEmpty) Text('Condition : ${step.condition}',style:const TextStyle(fontWeight:FontWeight.bold)),
      if(step.condition.isNotEmpty) CheckboxListTile(
        title:const Text('Condition remplie pour ce travail'),
        value:_conditionsConfirmees.contains(step.id),
        onChanged:(v)=>setState((){if(v==true){_conditionsConfirmees.add(step.id);_etapesNonApplicables.remove(step.id);}else{_conditionsConfirmees.remove(step.id);}})),
      if(_mode == 'À distance' && step.kind == 'priere') const Padding(padding:EdgeInsets.only(bottom:8),child:Text('À distance : effectuer les signes et réciter la prière sur la photographie, sans geste sur le patient.')),
      if(step.kind == 'distance') ...[
        const Text('Travail sur support, sans passes ni imposition physique sur le patient.'),
        const SizedBox(height:8),
        if(newSupport) SelectableText(_find('planches_anatomiques_distance')?.contenu ?? 'Consulter la technique sur planche anatomique dans la bibliothèque.')
        else const Text('Conserver le même support et la même zone pour l’intention complémentaire ci-dessous ; ne pas recommencer toute la préparation.'),
        const Divider(),
      ],
      if(step.kind=='flux') ...[
        ...((step.selectedRoute && GuidanceText.selectedRoutes(step.zones).isNotEmpty)
          ? GuidanceText.selectedRoutes(step.zones)
          : GuidanceText.fixedRoutes(step.route,step.zones,sideAware:step.sideAware)).where((s)=>s.isNotEmpty).map((r)=>Text(r,style:const TextStyle(fontWeight:FontWeight.bold))),
        const SizedBox(height:8),const Text(GuidanceText.blockedFlux),
      ] else ...[
        if(step.selectedRoute && _mode=='Présentiel' && step.kind=='rapide')
          ...GuidanceText.selectedRoutes(step.zones).map((r)=>Text(r,style:const TextStyle(fontWeight:FontWeight.bold))),
        if(!(step.kind=='rapide' && (step.route.toLowerCase().contains('chakra entrant') || step.route.toLowerCase().contains('chakra sortant')) && GuidanceText.anatomicalRoutes(step.zones).isNotEmpty))
          SelectableText(text,style:const TextStyle(fontSize:16,height:1.4)),
      ],
      if(step.ficheId.isNotEmpty) TrainerAdvice(items:_find(step.ficheId)?.raw['conseilsFormateur'] as List? ?? const []),
      if(step.seconds!=null) ProtocolTimer(key:ValueKey(step.id),seconds:step.seconds!,
        initialRemaining:_tempsLocaux[step.id],onChanged:(value)=>_tempsLocaux[step.id]=value),
      if(step.kind=='personnel') const Text('Contenu historique conservé. Protocole complet non vérifié dans les sources de formation ; adaptation distance et fusion non certifiées.'),
      if(step.kind=='intentions') ...[
        const SizedBox(height:12),
        if ((_lectureIntentionsPlanifiees || _pauseIntentionsPlanifiees) &&
            _indicesIntentionsPlanifiees.isNotEmpty &&
            _indicesIntentionsPlanifiees[_indexIntentionPlanifiee] == index) ...[
          Text('Intention ${_positionIntentionPlanifiee + 1} / ${_intentionsDeLEtape(index).length}',style:const TextStyle(fontWeight:FontWeight.bold)),
          SelectableText(_intentionsDeLEtape(index)[_positionIntentionPlanifiee]),
          Text('Temps restant : ${(_restantIntentionPlanifiee ~/ 60).toString().padLeft(2,'0')}:${(_restantIntentionPlanifiee % 60).toString().padLeft(2,'0')}'),
        ],
        FilledButton.icon(
          onPressed:_lectureIntentionsPlanifiees ? _pauseIntentionsPlanifieesLecture : _demarrerIntentionsPlanifiees,
          icon:Icon(_lectureIntentionsPlanifiees ? Icons.pause : Icons.play_arrow),
          label:Text(_lectureIntentionsPlanifiees ? 'Pause' : (_pauseIntentionsPlanifiees ? 'Reprendre' : 'Démarrer les conventions supplémentaires')),
        ),
        const Text('Enchaînement automatique sans son ni vibration. Durée réglable dans les conventions de base.'),
      ],
      if(step.source.isNotEmpty) ExpansionTile(title:const Text('Source'),children:[SelectableText(step.source)]),
      if(step.condition.isEmpty || _conditionsConfirmees.contains(step.id)) _checkStep(index),
      if(step.condition.isNotEmpty && !_conditionsConfirmees.contains(step.id)) TextButton(
        onPressed:()=>setState((){
          _etapesNonApplicables.add(step.id);
          if(index<_etapes.length-1)_etapeOuverte=index+1;
          WidgetsBinding.instance.addPostFrameCallback((_){
            if(!mounted)return;
            final target=_stepKeys[index+1]?.currentContext;
            if(target!=null){Scrollable.ensureVisible(target,duration:const Duration(milliseconds:350),alignment:0.02);}
          });
        }),child:const Text('Condition non remplie : passer ce travail')),
    ]);
  }

  int get _currentStepIndex => _etapeOuverte.clamp(0,_etapes.length-1);

  Widget _etapeFluxParMotif(int index) {
    final d = int.tryParse(_etapes[index].split(' · ').last) ?? 0;
    final doc = _selectedFts[d];
    final trajets = _trajetsZones(_zonesParPathologie[doc.titre] ?? <String>{});
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Text(doc.titre, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      if (trajets.isEmpty)
        const Text('Aucun trajet articulaire identifié : vérifier la zone et la fiche.')
      else
        ...trajets.map((t) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(t, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        )),
      _checkStep(index),
    ]);
  }

  Widget _etapeGeste(int index) {
    final parts = _etapes[index].split(' · ');
    final phase = parts[1];
    final d = int.parse(parts[2]);
    final j = int.parse(parts[3]);
    final doc = _selectedFts[d];
    final texte = doc.etapesGuideSource[j]['texte'] ?? '';
    final gestes = _gestesDeFiche(texte, phase);
    final zones = _zonesParPathologie[doc.titre] ?? <String>{};
    final trajets = _trajetsZones(zones);
    final trajetSelonZone = phase == 'rapide' &&
        !RegExp(r'chakra\s+plexus|chakra\s+racine', caseSensitive: false).hasMatch(texte);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Text(doc.titre, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      if (trajetSelonZone && trajets.isNotEmpty)
        ...trajets.map((trajet) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(trajet, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        )),
      ...gestes.map((geste) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SelectableText(geste, style: const TextStyle(fontSize: 16, height: 1.4)),
      )),
      if (zones.isNotEmpty)
        Text('Zone(s) : ' + (zones.toList()..sort()).join(', ')),
      _checkStep(index),
    ]);
  }

  Widget _etapeFicheSource(int index) {
    final parts = _etapes[index].split(' · ');
    final docIndex = int.tryParse(parts[1]) ?? 0;
    final stepIndex = int.tryParse(parts[2]) ?? 0;
    final doc = _selectedFts[docIndex];
    final step = doc.etapesGuideSource[stepIndex];
    final texte = step['texte'] ?? '';
    final type = step['type'] ?? '';
    final gestePhysique = type == 'travail' || type == 'imposition';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Text(doc.titre, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      if (_mode == 'À distance' && gestePhysique)
        const Text('À distance : ne pas effectuer de gestes physiques.'),
      SelectableText(texte, style: const TextStyle(fontSize: 16, height: 1.4)),
      if (_zonesSoin.isNotEmpty)
        Text('Zone(s) sélectionnée(s) : ' + (_zonesSoin.toList()..sort()).join(', ')),
      _checkStep(index),
    ]);
  }

  List<String> get _parcoursPdfUnique {
    final docs = _selectedFts;
    if (docs.isEmpty || docs.length > 3) return <String>[];
    final fiches = docs.map(_protocolePdfPour).toList();
    if (fiches.any((fiche) => fiche == null)) return <String>[];
    final primary = List<String>.from(fiches.first!['order'] as List);
    final orderedStages = <String>[];
    for (final stage in primary) {
      if (!orderedStages.contains(stage)) orderedStages.add(stage);
    }
    for (final fiche in fiches.skip(1)) {
      for (final stage in List<String>.from(fiche!['order'] as List)) {
        if (!orderedStages.contains(stage)) orderedStages.add(stage);
      }
    }
    final stages = <String>[];
    for (final stage in orderedStages) {
      if (stage == 'c') {
        stages.add('14 conventions mentales');
        continue;
      }
      // Les intentions, prières et gestes sont regroupés par type,
      // puis par priorité, sans répéter l'accueil ni le balayage.
      if (stage == 't' && _mode == 'Présentiel') {
        // Tous les passages rapides, puis flux, pendule facultatif,
        // puis tous les passages lents : priorité conservée dans chaque bloc.
        for (final phase in <String>['r', 'l']) {
          if (phase == 'l') {
            stages.add('Contrôle des flux');
            if (_soinPenduleNecessaire) {
              stages.add('Pendule de Thot');
            }
          }
          for (var docIndex = 0; docIndex < docs.length; docIndex++) {
            final order = List<String>.from(fiches[docIndex]!['order'] as List);
            final count = order.where((item) => item == 't').length;
            for (var n = 1; n <= count; n++) {
              stages.add('PDF45 · $docIndex · $phase · $n');
            }
          }
        }
        continue;
      }
      for (var docIndex = 0; docIndex < docs.length; docIndex++) {
        final order = List<String>.from(fiches[docIndex]!['order'] as List);
        final count = order.where((item) => item == stage).length;
        for (var n = 1; n <= count; n++) {
          stages.add('PDF45 · $docIndex · $stage · $n');
        }
      }
    }
    return <String>[
      'Prise de contact',
      'Bilan énergétique',
      if (_scanPenduleNecessaire) 'Scan au pendule',
      'Dégagement des entités / énergies négatives si nécessaire',
      ...stages,
      if (_mode == 'Présentiel' && _ftHasCirculation)
        'Circulation énergétique entre les chakras',
      if (_mode == 'Présentiel' && _ftHasBalayage) 'Balayage',
      'Débriefing / observation',
    ];
  }

  List<String> _sectionsNumerotees(_Doc doc) {
    final text = doc.contenu;
    final starts = RegExp(r'(?m)^\s*(?:[1-9]|10)\.\s+(?=[A-ZÀÂÉÈÊÎÔÙÇ])')
        .allMatches(text).toList();
    if (starts.isEmpty) return <String>[];
    final sections = <String>[];
    for (var i = 0; i < starts.length; i++) {
      final end = i + 1 < starts.length ? starts[i + 1].start : text.length;
      sections.add(text.substring(starts[i].start, end).trim());
    }
    return sections;
  }

  String? _instructionFichePour(_Doc doc, String stage, int occurrence) {
    final sections = _sectionsNumerotees(doc);
    final pattern = stage == 't'
        ? RegExp(r'travaillez? en passe|travail en passe|passes rapides', caseSensitive: false)
        : stage == 'i'
            ? RegExp(r'imposez vos mains|imposition des mains|imposez les mains', caseSensitive: false)
            : stage == 'p'
                ? RegExp(r'prière|récitez|signe de croix', caseSensitive: false)
                : RegExp(r'conventions? mentales? supplémentaires?', caseSensitive: false);
    final candidates = sections.where((section) =>
        pattern.hasMatch(section.split('\n').first)).toList();
    return occurrence >= 1 && occurrence <= candidates.length
        ? candidates[occurrence - 1] : null;
  }

  Widget _etapePdf(int index) {
    final parts = _etapes[index].split(' · ');
    final docIndex = int.tryParse(parts[1]) ?? 0;
    final stage = parts[2];
    final doc = _selectedFts[docIndex];
    final fiche = _protocolePdfPour(doc)!;
    final source = fiche['source'] as String;
    if (stage == 'c') return _conventions();
    if (_normaliserTitre(doc.titre) == 'eczema' && stage == 'i') {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        const Text('Imposition des mains sur l’eczéma',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        const SizedBox(height: 8),
        const Text('Visualiser l’eczéma qui sèche — 5 minutes.'),
        if (_zonesSoin.isNotEmpty)
          Text('Zone(s) sélectionnée(s) : ' + (_zonesSoin.toList()..sort()).join(', ')),
        _checkStep(index),
      ]);
    }
    if (_normaliserTitre(doc.titre) == 'eczema' && stage == 't') {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        const Text('Travail en passe sur le ventre',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        const SizedBox(height: 8),
        const Text('1. Passes rapides : chakra plexus solaire → chakra racine.'),
        const Text('2. Passes lentes sur le système intestinal.'),
        const Text('3. Imposition des mains sur les intestins, avec l’intention décrite dans la fiche.'),
        _checkStep(index),
      ]);
    }
    if (stage == 's' || stage == 'p') {
      final occurrence = int.tryParse(parts.last) ?? 1;
      final instruction = stage == 's'
          ? (_specificConventions(doc).isNotEmpty
              ? _specificConventions(doc).join('\\n')
              : _instructionFichePour(doc, stage, occurrence))
          : _instructionFichePour(doc, stage, occurrence);
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Text(doc.titre, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (instruction != null && instruction.isNotEmpty)
          SelectableText(instruction, style: const TextStyle(fontSize: 16, height: 1.4))
        else
          const Text('Consulter la fiche source pour les instructions de cette étape.'),
        _sourcePdf(source),
        _checkStep(index),
      ]);
    }
    final occurrence = int.tryParse(parts.last) ?? 1;
    final instruction = _instructionFichePour(doc, stage == 'r' || stage == 'l' ? 't' : stage, occurrence);
    final matches = instruction == null ? <String>[] : <String>[instruction];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Text(doc.titre + (stage == 'r' ? ' — Passes rapides' : stage == 'l' ? ' — Passes lentes et impositions' : ''), style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      if (_mode == 'À distance')
        const Text('À distance : ne pas effectuer de passes ni d’impositions physiques.'),
      if (matches.isEmpty)
        const Text('Consulter le schéma de la fiche originale ci-dessous.')
      else
        ...matches.map((line) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SelectableText(line, style: const TextStyle(fontSize: 16)),
        )),
      if (_zonesSoin.isNotEmpty)
        Text('Zone(s) : ' + (_zonesSoin.toList()..sort()).join(', ')),
      _sourcePdf(source),
      _checkStep(index),
    ]);
  }

  Widget _sourcePdf(String source) {
    return ExpansionTile(
      title: const Text('Fiche PDF originale — instructions complètes'),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(12),
          child: SelectableText(source),
        ),
      ],
    );
  }

  List<String> get _etapes {
    if (_parcoursFichesStructurees.isNotEmpty) return _parcoursFichesStructurees;
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

    if (_parcoursFichesStructurees.isNotEmpty) return _parcoursFichesStructurees;
    if (_parcoursPdfUnique.isNotEmpty) return _parcoursPdfUnique;

    return <String>[
      'Prise de contact',
      'Bilan énergétique',
      if (_scanPenduleNecessaire) 'Scan au pendule',
      'Dégagement des entités / énergies négatives si nécessaire',
      '14 conventions mentales',
      'Conventions mentales supplémentaires de la fiche technique',
      'Prières / formulations prévues par le protocole',
      if (_mode == 'Présentiel') ...<String>[
        if (_gestesFiches.isNotEmpty) ...<String>[
          ..._gestesFiches,
          if (_soinPenduleNecessaire) 'Pendule de Thot',
        ] else if (_ftHasPasses) ...<String>[
          '7A · Passes rapides',
          'Contrôle des flux',
          if (_soinPenduleNecessaire) 'Pendule de Thot',
          '7D · Passes lentes',
          '7E · Impositions et travaux spécifiques',
        ],
        if (_ftHasCirculation) 'Circulation énergétique entre les chakras',
        if (_ftHasBalayage) 'Balayage',
      ] else ...<String>[
        if (_soinPenduleNecessaire) 'Soin au pendule (1 soin)',
        if (_ftHasPasses || _ftHasCirculation || _ftHasBalayage)
          'Travail sur photo / planches anatomiques selon la fiche',
      ],
      'Débriefing / observation',
    ];
  }

  Future<void> _enregistrer() async {
    if (_saving || _patient.isEmpty || _ft == null) return;
    if (widget.demarrerSuivi && ((_pathologies.contains('Fibromyalgie') && !_zonesSuiviConfirmees) || (_pathologies.any((t)=>t.startsWith('Intervention chirurgicale')) && !_chirurgieSuiviConfirmee))) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Confirmez les zones du jour et la fiche de suivi avant l’enregistrement.')));return;
    }
    if (_selectedFts.length > 3 || (_usesPlanV33 && !_planV33.canStart)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vérifiez les motifs et les conflits du parcours.')));return;
    }

    setState(() => _saving = true);

    try {
    await MagnetismeSessionService.save(<String, dynamic>{
      'date': DateTime.now().toIso8601String(),
      'nomPatient': _prenom.text.trim(),
      'nomFamille': _nom.text.trim(),
      'mode': _mode,
      'ftId': _ft!.id,
      'ftTitre': _ft!.titre,
      'zonesSoin': _zonesSoin.toList(),
      'zonesParPathologie': {for (final e in _zonesParPathologie.entries) e.key: e.value.toList()},
      'ftIds': _selectedFts.map((doc) => doc.id).toList(),
      'ftTitres': _selectedFts.map((doc) => doc.titre).toList(),
      'typesSuivi': Map<String, String>.from(_typesSuivi),
      'zonesSuiviConfirmees': _zonesSuiviConfirmees,
      'chirurgieSuiviConfirmee': _chirurgieSuiviConfirmee,
      'versionGuide': '3.3.2',
      'thotClassiqueParTravail': {for(final e in _thotClassique.entries)e.key:List<bool>.from(e.value)},
      'minuteursLocaux': Map<String,int>.from(_tempsLocaux),
      'radioConnexionConfirmee': _radioConnexionConfirmee,
      'conditionsConfirmees': _conditionsConfirmees.toList(),
      'etapesNonApplicables': _etapesNonApplicables.toList(),
      'cm9Vigilance': _cm9Vigilance,
      'evenementsCM3': _evenementsCM3.text,
      'etapesIds': _usesPlanV33 ? _planV33.steps.map((s)=>s.id).toList() : _etapes,
      'conventionsSupplementairesFaites': _conventionsSupplementairesFaites.toList(),
      'seancePrecedenteDate': _seancePrecedente?['date'],
      'utiliserRaphael': _utiliserRaphael,
      'etapes': _etapes,
      'anamnese': {for (final e in _anamneseFields.entries) e.key: e.value.text.trim()},
      'soinPenduleNecessaire': _soinPenduleNecessaire,
      'scanPenduleNecessaire': _scanPenduleNecessaire,
      'soinPendule': _soinPenduleNecessaire ? {
        'zone': _selectedFts.map((d)=>'${d.titre} : ${(_zonesParPathologie[d.titre]?.toList()??[]).join(', ')}').join('; '),
        'etapes': List<bool>.generate(3,(i)=>_thotClassique.isNotEmpty&&_thotClassique.values.every((v)=>v[i])),
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

    } catch (error) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Enregistrement impossible : $error')));
      return;
    } finally {
      if(mounted) setState(()=>_saving=false);
    }
    if (!mounted) return;
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
          if (_ft!=null && !_usesPlanV33 && !_isCouperLeFeu) const Padding(padding:EdgeInsets.all(12),child:Text('Fiche ancienne : déroulé V3.2 conservé, non normalisé dans le guide V3.3.')),
          if (_usesPlanV33 && !_planV33.canStart) ..._planV33.conflicts.map((e)=>Text(e,style:const TextStyle(color:Colors.red))),
          if (_ft != null) ...<Widget>[
            const SizedBox(height: 10),
            _progressCard(faites, total),
            const SizedBox(height: 10),
            // Garder les clés des étapes montées : le défilement automatique
            // reste fiable quand l'étape précédente se replie.
            Column(children:List<Widget>.generate(_etapes.length, _stepCard)),
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
                _timerConventions?.cancel();
                setState(() { _mode = selection.first; _lectureAuto=false; _lectureSuspendue=false; _momentIndex=0; _etapesFaites.clear(); _etapeOuverte=0; });
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
                _timerConventions?.cancel();_lectureAuto=false;_lectureSuspendue=false;_etapeOuverte=0;
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
                'Complément classique : rotation négative, retrait et deux tapotements, rotation positive. Les zones de préparation sont réutilisées.',
              ),
              onChanged: (value) => setState(() {
                _timerConventions?.cancel(); _lectureAuto=false; _lectureSuspendue=false;
                _etapesFaites.clear(); _etapeOuverte=0;
                _soinPenduleNecessaire = value ?? false;
                if (!_soinPenduleNecessaire) {
                  _thotClassique.clear();
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
              items: _choixSoin.map((doc) => DropdownMenuItem<String>(
                value: doc.id,
                child: Text(doc.titre, overflow: TextOverflow.ellipsis),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _timerConventions?.cancel();_lectureAuto=false;_lectureSuspendue=false;_momentIndex=0;
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
                  _zonesParPathologie.clear();
                  _pathologieZoneActive = doc?.titre;
                  _utiliserRaphael = false;
                });
              },
            ),
            const SizedBox(height: 12),
            if (widget.demarrerSuivi) ...[
              const Text('Consultation de suivi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(_seancePrecedente == null ? 'Aucune séance précédente enregistrée : sélectionnez les motifs.' : 'Dernière séance : ${(_seancePrecedente!['date'] ?? '').toString().split('T').first}. Vérifiez les zones et les motifs avant de continuer.'),
              const SizedBox(height: 12),
              for (final titre in _pathologies.toList())
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(titre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(SuivisFormation.indication(titre), style: const TextStyle(fontSize: 12)),
                  DropdownButtonFormField<String>(
                    value: (_mode == 'Présentiel' && SuivisFormation.typePour(titre) == 'court') || (_mode == 'À distance' && titre == 'Traitements lourds (aide aux)') ? (_typesSuivi[titre] == 'radio' && _mode != 'À distance' ? 'complet' : _typesSuivi[titre] ?? 'complet') : 'complet',
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Type de visite'),
                    items: [
                      const DropdownMenuItem(value: 'complet', child: Text('Séance complète / existante')),
                      if (SuivisFormation.typePour(titre) == 'court' && _mode == 'Présentiel')
                        const DropdownMenuItem(value: 'court', child: Text('Suivi court documenté')),
                      if (_mode == 'À distance' && titre == 'Traitements lourds (aide aux)')
                        const DropdownMenuItem(value: 'radio', child: Text('Radiothérapie : suivi par prière contre le feu')),
                    ],
                    onChanged: (v) => setState(() { if (v != null) { _timerConventions?.cancel();_lectureAuto=false;_lectureSuspendue=false; _typesSuivi[titre] = v; _etapesFaites.clear(); _etapeOuverte=0; } }),
                  ),
                  const SizedBox(height: 12),
                ]),
              if (_pathologies.length > 1 && _typesSuivi.values.contains('court'))
                const Text('Chaque motif conserve son type de visite. Les étapes communes restent présentes pour les motifs en séance complète.', style: TextStyle(fontSize: 12)),
              if(_mode=='À distance' && _typesSuivi.values.contains('radio')) CheckboxListTile(
                title:const Text('Première séance complète réalisée ; connexion et photo déjà établies'),
                value:_radioConnexionConfirmee,onChanged:(v)=>setState(()=>_radioConnexionConfirmee=v??false)),
              if (_pathologies.contains('Fibromyalgie')) CheckboxListTile(
                title:const Text('J’ai confirmé les zones douloureuses du jour'),
                value:_zonesSuiviConfirmees,onChanged:(v)=>setState(()=>_zonesSuiviConfirmees=v??false)),
              if (_pathologies.any((t)=>t.startsWith('Intervention chirurgicale'))) CheckboxListTile(
                title:const Text('J’ai choisi la fiche avant ou après intervention correspondant à cette visite'),
                value:_chirurgieSuiviConfirmee,onChanged:(v)=>setState(()=>_chirurgieSuiviConfirmee=v??false)),
            ],
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
                    _timerConventions?.cancel();_lectureAuto=false;_lectureSuspendue=false;_momentIndex=0;
                    if (selected) {
                      if (_pathologies.length >= 3) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Maximum 3 soins par séance. Les prières ne sont pas limitées.')));return;
                      }
                      _pathologies.add(name);
                      _ftId ??= _fts.firstWhere((d)=>d.titre==name).id;
                    } else {
                      _pathologies.remove(name);
                      if (_find(_ftId)?.titre == name) _ftId = _fts.where((d)=>_pathologies.contains(d.titre)).firstOrNull?.id;
                    }
                    if (!selected) _zonesParPathologie.remove(name);
                    _pathologieZoneActive = selected ? name : (_pathologies.isEmpty ? null : _pathologies.first);
                    _zonesSoin.clear();
                    for (final values in _zonesParPathologie.values) { _zonesSoin.addAll(values); }
                    _conventionsSupplementairesFaites.clear();
                    _etapesFaites.clear();
                    _etapeOuverte = 0;
                  });
                },
              )).toList(),
            ),
            const SizedBox(height: 14),
            for(final d in _selectedFts) TrainerAdvice(items:d.raw['conseilsFormateur'] as List? ?? const [],title:'Conseils du formateur — ${d.titre}',initiallyExpanded:true),
            const Text('Zones anatomiques par pathologie',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Sélectionne une pathologie, puis ses zones sur le bonhomme. Recommence pour chaque motif : les zones restent séparées.',
                style: TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 8),
            if (_pathologies.isNotEmpty) ...<Widget>[
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _pathologies.map((name) => ChoiceChip(
                  label: Text('$name (${_zonesPour(name).length})'),
                  selected: (_pathologieZoneActive ?? _pathologies.first) == name,
                  onSelected: (_) => setState(() => _pathologieZoneActive = name),
                )).toList(),
              ),
              const SizedBox(height: 8),
              Builder(builder: (context) {
                final active = _pathologies.contains(_pathologieZoneActive)
                    ? _pathologieZoneActive! : _pathologies.first;
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Zones pour : $active', style: const TextStyle(fontWeight: FontWeight.bold)),
                  InteractiveBody(
                    key: ValueKey(active),
                    selectedZones: _zonesPour(active),
                    onZoneTap: (zone) => _onZonePathologieTap(active, zone),
                  ),
                  if (_zonesPour(active).isNotEmpty)
                    Wrap(spacing: 6, children: _zonesPour(active).map((zone) => Chip(
                      label: Text(zone),
                      onDeleted: () => _onZonePathologieTap(active, zone),
                    )).toList()),
                ]);
              }),
            ],
            for(final d in _selectedFts)
              if((_zonesParPathologie[d.titre]??{}).isNotEmpty)
                Text('${d.titre} — Zones mémorisées : ${_zonesParPathologie[d.titre]!.join(', ')}'),
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

  String _titreEtapeVisible(String title) {
    if (title.startsWith('V33 · ')) return _plannedStep(title).title;
    if (title == 'SUIVI · prière') return '${_pathologies.first} — Prière de suivi';
    if (title == 'SUIVI · imposition') return '${_pathologies.first} — Imposition de suivi';
    if (title.startsWith('FLUX · ')) {
      final d = int.tryParse(title.split(' · ').last) ?? 0;
      return '${_selectedFts[d].titre} — Contrôle des flux';
    }
    if (title.startsWith('GESTE · ')) {
      final p = title.split(' · ');
      final d = int.tryParse(p[2]) ?? 0;
      final label = p[1] == 'rapide' ? 'Passes rapides' : p[1] == 'lente' ? 'Passes lentes' : 'Impositions / visualisations';
      return '${_selectedFts[d].titre} — $label';
    }
    if (!title.startsWith('SOURCE · ')) return title;
    final parts = title.split(' · ');
    if (parts.length != 3) return title;
    final docIndex = int.tryParse(parts[1]) ?? -1;
    final stepIndex = int.tryParse(parts[2]) ?? -1;
    final docs = _selectedFts;
    if (docIndex < 0 || docIndex >= docs.length) return title;
    final steps = docs[docIndex].etapesGuideSource;
    if (stepIndex < 0 || stepIndex >= steps.length) return title;
    const labels = <String, String>{
      'intentions': 'Conventions supplémentaires',
      'priere': 'Prière / formulation',
      'travail': 'Travail en passes',
      'imposition': 'Imposition / visualisation',
      'autre': 'Instruction spécifique',
    };
    final type = steps[stepIndex]['type'] ?? 'autre';
    return '${docs[docIndex].titre} — ${labels[type] ?? 'Instruction spécifique'}';
  }

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
            _timerConventions?.cancel();
            setState(() { _lectureAuto=false; _lectureSuspendue=false; _etapeOuverte = open ? -1 : index; });
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
              Expanded(child: Text(_titreEtapeVisible(title), style: const TextStyle(fontWeight: FontWeight.w600))),
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
    if(widget.demarrerSuivi && _pathologies.contains('Fibromyalgie') && !_zonesSuiviConfirmees) {
      return const Text('Confirmez les zones douloureuses actuelles dans la préparation avant le guidage.');
    }
    if(widget.demarrerSuivi && _pathologies.any((t)=>t.startsWith('Intervention chirurgicale')) && !_chirurgieSuiviConfirmee) {
      return const Text('Confirmez la fiche avant/après intervention dans la préparation avant le guidage.');
    }
    if (_usesPlanV33 && !_planV33.canStart) return Column(children:[..._planV33.conflicts.map((e)=>Text(e,style:const TextStyle(color:Colors.red)))]);
    if (_etapes[index].startsWith('V33 · ')) return _plannedContent(index);
    if (_isCouperLeFeu) {
      if (index == 0) return _couperLeFeuStep(0);
      if (_scanPenduleNecessaire && index == 1) return _scanPenduleStep();
      if (_soinPenduleNecessaire && index == 1 + (_scanPenduleNecessaire ? 1 : 0)) return _soinPenduleStep();
      final baseIndex = index - (_scanPenduleNecessaire ? 1 : 0) - (_soinPenduleNecessaire ? 1 : 0);
      if (_mode == 'À distance' && baseIndex == 2) return _couperLeFeuStep(3);
      return _couperLeFeuStep(baseIndex);
    }

    final title = _etapes[index];
    if (title.startsWith('V33 · ')) return _plannedContent(index);
    if (title == 'SUIVI · prière') return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_pathologies.first.toLowerCase().contains('zona') ? _priereFeu : 'Reprendre la prière de la fiche technique « Verrue ».', style: const TextStyle(fontSize: 16)), _checkStep(index)]);
    if (title == 'SUIVI · imposition') return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_pathologies.first.toLowerCase().contains('zona') ? 'Reprendre uniquement l’imposition des mains décrite dans la fiche Zona.' : 'Reprendre l’imposition / rayon sur les verrues décrit dans la fiche.', style: const TextStyle(fontSize: 16)), _checkStep(index)]);
    if (title.startsWith('FLUX · ')) return _etapeFluxParMotif(index);
    if (title.startsWith('GESTE · ')) return _etapeGeste(index);
    if (title.startsWith('SOURCE · ')) return _etapeFicheSource(index);
    if (title.startsWith('PDF45 · ')) return _etapePdf(index);
    if (title == 'Prise de contact') return _contactHelp();
    if (title == 'Bilan énergétique') return _bilan();
    if (title == 'Scan au pendule') return _scanPenduleStep();
    if (title == 'Soin au pendule (1 soin)') return _soinPenduleStep();
    if (title == 'Pendule de Thot') return _soinPenduleStep();
    if (title.startsWith('Geste fiche : ')) return _gesteFiche(index);
    if (title.startsWith('Dégagement des entités')) return _degagement();
    if (title == '14 conventions mentales') return _conventions();
    if (title == 'Conventions mentales supplémentaires de la fiche technique') return _specific();
    if (title == 'Prières / formulations prévues par le protocole') return _prieres();
    if (title == 'Débriefing / observation') return _debrief();
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
            _checkStep(_currentStepIndex),
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
            _checkStep(_currentStepIndex),
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
            _checkStep(_currentStepIndex),
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
        _checkStep(_currentStepIndex),
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
        CheckboxListTile(
          title:const Text('CM9 : seuil de vigilance relevé au bilan traditionnel'),
          subtitle:const Text('Nettoyage de 2 minutes ; 4 minutes si « Magie noire » est marqué Oui.'),
          value:_cm9Vigilance,onChanged:(v)=>setState(()=>_cm9Vigilance=v??false)),
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
        _checkStep(_currentStepIndex),
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
        const Text('Scan général : zones mémorisées lors de la préparation', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        const Text('Pour un examen plus précis, utilise les planches anatomiques de la bibliothèque.'),
        const SizedBox(height: 8),
        const Text('Zones anatomiques observées', style: TextStyle(fontWeight: FontWeight.w600)),
        ..._selectedFts.map((f)=>Text('${f.titre} — Zones mémorisées : ${(_zonesParPathologie[f.titre]?.toList()??[]).join(', ')}')),
        _compactText('Notes du scan', _bilanNotes, minLines: 3),
        _checkStep(_currentStepIndex),
      ],
    );
  }

  Widget _soinPenduleStep({PlanStep? step}) {
    final id=step?.id ?? 'thot-manuel';
    final done=_thotClassique.putIfAbsent(id,()=>List<bool>.filled(3,false));
    final zones=step?.zones ?? const <String>[];
    return Column(key:const ValueKey('classic-thot'),crossAxisAlignment:CrossAxisAlignment.start,children:[
      if(step!=null && step.target!='selection' && step.target.isNotEmpty)
        Text('Zone à travailler : ${step.target}'),
      if(step!=null && step.target!='selection' && zones.isNotEmpty)
        Text('Zones mémorisées pour ce motif (repères ; cible actuelle ci-dessus) : ${zones.join(', ')}'),
      if(step==null) ..._selectedFts.map((f)=>Text('${f.titre} — Zones à travailler : ${(_zonesParPathologie[f.titre]?.toList()??[]).join(', ')}'))
      else if(step.target=='selection') Text('Zones à travailler : ${zones.isEmpty?'zones mémorisées non précisées':zones.join(', ')}'),
      if(_mode=='À distance') const Text('Sur la représentation de la zone concernée, reliée au témoin. Aucun geste sur le patient.'),
      if(id.endsWith(':option')) const Text('Placement spécifique de ce complément à vérifier pour ce parcours : aucun contrôle local n’est décrit.'),
      for(var n=0;n<3;n++) CheckboxListTile(
        key:ValueKey('$id-operation-$n'),contentPadding:EdgeInsets.zero,
        title:Text(const [
          'Rotation négative : dégagement.',
          'Lever le pendule et tapoter deux fois pour évacuer le négatif.',
          'Rotation positive : rééquilibrage.',
        ][n]),
        value:done[n],onChanged:(v)=>setState(()=>done[n]=v??false)),
      if(step?.source.isNotEmpty??false) ExpansionTile(title:const Text('Source'),children:[SelectableText(step!.source)]),
      if(step!=null) TrainerAdvice(items:_find(step.ficheId)?.raw['conseilsFormateur'] as List? ?? const []),
      _checkStep(_currentStepIndex),
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
      _checkStep(_currentStepIndex),
    ]);
  }

  int _momentIndex = 0;
  List<ConventionMoment> get _moments => ConventionTiming.build(
    medication:_traitements.text.trim().isNotEmpty,
    observations:_cm9Observation,
    lowBlood:_sangBelow70(),
    events:_evenementsCM3.text.split('\n').map((s)=>s.trim()).where((s)=>s.isNotEmpty).toList(),
    weakBodies: {for(final e in _corpsFields.entries)
      if(const ['G','D','G + D','Oui'].contains(e.value.text)) e.key: const {'2':'éthérique','3':'astral','4':'mental','5':'causal','6':'bouddhique','7':'atmique'}[e.key]!},
  );
  ConventionMoment get _moment => _moments[_momentIndex.clamp(0,_moments.length-1)];
  int _dureeConvention() => _dureePersonnalisee > 0 ? _dureePersonnalisee : _moment.seconds;

  void _arreterLecture() {
    _timerConventions?.cancel();
    setState(() { _lectureAuto=false; _lectureSuspendue=true; });
  }
  void _moveMoment(int next,{bool complete=false}) {
    _timerConventions?.cancel();
    if(complete && _moment.last) _conventionsFaites.add(_moment.convention);
    _momentIndex=next.clamp(0,_moments.length-1);
    _conventionOuverte=_moment.convention;
    _secondesRestantes=_dureeConvention();
    _lectureSuspendue=false; _lectureAuto=false;
  }
  void _nextMoment() {
    setState(() {
      if(_momentIndex == _moments.length-1) {
        _conventionsFaites.add(_moment.convention);
        _timerConventions?.cancel();_lectureAuto=false;_lectureSuspendue=false;
      } else { _moveMoment(_momentIndex+1,complete:true); }
    });
  }
  void _demarrerLecture() {
    _timerConventions?.cancel();
    setState(() {
      _lectureAuto=true;
      if(!_lectureSuspendue) _secondesRestantes=_dureeConvention();
      _lectureSuspendue=false;
    });
    _timerConventions=Timer.periodic(const Duration(seconds:1),(timer) {
      if(!mounted){timer.cancel();return;}
      if(_secondesRestantes>1){setState(()=>_secondesRestantes--);return;}
      final finished=_momentIndex==_moments.length-1;
      _nextMoment();
      if(!finished) {
        _demarrerLecture();
      } else {
        // En parcours V33, les intentions sont des étapes du plan, et non
        // nécessairement des entrées de _allSpecificConventions.
        final nextIntentions = _usesPlanV33
            ? _etapes.indexWhere((title) => title.startsWith('V33 · ') &&
                _plannedStep(title).kind == 'intentions')
            : -1;
        if (nextIntentions >= 0) {
          _etapeOuverte = nextIntentions;
          _demarrerIntentionsPlanifiees();
        } else if (_allSpecificConventions.isNotEmpty) {
          _indexConventionSpecifique = 0;
          _secondesConventionSpecifique = 0;
          _pauseConventionsSpecifiques = false;
          _conventionsSupplementairesFaites.clear();
          _demarrerLectureSpecifique();
        }
      }
    });
  }
  Widget _lectureAutomatique() {
    final m=_moment;
    final duration=_dureeConvention();
    final remaining=(!_lectureAuto&&!_lectureSuspendue) ? duration : _secondesRestantes;
    final progress=(1-remaining/duration).clamp(0.0,1.0);
    final base=_conventionAction(m.convention);
    final instruction=m.intention.isEmpty ? base :
      '${_mode == 'À distance' ? 'Les deux mains au-dessus de la photo.' : 'Les mains sur le chakra couronne.'} Intention : « ${m.intention} ». ${m.seconds} secondes (manuel).';
    final title=m.label.isEmpty ? _conventionTitles[m.convention] : m.label;
    return Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(
      crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Text('Convention ${m.convention+1} / 14',style:const TextStyle(fontSize:19,fontWeight:FontWeight.bold)),
      Text(title),const SizedBox(height:16),
      Center(child:SizedBox(width:200,height:200,child:Stack(alignment:Alignment.center,children:[
        SizedBox.expand(child:CircularProgressIndicator(value:progress,strokeWidth:10,backgroundColor:Colors.black12)),
        Text('${(remaining~/60).toString().padLeft(2,'0')}:${(remaining%60).toString().padLeft(2,'0')}',style:const TextStyle(fontSize:42,fontWeight:FontWeight.bold)),
      ]))),const SizedBox(height:16),
      Text('Durée utilisée : $duration secondes${_dureePersonnalisee>0 ? ' (réglage personnel)' : ''}.'),
      if(m.convention==8 && m.intention.isNotEmpty) const Text('CM9 : la bibliothèque indique 30 s pour équilibrage/recharge ; les notes vidéo évoquent 15–20 s. Divergence conservée : ajustement personnel possible, sans prétendre à une durée unique validée.'),
      SelectableText(instruction,style:const TextStyle(fontSize:16,height:1.4)),
      const SizedBox(height:10),
      Wrap(spacing:6,children:[for(final seconds in [0,15,20,30,60,120,180,240]) ChoiceChip(
        label:Text(seconds==0?'Bibliothèque':'$seconds s'), selected:_dureePersonnalisee==seconds,
        onSelected:_lectureAuto?null:(_)=>setState((){_dureePersonnalisee=seconds;_secondesRestantes=_dureeConvention();_lectureSuspendue=false;}),
      )]),
      FilledButton.icon(onPressed:_lectureAuto?_arreterLecture:_demarrerLecture,icon:Icon(_lectureAuto?Icons.pause:Icons.play_arrow),label:Text(_lectureAuto?'Pause':(_lectureSuspendue?'Reprendre':'Démarrer'))),
      const Text('Sans son ni vibration',textAlign:TextAlign.center),
      Row(children:[
        OutlinedButton(onPressed:_momentIndex==0?null:()=>setState(()=>_moveMoment(_momentIndex-1)),child:const Text('Précédente')),
        const Spacer(),
        FilledButton(onPressed:_nextMoment,child:const Text('Réalisée → suivante')),
      ]),
    ])));
  }
  Widget _conventions() {
    final ids=_moments.map((m)=>m.convention).toSet();
    final complete=ids.every(_conventionsFaites.contains);
    final doc=_reference('14 conventions — version complète') ?? _reference('14 conventions');
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      TextField(controller:_evenementsCM3,minLines:1,maxLines:3,enabled:!_lectureAuto,
        decoration:const InputDecoration(labelText:'CM3 : événements particuliers (facultatif, un par ligne)',hintText:'Événement et date connus de la personne'),
        onChanged:(_)=>setState((){_momentIndex=0;_lectureSuspendue=false;_conventionsFaites.clear();})),
      const Text('Complément CM3 : 30 s par événement dans la bibliothèque ; les notes vidéo évoquent 15–20 s. La durée retenue reste affichée et ajustable.'),
      if (_lectureConventionsSpecifiques || _pauseConventionsSpecifiques || (_conventionsFaites.length == ids.length && _conventionsSupplementairesFaites.isNotEmpty))
        Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(
          crossAxisAlignment:CrossAxisAlignment.stretch,
          children:[
            const Text('Conventions supplémentaires',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
            if (_indexConventionSpecifique < _allSpecificConventions.length) ...[
              Text('Convention ${_indexConventionSpecifique + 1} / ${_allSpecificConventions.length}'),
              SelectableText(_allSpecificConventions[_indexConventionSpecifique]),
              Text('Temps restant : ${(_secondesConventionSpecifique ~/ 60).toString().padLeft(2,'0')}:${(_secondesConventionSpecifique % 60).toString().padLeft(2,'0')}'),
            ],
            FilledButton.icon(
              onPressed:_lectureConventionsSpecifiques ? _pauseLectureSpecifique : _demarrerLectureSpecifique,
              icon:Icon(_lectureConventionsSpecifiques ? Icons.pause : Icons.play_arrow),
              label:Text(_lectureConventionsSpecifiques ? 'Pause' : (_pauseConventionsSpecifiques ? 'Reprendre' : 'Relancer les conventions supplémentaires')),
            ),
          ],
        )))
      else _lectureAutomatique(),
      if(_traitements.text.trim().isEmpty) const Text('Convention 8 omise : aucun traitement signalé au bilan.'),
      ExpansionTile(title:const Text('Les 14 conventions et leurs sources'),children:[
        for(var i=0;i<14;i++) ListTile(
          title:Text('${i+1}. ${_conventionTitles[i]}'),
          trailing:_conventionsFaites.contains(i)?const Icon(Icons.check_circle):null,
          onTap:(){final n=_moments.indexWhere((m)=>m.convention==i);if(n>=0)setState(()=>_moveMoment(n));},
        ),
        if(doc!=null) OutlinedButton(onPressed:()=>_openReader(doc),child:const Text('Ouvrir le document complet')),
      ]),
      if(complete) _checkStep(_currentStepIndex),
    ]);
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
        .replaceAll('[nom de la maladie]', _selectedFts.map((d)=>d.titre).join(', '));
    if (_mode == 'À distance') {
      return durations[index] + '\n\n' + intention.replaceAll('Vos mains sur le chakra couronne du consultant, ', 'Les deux mains au-dessus de la photo, ').replaceAll('laissez passer l’énergie', 'maintenez votre intention');
    }
    return durations[index] + '\n\n' + intention;
  }

  String get _cm9Observation => _negatives.text == 'Oui' ? 'magie noire' : _cm9Vigilance ? 'vigilance' : '';
  String _convention9Duration() {
    final seconds=ConventionTiming.cleaningSeconds(_cm9Observation);
    return '${seconds ~/ 60} minute(s) de nettoyage (manuel), puis équilibrage et recharge guidés séparément.';
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

  String? _protocolSection(int number) => _ft == null ? null : _protocolSectionFor(_ft!, number);

  String? _protocolSectionFor(_Doc doc, int number) {
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

  List<int> get _indicesIntentionsPlanifiees => [
    for (var i = 0; i < _etapes.length; i++)
      if (_etapes[i].startsWith('V33 · ') &&
          _plannedStep(_etapes[i]).kind == 'intentions') i,
  ];

  List<String> _intentionsDeLEtape(int index) {
    final step = _plannedStep(_etapes[index]);
    return step.text.split('\\n').map((s) => s.trim())
        .where((s) => s.isNotEmpty).toList();
  }

  int _indexIntentionPlanifiee = 0;
  int _positionIntentionPlanifiee = 0;
  bool _lectureIntentionsPlanifiees = false;
  bool _pauseIntentionsPlanifiees = false;
  int _restantIntentionPlanifiee = 0;
  Timer? _timerIntentionsPlanifiees;

  void _demarrerIntentionsPlanifiees() {
    final indices = _indicesIntentionsPlanifiees;
    if (indices.isEmpty) return;
    _timerIntentionsPlanifiees?.cancel();
    if (!_pauseIntentionsPlanifiees) {
      _indexIntentionPlanifiee = 0;
      _positionIntentionPlanifiee = 0;
      _restantIntentionPlanifiee = _dureePersonnalisee > 0 ? _dureePersonnalisee : 60;
    }
    setState(() {
      _lectureIntentionsPlanifiees = true;
      _pauseIntentionsPlanifiees = false;
      _etapeOuverte = indices[_indexIntentionPlanifiee];
    });
    _timerIntentionsPlanifiees = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() {
        if (_restantIntentionPlanifiee > 1) {
          _restantIntentionPlanifiee--;
          return;
        }
        final index = indices[_indexIntentionPlanifiee];
        final intentions = _intentionsDeLEtape(index);
        if (_positionIntentionPlanifiee + 1 < intentions.length) {
          _positionIntentionPlanifiee++;
        } else {
          _etapesFaites.add(index);
          if (_indexIntentionPlanifiee + 1 == indices.length) {
            timer.cancel();
            _lectureIntentionsPlanifiees = false;
            _pauseIntentionsPlanifiees = false;
            _restantIntentionPlanifiee = 0;
            return;
          }
          _indexIntentionPlanifiee++;
          _positionIntentionPlanifiee = 0;
          _etapeOuverte = indices[_indexIntentionPlanifiee];
        }
        _restantIntentionPlanifiee = _dureePersonnalisee > 0 ? _dureePersonnalisee : 60;
      });
    });
  }

  void _pauseIntentionsPlanifieesLecture() {
    _timerIntentionsPlanifiees?.cancel();
    setState(() {
      _lectureIntentionsPlanifiees = false;
      _pauseIntentionsPlanifiees = true;
    });
  }

  void _pauseLectureSpecifique() {
    _timerConventionsSpecifiques?.cancel();
    setState(() {
      _lectureConventionsSpecifiques = false;
      _pauseConventionsSpecifiques = true;
    });
  }

  void _demarrerLectureSpecifique() {
    final conventions = _allSpecificConventions;
    if (conventions.isEmpty) return;
    _timerConventionsSpecifiques?.cancel();
    setState(() {
      if (_indexConventionSpecifique >= conventions.length) {
        _indexConventionSpecifique = 0;
        _conventionsSupplementairesFaites.clear();
      }
      if (!_pauseConventionsSpecifiques || _secondesConventionSpecifique <= 0) {
        _secondesConventionSpecifique = _dureePersonnalisee > 0 ? _dureePersonnalisee : 60;
      }
      _lectureConventionsSpecifiques = true;
      _pauseConventionsSpecifiques = false;
    });
    _timerConventionsSpecifiques = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() {
        if (_secondesConventionSpecifique > 1) {
          _secondesConventionSpecifique--;
          return;
        }
        _conventionsSupplementairesFaites.add(_indexConventionSpecifique);
        if (_indexConventionSpecifique + 1 >= conventions.length) {
          timer.cancel();
          _lectureConventionsSpecifiques = false;
          _pauseConventionsSpecifiques = false;
          _secondesConventionSpecifique = 0;
        } else {
          _indexConventionSpecifique++;
          _secondesConventionSpecifique = _dureePersonnalisee > 0 ? _dureePersonnalisee : 60;
        }
      });
    });
  }

  Widget _specific() {
    final zones = _zonesSoin.toList()..sort();
    final conventions = _allSpecificConventions;
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
          const Text('Lecture automatique des conventions supplémentaires, sans son ni vibration.'),
          if (_indexConventionSpecifique < conventions.length) ...[
            Text('Convention supplémentaire ${_indexConventionSpecifique + 1} / ${conventions.length}',style:const TextStyle(fontWeight:FontWeight.bold)),
            SelectableText(conventions[_indexConventionSpecifique]),
            Text('Temps restant : ${(_secondesConventionSpecifique ~/ 60).toString().padLeft(2,'0')}:${(_secondesConventionSpecifique % 60).toString().padLeft(2,'0')}'),
          ],
          FilledButton.icon(
            onPressed: _lectureConventionsSpecifiques ? _pauseLectureSpecifique : _demarrerLectureSpecifique,
            icon: Icon(_lectureConventionsSpecifiques ? Icons.pause : Icons.play_arrow),
            label: Text(_lectureConventionsSpecifiques ? 'Pause' : (_pauseConventionsSpecifiques ? 'Reprendre' : 'Démarrer toutes les conventions supplémentaires')),
          ),
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
        _checkStep(_currentStepIndex),
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
        if (_ftHasFirePrayer)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ExpansionTile(
              initiallyExpanded: true,
              title: const Text('Prière contre le feu — 3 fois'),
              subtitle: Text('Demandée par la fiche : ${_ft?.titre ?? ""}'),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  child: SelectableText(
                    MagnetismeLibraryService.personalized(
                      _priereFeu,
                      prenom: _prenom.text,
                      nom: _nom.text,
                    ),
                    style: const TextStyle(fontSize: 14, height: 1.45),
                  ),
                ),
              ],
            ),
          ),
        ..._pathologies.expand((pathology) {
          final prayers = _findPrayers(pathology);
          if (prayers.isEmpty && _ftHasFirePrayer) return <Widget>[];
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
        _checkStep(_currentStepIndex),
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
      'Effectuez deux séries de passes à vitesse moyenne, pendant environ 30 secondes à 1 minute au total.\n\n'
      '1. Passage à deux mains sur le bras gauche.\n'
      '2. Passage à deux mains sur le tronc côté gauche et centre.\n'
      '3. Passage à deux mains sur le tronc côté droit et centre.\n'
      '4. Passage à deux mains sur le bras droit.\n'
      '5. Passage à deux mains sur la jambe gauche.\n'
      '6. Passage à deux mains sur la jambe droite.\n'
      '7. Recommencez cette série une deuxième fois pour terminer la séance.';

  static const _memoCirculation = 'Une main au chakra couronne, l’autre au troisième œil. Contrôler par un petit va-et-vient sans contact de la main au chakra couronne. Si aucun ressenti : cinq passes rapides entre les deux chakras, puis nouveau contrôle. Recommencer depuis la couronne vers gorge, cœur, plexus, sacré puis racine. Mains inversables selon votre confort. Référence : La circulation énergétique entre les chakras.';

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
    if (titreEtape == 'Circulation énergétique entre les chakras' || titreEtape == 'Balayage') {
      final circulation = titreEtape == 'Circulation énergétique entre les chakras';
      return EnergyEndingGuidance(
        circulation: circulation,
        instructions: circulation
            ? SelectableText(_find('circulation-energetique-entre-les-chakras')?.contenu ?? _memoCirculation)
            : const Text(_memoBalayage),
        validation: _checkStep(index),
      );
    }
    final distance = _mode == 'À distance';
    final techniques = _selectedFts.map((doc) {
      final section = _protocolSectionFor(doc, 7);
      return section == null ? null : '${doc.titre}\n$section';
    }).whereType<String>().toList();
    final zones = _zonesSoin.toList()..sort();

    if (titreEtape == '7A · Passes rapides' || titreEtape == 'Contrôle des flux') {
      final routes = _trajetsZones(<String>{
        ..._zonesSoin,
        for (final values in _zonesParPathologie.values) ...values,
      });
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        if (routes.isEmpty)
          const Text('Aucun trajet articulaire identifié pour cette sélection : consulter la fiche technique.')
        else
          ...routes.map((route) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(route, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          )),
        _checkStep(index),
      ]);
    }

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

    final isRapid = titreEtape == '7A · Passes rapides';
    final isSlow = titreEtape == '7D · Passes lentes';
    final isSpecific = titreEtape == '7E · Impositions et travaux spécifiques';
    String relevantInstructions(String section) {
      final lines = section.split('\n');
      final pattern = isRapid
          ? RegExp(r'passes? rapides?|chakra en amont|chakra en aval', caseSensitive: false)
          : isSlow
              ? RegExp(r'passes? lentes?', caseSensitive: false)
              : RegExp(r'imposition|apposition|visualisation|ligament|travail complémentaire', caseSensitive: false);
      return lines.where((line) => pattern.hasMatch(line)).join('\n').trim();
    }
    // Afficher la fiche complète : ne pas perdre les gestes ni leur ordre.
    final instructions = (isRapid || isSlow)
        ? techniques.map(relevantInstructions).where((item) => item.isNotEmpty).toList()
        : isSpecific ? techniques : <String>[];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      if (titreEtape == 'Balayage') _aideMemoire('Le balayage', _memoBalayage),
      if (titreEtape == 'Circulation énergétique entre les chakras') _aideMemoire('Circulation entre les chakras', _memoCirculation),
      if (isRapid || isSlow || isSpecific) ...<Widget>[
        if (instructions.isNotEmpty)
          SelectableText(instructions.join('\n\n'), style: const TextStyle(fontSize: 16, height: 1.4))
        else
          const Text('Aucune consigne spécifique identifiée pour cette sous-étape dans la fiche.'),
      ],
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

  Widget _thotComplementStep(int index) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      const Text('Pendule de Thot — complément facultatif',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      const SizedBox(height: 8),
      const Text('1. Rotation négative du pendule sur la zone choisie.'),
      const Text('2. Lever le pendule, puis tapoter deux fois.'),
      const Text('3. Rotation positive du pendule sur la même zone.'),
      const SizedBox(height: 8),
      if (_zonesSoin.isNotEmpty)
        Text('Zone : ${(_zonesSoin.toList()..sort()).join(', ')}'),
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
      _checkStep(_currentStepIndex),
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
  final List<Map<String, String>> etapesGuideSource;
  final Map<String,dynamic> raw;

  const _Doc({
    required this.id,
    required this.titre,
    required this.source,
    required this.type,
    required this.contenu,
    this.description = '',
    this.aliases = const <String>[],
    this.etapesGuideSource = const <Map<String, String>>[],
    this.raw = const {},
  });

  factory _Doc.fromJson(Map<String, dynamic> json) {
    return _Doc(
      raw: json,
      id: (json['id'] ?? '').toString(),
      titre: (json['titre'] ?? '').toString(),
      source: (json['source'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      contenu: (json['contenu'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      aliases: (json['aliases'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[],
      etapesGuideSource: (json['etapesGuideSource'] as List?)
          ?.map((item) => Map<String, String>.from(item as Map))
          .toList() ?? const <Map<String, String>>[],
    );
  }
}
