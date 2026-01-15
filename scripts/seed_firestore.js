/**
 * Script para poblar Firestore con datos de prueba
 *
 * Uso:
 *   1. Instalar firebase-admin: npm install firebase-admin
 *   2. Descargar service account key desde Firebase Console:
 *      Project Settings > Service accounts > Generate new private key
 *   3. Ejecutar: node seed_firestore.js
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Inicializar Firebase Admin con service account key
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Leer datos seed
const seedData = JSON.parse(
  fs.readFileSync(path.join(__dirname, '..', 'firestore_seed_data.json'), 'utf8')
);

async function seedMuscleGroups() {
  console.log('Seeding muscle_groups...');
  const batch = db.batch();

  for (const group of seedData.muscle_groups) {
    const docRef = db.collection('muscle_groups').doc(group.id);
    batch.set(docRef, {
      ...group,
      createdAt: admin.firestore.Timestamp.fromDate(new Date(group.createdAt)),
      updatedAt: admin.firestore.Timestamp.fromDate(new Date(group.updatedAt))
    });
  }

  await batch.commit();
  console.log(`  Created ${seedData.muscle_groups.length} muscle groups`);
}

async function seedExercises() {
  console.log('Seeding exercises...');
  const batch = db.batch();

  for (const exercise of seedData.exercises) {
    const docRef = db.collection('exercises').doc(exercise.id);
    batch.set(docRef, {
      ...exercise,
      createdAt: admin.firestore.Timestamp.fromDate(new Date(exercise.createdAt)),
      updatedAt: admin.firestore.Timestamp.fromDate(new Date(exercise.updatedAt))
    });
  }

  await batch.commit();
  console.log(`  Created ${seedData.exercises.length} exercises`);
}

async function main() {
  try {
    console.log('Starting Firestore seed...\n');

    await seedMuscleGroups();
    await seedExercises();

    console.log('\nSeed completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('Error seeding Firestore:', error);
    process.exit(1);
  }
}

main();
