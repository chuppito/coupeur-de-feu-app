# Suivi Coupeur de Feu

Application Flutter de suivi de patients pour une pratique de coupeur de feu :
fiches patients, zones du corps associées à des problématiques symboliques,
prières de soin, stockage 100% local via Hive.

## Installation

```bash
cd coupeur_de_feu_app
flutter pub get
flutter run
```

Le `TypeAdapter` Hive (`PatientSessionAdapter`, dans `patient_session.g.dart`)
est généré par `build_runner` à partir des annotations `@HiveType`/`@HiveField`
de `lib/models/patient_session.dart`. Si tu modifies ce modèle, régénère
l'adaptateur avec :

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Architecture

```
lib/
 ├── main.dart                     # Point d'entrée, init Hive
 ├── models/
 │    ├── patient_session.dart     # Modèle de séance (HiveObject)
 │    └── patient_session.g.dart   # Adaptateur Hive généré
 ├── data/
 │    └── symbolique_data.dart     # Pathologies, zones, synthèses symboliques, prières
 ├── services/
 │    ├── history_service.dart     # CRUD Hive + export/import JSON
 │    └── backup_service.dart      # Export fichier + partage / restauration
 ├── widgets/
 │    └── interactive_body.dart    # Schéma corporel tactile (face/dos)
 └── screens/
      ├── home_screen.dart         # Création de fiche (zones, intensité, prière)
      ├── history_screen.dart      # Historique par patient, recherche, sauvegarde
      └── stats_screen.dart        # Statistiques (répartition, taux de guérison)
```

## Fonctionnalités

- **Fiche de soin** : prénom + nom (optionnel, pour distinguer les
  homonymes), pathologie, sélection de zones du corps sur un schéma
  interactif (face/dos), curseurs d'intensité avant/après (0-10),
  génération automatique d'une synthèse symbolique et d'une prière de soin
  adaptées à chaque combinaison pathologie × zone.
- **Historique** : regroupement par patient, recherche par nom, marquage
  "guéri" horodaté, notes libres par séance, suppression avec possibilité
  d'annuler (SnackBar "Annuler" pendant quelques secondes après suppression).
- **Statistiques** : nombre de patients suivis, taux de guérison global,
  délai moyen de guérison, répartition des soins par pathologie.
- **Sauvegarde** : export de tout l'historique en JSON (partagé via le menu
  natif — email, Drive, fichiers…) et restauration depuis un fichier de
  sauvegarde. Pas de chiffrement (choix assumé : le téléphone est déjà
  protégé en amont). Attention : restaurer deux fois le même fichier crée
  des doublons (pas de déduplication automatique).

## Aller plus loin

- Étendre `typesMaladie`/`zonesCorps` et les textes symboliques dans
  `lib/data/symbolique_data.dart` selon ta pratique.
- Export PDF d'une fiche patient individuelle (à remettre en main propre).
- Rappel/notification si un patient n'est pas marqué guéri après X jours.
- Chiffrer la box Hive (`Hive.openBox` supporte une clé de chiffrement via
  `HiveAesCipher` + `flutter_secure_storage`) si le besoin de sécurité
  évolue.
