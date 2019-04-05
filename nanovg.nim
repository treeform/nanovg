#
# Copyright (c) 2013 Mikko Mononen memon@inside.org
#
# This software is provided 'as-is', without any express or implied
# warranty.  In no event will the authors be held liable for any damages
# arising from the use of this software.
# Permission is granted to anyone to use this software for any purpose,
# including commercial applications, and to alter it and redistribute it
# freely, subject to the following restrictions:
# 1. The origin of this software must not be misrepresented; you must not
#    claim that you wrote the original software. If you use this software
#    in a product, an acknowledgment in the product documentation would be
#    appreciated but is not required.
# 2. Altered source versions must be plainly marked as such, and must not be
#    misrepresented as being the original software.
# 3. This notice may not be removed or altered from any source distribution.
#
import math , opengl

when defined(nvgGL2):
  const GLVersionStr* = "GL2"
elif defined(nvgGL3):
  const GLVersionStr* = "GL3"
elif defined(nvgGLES2):
  const GLVersionStr* = "GLES2"
elif defined(nvgGLES3):
  const GLVersionStr* = "GLES3"
else:
  # defaults to GL3
  const GLVersionStr* = "GL3"

{.pragma: nvg,
  header:"nanovg.h",
  cdecl,
  importc,
.}

{.pragma: glf,
  importc:"gl_$1",
  cdecl,
  header:"nanovg_gl.h"
.}

{.pragma: glf2,
  importc,
  header:"nanovg_gl.h",
  cdecl
.}

{.pragma: nvgType,
  header:"nanovg.h",
  importc
.}

import os
const ThisPath* = currentSourcePath.splitPath.head

when defined(macosx):
  {.passC: "-include\"OpenGL/gl3.h\" ".}
  {.passC: "-include\"nanovg.h\" ".}
  {.passC: "-I/usr/local/include".}
  {.passL: "-framework Cocoa -framework OpenGL -framework IOKit -framework CoreVideo ".}
else:
  {.passC: " -include\"GL/gl.h\" -include\"nanovg.h\" ".}
  {.passL: "-lGL".}

{.passC: "-DNANOVG_" & GLVersionStr & "_IMPLEMENTATION".}
{.passC: "-I"&ThisPath&"/nanovg/src -I"&ThisPath&"/nanovg/example ".}
{.compile: ThisPath/"nanovg/src/nanovg.c"}


type
  Context* {.nvgType, importc: "NVGcontext".} = object
  ContextPtr* = ptr Context

  Color* {.nvgType, byCopy, importc: "NVGcolor".} = object
    r*: cfloat
    g*: cfloat
    b*: cfloat
    a*: cfloat

  Paint* {.nvgType, byCopy.} = object
    xform*: array[6, cfloat]
    extent*: array[2, cfloat]
    radius*: cfloat
    feather*: cfloat
    innerColor*: Color
    outerColor*: Color
    image*: cint

  Winding* = distinct cint
const
  CCW* = 1.Winding     # Winding for solid shapes
  CW* = 2.Winding      # Winding for holes

type
  Solidity* = enum
    SOLID = 1,            # CCW
    HOLE = 2              # CW


type
  LineCap* = enum
    BUTT, ROUND, SQUARE, BEVEL, MITER


type
  Align* = enum            # Horizontal align
    ALIGN_LEFT = 1 shl 0, # Default, align text horizontally to left.
    ALIGN_CENTER = 1 shl 1, # Align text horizontally to center.
    ALIGN_RIGHT = 1 shl 2, # Align text horizontally to right.
                               # Vertical align
    ALIGN_TOP = 1 shl 3,  # Align text vertically to top.
    ALIGN_MIDDLE = 1 shl 4, # Align text vertically to middle.
    ALIGN_BOTTOM = 1 shl 5, # Align text vertically to bottom.
    ALIGN_BASELINE = 1 shl 6 # Default, align text vertically to baseline.


type
  GlyphPosition* = object
    str*: cstring             # Position of the glyph in the input string.
    x*: cfloat                # The x-coordinate of the logical glyph position.
    minx*: cfloat
    maxx*: cfloat             # The bounds of the glyph shape.

  TextRow* = object
    start*: cstring           # Pointer to the input text where the row starts.
    `end`*: cstring           # Pointer to the input text where the row ends (one past the last character).
    next*: cstring            # Pointer to the beginning of the next row.
    width*: cfloat            # Logical width of the row.
    minx*: cfloat
    maxx*: cfloat             # Actual bounds of the row. Logical with and bounds can differ because of kerning and some parts over extending.

  ImageFlags* = enum
    IMAGE_GENERATE_MIPMAPS = 1 shl 0, # Generate mipmaps during creation of the image.
    IMAGE_REPEATX = 1 shl 1, # Repeat image in X direction.
    IMAGE_REPEATY = 1 shl 2, # Repeat image in Y direction.
    IMAGE_FLIPY = 1 shl 3, # Flips (inverses) image in Y direction when rendered.
    IMAGE_PREMULTIPLIED = 1 shl 4 # Image data has premultiplied alpha.


