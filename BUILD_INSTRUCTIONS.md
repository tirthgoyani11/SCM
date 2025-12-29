# 📱 APK Build Instructions

## Prerequisites

Before building the APK files, ensure you have:

1. **Flutter SDK** (3.0 or higher)
   - Download from: https://docs.flutter.dev/get-started/install
   - Add Flutter to your PATH
   - Run `flutter doctor` to verify installation

2. **Android Studio** or **Android SDK**
   - Required for Android build tools
   - Accept Android licenses: `flutter doctor --android-licenses`

3. **Java JDK** (17 or higher)
   - Required for Android builds

## Configuration Steps

### Step 1: Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use existing one
3. Add Android apps:
   - **Parent App**: Package name `com.schoolbus.parent`
   - **Driver App**: Package name `com.schoolbus.driver`
4. Download `google-services.json` for each app
5. Place files in:
   - `flutter_parent_app/android/app/google-services.json`
   - `flutter_driver_app/android/app/google-services.json`

### Step 2: Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Enable **Maps SDK for Android**
3. Create an API key (restrict to your app package names for security)
4. Replace `YOUR_GOOGLE_MAPS_API_KEY` in:
   - `flutter_parent_app/android/app/src/main/AndroidManifest.xml`
   - `flutter_driver_app/android/app/src/main/AndroidManifest.xml`

### Step 3: Backend URL Configuration

Update the backend URL in both apps:

**Parent App** - `flutter_parent_app/lib/core/constants/app_constants.dart`:
```dart
static const String baseUrl = 'https://your-backend-url.com/api';
static const String socketUrl = 'https://your-backend-url.com';
```

**Driver App** - `flutter_driver_app/lib/core/constants/app_constants.dart`:
```dart
static const String baseUrl = 'https://your-backend-url.com/api';
static const String socketUrl = 'https://your-backend-url.com';
```

## Building APKs

### Option 1: Using Build Script (Recommended)

```bash
# Make script executable
chmod +x build_apks.sh

# Run the build script
./build_apks.sh
```

APKs will be generated in `apk_builds/` folder.

### Option 2: Manual Build

**Build Parent App:**
```bash
cd flutter_parent_app
flutter pub get
flutter clean
flutter build apk --release
# APK location: build/app/outputs/flutter-apk/app-release.apk
```

**Build Driver App:**
```bash
cd flutter_driver_app
flutter pub get
flutter clean
flutter build apk --release
# APK location: build/app/outputs/flutter-apk/app-release.apk
```

### Option 3: Debug Build (For Testing)

For faster builds during development:

```bash
cd flutter_parent_app
flutter build apk --debug
```

## Build Variants

### Split APKs by ABI (Smaller file size)
```bash
flutter build apk --split-per-abi
```
This creates separate APKs for different CPU architectures:
- `app-armeabi-v7a-release.apk` (32-bit ARM)
- `app-arm64-v8a-release.apk` (64-bit ARM)
- `app-x86_64-release.apk` (x86_64)

### App Bundle (For Play Store)
```bash
flutter build appbundle
```
Location: `build/app/outputs/bundle/release/app-release.aab`

## Signing for Release

For production releases, you need to sign your APKs:

### 1. Generate a Keystore

```bash
keytool -genkey -v -keystore school-bus-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias school-bus
```

### 2. Create `key.properties`

Create `android/key.properties` in each app:

```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=school-bus
storeFile=/path/to/school-bus-key.jks
```

### 3. Update `build.gradle`

Add signing config in `android/app/build.gradle`:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

## Troubleshooting

### Common Issues

1. **Gradle build fails**
   ```bash
   cd android
   ./gradlew clean
   cd ..
   flutter clean
   flutter pub get
   ```

2. **SDK not found**
   - Set `ANDROID_HOME` environment variable
   - Or create `local.properties` with:
     ```
     sdk.dir=/path/to/Android/Sdk
     flutter.sdk=/path/to/flutter
     ```

3. **Out of memory**
   - Increase Gradle memory in `gradle.properties`:
     ```
     org.gradle.jvmargs=-Xmx4G
     ```

4. **Google Maps not loading**
   - Verify API key is correct
   - Check API key restrictions
   - Ensure Maps SDK for Android is enabled

5. **Firebase issues**
   - Verify `google-services.json` is in correct location
   - Check package name matches Firebase config

## APK Installation

### Install via ADB
```bash
adb install apk_builds/SchoolBusParent.apk
adb install apk_builds/SchoolBusDriver.apk
```

### Enable Unknown Sources
On the Android device:
1. Go to Settings > Security
2. Enable "Unknown sources" or "Install unknown apps"
3. Transfer APK and open to install

## Testing Checklist

After installation, verify:

- [ ] App opens without crashes
- [ ] Login/Registration works
- [ ] Google Maps displays correctly
- [ ] GPS location is detected
- [ ] Push notifications received
- [ ] Socket connection establishes
- [ ] Live video streaming works

## Support

For issues or questions:
- Check Flutter docs: https://docs.flutter.dev/
- Firebase docs: https://firebase.google.com/docs
- Google Maps Platform: https://developers.google.com/maps
