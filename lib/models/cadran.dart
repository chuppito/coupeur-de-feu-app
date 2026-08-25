import 'package:hive/hive.dart';

part 'cadran.g.dart';

/// Une planche de radiesthésie (cadran), ajoutée par l'utilisateur sous
/// forme d'image. Contrairement aux autres bibliothèques de l'app
/// (protocoles, chakras), ce contenu n'est jamais pré-rempli : les
/// planches "toutes faites" qu'on trouve en ligne sont très souvent
/// protégées par des droits d'auteur explicites, donc chaque cadran ici
/// doit être le tien (dessiné, acheté avec une licence adaptée, ou
/// réellement libre de droits).
@HiveType(typeId: 2)
class Cadran extends HiveObject {
  @HiveField(0)
  String titre;
  @HiveField(1)
  String cheminImage;
  @HiveField(2)
  DateTime dateAjout;

  Cadran({
    required this.titre,
    required this.cheminImage,
    required this.dateAjout,
  });
}
