import testwindow, nanovg

testwindow "Shapes", proc(ctx: ContextPtr) =
  ctx.beginPath()
  ctx.rect(100, 100, 100, 100)
  ctx.circle(100, 100, 50)
  ctx.pathWinding(HOLE) # Mark circle as a hole.
  ctx.fillColor(RGBA(0, 0, 0, 255))
  ctx.fill()