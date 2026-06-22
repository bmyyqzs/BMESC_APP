# BMESC App Store Metadata Draft

## App Record

- Name: BMESC
- Bundle ID: `com.bmesc.app`
- SKU: `BMESC-IOS-001`
- Primary language: English
- Availability: Worldwide
- Price: Free
- Version: `1.0.0`
- Build: `1`
- Support URL: `https://gcore.jsdelivr.net/gh/bmyyqzs/BMESC_APP@main/docs/app-store/support.html`
- Privacy Policy URL: `https://gcore.jsdelivr.net/gh/bmyyqzs/BMESC_APP@main/docs/app-store/privacy-policy.html`

## Subtitle

Bluetooth device dashboard

## Description

BMESC is a companion app for compatible BMESC hardware. It helps users find nearby devices over Bluetooth, connect to their device, view live telemetry, review device information, and understand user-facing fault and safety messages.

The first release focuses on local device management. It does not require an account, does not bind devices to a cloud service, and does not include payments, social features, or leaderboards.

## Keywords

BMESC, Bluetooth, telemetry, device, mobility, controller

## Review Notes

BMESC connects to compatible BMESC hardware over Bluetooth Low Energy. Core flows are BLE discovery and connection, live telemetry, device information, local fault logs, units/language settings, support, privacy policy, user agreement, and open source license information.

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
