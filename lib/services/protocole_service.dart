import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/protocole.dart';

/// Gère la bibliothèque de protocoles (prières + techniques de passes de
/// magnétisme).
///
/// Système de versions : chaque lot de nouveautés fournies par Thomas a un
/// numéro de version. Au démarrage, seedNouveautesSiNecessaire() n'ajoute
/// que les lots dont le numéro est supérieur à la dernière version connue
/// (stockée dans la box 'app_meta'). Ça permet d'ajouter du contenu au fil
/// des mises à jour sans jamais dupliquer ce qui a déjà été inséré, ni
/// ressusciter une fiche que Thomas aurait volontairement supprimée.
class ProtocoleService {
  static Box<Protocole> get _box => Hive.box<Protocole>('protocoles');
  static Box get _meta => Hive.box('app_meta');
  static const String _cleVersion = 'protocoles_seed_version';

  /// Version la plus haute connue. À incrémenter à chaque nouveau lot de
  /// contenu ajouté dans _lotsParVersion.
  static const int _versionActuelle = 2;

  static ValueListenable<Box<Protocole>> listenable() => _box.listenable();

  /// À appeler une fois au démarrage (voir main.dart).
  static Future<void> seedNouveautesSiNecessaire() async {
    int version = (_meta.get(_cleVersion) as int?) ?? 0;

    // Compatibilité avec les installations qui avaient déjà les 4 premiers
    // protocoles créés par l'ancien mécanisme (seedDefaultsSiVide, avant le
    // suivi de version) : on ne les rajoute pas une seconde fois.
    if (version == 0 && _box.isNotEmpty) {
      version = 1;
    }

    final maintenant = DateTime.now();
    for (final lot in _lotsParVersion.entries) {
      if (lot.key > version) {
        await _box.addAll(lot.value(maintenant));
      }
    }

    if (version < _versionActuelle) {
      await _meta.put(_cleVersion, _versionActuelle);
    }
  }

