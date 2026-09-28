# Docora — ProGuard / R8 Rules
# Applied in release builds via build.gradle.kts

# ── Flutter ────────────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**
-keep class io.flutter.plugins.** { *; }
-keep class com.crazecoder.openfile.** { *; }
-keep class com.tundralabs.flutter_tts.** { *; }

# ── pdfrx & pdfium (Native PDF Rendering Engine) ──────────────────────────────
-keep class io.github.espresso3389.pdfrx.** { *; }
-dontwarn io.github.espresso3389.pdfrx.**
-keep class com.shockwave.** { *; }
-dontwarn com.shockwave.**

# ── File Picker, Wakelock & Plugins ───────────────────────────────────────────
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-keep class dev.fluttercommunity.plus.** { *; }
-keep class creativecreatorormaybenot.wakelock.** { *; }
-keep class dev.flutter.plugins.** { *; }

# ── Kotlin & Coroutines ────────────────────────────────────────────────────────
-keep class kotlin.** { *; }
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# ── Drift / SQLite ─────────────────────────────────────────────────────────────
-keep class androidx.sqlite.** { *; }
-keep class com.google.crypto.tink.** { *; }

# ── Google ML Kit (OCR) ────────────────────────────────────────────────────────
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# ── Biometric / Security ───────────────────────────────────────────────────────
-keep class androidx.biometric.** { *; }

# ── File Provider ──────────────────────────────────────────────────────────────
-keep class androidx.core.content.FileProvider { *; }

# ── Keep enums intact ─────────────────────────────────────────────────────────
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ── Prevent stripping serializable classes ──────────────────────────────────
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ── Keep BuildConfig ─────────────────────────────────────────────────────────
-keep class com.docora.app.BuildConfig { *; }

# ── Suppress common warnings from transitive dependencies ─────────────────────
-dontwarn org.bouncycastle.**
-dontwarn org.conscrypt.**
-dontwarn org.openjsse.**
