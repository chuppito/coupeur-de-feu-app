import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/patient_session.dart';
import '../services/backup_service.dart';
import '../services/body_scan_service.dart';
import '../services/history_service.dart';
import '../services/energy_assessment_service.dart';
import '../services/pendulum_care_service.dart';
import 'chakras_screen.dart';
import 'body_scan_screen.dart';
import 'energy_assessment_screen.dart';
import 'pendulum_care_screen.dart';
import 'home_screen.dart';
import 'pendule_screen.dart';
import 'protocoles_screen.dart';
import 'magnetisme_screen.dart';
import 'magnetisme_session_screen.dart';
import '../services/magnetisme_session_service.dart';
import 'stats_screen.dart';

/// Écran d'accueil de l'app : liste des patients (recherche, création,
/// historique par patient), avec accès aux bibliothèques de référence
/// (magnétisme, chakras, pendule) et à la sauvegarde depuis le menu latéral.
class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  String _recherche = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes patients"),
        actions: [
          IconButton(
            tooltip: "Nouveau soin",
            icon: const Icon(Icons.local_fire_department),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MagnetismeSessionScreen()),
            ),
          ),
        ],
      ),
      drawer: _MenuLateral(onExporter: () => _exporter(context), onRestaurer: () => _restaurer(context)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: "Rechercher un patient…",
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (val) => setState(() => _recherche = val.trim().toLowerCase()),
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<Box<PatientSession>>(
                valueListenable: HistoryService.listenable(),
                builder: (context, box, _) {
                  final sessions = HistoryService.getHistory();

                  if (sessions.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people_outline, size: 48, color: Colors.black26),
                            const SizedBox(height: 12),
                            const Text(
                              "Aucun patient pour le moment.",
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Touchez la flamme en haut pour créer votre premier soin.",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final grouped = <String, List<PatientSession>>{};
                  for (final s in sessions) {
                    grouped.putIfAbsent(s.nomComplet, () => []).add(s);
                  }

                  var entries = grouped.entries.toList();
                  if (_recherche.isNotEmpty) {
                    entries = entries
                        .where((e) => e.key.toLowerCase().contains(_recherche))
                        .toList();
                  }

                  if (entries.isEmpty) {
                    return const Center(child: Text("Aucun patient ne correspond à la recherche."));
                  }

                  return ListView(
                    padding: const EdgeInsets.only(bottom: 24, top: 8),
                    children: entries.map((entry) => Card(
                      child: Column(
                        children: [
                          ExpansionTile(
                        title: Row(children: [
                          Expanded(child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold))),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () => _showRenameDialog(context, entry.value.first),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                            onPressed: () => _confirmDelete(context, entry.key),
                          ),
                        ]),
                        children: [
                          ...entry.value.map((h) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    IconButton(
                                      tooltip: h.guerie ? "Marquer comme non guéri" : "Marquer comme guéri",
                                      icon: Icon(
                                        h.guerie ? Icons.check_circle : Icons.check_circle_outline,
                                        color: h.guerie ? Colors.green : Colors.grey,
                                      ),
                                      onPressed: () => HistoryService.toggleGuerison(h),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(_titreSeance(h)),
                                          Text(
                                            DateFormat('dd/MM/yyyy à HH:mm').format(h.date),
                                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                                          ),
                                          if (h.protocoleTitre != null && h.protocoleTitre!.trim().isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 2),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.self_improvement, size: 14, color: Colors.indigo),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    "Magnétisme : ${h.protocoleTitre}",
                                                    style: const TextStyle(fontSize: 12, color: Colors.indigo, fontWeight: FontWeight.w600),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          if (h.intensiteAvant != null || h.intensiteApres != null)
                                            Text(
                                              "Intensité : ${_formatIntensite(h.intensiteAvant)} → ${_formatIntensite(h.intensiteApres)}",
                                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                                            ),
                                          if (h.guerie && h.dateGuerison != null)
                                            Text(
                                              "✅ Guéri le ${DateFormat('dd/MM/yyyy à HH:mm').format(h.dateGuerison!)}",
                                              style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600),
                                            ),
                                          if (h.observation.trim().isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Text(
                                                h.observation,
                                                style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: h.observation.trim().isEmpty ? "Ajouter une note" : "Modifier la note",
                                      icon: Icon(
                                        h.observation.trim().isEmpty ? Icons.note_add_outlined : Icons.edit_note,
                                        size: 20,
                                      ),
                                      onPressed: () => _showNoteDialog(context, h),
                                    ),
                                  ],
                                ),
                              )),
                          ValueListenableBuilder<Box>(
                            valueListenable: BodyScanService.listenable(),
                            builder: (context, scanBox, _) {
                              final scans = BodyScanService.getScans(nomComplet: entry.key);
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.accessibility_new, color: Colors.teal),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            "Scans du corps (${scans.length})",
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (scans.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 8),
                                        child: Text(
                                          "Aucun scan enregistré pour ce patient.",
                                          style: TextStyle(fontSize: 12, color: Colors.black54),
                                        ),
                                      )
                                    else
                                      ...scans.map((scan) {
                                        final date = DateTime.tryParse((scan['date'] ?? '').toString());
                                        final zones = (scan['zones'] as List?) ?? const [];
                                        return Card(
                                          margin: const EdgeInsets.only(top: 6),
                                          child: ExpansionTile(
                                            leading: const Icon(Icons.history, color: Colors.teal),
                                            title: Text(
                                              date == null
                                                  ? "Scan enregistré"
                                                  : DateFormat('dd/MM/yyyy à HH:mm').format(date),
                                            ),
                                            subtitle: Text("${zones.length} zone(s) renseignée(s)"),
                                            children: [
                                              ...zones.map((zoneData) {
                                                if (zoneData is! Map) return const SizedBox.shrink();
                                                final zoneNom = (zoneData['zone'] ?? '').toString();
                                                final resultat = (zoneData['resultat'] ?? '').toString();
                                                final remarque = (zoneData['observation'] ?? '').toString();
                                                return ListTile(
                                                  dense: true,
                                                  title: Text(zoneNom),
                                                  subtitle: Text(
                                                    remarque.trim().isEmpty ? resultat : "$resultat\n$remarque",
                                                  ),
                                                );
                                              }),
                                              if ((scan['observation'] ?? '').toString().trim().isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                                  child: Align(
                                                    alignment: Alignment.centerLeft,
                                                    child: Text("Notes : ${scan['observation']}"),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        );
                                      }),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                          ),
                          ValueListenableBuilder<Box>(
                            valueListenable: MagnetismeSessionService.listenable(),
                            builder: (context, magnetismeBox, _) {
                              final sessions = MagnetismeSessionService.getForPatient(entry.key);
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      const Icon(Icons.self_improvement, color: Colors.indigo),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(
                                        "Historique magnétisme (" + sessions.length.toString() + ")",
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      )),
                                    ]),
                                    if (sessions.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 8),
                                        child: Text("Aucune séance de magnétisme V2 enregistrée.",
                                            style: TextStyle(fontSize: 12, color: Colors.black54)),
                                      )
                                    else
                                      ...sessions.map((s) {
                                        final date = DateTime.tryParse((s['date'] ?? '').toString());
                                        final bilan = s['bilan'] is Map ? Map<String,dynamic>.from(s['bilan'] as Map) : <String,dynamic>{};
                                        final chakras = bilan['chakras'] is Map ? Map<String,dynamic>.from(bilan['chakras'] as Map) : <String,dynamic>{};
                                        return Card(
                                          margin: const EdgeInsets.only(top: 6),
                                          child: ExpansionTile(
                                            leading: const Icon(Icons.history, color: Colors.indigo),
                                            title: Text(date == null ? "Séance" : DateFormat('dd/MM/yyyy à HH:mm').format(date)),
                                            subtitle: Text((s['ftTitre'] ?? 'FT non renseignée').toString() + " · " + (s['mode'] ?? '').toString()),
                                            children: [
                                              ListTile(
                                                dense: true,
                                                title: const Text("Déroulé"),
                                                subtitle: Text(((s['etapesFaites'] as List?)?.length ?? 0).toString() + "/" + ((s['etapes'] as List?)?.length ?? 0).toString() + " étapes cochées"),
                                              ),
                                              if ((bilan['vitalite'] ?? '').toString().isNotEmpty)
                                                ListTile(dense: true, title: const Text("Vitalité"), subtitle: Text(bilan['vitalite'].toString())),
                                              if ((bilan['vibratoire'] ?? '').toString().isNotEmpty)
                                                ListTile(dense: true, title: const Text("Taux vibratoire"), subtitle: Text(bilan['vibratoire'].toString())),
                                              if (chakras.isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: chakras.entries.where((e) => (e.value ?? '').toString().isNotEmpty).map(
                                                      (e) => Text(e.key + " : " + e.value.toString()),
                                                    ).toList(),
                                                  ),
                                                ),
                                              for (final key in const ['corpsEnergetiques','entites','energiesNegatives','organesZones','sang','notes'])
                                                if ((bilan[key] ?? '').toString().trim().isNotEmpty)
                                                  ListTile(dense: true, title: Text(_libelleBilan(key)), subtitle: Text(bilan[key].toString())),
                                              if ((s['observations'] ?? '').toString().trim().isNotEmpty)
                                                ListTile(dense: true, title: const Text("Observations"), subtitle: Text(s['observations'].toString())),
                                              if ((s['debrief'] ?? '').toString().trim().isNotEmpty)
                                                ListTile(dense: true, title: const Text("Débrief"), subtitle: Text(s['debrief'].toString())),
                                            ],
                                          ),
                                        );
                                      }),
                                  ],
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.monitor_heart_outlined, color: Colors.deepPurple),
                            title: const Text("Bilan énergétique au pendule"),
                            subtitle: const Text("Créer ou consulter les bilans de ce patient"),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EnergyAssessmentScreen(
                                  prefillNom: entry.value.first.nomPatient,
                                  prefillNomFamille: entry.value.first.nomFamille,
                                ),
                              ),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.self_improvement, color: Colors.indigo),
                            title: const Text("Nouvelle séance magnétisme V2"),
                            subtitle: const Text("FT → protocole → bilan → résultats → historique"),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MagnetismeSessionScreen(
                                  prefillNom: entry.value.first.nomPatient,
                                  prefillNomFamille: entry.value.first.nomFamille,
                                ),
                              ),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.accessibility_new, color: Colors.teal),
                            title: const Text("Scanner le corps au pendule"),
                            subtitle: const Text("Nouveau scan pour ce patient"),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BodyScanScreen(
                                  prefillNom: entry.value.first.nomPatient,
                                  prefillNomFamille: entry.value.first.nomFamille,
                                ),
                              ),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.local_fire_department, color: Colors.deepOrange),
                            title: const Text("Ajouter un nouveau soin"),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HomeScreen(
                                  prefillNom: entry.value.first.nomPatient,
                                  prefillNomFamille: entry.value.first.nomFamille,
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    )).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _libelleBilan(String key) {
    switch (key) {
      case 'corpsEnergetiques': return 'Corps énergétiques';
      case 'entites': return 'Entités';
      case 'energiesNegatives': return 'Énergies négatives';
      case 'organesZones': return 'Organes / zones';
      case 'sang': return 'Qualité énergétique du sang';
      case 'notes': return 'Notes du bilan';
      default: return key;
    }
  }

  String _formatIntensite(int? valeur) => valeur == null ? "non renseigné" : "$valeur/10";

  String _titreSeance(PatientSession h) {
    final aSymbolique = h.maladie.trim().isNotEmpty;
    if (aSymbolique) return "${h.maladie} (${h.zone})";
    return h.protocoleTitre?.trim().isNotEmpty == true
        ? "Soin de magnétisme"
        : "Séance";
  }

  Future<void> _showNoteDialog(BuildContext context, PatientSession session) async {
    TextEditingController controller = TextEditingController(text: session.observation);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Note"),
        content: TextField(
          controller: controller,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Ex : réaction du patient, suivi à prévoir...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          TextButton(
            onPressed: () async {
              await HistoryService.updateObservation(session, controller.text.trim());
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Enregistrer"),
          )
        ],
      ),
    );
  }

  Future<void> _showRenameDialog(BuildContext context, PatientSession reference) async {
    final oldNomComplet = reference.nomComplet;
    TextEditingController prenomController = TextEditingController(text: reference.nomPatient);
    TextEditingController nomController = TextEditingController(text: reference.nomFamille);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Renommer le patient"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: prenomController,
              decoration: const InputDecoration(labelText: "Prénom"),
            ),
            TextField(
              controller: nomController,
              decoration: const InputDecoration(labelText: "Nom (optionnel)"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          TextButton(
            onPressed: () async {
              await HistoryService.renamePatient(
                oldNomComplet,
                prenomController.text.trim(),
                nomController.text.trim(),
              );
              await BodyScanService.renamePatientScans(
                oldNomComplet,
                prenomController.text.trim(),
                nomController.text.trim(),
              );
              await EnergyAssessmentService.renamePatient(
                oldNomComplet, prenomController.text.trim(), nomController.text.trim(),
              );
              await PendulumCareService.renamePatient(
                oldNomComplet, prenomController.text.trim(), nomController.text.trim(),
              );
              await MagnetismeSessionService.renamePatient(
                oldNomComplet, prenomController.text.trim(), nomController.text.trim(),
              );
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Valider"),
          )
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String nomComplet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Supprimer"),
        content: Text("Supprimer tout l'historique de $nomComplet ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final snapshot = await HistoryService.deletePatientAndSnapshot(nomComplet);
              final scansSnapshot = await BodyScanService.deletePatientScans(nomComplet);
              final bilansSnapshot = await EnergyAssessmentService.deletePatient(nomComplet);
              final soinsSnapshot = await PendulumCareService.deletePatient(nomComplet);
              final magnetismeSnapshot = await MagnetismeSessionService.deletePatient(nomComplet);
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text("Historique de $nomComplet supprimé."),
                  action: SnackBarAction(
                    label: "Annuler",
                    onPressed: () async {
                      await HistoryService.restoreSnapshot(snapshot);
                      await BodyScanService.restorePatientScans(scansSnapshot);
                      await EnergyAssessmentService.restore(bilansSnapshot);
                      await PendulumCareService.restore(soinsSnapshot);
                      await MagnetismeSessionService.restore(magnetismeSnapshot);
                    },
                  ),
                  duration: const Duration(seconds: 5),
                ),
              );
            },
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }

  Future<void> _exporter(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await BackupService.exportSessionsAndShare();
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text("Échec de l'export : $e")),
      );
    }
  }

  Future<void> _restaurer(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return;

    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Restaurer une sauvegarde"),
        content: const Text(
          "Les séances contenues dans le fichier seront ajoutées à l'historique actuel "
          "(rien n'est écrasé, mais restaurer deux fois le même fichier créera des doublons).",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Restaurer")),
        ],
      ),
    );
    if (confirme != true) return;

    try {
      final nb = await BackupService.importSessionsFromFile(File(result.files.single.path!));
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text("$nb séance(s) restaurée(s).")),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text("Échec de la restauration : $e")),
      );
    }
  }
}

/// Menu latéral : accès aux bibliothèques de référence (indépendantes d'un
/// patient) et à la sauvegarde des patients.
class _MenuLateral extends StatelessWidget {
  final VoidCallback onExporter;
  final VoidCallback onRestaurer;
  const _MenuLateral({required this.onExporter, required this.onRestaurer});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                "Bibliothèques",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.local_fire_department, color: Colors.deepOrange),
              title: const Text("Nouveau soin"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const MagnetismeScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.self_improvement, color: Colors.indigo),
              title: const Text("Techniques de magnétisme"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProtocolesScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.brightness_7_outlined, color: Colors.deepPurple),
              title: const Text("Les 7 chakras"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ChakrasScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.explore_outlined, color: Colors.teal),
              title: const Text("Pendule"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PenduleScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.self_improvement, color: Colors.indigo),
              title: const Text("Nouvelle séance magnétisme V2"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const MagnetismeSessionScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.accessibility_new, color: Colors.teal),
              title: const Text("Scan du corps au pendule"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const BodyScanScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.monitor_heart_outlined, color: Colors.deepPurple),
              title: const Text("Bilan énergétique au pendule"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const EnergyAssessmentScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.spa_outlined, color: Colors.deepOrange),
              title: const Text("Soin au pendule"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PendulumCareScreen()));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text("Statistiques"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const StatsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: const Text("Exporter mes patients"),
              onTap: () {
                Navigator.pop(context);
                onExporter();
              },
            ),
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text("Restaurer mes patients"),
              onTap: () {
                Navigator.pop(context);
                onRestaurer();
              },
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "Coupeur de Feu · v2.4.0",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.black38),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
