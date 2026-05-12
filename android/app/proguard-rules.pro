# OkHttp platform warnings
-dontwarn okhttp3.internal.platform.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

# Flutter — keep JNI entry points
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Isar (community) — reflection-based native bridge
-keep class com.isar.** { *; }
-keep class dev.isar.** { *; }
-keep @interface dev.isar.**
-keepclassmembers class * {
    @dev.isar.* <fields>;
}
-dontwarn com.isar.**
-dontwarn dev.isar.**

# Supabase / Ktor / Kotlinx-serialization
-keep class io.github.jan.supabase.** { *; }
-dontwarn io.github.jan.supabase.**
-keep class io.ktor.** { *; }
-dontwarn io.ktor.**
-keepattributes *Annotation*, InnerClasses
-keep @kotlinx.serialization.Serializable class * { *; }
-keepclassmembers class * {
    @kotlinx.serialization.SerialName <fields>;
}
-dontwarn kotlinx.serialization.**

# Google Sign-In
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.api.client.** { *; }
-dontwarn com.google.android.gms.**

# Sign in with Apple (via browser/intent — no native keep needed, but suppress warnings)
-dontwarn com.aboutyou.dart_packages.**

# Gson / JSON (used by various SDKs)
-keepattributes Signature
-keepattributes EnclosingMethod
-keep class sun.misc.Unsafe { *; }

# Kotlin coroutines & reflection
-keep class kotlin.coroutines.** { *; }
-dontwarn kotlin.**
-dontwarn kotlinx.**
