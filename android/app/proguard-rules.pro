# ════════════════════════════════════════════════════════════
#                    HABITFLOW PROGUARD RULES
# ════════════════════════════════════════════════════════════

# Flutter wrapper
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# Google Play Core
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.** { *; }
-dontwarn com.google.android.play.**

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}

# AndroidX
-keep class androidx.** { *; }
-keep interface androidx.** { *; }
-dontwarn androidx.**

# Keep Timer and related classes
-keep class java.util.Timer { *; }
-keep class java.util.TimerTask { *; }
-keep class dart.** { *; }

# Keep all setState methods
-keepclassmembers class * {
    void setState(...);
    boolean mounted;
}

# Prevent stripping of native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep crashlytics
-keep class com.google.firebase.crashlytics.** { *; }
-dontwarn com.google.firebase.crashlytics.**

# Firestore
-keep class com.google.android.gms.tasks.** { *; }
-keep class com.google.firebase.firestore.** { *; }

# General optimizations
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose

# Keep line numbers for debugging
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# ════════════════════════════════════════════════════════════
#              ✅ NOTIFICATION PLUGIN RULES (CRITICAL)
# ════════════════════════════════════════════════════════════

# Keep ALL notification plugin classes
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Keep notification channel classes
-keep class android.app.NotificationChannel { *; }
-keep class android.app.NotificationManager { *; }
-keep class androidx.core.app.NotificationCompat** { *; }
-keep class androidx.core.app.NotificationManagerCompat { *; }

# Keep notification builder
-keep class android.app.Notification$** { *; }
-keep class android.app.NotificationChannel$** { *; }

# Keep receivers for notifications
-keep class * extends android.content.BroadcastReceiver {
    <init>(...);
}

# Keep services for foreground notifications
-keep class * extends android.app.Service {
    <init>(...);
}

# ✅ CRITICAL: Keep drawable resources
-keep class **.R$drawable { *; }
-keep class **.R$* {
    public static <fields>;
}

# ✅ CRITICAL: Don't obfuscate resource IDs
-keepclassmembers class **.R$* {
    public static <fields>;
}

# ✅ Keep integer resource access (for icon loading)
-keepclassmembers class * {
    *** getDrawable(...);
    *** getIdentifier(...);
}

# ✅ Keep notification style information
-keep class android.app.Notification$BigTextStyle { *; }
-keep class android.app.Notification$InboxStyle { *; }
-keep class android.app.Notification$BigPictureStyle { *; }

# ════════════════════════════════════════════════════════════
#              ✅ TIMER FIX RULES
# ════════════════════════════════════════════════════════════

# Keep lambda classes
-keep class **$$Lambda$* { *; }
-keepclassmembers class ** {
    private synthetic <methods>;
}

# Keep List operations
-keepclassmembers class ** {
    ** any(...);
    ** where(...);
    ** indexWhere(...);
    ** forEach(...);
    ** firstWhere(...);
}

# Keep timer methods
-keepclassmembers class ** {
    ** _startTimer(...);
    ** _pauseTimer(...);
    ** _stopTimer(...);
    ** _startUIUpdateTimer(...);
    ** _autoCompleteTask(...);
    ** _updateTimerNotification(...);
}

# Keep all timer callback methods
-keepclassmembers class ** {
    ** onTimer*(...);
    ** onTimer*;
}

# Keep tasklist and related fields
-keepclassmembers class ** {
    ** tasklist;
    ** _filteredTaskList;
}

# Keep async operations
-keep class dart.async.** { *; }

# Keep microtask and postFrameCallback
-keepclassmembers class ** {
    ** addPostFrameCallback(...);
}

# Keep widget keys
-keepclassmembers class ** {
    ** key;
}

# Keep callback functions
-keepclasseswithmembers class ** {
    ** onChanged(...);
    ** deleteFun(...);
    ** updateFun(...);
    ** onTimerComplete(...);
}

# Keep custom toast classes
-keepclassmembers class ** {
    ** CustomToast*;
    ** showToast(...);
    ** showWarning(...);
    ** showSuccess(...);
    ** showError(...);
}

# ✅ CRITICAL: Keep SharedPreferences for notification preferences
-keep class android.content.SharedPreferences { *; }
-keep class android.content.SharedPreferences$** { *; }
-keepclassmembers class ** {
    ** getSharedPreferences(...);
}

# Disable aggressive optimizations
-optimizations !class/merging/*
-optimizations !code/simplification/arithmetic
-optimizations !code/simplification/cast
-optimizations !field/*
-optimizations !method/inlining/*

# Keep attributes for reflection
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes Exceptions

# ════════════════════════════════════════════════════════════
#                       END OF RULES
# ════════════════════════════════════════════════════════════
