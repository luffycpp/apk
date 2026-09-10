# ── RapidFire Panel - ProGuard Rules ─────────────────────────────

# Keep Capacitor core
-keep class com.getcapacitor.** { *; }
-keep class in.rapidfirecorporation.streamer.** { *; }
-keepattributes *Annotation*

# Keep WebView JavaScript interface
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep biometric classes
-keep class androidx.biometric.** { *; }

# Keep network classes
-keep class okhttp3.** { *; }

# ── Anti-reverse engineering ──────────────────────────────────────
# Obfuscate everything not kept above
-renamesourcefileattribute SourceFile
-keepattributes SourceFile,LineNumberTable

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
    public static *** e(...);
}

# Prevent decompilation hints
-dontskipnonpubliclibraryclasses
-optimizationpasses 5
-allowaccessmodification
