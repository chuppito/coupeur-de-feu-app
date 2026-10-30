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
