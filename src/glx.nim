#
#
#  Translation of the Mesa GLX headers for FreePascal
#  Copyright (C) 1999 Sebastian Guenther
#
#
#  Mesa 3-D graphics library
#  Version:  3.0
#  Copyright (C) 1995-1998  Brian Paul
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Library General Public
#  License as published by the Free Software Foundation; either
#  version 2 of the License, or (at your option) any later version.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  Library General Public License for more details.
#
#  You should have received a copy of the GNU Library General Public
#  License along with this library; if not, write to the Free
#  Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#

import X, XLib, XUtil, opengl

{.deadCodeElim: on.}

when defined(windows):
  const
    dllname = "GL.dll"
elif defined(macosx):
  const
    dllname = "/usr/X11R6/lib/libGL.dylib"
else:
  const
    dllname = "libGL.so"
const
  USE_GL* = 1'i32
  BUFFER_SIZE* = 2'i32
  LEVEL* = 3'i32
  RGBA* = 4'i32
  DOUBLEBUFFER* = 5'i32
  STEREO* = 6'i32
  AUX_BUFFERS* = 7'i32
  RED_SIZE* = 8'i32
  GREEN_SIZE* = 9'i32
  BLUE_SIZE* = 10'i32
  ALPHA_SIZE* = 11'i32
  DEPTH_SIZE* = 12'i32
  STENCIL_SIZE* = 13'i32
  ACCUM_RED_SIZE* = 14'i32
  ACCUM_GREEN_SIZE* = 15'i32
  ACCUM_BLUE_SIZE* = 16'i32
  ACCUM_ALPHA_SIZE* = 17'i32  # EXT_visual_info extension
  X_VISUAL_TYPE_EXT* = 0x00000022
  TRANSPARENT_TYPE_EXT* = 0x00000023
  TRANSPARENT_INDEX_VALUE_EXT* = 0x00000024
  TRANSPARENT_RED_VALUE_EXT* = 0x00000025
  TRANSPARENT_GREEN_VALUE_EXT* = 0x00000026
  TRANSPARENT_BLUE_VALUE_EXT* = 0x00000027
  TRANSPARENT_ALPHA_VALUE_EXT* = 0x00000028 # Error codes returned by glXGetConfig:
  BAD_SCREEN* = 1
  BAD_ATTRIBUTE* = 2
  NO_EXTENSION* = 3
  BAD_VISUAL* = 4
  BAD_CONTEXT* = 5
  BAD_VALUE* = 6
  BAD_ENUM* = 7           # GLX 1.1 and later:
  VENDOR* = 1
  VERSION* = 2
  EXTENSIONS* = 3         # visual_info extension
  TRUE_COLOR_EXT* = 0x00008002
  DIRECT_COLOR_EXT* = 0x00008003
  PSEUDO_COLOR_EXT* = 0x00008004
  STATIC_COLOR_EXT* = 0x00008005
  GRAY_SCALE_EXT* = 0x00008006
  STATIC_GRAY_EXT* = 0x00008007
  NONE_EXT* = 0x00008000
  TRANSPARENT_RGB_EXT* = 0x00008008
  TRANSPARENT_INDEX_EXT* = 0x00008009

type                          # From XLib:
  XPixmap* = TXID
  XFont* = TXID
  XColormap* = TXID
  GLXContext* = pointer
  GLXPixmap* = TXID
  GLXDrawable* = TXID
  GLXContextID* = TXID
  TXPixmap* = XPixmap
  TXFont* = XFont
  TXColormap* = XColormap
  TGLXContext* = GLXContext
  TGLXPixmap* = GLXPixmap
  TGLXDrawable* = GLXDrawable
  TGLXContextID* = GLXContextID

{.push cdecl, dynlib: dllname, importc: "glX$1".}

proc glXChooseVisual*(dpy: PDisplay, screen: int, attribList: ptr int32): PXVisualInfo
proc glXCreateContext*(dpy: PDisplay, vis: PXVisualInfo, shareList: GLXContext,
                       direct: bool): GLXContext
proc glXDestroyContext*(dpy: PDisplay, ctx: GLXContext)
proc glXMakeCurrent*(dpy: PDisplay, drawable: GLXDrawable, ctx: GLXContext): bool
proc glXCopyContext*(dpy: PDisplay, src, dst: GLXContext, mask: int32)
proc glXSwapBuffers*(dpy: PDisplay, drawable: GLXDrawable)
proc glXCreateGLXPixmap*(dpy: PDisplay, visual: PXVisualInfo, pixmap: XPixmap): GLXPixmap
proc glXDestroyGLXPixmap*(dpy: PDisplay, pixmap: GLXPixmap)
proc glXQueryExtension*(dpy: PDisplay, errorb, event: var int): bool
proc glXQueryVersion*(dpy: PDisplay, maj, min: var int): bool
proc glXIsDirect*(dpy: PDisplay, ctx: GLXContext): bool
proc glXGetConfig*(dpy: PDisplay, visual: PXVisualInfo, attrib: int,
                   value: var int): int
proc glXGetCurrentContext*(): GLXContext
proc glXGetCurrentDrawable*(): GLXDrawable
proc glXWaitGL*()
proc glXWaitX*()
proc glXUseXFont*(font: XFont, first, count, list: int)
  # GLX 1.1 and later
proc glXQueryExtensionsString*(dpy: PDisplay, screen: int): cstring
proc glXQueryServerString*(dpy: PDisplay, screen, name: int): cstring
proc glXGetClientString*(dpy: PDisplay, name: int): cstring
  # Mesa GLX Extensions
proc glXCreateGLXPixmapMESA*(dpy: PDisplay, visual: PXVisualInfo,
                             pixmap: XPixmap, cmap: XColormap): GLXPixmap
proc glXReleaseBufferMESA*(dpy: PDisplay, d: GLXDrawable): bool
proc glXCopySubBufferMESA*(dpy: PDisplay, drawbale: GLXDrawable,
                           x, y, width, height: int)
proc glXGetVideoSyncSGI*(counter: var int32): int
proc glXWaitVideoSyncSGI*(divisor, remainder: int, count: var int32): int
# implementation
{.pop.}
