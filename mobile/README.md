# Chennai Assist mobile app (Flutter)

The visitor app for Chennai Assist: city guide, ask a question, photos, local
interviews and live chat with the admin. It talks to the website's API
(`/api/v1`) and its real-time chat channel (`/socket`).

## Screens

- **Home**: welcome, guide categories, latest photos, local voices.
- **Guide**: articles by category (same content as the website).
- **Ask**: send a question (answered by email) and read public answers.
- **Photos**: gallery with full-screen, pinch-to-zoom viewer.
- **Chat**: live chat. The chat is remembered on the phone; admin replies
  (from the website or Telegram) appear instantly.

## Get the Android app without installing anything

Every push that changes `mobile/` builds an APK on GitHub:

1. Open the repo on GitHub → **Actions** → **Mobile app (Android APK)**.
2. Open the latest green run → **Artifacts** → download `chennai-assist-android`.
3. Unzip it, copy `app-release.apk` to an Android phone and open it
   (allow "install unknown apps" when asked).

You can also start a build by hand: Actions → Mobile app (Android APK) → **Run workflow**.

## Run it yourself

Install Flutter (3.50+) and Android Studio, then:

```bash
cd mobile
flutter pub get
flutter run                      # uses https://city-help.onrender.com
```

Against a local server (`mix phx.server` on port 4000):

```bash
flutter run --dart-define=API_BASE=http://10.0.2.2:4000   # Android emulator
flutter run --dart-define=API_BASE=http://localhost:4000  # iOS simulator
```

Build an APK: `flutter build apk --release`.
Checks: `flutter analyze` and `flutter test`.

## Before publishing to the Play Store / App Store

- **Signing:** release builds currently use the debug key, which is fine for
  installing directly but not accepted by the Play Store. Create an upload key
  and configure `android/app/build.gradle.kts` (see
  https://docs.flutter.dev/deployment/android#sign-the-app).
- **App ID:** `in.cityhelp.chennai_assist` (change before the first upload if
  you want a different one; it cannot change afterwards).
- **Icon:** replace the default Flutter icon (e.g. with `flutter_launcher_icons`).
- **iOS:** needs a Mac with Xcode and an Apple Developer account.
- **Server:** the free Render plan sleeps; the app shows "Waking up Chennai
  Assist…" while it starts.
