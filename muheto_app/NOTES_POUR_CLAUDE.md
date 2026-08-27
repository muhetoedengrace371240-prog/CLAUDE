# Note de passation — à lire en plus de MEMO.md

> Ceci n'est PAS un fichier technique. MEMO.md te dit CE QUI EXISTE dans le code.
> Ce fichier te dit COMMENT TRAVAILLER AVEC CETTE PERSONNE. Les deux sont complémentaires.
> Écrit le 27/08/2026, après plusieurs sessions de travail avec Eden sur MUHETO.

---

## Qui est la personne, et comment lui parler

Eden ne code pas et ne connaît pas le vocabulaire technique. Elle a pourtant mené un projet Flutter/Firebase assez avancé jusqu'ici — mais en délégant TOUT le code à des IA (moi dans des conversations précédentes, puis Gemini pour l'intégration dans VS Code, et moi à nouveau maintenant). Elle exécute des instructions précises, elle ne les invente ni ne les devine.

**Ce qui marche très bien avec elle, ne pas s'en écarter :**
- Expliquer chaque terme technique avec une image simple avant de l'utiliser (le "château de Lego" pour expliquer les briques de code, le "tapis magique" pour les `Localizations`, etc.). Elle a explicitement demandé du "ELI10" à un moment — garder ce réflexe même si elle ne le redemande pas.
- **Une seule action à la fois.** Ne jamais donner 5 étapes d'un coup en espérant qu'elle les fasse toutes puis revienne. Une étape, elle l'exécute, elle montre une capture, on vérifie, on passe à la suivante.
- **Toujours vérifier avant qu'elle sauvegarde**, surtout pour du JSON (elle a fait l'erreur de mal placer une accolade fermante `}` avant le bon endroit, plusieurs fois) et pour l'indentation YAML (piège classique de GitHub Actions). Le réflexe "montre-moi avant d'enregistrer" lui évite de casser des choses et lui apprend à repérer les erreurs elle-même petit à petit.
- Elle **prend des captures d'écran** en permanence plutôt que de copier du texte — c'est son mode de communication naturel avec moi. Accepter ça, ne pas systématiquement lui demander de copier-coller à la place (même si le texte est objectivement plus fiable à lire).
- Elle communique aussi via WhatsApp Image (elle transfère probablement les captures de son téléphone via WhatsApp vers elle-même). Rien à faire de spécial, juste savoir que le nom du fichier ne donne aucune indication utile.

**Ce qui ne marche pas / à éviter :**
- Ne pas supposer qu'elle sait ce que veut dire "terminal", "commit", "sauvegarder un fichier" sans lui montrer où cliquer la première fois qu'un terme apparaît.
- Ne pas donner un bloc de code de 100 lignes à "adapter selon ses besoins" — elle a besoin du bloc exact à copier-coller, avec l'endroit précis où le mettre.
- Ne pas s'étonner si elle demande "c'est qui qui vient de faire ça ?" en voyant un fichier déjà existant qu'elle ne se rappelle pas avoir créé — répondre calmement, sans laisser sous-entendre une erreur de sa part : très probablement une manipulation de sa part quelques minutes plus tôt (double-clic, tentative précédente) plutôt qu'un mystère.

---

## Contexte du projet qui n'est pas dans MEMO.md

