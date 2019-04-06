import nanovg, testwindow, math, times


testwindow "Scissor", proc(ctx: ContextPtr) =

  var a = (sin(epochTime()) + 1) / 2
  ctx.scissor(64*a, 64*a, 256 - 64*a*2, 256 - 64*a*2)

  ctx.fillColor(RGBA(0,0,0,255))
  ctx.beginPath()
  ctx.rect(0, 0, 256, 256)
  ctx.fill()

  ctx.beginPath()
  ctx.strokeColor(RGBA(0,255,0,255))
  ctx.moveTo(0, 0)
  ctx.lineTo(256, 256)
  ctx.moveTo(256, 0)
  ctx.lineTo(0, 256)
  ctx.strokeWidth(10.0)
  ctx.stroke()