# Begin drawing a new frame
# Calls to nanovg drawing API should be wrapped in nvgBeginFrame() & nvgEndFrame()
# nvgBeginFrame() defines the size of the window to render to in relation currently
# set viewport (i.e. glViewport on GL backends). Device pixel ration allows to
# control the rendering on Hi-DPI devices.
# For example, GLFW returns two dimension for an opened window: window size and
# frame buffer size. In that case you would set windowWidth/Height to the window size
# devicePixelRatio to: frameBufferWidth / windowWidth.

proc beginFrame*(ctx: ContextPtr; windowWidth: cint; windowHeight: cint; devicePixelRatio: cfloat) {.nvg, importc:"nvgBeginFrame".}
# Cancels drawing the current frame.

proc cancelFrame*(ctx: ContextPtr) {.nvg, importc:"nvgCancelFrame".}
# Ends drawing flushing remaining render state.

proc endFrame*(ctx: ContextPtr) {.nvg, importc:"nvgEndFrame".}
#
# Color utils
#
# Colors in NanoVG are stored as unsigned ints in ABGR format.
# Returns a color value from red, green, blue values. Alpha will be set to 255 (1.0f).

proc RGB*(r: cuchar; g: cuchar; b: cuchar): Color {.nvg, importc:"nvgRGB".}
# Returns a color value from red, green, blue values. Alpha will be set to 1.0f.

proc RGBf*(r: cfloat; g: cfloat; b: cfloat): Color {.nvg, importc:"nvgRGBf".}
# Returns a color value from red, green, blue and alpha values.

proc RGBA*(r,g,b,a: uint8): Color {.nvg, importc:"nvgRGBA".}
# Returns a color value from red, green, blue and alpha values.

proc RGBAf*(r: cfloat; g: cfloat; b: cfloat; a: cfloat): Color {.nvg, importc:"nvgRGBAf".}
# Linearly interpolates from color c0 to c1, and returns resulting color value.

proc lerpRGBA*(c0: Color; c1: Color; u: cfloat): Color {.nvg, importc:"nvgLerpRGBA".}
# Sets transparency of a color value.

proc transRGBA*(c0: Color; a: cuchar): Color {.nvg, importc:"nvgTransRGBA".}
# Sets transparency of a color value.

proc transRGBAf*(c0: Color; a: cfloat): Color {.nvg, importc:"nvgTransRGBAf".}
# Returns color value specified by hue, saturation and lightness.
# HSL values are all in range [0..1], alpha will be set to 255.

proc HSL*(h: cfloat; s: cfloat; l: cfloat): Color {.nvg, importc:"nvgHSL".}
# Returns color value specified by hue, saturation and lightness and alpha.
# HSL values are all in range [0..1], alpha in range [0..255]

proc HSLA*(h: cfloat; s: cfloat; l: cfloat; a: cuchar): Color {.nvg, importc:"nvgHSLA".}
#
# State Handling
#
# NanoVG contains state which represents how paths will be rendered.
# The state contains transform, fill and stroke styles, text and font styles,
# and scissor clipping.
# Pushes and saves the current render state into a state stack.
# A matching nvgRestore() must be used to restore the state.

proc save*(ctx: ContextPtr) {.nvg, importc:"nvgSave".}
# Pops and restores current render state.

proc restore*(ctx: ContextPtr) {.nvg, importc:"nvgRestore".}
# Resets current render state to default values. Does not affect the render state stack.

proc reset*(ctx: ContextPtr) {.nvg, importc:"nvgReset".}
#
# Render styles
#
# Fill and stroke render style can be either a solid color or a paint which is a gradient or a pattern.
# Solid color is simply defined as a color value, different kinds of paints can be created
# using nvgLinearGradient(), nvgBoxGradient(), nvgRadialGradient() and nvgImagePattern().
#
# Current render style can be saved and restored using nvgSave() and nvgRestore().
# Sets current stroke style to a solid color.

proc strokeColor*(ctx: ContextPtr; color: Color) {.nvg, importc:"nvgStrokeColor".}
# Sets current stroke style to a paint, which can be a one of the gradients or a pattern.

