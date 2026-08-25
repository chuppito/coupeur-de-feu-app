import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../models/cadran.dart';

/// Gère la bibliothèque de cadrans de radiesthésie. Voir cadran.dart pour
/// le choix de ne jamais pré-remplir cette bibliothèque (droits d'auteur).
class CadranService {
  static Box<Cadran> get _box => Hive.box<Cadran>('cadrans');

  static ValueListenable<Box<Cadran>> listenable() => _box.listenable();

  static List<Cadran> getAll() {
    final list = _box.values.toList();
    list.sort((a, b) => a.titre.toLowerCase().compareTo(b.titre.toLowerCase()));
    return list;
  }

  /// Copie l'image choisie (ex: depuis la galerie) dans le stockage propre
  /// à l'app, pour ne pas dépendre du fichier d'origine qui peut être
  /// déplacé ou supprimé par la suite.
  static Future<void> add({required String titre, required File sourceImage}) async {
    final dir = await getApplicationDocumentsDirectory();
    final cadransDir = Directory('${dir.path}/cadrans');
    if (!await cadransDir.exists()) {
      await cadransDir.create(recursive: true);
    }
    final extension = sourceImage.path.contains('.') ? sourceImage.path.split('.').last : 'jpg';
    final nomFichier = 'cadran_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final destination = File('${cadransDir.path}/$nomFichier');
    await sourceImage.copy(destination.path);

    await _box.add(Cadran(
      titre: titre,
      cheminImage: destination.path,
      dateAjout: DateTime.now(),
    ));
  }

  static Future<void> delete(Cadran cadran) async {
    final fichier = File(cadran.cheminImage);
    if (await fichier.exists()) {
      await fichier.delete();
    }
    await cadran.delete();
  }
}
