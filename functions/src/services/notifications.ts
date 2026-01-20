// functions/src/services/notifications.ts
import * as admin from "firebase-admin";

export async function createInAppNotification(params: {
  db: admin.firestore.Firestore;
  uid: string;
  type: string;
  title: string;
  body: string;
  customId?: string;
  globalId?: string;
}) {
  const { db, uid, type, title, body, customId, globalId } = params;

  await db.collection(`users/${uid}/notifications`).add({
    type,
    title,
    body,
    customId: customId ?? null,
    globalId: globalId ?? null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    read: false,
  });
}
