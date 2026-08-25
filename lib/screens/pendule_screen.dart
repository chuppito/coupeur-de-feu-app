import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../models/cadran.dart';
import '../services/cadran_service.dart';
import 'cadran_fullscreen_screen.dart';

/// Bibliothèque de cadrans de radiesthésie, entièrement alimentée par
/// l'utilisateur (voir cadran.dart). Chaque cadran s'ouvre en plein écran,
/// avec l'écran maintenu allumé pendant la consultation.
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
                      "Aucun cadran pour le moment. Touchez + pour importer une image "
                      "(une planche que vous avez dessinée ou dont vous avez les droits).",
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
            itemBuilder: (context, index) {
              final cadran = cadrans[index];
              return _TuileCadran(cadran: cadran);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _ajouterCadran(context),
        tooltip: "Importer un cadran",
        child: const Icon(Icons.add_photo_alternate_outlined),
      ),
    );
  }

  Future<void> _ajouterCadran(BuildContext context) async {
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
              child: Image.file(File(cadran.cheminImage), fit: BoxFit.cover, width: double.infinity),
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
