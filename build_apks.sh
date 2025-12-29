#!/bin/bash

# School Bus Tracking System - APK Build Script
# This script builds both Parent and Driver apps

set -e

echo "========================================"
echo "School Bus Tracking System - APK Builder"
echo "========================================"

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "Error: Flutter is not installed!"
    echo "Please install Flutter from: https://docs.flutter.dev/get-started/install"
    exit 1
fi

# Display Flutter version
echo ""
echo "Flutter Version:"
flutter --version
echo ""

# Build Parent App
echo "========================================"
echo "Building Parent App APK..."
echo "========================================"
cd flutter_parent_app

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Clean previous builds
echo "Cleaning previous builds..."
flutter clean

# Build APK
echo "Building release APK..."
flutter build apk --release

# Copy APK to root directory
mkdir -p ../apk_builds
cp build/app/outputs/flutter-apk/app-release.apk ../apk_builds/SchoolBusParent.apk
echo "✅ Parent App APK built successfully!"
echo "Location: apk_builds/SchoolBusParent.apk"

cd ..

# Build Driver App
echo ""
echo "========================================"
echo "Building Driver App APK..."
echo "========================================"
cd flutter_driver_app

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Clean previous builds
echo "Cleaning previous builds..."
flutter clean

# Build APK
echo "Building release APK..."
flutter build apk --release

# Copy APK to root directory
cp build/app/outputs/flutter-apk/app-release.apk ../apk_builds/SchoolBusDriver.apk
echo "✅ Driver App APK built successfully!"
echo "Location: apk_builds/SchoolBusDriver.apk"

cd ..

echo ""
echo "========================================"
echo "Build Complete!"
echo "========================================"
echo ""
echo "APK Files Location:"
echo "  📱 Parent App: apk_builds/SchoolBusParent.apk"
echo "  🚌 Driver App: apk_builds/SchoolBusDriver.apk"
echo ""
echo "Note: Before installing, make sure to:"
echo "  1. Replace 'YOUR_GOOGLE_MAPS_API_KEY' in AndroidManifest.xml"
echo "  2. Add your google-services.json from Firebase Console"
echo "  3. Update the backend URL in lib/core/constants/app_constants.dart"
echo ""
