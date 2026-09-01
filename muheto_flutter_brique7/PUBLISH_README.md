# MUHETO — Brique 3 : Création & Publication

## Fichiers livrés

```
lib/services/upload_service.dart                  → Pipeline complet Storage + Firestore

lib/features/create/create_screen.dart             → Point d'entrée (remplace le placeholder)
lib/features/create/camera_capture_screen.dart      → Capture caméra plein écran
lib/features/create/publish_screen.dart             → Légende, hashtags, catégorie, univers, upload
lib/features/create/widgets/category_selector.dart  → Chips de catégorie réutilisables
lib/features/create/widgets/scope_selector.dart      → Sélecteur Burundi/Afrique/Monde
```

## Flux complet

```
CreateScreen (bouton +)
   ├─ "Caméra"  → CameraCaptureScreen  ──┐
   └─ "Galerie" → image_picker          ├─► PublishScreen(videoFile)
                                          │        │
                                          │        ▼
                                          │   UploadService.publishVideo()
                                          │        │
                                          │        ├─ 1. Génère une miniature (video_thumbnail)
                                          │        ├─ 2. Upload vidéo → Storage videos/{uid}/{id}.mp4
                                          │        ├─ 3. Upload miniature → Storage thumbnails/{uid}/{id}.jpg
                                          │        └─ 4. Crée le doc Firestore videos/{id}
                                          │
                                          └─► Retour automatique au Feed (Navigator.popUntil root)
```

## `UploadService` en détail

- Pré-génère l'id du document Firestore *avant* l'upload, pour nommer les
  fichiers Storage de façon cohérente (`videos/{uid}/{videoId}.mp4`).
- Émet une progression par étape via `onProgress(PublishProgress)` :
  `generatingThumbnail → uploadingVideo (0–100%) → uploadingThumbnail → savingPost`.
- Dénormalise `username`, `userAvatarUrl`, `isVerified` depuis
  `users/{uid}` au moment de la publication, pour que le feed n'ait jamais à
  refaire une lecture supplémentaire par vidéo affichée.
- Laisse `createdAt: null` → `VideoModel.toFirestore()` utilise alors
  `FieldValue.serverTimestamp()`, l'heure serveur fiable plutôt que l'heure
  locale du téléphone.

## ⚠️ Permissions natives à ajouter (obligatoire avant de tester)

### Android — `android/app/src/main/AndroidManifest.xml`
Ajoute ces lignes **avant** la balise `<application>` :
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
```
Et dans `android/app/build.gradle`, vérifie `minSdkVersion 21` minimum
(requis par le package `camera`).

### iOS — `ios/Runner/Info.plist`
Ajoute ces clés :
```xml
<key>NSCameraUsageDescription</key>
<string>MUHETO a besoin de la caméra pour filmer tes vidéos.</string>
<key>NSMicrophoneUsageDescription</key>
<string>MUHETO a besoin du micro pour enregistrer le son de tes vidéos.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>MUHETO a besoin d'accéder à ta galerie pour importer une vidéo.</string>
```

Sans ces clés, l'app plante immédiatement (sans message clair) à l'ouverture
de la caméra ou de la galerie — étape à ne pas sauter.

## Règles Firebase Storage à ajouter (`storage.rules`)

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    match /videos/{uid}/{fileName} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == uid
                   && request.resource.size < 200 * 1024 * 1024 // 200 Mo max
                   && request.resource.contentType.matches('video/.*');
    }

    match /thumbnails/{uid}/{fileName} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == uid
                   && request.resource.contentType.matches('image/.*');
    }
  }
}
```

## Intégration

1. Copie `lib/services/upload_service.dart` et tout `lib/features/create/`
   (il remplace l'ancien placeholder de la Brique 2).
2. Fusionne les nouvelles dépendances de `pubspec.yaml` : `camera`,
   `image_picker`, `video_thumbnail`, `path_provider`.
3. Ajoute les permissions natives ci-dessus, puis `flutter pub get`.
4. Applique les règles Storage dans la console Firebase (Storage → Rules).
5. Teste sur un **vrai appareil** si possible : les émulateurs Android/iOS
   ont un support caméra limité (souvent juste une mire de test).

## Limites volontaires de cette brique (V1)

- Pas de recadrage/trim vidéo côté client (upload du fichier brut tel que
  capturé ou sélectionné).
- Pas de compression avant upload — à ajouter plus tard (`video_compress` ou
  compression côté Cloud Function) si la taille des fichiers pose problème.
- Durée max fixée à 60s en dur dans `camera_capture_screen.dart`
  (`_kMaxRecordingSeconds`) — c'est ici qu'il faudra brancher la vérification
  du statut MUHETO Gold pour débloquer les vidéos de 10 min.

## Prochaines briques possibles

1. Splash / Login / Inscription (Firebase Auth)
2. Profil dynamique branché Firestore + édition
3. Page Business Locale
4. Messagerie temps réel
5. MUHETO Gold (abonnement, déblocage 10 min, badge premium)
6. Localisation multilingue (rn / fr / en / sw)

Dis-moi laquelle tu veux ensuite.
