#
#
#  Adaption of the delphi3d.net OpenGL units to FreePascal
#  Sebastian Guenther (sg@freepascal.org) in 2002
#  These units are free to use
#

# Copyright (c) Mark J. Kilgard, 1994, 1995, 1996.
# This program is freely distributable without licensing fees  and is
#   provided without guarantee or warrantee expressed or  implied. This
#   program is -not- in the public domain.
#******************************************************************************
# Converted to Delphi by Tom Nuydens (tom@delphi3d.net)
#   Contributions by Igor Karpov (glygrik@hotbox.ru)
#   For the latest updates, visit Delphi3D: http://www.delphi3d.net
#******************************************************************************

import opengl

{.deadCodeElim: on.}

when defined(windows):
  const
    dllname = "glut32.dll"
elif defined(macosx):
  const
    dllname = "/System/Library/Frameworks/GLUT.framework/GLUT"
else:
  const
    dllname = "libglut.so.3"
type
  VoidCallback* = proc (){.cdecl.}
  OneIntCallback* = proc (value: cint){.cdecl.}
  TwoIntCallback* = proc (v1, v2: cint){.cdecl.}
  ThreeIntCallback* = proc (v1, v2, v3: cint){.cdecl.}
  FourIntCallback* = proc (v1, v2, v3, v4: cint){.cdecl.}
  OneCharTwoIntCallback* = proc (c: int8, v1, v2: cint){.cdecl.}
  OneUIntThreeIntCallback* = proc (u, v1, v2, v3: cint){.cdecl.}

{.deprecated: [Pointer: pointer,
               TGlutVoidCallback: VoidCallback,
               TGlut1IntCallback: OneIntCallback,
               TGlut2IntCallback: TwoIntCallback,
               TGlut3IntCallback: ThreeIntCallback,
               TGlut4IntCallback: FourIntCallback,
               TGlut1Char2IntCallback: OneCharTwoIntCallback,
               TGlut1UInt3IntCallback: OneUIntThreeIntCallback
               ].}

const
  API_VERSION* = 3
  XLIB_IMPLEMENTATION* = 12 # Display mode bit masks.
  RGB* = 0
  RGBA* = RGB
  INDEX* = 1
  SINGLE* = 0
  DOUBLE* = 2
  ACCUM* = 4
  ALPHA* = 8
  DEPTH* = 16
  STENCIL* = 32
  MULTISAMPLE* = 128
  STEREO* = 256
  LUMINANCE* = 512       # Mouse buttons.
  LEFT_BUTTON* = 0
  MIDDLE_BUTTON* = 1
  RIGHT_BUTTON* = 2      # Mouse button state.
  DOWN* = 0
  UP* = 1                # function keys
  KEY_F1* = 1
  KEY_F2* = 2
  KEY_F3* = 3
  KEY_F4* = 4
  KEY_F5* = 5
  KEY_F6* = 6
  KEY_F7* = 7
  KEY_F8* = 8
  KEY_F9* = 9
  KEY_F10* = 10
  KEY_F11* = 11
  KEY_F12* = 12          # directional keys
  KEY_LEFT* = 100
  KEY_UP* = 101
  KEY_RIGHT* = 102
  KEY_DOWN* = 103
  KEY_PAGE_UP* = 104
  KEY_PAGE_DOWN* = 105
  KEY_HOME* = 106
  KEY_END* = 107
  KEY_INSERT* = 108      # Entry/exit  state.
  LEFT* = 0
  ENTERED* = 1           # Menu usage state.
  MENU_NOT_IN_USE* = 0
  MENU_IN_USE* = 1       # Visibility  state.
  NOT_VISIBLE* = 0
  VISIBLE* = 1           # Window status  state.
  HIDDEN* = 0
  FULLY_RETAINED* = 1
  PARTIALLY_RETAINED* = 2
  FULLY_COVERED* = 3     # Color index component selection values.
  RED* = 0
  GREEN* = 1
  BLUE* = 2              # Layers for use.
  NORMAL* = 0
  OVERLAY* = 1

when defined(Windows):
  const                       # Stroke font constants (use these in GLUT program).
    STROKE_ROMAN* = cast[pointer](0)
    STROKE_MONO_ROMAN* = cast[pointer](1) # Bitmap font constants (use these in GLUT program).
    BITMAP_9_BY_15* = cast[pointer](2)
    BITMAP_8_BY_13* = cast[pointer](3)
    BITMAP_TIMES_ROMAN_10* = cast[pointer](4)
    BITMAP_TIMES_ROMAN_24* = cast[pointer](5)
    BITMAP_HELVETICA_10* = cast[pointer](6)
    BITMAP_HELVETICA_12* = cast[pointer](7)
    BITMAP_HELVETICA_18* = cast[pointer](8)
