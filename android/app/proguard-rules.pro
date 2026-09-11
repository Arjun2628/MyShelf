-dontwarn com.google.mlkit.vision.text.**
-keep class com.google.mlkit.vision.text.** { *; }
-dontwarn com.google_mlkit_text_recognition.**
-keep class com.google_mlkit_text_recognition.** { *; }
-dontwarn com.google.android.gms.**

# Tesseract OCR & Leptonica
-dontwarn io.paratoner.flutter_tesseract_ocr.**
-keep class io.paratoner.flutter_tesseract_ocr.** { *; }
-dontwarn com.googlecode.tesseract.android.**
-keep class com.googlecode.tesseract.android.** { *; }
-dontwarn com.googlecode.leptonica.android.**
-keep class com.googlecode.leptonica.android.** { *; }
