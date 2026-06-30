# Troubleshooting Instalasi Aplikasi di Device Fisik

## 🚨 Masalah: "Not Compatible" dan Gagal Instal

### Daftar Masalah yang Sering Terjadi:
1. **"App not installed"** 
2. **"This app is not compatible with your device"**
3. **"Parse error"**
4. **"Installation blocked"**

---

## 🔍 Diagnosis Masalah

### 1. Cek Device Compatibility

#### Cek Android Version Device
```bash
# Di device Android, cek:
Settings > About Phone > Android Version
```

#### Cek Minimum SDK Requirement
```yaml
# Di pubspec.yaml
environment:
  sdk: ^3.7.2

# Di android/app/build.gradle.kts
defaultConfig {
    minSdk = flutter.minSdkVersion  # Default: 21 (Android 5.0)
    targetSdk = flutter.targetSdkVersion  # Default: 33 (Android 13)
}
```

### 2. Cek Device Anda
| Device Requirement | Minimum | Your Device |
|-------------------|---------|-------------|
| Android Version | 5.0 (API 21) | ❓ |
| Architecture | ARM64, ARM, x86 | ❓ |
| Storage Space | 50MB+ free | ❓ |

---

## 🛠️ Solusi Masalah

### A. Update Minimum SDK Version (Jika Device Terlalu Lama)

#### 1. Edit android/app/build.gradle.kts
```kotlin
android {
    defaultConfig {
        // Turunkan minimum SDK jika device lama
        minSdk = 19  // Android 4.4 (default: 21)
        // atau
        minSdk = 16  // Android 4.1 (risiko: beberapa fitur tidak support)
    }
}
```

#### 2. Edit android/local.properties (jika belum ada)
```properties
flutter.minSdkVersion=19
flutter.targetSdkVersion=33
flutter.compileSdkVersion=33
```

### B. Support untuk Architecture Lama

#### 1. Enable ABI Split untuk semua architecture
```kotlin
// android/app/build.gradle.kts
android {
    defaultConfig {
        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86", "x86_64")
        }
    }
}
```

#### 2. Build untuk semua architecture
```bash
# Build universal APK
flutter build apk --release

# Build split APK per architecture
flutter build apk --release --split-per-abi
```

### C. Fix Signing Issue (Untuk Release Build)

#### 1. Debug Build (Untuk Testing)
```bash
# Build debug version (lebih compatible)
flutter build apk --debug
```

#### 2. Release Build dengan Debug Signing
```kotlin
// android/app/build.gradle.kts
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("debug") // Untuk testing
    }
}
```

### D. Clear Cache dan Rebuild

```bash
# Clean semua cache
flutter clean
flutter pub get

# Rebuild
flutter build apk --release
```

---

## 📱 Testing Instalasi

### 1. Install via ADB (Lebih Detail Error)
```bash
# Enable USB Debugging di device
# Connect device via USB
adb devices

# Install APK dengan verbose error
adb install -r build/app/outputs/flutter-apk/app-release.apk

# Cek error message
adb logcat | grep flutter
```

### 2. Install via File Manager
1. Copy APK ke device
2. Enable "Install from Unknown Sources"
3. Install via file manager

### 3. Cek Error di Device
```bash
# Jika install gagal, cek log:
adb logcat | grep -i "install\|package"
```

---

## 🔧 Konfigurasi Device

### Enable Developer Options
1. **Settings > About Phone**
2. **Tap "Build Number" 7x**
3. **Settings > Developer Options**
4. **Enable "USB Debugging"**

### Enable Unknown Sources
1. **Settings > Security**
2. **Enable "Unknown Sources"**

---

## 📊 Compatibility Matrix

| Android Version | API Level | Support Status |
|----------------|-----------|----------------|
| 4.1-4.3 | 16-18 | ⚠️ Limited |
| 4.4 | 19 | ✅ Supported |
| 5.0-5.1 | 21-22 | ✅ Supported |
| 6.0 | 23 | ✅ Supported |
| 7.0-7.1 | 24-25 | ✅ Supported |
| 8.0-8.1 | 26-27 | ✅ Supported |
| 9 | 28 | ✅ Supported |
| 10 | 29 | ✅ Supported |
| 11 | 30 | ✅ Supported |
| 12 | 31 | ✅ Supported |
| 13 | 33 | ✅ Supported |

---

## 🚀 Quick Fix Commands

### Untuk Device Android 4.4+
```bash
# Update minSdkVersion
echo "flutter.minSdkVersion=19" >> android/local.properties

# Rebuild
flutter clean
flutter pub get
flutter build apk --release
```

### Untuk Testing Cepat
```bash
# Build debug version (lebih compatible)
flutter build apk --debug

# Install via ADB
adb install build/app/outputs/flutter-apk/app-debug.apk
```

---

## 📞 Jika Masalah Masih Ada

### Info yang Dibutuhkan untuk Troubleshooting:
1. **Device Model**: (contoh: Samsung Galaxy A10)
2. **Android Version**: (contoh: Android 8.1)
3. **Error Message**: (screenshot atau teks lengkap)
4. **APK Type**: Debug atau Release?
5. **Install Method**: ADB, File Manager, atau Play Store?

### Command untuk Info Device
```bash
# Get device info
adb shell getprop ro.build.version.release
adb shell getprop ro.product.model
adb shell getprop ro.product.cpu.abi
```

---

## ✅ Checklist Sebelum Install

- [ ] Device Android 4.4+ (API 19+)
- [ ] Storage space ≥ 50MB
- [ ] USB Debugging enabled (jika via ADB)
- [ ] Unknown Sources enabled (jika via file manager)
- [ ] APK built for correct architecture
- [ ] APK signed correctly (untuk release)

---

## 🆘 Emergency Solutions

### 1. Build Universal APK
```bash
flutter build apk --release --target-platform android-arm,android-arm64,android-x64
```

### 2. Test di Emulator
```bash
# Jalankan emulator
flutter emulators --launch Pixel_3a_API_30

# Install di emulator
flutter install
```

### 3. Build Debug Version
```bash
flutter build apk --debug
adb install build/app/outputs/flutter-apk/app-debug.apk
```

---

## 📞 Kontak Support
Jika masalah masih berlanjut, berikan:
1. Device model lengkap
2. Android version
3. Error message screenshot
4. Output dari `flutter doctor -v`