else:
  var                         # Stroke font constants (use these in GLUT program).
    STROKE_ROMAN*: pointer
    STROKE_MONO_ROMAN*: pointer # Bitmap font constants (use these in GLUT program).
    BITMAP_9_BY_15*: pointer
    BITMAP_8_BY_13*: pointer
    BITMAP_TIMES_ROMAN_10*: pointer
    BITMAP_TIMES_ROMAN_24*: pointer
    BITMAP_HELVETICA_10*: pointer
    BITMAP_HELVETICA_12*: pointer
    BITMAP_HELVETICA_18*: pointer
const                         # glutGet parameters.
  WINDOW_X* = 100
  WINDOW_Y* = 101
  WINDOW_WIDTH* = 102
  WINDOW_HEIGHT* = 103
  WINDOW_BUFFER_SIZE* = 104
  WINDOW_STENCIL_SIZE* = 105
  WINDOW_DEPTH_SIZE* = 106
  WINDOW_RED_SIZE* = 107
  WINDOW_GREEN_SIZE* = 108
  WINDOW_BLUE_SIZE* = 109
  WINDOW_ALPHA_SIZE* = 110
  WINDOW_ACCUM_RED_SIZE* = 111
  WINDOW_ACCUM_GREEN_SIZE* = 112
  WINDOW_ACCUM_BLUE_SIZE* = 113
  WINDOW_ACCUM_ALPHA_SIZE* = 114
  WINDOW_DOUBLEBUFFER* = 115
  WINDOW_RGBA* = 116
  WINDOW_PARENT* = 117
  WINDOW_NUM_CHILDREN* = 118
  WINDOW_COLORMAP_SIZE* = 119
  WINDOW_NUM_SAMPLES* = 120
  WINDOW_STEREO* = 121
  WINDOW_CURSOR* = 122
  SCREEN_WIDTH* = 200
  SCREEN_HEIGHT* = 201
  SCREEN_WIDTH_MM* = 202
  SCREEN_HEIGHT_MM* = 203
  MENU_NUM_ITEMS* = 300
  DISPLAY_MODE_POSSIBLE* = 400
  INIT_WINDOW_X* = 500
  INIT_WINDOW_Y* = 501
  INIT_WINDOW_WIDTH* = 502
  INIT_WINDOW_HEIGHT* = 503
  constINIT_DISPLAY_MODE* = 504
  ELAPSED_TIME* = 700
  WINDOW_FORMAT_ID* = 123 # glutDeviceGet parameters.
  HAS_KEYBOARD* = 600
  HAS_MOUSE* = 601
  HAS_SPACEBALL* = 602
  HAS_DIAL_AND_BUTTON_BOX* = 603
  HAS_TABLET* = 604
  NUM_MOUSE_BUTTONS* = 605
  NUM_SPACEBALL_BUTTONS* = 606
  NUM_BUTTON_BOX_BUTTONS* = 607
  NUM_DIALS* = 608
  NUM_TABLET_BUTTONS* = 609
  DEVICE_IGNORE_KEY_REPEAT* = 610
  DEVICE_KEY_REPEAT* = 611
  HAS_JOYSTICK* = 612
  OWNS_JOYSTICK* = 613
  JOYSTICK_BUTTONS* = 614
  JOYSTICK_AXES* = 615
  JOYSTICK_POLL_RATE* = 616 # glutLayerGet parameters.
  OVERLAY_POSSIBLE* = 800
  LAYER_IN_USE* = 801
  HAS_OVERLAY* = 802
  TRANSPARENT_INDEX* = 803
  NORMAL_DAMAGED* = 804
  OVERLAY_DAMAGED* = 805 # glutVideoResizeGet parameters.
  VIDEO_RESIZE_POSSIBLE* = 900
  VIDEO_RESIZE_IN_USE* = 901
  VIDEO_RESIZE_X_DELTA* = 902
  VIDEO_RESIZE_Y_DELTA* = 903
  VIDEO_RESIZE_WIDTH_DELTA* = 904
  VIDEO_RESIZE_HEIGHT_DELTA* = 905
  VIDEO_RESIZE_X* = 906
  VIDEO_RESIZE_Y* = 907
  VIDEO_RESIZE_WIDTH* = 908
  VIDEO_RESIZE_HEIGHT* = 909 # glutGetModifiers return mask.
  ACTIVE_SHIFT* = 1
  ACTIVE_CTRL* = 2
  ACTIVE_ALT* = 4        # glutSetCursor parameters.
                              # Basic arrows.
  CURSOR_RIGHT_ARROW* = 0
  CURSOR_LEFT_ARROW* = 1 # Symbolic cursor shapes.
  CURSOR_INFO* = 2
  CURSOR_DESTROY* = 3
  CURSOR_HELP* = 4
  CURSOR_CYCLE* = 5
  CURSOR_SPRAY* = 6
  CURSOR_WAIT* = 7
  CURSOR_TEXT* = 8
  CURSOR_CROSSHAIR* = 9  # Directional cursors.
  CURSOR_UP_DOWN* = 10
  CURSOR_LEFT_RIGHT* = 11 # Sizing cursors.
  CURSOR_TOP_SIDE* = 12
  CURSOR_BOTTOM_SIDE* = 13
  CURSOR_LEFT_SIDE* = 14
  CURSOR_RIGHT_SIDE* = 15
  CURSOR_TOP_LEFT_CORNER* = 16
  CURSOR_TOP_RIGHT_CORNER* = 17
  CURSOR_BOTTOM_RIGHT_CORNER* = 18
  CURSOR_BOTTOM_LEFT_CORNER* = 19 # Inherit from parent window.
  CURSOR_INHERIT* = 100  # Blank cursor.
  CURSOR_NONE* = 101     # Fullscreen crosshair (if available).
  CURSOR_FULL_CROSSHAIR* = 102 # GLUT device control sub-API.
                                    # glutSetKeyRepeat modes.
  KEY_REPEAT_OFF* = 0
  KEY_REPEAT_ON* = 1
  KEY_REPEAT_DEFAULT* = 2 # Joystick button masks.
  JOYSTICK_BUTTON_A* = 1
  JOYSTICK_BUTTON_B* = 2
  JOYSTICK_BUTTON_C* = 4
  JOYSTICK_BUTTON_D* = 8 # GLUT game mode sub-API.
                              # glutGameModeGet.
  GAME_MODE_ACTIVE* = 0
  GAME_MODE_POSSIBLE* = 1
  GAME_MODE_WIDTH* = 2
  GAME_MODE_HEIGHT* = 3
  GAME_MODE_PIXEL_DEPTH* = 4
  GAME_MODE_REFRESH_RATE* = 5
  GAME_MODE_DISPLAY_CHANGED* = 6 # GLUT initialization sub-API.

