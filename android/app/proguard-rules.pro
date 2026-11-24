# Flutter rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Suppress Play Core warnings
-dontwarn com.google.android.play.core.**

# Google / Firebase
-dontwarn com.google.android.gms.**
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-keep class com.google.firebase.** { *; }

# Audio & Media
-dontwarn com.ryanheise.audioplayers.**
-keep class com.ryanheise.audioplayers.** { *; }
-dontwarn xyz.luan.audioplayers.**
-keep class xyz.luan.audioplayers.** { *; }
