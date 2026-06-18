#include "productdevicemodel.h"
#include "utility.h"

#include <QSettings>
#include <QtMath>
#include <QtGlobal>

namespace {
const char *faultLogsKey = "product/faultLogs";
const int maxFaultLogCount = 100;
const int nodeFwReadTimeoutMs = 1500;

QString firmwareString(const FW_RX_PARAMS &params)
{
    if (params.major < 0 || params.minor < 0) {
        return QStringLiteral("--");
    }

    return QStringLiteral("%1.%2").arg(params.major).arg(params.minor);
}

QString nodeTypeString(const FW_RX_PARAMS &params, bool readOk)
{
    if (!readOk) {
        return QStringLiteral("unknown");
    }

    switch (params.hwType) {
    case HW_TYPE_VESC:
        return QStringLiteral("motor");
    case HW_TYPE_VESC_BMS:
        return QStringLiteral("bms");
    case HW_TYPE_CUSTOM_MODULE:
        return QStringLiteral("module");
    }

    return QStringLiteral("unknown");
}

bool isMotorNode(const FW_RX_PARAMS &params, bool readOk)
{
    return readOk && params.hwType == HW_TYPE_VESC;
}

QString displayNameForNodeParams(const FW_RX_PARAMS &params, const QString &fallbackName)
{
    QString name = params.hw.trimmed();
    if (name.isEmpty()) {
        FW_RX_PARAMS paramsCopy = params;
        name = paramsCopy.hwTypeStr();
    }

    const QString firmwareName = params.fwName.trimmed();
    if (!firmwareName.isEmpty() && !name.contains(firmwareName, Qt::CaseInsensitive)) {
        name += QStringLiteral(" ") + firmwareName;
    }

    name = name.simplified().replace(QStringLiteral("_"), QStringLiteral(" "));
    return name.isEmpty() ? fallbackName : name;
}
}

ProductDeviceModel::ProductDeviceModel(QObject *parent)
    : QObject(parent),
      mVesc(nullptr),
      mCommands(nullptr),
      mTelemetryValid(false),
      mHighRateTelemetry(false),
      mScanning(false),
      mScanFinished(true),
      mConnecting(false),
      mPreviousBlockFwSwap(false),
      mProductBlockedFwSwap(false),
      mCanAutoSelectedOnConnect(false),
      mInitialNodeScanRequestedOnConnect(false),
      mCanScanning(false),
      mConnectCountdownSeconds(0),
      mSpeedMetersPerSecond(0.0),
      mBatteryPercent(0.0),
      mInputVoltage(0.0),
      mMotorCurrentAmps(0.0),
      mInputCurrentAmps(0.0),
      mPowerWatts(0.0),
      mControllerTemperatureCelsius(0.0),
      mMotorTemperatureCelsius(0.0),
      mOdometerKm(0.0),
      mTripKm(0.0),
      mSessionMaxSpeedMetersPerSecond(0.0),
      mFaultCode("FAULT_CODE_NONE"),
      mFaultText(tr("Ready")),
      mSelectedCanNodeId(-1),
      mPendingConnectionFlow(ProductConnectionFlow::Unknown),
      mActiveConnectionFlow(ProductConnectionFlow::Unknown)
{
    mPollTimer.setInterval(250);
    mPollTimer.setSingleShot(false);
    connect(&mPollTimer, &QTimer::timeout, this, &ProductDeviceModel::pollTelemetry);
    mPollTimer.start();

    mConnectCountdownTimer.setInterval(1000);
    mConnectCountdownTimer.setSingleShot(false);
    connect(&mConnectCountdownTimer, &QTimer::timeout,
            this, &ProductDeviceModel::updateConnectCountdown);

    loadFaultLogs();
}

VescInterface *ProductDeviceModel::vesc() const
{
    return mVesc;
}

