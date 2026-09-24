import 'package:hive/hive.dart';

part 'patient_session.g.dart'; // Nécessaire pour Hive

@HiveType(typeId: 0)
class PatientSession extends HiveObject {
  @HiveField(0)
  String nomPatient;
  @HiveField(1)
  String zone;
  @HiveField(2)
  String observation;
  /// null = non renseigné (à ne pas confondre avec 0 = "aucune douleur").
  @HiveField(3)
  int? intensiteAvant;
  @HiveField(4)
  int? intensiteApres;
  @HiveField(5)
  DateTime date;
  @HiveField(6)
  String maladie;
  @HiveField(7)
  bool guerie;
  @HiveField(8)
  DateTime? dateGuerison;
  @HiveField(9)
  String nomFamille;
  @HiveField(10)
  String? protocoleTitre;

  PatientSession({
    required this.nomPatient,
    required this.zone,
    required this.observation,
    required this.date,
    this.intensiteAvant,
    this.intensiteApres,
    this.maladie = '',
    this.guerie = false,
    this.dateGuerison,
    this.nomFamille = '',
    this.protocoleTitre,
  });

  /// Nom complet (prénom + nom de famille si renseigné), utilisé pour
  /// regrouper/distinguer les patients dans l'historique sans confondre
  /// deux personnes ayant le même prénom.
  String get nomComplet =>
      nomFamille.trim().isEmpty ? nomPatient : '$nomPatient ${nomFamille.trim()}';
}
