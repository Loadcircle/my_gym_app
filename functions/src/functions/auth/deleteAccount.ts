import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/**
 * Cloud Function callable para eliminar cuenta de usuario.
 * Borra: Firestore data, Storage files, Firebase Auth user.
 */
export const deleteAccount = functions.https.onCall(async (data, context) => {
  // 1. Verificar autenticacion
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Usuario no autenticado"
    );
  }

  const uid = context.auth.uid;
  const db = admin.firestore();
  const storage = admin.storage().bucket();

  try {
    // 2. Borrar subcolecciones de usuario en Firestore
    const userDocRef = db.collection("users").doc(uid);

    // Borrar customExercises
    const customExercises = await userDocRef.collection("customExercises").get();
    for (const doc of customExercises.docs) {
      await doc.ref.delete();
    }

    // Borrar routines y sus items (subcoleccion)
    const routines = await userDocRef.collection("routines").get();
    for (const routine of routines.docs) {
      const items = await routine.ref.collection("items").get();
      for (const item of items.docs) {
        await item.ref.delete();
      }
      await routine.ref.delete();
    }

    // Borrar routineCompletions
    const completions = await userDocRef.collection("routineCompletions").get();
    for (const doc of completions.docs) {
      await doc.ref.delete();
    }

    // Borrar documento de usuario
    await userDocRef.delete();

    // 3. Borrar weightRecords del usuario (coleccion root)
    const weightRecords = await db.collection("weightRecords")
      .where("userId", "==", uid)
      .get();
    for (const doc of weightRecords.docs) {
      await doc.ref.delete();
    }

    // 4. Borrar archivos de Storage del usuario
    const [files] = await storage.getFiles({prefix: `users/${uid}/`});
    for (const file of files) {
      await file.delete();
    }

    // 5. Eliminar usuario de Firebase Auth
    await admin.auth().deleteUser(uid);

    return {success: true};
  } catch (error) {
    console.error("Error eliminando cuenta:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Error al eliminar la cuenta. Intenta de nuevo."
    );
  }
});
