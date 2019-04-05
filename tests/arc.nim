import nanovg, testwindow, math, times

testwindow "Arc", proc(ctx: ContextPtr) =
  var
    xc = 128.0
    yc = 128.0
    radius = 100.0
    a = (sin(epochTime()) + 1) / 2
    angle1 = a * 120.0 * PI / 180.0  # angles are specified
    angle2 = 180.0 * PI / 180.0  # in radians

  ctx.beginPath()
  ctx.strokeColor(RGBA(0,0,0,255))
  ctx.strokeWidth(10.0)
  ctx.arc(xc, yc, radius, angle1, angle2)
  ctx.stroke()

  # draw helping lines
  ctx.beginPath()
  ctx.fillColor(RGBAf(1.0, 0.2, 0.2, 0.6))
  ctx.strokeWidth(6.0)
  ctx.arc(xc, yc, 10.0, 0, 2*PI)
  ctx.fill()

  ctx.beginPath()
  ctx.strokeColor(RGBAf(1.0, 0.2, 0.2, 0.6))
  ctx.arc(xc, yc, radius, angle1, angle1)
  ctx.lineTo(xc, yc)
  ctx.arc(xc, yc, radius, angle2, angle2)
  ctx.lineTo(xc, yc)
  ctx.stroke()