  static final Map<int, List<Protocole> Function(DateTime)> _lotsParVersion = {
    1: (date) => [
          Protocole(
            titre: "Lombalgie (mal de dos)",
            dateAjout: date,
            estParDefaut: true,
            priere: """(+) Dos cassé, échine courbée, dos meurtri, redresse-toi sans plus tarder. """
                """Fais, Seigneur, que [NOM] marche droit, fier comme l'était notre Seigneur Jésus-Christ """
                """de sa mission d'amour sur la terre. Tu avances ainsi, guéri de toutes blessures, """
                """cassures ou courbatures, car notre Seigneur est près de toi et te soutient. Amen. (+)""",
            etapes: """1. 10 à 20 passes rapides, toujours du haut du dos vers le bas jusqu'au coccyx : """
                """main ouverte à 1-2 cm du corps en descendant, puis remonter poing fermé.
2. 30 secondes de passes lentes sur la même zone.
3. Imposition ou apposition des mains pendant 2 minutes sur les lombaires, en visualisant """
                """une lumière bleue (froide) qui se diffuse dans la zone.""",
          ),
          Protocole(
            titre: "Cervicales",
            dateAjout: date,
            estParDefaut: true,
            etapes: """Même protocole que la lombalgie, appliqué du haut de la tête jusqu'aux dorsales :
1. 10 à 20 passes rapides, du haut de la tête vers les dorsales : main ouverte à 1-2 cm """
                """en descendant, puis remonter poing fermé.
2. 30 secondes de passes lentes sur la même zone.
3. Imposition ou apposition des mains pendant 2 minutes, en visualisant une lumière bleue """
                """(froide) qui se diffuse dans la zone.""",
          ),
          Protocole(
            titre: "Sciatique",
            dateAjout: date,
            estParDefaut: true,
            etapes: """1. Protocole lombalgie complet sur le bas du dos (passes rapides + passes lentes """
                """+ imposition 2 min avec visualisation d'une lumière bleue).
2. 20 passes rapides des fesses jusqu'au genou.
3. Puis 20 passes rapides du genou jusqu'au pied.
4. Terminer par 30 secondes de passes lentes sur toute la jambe.""",
          ),
          Protocole(
            titre: "Cruralgie",
            dateAjout: date,
            estParDefaut: true,
            etapes: """1. Protocole lombalgie complet sur le bas du dos (passes rapides + passes lentes """
                """+ imposition 2 min avec visualisation d'une lumière bleue).
2. Le patient se remet sur le dos.
3. Passes rapides de l'aine jusqu'au genou.
4. Puis passes rapides du genou jusqu'au pied.
5. Terminer par des passes lentes sur toute la jambe.""",
          ),
        ],
    2: (date) {
      // La prière du feu utilisée par Thomas (identique à celle déjà en
      // place pour "Brûlure" dans symbolique_data.dart), réutilisée pour
      // toutes les fiches de cette bibliothèque au lieu de "Feu de Dieu
      // perds ta chaleur...".
      const priereFeu = """Feu, je te coupe +
Feu, je te bloque +
Tu n'as pas lieu d'être sur le corps de [NOM].
Le feu ne brûle pas les chairs,
Les chairs deviennent normales,
La peau s'assouplit, s'adoucit, ne devient pas dure,
Mais reste telle qu'elle était avant la brûlure.""";

      return [
        Protocole(
          titre: "Piqûre de guêpe ou d'abeille",
          dateAjout: date,
          estParDefaut: true,
          priere: """1. Prière contre la piqûre (3 signes de croix avec le pouce au-dessus de la piqûre) :
« Ô guêpe (ou ô abeille), malheureuse bête, ton aiguillon est entré, ton venin est versé. Au nom du Créateur, je te commande de perdre ta force, ton ardeur et ton venin, et que cette chair redevienne saine et fraîche comme elle l'était auparavant. »

2. Prière contre le feu (main rapprochée + signe de croix sur la piqûre, à répéter 3 fois d'affilée) :
$priereFeu""",
          etapes: """1. Faire 3 signes de croix avec le pouce au-dessus de la piqûre en récitant la prière contre la piqûre.
2. Laisser la main 30 secondes sur la zone, avec l'intention de stopper l'évolution du venin et des toxines dans les fibres.
3. Enchaîner avec la prière contre le feu (main rapprochée + signe de croix sur la piqûre), à faire 3 fois d'affilée.
4. Souffler sur la piqûre.
5. Laisser la main au-dessus de la piqûre pendant 1 minute, en visualisant une lumière bleue (le froid) qui se répand sur la zone.""",
        ),
        Protocole(
          titre: "Piqûre de moustique",
          dateAjout: date,
          estParDefaut: true,
          priere: """Prière contre le feu (main rapprochée + signe de croix sur la piqûre, à répéter 3 fois d'affilée) :
$priereFeu""",
          etapes: """Contrairement à la piqûre de guêpe/abeille, on ne fait que la prière contre le feu (pas de prière spécifique à l'insecte, pas de venin à stopper) :
1. Main rapprochée + signe de croix sur la piqûre, prière contre le feu, à faire 3 fois d'affilée.
2. Souffler sur la piqûre.
3. Laisser la main au-dessus de la piqûre pendant 1 minute, en visualisant une lumière bleue (le froid) qui se répand sur la zone.""",
        ),
        Protocole(
          titre: "Protection contre les moustiques",
          dateAjout: date,
          estParDefaut: true,
          priere: """Saint Grat, toi qui as reçu le pouvoir de commander aux éléments et de chasser les fléaux qui perturbent la paix des hommes et de la terre ;
Nous sollicitons aujourd'hui ton intercession et ta protection spirituelle face à l'invasion des moustiques et des insectes qui nuisent à notre repos, à notre santé et à la sérénité de notre foyer.
Par tes mérites et tes prières, demande au Seigneur d'éloigner ces créatures de notre demeure, de notre jardin et de nos proches. Que nos espaces soient préservés de leurs attaques et de leurs piqûres.
Saint Grat, dresse une barrière de protection autour de ce lieu et accorde-nous de pouvoir jouir de la nature et de nos nuits en toute tranquillité, sous ton regard bienveillant.
Amen.""",
          etapes: """À réciter avant une sortie ou une nuit, à titre préventif — ce n'est pas un soin curatif contrairement aux autres fiches de cette bibliothèque.""",
        ),
        Protocole(
          titre: "Coup de soleil",
          dateAjout: date,
          estParDefaut: true,
          priere: """Prière contre le feu (main rapprochée + signe de croix sur la partie rouge, à répéter 3 fois d'affilée) :
$priereFeu""",
          etapes: """1. Main rapprochée + signe de croix sur la partie rouge, prière contre le feu, à faire 3 fois d'affilée.
2. Répéter sur toutes les zones touchées par le coup de soleil.
3. Laisser la main 1 minute sur chaque zone, en visualisant une lumière bleue (le froid) qui se diffuse.""",
        ),
        Protocole(
          titre: "Fièvre / insolation",
          dateAjout: date,
          estParDefaut: true,
          priere: """Grand Saint Pierre,
Qui êtes assis à la droite de la gloire de Dieu (+)
Daignez-vous rappeler ce que notre Seigneur Jésus-Christ a dit à Saint Thérèse.
Il lui a promis que quiconque lui demanderait
En votre Nom la grâce de la guérison
Cela lui serait accordé.
Par le bonheur dont vous jouissez dans le ciel (+)
Daignez intercéder pour les mortifications
De [NOM]
Et tirer de son corps cette fièvre (+)
Au nom de Sainte Thérèse (+)
Dieu te guérit (+)
Ainsi soit-il.
(Chaque (+) est un signe de croix à faire à ce moment de la prière.)""",
          etapes: """Pour les insolations, en complément de la prière contre le feu.
1. Faire un signe de croix sur la tête du malade.
2. Réciter la prière ci-dessus, en marquant chaque (+) par un signe de croix.""",
        ),
      ];
    },
  };

  static List<Protocole> getAll() {
    final list = _box.values.toList();
    list.sort((a, b) => a.titre.toLowerCase().compareTo(b.titre.toLowerCase()));
    return list;
  }

  static Future<void> add({
    required String titre,
    String priere = '',
    String etapes = '',
  }) async {
    await _box.add(Protocole(
      titre: titre,
      priere: priere,
      etapes: etapes,
      dateAjout: DateTime.now(),
    ));
  }

  static Future<void> update(
    Protocole protocole, {
    required String titre,
    required String priere,
    required String etapes,
  }) async {
    protocole.titre = titre;
    protocole.priere = priere;
    protocole.etapes = etapes;
    await protocole.save();
  }

  static Future<void> delete(Protocole protocole) async {
    await protocole.delete();
  }

  // ---------------------------------------------------------------------
  // Sauvegarde / restauration de la bibliothèque de techniques
  // ---------------------------------------------------------------------

  /// Sérialise toute la bibliothèque en JSON (indépendant de l'historique
  /// patient — c'est une sauvegarde de tes réglages : prières, protocoles,
  /// tes propres ajouts).
  static String exportAllToJson() {
    final all = _box.values
        .map((p) => {
              'titre': p.titre,
              'priere': p.priere,
              'etapes': p.etapes,
            })
        .toList();
    final payload = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'protocoles': all,
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Réimporte une bibliothèque exportée par [exportAllToJson]. Contrairement
  /// à l'import de l'historique patient, ceci fonctionne par REMPLACEMENT :
  /// si une fiche du fichier a le même titre qu'une fiche déjà présente, son
  /// contenu (prière/étapes) écrase l'existant plutôt que de créer un
  /// doublon. C'est ce qui permet de revenir en arrière (ex: retrouver une
  /// ancienne version d'une prière) simplement en restaurant un ancien
  /// export. Les fiches du fichier dont le titre n'existe pas encore sont
  /// ajoutées normalement.
  static Future<int> importFromJson(String jsonStr) async {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    final protocoles = (data['protocoles'] as List).cast<Map<String, dynamic>>();

    for (final m in protocoles) {
      final titre = m['titre'] as String? ?? '';
      if (titre.isEmpty) continue;
      final priere = m['priere'] as String? ?? '';
      final etapes = m['etapes'] as String? ?? '';

      final existant = _box.values.where((p) => p.titre == titre).toList();
      if (existant.isNotEmpty) {
        for (final p in existant) {
          p.priere = priere;
          p.etapes = etapes;
          await p.save();
        }
      } else {
        await _box.add(Protocole(titre: titre, priere: priere, etapes: etapes, dateAjout: DateTime.now()));
      }
    }
    return protocoles.length;
  }
}
