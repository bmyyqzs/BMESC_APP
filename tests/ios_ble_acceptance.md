# iOS BLE and Data Flow Acceptance

## Purpose

Use this checklist on a signed iPhone build and production-representative
hardware. It verifies the path from the pairing UI through BLE transport,
packet framing, command decoding, and live UI updates. Record the app commit,
iOS version, phone model, hardware revision, and firmware version for each run.

## Preconditions

- Bluetooth is enabled and the app has Bluetooth permission.
- The target device advertises Nordic UART Service
  `6e400001-b5a3-f393-e0a9-e50e24dcca9e`.
- The target is not connected to another phone.
- The device has enough power to remain connected for at least 10 minutes.
- App logs can be captured from Xcode or the macOS Console app.

## Acceptance Matrix

| ID | Scenario | Steps | Expected transport/protocol result | Expected UI result |
| --- | --- | --- | --- | --- |
| IOS-BLE-01 | First permission and scan | Fresh-install the app, open pairing, allow Bluetooth, start scan | Scan completes without `bleError`; target is identified by iOS UUID and Nordic UART service | Pairing button gives immediate pressed/loading feedback; target appears once and remains selectable |
| IOS-BLE-02 | Pair button action | Tap the target's pairing button once | `BleUart::startConnect` is called once; service discovery finds RX/TX characteristics; TX notifications are enabled; `BleUart::connected` fires | Button cannot create duplicate attempts; state changes from scanning/connecting to connected; selected device identity is shown |
| IOS-BLE-03 | Firmware round trip | Connect, then trigger `Commands::getFwVersion()` | TX payload starts with `COMM_FW_VERSION`; framed bytes are written to BLE RX; notification bytes reach `Packet::processData`; one valid packet reaches `Commands::processPacket`; `fwVersionReceived` fires within 3 seconds | Connected state is not shown before the round trip succeeds; firmware and hardware identity shown by the UI match the target |
| IOS-BLE-04 | Bad or missing firmware response | Block notifications or use incompatible hardware, then connect | No false `fwVersionReceived`; timeout/error is observable; app remains responsive | UI reports connection verification failure and offers retry; it does not display stale device data |
| IOS-BLE-05 | Device-side disconnect | While live data is updating, power off the target | `deviceDisconnected` and `unintentionalDisconnect` fire; polling and writes stop | Connected indicator clears within 3 seconds; values stop updating and are marked unavailable; reconnect action becomes available |
| IOS-BLE-06 | Reconnect | Power target on and use reconnect without restarting app | A new BLE controller/service session is created; notification subscription succeeds; `COMM_FW_VERSION` succeeds again | UI returns to connected state without duplicate devices, frozen loading state, or stale values |
| IOS-BLE-07 | App foreground recovery | Connect, background app for 30 seconds, return to foreground | Existing valid connection resumes, or disconnect is detected and reconnect is offered; no write loop floods BLE | UI state matches actual transport state and live values resume only after valid packets arrive |
| IOS-BLE-08 | Ten-minute stability | Stay connected with live telemetry visible for 10 minutes | No repeated connect events, parser stalls, uncontrolled request growth, or malformed-packet crash | Values continue updating smoothly; navigation and pairing controls remain responsive |

## Live Data Mapping

Verify at least five changing fields against a trusted reference such as the
device firmware console or a second validated client. UI labels may be
product-oriented, but their source and units must remain traceable.

| Protocol field from `MC_VALUES` | Required UI meaning | Conversion/check |
| --- | --- | --- |
| `v_in` | Battery/input voltage | Display volts; no percent conversion unless a documented battery profile is applied |
| `current_motor` | Motor current | Display amperes with sign preserved |
| `current_in` | Battery/input current or power input | If UI shows power, verify `current_in * v_in` and display watts |
| `duty_now` | Controller duty | Multiply by 100 only for percent display |
| `rpm` | Motor speed source | Any vehicle speed conversion must use documented motor poles, gearing, and wheel circumference |
| `temp_mos` | Controller temperature | Display degrees C and verify warning thresholds are product-defined |
| `temp_motor` | Motor temperature | Must not be swapped with controller temperature |
| `tachometer_abs` | Distance source | Verify the configured conversion before displaying trip or odometer distance |
| `watt_hours` / `watt_hours_charged` | Energy use/recovery | Net consumption is `watt_hours - watt_hours_charged` |
| `fault_code` / `fault_str` | Fault state | A non-zero firmware fault must produce a visible, non-stale warning |

For every checked field, confirm this chain:

1. BLE notification reaches `BleUart::dataRx`.
2. `Packet::packetReceived` emits one complete payload.
3. `Commands::valuesReceived` contains the expected value and mask bit.
4. The visible UI value updates from that signal, not from placeholder data.
5. After disconnect, the UI does not continue presenting the last value as live.

## Failure Evidence

For a failed row, attach:

- screen recording from before the action through the failure;
- timestamped app logs containing scan, connect, service, notification, packet,
  command, and disconnect events where available;
- target firmware version and hardware revision;
- whether retry, app restart, Bluetooth toggle, or device reboot changes the result;
- the first layer where the expected event is missing: UI, `BleUart`, `Packet`,
  `Commands`, or UI data binding.

Do not change packet framing or command semantics to compensate for a UI state
or binding failure. First isolate the missing layer using the event chain above.
