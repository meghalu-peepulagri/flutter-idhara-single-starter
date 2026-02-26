# Please add these rules to your existing keep rules in order to suppress warnings.
# This is generated automatically by the Android Gradle plugin.
-dontwarn com.google.errorprone.annotations.CanIgnoreReturnValue
-dontwarn com.google.errorprone.annotations.CheckReturnValue
-dontwarn com.google.errorprone.annotations.Immutable
-dontwarn com.google.errorprone.annotations.RestrictedApi
-dontwarn javax.annotation.Nullable
-dontwarn javax.annotation.concurrent.GuardedBy
-dontwarn org.bouncycastle.jce.provider.BouncyCastleProvider
-dontwarn org.bouncycastle.pqc.jcajce.provider.BouncyCastlePQCProvider
-keep class org.xmlpull.v1.** { *; }

# Keep annotation attributes - required for Firebase and Flutter plugins
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes Signature
-keepattributes Exceptions

# Firebase Messaging - Required for background notifications in release builds
-keep class com.google.firebase.** { *; }
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Flutter plugin wrapper classes - CRITICAL for background message handler in release
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.**

# Generated plugin registrant - needed for background isolate plugin registration
-keep class **.GeneratedPluginRegistrant { *; }
-keepclassmembers class **.GeneratedPluginRegistrant { *; }

# Flutter Firebase Messaging background executor
-keep class io.flutter.plugins.firebase.messaging.** { *; }
-keep class com.google.firebase.messaging.FirebaseMessagingService { *; }

# Flutter Local Notifications Plugin
-keep class com.dexterous.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.**

# Keep Kotlin metadata and serialization
-keep class kotlin.Metadata { *; }
-keepclassmembers class kotlin.Metadata { *; }

# Keep all classes that implement Parcelable
-keep class * implements android.os.Parcelable { *; }

# Keep notification-related classes
-keep class android.app.Notification { *; }
-keep class android.app.NotificationChannel { *; }
-keep class android.app.NotificationManager { *; }
-keep class androidx.core.app.NotificationCompat { *; }
-keep class androidx.core.app.NotificationCompat$* { *; }

# Keep BroadcastReceiver and Service subclasses (needed for FCM)
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver

# Keep Gson and JSON serialization classes (used internally by Firebase)
-keep class com.google.gson.** { *; }
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# Keep Firebase Installations (required for FCM token generation in release)
-keep class com.google.firebase.installations.** { *; }
-keep class com.google.firebase.iid.** { *; }

# Keep background message handler callback lookup
-keep class io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingBackgroundService { *; }
-keep class io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingBackgroundExecutor { *; }

# Keep Application subclasses (needed for background isolate initialization)
-keep public class * extends android.app.Application