{.push cdecl, dynlib: dllname, importc: "glut$1".}
proc Init*(argcp: ptr cint, argv: pointer)

proc Init*() =
  ## version that passes `argc` and `argc` implicitely.
  var
    cmdLine {.importc: "cmdLine".}: array[0..255, cstring]
    cmdCount {.importc: "cmdCount".}: cint
  glutInit(addr(cmdCount), addr(cmdLine))

proc InitDisplayMode*(mode: int16)
proc InitDisplayString*(str: cstring)
proc InitWindowPosition*(x, y: int)
proc InitWindowSize*(width, height: int)
proc MainLoop*()
  # GLUT window sub-API.
proc CreateWindow*(title: cstring): int
proc CreateSubWindow*(win, x, y, width, height: int): int
proc DestroyWindow*(win: int)
proc PostRedisplay*()
proc PostWindowRedisplay*(win: int)
proc SwapBuffers*()
proc SetWindow*(win: int)
proc SetWindowTitle*(title: cstring)
proc SetIconTitle*(title: cstring)
proc PositionWindow*(x, y: int)
proc ReshapeWindow*(width, height: int)
proc PopWindow*()
proc PushWindow*()
proc IconifyWindow*()
proc ShowWindow*()
proc HideWindow*()
proc FullScreen*()
proc SetCursor*(cursor: int)
proc Warppointer*(x, y: int)
  # GLUT overlay sub-API.
proc EstablishOverlay*()
proc RemoveOverlay*()
proc UseLayer*(layer: GLenum)
proc PostOverlayRedisplay*()
proc PostWindowOverlayRedisplay*(win: int)
proc ShowOverlay*()
proc HideOverlay*()
  # GLUT menu sub-API.
proc CreateMenu*(callback: OneIntCallback): int
proc DestroyMenu*(menu: int)
proc GetMenu*(): int
proc SetMenu*(menu: int)
proc AddMenuEntry*(caption: cstring, value: int)
proc AddSubMenu*(caption: cstring, submenu: int)
proc ChangeToMenuEntry*(item: int, caption: cstring, value: int)
proc ChangeToSubMenu*(item: int, caption: cstring, submenu: int)
proc RemoveMenuItem*(item: int)
proc AttachMenu*(button: int)
proc DetachMenu*(button: int)
  # GLUT window callback sub-API.
