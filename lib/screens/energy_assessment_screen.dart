import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../services/energy_assessment_service.dart';

class EnergyAssessmentScreen extends StatefulWidget {
  final String prefillNom;
  final String prefillNomFamille;
  const EnergyAssessmentScreen({super.key, required this.prefillNom, this.prefillNomFamille = ''});

  @override
  State<EnergyAssessmentScreen> createState() => _EnergyAssessmentScreenState();
}

class _EnergyAssessmentScreenState extends State<EnergyAssessmentScreen> {
  final _vitalite = TextEditingController();
  final _vibratoire = TextEditingController();
  final _entite = TextEditingController();
  final _energieNegative = TextEditingController();
  final _notes = TextEditingController();
  final Map<String, String?> _chakras = {for (final c in _chakraNames) c: null};
  bool _saving = false;

  static const _chakraNames = [
    'Chakra racine', 'Chakra sacré', 'Chakra plexus solaire', 'Chakra cœur',
    'Chakra gorge', 'Chakra 3ᵉ œil', 'Chakra couronne',
  ];
  static const _chakraChoices = [
    'Déficience — G (grave)', 'Déficience — I (importante)', 'Déficience — F (faible)',
    'Équilibre', 'Excès — G (grave)', 'Excès — I (important)', 'Excès — F (faible)',
  ];

  @override
  void dispose() {
    _vitalite.dispose(); _vibratoire.dispose(); _entite.dispose();
    _energieNegative.dispose(); _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    await EnergyAssessmentService.save({
      'nomPatient': widget.prefillNom.trim(), 'nomFamille': widget.prefillNomFamille.trim(),
      'date': DateTime.now().toIso8601String(),
      'tauxVitalite': _vitalite.text.trim(), 'tauxVibratoire': _vibratoire.text.trim(),
      'chakras': Map<String, String?>.from(_chakras),
      'entiteBasAstral': _entite.text.trim(), 'energieNegative': _energieNegative.text.trim(),
      'notes': _notes.text.trim(),
    });
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bilan énergétique enregistré.')));
    _vitalite.clear(); _vibratoire.clear(); _entite.clear(); _energieNegative.clear(); _notes.clear();
    setState(() { for (final key in _chakras.keys.toList()) { _chakras[key] = null; } });
  }

