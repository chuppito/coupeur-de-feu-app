# Matrice des 18 constats — état V0.4

Référence V3 : a554f5e9f362b5b8da2a6500649f4be7819fb7a0. Corrections limitées au nouveau parcours. **46 tests locaux réussis**, analyse ciblée sans anomalie. Compilation Android réussie aussi sur le dernier code c673ee6 : exécution 41078836721, 46 tests réussis. Tous les contenus ne sont pas encore normalisés.

## A01 — Minuteur

**État :** corrigé dans le nouveau lecteur

Cause / preuve V3 : La durée active vaut 60 secondes par défaut, avec un seul cas à 120 secondes sur la convention 12, alors que le texte de la convention 9 peut afficher 4 minutes. (lib/screens/magnetisme_session_screen.dart:1304;1555;1609).

Attendu : Une seule valeur durationSeconds issue de la règle sourcée pilote texte et minuteur.

Modification : DurationSpec unique pour texte, minuteur et instantané ; aucun délai codé par indice.

Tests / résultat : 240 s entières, pause/reprise et progression automatique : tests réussis.

Reste à vérifier : Revoir toutes les durées des fiches non encore normalisées.

## A02 — Extraction des conventions

**État :** corrigé dans le moteur ; contenus partiels

Cause / preuve V3 : Le parseur exige une section commençant par 5. et contenant convention et suppl, puis des lignes à tiret. Les variantes en ligne et les fiches sans numéros échappent à cette extraction. (lib/screens/magnetisme_session_screen.dart:1630).

Attendu : Conventions stockées comme objets avec identifiant, condition et sources ; aucun parsing de prose en séance.

Modification : Actions et conventions déclaratives ; aucun parseur de prose en V4.

Tests / résultat : Quatre fiches normalisées et validations de sources testées.

Reste à vérifier : Normaliser les autres fiches, notamment leurs conventions supplémentaires.

## A03 — Fiche eczéma

**État :** corrigé pour la fiche V4 initiale

