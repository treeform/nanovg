
import glfw3 as glfw
import nanovg, opengl

proc testwindow*(title: string, code: proc(ctx: ContextPtr)) =

  proc errorcb(error: cint; desc: cstring) {.cdecl.}  =
    echo "GLFW error ", error, ": ", desc

  proc key(window: glfw.Window; key: cint; scancode: cint; action: cint; mods: cint) {.cdecl.} =
    if key == KEY_ESCAPE and action == PRESS:
      SetWindowShouldClose(window, cint(GL_TRUE))

  proc main(): cint =
    var window: glfw.Window
    var ctx: ContextPtr = nil
    var
      prevt: cdouble = 0
      cpuTime: cdouble = 0
    if not glfw.Init().bool:
      echo("Failed to init GLFW.")
      return - 1

    discard glfw.SetErrorCallback(errorcb)
    when not defined(windows):#_WIN32):
      # don't require this on win32, and works with more cards
      glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
      glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 2)
      glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, cint(GL_TRUE))
      glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
    glfw.WindowHint(glfw.OPENGL_DEBUG_CONTEXT, 1)
    when defined(DEMO_MSAA):
      glfw.WindowHint(glfw.SAMPLES, 4)
    window = glfw.CreateWindow(256, 256, title, nil, nil)
    if window.isNil:
      glfw.Terminate()
      return - 1
    discard glfw.SetKeyCallback(window, key)

    opengl.loadExtensions()

    glfw.MakeContextCurrent(window)
    when defined(NANOVG_GLEW):
      glewExperimental = cint(GL_TRUE)
      if glewInit() != GLEW_OK:
        printf("Could not init glew.\x0A")
        return - 1
      glGetError()
    ctx = CreateGL3(ANTIALIAS or STENCIL_STROKES or DEBUG)
    if ctx == nil:
      echo "Could not init nanovg."
      return - 1

    glfw.SwapInterval(0)

    glfw.SetTime(0)
    prevt = glfw.GetTime()
    while not glfw.WindowShouldClose(window).bool:
      var
        mx: cdouble
        my: cdouble
        t: cdouble
        dt: cdouble
      var
        winWidth: cint
        winHeight: cint
      var
        fbWidth: cint
        fbHeight: cint
      var pxRatio: cfloat
      t = glfw.GetTime()
      dt = t - prevt
      prevt = t

      glfw.GetCursorPos(window, addr(mx), addr(my))
      glfw.GetWindowSize(window, addr(winWidth), addr(winHeight))
      glfw.GetFramebufferSize(window, addr(fbWidth), addr(fbHeight))
      # Calculate pixel ration for hi-dpi devices.
      pxRatio = fbWidth.cfloat / cfloat(winWidth)
      # Update and render
      glViewport(0, 0, fbWidth, fbHeight)

      glClearColor(1.0, 1.0, 1.0, 1.0)
      glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or
          GL_STENCIL_BUFFER_BIT)
      ctx.beginFrame(winWidth, winHeight, pxRatio)

      code(ctx)

      ctx.endFrame()
      # Measure the CPU time taken excluding swap buffers (as the swap may wait for GPU)
      cpuTime = glfw.GetTime() - t

      glfw.SwapBuffers(window)
      glfw.PollEvents()


    glfw.Terminate()
    return 0

  programResult = main()
