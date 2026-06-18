# BM UI 与代码映射

## 当前页面

|

## 配对按钮调用链

```text
BMHomePage.Pair device
  -> requestConnect()
  -> main.qml openConnectionPage()
  -> navigateToPage(1)
  -> ConnectScreen opened=true
  -> autoStartScanTimer
  -> BleUart.startScan()
```

设备列表连接按钮：

```text
Connect button
  -> beginBleConnection(address, name)
  -> 显示 Connecting...
  -> ProductDeviceModel.connectBle(address)（连接页迁移目标）
  -> VescIf.connectBle(address)
  -> BleUart.startConnect(address)
  -> 停止扫描
  -> 发现 Nordic UART Service
  -> 校验 TX/RX Characteristic
  -> 开启 notification
  -> BleUart.connected()
  -> VescInterface portConnectedChanged()
  -> main.qml 返回首页
```

## 实时数据调用链

```text
ProductDeviceModel polling timer
  -> Commands.getValuesSetup()
  -> 设备协议 COMM_GET_VALUES_SETUP
  -> Packet.packetReceived()
  -> Commands.valuesSetupReceived(values, mask)
  -> ProductDeviceModel.applyTelemetry()
  -> 只读产品属性和过期数据状态
  -> BMHomePage / BMRealtimePage / BMDevicePage 属性绑定
```

## 数据字段

| UI 指标 | 协议字段/计算 | QML 属性 |
| --- | --- | --- |
| 速度 | `values.speed` | `speedMetersPerSecond` |
| 电量 | `values.battery_level * 100` | `batteryPercent` |
| 电压 | `values.v_in` | `inputVoltage` |
| 功率 | `values.current_in * values.v_in` | `powerWatts` |
| 本次里程 | `values.tachometer_abs / 1000` | `tripKm` |
| 累计里程 | `values.odometer / 1000` | `odometerKm` |
| 控制器温度 | `values.temp_mos` | `controllerTemperatureCelsius` |
| 电机温度 | `values.temp_motor` | `motorTemperatureCelsius` |
| 故障 | `values.fault_str` | `faultCode` / `faultText` |
| 固件版本 | `FW_RX_PARAMS.major/minor` | `firmwareVersion` |
| 设备型号 | `FW_RX_PARAMS.hw` | `hardwareName` |
| 设备 ID | `VescIf.getConnectedUuid()` | `deviceIdentifier` |

## 尚未实现

- 连接扫描页完全迁移到产品连接模型；当前扫描列表仍复用历史 `ConnectScreen`。
- 登录、注册、账号 Token 和云端设备绑定，属于第二阶段。
- 骑行历史、图表和排行榜。
- 服务端固件查询、hash 校验和受控升级，属于第二阶段。
- 正式隐私政策和用户协议 URL。
