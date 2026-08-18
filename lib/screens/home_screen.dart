import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/symbolique_data.dart';
import '../models/protocole.dart';
import '../services/history_service.dart';
import '../services/protocole_service.dart';
import '../widgets/interactive_body.dart';
import 'history_screen.dart';
import 'protocoles_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? prefillNom;
  final String? prefillNomFamille;
  const HomeScreen({super.key, this.prefillNom, this.prefillNomFamille});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedMaladie;
  final Set<String> _selectedZones = {};
  late TextEditingController _nomController;
  late TextEditingController _nomFamilleController;
  bool _avantRenseigne = false;
  double _intensiteAvant = 5;
  bool _apresRenseigne = false;
  double _intensiteApres = 5;
  Protocole? _selectedProtocole;

  /// Couleur distinctive pour tout ce qui touche au magnétisme, afin de
  /// bien le séparer visuellement de la partie symbolique "coupeur de feu".
  static const MaterialColor _couleurMagnetisme = Colors.indigo;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.prefillNom ?? "");
    _nomFamilleController =
        TextEditingController(text: widget.prefillNomFamille ?? "");
  }

  @override
  void dispose() {
    _nomController.dispose();
    _nomFamilleController.dispose();
    super.dispose();
  }

  /// La fiche peut être générée dès qu'il y a un contenu symbolique
  /// (maladie + au moins une zone) OU une technique de magnétisme choisie
  /// (les deux peuvent aussi être combinés, ex: brûlure + magnétisme).
  bool get _peutGenererFiche =>
      (_selectedMaladie != null && _selectedZones.isNotEmpty) || _selectedProtocole != null;

  void _onZoneTap(String zone) {
    setState(() {
      if (_selectedZones.contains(zone)) {
        _selectedZones.remove(zone);
      } else {
        _selectedZones.add(zone);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Coupeur de Feu"),
        actions: [
          IconButton(
            tooltip: "Techniques de magnétisme",
            icon: const Icon(Icons.self_improvement),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProtocolesScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Prénom :", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _nomController,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            const Text("Nom (optionnel, pour distinguer les homonymes) :",
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _nomFamilleController,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            const Text("Problème :", style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              isExpanded: true,
              value: _selectedMaladie,
              hint: const Text("Sélectionnez une pathologie"),
              items: typesMaladie.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (val) => setState(() => _selectedMaladie = val),
            ),
            const SizedBox(height: 20),
            const Text("Zones : touchez le schéma (face ou dos)",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InteractiveBody(
              selectedZones: _selectedZones,
              onZoneTap: _onZoneTap,
            ),
            if (_selectedZones.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: _selectedZones
                    .map((z) => Chip(
                          label: Text(z),
                          onDeleted: () => _onZoneTap(z),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 20),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _avantRenseigne,
              title: Text(
                _avantRenseigne
                    ? "Intensité avant le soin : ${_intensiteAvant.round()}/10"
                    : "Renseigner l'intensité avant le soin",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onChanged: (val) => setState(() => _avantRenseigne = val ?? false),
            ),
            if (_avantRenseigne)
              Slider(
                value: _intensiteAvant,
                min: 0,
                max: 10,
                divisions: 10,
                label: _intensiteAvant.round().toString(),
                onChanged: (val) => setState(() => _intensiteAvant = val),
              ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _apresRenseigne,
              title: Text(
                _apresRenseigne
                    ? "Intensité après le soin : ${_intensiteApres.round()}/10"
                    : "Renseigner l'intensité après le soin",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onChanged: (val) => setState(() => _apresRenseigne = val ?? false),
            ),
            if (_apresRenseigne)
              Slider(
                value: _intensiteApres,
                min: 0,
                max: 10,
                divisions: 10,
                label: _intensiteApres.round().toString(),
                onChanged: (val) => setState(() => _intensiteApres = val),
              ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _couleurMagnetisme.withOpacity(0.08),
                border: Border.all(color: _couleurMagnetisme.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.self_improvement, color: _couleurMagnetisme, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        "Technique de magnétisme (optionnel)",
                        style: TextStyle(fontWeight: FontWeight.bold, color: _couleurMagnetisme.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<Box<Protocole>>(
                    valueListenable: ProtocoleService.listenable(),
                    builder: (context, box, _) {
                      final protocoles = ProtocoleService.getAll();
                      return DropdownButton<Protocole?>(
                        isExpanded: true,
                        value: _selectedProtocole,
                        hint: const Text("Aucune (soin symbolique seul)"),
                        items: [
                          const DropdownMenuItem<Protocole?>(
                            value: null,
                            child: Text("Aucune"),
                          ),
                          ...protocoles.map(
                            (p) => DropdownMenuItem<Protocole?>(value: p, child: Text(p.titre)),
                          ),
                        ],
                        onChanged: (val) => setState(() => _selectedProtocole = val),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _peutGenererFiche ? () => _afficherFiche(context) : null,
                child: const Text("Générer ma fiche"),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  void _afficherFiche(BuildContext context) async {
    String nom = _nomController.text.trim().isEmpty ? "la personne" : _nomController.text.trim();
    String nomFamille = _nomFamilleController.text.trim();
    final bool aSymbolique = _selectedMaladie != null && _selectedZones.isNotEmpty;

    await HistoryService.saveEntry(
      nom,
      _selectedMaladie ?? '',
      _selectedZones.join(', '),
      nomFamille: nomFamille,
      intensiteAvant: _avantRenseigne ? _intensiteAvant.round() : null,
      intensiteApres: _apresRenseigne ? _intensiteApres.round() : null,
      protocoleTitre: _selectedProtocole?.titre,
    );

    if (!context.mounted) return;

    final zonesTriees = _selectedZones.toList()..sort();
    final protocole = _selectedProtocole;
    final titreFiche = aSymbolique
        ? _selectedMaladie!
        : (protocole?.titre ?? "Fiche de soin");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Fiche : $titreFiche"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (aSymbolique) ...[
                const Text("Analyse symbolique :", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                for (final zone in zonesTriees) ...[
                  Text(zone, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(genererSynthese(_selectedMaladie!, zone, nom)),
                  if (intentionsLateralisees[_selectedMaladie]?[zone] != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      "Intention (à dire par le patient) :",
                      style: TextStyle(fontWeight: FontWeight.w600, color: Colors.teal.shade700, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      intentionsLateralisees[_selectedMaladie]![zone]!,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
                const Divider(),
                const Text("Prière de soin :", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text((prieres[_selectedMaladie] ?? "").replaceAll("[NOM]", nom)),
              ],
              if (aSymbolique && protocole != null) const SizedBox(height: 16),
              if (protocole != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _couleurMagnetisme.withOpacity(0.08),
                    border: Border.all(color: _couleurMagnetisme.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.self_improvement, color: _couleurMagnetisme, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "Magnétisme : ${protocole.titre}",
                              style: TextStyle(fontWeight: FontWeight.bold, color: _couleurMagnetisme.shade700),
                            ),
                          ),
                        ],
                      ),
                      if (protocole.priere.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text("Prière :", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(protocole.priere.replaceAll("[NOM]", nom)),
                      ],
                      if (protocole.etapes.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Text("Technique / passes :", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(protocole.etapes),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Fermer"))
        ],
      ),
    );
  }
}
