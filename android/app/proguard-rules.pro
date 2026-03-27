-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**

-keep class com.example.my_app.** { *; }
-keepattributes *Annotation*
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory