import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/patient_session.dart';
import '../services/backup_service.dart';
import '../services/history_service.dart';
import 'home_screen.dart';
import 'stats_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _recherche = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historique des soins"),
        actions: [
          IconButton(
            tooltip: "Statistiques",
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const StatsScreen()),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: "Sauvegarde",
            onSelected: (value) {
              if (value == 'export') {
                _exporter(context);
              } else if (value == 'import') {
                _restaurer(context);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'export', child: Text("Exporter une sauvegarde")),
              PopupMenuItem(value: 'import', child: Text("Restaurer une sauvegarde")),
            ],
          ),
        ],
      ),
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
                    return const Center(child: Text("Aucun soin enregistré pour le moment."));
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
                      child: ExpansionTile(
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
                          ListTile(
                            leading: const Icon(Icons.add_circle, color: Colors.blue),
                            title: const Text("Ajouter un nouveau soin"),
                            onTap: () => Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HomeScreen(
                                  prefillNom: entry.value.first.nomPatient,
                                  prefillNomFamille: entry.value.first.nomFamille,
                                ),
                              ),
                              (route) => false,
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
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text("Historique de $nomComplet supprimé."),
                  action: SnackBarAction(
                    label: "Annuler",
                    onPressed: () => HistoryService.restoreSnapshot(snapshot),
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
