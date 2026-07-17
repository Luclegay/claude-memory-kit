---
name: lecon
description: Transforme une erreur résolue en leçon réutilisable. À utiliser juste après avoir corrigé un bug, une commande qui échouait ou une mauvaise hypothèse — pour que la prochaine session ne répète pas l'erreur.
---

# Enregistrer une leçon (boucle d'apprentissage des erreurs)

Une erreur vient d'être diagnostiquée et corrigée. Capture-la MAINTENANT, pendant
que le contexte est frais : c'est ce qui rend l'agent meilleur à la session
suivante (« la deuxième fois, la tâche réussit du premier coup »).

## 1. Vérifier l'existant

`grep` dans `memoire/lecons/` : si une leçon couvre déjà cette erreur,
mets-la à jour (compteur d'occurrences, précision de la cause) au lieu de dupliquer.

## 2. Écrire la leçon

Crée `memoire/lecons/<AAAA-MM-JJ>-<slug-court>.md` :

```markdown
---
name: <slug-court>
description: <l'erreur en une ligne, formulée comme un symptôme reconnaissable>
type: lecon
date: <AAAA-MM-JJ>
source: session <8 premiers caractères de l'id de session si connu>
---

# Leçon : <titre parlant>

**Symptôme** : <ce qu'on observe quand l'erreur se produit (message exact si utile)>

**Cause racine** : <la vraie cause, pas le symptôme>

**Correction appliquée** : <ce qui a marché, commande ou modification précise>

**Prévention** : <le réflexe à avoir AVANT d'agir pour ne plus tomber dedans>
```

Règles : dates absolues, pas de secrets, 15 lignes maximum, une erreur par fichier.

## 3. Indexer et solder le journal

1. Ajoute une ligne dans `memoire/MEMOIRE.md`, section « Leçons apprises ».
2. Ouvre `memoire/erreurs/journal.md` et repère les lignes correspondant à cette
   erreur. Annote chacune avec l'outil Edit en AJOUTANT ` [traité → lecons/<fichier>]`
   en fin de ligne, sans rien supprimer du texte d'origine (le garde-fou n'autorise
   que cette forme d'édition du journal).

## 4. Restituer

Termine par une phrase à l'utilisateur : « Leçon enregistrée : <titre>. La
prochaine session la verra au démarrage. »
