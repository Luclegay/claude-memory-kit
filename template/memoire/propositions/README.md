# Propositions (à valider par un humain)

Ici atterrissent :
- les **propositions du dreaming** (fichiers `AAAA-MM-JJ-dreaming.md`) : chaque
  proposition vient avec ses preuves (extraits de sessions) et ses statistiques
  (« vu 4 fois sur 6 sessions ») ;
- les **propositions de l'agent** pour modifier la mémoire partagée
  `memoire/organisation/` (qu'il n'a pas le droit de toucher directement).

## Comment valider

1. Ouvrez le fichier de propositions.
2. Pour chaque proposition, remplacez `[ ]` par `[OK]` (accepter) ou `[NON]` (refuser).
3. Lancez `claude` puis tapez `/dreaming appliquer` : seules les propositions
   marquées `[OK]` sont appliquées, le fichier est ensuite archivé avec un suffixe
   `-traite.md`.

Rien ne s'applique tout seul : **c'est vous qui décidez** (recommandation explicite
de la conférence : le dreaming propose, l'humain dispose).
