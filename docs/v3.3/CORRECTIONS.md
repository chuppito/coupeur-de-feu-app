# V3.3 - Corrections de l'audit du 02/11/2026

Base : V3.2 c3c9561177f8d5d13294e1d864e5dae38bdf009a. Interface, identifiant Android, boîtes Hive et prières conservés. Limite : trois motifs de soin ; aucune limite de prières. Le soin personnel optionnel au pendule demeure disponible et ne compte pas comme une prière.

## Changements

- Données explicites `guideV33` : liste ordonnée des actions, cible anatomique, trajet, référence, adaptation distance. Le moteur n'infère pas les gestes en recherchant des mots dans les textes.
- Assemblage par dépendances : conventions communes uniques, exceptions avant conventions préservées (zona, sclérose), séquences régionales complètes. Un cycle d'ordre est un conflit visible.
- Eczéma : peau puis rapides/flux/lentes/imposition abdominale. Sciatique : séquence lombaire complète avant jambe. Cruralgie : jambe antérieure sur le dos (vidéo 18.03).
- Flux attaché à chaque travail local, pas seulement au motif ; aucun trajet de coude substitué au travail abdominal. Les côtés du motif restent mémorisés.
- Distance : préparation du témoin, travail sur planches détaillé, cibles et intentions locales conservées. Pas de passes ni impositions physiques sur le patient.
- Conventions : un même entier de durée pour affichage et compte à rebours ; CM8 omise si aucun traitement signalé ; CM9 nettoyage 60/120/240 s selon les observations traditionnelles, puis équilibrage et recharge 30 s chacun, selon le manuel. Les conventions supplémentaires sans durée sont manuelles, à leur emplacement propre.
- Validation à partir de l'étape ouverte, au lieu d'indices d'une ancienne trame. Les changements de préparation arrêtent la lecture.
- Pendule de Thot sélectionné : soin optionnel complet personnel affiché, pas seulement le complément trois actions. Aucune substitution des prières.
- Circulation : aide dédiée à la circulation avec les mains, distincte du bilan au pendule.
- Suivis zona/verrue : vrais textes des prières et intentions d'imposition ; sélection par motif, compatible avec un autre motif en séance complète. Le parcours mixte est un assemblage applicatif, pas une séquence composite attribuée au formateur.
- Radiothérapie : choix explicite du suivi à distance, aucune application automatique à la chimiothérapie.
- Suivis fibro/chirurgie : confirmation explicite des zones du jour / du choix avant ou après intervention.
- Enregistrement : ajout de la version du guide et des identifiants d'étapes, sans migration destructive ni suppression d'historique.

## Sources et limites

Formation de Stéphane Langlade ; publication des vidéos non datée. Analyse audio documentaire du 02/11/2026, pas de nouveau visionnage visuel intégral.
- 19.02 eczéma : https://enligne.formationmagnetisme.fr/school/course/praticien/lecture/3962908 (04:06-05:59)
- 18.03 sciatique/cruralgie : https://enligne.formationmagnetisme.fr/school/course/praticien/lecture/4213494 (environ 03:35-05:40)
- 19.04 zona : https://enligne.formationmagnetisme.fr/school/course/praticien/lecture/3962918 (02:53-05:20 ; 06:09-07:23)
- 19.01 verrue : https://enligne.formationmagnetisme.fr/school/course/praticien/lecture/3962883 (05:23-06:45)
- 23.01 radio : https://enligne.formationmagnetisme.fr/school/course/praticien/lecture/3962979 (02:31-03:27)
- Manuel intégré : 14 conventions ; travail sur planches anatomiques ; création du témoin ; circulation entre chakras.

Les divergences 10/15 min du suivi verrue ne sont pas transformées en minuteur imposé. Les variantes de durée CM9 15/20 s évoquées antérieurement ne sont pas présentées comme tranchées : cette version utilise explicitement les 30 s du manuel. Aucun suivi court verrue à distance n'est inventé. Les durées non précisées restent manuelles. Les fiches non structurées gardent leur parcours V3.2 ; leur normalisation ne saurait être déclarée complète. Les pratiques ne sont pas des traitements médicaux validés.

## Validation

Voir le workflow `V3.3 - Tests et APK` pour les résultats réellement exécutés. Tests de dépendances, de chaque fiche structurée, de plusieurs motifs, modes, durées et widgets de préparation/guidage/enregistrement. L'installation et les essais physiques sur téléphone restent à vérifier. Signature Android de la branche source conservée ; aucune désinstallation de données prescrite.

Correction supplémentaire de l'acné : le guide source normalisé comportait un marqueur vide et une intention intestinale corrompue. Le schéma PDF déjà intégré précise sérotonine puis circulation. Seul le guide V3.3 est corrigé ; la source historique reste inchangée pour traçabilité.
