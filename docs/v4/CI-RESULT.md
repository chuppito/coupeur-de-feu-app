# Validation Android et tests — résultat final V0.4

Code validé : c673ee6c7fd4cc7e0f30068c96c9efd561beffb6.

- Exécution : https://github.com/chuppito/coupeur-de-feu-app/actions/runs/41078836721
- Job : 124142204862, terminé avec succès.
- Flutter 3.47.9 / Dart 3.13.7 ; JDK 21, runner Linux GitHub avec SDK Android.
- Résolution des dépendances verrouillée : réussite.
- Analyse ciblée du moteur, des tests et de son intégration : aucune anomalie.
- Suite complète : 46 tests réussis (journal : 00:04 +46).
- Compilation : flutter build apk --debug --no-pub, réussite, app-debug.apk produit.
- Artefact : magnetisme-v4-debug, ID 12988093863, 89717235 octets pour son archive ZIP.
- Téléchargement : https://github.com/chuppito/coupeur-de-feu-app/actions/runs/41078836721/artifacts/12988093863
- SHA-256 de l’archive d’artefact (pas de l’APK seul) : 68894241a9ab102c82cffbee7f04142f5256e347a722a85a45317d726beae694.
- Expiration annoncée de l’artefact : 13 novembre 2026 à 15:19:44 UTC.

Il s’agit d’un APK debug compilé, sans essai sur téléphone. La conservation de l’écran, l’absence effective de son, l’arrêt forcé, les anciennes données réelles et l’ergonomie complète restent à vérifier sur appareil. Le SDK Android n’est pas installé dans l’environnement local ; cette compilation est celle de GitHub Actions.

Le compilateur signale une compatibilité future à surveiller pour les plugins utilisant encore Kotlin Gradle Plugin (file_picker, package_info_plus, share_plus, wakelock_plus). Ce sont des avertissements, pas des erreurs de cette compilation. Aucune mise à jour non testée des plugins n’a été ajoutée.

Les méthodes restent traditionnelles. Une réussite de tests et de compilation ne valide pas médicalement les protocoles. Les 62 vidéos restantes et les autres fiches doivent encore être étudiées/normalisées.
