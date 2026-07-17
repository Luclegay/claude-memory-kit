# Publier ce kit sur GitHub — pas à pas

> Guide pour mettre ce dépôt local en ligne sur votre compte GitHub
> (exemple avec le compte `Luclegay`). Chaque commande est expliquée.

## Étape 1 — Vérifier l'état local

```bash
cd ~/Desktop/claude-memory-kit
git status
```
`git status` montre l'état du dépôt. Vous devez voir « nothing to commit, working
tree clean » (tout est déjà enregistré). Si des fichiers apparaissent en rouge :

```bash
git add -A                            # « prépare tous les fichiers »
git commit -m "Ajustements avant publication"   # « enregistre avec ce message »
```

## Étape 2 — Créer le dépôt sur GitHub (interface web, le plus simple)

1. Allez sur https://github.com/new (connecté à votre compte).
2. **Repository name** : `claude-memory-kit`
3. **Description** : `Mémoire en fichiers + apprentissage des erreurs + Dreaming pour Claude Code (d'après la conférence de Lamis Mukta, Anthropic)`
4. Choisissez **Public**.
5. ⚠️ Ne cochez AUCUNE case (« Add a README », « Add .gitignore », « license ») :
   le dépôt local les contient déjà — les cocher créerait des conflits.
6. Cliquez **Create repository**.

## Étape 3 — Relier le dépôt local à GitHub et envoyer

GitHub affiche alors une page d'instructions. C'est la section
« …or push an existing repository from the command line » qui nous concerne :

```bash
cd ~/Desktop/claude-memory-kit
git remote add origin https://github.com/Luclegay/claude-memory-kit.git
git branch -M main
git push -u origin main
```

Ce que fait chaque ligne :
- `git remote add origin <url>` : « le dépôt en ligne s'appelle *origin* et vit à
  cette adresse » ;
- `git branch -M main` : renomme la branche courante en `main` (le standard) ;
- `git push -u origin main` : envoie tout vers GitHub et mémorise la liaison
  (les prochains envois seront un simple `git push`).

Si le Terminal demande un mot de passe : GitHub n'accepte plus les mots de passe,
il faut un **jeton d'accès** (Settings → Developer settings → Personal access
tokens → *Generate new token (classic)*, cochez `repo`) à coller à la place du
mot de passe. Alternative plus confortable : installer l'outil officiel
`brew install gh` puis `gh auth login`, et l'authentification est gérée pour vous.

## Étape 4 — Vérifier

Ouvrez https://github.com/Luclegay/claude-memory-kit : le README s'affiche en
page d'accueil, avec le schéma. C'est en ligne ! 🎉

## Pour les mises à jour futures

```bash
cd ~/Desktop/claude-memory-kit
git add -A
git commit -m "Description courte de la modification"
git push
```
