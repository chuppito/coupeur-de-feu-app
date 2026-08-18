import 'package:hive/hive.dart';

part 'protocole.g.dart';

/// Une fiche de "protocole" : prière et/ou technique de magnétisme (passes,
/// imposition des mains...) pour une problématique donnée. Contrairement au
/// système symbolique (maladie x zone dans symbolique_data.dart), ces fiches
/// sont du texte libre, entièrement modifiable par l'utilisateur : quelques
/// unes sont fournies par défaut (ex: Lombalgie), et Thomas peut en ajouter,
/// modifier ou supprimer via l'écran "Techniques de magnétisme".
@HiveType(typeId: 1)
class Protocole extends HiveObject {
  @HiveField(0)
  String titre;
  @HiveField(1)
  String priere;
  @HiveField(2)
  String etapes;
  @HiveField(3)
  DateTime dateAjout;
  @HiveField(4)
  bool estParDefaut;

  Protocole({
    required this.titre,
    required this.dateAjout,
    this.priere = '',
    this.etapes = '',
    this.estParDefaut = false,
  });
}
