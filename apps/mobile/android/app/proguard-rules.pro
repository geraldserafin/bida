# Flutter embedding + plugin channels. Most plugins ship their own consumer
# rules; these are defensive keeps so R8 never strips native-facing classes.
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }

# local_auth uses AndroidX Biometric under the hood.
-keep class androidx.biometric.** { *; }

# sqflite (SQLite) JNI-facing classes.
-keep class com.tekartik.sqflite.** { *; }

# Flutter's engine references Play Core (deferred components / split install),
# which this app doesn't bundle. Tell R8 not to fail on those absent classes.
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Suppress warnings for optional/desugared references.
-dontwarn javax.annotation.**
