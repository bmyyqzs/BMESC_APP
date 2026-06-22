import QtQuick 2.15

// App-level background reproducing the prototype's body + frame gradients
// (vesc_premium_mobility_prototype.html): a dark vertical base with a gold glow
// at top-left and a blue glow at top-right. Painted with Canvas radial gradients
// so no QtGraphicalEffects dependency is needed. Static: repaints only on resize.
Canvas {
    id: bg
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        var w = width
        var h = height

        // Base vertical gradient (the prototype .app frame).
        var lin = ctx.createLinearGradient(0, 0, 0, h)
        lin.addColorStop(0.0, "#0a0c11")
        lin.addColorStop(0.58, "#050609")
        lin.addColorStop(1.0, "#030406")
        ctx.fillStyle = lin
        ctx.fillRect(0, 0, w, h)

        // Gold glow, top-left (radial-gradient at 20% 0%).
        var g1 = ctx.createRadialGradient(w * 0.20, 0, 0, w * 0.20, 0, h * 0.34)
        g1.addColorStop(0.0, "rgba(217,180,106,0.22)")
        g1.addColorStop(1.0, "rgba(217,180,106,0.0)")
        ctx.fillStyle = g1
        ctx.fillRect(0, 0, w, h)

        // Blue glow, top-right (radial-gradient at 85% 16%).
        var g2 = ctx.createRadialGradient(w * 0.85, h * 0.16, 0, w * 0.85, h * 0.16, h * 0.32)
        g2.addColorStop(0.0, "rgba(77,180,255,0.18)")
        g2.addColorStop(1.0, "rgba(77,180,255,0.0)")
        ctx.fillStyle = g2
        ctx.fillRect(0, 0, w, h)
    }
}
