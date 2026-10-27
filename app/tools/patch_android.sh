#!/usr/bin/env bash
# Run from the app/ folder AFTER "flutter create --platforms=android ." (the CI workflow does this for you).
set -e
M=android/app/src/main/AndroidManifest.xml
grep -q 'POST_NOTIFICATIONS' $M || sed -i 's#<application#<uses-permission android:name="android.permission.INTERNET"/>\n    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>\n    <application#' $M
sed -i 's#android:label="[^"]*"#android:label="Gamotin Services"#' $M
# Allow plain http only if you pass ALLOW_HTTP=1 (for testing on your own network)
if [ "$ALLOW_HTTP" = "1" ]; then sed -i 's#<application#<application android:usesCleartextTraffic="true"#' $M; fi
G=$(ls android/app/build.gradle.kts android/app/build.gradle 2>/dev/null | head -1)
if [[ "$G" == *.kts ]]; then
  sed -i 's#compileOptions {#compileOptions {\n        isCoreLibraryDesugaringEnabled = true#' $G
  sed -i 's#minSdk = flutter.minSdkVersion#minSdk = 21#' $G
  printf '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n' >> $G
else
  sed -i 's#compileOptions {#compileOptions {\n        coreLibraryDesugaringEnabled true#' $G
  sed -i 's#minSdkVersion flutter.minSdkVersion#minSdkVersion 21#' $G
  printf "\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n}\n" >> $G
fi
echo "Android project patched."