void ProductDeviceModel::setVesc(VescInterface *vesc)
{
    if (mVesc == vesc) {
        return;
    }

    if (mVesc) {
        restoreFirmwareSwapPolicy();
        disconnect(mVesc, nullptr, this, nullptr);
    }
    if (mCommands) {
        disconnect(mCommands, nullptr, this, nullptr);
    }

    mVesc = vesc;
    mCommands = mVesc ? mVesc->commands() : nullptr;

    if (mVesc) {
        connect(mVesc, &VescInterface::portConnectedChanged,
                this, &ProductDeviceModel::updateConnection);
        connect(mVesc, &VescInterface::fwRxChanged,
                this, &ProductDeviceModel::handleFwRxChanged);
        connect(mVesc, &VescInterface::fwRxChanged,
                this, &ProductDeviceModel::updateIdentity);
        connect(mVesc, &VescInterface::useImperialUnitsChanged,
                this, &ProductDeviceModel::useImperialUnitsChanged);
#ifdef HAS_BLUETOOTH
        if (mVesc->bleDevice()) {
            connect(mVesc->bleDevice(), &BleUart::scanDone,
                    this, &ProductDeviceModel::handleBleScanDone);
            connect(mVesc->bleDevice(), &BleUart::bleError,
                    this, &ProductDeviceModel::handleBleError);
            connect(mVesc->bleDevice(), &BleUart::connected,
                    this, &ProductDeviceModel::handleBleConnected);
        }
#endif
    }

    if (mCommands) {
        connect(mCommands, &Commands::valuesSetupReceived,
                this, &ProductDeviceModel::applyTelemetry);
    }

    resetTelemetry();
    updateConnection();
    updateIdentity();
    emit vescChanged();
}

bool ProductDeviceModel::connected() const
{
    return mVesc && mVesc->isPortConnected();
}

bool ProductDeviceModel::protocolReady() const
{
    return connected() && mVesc && mVesc->fwRx();
}

QString ProductDeviceModel::connectionName() const
{
    return mVesc ? mVesc->getConnectedPortName() : tr("Not connected");
}

QString ProductDeviceModel::deviceName() const
{
    return hardwareName().isEmpty() ? tr("BM Device") : hardwareName();
}

QString ProductDeviceModel::hardwareName() const
{
    if (!connected()) {
        return QString();
    }

    FW_RX_PARAMS params = mVesc->getLastFwRxParams();
    return params.hw.isEmpty() ? params.hwTypeStr() : params.hw;
}

QString ProductDeviceModel::firmwareVersion() const
{
    if (!connected()) {
        return QString();
    }

    FW_RX_PARAMS params = mVesc->getLastFwRxParams();
    if (params.major < 0 || params.minor < 0) {
        return QString();
    }

    return QString("%1.%2").arg(params.major).arg(params.minor);
}

QString ProductDeviceModel::deviceIdentifier() const
{
    return connected() ? mVesc->getConnectedUuid() : QString();
}

bool ProductDeviceModel::telemetryValid() const { return mTelemetryValid; }
double ProductDeviceModel::speedMetersPerSecond() const { return mSpeedMetersPerSecond; }
double ProductDeviceModel::batteryPercent() const { return mBatteryPercent; }
double ProductDeviceModel::inputVoltage() const { return mInputVoltage; }
double ProductDeviceModel::motorCurrentAmps() const { return mMotorCurrentAmps; }
double ProductDeviceModel::inputCurrentAmps() const { return mInputCurrentAmps; }
double ProductDeviceModel::powerWatts() const { return mPowerWatts; }
double ProductDeviceModel::controllerTemperatureCelsius() const { return mControllerTemperatureCelsius; }
double ProductDeviceModel::motorTemperatureCelsius() const { return mMotorTemperatureCelsius; }
double ProductDeviceModel::odometerKm() const { return mOdometerKm; }
double ProductDeviceModel::tripKm() const { return mTripKm; }
QString ProductDeviceModel::faultCode() const { return mFaultCode; }
QString ProductDeviceModel::faultText() const { return mFaultText; }
bool ProductDeviceModel::hasFault() const { return mFaultCode != "FAULT_CODE_NONE"; }
QVariantList ProductDeviceModel::faultLogs() const { return mFaultLogs; }
int ProductDeviceModel::faultLogCount() const { return mFaultLogs.size(); }

bool ProductDeviceModel::useImperialUnits() const
{
    return mVesc && mVesc->useImperialUnits();
}

void ProductDeviceModel::setUseImperialUnits(bool useImperial)
{
    if (!mVesc || mVesc->useImperialUnits() == useImperial) {
        return;
    }

    mVesc->setUseImperialUnits(useImperial);
}

bool ProductDeviceModel::highRateTelemetry() const
{
    return mHighRateTelemetry;
}

void ProductDeviceModel::setHighRateTelemetry(bool highRate)
{
    if (mHighRateTelemetry == highRate) {
        return;
    }

    mHighRateTelemetry = highRate;
    mPollTimer.setInterval(highRate ? 50 : 250);
    emit highRateTelemetryChanged();
}

