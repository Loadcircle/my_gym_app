# Firebase Setup - My Gym App

## Informacion del Proyecto

| Campo | Valor |
|-------|-------|
| Project ID | `my-gym-app-fd1db` |
| Project Number | `747178948665` |
| Region Firestore | `us-east1` |
| Storage Bucket | `my-gym-app-fd1db.firebasestorage.app` |
| Android App ID | `1:747178948665:android:5852ae9ff82f4f231db5e8` |
| Android Package | `com.example.my_gym_app` |

## 1. Configuracion de Google Sign-In (Pasos Manuales)

### 1.1 Habilitar Google Sign-In en Firebase Console

1. Ve a [Firebase Console](https://console.firebase.google.com/project/my-gym-app-fd1db/authentication/providers)
2. En Authentication > Sign-in method
3. Habilita "Google" como proveedor
4. Configura el nombre publico de la app y el email de soporte
5. Guarda los cambios

### 1.2 Actualizar google-services.json

Despues de habilitar Google Sign-In, descarga el `google-services.json` actualizado:
1. Ve a Project Settings > General
2. En "Your apps", selecciona la app Android
3. Descarga `google-services.json`
4. Reemplaza el archivo en `android/app/google-services.json`

### 1.3 SHA-1 Configurado

El SHA-1 del debug keystore ya esta registrado:
```
BF:8F:0F:28:12:61:63:57:91:6F:A8:05:83:91:60:39:D9:79:9E:11
```

Para produccion, necesitaras agregar el SHA-1 de tu keystore de release.

## 2. Dependencias Flutter (pubspec.yaml)

Agrega las siguientes dependencias:

```yaml
dependencies:
  # Firebase Core
  firebase_core: ^3.8.1

  # Authentication
  firebase_auth: ^5.3.4
  google_sign_in: ^6.2.2

  # Database
  cloud_firestore: ^5.6.0

  # Storage
  firebase_storage: ^12.4.0

  # Crashlytics (opcional pero recomendado)
  firebase_crashlytics: ^4.2.0
```

## 3. Inicializacion en Flutter

### 3.1 main.dart

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Generado por flutterfire configure

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
```

### 3.2 Generar firebase_options.dart (Recomendado)

```bash
# Instalar FlutterFire CLI
dart pub global activate flutterfire_cli

# Configurar proyecto
flutterfire configure --project=my-gym-app-fd1db
```

Esto generara automaticamente `lib/firebase_options.dart` con toda la configuracion.

## 4. Modelo de Datos Firestore

### 4.1 Colecciones

```
firestore/
├── muscle_groups/          # Catalogo de grupos musculares
│   └── {muscleGroupId}
├── exercises/              # Catalogo de ejercicios
│   └── {exerciseId}
└── users/                  # Datos de usuarios
    └── {userId}
        ├── profile         # Documento de perfil (inline)
        └── weight_logs/    # Subcoleccion de registros
            └── {logId}
```

### 4.2 Schema: muscle_groups

```json
{
  "id": "chest",
  "name": "Pecho",
  "nameEn": "Chest",
  "description": "Musculos pectorales mayor y menor",
  "iconName": "fitness_center",
  "sortOrder": 1,
  "isActive": true,
  "createdAt": Timestamp,
  "updatedAt": Timestamp
}
```

### 4.3 Schema: exercises

```json
{
  "id": "bench_press",
  "name": "Press de Banca",
  "nameEn": "Bench Press",
  "description": "Ejercicio compuesto para desarrollar el pecho...",
  "muscleGroupId": "chest",
  "secondaryMuscles": ["shoulders", "arms"],
  "equipment": "barbell",
  "difficulty": "intermediate",
  "instructions": ["Paso 1...", "Paso 2..."],
  "tips": ["Tip 1...", "Tip 2..."],
  "media": {
    "imagePath": "exercises/images/bench_press.jpg",
    "videoPath": "exercises/videos/bench_press.mp4",
    "thumbnailPath": "exercises/thumbnails/bench_press.jpg"
  },
  "searchKeywords": ["press", "banca", "pecho"],
  "isActive": true,
  "createdAt": Timestamp,
  "updatedAt": Timestamp
}
```

### 4.4 Schema: users/{userId}

```json
{
  "uid": "abc123",
  "email": "user@example.com",
  "displayName": "Usuario",
  "photoUrl": "https://...",
  "preferences": {
    "weightUnit": "kg",
    "language": "es",
    "notifications": true
  },
  "createdAt": Timestamp,
  "updatedAt": Timestamp
}
```

### 4.5 Schema: users/{userId}/weight_logs/{logId}

```json
{
  "id": "auto-generated",
  "exerciseId": "bench_press",
  "weight": 80.5,
  "weightUnit": "kg",
  "reps": 10,
  "sets": 3,
  "notes": "Buena sesion",
  "performedAt": Timestamp,
  "createdAt": Timestamp,
  "syncedAt": Timestamp | null
}
```

## 5. Queries Tipicas

### Ejercicios por grupo muscular
```dart
FirebaseFirestore.instance
  .collection('exercises')
  .where('muscleGroupId', isEqualTo: 'chest')
  .where('isActive', isEqualTo: true)
  .orderBy('name');
```

### Historial de peso por ejercicio
```dart
FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .collection('weight_logs')
  .where('exerciseId', isEqualTo: 'bench_press')
  .orderBy('performedAt', descending: true)
  .limit(20);
```

## 6. Estrategia Offline-First

### 6.1 Arquitectura

```
┌─────────────────────────────────────────────────────────┐
│                      Flutter App                         │
├─────────────────────────────────────────────────────────┤
│   ┌─────────────┐         ┌─────────────────────────┐   │
│   │  Drift DB   │◄───────►│    Repository Layer     │   │
│   │  (SQLite)   │         │                         │   │
│   │             │         │  - ExerciseRepository   │   │
│   │  - Logs     │         │  - WeightLogRepository  │   │
│   │  - Cache    │         │  - UserRepository       │   │
│   │  - SyncQ    │         │                         │   │
│   └─────────────┘         └───────────┬─────────────┘   │
│                                       │                  │
│                           ┌───────────▼─────────────┐   │
│                           │   Firestore + Storage    │   │
│                           │   (cuando hay conexion)  │   │
│                           └─────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### 6.2 Principios

1. **Catalogo (exercises, muscle_groups)**:
   - Cache en Drift al primer fetch
   - Refresh periodico o manual
   - Mostrar desde cache, actualizar en background

2. **Weight Logs**:
   - Guardar SIEMPRE primero en Drift
   - Marcar como `syncedAt: null` si offline
   - Sync worker que sube pendientes cuando hay conexion

3. **Resolucion de conflictos**:
   - Estrategia: Last-Write-Wins con `updatedAt`
   - Para MVP es suficiente; refinable post-MVP

## 7. Storage - Estructura de Archivos

```
gs://my-gym-app-fd1db.firebasestorage.app/
└── exercises/
    ├── images/
    │   ├── bench_press.jpg
    │   ├── squat.jpg
    │   └── ...
    ├── videos/
    │   ├── bench_press.mp4
    │   ├── squat.mp4
    │   └── ...
    └── thumbnails/
        ├── bench_press.jpg
        └── ...
```

### Obtener URL firmada en Flutter

```dart
final ref = FirebaseStorage.instance.ref('exercises/images/bench_press.jpg');
final url = await ref.getDownloadURL();
```

## 8. Deploy de Reglas e Indices

```bash
# Deploy solo Firestore rules
firebase deploy --only firestore:rules

# Deploy solo indices
firebase deploy --only firestore:indexes

# Deploy solo Storage rules
firebase deploy --only storage

# Deploy todo
firebase deploy
```

## 9. Seed de Datos de Prueba

### Opcion A: Usando el script Node.js

```bash
cd scripts
npm install firebase-admin
# Configura GOOGLE_APPLICATION_CREDENTIALS o usa service account
node seed_firestore.js
```

### Opcion B: Importar manualmente desde Firebase Console

1. Ve a Firestore en Firebase Console
2. Crea la coleccion `muscle_groups`
3. Agrega documentos usando los datos de `firestore_seed_data.json`
4. Repite para `exercises`

## 10. Checklist de Configuracion

- [x] Proyecto Firebase creado
- [x] App Android registrada
- [x] SHA-1 debug agregado
- [x] google-services.json generado
- [x] Gradle configurado con google-services plugin
- [x] Firestore rules definidas
- [x] Storage rules definidas
- [x] Indices Firestore definidos
- [x] Datos seed preparados
- [ ] Habilitar Google Sign-In en Console (manual)
- [ ] Agregar dependencias Flutter
- [ ] Ejecutar flutterfire configure
- [ ] Subir media a Storage
- [ ] Deploy reglas a produccion
