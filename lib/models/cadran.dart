import 'package:hive/hive.dart';

part 'cadran.g.dart';

/// Une planche de radiesthésie (cadran), ajoutée par l'utilisateur.
/// Deux formes possibles :
///  - "image" : une photo/capture importée depuis la galerie (cheminImage).
///  - "eventail" : un cadran dessiné nativement par l'app à partir d'une
///    liste de libellés (labels), sur le modèle classique en éventail
///    (demi-cercle divisé en secteurs). Plus net à l'écran, et surtout
///    éditable directement dans l'app sans repasser par une image.
///
/// Dans les deux cas, ce contenu n'est jamais pré-rempli par l'app : les
/// planches "toutes faites" qu'on trouve en ligne sont très souvent
/// protégées par des droits d'auteur explicites. Chaque cadran ici doit
/// être le tien (dessiné, une licence Creative Commons qui autorise la
/// réutilisation avec attribution, ou réellement dans le domaine public).
/// Le champ `attribution` sert à créditer la source quand la licence
/// l'exige (ex: CC BY).
@HiveType(typeId: 2)
class Cadran extends HiveObject {
  @HiveField(0)
  String titre;
  @HiveField(1)
  String cheminImage;
  @HiveField(2)
  DateTime dateAjout;
  @HiveField(3)
  String type; // 'image' ou 'eventail'
  @HiveField(4)
  List<String>? labels; // pour type == 'eventail'
  @HiveField(5)
  String? attribution;
  @HiveField(6)
  List<String>? groupes; // anneau extérieur optionnel (divisions égales), pour type == 'eventail'

  Cadran({
    required this.titre,
    required this.dateAjout,
    this.cheminImage = '',
    this.type = 'image',
    this.labels,
    this.attribution,
    this.groupes,
  });
}
