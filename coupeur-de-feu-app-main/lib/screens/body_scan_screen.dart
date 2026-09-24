import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../services/body_scan_service.dart';

class BodyScanScreen extends StatefulWidget {
  final String? prefillNom;
  final String? prefillNomFamille;

  const BodyScanScreen({
    super.key,
    this.prefillNom,
    this.prefillNomFamille,
  });

  @override
  State<BodyScanScreen> createState() => _BodyScanScreenState();
}

class _BodyScanZone {
  final String titre;
  final String question;
  final IconData icon;
  const _BodyScanZone(this.titre, this.question, this.icon);
}

class _BodyScanScreenState extends State<BodyScanScreen> {
  static const _zones = [
    _BodyScanZone('Tête et cou', 'Y a-t-il un point de tension au niveau de la tête et du cou ?', Icons.face),
    _BodyScanZone('Colonne vertébrale', 'Y a-t-il un point de tension sur ou autour de la colonne ?', Icons.accessibility_new),
    _BodyScanZone('Tronc — côté gauche', 'Y a-t-il un point de tension sur le côté gauche du tronc ?', Icons.favorite_border),
    _BodyScanZone('Tronc — côté droit', 'Y a-t-il un point de tension sur le côté droit du tronc ?', Icons.favorite_border),
    _BodyScanZone('Bras gauche', 'Y a-t-il un point de tension dans le bras gauche ?', Icons.back_hand_outlined),
    _BodyScanZone('Bras droit', 'Y a-t-il un point de tension dans le bras droit ?', Icons.back_hand_outlined),
    _BodyScanZone('Jambe gauche', 'Y a-t-il un point de tension dans la jambe gauche ?', Icons.directions_walk),
    _BodyScanZone('Jambe droite', 'Y a-t-il un point de tension dans la jambe droite ?', Icons.directions_walk),
  ];

  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _observationController = TextEditingController();

  final Map<String, String> _resultats = {};
  final Map<String, TextEditingController> _notes = {};

  @override
  void initState() {
    super.initState();
    _prenomController.text = widget.prefillNom ?? '';
    _nomController.text = widget.prefillNomFamille ?? '';
    for (final z in _zones) {
      _notes[z.titre] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _observationController.dispose();
    for (final c in _notes.values) {
      c.dispose();
    }
    super.dispose();
  }

  int get _scannees => _resultats.length;

  Future<void> _enregistrer() async {
    final prenom = _prenomController.text.trim();
    if (prenom.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indiquez au minimum le prénom du patient.')),
      );
      return;
    }
    if (_resultats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scannez au moins une zone avant d’enregistrer.')),
      );
      return;
    }

    final zones = _resultats.entries.map((e) => {
      'zone': e.key,
      'resultat': e.value,
      'observation': _notes[e.key]?.text.trim() ?? '',
    }).toList();

    await BodyScanService.saveScan(
      nomPatient: prenom,
      nomFamille: _nomController.text,
      zones: zones,
      observation: _observationController.text,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scan du corps enregistré.')),
    );
    setState(() {
      _resultats.clear();
      for (final c in _notes.values) {
        c.clear();
      }
      _observationController.clear();
    });
  }

  Future<void> _choisirResultat(_BodyScanZone zone) async {
    final choix = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle_outline, color: Colors.green),
              title: const Text('RAS / pendule reste neutre'),
              onTap: () => Navigator.pop(context, 'RAS'),
            ),
            ListTile(
              leading: const Icon(Icons.trending_flat),
              title: const Text('Légère orientation vers le Oui'),
              onTap: () => Navigator.pop(context, 'Orientation Oui'),
            ),
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('Rotation vers le Oui'),
              onTap: () => Navigator.pop(context, 'Rotation Oui'),
            ),
          ],
        ),
      ),
    );
    if (choix != null) {
      setState(() => _resultats[zone.titre] = choix);
    }
  }

  String _nomComplet() {
    final p = _prenomController.text.trim();
    final n = _nomController.text.trim();
    return n.isEmpty ? p : '$p $n';
  }

  @override
  Widget build(BuildContext context) {
    final couleur = Colors.teal;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan du corps au pendule'),
        actions: [
          IconButton(
            tooltip: 'Enregistrer le scan',
            onPressed: _enregistrer,
            icon: const Icon(Icons.save_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: couleur.withValues(alpha: 0.08),
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.info_outline, color: Colors.teal),
                        SizedBox(width: 8),
                        Expanded(child: Text('Méthode du scan', style: TextStyle(fontWeight: FontWeight.bold))),
                      ]),
                      SizedBox(height: 8),
                      Text(
                        'La personne reste allongée sur le dos. Pour chaque zone, '
                        'faites votre mouvement neutre habituel, formulez votre question, '
                        'puis déplacez le pendule progressivement. Enregistrez uniquement '
                        'ce que vous observez.',
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Les résultats ci-dessous sont des observations de radiesthésie '
                        'et ne constituent pas un diagnostic médical.',
                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('Patient', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _prenomController,
                decoration: const InputDecoration(labelText: 'Prénom', prefixIcon: Icon(Icons.person_outline)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nomController,
                decoration: const InputDecoration(labelText: 'Nom (optionnel)'),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Zones scannées : $_scannees/${_zones.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton(
                    onPressed: _resultats.isEmpty ? null : () => setState(() {
                      _resultats.clear();
                      for (final c in _notes.values) c.clear();
                    }),
                    child: const Text('Réinitialiser'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              for (final zone in _zones) _buildZone(zone),
              const SizedBox(height: 12),
              Text('Observations générales', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _observationController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Notes complémentaires…',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _enregistrer,
                  icon: const Icon(Icons.save),
                  label: const Text('Enregistrer le scan'),
                ),
              ),
              if (widget.prefillNom != null && widget.prefillNom!.trim().isNotEmpty) ...[
                const SizedBox(height: 28),
                Text('Derniers scans de ${_nomComplet()}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _historiquePatient(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZone(_BodyScanZone zone) {
    final resultat = _resultats[zone.titre];
    final couleur = resultat == null
        ? Colors.grey
        : resultat == 'RAS'
            ? Colors.green
            : Colors.orange;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: couleur.withValues(alpha: 0.12),
                foregroundColor: couleur,
                child: Icon(zone.icon),
              ),
              title: Text(zone.titre, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(resultat ?? 'À scanner'),
              trailing: FilledButton.tonal(
                onPressed: () => _choisirResultat(zone),
                child: Text(resultat == null ? 'Scanner' : 'Modifier'),
              ),
            ),
            if (resultat != null)
              TextField(
                controller: _notes[zone.titre],
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Localisation / remarque',
                  hintText: 'Ex. lombaires, gorge, genou…',
                ),
              ),
            if (resultat == null)
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    zone.question,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _historiquePatient() {
    final nom = _nomComplet();
    return ValueListenableBuilder<Box>(
      valueListenable: BodyScanService.listenable(),
      builder: (context, box, _) {
        final scans = BodyScanService.getScans(nomComplet: nom);
        if (scans.isEmpty) return const Text('Aucun scan enregistré.');
        return Column(
          children: scans.take(5).map((scan) {
            final date = DateTime.tryParse(scan['date'].toString());
            final zones = (scan['zones'] as List?)?.length ?? 0;
            return Card(
              child: ListTile(
                leading: const Icon(Icons.accessibility_new, color: Colors.teal),
                title: Text(date == null ? 'Scan' : DateFormat('dd/MM/yyyy à HH:mm').format(date)),
                subtitle: Text('$zones zone(s) enregistrée(s)'),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
