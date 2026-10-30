# Validation progressive V4

30 octobre 2026. Flutter 3.47.9, Dart 3.13.7, Linux.

Phase A : modèles explicites et moteur ; analyse statique du domaine sans anomalie ; vingt tests initiaux du moteur passants avant le commit.

Phase B : vingt-huit tests moteur et progression passants. Cas couverts : quatre motifs, cibles répétées par bloc, provenance multiple, cycle d'ordre, partage incompatible, interdiction des gestes corporels à distance, source contradictoire, durée inconnue ou choisie dans une plage, identifiants stables, conditions non renseignées, instantané JSON, budget local sans troncature, immutabilité imbriquée, pause/reprise, fin de minuteur et restauration corrompue.

Commandes exécutées : `flutter test test/v4 --reporter expanded` et `flutter analyze lib/v4 test/v4`. Résultat : 28 tests passants, aucune anomalie dans cette analyse ciblée.

La compilation Android et les essais sur appareil ne sont pas couverts par ce point intermédiaire. Les tests n'établissent aucune efficacité médicale des méthodes.

## Intégration et migration préparatoire — 30 octobre 2026

- Phase C : 40 tests réussis sur moteur, lecteur, stockage et interface (sans les quatre tests de migration).
- Phase D : 44 tests réussis sur la suite complète, comprenant migration non destructive et restauration des originaux.
- Analyse statique ciblée : `flutter analyze --no-pub lib/v4 test/v4 lib/widgets/interactive_body.dart test/widget_test.dart` : aucune anomalie.
- Environnement local : Flutter 3.47.9, Dart 3.13.7, Linux. Données fictives uniquement.
- Compilation locale `flutter build apk --debug --no-pub` interrompue avant Gradle : SDK Android absent. Aucun APK local validé.
- La chaîne GitHub Actions V4 réalise résolution verrouillée, analyse ciblée, tests complets et construction APK debug. Son résultat reste à vérifier après publication ; l’existence du workflow n’est pas une compilation réussie.

Les tests d’interface couvrent l’accès depuis l’accueil historique, l’orientation anatomique face/dos, le début de la nouvelle action, le compte à rebours et la pause en arrière-plan. Le lecteur utilise un adaptateur de persistance contrôlé dans ce test ; les sauvegardes Hive et leur relecture après fermeture sont vérifiées séparément. Maintien de l’écran, interruption forcée Android, absence effective de sons sur appareil et restauration de vraies données restent à vérifier sur téléphone.

Le catalogue normalisé initial (quatre fiches présentielles et une trame distance) n’est pas une migration complète des 45 fiches. Les 18 constats ne sont donc pas tous clos sur l’intégralité des contenus.

## Renforcement après dix nouvelles analyses vidéo

46 tests locaux réussis et analyse ciblée sans anomalie. Les deux cas ajoutés vérifient l’ordre global des phases sur les quatre fiches initiales et le refus d’un conflit entre phase et ordre local. La trame distance conserve ses huit phases, dont deux repères explicitement incomplets pour les éléments par motif. La circulation est détaillée en six actions.

Le premier GitHub Actions (commit 4bc7bff, exécution 41076877915) a réussi les 44 tests d’alors et compilé un APK debug. Artefact : magnetisme-v4-debug, ID 12987612652. Cela n’est pas une installation ni un essai sur téléphone. Le contrôle du dernier commit enrichi doit encore être observé avant de lui attribuer ce succès.

La télémétrie des prochaines commandes Flutter est désactivée par FLUTTER_SUPPRESS_ANALYTICS=true. Dans ce SDK, ce réglage retourne NoOpAnalytics ; les tests n’utilisent pas de résolution réseau des paquets grâce à --no-pub.

## Résultat final du code enrichi

Le contrôle 41078836721 du commit c673ee6 est terminé avec succès : 46 tests, analyse ciblée et APK debug compilé. Voir [CI-RESULT.md](CI-RESULT.md) pour la preuve, le téléchargement et ses limites. Les mentions « en attente » ci-dessus décrivent les points de sauvegarde antérieurs.
