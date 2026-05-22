# Firebase setup for Food Track

Follow these steps once. After that, sign-in and saving your calorie goal on **Profile** will use Firebase.

## 1. Create a Firebase project (do this first)

You must have a **project** before you see Authentication, Firestore, or **Build**.

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Sign in with Google
3. Click **Add project** (or **Create a project**)
4. Name it (e.g. `food-track`) → Continue → finish the wizard
5. You should land on **Project overview** for that project

If you already have projects, pick **food-track** (or your name) from the project dropdown at the top.

## 2. Enable Authentication

The left sidebar labels vary. Use whichever you see:

- **Build → Authentication**, or
- **Authentication** directly under the project name

Then:

1. Click **Get started** (if shown)
2. Open **Sign-in method**
3. **Email/Password** → Enable → **Save**

## 3. Create Firestore

In the left sidebar:

- **Build → Firestore Database**, or
- **Firestore Database**

Then:

1. **Create database**
2. Start in **test mode** while learning (lock down rules before production)
3. Pick a region close to you

## 4. Add Android app

On **Project overview** (home of your project):

1. Click the **gear icon** next to “Project overview” → **Project settings**
2. Scroll to **Your apps**
3. Click **Add app** → choose **Android** (robot icon)
2. Android package name: `com.example.food_track` (must match `android/app/build.gradle.kts`)
3. Download **`google-services.json`**
4. Put the file here:

   ```
   android/app/google-services.json
   ```

## 5. FlutterFire CLI (generates Dart config)

In a terminal at the project root (where `pubspec.yaml` is):

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

- Sign in with Google when asked
- Select your Firebase project
- Select **Android** (add iOS later on a Mac if needed)

This overwrites `lib/firebase_options.dart` and sets `isConfigured` to real API keys.

If `flutterfire` is not found, add Pub cache to PATH or run:

```bash
dart pub global run flutterfire_cli:flutterfire configure
```

## 6. Firestore security rules

In the console: **Firestore → Rules**, paste the contents of `firestore.rules` from this repo, then **Publish**.

That allows each signed-in user to read/write only their own document under `users/{uid}`.

## 7. Install packages and run

```bash
flutter pub get
flutter run
```

You should see the **login** screen. Create an account, then open **Profile** to set your calorie goal (saved to Firestore).

## Troubleshooting

| Problem | Fix |
|--------|-----|
| App shows "Firebase setup required" | Run `flutterfire configure` so `firebase_options.dart` is generated |
| Android build fails on Google Services | Ensure `android/app/google-services.json` exists |
| `email-already-in-use` | Use another email or sign in instead of sign up |
| Permission denied on Firestore | Publish `firestore.rules` and confirm you are signed in |

## Data shape

Each user gets a document:

```
users/{uid}
  email: string
  calorieGoal: number (default 2200)
  createdAt: timestamp
  updatedAt: timestamp
```

Diary and exercise logs will use subcollections under this path in a later step.
