import testwindow, nanovg

testwindow "Shapes", proc(ctx: ContextPtr) =

  ctx.fillColor(RGBA(0, 0, 0, 255))
  ctx.beginPath()
  ctx.rect(100, 100, 100, 100)
  ctx.circle(100, 100, 50)
  ctx.pathWinding(CW) # Make circle as be a hole.
  ctx.fill()