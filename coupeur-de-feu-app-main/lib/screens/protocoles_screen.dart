import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/protocole.dart';
import '../services/backup_service.dart';
import '../services/protocole_service.dart';

/// Bibliothèque de protocoles (prière + technique de passes) entièrement
/// gérable depuis l'app : quelques-uns sont fournis par défaut, et Thomas
/// peut en ajouter, modifier ou supprimer autant qu'il veut via le bouton +.
class ProtocolesScreen extends StatelessWidget {
  const ProtocolesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Techniques de magnétisme"),
        actions: [
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
              PopupMenuItem(value: 'export', child: Text("Exporter mes techniques")),
              PopupMenuItem(value: 'import', child: Text("Restaurer mes techniques")),
            ],
          ),
        ],
      ),
      body: ValueListenableBuilder<Box<Protocole>>(
        valueListenable: ProtocoleService.listenable(),
        builder: (context, box, _) {
          final protocoles = ProtocoleService.getAll();

          if (protocoles.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "Aucune technique enregistrée. Touchez + pour ajouter une prière "
                  "et/ou un protocole de passes.",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 88, top: 8),
            itemCount: protocoles.length,
            itemBuilder: (context, index) {
              final p = protocoles[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ExpansionTile(
                  title: Text(p.titre, style: const TextStyle(fontWeight: FontWeight.bold)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (p.priere.trim().isNotEmpty) ...[
                            const Text("Prière :", style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            SelectableText(p.priere),
                            const SizedBox(height: 12),
                          ],
                          if (p.etapes.trim().isNotEmpty) ...[
                            const Text("Technique / passes :", style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            SelectableText(p.etapes),
                            const SizedBox(height: 12),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.edit, size: 18),
                                label: const Text("Modifier"),
                                onPressed: () => _ouvrirFormulaire(context, protocole: p),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                label: const Text("Supprimer", style: TextStyle(color: Colors.red)),
                                onPressed: () => _confirmerSuppression(context, p),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _ouvrirFormulaire(context),
        tooltip: "Ajouter une technique",
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _exporter(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await BackupService.exportProtocolesAndShare();
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
          "Les fiches du fichier dont le titre existe déjà REMPLACERONT le contenu actuel "
          "(prière/étapes). Les fiches nouvelles seront ajoutées. Rien n'est supprimé.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Restaurer")),
        ],
      ),
    );
    if (confirme != true) return;

    try {
      final nb = await BackupService.importProtocolesFromFile(File(result.files.single.path!));
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text("$nb fiche(s) restaurée(s)/mise(s) à jour.")),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text("Échec de la restauration : $e")),
      );
    }
  }

  void _ouvrirFormulaire(BuildContext context, {Protocole? protocole}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProtocoleFormScreen(protocole: protocole)),
    );
  }

  void _confirmerSuppression(BuildContext context, Protocole p) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Supprimer"),
        content: Text("Supprimer la technique « ${p.titre} » ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          TextButton(
            onPressed: () {
              ProtocoleService.delete(p);
              Navigator.pop(context);
            },
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// Formulaire d'ajout / modification d'une technique.
class ProtocoleFormScreen extends StatefulWidget {
  final Protocole? protocole; // null = création
  const ProtocoleFormScreen({super.key, this.protocole});

  @override
  State<ProtocoleFormScreen> createState() => _ProtocoleFormScreenState();
}

class _ProtocoleFormScreenState extends State<ProtocoleFormScreen> {
  late TextEditingController _titreController;
  late TextEditingController _priereController;
  late TextEditingController _etapesController;

  bool get _estModification => widget.protocole != null;

  @override
  void initState() {
    super.initState();
    _titreController = TextEditingController(text: widget.protocole?.titre ?? '');
    _priereController = TextEditingController(text: widget.protocole?.priere ?? '');
    _etapesController = TextEditingController(text: widget.protocole?.etapes ?? '');
  }

  @override
  void dispose() {
    _titreController.dispose();
    _priereController.dispose();
    _etapesController.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    final titre = _titreController.text.trim();
    if (titre.isEmpty) return;

    if (_estModification) {
      await ProtocoleService.update(
        widget.protocole!,
        titre: titre,
        priere: _priereController.text.trim(),
        etapes: _etapesController.text.trim(),
      );
    } else {
      await ProtocoleService.add(
        titre: titre,
        priere: _priereController.text.trim(),
        etapes: _etapesController.text.trim(),
      );
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_estModification ? "Modifier la technique" : "Nouvelle technique")),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Nom de la technique / pathologie :", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: _titreController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Ex : Tendinite, Migraine...",
                ),
              ),
              const SizedBox(height: 20),
              const Text("Prière (optionnel) :", style: TextStyle(fontWeight: FontWeight.bold)),
              const Text(
                "Astuce : utilisez [NOM] dans le texte, il sera remplacé par le prénom du patient "
                "si vous réutilisez ce texte ailleurs.",
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _priereController,
                maxLines: 8,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              const Text("Technique / protocole de passes (optionnel) :", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: _etapesController,
                maxLines: 10,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Ex : 10 à 20 passes rapides, puis 30s de passes lentes, "
                      "puis imposition 2 min...",
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _enregistrer,
                  child: const Text("Enregistrer"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