bool ProductDeviceModel::scanning() const { return mScanning; }
bool ProductDeviceModel::scanFinished() const { return mScanFinished; }
bool ProductDeviceModel::connecting() const { return mConnecting; }
QString ProductDeviceModel::connectingIdentifier() const { return mConnectingIdentifier; }
int ProductDeviceModel::connectCountdownSeconds() const { return mConnectCountdownSeconds; }
QString ProductDeviceModel::connectionErrorText() const { return mConnectionErrorText; }
QVariantList ProductDeviceModel::discoveredBleDevices() const { return mDiscoveredBleDevices; }
QVariantList ProductDeviceModel::canNodes() const { return mCanNodes; }
bool ProductDeviceModel::canScanning() const { return mCanScanning; }
int ProductDeviceModel::selectedCanNodeId() const { return mSelectedCanNodeId; }
QString ProductDeviceModel::selectedNodeName() const { return mSelectedNodeName; }
double ProductDeviceModel::sessionMaxSpeedMetersPerSecond() const { return mSessionMaxSpeedMetersPerSecond; }
QDateTime ProductDeviceModel::lastTelemetryAt() const { return mLastTelemetryAt; }

QString ProductDeviceModel::connectionUiState() const
{
    if (protocolReady()) {
        return QStringLiteral("connected");
    }
    if (connected()) {
        return QStringLiteral("reading");
    }
    if (mConnecting) {
        return QStringLiteral("connecting");
    }
    if (!mConnectionErrorText.isEmpty()) {
        return QStringLiteral("failed");
    }
    if (mScanning) {
        return QStringLiteral("scanning");
    }
    return QStringLiteral("disconnected");
}

void ProductDeviceModel::startBleScan()
{
#ifdef HAS_BLUETOOTH
    if (!mVesc || !mVesc->bleDevice()) {
        mConnectionErrorText = tr("Bluetooth is unavailable.");
        emit connectionAttemptChanged();
        return;
    }

    mConnectionErrorText.clear();
    mScanning = true;
    mScanFinished = false;
    mPendingConnectionFlow = ProductConnectionFlow::Unknown;
    emit scanChanged();
    emit connectionAttemptChanged();
    mVesc->bleDevice()->startScan();
#else
    mConnectionErrorText = tr("Bluetooth is unavailable.");
    emit connectionAttemptChanged();
#endif
}

void ProductDeviceModel::connectBle(const QString &identifier)
{
    connectDevice(identifier);
}

void ProductDeviceModel::connectDevice(const QString &identifier)
{
    if (!mVesc || identifier.isEmpty()) {
        return;
    }
    if (mConnecting) {
        return;
    }

    if (mCommands) {
        mCommands->setSendCan(false, 0);
    }
    blockFirmwareSwapForProductConnection();
    mSelectedCanNodeId = -1;
    mSelectedNodeName.clear();
    mCanNodes.clear();
    mCanAutoSelectedOnConnect = false;
    mInitialNodeScanRequestedOnConnect = false;

    mConnectionErrorText.clear();
    mConnectingIdentifier = identifier;
    const QString rawDeviceName = mDiscoveredBleDeviceNames.value(identifier);
    mConnectingDeviceName = rawDeviceName.trimmed().isEmpty()
            ? displayNameForBleDevice(identifier, rawDeviceName)
            : rawDeviceName;
    mPendingConnectionFlow = classifyBleDevice(mConnectingDeviceName);
    mScanning = false;
    mScanFinished = true;
    mConnecting = true;
    mConnectCountdownSeconds = 15;
    resetTelemetry();
    emit scanChanged();
    emit canNodesChanged();
    mConnectCountdownTimer.start();
    emit connectionAttemptChanged();
    mVesc->connectBle(identifier);
}

void ProductDeviceModel::disconnectDevice()
{
    if (mVesc) {
        mVesc->disconnectPort();
    }
    restoreFirmwareSwapPolicy();
    finishConnectionAttempt();
    mActiveConnectionFlow = ProductConnectionFlow::Unknown;
    mPendingConnectionFlow = ProductConnectionFlow::Unknown;
    mSelectedCanNodeId = -1;
    mSelectedNodeName.clear();
    mCanNodes.clear();
    mCanAutoSelectedOnConnect = false;
    mInitialNodeScanRequestedOnConnect = false;
    emit canNodesChanged();
    emit connectionAttemptChanged();
}

