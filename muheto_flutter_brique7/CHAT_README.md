# MUHETO — Brique 6 : Messagerie en temps réel

## Fichiers livrés

```
lib/models/chat_model.dart                    → Modèle conversation (vue côté utilisateur connecté)
lib/models/message_model.dart                 → Modèle message

lib/services/chat_service.dart                → Création de chat, envoi, lecture, compteurs non-lus

lib/features/chat/chat_screen.dart            → Salon de discussion temps réel
lib/features/chat/widgets/message_bubble.dart → Bulle de message (dorée / grise)

lib/features/inbox/inbox_screen.dart          → Réécrit : onglet "Messages" branché en direct
lib/features/inbox/widgets/chat_list_tile.dart → Ligne de la liste des conversations
```

Petits ajustements corollaires :
- `profile_screen.dart` — le bouton message (icône bulle, à côté de
  "Suivre") crée ou récupère la conversation et ouvre `ChatScreen`.

## Structure Firestore

```
chats/{chatId}
  - participants: [uid1, uid2]                     (triés alphabétiquement)
  - participantsInfo: { uid: {username, avatarUrl} } (dénormalisé, les 2 côtés)
  - lastMessage: string
  - lastMessageSenderId: string
  - lastMessageAt: Timestamp
  - unreadCounts: { uid1: number, uid2: number }
  - createdAt: Timestamp

chats/{chatId}/messages/{messageId}
  - senderId: string
  - text: string
  - createdAt: Timestamp
```

### Pourquoi un id de chat déterministe ?

`ChatService` construit l'id en triant les deux `uid` et en les joignant par
`_` (`uid_plus_petit_uid_plus_grand`). Résultat : il ne peut jamais exister
deux conversations différentes entre les deux mêmes personnes, et
`getOrCreateChat()` peut vérifier l'existence du document sans avoir besoin
d'une requête `where` coûteuse.

## Comportement temps réel

- **Liste des conversations** (`watchUserChats`) : requête
  `chats where participants array-contains uid orderBy lastMessageAt desc`
  — live, donc l'ordre se met à jour tout seul dès qu'un message arrive.
- **Messages** (`watchMessages`) : triés `descending`, affichés dans un
  `ListView` avec `reverse: true` → comportement de chat naturel (nouveau
  message en bas, scroll automatique).
- **Compteur non-lu** : à l'envoi, `unreadCounts.{destinataire}` est
  incrémenté et `unreadCounts.{expéditeur}` remis à 0, en une seule
  transaction avec la création du message. `markChatAsRead()` est appelé à
  l'ouverture de `ChatScreen` pour remettre le compteur du lecteur à 0.

## Index composite Firestore requis

```
Collection: chats
Fields indexed: participants (Arrays), lastMessageAt (Descending)
```

## Règles Firestore à ajouter (complète les briques précédentes)

```
match /chats/{chatId} {
  allow read: if request.auth != null && request.auth.uid in resource.data.participants;
  allow create: if request.auth != null && request.auth.uid in request.resource.data.participants;
  allow update: if request.auth != null && request.auth.uid in resource.data.participants;

  match /messages/{messageId} {
    allow read: if request.auth != null &&
      request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants;
    allow create: if request.auth != null &&
      request.auth.uid == request.resource.data.senderId &&
      request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants;
    allow update, delete: if false; // messages immuables une fois envoyés
  }
}
```

## Intégration

1. Copie `lib/models/chat_model.dart`, `lib/models/message_model.dart`,
   `lib/services/chat_service.dart`, tout `lib/features/chat/`, et
   remplace `lib/features/inbox/inbox_screen.dart` +
   `lib/features/inbox/widgets/chat_list_tile.dart`.
2. Applique le petit patch sur `profile_screen.dart` (bouton chat).
3. Aucune nouvelle dépendance `pubspec.yaml` — `timeago` était déjà présent
   depuis la Brique 1 pour l'horodatage relatif ("il y a 5 min").
   ⚠️ Ajoute impérativement dans ton `main()`, avant `runApp()` :
   ```dart
   timeago.setLocaleMessages('fr', timeago.FrMessages());
   ```
   (import `package:timeago/timeago.dart as timeago`) — sans ça, l'app
   plante dès qu'une bulle de message ou une ligne de l'Inbox s'affiche.
4. Crée l'index composite ci-dessus et complète tes `firestore.rules`.

## Limites volontaires de cette brique (V1)

- Messages texte uniquement — pas encore d'images, vidéos ou vocaux (à
  ajouter en réutilisant le pattern d'upload de `upload_service.dart`).
- Pas d'indicateur "en train d'écrire..." ni de statut lu/non lu par
  message individuel (seulement un compteur global non-lu par
  conversation).
- Pas de suppression de conversation ni de blocage d'utilisateur.
- `participantsInfo` (username/avatar) est rafraîchi seulement à la
  création du chat — si un utilisateur change de pseudo/avatar après
  coup, l'ancienne info peut apparaître dans la liste de l'autre jusqu'à
  ce qu'un mécanisme de rafraîchissement soit ajouté (ex: à chaque envoi
  de message, comme suggéré en commentaire dans `chat_service.dart`).

## Prochaines briques possibles

1. Page Business Locale
2. MUHETO Gold (abonnement premium, paiement)
3. Localisation multilingue (rn / fr / en / sw)
4. Messages avec médias (photo, vocal)
5. Notifications push (Firebase Cloud Messaging)

Dis-moi laquelle tu veux ensuite.
