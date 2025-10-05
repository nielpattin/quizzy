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


## Connecting to server on local pc from client app on emulator or real device

When running the Flutter app on an Android emulator or a real device, `localhost` does not refer to your development machine. You need to use different addresses depending on your setup.
### Android Emulator
When running the Flutter app on an Android emulator, `localhost` refers to the emulator itself, not your host machine. To connect to a server running on your host machine, use the special IP address `http://10.0.2.2:3000` in the `.env` file:

### Real Device

#### USB Connection
When running the Flutter app on a real device(need to connected with USB), `localhost` also refers to the device itself. To connect to a server running on your host machine:
- Use `adb reverse tcp:3000 tcp:3000` to forward requests from the device to your host machine.
- Set in the `.env` file the SERVER_URL to your host machine's local network IP address, e.g., `http://localhost:3000`

#### With Tailscale
Make sure both your development machine and your mobile device are connected to the same Tailscale network.

You can either use the ip address or the hostname provided by Tailscale.
- IP Address: `http://100.x.x.x:3000`
- Hostname: `http://some-random-name.ts.net:3000`

This can work on different networks as long as both devices are connected to Tailscale network.

No need to connect with USB.

#### With zrok (#TODO)