proc strokePaint*(ctx: ContextPtr; paint: Paint) {.nvg, importc:"nvgStrokePaint".}
# Sets current fill style to a solid color.

proc fillColor*(ctx: ContextPtr; color: Color) {.nvg, importc:"nvgFillColor".}
# Sets current fill style to a paint, which can be a one of the gradients or a pattern.

proc fillPaint*(ctx: ContextPtr; paint: Paint) {.nvg, importc:"nvgFillPaint".}
# Sets the miter limit of the stroke style.
# Miter limit controls when a sharp corner is beveled.

proc miterLimit*(ctx: ContextPtr; limit: cfloat) {.nvg, importc:"nvgMiterLimit".}
# Sets the stroke width of the stroke style.

proc strokeWidth*(ctx: ContextPtr; size: cfloat) {.nvg, importc:"nvgStrokeWidth".}
# Sets how the end of the line (cap) is drawn,
# Can be one of: BUTT (default), ROUND, SQUARE.

proc lineCap*(ctx: ContextPtr; cap: cint) {.nvg, importc:"nvgLineCap".}
# Sets how sharp path corners are drawn.
# Can be one of MITER (default), ROUND, BEVEL.

proc lineJoin*(ctx: ContextPtr; join: cint) {.nvg, importc:"nvgLineJoin".}
# Sets the transparency applied to all rendered shapes.
# Already transparent paths will get proportionally more transparent as well.

proc globalAlpha*(ctx: ContextPtr; alpha: cfloat) {.nvg, importc:"nvgGlobalAlpha".}
#
# Transforms
#
# The paths, gradients, patterns and scissor region are transformed by an transformation
# matrix at the time when they are passed to the API.
# The current transformation matrix is a affine matrix:
#   [sx kx tx]
#   [ky sy ty]
#   [ 0  0  1]
# Where: sx,sy define scaling, kx,ky skewing, and tx,ty translation.
# The last row is assumed to be 0,0,1 and is not stored.
#
# Apart from nvgResetTransform(), each transformation function first creates
# specific transformation matrix and pre-multiplies the current transformation by it.
#
# Current coordinate system (transformation) can be saved and restored using nvgSave() and nvgRestore().
# Resets current transform to a identity matrix.

proc resetTransform*(ctx: ContextPtr) {.nvg, importc:"nvgResetTransform".}
# Premultiplies current coordinate system by specified matrix.
# The parameters are interpreted as matrix as follows:
#   [a c e]
#   [b d f]
#   [0 0 1]

proc transform*(ctx: ContextPtr; a: cfloat; b: cfloat; c: cfloat; d: cfloat; e: cfloat; f: cfloat) {.nvg, importc:"nvgTransform".}
# Translates current coordinate system.

proc translate*(ctx: ContextPtr; x: cfloat; y: cfloat) {.nvg, importc:"nvgTranslate".}
# Rotates current coordinate system. Angle is specified in radians.

proc rotate*(ctx: ContextPtr; angle: cfloat) {.nvg, importc:"nvgRotate".}
# Skews the current coordinate system along X axis. Angle is specified in radians.

proc skewX*(ctx: ContextPtr; angle: cfloat) {.nvg, importc:"nvgSkewX".}
# Skews the current coordinate system along Y axis. Angle is specified in radians.

proc skewY*(ctx: ContextPtr; angle: cfloat) {.nvg, importc:"nvgSkewY".}
# Scales the current coordinate system.

proc scale*(ctx: ContextPtr; x: cfloat; y: cfloat) {.nvg, importc:"nvgScale".}
# Stores the top part (a-f) of the current transformation matrix in to the specified buffer.
#   [a c e]
#   [b d f]
#   [0 0 1]
# There should be space for 6 floats in the return buffer for the values a-f.

proc currentTransform*(ctx: ContextPtr; xform: ptr cfloat) {.nvg, importc:"nvgCurrentTransform".}
# The following functions can be used to make calculations on 2x3 transformation matrices.
# A 2x3 matrix is represented as float[6].
# Sets the transform to identity matrix.

proc transformIdentity*(dst: ptr cfloat) {.nvg, importc:"nvgTransformIdentity".}
# Sets the transform to translation matrix matrix.

proc transformTranslate*(dst: ptr cfloat; tx: cfloat; ty: cfloat) {.nvg, importc:"nvgTransformTranslate".}
# Sets the transform to scale matrix.

proc transformScale*(dst: ptr cfloat; sx: cfloat; sy: cfloat) {.nvg, importc:"nvgTransformScale".}
# Sets the transform to rotate matrix. Angle is specified in radians.

