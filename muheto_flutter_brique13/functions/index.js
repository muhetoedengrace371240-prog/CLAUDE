/**
 * MUHETO — Cloud Functions : déclencheurs de notifications push (Brique 11)
 *
 * ⚠️ POURQUOI CE CODE NE PEUT PAS ÊTRE CÔTÉ CLIENT (Flutter/Dart) :
 * Envoyer une notification FCM à UN AUTRE utilisateur nécessite les droits
 * d'administrateur Firebase (Admin SDK), qui ne doivent JAMAIS être exposés
 * dans une app mobile — n'importe qui pourrait décompiler l'app et récupérer
 * la clé pour envoyer des notifications à n'importe qui. C'est pour ça que
 * l'envoi se fait ici, côté serveur, dans une Cloud Function déclenchée
 * automatiquement par une écriture Firestore.
 *
 * DÉPLOIEMENT :
 *   cd functions
 *   npm install
 *   firebase deploy --only functions
 *
 * Nécessite le plan Firebase "Blaze" (pay-as-you-go) — les Cloud Functions
 * qui font des appels réseau sortants (comme envoyer via FCM) ne sont pas
 * disponibles sur le plan gratuit "Spark". Le coût réel reste minime pour
 * un volume de notifications de lancement (quota gratuit mensuel généreux
 * même sur Blaze).
 */

const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Envoie une notification à [uid] si un token FCM est enregistré sur son
 * profil. Ne fait rien silencieusement si l'utilisateur n'a jamais donné la
 * permission notifications (pas de token) — ce n'est pas une erreur.
 */
async function sendToUser(uid, { title, body, data }) {
  const userDoc = await db.collection('users').doc(uid).get();
  const fcmToken = userDoc.data()?.fcmToken;
  if (!fcmToken) return;

  try {
    await messaging.send({
      token: fcmToken,
      notification: { title, body },
      // Le payload `data` DOIT être un objet de strings uniquement (contrainte FCM).
      data,
      android: { priority: 'high' },
      apns: { payload: { aps: { sound: 'default' } } },
    });
  } catch (error) {
    // Un token invalide/expiré (désinstallation de l'app, etc.) ne doit
    // jamais faire planter la fonction — on logge et on continue.
    console.error(`Échec d'envoi FCM à ${uid}:`, error.message);

    // Nettoyage : si le token n'est plus valide, on le retire pour éviter
    // de retenter inutilement à chaque prochain message/commentaire/follow.
    const invalidTokenCodes = [
      'messaging/invalid-registration-token',
      'messaging/registration-token-not-registered',
    ];
    if (invalidTokenCodes.includes(error.code)) {
      await db.collection('users').doc(uid).update({
        fcmToken: admin.firestore.FieldValue.delete(),
      });
    }
  }
}

/**
 * ★ DÉCLENCHEUR PRINCIPAL DEMANDÉ (Brique 11, point 3) ★
 * Notifie le destinataire d'un nouveau message Eden Chat.
 * Se déclenche à chaque écriture dans chats/{chatId}/messages/{messageId}.
 */
exports.onNewChatMessage = onDocumentCreated(
  'chats/{chatId}/messages/{messageId}',
  async (event) => {
    const message = event.data?.data();
    if (!message) return;

    const { chatId } = event.params;
    const chatDoc = await db.collection('chats').doc(chatId).get();
    const chat = chatDoc.data();
    if (!chat) return;

    const recipientUid = (chat.participants || []).find((uid) => uid !== message.senderId);
    if (!recipientUid) return;

    const senderInfo = (chat.participantsInfo || {})[message.senderId] || {};
    const senderUsername = senderInfo.username || 'Quelqu\'un';

    await sendToUser(recipientUid, {
      title: `${senderUsername} t'a envoyé un message`,
      body: message.text || '',
      data: {
        type: 'chat',
        chatId: chatId,
        otherUserId: message.senderId,
        otherUsername: senderUsername,
        otherAvatarUrl: senderInfo.avatarUrl || '',
      },
    });
  },
);

/**
 * ★ EXTENSION (mentionnée dans le message d'intro de la brique) ★
 * Notifie l'auteur d'une vidéo quand quelqu'un la commente.
 */
exports.onNewComment = onDocumentCreated(
  'videos/{videoId}/comments/{commentId}',
  async (event) => {
    const comment = event.data?.data();
    if (!comment) return;

    const { videoId } = event.params;
    const videoDoc = await db.collection('videos').doc(videoId).get();
    const video = videoDoc.data();
    if (!video) return;

    // On ne notifie pas un créateur qui commente sa propre vidéo.
    if (video.userId === comment.userId) return;

    await sendToUser(video.userId, {
      title: `${comment.username} a commenté ta vidéo`,
      body: comment.text || '',
      data: {
        type: 'comment',
        videoId: videoId,
      },
    });
  },
);

/**
 * ★ EXTENSION (mentionnée dans le message d'intro de la brique) ★
 * Notifie un utilisateur quand il gagne un nouvel abonné.
 */
exports.onNewFollower = onDocumentCreated(
  'users/{uid}/followers/{followerUid}',
  async (event) => {
    const { uid, followerUid } = event.params;

    const followerDoc = await db.collection('users').doc(followerUid).get();
    const follower = followerDoc.data();
    if (!follower) return;

    await sendToUser(uid, {
      title: 'Nouvel abonné 🎉',
      body: `@${follower.username || 'Quelqu\'un'} a commencé à te suivre.`,
      data: {
        type: 'follow',
        followerId: followerUid,
      },
    });
  },
);
