# firmensms-flutter
A mobile client (Android/iOS app) for the firmensms.at REST API

## API used
This app uses the official REST API - documented at [https://www.firmensms.at/schnittstelle.pdf](https://www.firmensms.at/schnittstelle.pdf#%5B%7B%22num%22%3A86%2C%22gen%22%3A0%7D%2C%7B%22name%22%3A%22XYZ%22%7D%2C70.85%2C771.15%2C0%5D)

## Download
You can download the app on [Google Play](https://play.google.com/store/apps/details?id=at.mwllgr.firmensms) or an APK at the [release page](https://github.com/mwllgr/firmensms-flutter/releases).

## Building
The Flutter version is pinned in `.fvmrc` and managed with [fvm](https://fvm.app).

```bash
fvm install
fvm flutter pub get
fvm flutter test
fvm flutter build appbundle --release
```

Release builds are signed with the keystore referenced in `android/key.properties`
(see the [Flutter deployment docs](https://docs.flutter.dev/deployment/android#reference-the-keystore-from-the-app)).
Without that file the release build falls back to the debug key.

Android targets API 36 (Android 16) and requires API 24 (Android 7.0) or newer.
iOS requires iOS 13 or newer.

Launcher icons are generated from `assets/icon` with `fvm dart run flutter_launcher_icons`.

## Screenshot
![Screenshot](https://user-images.githubusercontent.com/25794895/148666677-a6e49cc1-a59a-4f5c-a95c-937fe1a28d6e.png)