void ProductDeviceModel::scanCanNodes()
{
    if (!connected() || !mCommands || !mVesc) {
        mCanScanning = false;
        mCanNodes.clear();
        emit canNodesChanged();
        return;
    }

    if (mCanScanning) {
        return;
    }
    mCanScanning = true;
    emit canNodesChanged();

    const QVector<int> remoteNodes = mVesc->scanCan();

    mCanScanning = false;
    rebuildCanNodes(remoteNodes, false);
}

void ProductDeviceModel::selectCanNode(int nodeId)
{
    applyCanNodeSelection(nodeId, true);
}

void ProductDeviceModel::clearConnectionError()
{
    if (mConnectionErrorText.isEmpty()) {
        return;
    }
    mConnectionErrorText.clear();
    emit connectionAttemptChanged();
}

void ProductDeviceModel::clearFaultLogs()
{
    if (mFaultLogs.isEmpty()) {
        return;
    }

    mFaultLogs.clear();
    saveFaultLogs();
    emit faultLogsChanged();
}

void ProductDeviceModel::refresh()
{
    updateConnection();
    updateIdentity();
    pollTelemetry();
}

void ProductDeviceModel::updateConnection()
{
    if (!connected()) {
        restoreFirmwareSwapPolicy();
        resetTelemetry();
        mActiveConnectionFlow = ProductConnectionFlow::Unknown;
        mCanNodes.clear();
        mSelectedCanNodeId = -1;
        mSelectedNodeName.clear();
        mCanAutoSelectedOnConnect = false;
        mInitialNodeScanRequestedOnConnect = false;
        mCanScanning = false;
        emit canNodesChanged();
    } else {
        finishConnectionAttempt();
        if (mPendingConnectionFlow != ProductConnectionFlow::Unknown) {
            mActiveConnectionFlow = mPendingConnectionFlow;
        }
    }

    emit connectionChanged();
    emit connectionAttemptChanged();
    updateIdentity();
}

void ProductDeviceModel::updateIdentity()
{
    emit identityChanged();
}

void ProductDeviceModel::pollTelemetry()
{
    if (!connected() || !mCommands) {
        if (mTelemetryValid) {
            resetTelemetry();
        }
        return;
    }

    if (!mVesc || !mVesc->fwRx()) {
        return;
    }

    if (mTelemetryValid && mLastTelemetryAt.msecsTo(QDateTime::currentDateTimeUtc()) > 2000) {
        mTelemetryValid = false;
        emit telemetryChanged();
    }

    mCommands->getValuesSetup();
}

void ProductDeviceModel::applyTelemetry(const SETUP_VALUES &values, unsigned int mask)
{
    Q_UNUSED(mask)

    if (!connected()) {
        return;
    }

    mLastTelemetryAt = QDateTime::currentDateTimeUtc();
    mTelemetryValid = true;
    mSpeedMetersPerSecond = values.speed;
    mBatteryPercent = qBound(0.0, values.battery_level * 100.0, 100.0);
    mInputVoltage = values.v_in;
    mMotorCurrentAmps = values.current_motor;
    mInputCurrentAmps = values.current_in;
    mPowerWatts = values.v_in * values.current_in;
    mControllerTemperatureCelsius = values.temp_mos;
    mMotorTemperatureCelsius = values.temp_motor;
    mOdometerKm = qMax(0.0, double(values.odometer) / 1000.0);
    mTripKm = qMax(0.0, values.tachometer_abs / 1000.0);
    mSessionMaxSpeedMetersPerSecond = qMax(mSessionMaxSpeedMetersPerSecond, qAbs(mSpeedMetersPerSecond));
    mFaultCode = values.fault_str.isEmpty() ? "FAULT_CODE_NONE" : values.fault_str;
    mFaultText = userFaultText(mFaultCode);

    if (mFaultCode == "FAULT_CODE_NONE") {
        mLastLoggedFaultCode.clear();
    } else if (mFaultCode != mLastLoggedFaultCode) {
        appendFaultLog(mFaultCode, mFaultText);
        mLastLoggedFaultCode = mFaultCode;
    }

    emit telemetryChanged();
}