  @override
  Widget build(BuildContext context) {
    final nomComplet = widget.prefillNomFamille.trim().isEmpty
        ? widget.prefillNom : '${widget.prefillNom} ${widget.prefillNomFamille.trim()}';
    return Scaffold(
      appBar: AppBar(title: const Text('Bilan énergétique au pendule')),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(12), children: [
        Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(nomComplet, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4), Text("Date du bilan : ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}"),
          const SizedBox(height: 6), const Text('Bilan de pratique au pendule — les indications ci-dessous reprennent tes notes personnelles et ne constituent pas une évaluation médicale.', style: TextStyle(fontSize: 12, color: Colors.black54)),
        ]))),
        _sectionHeader('CONTRÔLE DES TAUX', Colors.lightBlue.shade200),
        _reminder(
  'Rappel — taux de vitalité',
  "Repère du cadran : 0 à 100. Tes notes manuscrites mentionnent « 70 et + », des repères sous 70, au-dessus de 50 et de 0 à 30. Ce sont des interprétations personnelles au pendule, non validées médicalement et ne permettant pas d'établir un diagnostic.",
  'assets/cadrans/bilan_taux_vitalite.png',
), _numberField('Taux de vitalité (0 à 100)', _vitalite, hint: 'Valeur relevée au cadran'),
        _reminder('Rappel — taux vibratoire', 'Tes notes : mesure physique (corps humain), énergétique, mentale et spirituelle. 1ʳᵉ mesure : 0 à 10 000 sur le plan physique ; 2ᵉ mesure : globale si la mesure dépasse 10 000. Note personnelle : comparer au taux de vitalité × 100.', 'assets/cadrans/bilan_taux_vibratoire.png'),
        _numberField('Taux vibratoire', _vibratoire, hint: 'Valeur relevée au cadran'),
        _sectionHeader('CONTRÔLE DES CHAKRAS', Colors.deepPurple.shade100),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            "Coche le résultat correspondant pour chaque chakra. Repère de tes notes : gauche = déficience ; droite = excès. G = grave, I = importante, F = faible.",
            style: TextStyle(fontSize: 13),
          ),
        ),
        _reminder('Rappel — test des chakras', 'Utilise ton schéma papier des 7 chakras. Repère noté dans tes consignes : côté gauche pour la déficience, côté droit pour l’excès.', 'assets/cadrans/bilan_tests_chakras.png'),
        Card(child: Column(children: _chakraNames.map((name) => Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 6),
          DropdownButtonFormField<String>(value: _chakras[name], isExpanded: true, decoration: const InputDecoration(labelText: 'Résultat', isDense: true), items: _chakraChoices.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(), onChanged: (v) => setState(() => _chakras[name] = v)),
        ]))).toList())),
        _sectionHeader('CONTRÔLE DES PARASITAGES', Colors.lightGreen.shade200),
        _reminder('Rappel — entités bas astral', 'Le cadran fourni présente une échelle de 0 à 10, avec les repères « seuil de vigilance » et « entité — novice à halo ». Utilise le cadran papier pour effectuer ta mesure.', 'assets/cadrans/bilan_entite_bas_astral.png'),
        _numberField('Entités bas astral — résultat (0 à 10)', _entite, hint: 'Résultat au cadran'),
        _reminder('Rappel — énergies négatives / magie noire', 'Le cadran fourni présente une échelle de 0 à 10, avec les repères « seuil de vigilance » et « magie noire — novice à novice + ». Utilise le cadran papier pour effectuer ta mesure.', 'assets/cadrans/bilan_energie_negative.png'),
        _numberField('Énergies négatives — résultat (0 à 10)', _energieNegative, hint: 'Résultat au cadran'),
        _sectionHeader('NOTES ET CONCLUSION', Colors.blueGrey.shade100),
        TextField(controller: _notes, minLines: 3, maxLines: 7, decoration: const InputDecoration(labelText: 'Notes / conclusion', alignLabelWithHint: true)),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: _saving ? null : _save, icon: const Icon(Icons.save_outlined), label: Text(_saving ? 'Enregistrement…' : 'Enregistrer le bilan')),
        const SizedBox(height: 20),
        Text('Historique des bilans', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        ValueListenableBuilder<Box>(valueListenable: EnergyAssessmentService.listenable(), builder: (context, box, _) {
          final entries = EnergyAssessmentService.getForPatient(nomComplet);
          if (entries.isEmpty) return const Card(child: Padding(padding: EdgeInsets.all(14), child: Text('Aucun bilan enregistré pour ce patient.')));
          return Column(children: entries.map((entry) {
            final key = entry['_hiveKey'];
            final date = DateTime.tryParse((entry['date'] ?? '').toString());
            final chakras = entry['chakras'] is Map ? Map<String, dynamic>.from(entry['chakras'] as Map) : <String, dynamic>{};
            return Card(child: ExpansionTile(leading: const Icon(Icons.monitor_heart_outlined, color: Colors.teal), title: Text(date == null ? 'Bilan enregistré' : DateFormat('dd/MM/yyyy à HH:mm').format(date)), subtitle: Text('Vitalité : ${_display(entry['tauxVitalite'])}  •  Vibratoire : ${_display(entry['tauxVibratoire'])}'), children: [
              ...chakras.entries.where((e) => e.value != null && e.value.toString().isNotEmpty).map((e) => ListTile(dense: true, title: Text(e.key), subtitle: Text(e.value.toString()))),
              if (_display(entry['entiteBasAstral']).isNotEmpty) ListTile(dense: true, title: const Text('Entités bas astral'), subtitle: Text(_display(entry['entiteBasAstral']))),
              if (_display(entry['energieNegative']).isNotEmpty) ListTile(dense: true, title: const Text('Énergies négatives'), subtitle: Text(_display(entry['energieNegative']))),
              if (_display(entry['notes']).isNotEmpty) ListTile(dense: true, title: const Text('Notes'), subtitle: Text(_display(entry['notes']))),
              Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: key == null ? null : () => EnergyAssessmentService.deleteByKey(key), icon: const Icon(Icons.delete_outline, color: Colors.red), label: const Text('Supprimer', style: TextStyle(color: Colors.red)))),
            ]));
          }).toList());
        }),
      ])),
    );
  }

  String _display(dynamic value) => (value ?? '').toString();

  Widget _sectionHeader(String title, Color color) => Container(width: double.infinity, margin: const EdgeInsets.only(top: 12, bottom: 4), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color, border: Border.all(color: Colors.black12)), child: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)));

  Widget _numberField(String label, TextEditingController controller, {String? hint}) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: label, hintText: hint)));

  Widget _reminder(String title, String text, String asset) => Card(color: Colors.amber.shade50, child: ExpansionTile(leading: const Icon(Icons.lightbulb_outline, color: Colors.brown), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: const Text('Appuie pour afficher le rappel et le cadran'), children: [Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(text, style: const TextStyle(fontSize: 13)), const SizedBox(height: 10), ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.asset(asset, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Text('Cadran indisponible.')))]))]));
}