proc DisplayFunc*(f: VoidCallback)
proc CloseFunc*(f: VoidCallback)
proc ReshapeFunc*(f: TwoIntCallback)
proc KeyboardFunc*(f: OneCharTwoIntCallback)
proc MouseFunc*(f: FourIntCallback)
proc MotionFunc*(f: TwoIntCallback)
proc PassiveMotionFunc*(f: TwoIntCallback)
proc EntryFunc*(f: OneIntCallback)
proc VisibilityFunc*(f: OneIntCallback)
proc IdleFunc*(f: VoidCallback)
proc TimerFunc*(millis: int16, f: OneIntCallback, value: int)
proc MenuStateFunc*(f: OneIntCallback)
proc SpecialFunc*(f: ThreeIntCallback)
proc SpaceballMotionFunc*(f: ThreeIntCallback)
proc SpaceballRotateFunc*(f: ThreeIntCallback)
proc SpaceballButtonFunc*(f: TwoIntCallback)
proc ButtonBoxFunc*(f: TwoIntCallback)
proc DialsFunc*(f: TwoIntCallback)
proc TabletMotionFunc*(f: TwoIntCallback)
proc TabletButtonFunc*(f: FourIntCallback)
proc MenuStatusFunc*(f: ThreeIntCallback)
proc OverlayDisplayFunc*(f: VoidCallback)
proc WindowStatusFunc*(f: OneIntCallback)
proc KeyboardUpFunc*(f: OneCharTwoIntCallback)
proc SpecialUpFunc*(f: ThreeIntCallback)
proc JoystickFunc*(f: OneUIntThreeIntCallback, pollInterval: int)
  # GLUT color index sub-API.
proc SetColor*(cell: int, red, green, blue: GLfloat)
proc GetColor*(ndx, component: int): GLfloat
proc CopyColormap*(win: int)
  # GLUT state retrieval sub-API.
proc Get*(t: GLenum): int
proc DeviceGet*(t: GLenum): int
  # GLUT extension support sub-API
proc GetModifiers*(): int
proc LayerGet*(t: GLenum): int
proc ExtensionSupported*(name: cstring): int
  # GLUT font sub-API
proc BitmapCharacter*(font: pointer, character: int)
proc BitmapWidth*(font: pointer, character: int): int
proc StrokeCharacter*(font: pointer, character: int)
proc StrokeWidth*(font: pointer, character: int): int
proc BitmapLength*(font: pointer, str: cstring): int
proc StrokeLength*(font: pointer, str: cstring): int
  # GLUT pre-built models sub-API
proc WireSphere*(radius: GLdouble, slices, stacks: GLint)
proc SolidSphere*(radius: GLdouble, slices, stacks: GLint)
proc WireCone*(base, height: GLdouble, slices, stacks: GLint)
proc SolidCone*(base, height: GLdouble, slices, stacks: GLint)
proc WireCube*(size: GLdouble)
proc SolidCube*(size: GLdouble)
proc WireTorus*(innerRadius, outerRadius: GLdouble, sides, rings: GLint)
proc SolidTorus*(innerRadius, outerRadius: GLdouble, sides, rings: GLint)
proc WireDodecahedron*()
proc SolidDodecahedron*()
proc WireTeapot*(size: GLdouble)
proc SolidTeapot*(size: GLdouble)
proc WireOctahedron*()
proc SolidOctahedron*()
proc WireTetrahedron*()
proc SolidTetrahedron*()
proc WireIcosahedron*()
proc SolidIcosahedron*()
  # GLUT video resize sub-API.
proc VideoResizeGet*(param: GLenum): int
proc SetupVideoResizing*()
proc StopVideoResizing*()
proc VideoResize*(x, y, width, height: int)
proc VideoPan*(x, y, width, height: int)
  # GLUT debugging sub-API.
proc ReportErrors*()
  # GLUT device control sub-API.
proc IgnoreKeyRepeat*(ignore: int)
proc SetKeyRepeat*(repeatMode: int)
proc ForceJoystickFunc*()
  # GLUT game mode sub-API.
  #example glutGameModeString('1280x1024:32@75');
proc GameModeString*(AString: cstring)
proc EnterGameMode*()
proc LeaveGameMode*()
proc GameModeGet*(mode: GLenum): int
# implementation
{.pop.} # dynlib: dllname, importc
