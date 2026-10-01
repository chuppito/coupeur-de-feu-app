import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive_flutter/hive_flutter.dart';

class MagnetismeScreen extends StatefulWidget {
  final String? prefillNom;
  final String? prefillNomFamille;

  const MagnetismeScreen({super.key, this.prefillNom, this.prefillNomFamille});

  @override
  State<MagnetismeScreen> createState() => _MagnetismeScreenState();
}

class _MagnetismeScreenState extends State<MagnetismeScreen> {
  final _nomController = TextEditingController();
  final _familleController = TextEditingController();
  final _notesController = TextEditingController();

  List<_MagnetismeFiche> _fiches = [];
  bool _chargement = true;
  String? _erreur;
  String? _pathologie;
  String _mode = 'Présentiel';
  bool _ficheGeneree = false;
  String _recherche = '';
  final Set<int> _etapesFaites = {};
  final Map<String, bool> _scans = {};
  final Map<String, String> _observationsScans = {};

  @override
  void initState() {
    super.initState();
    _nomController.text = widget.prefillNom ?? '';
    _familleController.text = widget.prefillNomFamille ?? '';
    _chargerFiches();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _familleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _chargerFiches() async {
    try {
      final raw = await rootBundle.loadString('assets/data/magnetisme_protocoles.json');
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final list = (data['fiches'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(_MagnetismeFiche.fromJson)
          .toList();
      if (!mounted) return;
      setState(() {
        _fiches = list;
        _chargement = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _chargement = false;
        _erreur = 'Impossible de charger les fiches : $e';
      });
    }
  }

  List<_MagnetismeFiche> get _fichesTechniques =>
      _fiches.where((f) => f.type == 'fiche_technique').toList()
        ..sort((a, b) => a.titre.compareTo(b.titre));

  List<_MagnetismeFiche> get _references =>
      _fiches.where((f) => f.type == 'reference').toList()
        ..sort((a, b) => a.titre.compareTo(b.titre));

  _MagnetismeFiche? get _ficheSelectionnee {
    if (_pathologie == null) return null;
    for (final f in _fichesTechniques) {
      if (f.titre.toLowerCase() == _pathologie!.toLowerCase()) return f;
    }
    return null;
  }

  void _genererFiche() {
    if (_pathologie == null) return;
    setState(() {
      _ficheGeneree = true;
      _etapesFaites.clear();
      _scans.clear();
      _observationsScans.clear();
    });
  }

  Future<void> _enregistrerSeance() async {
    final box = await Hive.openBox('soins_magnetisme');
    await box.add({
      'date': DateTime.now().toIso8601String(),
      'nom': _nomController.text.trim(),
      'nomFamille': _familleController.text.trim(),
      'pathologie': _pathologie ?? '',
      'mode': _mode,
      'etapesFaites': _etapesFaites.toList(),
      'scans': Map<String, bool>.from(_scans),
      'observationsScans': Map<String, String>.from(_observationsScans),
      'notes': _notesController.text.trim(),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Séance enregistrée dans l’historique magnétisme.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Soins magnétisme'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.playlist_add_check), text: 'Nouveau soin'),
              Tab(icon: Icon(Icons.menu_book_outlined), text: 'Fiches techniques'),
            ],
          ),
        ),
        body: _chargement
            ? const Center(child: CircularProgressIndicator())
            : _erreur != null
                ? Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(_erreur!)))
                : TabBarView(
                    children: [
                      _buildNouveauSoin(),
                      _buildBibliotheque(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildNouveauSoin() {
    final fiche = _ficheSelectionnee;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      children: [
        Card(
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.45),
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('La séance est générée à partir de la FT choisie.', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text('La trame commune vient des fiches « récap séance » et la partie spécifique vient de la fiche technique de l’affection. Les cadrans de radiesthésie restent sur papier.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextField(controller: _nomController, decoration: const InputDecoration(labelText: 'Prénom du patient')),
        const SizedBox(height: 8),
        TextField(controller: _familleController, decoration: const InputDecoration(labelText: 'Nom (optionnel)')),
        const SizedBox(height: 14),
        const Text('Type de séance', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'Présentiel', label: Text('Présentiel'), icon: Icon(Icons.person)),
            ButtonSegment(value: 'Distance', label: Text('À distance'), icon: Icon(Icons.phone_in_talk)),
          ],
          selected: {_mode},
          onSelectionChanged: (v) => setState(() {
            _mode = v.first;
            _ficheGeneree = false;
          }),
        ),
        const SizedBox(height: 14),
        const Text('Fiche technique', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _pathologie,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Choisir l’affection / la FT'),
          items: _fichesTechniques
              .map((f) => DropdownMenuItem(value: f.titre, child: Text(f.titre)))
              .toList(),
          onChanged: (v) => setState(() {
            _pathologie = v;
            _ficheGeneree = false;
          }),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _pathologie == null ? null : _genererFiche,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Générer la séance complète'),
          ),
        ),
        if (!_ficheGeneree) ...[
          const SizedBox(height: 18),
          const Text('Exemple : pour une personne qui vient pour de l’acné, choisir « Acné », puis le mode Présentiel ou À distance. La fiche complète apparaît ensuite dans l’ordre de la séance.'),
        ],
        if (_ficheGeneree && fiche != null) ...[
          const SizedBox(height: 18),
          _buildEnteteSeance(fiche),
          const SizedBox(height: 10),
          ..._buildEtapes(fiche),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(labelText: 'Notes / débriefing', alignLabelWithHint: true),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _enregistrerSeance,
            icon: const Icon(Icons.save),
            label: const Text('Enregistrer la séance'),
          ),
        ],
      ],
    );
  }

  Widget _buildEnteteSeance(_MagnetismeFiche fiche) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.self_improvement, color: Colors.indigo),
        title: Text('${fiche.titre} — $_mode', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Fiche technique spécifique + déroulé complet de la séance'),
      ),
    );
  }

  List<Widget> _buildEtapes(_MagnetismeFiche fiche) {
    final common = <_CareStep>[
      const _CareStep('Prise de contact', 'Échange initial et écoute de la personne. Prévoir environ 10 minutes selon le récapitulatif de séance.'),
      const _CareStep('Bilan énergétique', 'Faire le bilan systématiquement avant le travail de magnétisme.'),
      const _CareStep('Dégagement des entités / énergies négatives', 'À effectuer si le bilan au pendule a mis quelque chose en évidence.'),
      const _CareStep('14 conventions mentales', 'Base commune de la séance. Utiliser ta fiche papier des 14 conventions et suivre ton protocole habituel.'),
      _CareStep('Conventions mentales supplémentaires — ${fiche.titre}', 'Reprendre les conventions/intention(s) indiquées dans la FT « ${fiche.titre} ».', details: fiche.contenu),
      const _CareStep('Prière(s)', 'Réaliser la ou les prières indiquées dans la FT lorsque le protocole en prévoit.'),
    ];

    if (_mode == 'Présentiel') {
      common.addAll([
        _CareStep('Passes et impositions des mains', 'Appliquer exactement les passes, impositions et visualisations décrites dans la FT.'),
        const _CareStep('Circulation énergétique entre les chakras', 'Étape systématique du récapitulatif de séance en présentiel.'),
        const _CareStep('Balayage', 'Étape systématique de fin de travail en présentiel.'),
        const _CareStep('Débriefing', 'Communiquer les informations utiles au suivi et terminer la séance.'),
      ]);
    } else {
      common.addAll([
        const _CareStep('Travail sur planches anatomiques / photo', 'À distance, les passes et impositions sont remplacées par le travail sur planches anatomiques. Le travail peut être réalisé à partir de la photo selon la fiche.'),
        const _CareStep('Convention n°10 — intention renforcée', 'Le récapitulatif à distance prévoit une intention plus poussée lors de la convention n°10 « Nettoyer et harmoniser les 7 chakras ».'),
        const _CareStep('Débriefing à distance', 'Faire le débriefing au téléphone lorsque la personne est disponible et à l’écoute.'),
      ]);
    }

    return [
      _buildScanSection(),
      ...List.generate(common.length, (i) => _buildCareStep(i, common[i])),
    ];
  }

  Widget _buildScanSection() {
    final scans = _mode == 'Présentiel'
        ? const [
            'Taux de vitalité / taux vibratoire',
            'Corps énergétiques',
            'Contrôle des 7 chakras',
            'Entités bas astral',
            'Énergies négatives',
            'Scan énergétique des organes',
            'Qualité énergétique du sang',
          ]
        : const [
            'Taux de vitalité / taux vibratoire sur photo',
            'Corps énergétiques sur photo',
            'Contrôle des 7 chakras sur la planche',
            'Entités bas astral sur photo',
            'Énergies négatives sur photo',
            'Scan énergétique des organes sur planche anatomique',
            'Qualité énergétique du sang',
          ];

    return Card(
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(Icons.explore_outlined, color: Colors.teal),
        title: const Text('Bilan + scans au pendule', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Les cadrans restent sur papier'),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('Cocher chaque mesure réalisée. Les valeurs et observations peuvent être notées ci-dessous.'),
          ),
          ...scans.map((nom) => CheckboxListTile(
                dense: true,
                value: _scans[nom] ?? false,
                title: Text(nom),
                onChanged: (v) => setState(() => _scans[nom] = v ?? false),
              )),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: TextField(
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Résultats / observations du bilan', alignLabelWithHint: true),
              onChanged: (v) => _observationsScans['bilan'] = v,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareStep(int index, _CareStep step) {
    final done = _etapesFaites.contains(index);
    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(child: Text('${index + 1}')),
        title: Row(
          children: [
            Expanded(child: Text(step.titre, style: const TextStyle(fontWeight: FontWeight.w600))),
            Checkbox(value: done, onChanged: (v) => setState(() => v == true ? _etapesFaites.add(index) : _etapesFaites.remove(index))),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.description),
                if (step.details != null) ...[
                  const SizedBox(height: 12),
                  const Text('Contenu de la FT source', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 420),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SingleChildScrollView(child: SelectableText(step.details!)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBibliotheque() {
    final q = _recherche.trim().toLowerCase();
    final fiches = _fichesTechniques.where((f) => f.titre.toLowerCase().contains(q)).toList();
    final refs = _references.where((f) => f.titre.toLowerCase().contains(q)).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 30),
      children: [
        TextField(
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Rechercher une fiche'),
          onChanged: (v) => setState(() => _recherche = v),
        ),
        const SizedBox(height: 12),
        const Text('Fiches techniques', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        ...fiches.map((f) => _ficheTile(f, true)),
        const SizedBox(height: 16),
        const Text('Fiches de séance et références', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ...refs.map((f) => _ficheTile(f, false)),
      ],
    );
  }

  Widget _ficheTile(_MagnetismeFiche fiche, bool technique) {
    return Card(
      child: ExpansionTile(
        leading: Icon(technique ? Icons.medical_information_outlined : Icons.menu_book_outlined, color: technique ? Colors.indigo : Colors.teal),
        title: Text(fiche.titre),
        subtitle: Text(fiche.source, maxLines: 1, overflow: TextOverflow.ellipsis),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(fiche.contenu),
                if (technique) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        setState(() {
                          _pathologie = fiche.titre;
                          _ficheGeneree = false;
                        });
                        DefaultTabController.of(context).animateTo(0);
                      },
                      icon: const Icon(Icons.playlist_add_check),
                      label: const Text('Utiliser cette FT pour un soin'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MagnetismeFiche {
  final String id;
  final String titre;
  final String source;
  final String type;
  final String contenu;

  const _MagnetismeFiche({required this.id, required this.titre, required this.source, required this.type, required this.contenu});

  factory _MagnetismeFiche.fromJson(Map<String, dynamic> json) => _MagnetismeFiche(
        id: '${json['id'] ?? ''}',
        titre: '${json['titre'] ?? ''}',
        source: '${json['source'] ?? ''}',
        type: '${json['type'] ?? ''}',
        contenu: '${json['contenu'] ?? ''}',
      );
}

class _CareStep {
  final String titre;
  final String description;
  final String? details;

  const _CareStep(this.titre, this.description, {this.details});
}
