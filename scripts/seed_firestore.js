/**
 * Script para poblar Firestore con datos de prueba
 *
 * Uso:
 *   1. Instalar firebase-admin: npm install firebase-admin
 *   2. Descargar service account key desde Firebase Console:
 *      Project Settings > Service accounts > Generate new private key
 *   3. Guardar como serviceAccountKey.json en este directorio
 *   4. Ejecutar: node seed_firestore.js
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Inicializar Firebase Admin con service account key
const env = process.env.ENV || "dev"; // dev por defecto

const keyPath = path.join(__dirname, `serviceAccountKey.${env}.json`);
const serviceAccount = require(keyPath);
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Leer datos seed
const seedData = JSON.parse(
  fs.readFileSync(path.join(__dirname, '..', 'firestore_seed_data.json'), 'utf8')
);

async function clearExercises() {
  console.log('Clearing existing exercises...');
  const snapshot = await db.collection('exercises').get();

  if (snapshot.empty) {
    console.log('  No existing exercises to clear');
    return;
  }

  const batch = db.batch();
  snapshot.docs.forEach(doc => batch.delete(doc.ref));
  await batch.commit();
  console.log(`  Deleted ${snapshot.size} exercises`);
}

async function seedExercises() {
  console.log('Seeding exercises...');
  const batch = db.batch();

  for (const exercise of seedData.exercises) {
    const docRef = db.collection('exercises').doc(exercise.id);

    // El seed data ya tiene el formato correcto para el modelo Flutter:
    // - muscleGroup: string con nombre en español (Pecho, Espalda, etc.)
    // - instructions: string con pasos separados por \n
    // - order: número para ordenar dentro del grupo
    batch.set(docRef, {
      name: exercise.name,
      muscleGroup: exercise.muscleGroup,
      description: exercise.description || '',
      instructions: exercise.instructions || '',
      imageUrl: exercise.imageUrl || null,
      videoUrl: exercise.videoUrl || null,
      order: exercise.order || 0
    });
  }

  await batch.commit();
  console.log(`  Created ${seedData.exercises.length} exercises`);
}

async function main() {
  try {
    console.log('Starting Firestore seed...\n');
    console.log('Project ID:', serviceAccount.project_id);
    console.log('');

    // Limpiar ejercicios existentes antes de crear nuevos
    await clearExercises();

    // Crear nuevos ejercicios
    await seedExercises();

    console.log('\nSeed completed successfully!');
    console.log('\nExercises created:');

    // Mostrar resumen por grupo muscular
    const groups = {};
    seedData.exercises.forEach(ex => {
      groups[ex.muscleGroup] = (groups[ex.muscleGroup] || 0) + 1;
    });
    Object.entries(groups).forEach(([group, count]) => {
      console.log(`  - ${group}: ${count} ejercicios`);
    });

    process.exit(0);
  } catch (error) {
    console.error('Error seeding Firestore:', error);
    process.exit(1);
  }
}

main();