**Historique des intervenants** — attention aux incohérences de style :
1. Les 13 premières "briques" de code ont été écrites par moi (Claude, conversation web), livrées sous forme de zips téléchargeables un par un.
2. Eden a ensuite intégré ces briques dans VS Code + GitHub, guidée pas à pas par **Gemini** (Gemini Code Assist, dans VS Code) — pas par moi. Gemini a pu faire des choix différents des miens à cette étape (par exemple, c'est probablement Gemini qui a configuré `analysis_options.yaml` au départ, avant qu'on ne découvre que c'était en fait le template par défaut de Flutter).
3. Une **Brique 14** existe en zip séparé (traduction complète, écran Paramètres, nettoyage dépréciations) mais n'a JAMAIS été intégrée telle quelle — on a réintégré ses éléments un par un manuellement pendant nos sessions (suppression de compte, CGU). Si Eden mentionne "la brique 14", vérifier ce qui a réellement été fait avant de supposer que tout le zip a été appliqué.
4. Un zip nommé `CLAUDE.zip` peut circuler et représenter un **instantané figé à un moment donné**, pas nécessairement synchronisé avec l'état réel du dépôt GitHub. Si elle en envoie un nouveau, vérifier la date du dernier commit dans son historique Git avant de s'y fier pour une réponse.

**Environnement de travail d'Eden :**
- PC Windows, VS Code, terminal PowerShell.
- Dossier de travail : `C:\Users\LENOVO\Downloads\CLAUDE\muheto_app\`
- Utilise WinRAR (version d'essai) pour extraire les zips.
- Téléphone de test : Infinix HOT 40i (Android), connecté en USB pour transférer les APK.
- Son dossier Téléchargements est très encombré (documents de cours, PDF, rapports sans rapport avec le projet) — quand on cherche un fichier avec elle, s'attendre à devoir distinguer plusieurs fichiers au nom similaire (`app-debug.apk`, `app-debug (1).zip`, etc.) et vérifier systématiquement par la **taille en octets**, pas par le nom, avant de lui faire transférer quoi que ce soit sur le téléphone. C'est déjà arrivé deux fois qu'elle teste une ancienne version par erreur à cause de ça.

**Localisation géographique — pertinent pour certaines décisions :**
Eden semble basée au Burundi (Bujumbura), le numéro de téléphone du compte Google est un numéro burundais, et l'app cible justement le Burundi/l'Afrique. Ça a une incidence concrète : l'accès à une carte bancaire internationale pour activer Firebase Blaze n'est pas trivial pour elle (voir MEMO.md section 4.9) — ne pas traiter ça comme un simple "il suffit d'ajouter une carte", montrer de la patience et proposer des pistes locales (carte prépayée, mobile money avec carte virtuelle) si le sujet revient.

**État émotionnel / rapport au projet :**
Elle est visiblement très investie dans ce projet (nom du dossier "CLAUDE" en majuscules, features poussées comme MUHETO Gold, 4 langues dont le Kirundi). Elle pose parfois des questions qui trahissent une légère anxiété face à la technique ("tu es sûr que tu te rappelleras de tout ?"). Rassurer factuellement sans minimiser la vraie limite (pas de mémoire entre conversations) — elle a bien compris et accepté l'explication la dernière fois, pas besoin de re-simplifier à l'excès si elle revient dessus, juste confirmer.

---

## Pièges déjà rencontrés qui pourraient se reproduire

- **Copier-coller entre onglets VS Code** : au moins un incident où le contenu d'un fichier (`comment_model.dart`) a été entièrement écrasé par le contenu d'un autre fichier ouvert en même temps (`MEMO.md`), probablement un `Ctrl+A`/`Ctrl+V` sur le mauvais onglet actif. Si un fichier Dart semble contenir du texte en français explicatif plutôt que du code, c'est probablement ça — pas la peine de chercher une explication plus complexe, juste restaurer le bon contenu.
- **"git commit" qui dit "nothing to commit"` alors qu'on vient de modifier un fichier** : dans notre cas, le fichier était en fait déjà sauvegardé avec le bon contenu (on avait eu un doute pour rien) — mais garder en tête que ça peut aussi vouloir dire que le collage a été fait dans le mauvais fichier ou pas sauvegardé du tout. Toujours faire confirmer par `git status` avant de s'inquiéter ou de refaire un travail déjà fait.
- **VS Code garde plusieurs versions/onglets du même nom de fichier ouverts** (ex: plusieurs `MEMO.md` provenant de dossiers différents) — toujours vérifier le chemin complet affiché en haut de l'éditeur avant de dire "c'est bon", pas juste le nom de l'onglet.

---

## Pour la suite probable du projet

Au moment de cette note, le prochain vrai blocage business est **Firebase Storage / plan Blaze** (carte bancaire). Tant que ce n'est pas réglé, éviter de proposer des tâches qui en dépendent (upload avatar, logo business, vidéo) comme "prochaine étape" par défaut — proposer plutôt : peaufinage UI, vérification des règles Firestore restantes, préparation du contenu (catégories, textes), ou tout ce qui ne touche pas à Storage.
