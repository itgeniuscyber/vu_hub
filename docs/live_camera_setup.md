# VU Live Camera Broadcasting Setup

VU Hub uses ZEGOCLOUD Live Streaming Kit for real camera broadcasts.

## 1. ZEGOCLOUD App

Created project:

- Project name: `VU_Hub_Live`
- App ID: `371517648`
- Use case: Live Streaming
- Integration path: UIKits / Flutter

The App Sign is stored locally in `.env.zego.json`, which is ignored by Git.

## 2. Run Flutter With Keys

```sh
flutter run --dart-define-from-file=.env.zego.json
```

Or use the helper:

```sh
./scripts/run_with_zego.sh
```

In Trae or VS Code, use the launch configuration named
`VU Hub with ZEGOCLOUD`.

## 3. Build APK With Keys

For a release APK:

```sh
./scripts/build_apk_with_zego.sh
```

Equivalent command:

```sh
flutter build apk --release --dart-define-from-file=.env.zego.json
```

The keys are compiled into that APK at build time. You do not need to run the
command on every phone. You only need the command when building or installing a
new version of the app.

## 4. How It Works

- `Camera` mode creates a `live_posts` document with `provider: zego_uikit`.
- The host opens the room as broadcaster.
- Other signed-in users join the same `providerRoomId` as audience.
- Views and plays are still tracked in Firestore on the live post.

If the keys are missing, VU Hub shows a setup screen instead of crashing.
