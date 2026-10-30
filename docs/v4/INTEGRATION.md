# Intégration V4 progressive

L’entrée « Parcours V4 » de l’accueil ouvre un espace séparé. Le parcours historique reste accessible. La V4 ne convertit pas les textes par mots-clés.

Le catalogue initial comporte quatre fiches présentielles (entorse, eczéma, arthrose, insuffisance veineuse) et une trame à distance sur support. Il ne représente pas la migration complète des fiches de la formation. Chaque aperçu expose ses sources et les incertitudes conservées. Les trajets précis des articulations multizones restent à normaliser ; consulter les références avant leur emploi. Les informations ambiguës ne deviennent pas des règles automatiques.

Les zones sont propres à chaque sélection et gardent leur côté et leur face. Le schéma V4 utilise le côté anatomique : face au patient, sa droite apparaît à gauche de l’écran ; de dos, elle apparaît à droite. Le schéma V3 garde son comportement existant.

Une durée provient de DurationSpec pour son libellé et son compte à rebours. Une plage demande un choix personnel borné ; sans choix, la progression reste manuelle. Le lecteur démarre en pause et se remet en pause lorsque l’application quitte le premier plan. Il garde le haut de la nouvelle action visible. Aucune lecture sonore n’est ajoutée ; le maintien de l’écran utilise wakelock_plus au premier plan. Une défaillance de maintien de l’écran ou de sauvegarde est affichée.

Le bilan V4 conserve les demandes, les données rapportées et les observations traditionnelles, sans conversion automatique gauche/droite des chakras. Les prières sont liées par identifiant explicite à la bibliothèque existante, y compris ses versions personnelles. Les séances conservent un instantané autonome, leurs observations et les identifiants stables de progression. La reprise ne relit pas une fiche qui aurait été modifiée depuis.

Les patients V4 ont des UUID distincts, y compris les homonymes. Recherche sans accents et tri nom/prénom. Les imports refusent les conflits avant la première écriture. Les exportations incluent les métadonnées de conservation des originaux V3. Le transfert est pour l’instant une sauvegarde JSON copiée/collée, pas un service cloud.

Validation : tests du moteur, du lecteur, des boîtes Hive temporaires et de l’interface Flutter. Cela ne constitue pas une validation sur téléphone réel ni une validation médicale des méthodes traditionnelles.
