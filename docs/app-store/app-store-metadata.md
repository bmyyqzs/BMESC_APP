# BMESC App Store Metadata Draft

## App Record

- Name: BMESC
- Bundle ID: `com.floatingwheel.bmesc`
- SKU: `BMESC-IOS-001`
- Primary language: English
- Availability: Worldwide
- Price: Free
- Version: `1.0.0`
- Build: `1`
- Support URL: `https://bmyyqzs.github.io/BMESC_APP/app-store/support.html`
- Privacy Policy URL: `https://bmyyqzs.github.io/BMESC_APP/app-store/privacy-policy.html`

## Subtitle

Bluetooth companion for BMESC devices

## Description

BMESC is a companion app for compatible BMESC hardware. Use it to find a nearby device over Bluetooth, connect to it, and view the device status shown by the app.

The app focuses on local device management. It can show connection status, device information, live telemetry, and user-facing fault messages when a compatible device is connected.

BMESC does not require an account. It does not bind devices to a cloud service, and it does not include ads, payments, social features, or leaderboards.

## Keywords

BMESC, Bluetooth, device

## Review Notes

BMESC connects to compatible BMESC hardware over Bluetooth Low Energy. The first release supports BLE discovery and connection, local device status, device information, user-facing fault messages, settings, support, privacy policy, user agreement, and open source license information.

No login is required. The app does not include user accounts, cloud device binding, in-app purchases, payment, social features, or leaderboards. The app uses Bluetooth only to discover and connect to nearby compatible devices. Telemetry is displayed locally and is not uploaded to a cloud service in this release.

If review hardware is unavailable, use the supplied screenshots and review video to inspect the connected-state UI. A physical compatible BMESC device is required to exercise real BLE telemetry.

## App Privacy Answers

- Data collected from this app: None, assuming the submitted build matches the first-release behavior and does not upload telemetry or user identifiers.
- Bluetooth: Used for app functionality, specifically discovery and connection to nearby compatible BMESC devices.
- Tracking: No.
- Account creation: Not included in this release.
- User-generated content, social, payments, ads: Not included in this release.

## Screenshot Checklist

- Not connected home state.
- BLE scan/device list.
- Connected home telemetry.
- Device information page.
- Fault log page or empty fault log state.
- Mine/settings page showing legal and support entries.
