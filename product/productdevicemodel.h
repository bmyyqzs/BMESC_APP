#ifndef PRODUCTDEVICEMODEL_H
#define PRODUCTDEVICEMODEL_H

#include <QObject>
#include <QDateTime>
#include <QHash>
#include <QTimer>
#include <QVariantList>
#include <QVariantMap>
#include <QVector>

#include "vescinterface.h"

class ProductDeviceModel : public QObject
{
    Q_OBJECT
    Q_PROPERTY(VescInterface *vesc READ vesc WRITE setVesc NOTIFY vescChanged)
    Q_PROPERTY(bool connected READ connected NOTIFY connectionChanged)
    Q_PROPERTY(bool protocolReady READ protocolReady NOTIFY connectionAttemptChanged)
    Q_PROPERTY(QString connectionName READ connectionName NOTIFY connectionChanged)
    Q_PROPERTY(QString deviceName READ deviceName NOTIFY identityChanged)
    Q_PROPERTY(QString hardwareName READ hardwareName NOTIFY identityChanged)
    Q_PROPERTY(QString firmwareVersion READ firmwareVersion NOTIFY identityChanged)
    Q_PROPERTY(QString deviceIdentifier READ deviceIdentifier NOTIFY identityChanged)
    Q_PROPERTY(bool telemetryValid READ telemetryValid NOTIFY telemetryChanged)
    Q_PROPERTY(double speedMetersPerSecond READ speedMetersPerSecond NOTIFY telemetryChanged)
    Q_PROPERTY(double batteryPercent READ batteryPercent NOTIFY telemetryChanged)
    Q_PROPERTY(double inputVoltage READ inputVoltage NOTIFY telemetryChanged)
    Q_PROPERTY(double motorCurrentAmps READ motorCurrentAmps NOTIFY telemetryChanged)
    Q_PROPERTY(double inputCurrentAmps READ inputCurrentAmps NOTIFY telemetryChanged)
    Q_PROPERTY(double powerWatts READ powerWatts NOTIFY telemetryChanged)
    Q_PROPERTY(double controllerTemperatureCelsius READ controllerTemperatureCelsius NOTIFY telemetryChanged)
    Q_PROPERTY(double motorTemperatureCelsius READ motorTemperatureCelsius NOTIFY telemetryChanged)
    Q_PROPERTY(double odometerKm READ odometerKm NOTIFY telemetryChanged)
    Q_PROPERTY(double tripKm READ tripKm NOTIFY telemetryChanged)
    Q_PROPERTY(QString faultCode READ faultCode NOTIFY telemetryChanged)
    Q_PROPERTY(QString faultText READ faultText NOTIFY telemetryChanged)
    Q_PROPERTY(bool hasFault READ hasFault NOTIFY telemetryChanged)
    Q_PROPERTY(QVariantList faultLogs READ faultLogs NOTIFY faultLogsChanged)
    Q_PROPERTY(int faultLogCount READ faultLogCount NOTIFY faultLogsChanged)
    Q_PROPERTY(bool useImperialUnits READ useImperialUnits WRITE setUseImperialUnits NOTIFY useImperialUnitsChanged)
    Q_PROPERTY(bool highRateTelemetry READ highRateTelemetry WRITE setHighRateTelemetry NOTIFY highRateTelemetryChanged)
    Q_PROPERTY(bool scanning READ scanning NOTIFY scanChanged)
    Q_PROPERTY(bool scanFinished READ scanFinished NOTIFY scanChanged)
    Q_PROPERTY(bool connecting READ connecting NOTIFY connectionAttemptChanged)
    Q_PROPERTY(QString connectingIdentifier READ connectingIdentifier NOTIFY connectionAttemptChanged)
    Q_PROPERTY(int connectCountdownSeconds READ connectCountdownSeconds NOTIFY connectionAttemptChanged)
    Q_PROPERTY(QString connectionUiState READ connectionUiState NOTIFY connectionAttemptChanged)
    Q_PROPERTY(QString connectionErrorText READ connectionErrorText NOTIFY connectionAttemptChanged)
    Q_PROPERTY(QVariantList discoveredBleDevices READ discoveredBleDevices NOTIFY scanChanged)
    Q_PROPERTY(QVariantList canNodes READ canNodes NOTIFY canNodesChanged)
    Q_PROPERTY(bool canScanning READ canScanning NOTIFY canNodesChanged)
    Q_PROPERTY(int selectedCanNodeId READ selectedCanNodeId NOTIFY canNodesChanged)
    Q_PROPERTY(QString selectedNodeName READ selectedNodeName NOTIFY canNodesChanged)
    Q_PROPERTY(double sessionMaxSpeedMetersPerSecond READ sessionMaxSpeedMetersPerSecond NOTIFY telemetryChanged)
    Q_PROPERTY(double speedGaugeMaximumMetersPerSecond READ speedGaugeMaximumMetersPerSecond NOTIFY telemetryChanged)
    Q_PROPERTY(QDateTime lastTelemetryAt READ lastTelemetryAt NOTIFY telemetryChanged)
    Q_PROPERTY(QString languageCode READ languageCode WRITE setLanguageCode NOTIFY languageChanged)
    Q_PROPERTY(bool isEnglish READ isEnglish NOTIFY languageChanged)

public:
    explicit ProductDeviceModel(QObject *parent = nullptr);

    VescInterface *vesc() const;
    void setVesc(VescInterface *vesc);

    bool connected() const;
    bool protocolReady() const;
    QString connectionName() const;
    QString deviceName() const;
    QString hardwareName() const;
    QString firmwareVersion() const;
    QString deviceIdentifier() const;

