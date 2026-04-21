# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Gson - preservar firmas genéricas para TypeToken
# Requerido por flutter_local_notifications para serializar notificaciones programadas
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken { *; }
-keep class com.google.gson.** { *; }

# flutter_local_notifications
-keep class com.dexterous.** { *; }

# Flutter deferred components (Play Core tasks API — not used at runtime)
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task
