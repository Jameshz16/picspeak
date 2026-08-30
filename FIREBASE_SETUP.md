# PicSpeak — Firebase Setup Guide

> **Note**: The app compiles and runs without Firebase. On first launch without
> credentials, you will see the login screen but sign-in attempts will fail.
> On desktop (Windows/macOS/Linux), Firebase is automatically skipped.
> Follow this guide to enable full Firebase features.

## Prerequisites

1. Install FlutterFire CLI:
```bash
dart pub global activate flutterfire_cli
```

2. Make sure you have a Firebase project created at https://console.firebase.google.com

## Step 1: Configure Firebase

Run from the project root:

```bash
flutterfire configure
```

This will:
- Detect your Firebase project
- Overwrite `lib/firebase_options.dart` with your real credentials
  (The repo ships a stub with placeholder values — this replaces it.)
- Set up `android/app/google-services.json`
- Set up `ios/Runner/GoogleService-Info.plist`

Select your project and both platforms (Android + iOS).

> **Important**: `google-services.json` and `GoogleService-Info.plist` are
> gitignored (they contain API keys). `firebase_options.dart` IS tracked but
> ships with placeholder values. The Android Gradle build applies the
> google-services plugin **only when `android/app/google-services.json`
> exists**, so a fresh clone builds fine without Firebase and Firebase gets
> enabled automatically once you run `flutterfire configure`.
> Just don't push your real keys to a public repo if you regenerate the file.

## Step 2: Install dependencies

```bash
flutter pub get
```

## Step 3: Enable Authentication methods

Go to Firebase Console → Authentication → Sign-in method:

1. Enable **Email/Password**
2. Enable **Google** (add your SHA-1 fingerprint for Android)

### Get SHA-1 for Android:

```bash
cd android
./gradlew signingReport
```

Copy the SHA-1 from the `debug` variant and add it to:
Firebase Console → Project Settings → Android app → Add fingerprint

## Step 4: Firestore Database

Go to Firebase Console → Firestore Database → Create database:

1. Start in **test mode** (we'll add rules later)
2. Select a location close to your users

## Step 5: Run the app

```bash
flutter run
```

## Step 6: Add Firestore Security Rules

After testing, update Firestore rules:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      match /favorites/{wordId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      match /history/{docId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

## Troubleshooting

### "No Firebase App" error
- Make sure `Firebase.initializeApp()` is called before `runApp()`
- Run `flutterfire configure` again

### Google Sign-In not working on Android
- Add SHA-1 fingerprint to Firebase Console
- Make sure `google-services.json` is in `android/app/`

### iOS build fails
- Run `cd ios && pod install`
- Make sure `GoogleService-Info.plist` is in `ios/Runner/`