    bool telemetryValid() const;
    double speedMetersPerSecond() const;
    double batteryPercent() const;
    double inputVoltage() const;
    double motorCurrentAmps() const;
    double inputCurrentAmps() const;
    double powerWatts() const;
    double controllerTemperatureCelsius() const;
    double motorTemperatureCelsius() const;
    double odometerKm() const;
    double tripKm() const;
    QString faultCode() const;
    QString faultText() const;
    bool hasFault() const;
    QVariantList faultLogs() const;
    int faultLogCount() const;

    bool useImperialUnits() const;
    void setUseImperialUnits(bool useImperial);

    bool highRateTelemetry() const;
    void setHighRateTelemetry(bool highRate);

    bool scanning() const;
    bool scanFinished() const;
    bool connecting() const;
    QString connectingIdentifier() const;
    int connectCountdownSeconds() const;
    QString connectionUiState() const;
    QString connectionErrorText() const;
    QVariantList discoveredBleDevices() const;
    QVariantList canNodes() const;
    bool canScanning() const;
    int selectedCanNodeId() const;
    QString selectedNodeName() const;
    double sessionMaxSpeedMetersPerSecond() const;
    double speedGaugeMaximumMetersPerSecond() const;
    QDateTime lastTelemetryAt() const;
    QString languageCode() const;
    void setLanguageCode(const QString &languageCode);
    bool isEnglish() const;

    Q_INVOKABLE void startBleScan();
    Q_INVOKABLE void connectBle(const QString &identifier);
    Q_INVOKABLE void connectDevice(const QString &identifier);
    Q_INVOKABLE void disconnectDevice();
    Q_INVOKABLE void scanCanNodes();
    Q_INVOKABLE void selectCanNode(int nodeId);
    Q_INVOKABLE void clearConnectionError();
    Q_INVOKABLE void clearFaultLogs();
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void toggleLanguage();
    Q_INVOKABLE QString faultTextForCode(const QString &faultCode, const QString &fallbackText = QString()) const;
    Q_INVOKABLE void seedFaultLogsForTesting(int count = 16);

signals:
    void vescChanged();
    void connectionChanged();
    void identityChanged();
    void telemetryChanged();
    void faultLogsChanged();
    void useImperialUnitsChanged();
    void highRateTelemetryChanged();
    void scanChanged();
    void connectionAttemptChanged();
    void canNodesChanged();
    void languageChanged();
    void requestShowHome();

private slots:
    void updateConnection();
    void updateIdentity();
    void pollTelemetry();
    void applyTelemetry(const SETUP_VALUES &values, unsigned int mask);
    void handleBleScanDone(QVariantMap devices, bool done);
    void handleBleError(const QString &info);
    void handleBleConnected();
    void handleFwRxChanged(bool rx, bool limited);
    void updateConnectCountdown();

private:
    VescInterface *mVesc;
    Commands *mCommands;
    QTimer mPollTimer;
    QTimer mConnectCountdownTimer;
    QDateTime mLastTelemetryAt;
    bool mTelemetryValid;
    bool mHighRateTelemetry;
    bool mScanning;
    bool mScanFinished;
    bool mConnecting;
    bool mPreviousBlockFwSwap;
    bool mProductBlockedFwSwap;
    bool mCanAutoSelectedOnConnect;
    bool mInitialNodeScanRequestedOnConnect;
    bool mCanScanning;
    int mConnectCountdownSeconds;
    double mSpeedMetersPerSecond;
    double mBatteryPercent;
    double mInputVoltage;
    double mMotorCurrentAmps;
    double mInputCurrentAmps;
    double mPowerWatts;
    double mControllerTemperatureCelsius;
    double mMotorTemperatureCelsius;
    double mOdometerKm;
    double mTripKm;
    double mSessionMaxSpeedMetersPerSecond;
    double mSpeedGaugeMaximumMetersPerSecond;
    QString mFaultCode;
    QString mFaultText;
    QVariantList mFaultLogs;
    QString mLastLoggedFaultCode;
    QString mConnectionErrorText;
    QString mConnectingIdentifier;
    QString mConnectingDeviceName;
    QVariantList mDiscoveredBleDevices;
    QVariantList mCanNodes;
    int mSelectedCanNodeId;
    QString mSelectedNodeName;
    QString mLanguageCode;
    QHash<QString, QString> mDiscoveredBleDeviceNames;

    enum class ProductConnectionFlow {
        Unknown,
        BleUartDirect,
        Express
    };

    ProductConnectionFlow mPendingConnectionFlow;
    ProductConnectionFlow mActiveConnectionFlow;

    void resetTelemetry();
    void loadFaultLogs();
    void saveFaultLogs() const;
    void appendFaultLog(const QString &faultCode, const QString &faultText);
    void finishConnectionAttempt();
    void blockFirmwareSwapForProductConnection();
    void restoreFirmwareSwapPolicy();
    void rebuildCanNodes(const QVector<int> &remoteNodes, bool isTimeout);
    void applyCanNodeSelection(int nodeId, bool showHome);
    void updateCanNodeSelectionFlags();
    void updateSpeedGaugeMaximum(const SETUP_VALUES &values);
    QString nameForCanNode(int nodeId) const;
    QString displayNameForBleDevice(const QString &identifier, const QString &rawName) const;
    ProductConnectionFlow classifyBleDevice(const QString &deviceName) const;
    void retranslateProductText();
    QString userFaultText(const QString &faultCode) const;
};

#endif // PRODUCTDEVICEMODEL_H
