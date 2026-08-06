# BMESC Google Play Release Materials

Use these values for the first Google Play production release.

## App Setup

- App name: `BMESC`
- Default language: English
- App or game: App
- Free or paid: Free
- Category: Tools
- Countries/regions: Worldwide
- Package name: `com.bmesc.app`

## Main Store Listing

- Short description: `Bluetooth companion for BMESC devices`
- Full description:

```text
BMESC is a companion app for compatible BMESC hardware. Use it to find a nearby device over Bluetooth, connect to it, and view the device status shown by the app.

The app focuses on local device management. It can show connection status, device information, live telemetry, and user-facing fault messages when a compatible device is connected.

BMESC does not require an account. It does not bind devices to a cloud service, and it does not include ads, payments, social features, or leaderboards.
```

- Support email: `op727142092@gmail.com`
- Support URL: `https://bmyyqzs.github.io/BMESC_APP/app-store/support.html`
- Privacy policy: `https://bmyyqzs.github.io/BMESC_APP/app-store/privacy-policy.html`

## Release Notes

```text
Initial release for Bluetooth discovery, connection, telemetry, device information, settings, support, privacy, and open-source license access.
```

## App Review Notes

```text
BMESC connects to compatible BMESC hardware over Bluetooth Low Energy. The first release supports BLE discovery and connection, local device status, device information, user-facing fault messages, settings, support, privacy policy, user agreement, and open-source license information.

No login is required. The app does not include user accounts, cloud device binding, in-app purchases, payment, ads, social features, user-generated content, or leaderboards. The app uses Bluetooth only to discover and connect to nearby compatible devices. Telemetry is displayed locally and is not uploaded to a cloud service in this release.

A physical compatible BMESC device is required to exercise real BLE telemetry. If review hardware is unavailable, screenshots and review video can be used to inspect the connected-state UI.
```

## Data Safety Answers

- Data collected: No user data collected.
- Data shared: No user data shared.
- Data processed ephemerally: Bluetooth telemetry is displayed locally while connected and is not uploaded by the first release.
- Account creation: Not available.
- Data deletion request: Not applicable because no account data is collected.
- Tracking: No.
- Ads: No.

## App Content Answers

- App access: All app content is available without login or special credentials. Compatible BMESC hardware is required for live BLE telemetry.
- Content rating: Utility/device management app; no violence, adult content, gambling, drugs, hate content, user-generated content, or unrestricted internet communication.
- Target audience: 13+ by default. Use 18+ if the final product positioning treats the hardware as adult-only mobility equipment.
- News app: No.
- Government app: No.
- Financial features: No.
- Health features: No.
- COVID-19 contact tracing/status: No.
- Data safety / privacy policy alignment: The first release does not collect or upload telemetry or identifiers.

## Permissions Declaration

The release manifest intentionally avoids background location:

- `ACCESS_BACKGROUND_LOCATION`: not declared.
- `FOREGROUND_SERVICE_LOCATION`: not declared.
- `ACCESS_COARSE_LOCATION` and `ACCESS_FINE_LOCATION`: declared only with `maxSdkVersion=30` for Android 11 and earlier BLE scanning compatibility.
- `BLUETOOTH_SCAN`: declared with `neverForLocation` because the app uses BLE scanning only to find compatible BMESC devices, not to infer physical location.
- Foreground service type: `connectedDevice`, used only to support device connection behavior.

If Play Console asks for location details, use:

```text
BMESC does not collect or infer user location. Location permission is declared only for Android 11 and earlier, where Bluetooth Low Energy scanning required location permission at the Android platform level. Android 12 and later use Bluetooth scan/connect permissions, with neverForLocation set on Bluetooth scan.
```

## Release Artifact

- Upload bundle: `build/android-play-release/artifacts/BMESC_mobile_release.aab`
- Upload key alias: `bmesc_upload`
- Keystore location: `keystores/bmesc-upload-key.jks`
- Keystore/password values are stored only in `PROJECT_MEMORY_PRIVATE.md`.