proc transformRotate*(dst: ptr cfloat; a: cfloat) {.nvg, importc:"nvgTransformRotate".}
# Sets the transform to skew-x matrix. Angle is specified in radians.

proc transformSkewX*(dst: ptr cfloat; a: cfloat) {.nvg, importc:"nvgTransformSkewX".}
# Sets the transform to skew-y matrix. Angle is specified in radians.

proc transformSkewY*(dst: ptr cfloat; a: cfloat) {.nvg, importc:"nvgTransformSkewY".}
# Sets the transform to the result of multiplication of two transforms, of A = A*B.

proc transformMultiply*(dst: ptr cfloat; src: ptr cfloat) {.nvg, importc:"nvgTransformMultiply".}
# Sets the transform to the result of multiplication of two transforms, of A = B*A.

proc transformPremultiply*(dst: ptr cfloat; src: ptr cfloat) {.nvg, importc:"nvgTransformPremultiply".}
# Sets the destination to inverse of specified transform.
# Returns 1 if the inverse could be calculated, else 0.

proc transformInverse*(dst: ptr cfloat; src: ptr cfloat): cint {.nvg, importc:"nvgTransformInverse".}
# Transform a point by given transform.

proc transformPoint*(dstx: ptr cfloat; dsty: ptr cfloat; xform: ptr cfloat; srcx: cfloat; srcy: cfloat) {.nvg, importc:"nvgTransformPoint".}
# Converts degrees to radians and vice versa.

proc degToRad*(deg: cfloat): cfloat {.nvg, importc:"nvgDegToRad".}
proc radToDeg*(rad: cfloat): cfloat {.nvg, importc:"nvgRadToDeg".}
#
# Images
#
# NanoVG allows you to load jpg, png, psd, tga, pic and gif files to be used for rendering.
# In addition you can upload your own image. The image loading is provided by stb_image.
# The parameter imageFlags is combination of flags defined in NVGimageFlags.
# Creates image by loading it from the disk from specified file name.
# Returns handle to the image.

proc createImage*(ctx: ContextPtr; filename: cstring; imageFlags: cint): cint {.nvg, importc:"nvgCreateImage".}
# Creates image by loading it from the specified chunk of memory.
# Returns handle to the image.

proc createImageMem*(ctx: ContextPtr; imageFlags: cint; data: ptr cuchar; ndata: cint): cint {.nvg, importc:"nvgCreateImageMem".}
# Creates image from specified image data.
# Returns handle to the image.

proc createImageRGBA*(ctx: ContextPtr; w: cint; h: cint; imageFlags: cint; data: ptr cuchar): cint {.nvg, importc:"nvgCreateImageRGBA".}
# Updates image data specified by image handle.

proc updateImage*(ctx: ContextPtr; image: cint; data: ptr cuchar) {.nvg, importc:"nvgUpdateImage".}
# Returns the dimensions of a created image.

proc imageSize*(ctx: ContextPtr; image: cint; w: ptr cint; h: ptr cint) {.nvg, importc:"nvgImageSize".}
# Deletes created image.

proc deleteImage*(ctx: ContextPtr; image: cint) {.nvg, importc:"nvgDeleteImage".}
#
# Paints
#
# NanoVG supports four types of paints: linear gradient, box gradient, radial gradient and image pattern.
# These can be used as paints for strokes and fills.
# Creates and returns a linear gradient. Parameters (sx,sy)-(ex,ey) specify the start and end coordinates
# of the linear gradient, icol specifies the start color and ocol the end color.
# The gradient is transformed by the current transform when it is passed to nvgFillPaint() or nvgStrokePaint().

proc linearGradient*(ctx: ContextPtr; sx: cfloat; sy: cfloat; ex: cfloat; ey: cfloat; icol: Color; ocol: Color): Paint {.nvg, importc:"nvgLinearGradient".}
# Creates and returns a box gradient. Box gradient is a feathered rounded rectangle, it is useful for rendering
# drop shadows or highlights for boxes. Parameters (x,y) define the top-left corner of the rectangle,
# (w,h) define the size of the rectangle, r defines the corner radius, and f feather. Feather defines how blurry
# the border of the rectangle is. Parameter icol specifies the inner color and ocol the outer color of the gradient.
# The gradient is transformed by the current transform when it is passed to nvgFillPaint() or nvgStrokePaint().