void ProductDeviceModel::resetTelemetry()
{
    mLastTelemetryAt = QDateTime();
    mTelemetryValid = false;
    mSpeedMetersPerSecond = 0.0;
    mBatteryPercent = 0.0;
    mInputVoltage = 0.0;
    mMotorCurrentAmps = 0.0;
    mInputCurrentAmps = 0.0;
    mPowerWatts = 0.0;
    mControllerTemperatureCelsius = 0.0;
    mMotorTemperatureCelsius = 0.0;
    mOdometerKm = 0.0;
    mTripKm = 0.0;
    mSessionMaxSpeedMetersPerSecond = 0.0;
    mFaultCode = "FAULT_CODE_NONE";
    mFaultText = tr("Ready");
    emit telemetryChanged();
}

void ProductDeviceModel::loadFaultLogs()
{
    QSettings settings;
    mFaultLogs = settings.value(QString::fromLatin1(faultLogsKey)).toList();
    if (mFaultLogs.size() > maxFaultLogCount) {
        mFaultLogs = mFaultLogs.mid(0, maxFaultLogCount);
        saveFaultLogs();
    }
    emit faultLogsChanged();
}

void ProductDeviceModel::saveFaultLogs() const
{
    QSettings settings;
    settings.setValue(QString::fromLatin1(faultLogsKey), mFaultLogs);
}

void ProductDeviceModel::appendFaultLog(const QString &faultCode, const QString &faultText)
{
    const QDateTime now = QDateTime::currentDateTime();
    QVariantMap log;
    log.insert(QStringLiteral("timestamp"), now.toString(Qt::ISODate));
    log.insert(QStringLiteral("displayTime"), now.toString(QStringLiteral("yyyy-MM-dd HH:mm:ss")));
    log.insert(QStringLiteral("deviceName"), deviceName());
    log.insert(QStringLiteral("deviceIdentifier"), deviceIdentifier());
    log.insert(QStringLiteral("selectedNodeName"), selectedNodeName());
    log.insert(QStringLiteral("selectedCanNodeId"), mSelectedCanNodeId);
    log.insert(QStringLiteral("faultCode"), faultCode);
    log.insert(QStringLiteral("faultText"), faultText);
    log.insert(QStringLiteral("speedMetersPerSecond"), mSpeedMetersPerSecond);
    log.insert(QStringLiteral("batteryPercent"), mBatteryPercent);
    log.insert(QStringLiteral("inputVoltage"), mInputVoltage);
    log.insert(QStringLiteral("controllerTemperatureCelsius"), mControllerTemperatureCelsius);
    log.insert(QStringLiteral("motorTemperatureCelsius"), mMotorTemperatureCelsius);

    mFaultLogs.prepend(log);
    while (mFaultLogs.size() > maxFaultLogCount) {
        mFaultLogs.removeLast();
    }

    saveFaultLogs();
    emit faultLogsChanged();
}

void ProductDeviceModel::handleBleScanDone(QVariantMap devices, bool done)
{
    QVariantList list;
    mDiscoveredBleDeviceNames.clear();
    for (auto it = devices.constBegin(); it != devices.constEnd(); ++it) {
        QVariantMap item;
        const QString identifier = it.key();
        const QString rawName = it.value().toString();
        mDiscoveredBleDeviceNames.insert(identifier, rawName);
        item.insert(QStringLiteral("identifier"), identifier);
        item.insert(QStringLiteral("name"), displayNameForBleDevice(identifier, rawName));
        item.insert(QStringLiteral("rawName"), rawName);
        item.insert(QStringLiteral("preferred"), mVesc ? mVesc->getBlePreferred(identifier) : false);
        item.insert(QStringLiteral("connected"), connected() && deviceIdentifier() == identifier);
        list.append(item);
    }

    mDiscoveredBleDevices = list;
    mScanning = !done;
    mScanFinished = done;
    emit scanChanged();
    emit connectionAttemptChanged();
}

void ProductDeviceModel::handleBleError(const QString &info)
{
    mConnectionErrorText = info;
    mScanning = false;
    mScanFinished = true;
    mPendingConnectionFlow = ProductConnectionFlow::Unknown;
    restoreFirmwareSwapPolicy();
    finishConnectionAttempt();
    emit scanChanged();
    emit connectionAttemptChanged();
}

void ProductDeviceModel::handleBleConnected()
{
    mScanning = false;
    mScanFinished = true;
    finishConnectionAttempt();
    emit scanChanged();
    emit connectionAttemptChanged();
}

