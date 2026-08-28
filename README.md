# Family Task App

Flutter family task app using Firebase Authentication, Firestore, and FCM.

## Push Notifications

The app requests notification permission and stores each signed-in device token in
`users/{uid}.fcmTokens`. The Cloud Function `notifyTodoAssignment` sends an FCM
notification when a todo is created for someone other than its creator.

From the project root, install and deploy the notification function:

```powershell
Set-Location functions
npm install
Set-Location ..
firebase deploy --only functions
```

Enable the Cloud Functions API and Cloud Messaging API for the Firebase project
before deploying. For web receivers, create a Web Push certificate key in
Firebase Console > Project settings > Cloud Messaging, then run the app with:

```powershell
flutter run -d chrome --dart-define=FCM_WEB_VAPID_KEY=YOUR_PUBLIC_VAPID_KEY
```

The browser must grant notification permission. Android receivers need a device
with Google Play services and notification permission enabled.

For Android, add the Firebase Cloud Messaging API configuration in the Firebase
project and test on a physical device or an emulator with Google Play services.
For iOS, upload an APNs authentication key or certificate in Firebase Console
and enable Push Notifications and Background Modes in the Runner target.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