proc boxGradient*(ctx: ContextPtr; x: cfloat; y: cfloat; w: cfloat; h: cfloat; r: cfloat; f: cfloat; icol: Color; ocol: Color): Paint {.nvg, importc:"nvgBoxGradient".}
# Creates and returns a radial gradient. Parameters (cx,cy) specify the center, inr and outr specify
# the inner and outer radius of the gradient, icol specifies the start color and ocol the end color.
# The gradient is transformed by the current transform when it is passed to nvgFillPaint() or nvgStrokePaint().

proc radialGradient*(ctx: ContextPtr; cx: cfloat; cy: cfloat; inr: cfloat; outr: cfloat; icol: Color; ocol: Color): Paint {.nvg, importc:"nvgRadialGradient".}
# Creates and returns an image patter. Parameters (ox,oy) specify the left-top location of the image pattern,
# (ex,ey) the size of one image, angle rotation around the top-left corner, image is handle to the image to render.
# The gradient is transformed by the current transform when it is passed to nvgFillPaint() or nvgStrokePaint().

proc imagePattern*(ctx: ContextPtr; ox: cfloat; oy: cfloat; ex: cfloat; ey: cfloat; angle: cfloat; image: cint; alpha: cfloat): Paint {.nvg, importc:"nvgImagePattern".}
#
# Scissoring
#
# Scissoring allows you to clip the rendering into a rectangle. This is useful for various
# user interface cases like rendering a text edit or a timeline.
# Sets the current scissor rectangle.
# The scissor rectangle is transformed by the current transform.

proc scissor*(ctx: ContextPtr; x: cfloat; y: cfloat; w: cfloat; h: cfloat) {.nvg, importc:"nvgScissor".}
# Intersects current scissor rectangle with the specified rectangle.
# The scissor rectangle is transformed by the current transform.
# Note: in case the rotation of previous scissor rect differs from
# the current one, the intersection will be done between the specified
# rectangle and the previous scissor rectangle transformed in the current
# transform space. The resulting shape is always rectangle.

proc intersectScissor*(ctx: ContextPtr; x: cfloat; y: cfloat; w: cfloat; h: cfloat) {.nvg, importc:"nvgIntersectScissor".}
# Reset and disables scissoring.

proc resetScissor*(ctx: ContextPtr) {.nvg, importc:"nvgResetScissor".}
#
# Paths
#
# Drawing a new shape starts with nvgBeginPath(), it clears all the currently defined paths.
# Then you define one or more paths and sub-paths which describe the shape. The are functions
# to draw common shapes like rectangles and circles, and lower level step-by-step functions,
# which allow to define a path curve by curve.
#
# NanoVG uses even-odd fill rule to draw the shapes. Solid shapes should have counter clockwise
# winding and holes should have counter clockwise order. To specify winding of a path you can
# call nvgPathWinding(). This is useful especially for the common shapes, which are drawn CCW.
#
# Finally you can fill the path using current fill style by calling nvgFill(), and stroke it
# with current stroke style by calling nvgStroke().
#
# The curve segments and sub-paths are transformed by the current transform.
# Clears the current path and sub-paths.

proc beginPath*(ctx: ContextPtr) {.nvg, importc:"nvgBeginPath".}
# Starts new sub-path with specified point as first point.

proc moveTo*(ctx: ContextPtr; x: cfloat; y: cfloat) {.nvg, importc:"nvgMoveTo".}
# Adds line segment from the last point in the path to the specified point.

proc lineTo*(ctx: ContextPtr; x: cfloat; y: cfloat) {.nvg, importc:"nvgLineTo".}
# Adds cubic bezier segment from last point in the path via two control points to the specified point.

proc bezierTo*(ctx: ContextPtr; c1x: cfloat; c1y: cfloat; c2x: cfloat; c2y: cfloat; x: cfloat; y: cfloat) {.nvg, importc:"nvgBezierTo".}
# Adds quadratic bezier segment from last point in the path via a control point to the specified point.

proc quadTo*(ctx: ContextPtr; cx: cfloat; cy: cfloat; x: cfloat; y: cfloat) {.nvg, importc:"nvgQuadTo".}
# Adds an arc segment at the corner defined by the last path point, and two specified points.

proc arcTo*(ctx: ContextPtr; x1: cfloat; y1: cfloat; x2: cfloat; y2: cfloat; radius: cfloat) {.nvg, importc:"nvgArcTo".}
# Closes current sub-path with a line segment.

proc closePath*(ctx: ContextPtr) {.nvg, importc:"nvgClosePath".}
# Sets the current sub-path winding, see Winding and NVGsolidity.

