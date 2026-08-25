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
  // Pré-remplissage versionné (même principe que ProtocoleService) : ne
  // sert que pour des cadrans dont la licence autorise explicitement la
  // réutilisation, jamais pour du contenu protégé.
  // ---------------------------------------------------------------------

  static const String _cleVersion = 'cadrans_seed_version';
  static const int _versionActuelle = 3;

  static Future<void> seedNouveautesSiNecessaire() async {
    final meta = Hive.box('app_meta');
    int version = (meta.get(_cleVersion) as int?) ?? 0;

    if (version < 1) {
      await _box.add(Cadran(
        titre: "Augmenter le taux vibratoire",
        dateAjout: DateTime.now(),
        type: 'eventail',
        labels: const [
          "Hygiène de vie",
          "Positiver",
          "Activité passion",
          "Ressourcer nature",
          "Lâcher prise",
          "Rire, s'amuser",
          "Purification énergétique",
          "Alimentation spirituelle",
          "Agir",
          "Porter l'amour à un proche",
          "Foi aux forces supérieures",
          "Méditer",
          "Prier",
          "Développement capacités subtiles",
          "Philosophie",
        ],
        attribution: "Cadran partagé par ocverclock sur subtil.net — Licence CC BY-NC 4.0",
      ));
    }

    if (version < 2) {
      final maintenant = DateTime.now();
      await _box.addAll([
        Cadran(
          titre: "Planche de contrôle",
          dateAjout: maintenant,
          type: 'eventail',
          labels: const ["Faux", "Désir", "Vrai"],
        ),
        Cadran(
          titre: "Pourcentages",
          dateAjout: maintenant,
          type: 'eventail',
          labels: List.generate(21, (i) => "${i * 5}"),
        ),
        Cadran(
          titre: "Chiffres",
          dateAjout: maintenant,
          type: 'eventail',
          labels: List.generate(10, (i) => "$i"),
        ),
        Cadran(
          titre: "Intensité",
          dateAjout: maintenant,
          type: 'eventail',
          labels: const ["Très faible", "Faible", "Moyenne", "Forte", "Très forte"],
        ),
        Cadran(
          titre: "Jours / mois",
          dateAjout: maintenant,
          type: 'eventail',
          labels: List.generate(31, (i) => "${i + 1}"),
          groupes: const [
            "Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
            "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre",
          ],
        ),
        Cadran(
          titre: "Les 7 chakras",
          dateAjout: maintenant,
          type: 'eventail',
          labels: const [
            "1 · Chakra Racine",
            "2 · Chakra Sacré",
            "3 · Chakra Plexus Solaire",
            "4 · Chakra Cœur",
            "5 · Chakra Gorge",
            "6 · Chakra 3ème Œil",
            "7 · Chakra Coronal",
          ],
        ),
        Cadran(
          titre: "Lettres",
          dateAjout: maintenant,
          type: 'eventail',
          labels: List.generate(26, (i) => "${String.fromCharCode(65 + i)} · ${i + 1}"),
          groupes: const ["Voyelle", "Consonne"],
        ),
        Cadran(
          titre: "Énergétique des chakras",
          dateAjout: maintenant,
          type: 'eventail',
          labels: const ["0%", "25%", "50%", "75%", "100%", "125%", "150%", "175%", "200%"],
          groupes: const ["Faiblesse", "Équilibré", "Surcharge"],
          attribution: "Note : \"Équilibré\" (100%) est ici étalé sur tout le tiers central par simplification, "
              "alors que sur la planche d'origine il ne marque que le point 100% précisément.",
        ),
      ]);
    }

    if (version < 3) {
      final maintenant = DateTime.now();
      await _box.addAll([
        Cadran(
          titre: "Sécurité (Oui/Non)",
          dateAjout: maintenant,
          type: 'eventail',
          labels: const [
            "Un autre jour",
            "Je reviens vers vous - date",
            "Je planifie",
            "plus tard",
            "Pas mûr",
            "Pas seul",
            "Situation trop ardue",
            "incompatible",
            "Danger",
            "Ennuis plus tard",
            "A refuser",
            "Perturbation venant du Karma",
          ],
          groupes: const ["OUI", "NON"],
          attribution: "Cadran partagé par phreip sur subtil.net, le 28/05/2023 — Licence CC BY-NC 4.0",
        ),
        Cadran(
          titre: "Origines subtiles des problèmes",
          dateAjout: maintenant,
          type: 'eventail',
          labels: const [
            "Présences",
            "Mémoires des murs",
            "Mémoire du lieu",
            "Charges",
            "Rituels",
            "Ondes de forme",
          ],
          attribution: "Cadran partagé par Subtil sur subtil.net, le 09/05/2018 — Licence CC BY-NC 4.0",
        ),
        Cadran(
          titre: "Origines des problèmes (bâtiment)",
          dateAjout: maintenant,
          type: 'eventail',
          labels: const [
            "Site Climat",
            "Sous-sol",
            "Bâtiment voisin",
            "Forme du bâtiment",
            "Orientation du bâtiment",
            "Intérieur du bâtiment",
            "Atmosphère",
            "Autres causes",
          ],
          attribution: "Cadran partagé par Subtil sur subtil.net, le 09/05/2018 — Licence CC BY-NC 4.0",
        ),
        Cadran(
          titre: "Planche d'erreur",
          dateAjout: maintenant,
          type: 'eventail',
          labels: const [
            "Erreur",
            "Influence",
            "Auto suggestion",
            "Influence sous-sol",
            "Ambiance mentale",
            "Horaire / Jour",
            "Pensée d'autrui",
            "Radiation parasite",
            "Virtualité",
            "Ambiance physique",
            "Traces du passé",
            "Réalité",
          ],
          attribution: "Cadran partagé par Subtil sur subtil.net, le 09/05/2018 — Licence CC BY-NC 4.0",
        ),
      ]);
    }

    if (version < _versionActuelle) {
      await meta.put(_cleVersion, _versionActuelle);
    }
  }
}