void ProductDeviceModel::handleFwRxChanged(bool rx, bool limited)
{
    Q_UNUSED(limited)

    emit connectionAttemptChanged();

    if (!rx || !connected()) {
        return;
    }

    restoreFirmwareSwapPolicy();

    if (mActiveConnectionFlow == ProductConnectionFlow::Express) {
        if (mInitialNodeScanRequestedOnConnect) {
            return;
        }
        mInitialNodeScanRequestedOnConnect = true;
        scanCanNodes();
        return;
    }

    if (mActiveConnectionFlow == ProductConnectionFlow::BleUartDirect) {
        if (mInitialNodeScanRequestedOnConnect) {
            return;
        }
        mInitialNodeScanRequestedOnConnect = true;
        mSelectedCanNodeId = -1;
        mSelectedNodeName = tr("Local device");
        updateCanNodeSelectionFlags();
        emit canNodesChanged();
        pollTelemetry();
        emit requestShowHome();
    }
}

void ProductDeviceModel::updateConnectCountdown()
{
    if (!mConnecting) {
        mConnectCountdownTimer.stop();
        return;
    }

    mConnectCountdownSeconds = qMax(0, mConnectCountdownSeconds - 1);
    if (mConnectCountdownSeconds == 0) {
        mConnectionErrorText = tr("Connection timed out.");
        mScanning = false;
        mScanFinished = true;
        mPendingConnectionFlow = ProductConnectionFlow::Unknown;
        restoreFirmwareSwapPolicy();
        finishConnectionAttempt();
        emit scanChanged();
    }
    emit connectionAttemptChanged();
}

void ProductDeviceModel::finishConnectionAttempt()
{
    mConnecting = false;
    mConnectingIdentifier.clear();
    mConnectingDeviceName.clear();
    mConnectCountdownSeconds = 0;
    mConnectCountdownTimer.stop();
}

void ProductDeviceModel::blockFirmwareSwapForProductConnection()
{
    if (!mVesc || mProductBlockedFwSwap) {
        return;
    }

    mPreviousBlockFwSwap = mVesc->isBlockFwSwap();
    mProductBlockedFwSwap = true;
    mVesc->setBlockFwSwap(true);
}

void ProductDeviceModel::restoreFirmwareSwapPolicy()
{
    if (!mVesc || !mProductBlockedFwSwap) {
        return;
    }

    mVesc->setBlockFwSwap(mPreviousBlockFwSwap);
    mProductBlockedFwSwap = false;
}

void ProductDeviceModel::rebuildCanNodes(const QVector<int> &remoteNodes, bool isTimeout)
{
    QVariantList nodes;
    int firstMotorNodeId = -1;
    bool hasFirstMotorNode = false;
    int previousSelectedNodeId = mSelectedCanNodeId;

    FW_RX_PARAMS localParams;
    bool localReadOk = false;
    if (mVesc) {
        localReadOk = Utility::getFwVersionBlockingCan(mVesc, &localParams, -1, nodeFwReadTimeoutMs);
    }
    const bool localEnabled = isMotorNode(localParams, localReadOk);

    QVariantMap local;
    local.insert(QStringLiteral("id"), -1);
    local.insert(QStringLiteral("displayId"), QStringLiteral("LOCAL"));
    local.insert(QStringLiteral("name"), localReadOk
                 ? displayNameForNodeParams(localParams, tr("Local device"))
                 : tr("Local device"));
    local.insert(QStringLiteral("firmware"), localReadOk ? firmwareString(localParams) : QStringLiteral("--"));
    local.insert(QStringLiteral("nodeType"), nodeTypeString(localParams, localReadOk));
    local.insert(QStringLiteral("enabled"), localEnabled);
    local.insert(QStringLiteral("state"), localEnabled ? tr("可用") : tr("不可用"));
    local.insert(QStringLiteral("selected"), localEnabled && mSelectedCanNodeId < 0);
    nodes.append(local);

    for (int nodeId : remoteNodes) {
        FW_RX_PARAMS params;
        bool readOk = false;
        if (mVesc && !isTimeout) {
            readOk = Utility::getFwVersionBlockingCan(mVesc, &params, nodeId, nodeFwReadTimeoutMs);
        }
        const bool nodeEnabled = isMotorNode(params, readOk);

        if (nodeEnabled && !hasFirstMotorNode) {
            firstMotorNodeId = nodeId;
            hasFirstMotorNode = true;
        }

        QVariantMap node;
        node.insert(QStringLiteral("id"), nodeId);
        node.insert(QStringLiteral("displayId"), QString::number(nodeId));
        node.insert(QStringLiteral("name"), readOk
                    ? displayNameForNodeParams(params, tr("节点 %1").arg(nodeId))
                    : tr("节点 %1").arg(nodeId));
        node.insert(QStringLiteral("firmware"), readOk ? firmwareString(params) : QStringLiteral("--"));
        node.insert(QStringLiteral("nodeType"), nodeTypeString(params, readOk));
        node.insert(QStringLiteral("enabled"), nodeEnabled);
        node.insert(QStringLiteral("state"), nodeEnabled ? tr("可用") : tr("不可用"));
        node.insert(QStringLiteral("selected"), nodeEnabled && mSelectedCanNodeId == nodeId);
        nodes.append(node);
    }

    mCanNodes = nodes;
    updateCanNodeSelectionFlags();
    mSelectedNodeName = nameForCanNode(mSelectedCanNodeId);
    emit canNodesChanged();

    if (mActiveConnectionFlow == ProductConnectionFlow::Express && !mCanAutoSelectedOnConnect &&
            hasFirstMotorNode) {
        mCanAutoSelectedOnConnect = true;
        if (previousSelectedNodeId != firstMotorNodeId) {
            applyCanNodeSelection(firstMotorNodeId, true);
        }
    }
}