proc pathWinding*(ctx: ContextPtr; dir: cint) {.nvg, importc:"nvgPathWinding".}
proc pathWinding*(ctx: ContextPtr; dir: Solidity) = ctx.pathWinding(cint dir)
# Creates new circle arc shaped sub-path. The arc center is at cx,cy, the arc radius is r,
# and the arc is drawn from angle a0 to a1, and swept in direction dir (CCW, or CW).
# Angles are specified in radians.


proc arc*(ctx: ContextPtr; cx: cfloat; cy: cfloat; r: cfloat; a0: cfloat; a1: cfloat; dir: Winding = CW) {.nvg, importc:"nvgArc".}
# Creates new rectangle shaped sub-path.

proc rect*(ctx: ContextPtr; x: cfloat; y: cfloat; w: cfloat; h: cfloat) {.nvg, importc:"nvgRect".}
# Creates new rounded rectangle shaped sub-path.

proc roundedRect*(ctx: ContextPtr; x: cfloat; y: cfloat; w: cfloat; h: cfloat; r: cfloat) {.nvg, importc:"nvgRoundedRect".}
# Creates new ellipse shaped sub-path.

proc ellipse*(ctx: ContextPtr; cx: cfloat; cy: cfloat; rx: cfloat; ry: cfloat) {.nvg, importc:"nvgEllipse".}
# Creates new circle shaped sub-path.

proc circle*(ctx: ContextPtr; cx: cfloat; cy: cfloat; r: cfloat) {.nvg, importc:"nvgCircle".}
# Fills the current path with current fill style.

proc fill*(ctx: ContextPtr) {.nvg, importc:"nvgFill".}
# Fills the current path with current stroke style.

proc stroke*(ctx: ContextPtr) {.nvg, importc:"nvgStroke".}
#
# Text
#
# NanoVG allows you to load .ttf files and use the font to render text.
#
# The appearance of the text can be defined by setting the current text style
# and by specifying the fill color. Common text and font settings such as
# font size, letter spacing and text align are supported. Font blur allows you
# to create simple text effects such as drop shadows.
#
# At render time the font face can be set based on the font handles or name.
#
# Font measure functions return values in local space, the calculations are
# carried in the same resolution as the final rendering. This is done because
# the text glyph positions are snapped to the nearest pixels sharp rendering.
#
# The local space means that values are not rotated or scale as per the current
# transformation. For example if you set font size to 12, which would mean that
# line height is 16, then regardless of the current scaling and rotation, the
# returned line height is always 16. Some measures may vary because of the scaling
# since aforementioned pixel snapping.
#
# While this may sound a little odd, the setup allows you to always render the
# same way regardless of scaling. I.e. following works regardless of scaling:
#
#		const char* txt = "Text me up.";
#		nvgTextBounds(vg, x,y, txt, NULL, bounds);
#		nvgBeginPath(vg);
#		nvgRoundedRect(vg, bounds[0],bounds[1], bounds[2]-bounds[0], bounds[3]-bounds[1]);
#		nvgFill(vg);
#
# Note: currently only solid color fill is supported for text.
# Creates font by loading it from the disk from specified file name.
# Returns handle to the font.

proc createFont*(ctx: ContextPtr; name: cstring; filename: cstring): cint {.nvg, importc:"nvgCreateFont".}
# Creates image by loading it from the specified memory chunk.
# Returns handle to the font.

proc createFontMem*(ctx: ContextPtr; name: cstring; data: ptr cuchar; ndata: cint; freeData: cint): cint {.nvg, importc:"nvgCreateFontMem".}
# Finds a loaded font of specified name, and returns handle to it, or -1 if the font is not found.

proc findFont*(ctx: ContextPtr; name: cstring): cint {.nvg, importc:"nvgFindFont".}
# Sets the font size of current text style.

proc fontSize*(ctx: ContextPtr; size: cfloat) {.nvg, importc:"nvgFontSize".}
# Sets the blur of current text style.

proc fontBlur*(ctx: ContextPtr; blur: cfloat) {.nvg, importc:"nvgFontBlur".}
# Sets the letter spacing of current text style.

proc textLetterSpacing*(ctx: ContextPtr; spacing: cfloat) {.nvg, importc:"nvgTextLetterSpacing".}
# Sets the proportional line height of current text style. The line height is specified as multiple of font size.

proc textLineHeight*(ctx: ContextPtr; lineHeight: cfloat) {.nvg, importc:"nvgTextLineHeight".}
# Sets the text align of current text style, see NVGalign for options.

proc textAlign*(ctx: ContextPtr; align: cint) {.nvg, importc:"nvgTextAlign".}
# Sets the font face based on specified id of current text style.

