# Architecture du moteur Magnétisme V4

Le domaine est indépendant de Flutter et de Hive. Le schéma 4 décrit fiches, blocs, actions, cibles, modes, gestes, durées, prières par identifiant et références avec état de vérification. Les instructions ne sont jamais analysées par mots-clés pour produire des étapes.

Le moteur développe chaque bloc local pour ses zones, puis assemble un graphe de dépendances. Un bloc commun n'est partagé que si sa clé explicite et sa signature complète sont compatibles. Les origines et références sont réunies, jamais effacées. La séquence de chaque fiche crée des arêtes ; les contraintes supplémentaires sont vérifiées par tri topologique. Un cycle interdit le démarrage et conserve l'aperçu des actions.

Une durée inconnue reste inconnue. Une plage n'acquiert pas de minuteur automatique avant choix personnel explicite dans les bornes. La même DurationSpec pilote affichage, lecteur et instantané. Une règle contradictoire bloque le plan ; une limite documentaire reste visible. Les scores et intentions décrivent des pratiques traditionnelles et ne produisent aucun diagnostic.

Le nouveau flux est ajouté sur V4 ; les écrans, ressources et données V3 restent accessibles. La migration devra être non destructive, sauvegardée et idempotente. Une fiche ancienne en texte libre n'est jamais considérée comme normalisée par simple import.

Les blocs peuvent déclarer une SessionPhase explicite. Les phases ajoutent des contraintes globales, en conservant toutes les arêtes de l’ordre propre à chaque fiche. Ainsi les conventions supplémentaires des quatre fiches initiales précèdent toutes leurs prières, puis les travaux locaux. Une contradiction entre phase et exception déclarée bloque le plan. L’absence de phase n’est pas interprétée par mots-clés ; elle est signalée lors d’une sélection multiple.

La circulation 09.01 est guidée en six actions distinctes. Pour sacré et racine seulement, la consigne conserve l’exception de départ au plexus si l’envergure est insuffisante. La trame distance expose les huit phases et marque les conventions/prière spécifiques encore à préparer ; cela ne constitue pas une normalisation automatique des fiches distance.