void ProductDeviceModel::applyCanNodeSelection(int nodeId, bool showHome)
{
    if (!mCommands) {
        return;
    }

    bool selectableNode = false;
    for (const QVariant &item : mCanNodes) {
        const QVariantMap node = item.toMap();
        if (node.value(QStringLiteral("id")).toInt() == nodeId) {
            selectableNode = node.value(QStringLiteral("enabled")).toBool();
            break;
        }
    }

    if (!selectableNode) {
        return;
    }

    if (nodeId < 0) {
        mCommands->setSendCan(false, 0);
        mSelectedCanNodeId = -1;
    } else {
        mCommands->setSendCan(true, nodeId);
        mSelectedCanNodeId = nodeId;
    }

    mSelectedNodeName = nameForCanNode(mSelectedCanNodeId);
    updateCanNodeSelectionFlags();

    resetTelemetry();
    emit canNodesChanged();
    pollTelemetry();

    if (showHome && protocolReady()) {
        emit requestShowHome();
    }
}

void ProductDeviceModel::updateCanNodeSelectionFlags()
{
    for (int i = 0; i < mCanNodes.size(); ++i) {
        QVariantMap node = mCanNodes.at(i).toMap();
        node.insert(QStringLiteral("selected"), node.value(QStringLiteral("enabled")).toBool() &&
                    node.value(QStringLiteral("id")).toInt() == mSelectedCanNodeId);
        mCanNodes[i] = node;
    }
}

QString ProductDeviceModel::nameForCanNode(int nodeId) const
{
    for (const QVariant &item : mCanNodes) {
        const QVariantMap node = item.toMap();
        if (node.value(QStringLiteral("id")).toInt() == nodeId) {
            const QString name = node.value(QStringLiteral("name")).toString();
            if (!name.trimmed().isEmpty()) {
                return name;
            }
        }
    }

    return nodeId < 0 ? tr("Local device") : tr("Node %1").arg(nodeId);
}

QString ProductDeviceModel::displayNameForBleDevice(const QString &identifier, const QString &rawName) const
{
    QString storedName = mVesc ? mVesc->getBleName(identifier) : QString();
    if (!storedName.isEmpty()) {
        return storedName;
    }
    if (!rawName.trimmed().isEmpty()) {
        return rawName.trimmed();
    }
    return tr("BM Device");
}

ProductDeviceModel::ProductConnectionFlow ProductDeviceModel::classifyBleDevice(const QString &deviceName) const
{
    const QString normalizedName = deviceName.trimmed();
    if (normalizedName.isEmpty()) {
        return ProductConnectionFlow::Unknown;
    }

    if (normalizedName.contains(QStringLiteral("EXPRESS"), Qt::CaseInsensitive)) {
        return ProductConnectionFlow::Express;
    }

    return ProductConnectionFlow::BleUartDirect;
}