proc fontFaceId*(ctx: ContextPtr; font: cint) {.nvg, importc:"nvgFontFaceId".}
# Sets the font face based on specified name of current text style.

proc fontFace*(ctx: ContextPtr; font: cstring) {.nvg, importc:"nvgFontFace".}
# Draws text string at specified location. If end is specified only the sub-string up to the end is drawn.

proc addFallbackFont*(ctx: ContextPtr; baseFont: cstring; fallbackFont: cstring) {.nvg, importc:"nvgAddFallbackFont".}
# Adds a fallback font by name.

proc addFallbackFontId*(ctx: ContextPtr; baseFont: cint; fallbackFont: cint) {.nvg, importc:"nvgAddFallbackFontId".}
# Adds a fallback font by handle.

proc text*(ctx: ContextPtr; x: cfloat; y: cfloat; string: cstring; `end`: cstring = nil): cfloat {.nvg, importc:"nvgText".}
# Draws multi-line text string at specified location wrapped at the specified width. If end is specified only the sub-string up to the end is drawn.
# White space is stripped at the beginning of the rows, the text is split at word boundaries or when new-line characters are encountered.
# Words longer than the max width are slit at nearest character (i.e. no hyphenation).

proc textBox*(ctx: ContextPtr; x: cfloat; y: cfloat; breakRowWidth: cfloat; string: cstring; `end`: cstring = nil) {.nvg, importc:"nvgTextBox".}
# Measures the specified text string. Parameter bounds should be a pointer to float[4],
# if the bounding box of the text should be returned. The bounds value are [xmin,ymin, xmax,ymax]
# Returns the horizontal advance of the measured text (i.e. where the next character should drawn).
# Measured values are returned in local coordinate space.

proc textBounds*(ctx: ContextPtr; x: cfloat; y: cfloat; string: cstring; `end`: cstring; bounds: ptr cfloat): cfloat {.nvg, importc:"nvgTextBounds".}
# Measures the specified multi-text string. Parameter bounds should be a pointer to float[4],
# if the bounding box of the text should be returned. The bounds value are [xmin,ymin, xmax,ymax]
# Measured values are returned in local coordinate space.

proc textBoxBounds*(ctx: ContextPtr; x: cfloat; y: cfloat; breakRowWidth: cfloat; string: cstring; `end`: cstring; bounds: ptr cfloat) {.nvg, importc:"nvgTextBoxBounds".}
# Calculates the glyph x positions of the specified text. If end is specified only the sub-string will be used.
# Measured values are returned in local coordinate space.

proc textGlyphPositions*(ctx: ContextPtr; x: cfloat; y: cfloat; string: cstring; `end`: cstring = nil; positions: ptr GlyphPosition; maxPositions: cint): cint {.nvg, importc:"nvgTextGlyphPositions".}
# Returns the vertical metrics based on the current text style.
# Measured values are returned in local coordinate space.

proc textMetrics*(ctx: ContextPtr; ascender: ptr cfloat; descender: ptr cfloat; lineh: ptr cfloat) {.nvg, importc:"nvgTextMetrics".}
# Breaks the specified text into lines. If end is specified only the sub-string will be used.
# White space is stripped at the beginning of the rows, the text is split at word boundaries or when new-line characters are encountered.
# Words longer than the max width are slit at nearest character (i.e. no hyphenation).

proc textBreakLines*(ctx: ContextPtr; string: cstring; `end`: cstring; breakRowWidth: cfloat; rows: ptr TextRow; maxRows: cint): cint {.nvg, importc:"nvgTextBreakLines".}


#
# Internal Render API
#

type
  NVGtexture* = enum
    TEXTURE_ALPHA = 0x00000001, TEXTURE_RGBA = 0x00000002


