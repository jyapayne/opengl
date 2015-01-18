#
#
#  Adaption of the delphi3d.net OpenGL units to FreePascal
#  Sebastian Guenther (sg@freepascal.org) in 2002
#  These units are free to use
#******************************************************************************
# Converted to Delphi by Tom Nuydens (tom@delphi3d.net)
# For the latest updates, visit Delphi3D: http://www.delphi3d.net
#******************************************************************************

import opengl

{.deadCodeElim: on.}

when defined(windows):
  {.push, callconv: stdcall.}
else:
  {.push, callconv: cdecl.}

when defined(windows):
  const
    dllname = "glu32.dll"
elif defined(macosx):
  const
    dllname = "/System/Library/Frameworks/OpenGL.framework/Libraries/libGLU.dylib"
else:
  const
    dllname = "libGLU.so.1"

type
  ViewPortArray* = array[0..3, GLint]
  c16dArray* = array[0..15, GLdouble]
  CallBack* = proc ()
  c3dArray* = array[0..2, GLdouble]
  c4pArray* = array[0..3, pointer]
  c4fArray* = array[0..3, GLfloat]

type
  GLUnurbs*{.final.} = object
  PGLUnurbs* = ptr GLUnurbs
  GLUquadric*{.final.} = object
  PGLUquadric* = ptr GLUquadric
  GLUtesselator*{.final.} = object
  PGLUtesselator* = ptr GLUtesselator # backwards compatibility:
  GLUnurbsObj* = GLUnurbs
  PGLUnurbsObj* = PGLUnurbs
  GLUquadricObj* = GLUquadric
  PGLUquadricObj* = PGLUquadric
  GLUtesselatorObj* = GLUtesselator
  PGLUtesselatorObj* = PGLUtesselator
  GLUtriangulatorObj* = GLUtesselator
  PGLUtriangulatorObj* = PGLUtesselator

{.deprecated: [TGLUnurbs: GLUnurbs,
               TGLUquadric: GLUquadric,
               TGLUtesselator: GLUtesselator,
               TGLUnurbsObj: GLUnurbsObj,
               TGLUquadricObj: GLUquadricObj,
               TGLUtesselatorObj: GLUtesselatorObj,
               TGLUtriangulatorObj: GLUtriangulatorObj,
               TViewPortArray: ViewPortArray,
               T16dArray: c16dArray,
               TCallback: Callback,
               T3dArray: c3dArray,
               T4pArray: c4pArray,
               T4fArray: c4fArray].}

{.push dynlib: dllname, importc: "glu$1".}

proc ErrorString*(errCode: GLenum): cstring
when defined(Windows):
  proc ErrorUnicodeStringEXT*(errCode: GLenum): ptr int16
proc GetString*(name: GLenum): cstring
proc Ortho2D*(left, right, bottom, top: GLdouble)
proc Perspective*(fovy, aspect, zNear, zFar: GLdouble)
proc PickMatrix*(x, y, width, height: GLdouble, viewport: var ViewPortArray)
proc LookAt*(eyex, eyey, eyez, centerx, centery, centerz, upx, upy, upz: GLdouble)
proc Project*(objx, objy, objz: GLdouble,
                 modelMatrix, projMatrix: var c16dArray,
                 viewport: var ViewPortArray, winx, winy, winz: ptr GLdouble): int
proc UnProject*(winx, winy, winz: GLdouble,
                   modelMatrix, projMatrix: var c16dArray,
                   viewport: var ViewPortArray, objx, objy, objz: ptr GLdouble): int
proc ScaleImage*(format: GLenum, widthin, heightin: GLint, typein: GLenum,
                    datain: pointer, widthout, heightout: GLint,
                    typeout: GLenum, dataout: pointer): int
proc Build1DMipmaps*(target: GLenum, components, width: GLint,
                        format, atype: GLenum, data: pointer): int
proc Build2DMipmaps*(target: GLenum, components, width, height: GLint,
                        format, atype: GLenum, data: pointer): int
