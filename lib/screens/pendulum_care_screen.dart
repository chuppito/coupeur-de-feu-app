import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../services/pendulum_care_service.dart';
import '../services/magnetisme_library_service.dart';

class PendulumCareScreen extends StatefulWidget {
  final String prefillNom;
  final String prefillNomFamille;

  const PendulumCareScreen({
    super.key,
    this.prefillNom = '',
    this.prefillNomFamille = '',
  });
  
  @override
  State<PendulumCareScreen> createState() => _PendulumCareScreenState();
}

class _PendulumCareScreenState extends State<PendulumCareScreen> {
  final _zone = TextEditingController();
  final _notes = TextEditingController();
  final _ressenti = TextEditingController();
  bool _saving = false;
  String _priereFeu = 'Prière contre le feu indisponible dans la bibliothèque.';
  final List<bool> _steps = List<bool>.filled(9, false);

  static const _stepTitles = [
    '20 passes rapides',
    'Prendre le pendule : intention de dégagement, rotation négative',
    'Lever le pendule lorsque le mouvement négatif est terminé',
    'Taper 2 fois pour retirer le négatif',
    '15 passes lentes',
    'Rotation positive du pendule : intention de soulager la zone',
    'Prière contre le feu × 3',
    'Formulation de dégagement',
    'Formulation de protection et de renforcement',
  ];

  static const _degagement = 'Je demande ici et maintenant que « {patient} » soit libéré(e) de toutes les énergies qui ne lui appartiennent pas.\nQue les pensées négatives, les projections et les influences d’autrui soient dissoutes et renvoyées à la terre pour être transformées. Je ferme son champ énergétique à ce qui n’est pas aligné avec sa paix intérieure.\nIl récupère ainsi sa pleine souveraineté, sa clarté et sa sérénité. Que seul l’amour et la bienveillance puissent franchir cet espace. Ainsi soit-il.';
  static const _protection = 'Je demande que « {patient} » soit entouré(e) d’une lumière de force et de protection.\nQue son énergie vitale soit maintenant restaurée, vibrante et alignée. Je renforce ses propres barrières naturelles pour que son espace personnel reste pur et inattaquable par les influences extérieures.\nDésormais « {patient} » est ancré(e), centré(e), et protégé(e). Que cette lumière rayonne depuis son cœur vers l’extérieur, transformant chaque obstacle en force. Il marche en toute sécurité, porté(e) par sa propre puissance intérieure.';

  Future<void> _chargerPriereFeu() async {
    try {
      final docs = await MagnetismeLibraryService.loadAll();
      final matches = docs.where((e) =>
          (e['type'] ?? '').toString() == 'priere' &&
          (e['titre'] ?? '').toString().trim().toUpperCase().contains('CONTRE LE FEU'));
      if (matches.isNotEmpty && mounted) {
        setState(() => _priereFeu = (matches.first['contenu'] ?? '').toString().trim());
      }
    } catch (_) {
      // Le protocole reste utilisable même si la bibliothèque n'est pas disponible.
    }
  }

  @override
  void initState() {
    super.initState();
    _chargerPriereFeu();
  }

