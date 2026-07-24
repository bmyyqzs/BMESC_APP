# BMESC Test Notes

## Protocol Packet Tests

`tests/packet` contains QtTest coverage for the low-level packet framing used
between transports and `Commands`.

Covered behavior:

- CRC16 known vector
- short payload framing
- fragmented receive reassembly
- consecutive short, 16-bit-length, and binary frames across transport chunks
- recovery from noise and a bad CRC frame
- recovery on the next transport callback after a bad CRC
- recovery after zero, non-canonical, and oversized length headers

Run with a desktop Qt kit:

```sh
cd tests
qmake tests.pro
make
./packet/tst_packet
```

The local machine currently has Android/iOS Qt 5.15.2 kits only. The test
executable therefore cannot be built and run natively here. Use a macOS or
Linux desktop Qt 5.15 kit with the Qt Test module installed, or run it in CI.

## BLE Connection Test Scope

BLE depends on phone OS permissions, the Nordic UART service exposed by the
device, radio conditions, and target hardware firmware. Treat it as a true
device test rather than a pure unit test.

Minimum Android hardware test:

1. Install the Android build on a phone running Android 12 or newer.
2. Grant Nearby Devices and Location permissions when requested.
3. Confirm scanning lists only preferred devices or devices advertising Nordic
   UART service `6e400001-b5a3-f393-e0a9-e50e24dcca9e`.
4. Connect to the target hardware and confirm `BleUart::connected` fires after
   TX notifications are enabled.
5. Send `COMM_FW_VERSION` through `Commands::getFwVersion`.
6. Confirm the response reaches `Packet::packetReceived`, then
   `Commands::fwVersionReceived`.
7. Disconnect from the device side and confirm `unintentionalDisconnect` is
   emitted and the UI returns to a reconnectable state.

The detailed iOS hardware acceptance matrix is in
[`ios_ble_acceptance.md`](ios_ble_acceptance.md). It covers scan and pairing,
the complete `COMM_FW_VERSION` round trip, disconnect and reconnect behavior,
and verification that live protocol fields reach the matching UI values.

Do not change protocol semantics while working on UI or branding. If a BLE
failure appears after UI changes, first compare the packet tests and the command
round trip above before changing `Commands`, `Packet`, or firmware-facing data
formats.