Cause / preuve V3 : Le texte de ft-eczema est dépourvu de numéros 5., 6., 7. ; la récupération de section 7 ne peut pas restituer son travail abdominal. (assets/data/magnetisme_protocoles.json#ft-eczema;lib/screens/magnetisme_session_screen.dart:1658;1863).

Attendu : Deux actions distinctes : imposition cutanée de cinq minutes puis travail abdominal, dans l’ordre de la fiche.

Modification : Bloc cutané de 300 s puis bloc abdominal distinct.

Tests / résultat : Ordre et durée testés.

Reste à vérifier : Vidéo spécifique eczéma encore à analyser ; V3 inchangée.

## A04 — Prière du feu

**État :** corrigé dans le moteur ; catalogue partiel

Cause / preuve V3 : La présence du texte signe de croix suffit à activer la prière du feu, même lorsque la croix accompagne une autre prière. (lib/screens/magnetisme_session_screen.dart:465;1716).

Attendu : Relations explicites fiche-prière ; les gestes de croix sont des attributs de chaque prière.

Modification : Liens explicites par prayerId ; aucune inférence à partir du signe de croix.

Tests / résultat : Eczéma sans prière du feu : test réussi ; bibliothèque personnelle réutilisée.

Reste à vérifier : Contrôler les autres associations lors de la migration.

## A05 — Circulation

**État :** corrigé dans le nouveau parcours ; appareil à vérifier

Cause / preuve V3 : Le bloc circulation ouvre l’aide de contrôle des chakras, alors que la circulation possède une technique différente et une fiche dédiée en bibliothèque. (lib/screens/magnetisme_session_screen.dart:1891;assets/data/magnetisme_protocoles.json#circulation-energetique-entre-les-chakras).

Attendu : Distinguer assessment.chakra et technique.circulation ; afficher la bonne aide selon actionId.

Modification : Six actions couronne → troisième œil, gorge, cœur, plexus, sacré, racine ; exception de portée au plexus pour les deux dernières seulement.

Tests / résultat : Ordre des six cibles vérifié dans la séance de quatre fiches ; séparation du bilan conservée.

Reste à vérifier : Validation gestuelle sur appareil et confirmation humaine ciblée de la narration automatique.

## A06 — Distance

**État :** partiel

Cause / preuve V3 : Le bloc de travail à distance affiche des consignes génériques sans dérouler localisation, décharge, deux frappes, recharge et travail focalisé sur planche. (lib/screens/magnetisme_session_screen.dart:1871;assets/data/magnetisme_protocoles.json#planches_anatomiques_distance).

Attendu : Un plan à distance en huit phases, avec une sous-séquence propre aux planches et aux zones sélectionnées.

Modification : Trame des huit phases à distance, préparation du témoin en préalable, sous-séquence de planche sans passe corporelle ; étapes spécifiques encore signalées à compléter.

Tests / résultat : Aucun type de passe corporelle autorisé à distance : tests réussis.

Reste à vérifier : Normaliser les variantes par motif ; recharge dix/vingt secondes à distinguer. Les phases 5 et 6 sont des repères manuels de préparation, pas des protocoles spécifiques complets.

## A07 — Ordres particuliers

**État :** mécanisme corrigé ; exceptions à migrer

Cause / preuve V3 : Le constructeur place toujours les conventions communes avant prières et travail local dans la séance standard. (lib/screens/magnetisme_session_screen.dart:473).

Attendu : Ordres locaux déclaratifs et statut de validation ; ne pas normaliser les exceptions sans arbitrage.

Modification : Ordre par graphe et contraintes explicites ; un cycle bloque le démarrage sans effacer aperçu. Les phases globales explicites ajoutent des contraintes sans enlever l’ordre local.

Tests / résultat : Ordres contradictoires et conservation des actions testés. Une phase contraire à un ordre local bloque aussi le démarrage.

Reste à vérifier : Saisir les exceptions des fiches zona, SEP et autres ; elles ne sont pas toutes migrées.

## A08 — Soin au pendule

**État :** non intégré : variante conservée en V3

Cause / preuve V3 : Le bloc facultatif impose 20 passes rapides puis 15 lentes et est inséré avant le dégagement dans la séance standard. (lib/screens/magnetisme_session_screen.dart:473;1185).

Attendu : Conserver le protocole personnel comme variante identifiée ; la variante formation a son emplacement et ses durées propres.

Modification : Aucun transfert automatique des 20 rapides/15 lentes vers la variante formation.

Tests / résultat : Conservation des données existantes ; aucune prétention de correction globale.

Reste à vérifier : Normaliser variantes pendule et emplacement après comparaison des sources.

## A09 — Options et validation

**État :** corrigé pour le nouveau lecteur ; feu court à migrer

Cause / preuve V3 : La validation finale des 14 conventions utilise un indice dépendant du soin pendule mais omet le décalage du scan. Les cases du protocole court feu emploient aussi des indices fixes. (lib/screens/magnetisme_session_screen.dart:1550;948;975;991).

Attendu : Valider par stepInstanceId stable et abandonner les calculs d’indice dispersés.

Modification : Identifiants stables par action ; validation de préfixe de progression.

Tests / résultat : Options ne décalent pas les IDs, instantané corrompu rejeté, retour en haut testé.

Reste à vérifier : Protocole court feu non encore migré.

## A10 — Séance multiple

**État :** corrigé dans le moteur

Cause / preuve V3 : Les conventions identiques sont dédupliquées par texte normalisé, en ne conservant dans le texte affiché que le premier titre rencontré. (lib/screens/magnetisme_session_screen.dart:451).

Attendu : Fusion par identifiant sémantique avec provenance multiple et union des cibles compatibles.

Modification : Partage seulement avec shareKey explicite et signature compatible ; union des provenances.

Tests / résultat : Quatre motifs, conservation des cibles et séquences locales, absence de fusion par texte : tests réussis. Quatre fiches réelles : toutes conventions supplémentaires avant prières puis travail local ; test réussi.

Reste à vérifier : Tester chaque combinaison réelle au fil de la normalisation du catalogue.

## A11 — Données patients

**État :** corrigé pour les nouveaux dossiers ; migration préparatoire

Cause / preuve V3 : La recherche des séances et les opérations de renommage reposent sur une égalité de nom complet, sans identifiant patient dans ce service. (lib/services/magnetisme_session_service.dart:11;24).

Attendu : PatientId stable, relation explicite des séances et reprise des anciens noms avec contrôle des ambiguïtés.

Modification : UUID par patient et relation explicite des séances ; revue manuelle des originaux V3.

Tests / résultat : Homonymes, recherche sans accents et refus de réassociation testés.

Reste à vérifier : Conversion complète des anciens historiques en séances V4 à développer.

## A12 — Historique et sauvegarde

**État :** corrigé pour le stockage V4 ; appareil à vérifier

Cause / preuve V3 : Les séances enregistrent les titres des étapes et leurs indices validés, mais pas un instantané complet des contenus et durées réellement suivis. L’import des séances magnétisme ajoute chaque élément. (lib/screens/magnetisme_session_screen.dart:510;lib/services/magnetisme_session_service.dart:50).

Attendu : PlanSnapshot versionné et import idempotent par UUID.

Modification : Instantané complet versionné et import sans écrasement ; métadonnées originales incluses.

Tests / résultat : Fermeture/relecture Hive, import idempotent, conflits refusés avant écriture, sauvegarde/restauration des originaux testés.

Reste à vérifier : Arrêt forcé Android, gros volumes et restauration de vraies données non testés.

## A13 — Formats hétérogènes

**État :** partiel

Cause / preuve V3 : Les ressources intègrent 98 entrées : 56 fiches, 21 prières, 11 techniques et 10 références. Aucun identifiant strictement dupliqué n’a été relevé. (assets/data/magnetisme_protocoles.json;assets/data/magnetisme_techniques.json;assets/data/magnetisme_techniques_chakras.json).

Attendu : Référentiel de thèmes et variantes liés ; ne pas supprimer automatiquement les documents proches.

Modification : Schéma versionné et catalogue initial de cinq parcours ; ressources historiques non supprimées.

Tests / résultat : Cinq définitions valides et sources présentes : test réussi.

Reste à vérifier : Normalisation complète des 98 entrées et des 45 fiches non terminée.

## A14 — Écart lexical de fiche

**État :** écart conservé, arbitrage non effectué

Cause / preuve V3 : La fiche V3 insuffisance veineuse demande d’insister sur les racines ; le PDF de la formation indique les toxines. (assets/data/magnetisme_protocoles.json#ft-insuffisance-veineuse).

Attendu : Afficher un différentiel de source et conserver la version personnelle avant toute correction choisie.

Modification : Version historique conservée ; variante V4 séparée et notes de provenance.

Tests / résultat : Aucune substitution silencieuse dans les fiches personnelles.

Reste à vérifier : Racines dans V3 versus toxines dans PDF : choix éditorial à confirmer, aucune physiologie déduite.

## A15 — Acquis à conserver

**État :** partiel, intégration progressive

Cause / preuve V3 : La V3 gère déjà plusieurs motifs, des zones par motif, une édition locale, un défilement vers l’étape suivante, des états de chakra et un historique trié avec recherche patient. (lib/screens/magnetisme_session_screen.dart:55;742;1961;282;lib/services/magnetisme_library_service.dart:64;lib/screens/patients_screen.dart:120).

Attendu : Migrer et consolider ces acquis ; vérifier leur comportement sur appareil séparément de l’audit statique.

Modification : Nouvel aperçu, zones par motif, édition locale, tri/recherche, UUID, sauvegarde et reprise ; parcours historique accessible.

Tests / résultat : Tests Flutter des écrans, du schéma face/dos et des sauvegardes réussis.

Reste à vérifier : Validation complète sur téléphone et parité de tous les champs historiques à terminer.

## A16 — Statut des affirmations

**État :** traité dans le nouveau flux ; historique inchangé

Cause / preuve V3 : Plusieurs supports et textes V3 expriment des effets biologiques, des guérisons, des toxines ou des phénomènes spirituels sans preuve clinique apportée par ces documents. (lib/screens/magnetisme_session_screen.dart:1555;PDF modules 3, 4, 5, 6, 15, 17 à 23).

Attendu : Séparer observation personnelle, intention traditionnelle et information médicale ; supprimer toute conclusion diagnostique automatisée.

Modification : Notice traditionnelle et observations séparées des diagnostics ; aucune conversion automatique de scores en maladie.

Tests / résultat : Contradiction documentaire bloque le plan ; saisie descriptive uniquement.

Reste à vérifier : Revue des formulations historiques et de toutes les fiches non achevée.

## A17 — Balayage

**État :** corrigé dans l’aide V4 ; audio humain à vérifier

Cause / preuve V3 : L’aide V3 décrit des passages lents à 10–15 cm. Les notes 10.01 donnent les répétitions ; les narrations automatiques 10.01 et 13.02 indiquent semi-rapides à environ 10 cm. (lib/screens/magnetisme_session_screen.dart:1843 ; vidéo 10.01, 41–50 s et 71–121 s ; vidéo 13.02, 298–335 s).

Attendu : Technique distincte avec vitesse semi-rapide, hauteur approximative, retour mains fermées et répétitions sourcées ; validation humaine du passage audio avant diffusion.

Modification : Balayage semi-rapide, environ 10 cm, retour mains fermées et plage 30–60 s.

Tests / résultat : Durée et identité de technique distinctes dans le catalogue validé.

Reste à vérifier : Écoute humaine ciblée et détail de l’ordre des membres à confirmer.

## A18 — Plusieurs zones et temps local

**État :** partiel

Cause / preuve V3 : La démonstration 13.02 annonce environ 5 min par point, à réduire en présence de nombreux points pour rester dans 10–15 min de travail local global. Cette précision n’était pas représentée dans les exigences V0.1. (vidéo 13.02, 174–200 s, transcription automatique ; construction V3 lib/screens/magnetisme_session_screen.dart).

Attendu : Afficher une estimation globale et demander une répartition explicite ; ne pas réduire une durée fixe d’une fiche sans signaler le conflit.

Modification : Avertissement de budget local sans réduction automatique des durées fixes.

Tests / résultat : Plusieurs zones totalisant 2100 s : avertissement, aucune troncature ; test réussi.

Reste à vérifier : Interface de répartition du budget et règles par fiche encore à développer.
