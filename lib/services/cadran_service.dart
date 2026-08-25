import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../models/cadran.dart';

/// Gère la bibliothèque de cadrans de radiesthésie (pré-remplie par
/// défaut, voir `seedNouveautesSiNecessaire`, et enrichissable par
/// l'utilisateur).
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

  /// Crée un cadran "éventail" (dessiné nativement, pas d'image).
  static Future<void> addEventail({
    required String titre,
    required List<String> labels,
    String? attribution,
    List<String>? groupes,
  }) async {
    await _box.add(Cadran(
      titre: titre,
      dateAjout: DateTime.now(),
      type: 'eventail',
      labels: labels,
      attribution: attribution,
      groupes: groupes,
    ));
  }

  /// Modifie un cadran "éventail" existant.
  static Future<void> updateEventail(
    Cadran cadran, {
    required String titre,
    required List<String> labels,
    String? attribution,
    List<String>? groupes,
  }) async {
    cadran.titre = titre;
    cadran.labels = labels;
    cadran.attribution = attribution;
    cadran.groupes = groupes;
    await cadran.save();
  }

  static Future<void> delete(Cadran cadran) async {
    if (cadran.cheminImage.trim().isNotEmpty) {
      final fichier = File(cadran.cheminImage);
      if (await fichier.exists()) {
        await fichier.delete();
      }
    }
    await cadran.delete();
  }

  // ---------------------------------------------------------------------
  // Pré-remplissage versionné (même principe que ProtocoleService).
  //
  // Version 4 : la bibliothèque de cadrans est remise à plat et remplacée
  // par les 9 planches en image fournies par l'utilisateur (assets/cadrans).
  // Tout ce qui existait avant (éventails générés nativement lors des
  // versions précédentes, ou cadrans ajoutés manuellement) est supprimé.
  // ---------------------------------------------------------------------

  static const String _cleVersion = 'cadrans_seed_version';
  static const int _versionActuelle = 4;

  /// Planches fournies en asset, copiées dans le stockage de l'app au
  /// premier lancement (ou à la mise à jour) pour être affichées comme les
  /// cadrans "image" habituels (voir `add`).
  static const List<({String asset, String titre})> _planchesParDefaut = [
    (asset: 'assets/cadrans/pourcentages.png', titre: 'Pourcentages'),
    (asset: 'assets/cadrans/affinites.png', titre: 'Affinités'),
    (asset: 'assets/cadrans/origines_subtiles_maison.png', titre: 'Origines subtiles des problèmes (maison)'),
    (asset: 'assets/cadrans/origines_problemes_maison.png', titre: 'Origines des problèmes (maison)'),
    (asset: 'assets/cadrans/subtil_individuel.png', titre: 'Subtil individuel'),
    (asset: 'assets/cadrans/taux_vibratoires_bovis.png', titre: 'Taux vibratoires (Bovis)'),
    (asset: 'assets/cadrans/taux_vibratoires_bovis_log.png', titre: 'Taux vibratoires (Bovis, logarithmique)'),
    (asset: 'assets/cadrans/chakras_personnels.png', titre: 'Chakras personnels'),
    (asset: 'assets/cadrans/energetique_chakras.png', titre: 'Énergétique des chakras'),
  ];

  static Future<void> seedNouveautesSiNecessaire() async {
    final meta = Hive.box('app_meta');
    int version = (meta.get(_cleVersion) as int?) ?? 0;

    if (version < 4) {
      // On vide entièrement la bibliothèque existante (fichiers + entrées
      // Hive) avant de repartir sur les nouvelles planches par défaut.
      for (final cadran in _box.values.toList()) {
        if (cadran.cheminImage.trim().isNotEmpty) {
          final fichier = File(cadran.cheminImage);
          if (await fichier.exists()) {
            await fichier.delete();
          }
        }
      }
      await _box.clear();

      final dir = await getApplicationDocumentsDirectory();
      final cadransDir = Directory('${dir.path}/cadrans');
      if (!await cadransDir.exists()) {
        await cadransDir.create(recursive: true);
      }

      final maintenant = DateTime.now();
      for (final planche in _planchesParDefaut) {
        final octets = await rootBundle.load(planche.asset);
        final nomFichier = planche.asset.split('/').last;
        final destination = File('${cadransDir.path}/$nomFichier');
        await destination.writeAsBytes(
          octets.buffer.asUint8List(octets.offsetInBytes, octets.lengthInBytes),
          flush: true,
        );

        await _box.add(Cadran(
          titre: planche.titre,
          cheminImage: destination.path,
          dateAjout: maintenant,
        ));
      }
    }

    if (version < _versionActuelle) {
      await meta.put(_cleVersion, _versionActuelle);
    }
  }
}
