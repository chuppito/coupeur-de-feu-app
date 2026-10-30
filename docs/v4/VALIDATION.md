# Validation progressive V4

30 octobre 2026. Flutter 3.47.9, Dart 3.13.7, Linux.

Phase A : modèles explicites et moteur ; analyse statique du domaine sans anomalie ; vingt tests initiaux du moteur passants avant le commit.

Phase B : vingt-huit tests moteur et progression passants. Cas couverts : quatre motifs, cibles répétées par bloc, provenance multiple, cycle d'ordre, partage incompatible, interdiction des gestes corporels à distance, source contradictoire, durée inconnue ou choisie dans une plage, identifiants stables, conditions non renseignées, instantané JSON, budget local sans troncature, immutabilité imbriquée, pause/reprise, fin de minuteur et restauration corrompue.

Commandes exécutées : `flutter test test/v4 --reporter expanded` et `flutter analyze lib/v4 test/v4`. Résultat : 28 tests passants, aucune anomalie dans cette analyse ciblée.

La compilation Android et les essais sur appareil ne sont pas couverts par ce point intermédiaire. Les tests n'établissent aucune efficacité médicale des méthodes.
