import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../models/cadran.dart';
import '../services/cadran_service.dart';
import '../widgets/planche_eventail.dart';
import 'cadran_fullscreen_screen.dart';

/// Bibliothèque de cadrans de radiesthésie : pré-remplie par défaut (voir
/// cadran_service.dart), et enrichissable par l'utilisateur. Deux façons
/// d'ajouter un cadran : importer une image, ou créer un éventail (texte)
/// dessiné nativement.
class PenduleScreen extends StatelessWidget {
  const PenduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pendule")),
      body: ValueListenableBuilder<Box<Cadran>>(
        valueListenable: CadranService.listenable(),
        builder: (context, box, _) {
          final cadrans = CadranService.getAll();

          if (cadrans.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.explore_outlined, size: 48, color: Colors.black26),
                    const SizedBox(height: 12),
                    const Text(
                      "Aucun cadran pour le moment. Touchez + pour en importer un "
                      "(image) ou en créer un (liste de libellés).",
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: cadrans.length,
            itemBuilder: (context, index) => _TuileCadran(cadran: cadrans[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _choisirTypeAjout(context),
        tooltip: "Ajouter un cadran",
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _choisirTypeAjout(BuildContext context) async {
    final choix = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_photo_alternate_outlined),
              title: const Text("Importer une image"),
              subtitle: const Text("Une planche dont vous avez les droits, ou dessinée par vous"),
              onTap: () => Navigator.pop(context, 'image'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text("Créer un éventail"),
              subtitle: const Text("Vous tapez la liste des libellés, l'app dessine le cadran"),
              onTap: () => Navigator.pop(context, 'eventail'),
            ),
          ],
        ),
      ),
    );

    if (choix == 'image' && context.mounted) {
      await _ajouterImage(context);
    } else if (choix == 'eventail' && context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FormulaireEventail()),
      );
    }
  }

  Future<void> _ajouterImage(BuildContext context) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (image == null || !context.mounted) return;

    final titreController = TextEditingController();
    final titre = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nom du cadran"),
        content: TextField(
          controller: titreController,
          autofocus: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: "Ex : Oui/Non, Échelle 0-100...",
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          TextButton(
            onPressed: () => Navigator.pop(context, titreController.text.trim()),
            child: const Text("Ajouter"),
          ),
        ],
      ),
    );

    if (titre == null || titre.isEmpty) return;
    await CadranService.add(titre: titre, sourceImage: File(image.path));
  }
}

