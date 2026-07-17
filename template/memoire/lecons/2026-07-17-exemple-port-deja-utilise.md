---
name: exemple-port-deja-utilise
description: EXEMPLE — le serveur local refuse de démarrer car le port 3000 est déjà pris.
type: lecon
date: 2026-07-17
source: fichier d'exemple fourni par le kit (à supprimer quand vous aurez de vraies leçons)
---

# Leçon : port 3000 déjà utilisé au lancement du serveur local

**Symptôme** : `npm run dev` échoue avec `EADDRINUSE: address already in use :::3000`.

**Cause racine** : une session précédente a laissé un serveur tourner en arrière-plan.

**Correction appliquée** : retrouver puis arrêter le processus :
`lsof -ti :3000 | xargs kill`

**Prévention** : avant de lancer un serveur de dev, vérifier si le port répond déjà
(`lsof -ti :3000`) et réutiliser le serveur existant plutôt que d'en lancer un second.

<!-- Ce fichier montre le format attendu par le skill `lecon` :
     un titre clair, symptôme / cause / correction / prévention, et un frontmatter
     avec une date ABSOLUE. Un fait par fichier. -->
