# Troubleshooting

## Common Issues with Google Sign-In in Flutter
```bash
Response error returned from framework
I/flutter ( 7170): Login failed:
GoogleSignInException(code GoogleSignInExceptionCode.canceled, [16] Account reauth failed., null)
```

> The error GoogleSignInExceptionCode.canceled with "Account reauth failed" suggests the Google Sign-In
process was canceled or failed during account selection/authentication.

Solution:
- Check SHA-1 fingerprint:

- cd app/android && ./gradlew signingReport

Look for the debug SHA-1 in debug/debug and  add it to your Firebase project (Project Settings > Your apps > Android app > SHA certificate fingerprints).