class _TuileCadran extends StatelessWidget {
  final Cadran cadran;
  const _TuileCadran({required this.cadran});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CadranFullscreenScreen(cadran: cadran)),
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Expanded(
              child: cadran.type == 'eventail'
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: 220,
                          child: PlancheEventail(titre: "", labels: cadran.labels ?? const [], groupes: cadran.groupes),
                        ),
                      ),
                    )
                  : Image.file(File(cadran.cheminImage), fit: BoxFit.cover, width: double.infinity),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(
                cadran.titre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Formulaire de création/modification d'un cadran en éventail : titre +
/// liste de libellés + groupes optionnels (anneau extérieur) + attribution
/// (à remplir si la licence de la source l'exige, ex: CC BY). Passer un
/// `cadran` existant pour l'éditer au lieu d'en créer un nouveau.
class FormulaireEventail extends StatefulWidget {
  final Cadran? cadran;
  const FormulaireEventail({super.key, this.cadran});

  @override
  State<FormulaireEventail> createState() => _FormulaireEventailState();
}

class _FormulaireEventailState extends State<FormulaireEventail> {
  final _titreController = TextEditingController();
  final _attributionController = TextEditingController();
  final _labelController = TextEditingController();
  final _groupeController = TextEditingController();
  final List<String> _labels = [];
  final List<String> _groupes = [];

  bool get _enEdition => widget.cadran != null;

  @override
  void initState() {
    super.initState();
    _titreController.addListener(() => setState(() {}));
    if (widget.cadran != null) {
      _titreController.text = widget.cadran!.titre;
      _attributionController.text = widget.cadran!.attribution ?? '';
      _labels.addAll(widget.cadran!.labels ?? const []);
      _groupes.addAll(widget.cadran!.groupes ?? const []);
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    _attributionController.dispose();
    _labelController.dispose();
    _groupeController.dispose();
    super.dispose();
  }

  void _ajouterLabel() {
    final texte = _labelController.text.trim();
    if (texte.isEmpty) return;
    setState(() {
      _labels.add(texte);
      _labelController.clear();
    });
  }

  void _ajouterGroupe() {
    final texte = _groupeController.text.trim();
    if (texte.isEmpty) return;
    setState(() {
      _groupes.add(texte);
      _groupeController.clear();
    });
  }

  Future<void> _enregistrer() async {
    final titre = _titreController.text.trim();
    if (titre.isEmpty || _labels.length < 2) return;
    final attribution = _attributionController.text.trim().isEmpty ? null : _attributionController.text.trim();
    final groupes = _groupes.isEmpty ? null : List.of(_groupes);

    if (_enEdition) {
      await CadranService.updateEventail(
        widget.cadran!,
        titre: titre,
        labels: List.of(_labels),
        attribution: attribution,
        groupes: groupes,
      );
    } else {
      await CadranService.addEventail(
        titre: titre,
        labels: List.of(_labels),
        attribution: attribution,
        groupes: groupes,
      );
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_enEdition ? "Modifier le cadran" : "Nouveau cadran (éventail)")),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Nom du cadran :", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _titreController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Ex : Augmenter le taux vibratoire",
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text("Libellés des secteurs (dans l'ordre, de gauche à droite) :",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _labelController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: "Ex : Lâcher prise",
                              isDense: true,
                            ),
                            onSubmitted: (_) => _ajouterLabel(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _ajouterLabel,
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_labels.isEmpty)
                      const Text("Aucun libellé ajouté pour l'instant (2 minimum).",
                          style: TextStyle(color: Colors.black45, fontSize: 12)),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (int i = 0; i < _labels.length; i++)
                          Chip(
                            label: Text(_labels[i]),
                            onDeleted: () => setState(() => _labels.removeAt(i)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text("Anneau extérieur / groupes (optionnel) :", style: TextStyle(fontWeight: FontWeight.bold)),
                    const Text(
                      "Ex : les mois autour des jours, ou Oui/Non autour des raisons. Divisions égales, "
                      "indépendantes du nombre de libellés ci-dessus.",
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _groupeController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: "Ex : Janvier",
                              isDense: true,
                            ),
                            onSubmitted: (_) => _ajouterGroupe(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _ajouterGroupe,
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (int i = 0; i < _groupes.length; i++)
                          Chip(
                            label: Text(_groupes[i]),
                            onDeleted: () => setState(() => _groupes.removeAt(i)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text("Source / attribution (optionnel) :", style: TextStyle(fontWeight: FontWeight.bold)),
                    const Text(
                      "À remplir si vous reprenez le contenu d'une planche existante dont la licence "
                      "exige de citer l'auteur (ex: Creative Commons CC BY).",
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _attributionController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Ex : Cadran partagé par ... sur ... — Licence CC BY-NC 4.0",
                      ),
                    ),
                    if (_labels.length >= 2) ...[
                      const SizedBox(height: 24),
                      const Text("Aperçu :", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      PlancheEventail(
                        titre: _titreController.text.trim().isEmpty ? "Aperçu" : _titreController.text.trim(),
                        labels: _labels,
                        groupes: _groupes.isEmpty ? null : _groupes,
                        attribution: _attributionController.text.trim().isEmpty
                            ? null
                            : _attributionController.text.trim(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _labels.length >= 2 && _titreController.text.trim().isNotEmpty ? _enregistrer : null,
                  child: Text(_enEdition ? "Mettre à jour" : "Enregistrer"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
