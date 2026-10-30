# Migration préparatoire sans destruction

Le menu V4 « Préparer la migration V3 » copie les boîtes V3 déjà ouvertes. Il n’écrit jamais dans ces boîtes. Les fiches personnelles sont conservées comme originaux et ne sont pas interprétées comme protocoles exécutables.

1. Sérialiser les données et vérifier leur forme avant toute écriture.
2. Enregistrer puis forcer la sauvegarde d’un instantané identifié par son empreinte.
3. Préparer des entrées de revue, avec clé d’origine typée et empreinte du contenu.
4. Associer au besoin une entrée à un UUID patient, après choix explicite. Aucun rapprochement automatique par nom ; aucune association existante n’est écrasée.
5. Exporter l’ensemble V4, métadonnées et originaux inclus. L’import valide tous les éléments et refuse les conflits.

Une nouvelle version d’un original V3 produit une autre entrée ; une nouvelle exécution à contenu identique ne duplique rien. Aucun champ personnel n’est supprimé. Les originaux restent consultables dans la revue ; leur conversion en véritables séances V4 modifiables reste à développer.

Tests : répétition idempotente, sauvegarde préalable, original inchangé, homonymes, refus de réassociation, fiches personnelles non interprétées et export/restauration des originaux. À vérifier encore sur une copie réelle des données utilisateur : volumes, anciens schémas inhabituels et interruption du processus pendant une écriture. Les tests utilisent des données fictives.