type
  NVGscissor* = object
    xform*: array[6, cfloat]
    extent*: array[2, cfloat]

  NVGvertex* = object
    x*: cfloat
    y*: cfloat
    u*: cfloat
    v*: cfloat

  NVGpath* = object
    first*: cint
    count*: cint
    closed*: cuchar
    nbevel*: cint
    fill*: ptr NVGvertex
    nfill*: cint
    stroke*: ptr NVGvertex
    nstroke*: cint
    winding*: cint
    convex*: cint

  NVGparams* = object
    userPtr*: pointer
    edgeAntiAlias*: cint
    renderCreate*: proc (uptr: pointer): cint
    renderCreateTexture*: proc (uptr: pointer; `type`: cint; w: cint; h: cint;
                                imageFlags: cint; data: ptr cuchar): cint
    renderDeleteTexture*: proc (uptr: pointer; image: cint): cint
    renderUpdateTexture*: proc (uptr: pointer; image: cint; x: cint; y: cint;
                                w: cint; h: cint; data: ptr cuchar): cint
    renderGetTextureSize*: proc (uptr: pointer; image: cint; w: ptr cint;
                                 h: ptr cint): cint
    renderViewport*: proc (uptr: pointer; width: cint; height: cint)
    renderCancel*: proc (uptr: pointer)
    renderFlush*: proc (uptr: pointer)
    renderFill*: proc (uptr: pointer; paint: ptr Paint;
                       scissor: ptr NVGscissor; fringe: cfloat;
                       bounds: ptr cfloat; paths: ptr NVGpath; npaths: cint)
    renderStroke*: proc (uptr: pointer; paint: ptr Paint;
                         scissor: ptr NVGscissor; fringe: cfloat;
                         strokeWidth: cfloat; paths: ptr NVGpath; npaths: cint)
    renderTriangles*: proc (uptr: pointer; paint: ptr Paint;
                            scissor: ptr NVGscissor; verts: ptr NVGvertex;
                            nverts: cint)
    renderDelete*: proc (uptr: pointer)


# Constructor and destructor, called by the render back-end.

proc createInternal*(params: ptr NVGparams): ContextPtr {.nvg, importc:"nvgCreateInternal".}
proc deleteInternal*(ctx: ContextPtr) {.nvg, importc:"nvgDeleteInternal".}
proc internalParams*(ctx: ContextPtr): ptr NVGparams {.nvg, importc:"nvgInternalParams".}
# Debug function to dump cached path data.

proc debugDumpPathCache*(ctx: ContextPtr) {.nvg, importc:"nvgDebugDumpPathCache".}
# when defined(_MSC_VER):
# template NOTUSED*(v: expr): stmt =
#   while true:
#     (void)(if 1: cast[nil](0) else: ((void)(v)))
#     break


type
  NVGcreateFlags* {.size:sizeof(cint).} = enum      # Flag indicating if geometry based anti-aliasing is used (may not be needed when using MSAA).
    ANTIALIAS = 1 shl 0, # Flag indicating if strokes should be drawn using stencil buffer. The rendering will be a little
                             # slower, but path overlaps (i.e. self-intersecting or sharp turns) will be drawn just once.
    STENCIL_STROKES = 1 shl 1, # Flag indicating that additional debug checks are done.
    DEBUG = 1 shl 2
converter toCint* (some:NVGcreateFlags): cint = cint(some)

const
  NANOVG_GL_USE_STATE_FILTER* = (1)

# Creates NanoVG contexts for different OpenGL (ES) versions.
# Flags should be combination of the create flags above.

when defined(nvgGL2):
  proc createGL2*(flags: cint): ContextPtr {.glf2, importc:"nvgCreateGL2".}
  proc deleteGL2*(ctx: ContextPtr) {.glf2, importc:"nvgDeleteGL2".}
elif defined(nvgGL3):
  proc createGL3*(flags: cint): ContextPtr {.glf2, importc:"nvgCreateGL3".}
  proc deleteGL3*(ctx: ContextPtr) {.glf2, importc:"nvgDeleteGL3".}
elif defined(NANOVG_GLES2):
  proc createGLES2*(flags: cint): ContextPtr {.glf2, importc:"nvgCreateGLES2".}
  proc deleteGLES2*(ctx: ContextPtr) {.glf2, importc:"nvgDeleteGLES2".}
elif defined(NANOVG_GLES3):
  proc createGLES3*(flags: cint): ContextPtr {.glf2, importc:"nvgCreateGLES3".}
  proc deleteGLES3*(ctx: ContextPtr) {.glf2, importc:"nvgDeleteGLES3".}
else:
  proc CreateGL3*(flags: cint): ContextPtr {.glf2, importc:"nvgCreateGL3".}
  proc DeleteGL3*(ctx: ContextPtr) {.glf2, importc:"nvgDeleteGL3".}

# These are additional flags on top of NVGimageFlags.

type
  NVGimageFlagsGL* = enum
    IMAGE_NODELETE = 1 shl 16 # Do not delete GL texture handle.


proc lCreateImageFromHandle*(ctx: ContextPtr; textureId: GLuint; w: cint; h: cint; flags: cint): cint {.glf2, importc:"nvgLCreateImageFromHandle".}
proc lImageHandle*(ctx: ContextPtr; image: cint): GLuint {.glf2, importc:"nvgLImageHandle".}










