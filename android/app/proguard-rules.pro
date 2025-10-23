# ════════════════════════════════════════════════════════════
#                    HABITFLOW PROGUARD RULES
# ════════════════════════════════════════════════════════════

# Flutter wrapper
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# Google Play Core (fixes missing classes)
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

# Notification support
-keep class com.dexterous.** { *; }

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
#              ✅ NEW RULES FOR TIMER FIX
# ════════════════════════════════════════════════════════════

# ═══ LAMBDA AND CLOSURE FIXES ═══
# Keep all lambda classes
-keep class **$$Lambda$* { *; }
-keepclassmembers class ** {
    private synthetic <methods>;
}

# ═══ LIST OPERATIONS ═══
# Keep List and collection operations
-keepclassmembers class ** {
    ** any(...);
    ** where(...);
    ** indexWhere(...);
    ** forEach(...);
    ** firstWhere(...);
}

# ═══ TIMER-SPECIFIC METHOD PROTECTION ═══
# Don't inline or optimize timer methods
-keepclassmembers class ** {
    ** _startTimer(...);
    ** _pauseTimer(...);
    ** _stopTimer(...);
    ** _startUIUpdateTimer(...);
    ** _autoCompleteTask(...);
}

# Keep all timer callback methods
-keepclassmembers class ** {
    ** onTimer*(...);
    ** onTimer*;
}

# ═══ FLUTTER WIDGET STATE PROTECTION ═══
# Keep tasklist and related fields
-keepclassmembers class ** {
    ** tasklist;
    ** _filteredTaskList;
}

# ═══ ASYNC AND FUTURE PROTECTION ═══
# Don't optimize Future and async operations
-keep class dart.async.** { *; }

# Keep microtask and postFrameCallback
-keepclassmembers class ** {
    ** addPostFrameCallback(...);
}

# ═══ WIDGET KEY PROTECTION ═══
# Keep all Key classes
-keepclassmembers class ** {
    ** key;
}

# ═══ PREVENT DEAD CODE ELIMINATION ═══
# Don't remove callback functions
-keepclasseswithmembers class ** {
    ** onChanged(...);
    ** deleteFun(...);
    ** updateFun(...);
    ** onTimerComplete(...);
}

# ═══ TOAST AND DIALOG PROTECTION ═══
# Keep custom toast classes
-keepclassmembers class ** {
    ** CustomToast*;
    ** showToast(...);
    ** showWarning(...);
    ** showSuccess(...);
    ** showError(...);
}

# ═══ DISABLE AGGRESSIVE OPTIMIZATIONS ═══
# Don't merge classes or inline methods
-optimizations !class/merging/*
-optimizations !code/simplification/arithmetic
-optimizations !code/simplification/cast
-optimizations !field/*
-optimizations !method/inlining/*

# ═══ ATTRIBUTE PRESERVATION ═══
# Keep all attributes for reflection
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes Exceptions

# ════════════════════════════════════════════════════════════
#                       END OF RULES
# ════════════════════════════════════════════════════════════
