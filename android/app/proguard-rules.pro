# Keep generic signatures and annotations required for Gson TypeToken (used by flutter_local_notifications)
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Gson rules
-keep class com.google.gson.** { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Flutter Local Notifications plugin rules
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.** { *; }

# Flutter Engine rules
-keep class io.flutter.** { *; }

# Suppress warnings for missing Play Core classes used in Flutter PlayStoreSplit / DeferredComponents
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