  @override
  void dispose() { _zone.dispose(); _notes.dispose(); _ressenti.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    await PendulumCareService.save({
      'nomPatient': widget.prefillNom.trim(),
      'nomFamille': widget.prefillNomFamille.trim(),
      'date': DateTime.now().toIso8601String(),
      'zone': _zone.text.trim(),
      'etapes': List<bool>.from(_steps),
      'notes': _notes.text.trim(),
      'ressenti': _ressenti.text.trim(),
    });
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Soin au pendule enregistré.')));
    _zone.clear(); _notes.clear(); _ressenti.clear();
    setState(() { for (var i = 0; i < _steps.length; i++) { _steps[i] = false; } });
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.prefillNomFamille.trim().isEmpty
        ? widget.prefillNom.trim()
        : '${widget.prefillNom.trim()} ${widget.prefillNomFamille.trim()}';
    final nomAffiche = patient.isEmpty ? '[Prénom NOM]' : patient;
    final degagement = _degagement.replaceAll('{patient}', nomAffiche);
    final protection = _protection.replaceAll('{patient}', nomAffiche);
    return Scaffold(
      appBar: AppBar(title: const Text('Soin au pendule')),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(12), children: [
        Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(patient, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4), Text('Date du soin : ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}'),
          const SizedBox(height: 6), const Text('Protocole personnel de pratique au pendule. Ne remplace pas un avis ou un soin médical.', style: TextStyle(fontSize: 12, color: Colors.black54)),
        ]))),
        TextField(controller: _zone, decoration: const InputDecoration(labelText: 'Zone à travailler / intention')),
        const SizedBox(height: 10),
        _header('PROTOCOLE AU PENDULE', Colors.deepOrange.shade100),
        Card(child: Column(children: List.generate(_stepTitles.length, (i) {
          final details = <String?>[
            null,
            'Rotation négative du pendule. Formule : « Je veux retirer les énergies négatives de… »',
            null,
            'Rappel systématique : 2 frappes après avoir levé le pendule.',
            null,
            'Relancer dans le sens positif en gardant l’intention de soulager la zone.',
            _priereFeu,
            degagement,
            protection,
          ];
          return CheckboxListTile(
            value: _steps[i],
            onChanged: (v) => setState(() => _steps[i] = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(_stepTitles[i]),
            subtitle: details[i] == null ? null : Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SelectableText(details[i]!,
                  style: const TextStyle(height: 1.5)),
            ),
          );
        }).toList())),
        _header('OBSERVATIONS', Colors.blueGrey.shade100),
        TextField(controller: _ressenti, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Ressenti du patient (facultatif)', alignLabelWithHint: true)),
        const SizedBox(height: 8),
        TextField(controller: _notes, minLines: 3, maxLines: 6, decoration: const InputDecoration(labelText: 'Notes / observations', alignLabelWithHint: true)),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: _saving ? null : _save, icon: const Icon(Icons.save_outlined), label: Text(_saving ? 'Enregistrement…' : 'Enregistrer le soin')),
        const SizedBox(height: 18),
        Text('Historique des soins', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        ValueListenableBuilder<Box>(valueListenable: PendulumCareService.listenable(), builder: (context, box, _) {
          final entries = PendulumCareService.getForPatient(patient);
          if (entries.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(14), child: Text('Aucun soin enregistré pour ce patient.')));
          return Column(children: entries.map((entry) {
            final key = entry['_hiveKey'];
            final date = DateTime.tryParse((entry['date'] ?? '').toString());
            return Card(child: ExpansionTile(
              leading: const Icon(Icons.spa_outlined, color: Colors.deepOrange),
              title: Text(date == null ? 'Soin enregistré' : DateFormat('dd/MM/yyyy à HH:mm').format(date)),
              subtitle: Text((entry['zone'] ?? '').toString().isEmpty ? 'Zone non précisée' : 'Zone : ${entry['zone']}'),
              children: [
                if ((entry['ressenti'] ?? '').toString().trim().isNotEmpty) ListTile(title: const Text('Ressenti'), subtitle: Text(entry['ressenti'].toString())),
                if ((entry['notes'] ?? '').toString().trim().isNotEmpty) ListTile(title: const Text('Notes'), subtitle: Text(entry['notes'].toString())),
                Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: key == null ? null : () => PendulumCareService.deleteByKey(key), icon: const Icon(Icons.delete_outline, color: Colors.red), label: const Text('Supprimer', style: TextStyle(color: Colors.red)))),
              ],
            ));
          }).toList());
        }),
      ])),
    );
  }

  Widget _header(String title, Color color) => Container(width: double.infinity, margin: const EdgeInsets.only(top: 12, bottom: 4), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color, border: Border.all(color: Colors.black12)), child: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)));

  Widget _reminder(String title, String text) => Card(color: Colors.amber.shade50, child: ExpansionTile(leading: const Icon(Icons.lightbulb_outline, color: Colors.brown), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: const Text('Appuie pour afficher le rappel'), children: [Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 12), child: SelectableText(text))]));
}