proc NewQuadric*(): PGLUquadric
proc DeleteQuadric*(state: PGLUquadric)
proc QuadricNormals*(quadObject: PGLUquadric, normals: GLenum)
proc QuadricTexture*(quadObject: PGLUquadric, textureCoords: GLboolean)
proc QuadricOrientation*(quadObject: PGLUquadric, orientation: GLenum)
proc QuadricDrawStyle*(quadObject: PGLUquadric, drawStyle: GLenum)
proc Cylinder*(qobj: PGLUquadric, baseRadius, topRadius, height: GLdouble,
                  slices, stacks: GLint)
proc Disk*(qobj: PGLUquadric, innerRadius, outerRadius: GLdouble,
              slices, loops: GLint)
proc PartialDisk*(qobj: PGLUquadric, innerRadius, outerRadius: GLdouble,
                     slices, loops: GLint, startAngle, sweepAngle: GLdouble)
proc Sphere*(qobj: PGLuquadric, radius: GLdouble, slices, stacks: GLint)
proc QuadricCallback*(qobj: PGLUquadric, which: GLenum, fn: Callback)
proc NewTess*(): PGLUtesselator
proc DeleteTess*(tess: PGLUtesselator)
proc TessBeginPolygon*(tess: PGLUtesselator, polygon_data: pointer)
proc TessBeginContour*(tess: PGLUtesselator)
proc TessVertex*(tess: PGLUtesselator, coords: var c3dArray, data: pointer)
proc TessEndContour*(tess: PGLUtesselator)
proc TessEndPolygon*(tess: PGLUtesselator)
proc TessProperty*(tess: PGLUtesselator, which: GLenum, value: GLdouble)
proc TessNormal*(tess: PGLUtesselator, x, y, z: GLdouble)
proc TessCallback*(tess: PGLUtesselator, which: GLenum, fn: Callback)
proc GetTessProperty*(tess: PGLUtesselator, which: GLenum, value: ptr GLdouble)
proc NewNurbsRenderer*(): PGLUnurbs
proc DeleteNurbsRenderer*(nobj: PGLUnurbs)
proc BeginSurface*(nobj: PGLUnurbs)
proc BeginCurve*(nobj: PGLUnurbs)
proc EndCurve*(nobj: PGLUnurbs)
proc EndSurface*(nobj: PGLUnurbs)
proc BeginTrim*(nobj: PGLUnurbs)
proc EndTrim*(nobj: PGLUnurbs)
proc PwlCurve*(nobj: PGLUnurbs, count: GLint, aarray: ptr GLfloat,
                  stride: GLint, atype: GLenum)
proc NurbsCurve*(nobj: PGLUnurbs, nknots: GLint, knot: ptr GLfloat,
                    stride: GLint, ctlarray: ptr GLfloat, order: GLint,
                    atype: GLenum)
proc NurbsSurface*(nobj: PGLUnurbs, sknot_count: GLint, sknot: ptr GLfloat,
                      tknot_count: GLint, tknot: ptr GLfloat,
                      s_stride, t_stride: GLint, ctlarray: ptr GLfloat,
                      sorder, torder: GLint, atype: GLenum)
proc LoadSamplingMatrices*(nobj: PGLUnurbs,
                              modelMatrix, projMatrix: var c16dArray,
                              viewport: var ViewPortArray)
proc NurbsProperty*(nobj: PGLUnurbs, aproperty: GLenum, value: GLfloat)
proc GetNurbsProperty*(nobj: PGLUnurbs, aproperty: GLenum, value: ptr GLfloat)
proc NurbsCallback*(nobj: PGLUnurbs, which: GLenum, fn: Callback)
  #*** Callback function prototypes ***
