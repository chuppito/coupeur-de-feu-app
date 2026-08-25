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
/// La bibliothèque est pré-remplie avec un jeu de planches par défaut (voir
/// `CadranService.seedNouveautesSiNecessaire`), et l'utilisateur peut en
/// ajouter d'autres : soit en important une image, soit en créant un
/// éventail. Le champ `attribution` sert à créditer la source d'une
/// planche quand sa licence l'exige (ex: CC BY).
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