QString ProductDeviceModel::userFaultText(const QString &faultCode)
{
    if (faultCode.isEmpty() || faultCode == "FAULT_CODE_NONE") {
        return tr("正常");
    }

    if (faultCode == "FAULT_CODE_OVER_VOLTAGE") {
        return tr("电池电压过高，请停止使用并检查电池");
    } else if (faultCode == "FAULT_CODE_UNDER_VOLTAGE") {
        return tr("电池电量或电压过低，请及时充电");
    } else if (faultCode == "FAULT_CODE_DRV") {
        return tr("电机驱动异常，请停止使用并联系售后");
    } else if (faultCode == "FAULT_CODE_ABS_OVER_CURRENT") {
        return tr("电流过大，设备已保护，请稍后再试");
    } else if (faultCode == "FAULT_CODE_OVER_TEMP_FET") {
        return tr("控制器温度过高，请停下等待降温");
    } else if (faultCode == "FAULT_CODE_OVER_TEMP_MOTOR") {
        return tr("电机温度过高，请停下等待降温");
    } else if (faultCode == "FAULT_CODE_GATE_DRIVER_OVER_VOLTAGE") {
        return tr("驱动电压异常偏高，请停止使用并检查设备");
    } else if (faultCode == "FAULT_CODE_GATE_DRIVER_UNDER_VOLTAGE") {
        return tr("驱动电压异常偏低，请停止使用并检查设备");
    } else if (faultCode == "FAULT_CODE_MCU_UNDER_VOLTAGE") {
        return tr("控制器供电不足，请检查电池和连接");
    } else if (faultCode == "FAULT_CODE_BOOTING_FROM_WATCHDOG_RESET") {
        return tr("设备刚刚自动重启，请观察是否恢复正常");
    } else if (faultCode == "FAULT_CODE_ENCODER_SPI") {
        return tr("电机位置传感器通信异常，请联系售后");
    } else if (faultCode == "FAULT_CODE_ENCODER_SINCOS_BELOW_MIN_AMPLITUDE") {
        return tr("电机位置传感器信号过弱，请联系售后");
    } else if (faultCode == "FAULT_CODE_ENCODER_SINCOS_ABOVE_MAX_AMPLITUDE") {
        return tr("电机位置传感器信号过强，请联系售后");
    } else if (faultCode == "FAULT_CODE_FLASH_CORRUPTION") {
        return tr("设备存储数据异常，请联系售后");
    } else if (faultCode == "FAULT_CODE_HIGH_OFFSET_CURRENT_SENSOR_1" ||
               faultCode == "FAULT_CODE_HIGH_OFFSET_CURRENT_SENSOR_2" ||
               faultCode == "FAULT_CODE_HIGH_OFFSET_CURRENT_SENSOR_3") {
        return tr("电流检测异常，请停止使用并联系售后");
    } else if (faultCode == "FAULT_CODE_UNBALANCED_CURRENTS") {
        return tr("电机电流不平衡，请停止使用并检查设备");
    } else if (faultCode == "FAULT_CODE_BRK") {
        return tr("制动保护触发，请松开刹车后再试");
    } else if (faultCode == "FAULT_CODE_RESOLVER_LOT" ||
               faultCode == "FAULT_CODE_RESOLVER_DOS") {
        return tr("电机位置传感器异常，请联系售后");
    } else if (faultCode == "FAULT_CODE_RESOLVER_LOS") {
        return tr("电机位置传感器信号丢失，请联系售后");
    } else if (faultCode == "FAULT_CODE_FLASH_CORRUPTION_APP_CFG") {
        return tr("应用配置异常，请联系售后");
    } else if (faultCode == "FAULT_CODE_FLASH_CORRUPTION_MC_CFG") {
        return tr("电机配置异常，请联系售后");
    } else if (faultCode == "FAULT_CODE_ENCODER_NO_MAGNET") {
        return tr("电机传感器未检测到磁体，请联系售后");
    } else if (faultCode == "FAULT_CODE_ENCODER_MAGNET_TOO_STRONG") {
        return tr("电机传感器磁场过强，请联系售后");
    } else if (faultCode == "FAULT_CODE_PHASE_FILTER") {
        return tr("电机相位检测异常，请停止使用并联系售后");
    } else if (faultCode == "FAULT_CODE_ENCODER_FAULT") {
        return tr("电机位置传感器故障，请联系售后");
    }

    return tr("未知异常，请停止使用并联系售后");
}
