# Gamotin Services v0.0.1
Flutter Android app (client) + Dart server with PostgreSQL + admin web page (phone & computer).

## 1. Server
1. Create a PostgreSQL database (Neon / Supabase / Railway / your own VPS).
2. Set environment variables and run:
   DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASS, DB_SSL=true (for cloud DBs)
   ADMIN_PHONE, ADMIN_PASSWORD, ADMIN_NAME  <- creates YOUR admin login
   cd server && dart pub get && dart run bin/server.dart      (or build the Dockerfile)
3. Open https://YOUR-SERVER/ on phone or PC and sign in with ADMIN_PHONE / ADMIN_PASSWORD.
   Put the server behind HTTPS (Render, Railway, Fly.io, Caddy/nginx). Keep /app/uploads on a persistent volume.

## 2. Android app
   flutter create --org com.gamotin --project-name gamotin_services app_tmp
   Copy app_tmp/android and app_tmp/.gitignore etc. into ./app (or copy ./app/lib + pubspec.yaml into app_tmp).
   Edit android/app/src/main/AndroidManifest.xml:
     <uses-permission android:name="android.permission.INTERNET"/>
     <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
     android:label="Gamotin Services"
   In android/app/build.gradle(.kts): minSdk 21+, and enable core library desugaring
   (required by flutter_local_notifications): see its README.
   flutter pub get
   flutter build apk --release --dart-define=API_URL=https://YOUR-SERVER
   -> build/app/outputs/flutter-apk/app-release.apk

## Known limits in 0.0.1
- Needs internet; truly offline phone-to-phone is not possible with a cloud server.
- Customer "finished" notification arrives while the app is running (checks every 15 s).
  Notifications with the app fully closed need Firebase Cloud Messaging (0.0.2).
- Admin web page alerts (sound + browser notification) work while the page is open.
- Passwords are salted SHA-256; switch to argon2/bcrypt before real public launch.