type                          # gluQuadricCallback
  GLUquadricErrorProc* = proc (p: GLenum) # gluTessCallback
  GLUtessBeginProc* = proc (p: GLenum)
  GLUtessEdgeFlagProc* = proc (p: GLboolean)
  GLUtessVertexProc* = proc (p: pointer)
  GLUtessEndProc* = proc ()
  GLUtessErrorProc* = proc (p: GLenum)
  GLUtessCombineProc* = proc (p1: var c3dArray, p2: c4pArray, p3: c4fArray,
                              p4: ptr pointer)
  GLUtessBeginDataProc* = proc (p1: GLenum, p2: pointer)
  GLUtessEdgeFlagDataProc* = proc (p1: GLboolean, p2: pointer)
  GLUtessVertexDataProc* = proc (p1, p2: pointer)
  GLUtessEndDataProc* = proc (p: pointer)
  GLUtessErrorDataProc* = proc (p1: GLenum, p2: pointer)
  GLUtessCombineDataProc* = proc (p1: var c3dArray, p2: var c4pArray,
                                  p3: var c4fArray, p4: ptr pointer, p5: pointer) #
  GLUnurbsErrorProc* = proc (p: GLenum) #***           Generic constants               ****/

const                         # Version
  VERSION_1_1* = 1
  VERSION_1_2* = 1        # Errors: (return value 0 = no error)
  INVALID_ENUM* = 100900
  INVALID_VALUE* = 100901
  OUT_OF_MEMORY* = 100902
  INCOMPATIBLE_GL_VERSION* = 100903 # StringName
  VERSION* = 100800
  EXTENSIONS* = 100801    # Boolean
  TRUE* = opengl.TRUE
  FALSE* = opengl.FALSE #***           Quadric constants               ****/
                        # QuadricNormal
  SMOOTH* = 100000
  FLAT* = 100001
  NONE* = 100002          # QuadricDrawStyle
  POINT* = 100010
  LINE* = 100011
  FILL* = 100012
  SILHOUETTE* = 100013    # QuadricOrientation
  OUTSIDE* = 100020
  INSIDE* = 100021        # Callback types:
                              #      ERROR       = 100103;
                              #***           Tesselation constants           ****/
  TESS_MAX_COORD* = 1.00000e+150 # TessProperty
  TESS_WINDING_RULE* = 100140
  TESS_BOUNDARY_ONLY* = 100141
  TESS_TOLERANCE* = 100142 # TessWinding
  TESS_WINDING_ODD* = 100130
  TESS_WINDING_NONZERO* = 100131
  TESS_WINDING_POSITIVE* = 100132
  TESS_WINDING_NEGATIVE* = 100133
  TESS_WINDING_ABS_GEQ_TWO* = 100134 # TessCallback
  TESS_BEGIN* = 100100    # void (CALLBACK*)(GLenum    type)
  constTESS_VERTEX* = 100101 # void (CALLBACK*)(void      *data)
  TESS_END* = 100102      # void (CALLBACK*)(void)
  TESS_ERROR* = 100103    # void (CALLBACK*)(GLenum    errno)
  TESS_EDGE_FLAG* = 100104 # void (CALLBACK*)(GLboolean boundaryEdge)
  TESS_COMBINE* = 100105 # void (CALLBACK*)(GLdouble  coords[3],
                             #                                                            void      *data[4],
                             #                                                            GLfloat   weight[4],
                             #                                                            void      **dataOut)
  TESS_BEGIN_DATA* = 100106 # void (CALLBACK*)(GLenum    type,
                                #                                                            void      *polygon_data)
  TESS_VERTEX_DATA* = 100107 # void (CALLBACK*)(void      *data,
                                 #                                                            void      *polygon_data)
  TESS_END_DATA* = 100108 # void (CALLBACK*)(void      *polygon_data)
  TESS_ERROR_DATA* = 100109 # void (CALLBACK*)(GLenum    errno,
                                #                                                            void      *polygon_data)
  TESS_EDGE_FLAG_DATA* = 100110 # void (CALLBACK*)(GLboolean boundaryEdge,
                                    #                                                            void      *polygon_data)
  TESS_COMBINE_DATA* = 100111 # void (CALLBACK*)(GLdouble  coords[3],
                                  #                                                            void      *data[4],
                                  #                                                            GLfloat   weight[4],
                                  #                                                            void      **dataOut,
                                  #                                                            void      *polygon_data)
                                  # TessError
  TESS_ERROR1* = 100151
  TESS_ERROR2* = 100152
  TESS_ERROR3* = 100153
  TESS_ERROR4* = 100154
  TESS_ERROR5* = 100155
  TESS_ERROR6* = 100156
  TESS_ERROR7* = 100157
  TESS_ERROR8* = 100158
  TESS_MISSING_BEGIN_POLYGON* = TESS_ERROR1
  TESS_MISSING_BEGIN_CONTOUR* = TESS_ERROR2
  TESS_MISSING_END_POLYGON* = TESS_ERROR3
  TESS_MISSING_END_CONTOUR* = TESS_ERROR4
  TESS_COORD_TOO_LARGE* = TESS_ERROR5
  TESS_NEED_COMBINE_CALLBACK* = TESS_ERROR6 #***           NURBS constants                 ****/
                                                    # NurbsProperty
  AUTO_LOAD_MATRIX* = 100200
  CULLING* = 100201
  SAMPLING_TOLERANCE* = 100203
  DISPLAY_MODE* = 100204
  PARAMETRIC_TOLERANCE* = 100202
  SAMPLING_METHOD* = 100205
  U_STEP* = 100206
  V_STEP* = 100207        # NurbsSampling
  PATH_LENGTH* = 100215
  PARAMETRIC_ERROR* = 100216
  DOMAIN_DISTANCE* = 100217 # NurbsTrim
  MAP1_TRIM_2* = 100210
  MAP1_TRIM_3* = 100211   # NurbsDisplay
                              #      FILL                = 100012;
  OUTLINE_POLYGON* = 100240
  OUTLINE_PATCH* = 100241 # NurbsCallback
                              #      ERROR               = 100103;
                              # NurbsErrors
  NURBS_ERROR1* = 100251
  NURBS_ERROR2* = 100252
  NURBS_ERROR3* = 100253
  NURBS_ERROR4* = 100254
  NURBS_ERROR5* = 100255
  NURBS_ERROR6* = 100256
  NURBS_ERROR7* = 100257
  NURBS_ERROR8* = 100258
  NURBS_ERROR9* = 100259
  NURBS_ERROR10* = 100260
  NURBS_ERROR11* = 100261
  NURBS_ERROR12* = 100262
  NURBS_ERROR13* = 100263
  NURBS_ERROR14* = 100264
  NURBS_ERROR15* = 100265
  NURBS_ERROR16* = 100266
  NURBS_ERROR17* = 100267
  NURBS_ERROR18* = 100268
  NURBS_ERROR19* = 100269
  NURBS_ERROR20* = 100270
  NURBS_ERROR21* = 100271
  NURBS_ERROR22* = 100272
  NURBS_ERROR23* = 100273
  NURBS_ERROR24* = 100274
  NURBS_ERROR25* = 100275
  NURBS_ERROR26* = 100276
  NURBS_ERROR27* = 100277
  NURBS_ERROR28* = 100278
  NURBS_ERROR29* = 100279
  NURBS_ERROR30* = 100280
  NURBS_ERROR31* = 100281
  NURBS_ERROR32* = 100282
  NURBS_ERROR33* = 100283
  NURBS_ERROR34* = 100284
  NURBS_ERROR35* = 100285
  NURBS_ERROR36* = 100286
  NURBS_ERROR37* = 100287 #***           Backwards compatibility for old tesselator           ****/

proc BeginPolygon*(tess: PGLUtesselator)
proc NextContour*(tess: PGLUtesselator, atype: GLenum)
proc EndPolygon*(tess: PGLUtesselator)

{.pop.}

const                         # Contours types -- obsolete!
  CW* = 100120
  CCW* = 100121
  INTERIOR* = 100122
  EXTERIOR* = 100123
  UNKNOWN* = 100124       # Names without "TESS_" prefix
  BEGIN* = TESS_BEGIN
  VERTEX* = constTESS_VERTEX
  END* = TESS_END
  ERROR* = TESS_ERROR
  EDGE_FLAG* = TESS_EDGE_FLAG

{.pop.}
# implementation
