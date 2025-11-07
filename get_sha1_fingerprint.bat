@echo off
echo Getting SHA-1 fingerprint for Firebase configuration...
echo.

cd android
echo Running gradlew signingReport...
gradlew signingReport

echo.
echo Look for the SHA-1 fingerprint in the output above.
echo Copy the SHA-1 value and add it to your Firebase Console.
echo.
echo Steps:
echo 1. Go to Firebase Console: https://console.firebase.google.com/
echo 2. Select your project: recostrect3
echo 3. Go to Project Settings (gear icon)
echo 4. Find your Android app: com.reconstrect.visionboard
echo 5. Click "Add fingerprint" under SHA certificate fingerprints
echo 6. Paste the SHA-1 value from above
echo 7. Click Save
echo 8. Download the updated google-services.json
echo 9. Replace android/app/google-services.json
echo.
pause 