import QtQuick 2.15

Item {
    id: root

    property real value: 0
    property real maxValue: 60
    property bool hasData: false
    property bool isEnglish: false
    property string unit: "KM/H"
    property color accentColor: "#dfbd91"
    property color secondaryAccentColor: Qt.rgba(0.30, 0.71, 1.0, 0.42)
    property real tickStep: 0

    readonly property real safeValue: hasData && isFinite(value) ? Math.max(0, value) : 0
    readonly property real safeMaxValue: isFinite(maxValue) ? Math.max(10, maxValue) : 60
    readonly property real effectiveTickStep: tickStep > 0 ? tickStep : automaticTickStep(safeMaxValue)
    readonly property real progress: Math.min(1, safeValue / safeMaxValue)

    property real animatedValue: safeValue
    property real animatedMaxValue: safeMaxValue
    property real dialRotation: hasData ? -8 + progress * 18 : 0

    implicitWidth: 230
    implicitHeight: 230

    function automaticTickStep(maximum) {
        var roundedMaximum = Math.max(10, isFinite(maximum) ? maximum : 60)
        var step = Math.max(10, Math.ceil(roundedMaximum / 100) * 10)
        if ((roundedMaximum / step) > 30) {
            step = roundedMaximum / 30
        }
        return step
    }

    onSafeValueChanged: animatedValue = safeValue
    onSafeMaxValueChanged: animatedMaxValue = safeMaxValue

    Behavior on animatedValue {
        NumberAnimation { duration: 420; easing.type: Easing.OutCubic }
    }

    Behavior on animatedMaxValue {
        NumberAnimation { duration: 520; easing.type: Easing.OutCubic }
    }

    Behavior on dialRotation {
        NumberAnimation { duration: 520; easing.type: Easing.OutCubic }
    }

    Canvas {
        id: tickCanvas
        anchors.fill: parent
        opacity: root.hasData ? 1.0 : 0.42

        onPaint: {
            var ctx = getContext("2d")
            var size = Math.min(width, height)
            var cx = width / 2
            var cy = height / 2
            var radius = size * 0.415
            var labelRadius = size * 0.472
            var startDeg = 132
            var sweepDeg = 276
            var tickStep = Math.max(1, root.effectiveTickStep)
            var maxValue = Math.max(tickStep, root.safeMaxValue)
            var minorPerStep = 5
            var activeRatio = Math.min(1, root.animatedValue / Math.max(1, root.animatedMaxValue))

            ctx.clearRect(0, 0, width, height)
            ctx.lineCap = "round"
            ctx.textAlign = "center"
            ctx.textBaseline = "middle"
            ctx.font = "bold " + Math.max(8, Math.round(size * 0.044)) + "px sans-serif"

            function angleForValue(tickValue) {
                return (startDeg + root.dialRotation + sweepDeg * tickValue / maxValue) * Math.PI / 180
            }

            function drawTick(tickValue, major) {
                var tickRatio = tickValue / maxValue
                var active = root.hasData && tickRatio <= activeRatio
                var angle = angleForValue(tickValue)
                var outer = radius
                var inner = radius - (major ? size * 0.060 : size * 0.031)

                ctx.beginPath()
                ctx.moveTo(cx + Math.cos(angle) * inner, cy + Math.sin(angle) * inner)
                ctx.lineTo(cx + Math.cos(angle) * outer, cy + Math.sin(angle) * outer)
                ctx.lineWidth = major ? 2.4 : 1.05
                ctx.strokeStyle = active ? root.accentColor : "rgba(244, 241, 234, 0.18)"
                ctx.stroke()
            }

            var majorValues = []
            for (var tickValue = 0; tickValue < maxValue; tickValue += tickStep) {
                majorValues.push(tickValue)
            }
            if (majorValues.length === 0 || Math.abs(majorValues[majorValues.length - 1] - maxValue) > 0.001) {
                majorValues.push(maxValue)
            }

            for (var i = 0; i < majorValues.length; ++i) {
                var majorValue = majorValues[i]
                drawTick(majorValue, true)

                if (i + 1 < majorValues.length) {
                    var minorStep = (majorValues[i + 1] - majorValue) / minorPerStep
                    for (var j = 1; j < minorPerStep; ++j) {
                        drawTick(majorValue + minorStep * j, false)
                    }
                }

                var labelAngle = angleForValue(majorValue)
                var labelX = cx + Math.cos(labelAngle) * labelRadius
                var labelY = cy + Math.sin(labelAngle) * labelRadius
                ctx.fillStyle = root.hasData ? "rgba(244, 241, 234, 0.64)" : "rgba(154, 163, 178, 0.42)"
                ctx.fillText(Math.round(majorValue).toString(), labelX, labelY)
            }
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Connections {
            target: root
            function onAnimatedValueChanged() { tickCanvas.requestPaint() }
            function onAnimatedMaxValueChanged() { tickCanvas.requestPaint() }
            function onDialRotationChanged() { tickCanvas.requestPaint() }
            function onAccentColorChanged() { tickCanvas.requestPaint() }
            function onHasDataChanged() { tickCanvas.requestPaint() }
            function onTickStepChanged() { tickCanvas.requestPaint() }
        }
    }

    Canvas {
        id: arcCanvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d")
            var size = Math.min(width, height)
            var cx = width / 2
            var cy = height / 2
            var radius = size * 0.365
            var start = 132 * Math.PI / 180
            var end = 408 * Math.PI / 180
            var ratio = Math.min(1, root.animatedValue / Math.max(1, root.animatedMaxValue))
            var progressEnd = start + (end - start) * ratio

            ctx.clearRect(0, 0, width, height)
            ctx.lineCap = "round"

            ctx.beginPath()
            ctx.arc(cx, cy, radius, start, end, false)
            ctx.lineWidth = size * 0.026
            ctx.strokeStyle = "rgba(244, 241, 234, 0.10)"
            ctx.stroke()

            if (root.hasData && ratio > 0.002) {
                ctx.beginPath()
                ctx.arc(cx, cy, radius, start, progressEnd, false)
                ctx.lineWidth = size * 0.034
                ctx.strokeStyle = root.accentColor
                ctx.stroke()

                ctx.beginPath()
                ctx.arc(cx, cy, radius - size * 0.038, start, progressEnd, false)
                ctx.lineWidth = size * 0.009
                ctx.strokeStyle = root.secondaryAccentColor
                ctx.stroke()
            }
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Connections {
            target: root
            function onAnimatedValueChanged() { arcCanvas.requestPaint() }
            function onAnimatedMaxValueChanged() { arcCanvas.requestPaint() }
            function onAccentColorChanged() { arcCanvas.requestPaint() }
            function onHasDataChanged() { arcCanvas.requestPaint() }
        }
    }

    Item {
        width: parent.width
        height: Math.min(104, parent.height * 0.45)
        anchors.centerIn: parent

        Text {
            id: speedText
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            text: root.hasData ? root.animatedValue.toFixed(1) : "--"
            color: "#f4f1ea"
            font.pixelSize: Math.max(42, root.width * 0.19)
            font.bold: true
            font.letterSpacing: 0
        }

        Text {
            id: unitText
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: speedText.bottom
            anchors.topMargin: 4
            text: root.unit
            color: root.accentColor
            font.pixelSize: 14
            font.bold: true
            font.letterSpacing: 0
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: unitText.bottom
            anchors.topMargin: 5
            text: root.isEnglish ? "Live Speed" : "实时速度"
            color: "#9aa3b2"
            font.pixelSize: 12
        }
    }

}
