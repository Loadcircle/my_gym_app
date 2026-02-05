# GymVault - Production Checklist

## Estado Actual
- **Versión**: 1.0.0+1
- **Fecha auditoría**: 2024

---

## Antes de Testear en Prod

- [x] Desplegar reglas Firestore y Storage:
  ```bash
  firebase deploy --only firestore:rules,storage:rules --project prod
  ```
- [x] Desplegar Cloud Function:
  ```bash
  cd functions && npm run build && firebase deploy --only functions:deleteAccount --project prod
  ```
- [ ] Obtener SHA-1 y SHA-256 de Play Store
- [ ] Agregar SHA fingerprints a Firebase Console (proyecto prod)
- [ ] Probar Google Sign-In en prod
- [x] Actualizar fecha en terminos y politicas

---

## Antes de Publicar en Play Store

### Crítico (Bloqueante)
- [x] Crear keystore de producción
- [x] Configurar signing config en `android/app/build.gradle.kts`
- [x] Verificar que APK está firmado correctamente

### Importante
- [ ] Habilitar ProGuard/R8 para ofuscación
- [x] Regenerar OpenAI API key (está expuesta en `functions/.env`)
- [x] Mover secrets a Firebase Secrets o variables de entorno seguras

### Recomendado
- [x] Test completo de flujo de login/logout en prod
- [ ] Test de deleteAccount en prod
- [ ] Verificar Crashlytics recibe errores
- [ ] Probar build release: `flutter build apk --flavor prod -t lib/main_prod.dart --release`

---

## iOS (Futuro)

- [ ] Completar Info.plist con descripciones de permisos
- [ ] Configurar App Store Connect
- [ ] Configurar signing con Apple Developer account
- [ ] Agregar GoogleService-Info.plist para iOS

---

## Notas

### Configuración actual correcta:
- Firebase AppCheck: debug (dev) / playIntegrity (prod) ✓
- Crashlytics: solo prod ✓
- Debug logs: solo dev ✓
- Firebase Rules: bien configuradas ✓
- Cloud Function deleteAccount: lista ✓

### Archivos de configuración Firebase:
- Dev: `android/app/src/dev/google-services.json`
- Prod: `android/app/src/prod/google-services.json`
