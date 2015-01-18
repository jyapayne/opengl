
#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2012 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module is a wrapper around `opengl`:idx:. If you define the symbol
## ``useGlew`` this wrapper does not use Nimrod's ``dynlib`` mechanism,
## but `glew`:idx: instead. However, this shouldn't be necessary anymore; even
## extension loading for the different operating systems is handled here.
##
## You need to call ``loadExtensions`` after a rendering context has been
## created to load any extension proc that your code uses.

{.deadCodeElim: on.}

import macros, sequtils

when defined(linux) and not defined(android):
  import X, XLib, XUtil
elif defined(windows):
  import winlean, os

when defined(windows):
  const
    ogldll* = "OpenGL32.dll"
    gludll* = "GLU32.dll"
elif defined(macosx):
  #macosx has this notion of a framework, thus the path to the openGL dylib files
  #is absolute
  const
    ogldll* = "/System/Library/Frameworks/OpenGL.framework/Versions/Current/Libraries/libGL.dylib"
    gludll* = "/System/Library/Frameworks/OpenGL.framework/Versions/Current/Libraries/libGLU.dylib"
else:
  const
    ogldll* = "libGL.so.1"
    gludll* = "libGLU.so.1"

when defined(useGlew):
  {.pragma: ogl, header: "<GL/glew.h>".}
  {.pragma: oglx, header: "<GL/glxew.h>".}
  {.pragma: wgl, header: "<GL/wglew.h>".}
  {.pragma: glu, dynlib: gludll.}
elif defined(ios):
  {.pragma: ogl.}
  {.pragma: oglx.}
  {.passC: "-framework OpenGLES", passL: "-framework OpenGLES".}
elif defined(android):
  {.pragma: ogl.}
  {.pragma: oglx.}
else:
  # quite complex ... thanks to extension support for various platforms:
  import dynlib

  let oglHandle = loadLib(ogldll)
  if isNil(oglHandle): quit("could not load: " & ogldll)

  when defined(windows):
    var wglGetProcAddress = cast[proc (s: cstring): pointer {.stdcall.}](
      symAddr(oglHandle, "wglGetProcAddress"))
  elif defined(linux):
    var glxGetProcAddress = cast[proc (s: cstring): pointer {.cdecl.}](
      symAddr(oglHandle, "glxGetProcAddress"))
    var glxGetProcAddressArb = cast[proc (s: cstring): pointer {.cdecl.}](
      symAddr(oglHandle, "glxGetProcAddressARB"))

  proc glGetProc(h: LibHandle; procName: cstring): pointer =
    when defined(windows):
      result = symAddr(h, procname)
      if result != nil: return
      if not isNil(wglGetProcAddress): result = wglGetProcAddress(procName)
    elif defined(linux):
      if not isNil(glxGetProcAddress): result = glxGetProcAddress(procName)
      if result != nil: return
      if not isNil(glxGetProcAddressArb):
        result = glxGetProcAddressArb(procName)
        if result != nil: return
      result = symAddr(h, procname)
    else:
      result = symAddr(h, procName)
    if result == nil: raiseInvalidLibrary(procName)

  var gluHandle: LibHandle

  proc gluGetProc(procname: cstring): pointer =
    if gluHandle == nil:
      gluHandle = loadLib(gludll)
      if gluHandle == nil: quit("could not load: " & gludll)
    result = glGetProc(gluHandle, procname)

  # undocumented 'dynlib' feature: the string literal is replaced by
  # the imported proc name:
  {.pragma: ogl, dynlib: glGetProc(oglHandle, "0").}
  {.pragma: oglx, dynlib: glGetProc(oglHandle, "0").}
  {.pragma: wgl, dynlib: glGetProc(oglHandle, "0").}
  {.pragma: glu, dynlib: gluGetProc("").}

  proc nimLoadProcs0() {.importc.}

  template loadExtensions*() =
    ## call this after your rendering context has been setup if you use
    ## extensions.
    bind nimLoadProcs0
    nimLoadProcs0()

type
  GLenum* = uint32
  GLboolean* = bool
  GLbitfield* = uint32
  GLvoid* = pointer
  GLbyte* = cchar
  GLshort* = int64
  GLint* = int32
  GLclampx* = int32
  GLubyte* = cuchar
  GLushort* = uint16
  GLuint* = uint32
  GLhandle* = GLuint
  GLsizei* = int32
  GLfloat* = float32
  GLclampf* = float32
  GLdouble* = float64
  GLclampd* = float64
  GLeglImageOES* = distinct pointer
  GLchar* = char
  GLcharArb* = char
  GLfixed* = int32
  GLhalfNv* = uint16
  GLvdpauSurfaceNv* = uint
  GLintptr* = int32
  GLintptrArb* = int32
  GLint64EXT* = int64
  GLuint64EXT* = uint64
  GLint64* = int64
  GLsizeiptrArb* = int32
  GLsizeiptr* = int32
  GLsync* = distinct pointer
  GLuint64* = uint64
  GLvectorub2* = array[0..1, GLubyte]
  GLvectori2* = array[0..1, GLint]
  GLvectorf2* = array[0..1, GLfloat]
  GLvectord2* = array[0..1, GLdouble]
  GLvectorp2* = array[0..1, pointer]
  GLvectorb3* = array[0..2, GLbyte]
  GLvectorub3* = array[0..2, GLubyte]
  GLvectori3* = array[0..2, GLint]
  GLvectorui3* = array[0..2, GLuint]
  GLvectorf3* = array[0..2, GLfloat]
  GLvectord3* = array[0..2, GLdouble]
  GLvectorp3* = array[0..2, pointer]
  GLvectors3* = array[0..2, GLshort]
  GLvectorus3* = array[0..2, GLushort]
  GLvectorb4* = array[0..3, GLbyte]
  GLvectorub4* = array[0..3, GLubyte]
  GLvectori4* = array[0..3, GLint]
  GLvectorui4* = array[0..3, GLuint]
  GLvectorf4* = array[0..3, GLfloat]
  GLvectord4* = array[0..3, GLdouble]
  GLvectorp4* = array[0..3, pointer]
  GLvectors4* = array[0..3, GLshort]
  GLvectorus4* = array[0..3, GLshort]
  GLarray4f* = GLvectorf4
  GLarrayf3* = GLvectorf3
  GLarrayd3* = GLvectord3
  GLarrayi4* = GLvectori4
  GLarrayp4* = GLvectorp4
  GLmatrixub3* = array[0..2, array[0..2, GLubyte]]
  GLmatrixi3* = array[0..2, array[0..2, GLint]]
  GLmatrixf3* = array[0..2, array[0..2, GLfloat]]
  GLmatrixd3* = array[0..2, array[0..2, GLdouble]]
  GLmatrixub4* = array[0..3, array[0..3, GLubyte]]
  GLmatrixi4* = array[0..3, array[0..3, GLint]]
  GLmatrixf4* = array[0..3, array[0..3, GLfloat]]
  GLmatrixd4* = array[0..3, array[0..3, GLdouble]]
  ClContext* = distinct pointer
  ClEvent* = distinct pointer
  GLdebugProc* = proc (
    source: GLenum,
    typ: GLenum,
    id: GLuint,
    severity: GLenum,
    length: GLsizei,
    message: ptr GLchar,
    userParam: pointer) {.stdcall.}
  GLdebugProcArb* = proc (
    source: GLenum,
    typ: GLenum,
    id: GLuint,
    severity: GLenum,
    len: GLsizei,
    message: ptr GLchar,
    userParam: pointer) {.stdcall.}
  GLdebugProcAmd* = proc (
    id: GLuint,
    category: GLenum,
    severity: GLenum,
    len: GLsizei,
    message: ptr GLchar,
    userParam: pointer) {.stdcall.}
  GLdebugProcKhr* = proc (
    source, typ: GLenum,
    id: GLuint,
    severity: GLenum,
    length: GLsizei,
    message: ptr GLchar,
    userParam: pointer) {.stdcall.}
type
  GLerrorCode* {.size: GLenum.sizeof.} = enum # XXX: can't be evaluated when
                                              # in the same type section as
                                              # GLenum.
    glErrNoError = (0, "no error")
    glErrInvalidEnum = (0x0500, "invalid enum")
    glErrInvalidValue = (0x0501, "invalid value")
    glErrInvalidOperation = (0x0502, "invalid operation")
    glErrStackOverflow = (0x0503, "stack overflow")
    glErrStackUnderflow = (0x0504, "stack underflow")
    glErrOutOfMem = (0x0505, "out of memory")
    glErrInvalidFramebufferOperation = (0x0506, "invalid framebuffer operation")
    glErrTableTooLarge = (0x8031, "table too large")

const AllErrorCodes = {
    glErrNoError,
    glErrInvalidEnum,
    glErrInvalidValue,
    glErrInvalidOperation,
    glErrStackOverflow,
    glErrStackUnderflow,
    glErrOutOfMem,
    glErrInvalidFramebufferOperation,
    glErrTableTooLarge,
}

when defined(macosx):
  type
    GLhandleArb = pointer
else:
  type
    GLhandleArb = uint32

{.deprecated: [
  TGLerror: GLerrorCode,
  TGLhandleARB: GLhandleArb,
  TGLenum: GLenum,
  TGLboolean: GLboolean,
  TGLbitfield: GLbitfield,
  TGLvoid: GLvoid,
  TGLbyte: GLbyte,
  TGLshort: GLshort,
  TGLint: GLint,
  TGLclampx: GLclampx,
  TGLubyte: GLubyte,
  TGLushort: GLushort,
  TGLuint: GLuint,
  TGLsizei: GLsizei,
  TGLfloat: GLfloat,
  TGLclampf: GLclampf,
  TGLdouble: GLdouble,
  TGLclampd: GLclampd,
  TGLeglImageOES: GLeglImageOES,
  TGLchar: GLchar,
  TGLcharARB: GLcharArb,
  TGLfixed: GLfixed,
  TGLhalfNV: GLhalfNv,
  TGLvdpauSurfaceNv: GLvdpauSurfaceNv,
  TGLintptr: GLintptr,
  TGLintptrARB: GLintptrArb,
  TGLint64EXT: GLint64Ext,
  TGLuint64EXT: GLuint64Ext,
  TGLint64: GLint64,
  TGLsizeiptrARB: GLsizeiptrArb,
  TGLsizeiptr: GLsizeiptr,
  TGLsync: GLsync,
  TGLuint64: GLuint64,
  TCL_context: ClContext,
  TCL_event: ClEvent,
  TGLdebugProc: GLdebugProc,
  TGLDebugProcARB: GLdebugProcArb,
  TGLDebugProcAMD: GLdebugProcAmd,
  TGLDebugProcKHR: GLdebugProcKhr,
  TGLVectorub2: GLvectorub2,
  TGLVectori2: GLvectori2,
  TGLVectorf2: GLvectorf2,
  TGLVectord2: GLvectord2,
  TGLVectorp2: GLvectorp2,
  TGLVectorb3: GLvectorb3,
  TGLVectorub3: GLvectorub3,
  TGLVectori3: GLvectori3,
  TGLVectorui3: GLvectorui3,
  TGLVectorf3: GLvectorf3,
  TGLVectord3: GLvectord3,
  TGLVectorp3: GLvectorp3,
  TGLVectors3: GLvectors3,
  TGLVectorus3: GLvectorus3,
  TGLVectorb4: GLvectorb4,
  TGLVectorub4: GLvectorub4,
  TGLVectori4: GLvectori4,
  TGLVectorui4: GLvectorui4,
  TGLVectorf4: GLvectorf4,
  TGLVectord4: GLvectord4,
  TGLVectorp4: GLvectorp4,
  TGLVectors4: GLvectors4,
  TGLVectorus4: GLvectorus4,
  TGLArrayf4: GLarray4f,
  TGLArrayf3: GLarrayf3,
  TGLArrayd3: GLarrayd3,
  TGLArrayi4: GLarrayi4,
  TGLArrayp4: GLarrayp4,
  TGLMatrixub3: GLmatrixub3,
  TGLMatrixi3: GLmatrixi3,
  TGLMatrixf3: GLmatrixf3,
  TGLMatrixd3: GLmatrixd3,
  TGLMatrixub4: GLmatrixub4,
  TGLMatrixi4: GLmatrixi4,
  TGLMatrixf4: GLmatrixf4,
  TGLMatrixd4: GLmatrixd4,
  TGLVector3d: GLvectord3,
  TGLVector4i: GLvectori4,
  TGLVector4f: GLvectorf4,
  TGLVector4p: GLvectorp4,
  TGLMatrix4f: GLmatrixf4,
  TGLMatrix4d: GLmatrixd4,
].}

proc GetError*: GLenum {.stdcall, importc: "gl$1", ogl.}
proc getGLerrorCode*: GLerrorCode = GetError().GLerrorCode
  ## Like ``glGetError`` but returns an enumerator instead.

type
  GLerror* = object of Exception
    ## An exception for OpenGL errors.
    code*: GLerrorCode ## The error code. This might be invalid for two reasons:
                    ## an outdated list of errors or a bad driver.

proc checkGLerror* =
  ## Raise ``GLerror`` if the last call to an OpenGL function generated an error.
  ## You might want to call this once every frame for example if automatic
  ## error checking has been disabled.
  let error = getGLerrorCode()
  if error == glErrNoError:
    return

  var
    exc = new(GLerror)
  for e in AllErrorCodes:
    if e == error:
      exc.msg = "OpenGL error: " & $e
      raise exc

  exc.code = error
  exc.msg = "OpenGL error: unknown (" & $error & ")"
  raise exc

const
  NoAutoGLerrorCheck* = defined(noAutoGLerrorCheck) ##\
  ## This determines (at compile time) whether an exception should be raised
  ## if an OpenGL call generates an error. No additional code will be generated
  ## and ``enableAutoGLerrorCheck(bool)`` will have no effect when
  ## ``noAutoGLerrorCheck`` is defined.

var
  gAutoGLerrorCheck = true
  gInsideBeginEnd* = false # do not change manually.

proc enableAutoGLerrorCheck*(yes: bool) =
  ## This determines (at run time) whether an exception should be raised if an
  ## OpenGL call generates an error. This has no effect when
  ## ``noAutoGLerrorCheck`` is defined.
  gAutoGLerrorCheck = yes

macro wrapErrorChecking(f: stmt): stmt {.immediate.} =
  f.expectKind nnkStmtList
  result = newStmtList()

  for child in f.children:
    child.expectKind nnkProcDef
    let params = toSeq(child.params.children)
    var glProc = copy child
    glProc.pragma = newNimNode(nnkPragma).add(
        newNimNode(nnkExprColonExpr).add(
          ident"importc" , newLit("gl" & $child.name))
      ).add(ident"ogl")

    let rawGLprocName = $glProc.name
    glProc.name = ident(rawGLprocName & "Impl")
    var
      body = newStmtList glProc
      returnsSomething = child.params[0].kind != nnkEmpty
      callParams = newSeq[PNimrodNode]()
    for param in params[1 .. <params.len]:
      callParams.add param[0]

    let glCall = newCall(glProc.name, callParams)
    body.add if returnsSomething:
        newAssignment(ident"result", glCall)
      else:
        glCall

    if rawGLprocName == "glBegin":
      body.add newAssignment(ident"gInsideBeginEnd", ident"true")
    if rawGLprocName == "glEnd":
      body.add newAssignment(ident"gInsideBeginEnd", ident"false")

    template errCheck: stmt =
      when not (NoAutoGLerrorCheck):
        if gAutoGLerrorCheck and not gInsideBeginEnd:
          checkGLerror()

    body.add getAst(errCheck())

    var procc = newProc(child.name, params, body)
    procc.pragma = newNimNode(nnkPragma).add(ident"inline")
    procc.name = postfix(procc.name, "*")
    result.add procc

{.push stdcall, hint[XDeclaredButNotUsed]: off.}
wrapErrorChecking:
  proc MultiTexCoord2d(target: GLenum, s: GLdouble, t: GLdouble)
  proc DrawElementsIndirect(mode: GLenum, `type`: GLenum, indirect: pointer)
  proc EnableVertexArrayEXT(vaobj: GLuint, `array`: GLenum)
  proc DeleteFramebuffers(n: GLsizei, framebuffers: ptr GLuint)
  proc MultiTexCoord3dv(target: GLenum, v: ptr GLdouble)
  proc VertexAttrib4d(index: GLuint, x: GLdouble, y: GLdouble, z: GLdouble, w: GLdouble)
  proc LoadPaletteFromModelViewMatrixOES()
  proc Vertex3xvOES(coords: ptr GLfixed)
  proc NormalStream3sATI(stream: GLenum, nx: GLshort, ny: GLshort, nz: GLshort)
  proc MatrixFrustumEXT(mode: GLenum, left: GLdouble, right: GLdouble, bottom: GLdouble, top: GLdouble, zNear: GLdouble, zFar: GLdouble)
  proc UniformMatrix2fvARB(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat)
  proc Color4dv(v: ptr GLdouble)
  proc Color3fv(v: ptr GLfloat)
  proc VertexAttribI1uiEXT(index: GLuint, x: GLuint)
  proc GetDebugMessageLogKHR(count: GLuint, bufsize: GLsizei, sources: ptr GLenum, types: ptr GLenum, ids: ptr GLuint, severities: ptr GLenum, lengths: ptr GLsizei, messageLog: cstring): GLuint
  proc VertexAttribI2iv(index: GLuint, v: ptr GLint)
  proc TexCoord1xvOES(coords: ptr GLfixed)
  proc Vertex3hNV(x: GLhalfNv, y: GLhalfNv, z: GLhalfNv)
  proc IsShader(shader: GLuint): GLboolean
  proc DeleteRenderbuffersEXT(n: GLsizei, renderbuffers: ptr GLuint)
  proc Vertex3hvNV(v: ptr GLhalfNv)
  proc GetPointervKHR(pname: GLenum, params: ptr pointer)
  proc ProgramUniform3i64vNV(program: GLuint, location: GLint, count: GLsizei, value: ptr GLint64Ext)
  proc NamedFramebufferTexture1DEXT(framebuffer: GLuint, attachment: GLenum, textarget: GLenum, texture: GLuint, level: GLint)
  proc GetNamedProgramLocalParameterfvEXT(program: GLuint, target: GLenum, index: GLuint, params: ptr GLfloat)
  proc GenRenderbuffersOES(n: GLsizei, renderbuffers: ptr GLuint)
  proc Vertex4dv(v: ptr GLdouble)
  proc TexCoord2fColor4ubVertex3fvSUN(tc: ptr GLfloat, c: ptr GLubyte, v: ptr GLfloat)
  proc TexStorage2DEXT(target: GLenum, levels: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei)
  proc VertexAttrib2d(index: GLuint, x: GLdouble, y: GLdouble)
  proc VertexAttrib1dv(index: GLuint, v: ptr GLdouble)
  proc BindProgramARB(target: GLenum, program: GLuint)
  proc RasterPos2dv(v: ptr GLdouble)
  proc CompressedTextureSubImage2DEXT(texture: GLuint, target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, width: GLsizei, height: GLsizei, format: GLenum, imageSize: GLsizei, bits: pointer)
  proc NormalPointervINTEL(`type`: GLenum, `pointer`: ptr pointer)
  proc GetInteger64vAPPLE(pname: GLenum, params: ptr GLint64)
  proc PushMatrix()
  proc GetCompressedTexImageARB(target: GLenum, level: GLint, img: pointer)
  proc BindMaterialParameterEXT(face: GLenum, value: GLenum): GLuint
  proc BlendEquationIndexedAMD(buf: GLuint, mode: GLenum)
  proc GetObjectBufferfvATI(buffer: GLuint, pname: GLenum, params: ptr GLfloat)
  proc MakeNamedBufferNonResidentNV(buffer: GLuint)
  proc Uniform2ui64NV(location: GLint, x: GLuint64Ext, y: GLuint64Ext)
  proc RasterPos4fv(v: ptr GLfloat)
  proc DeleteTextures(n: GLsizei, textures: ptr GLuint)
  proc SecondaryColorPointer(size: GLint, `type`: GLenum, stride: GLsizei, `pointer`: pointer)
  proc TextureSubImage1DEXT(texture: GLuint, target: GLenum, level: GLint, xoffset: GLint, width: GLsizei, format: GLenum, `type`: GLenum, pixels: pointer)
  proc EndTilingQCOM(preserveMask: GLbitfield)
  proc BindBuffer(target: GLenum, buffer: GLuint)
  proc UniformMatrix3fvARB(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat)
  proc SamplerParameterf(sampler: GLuint, pname: GLenum, param: GLfloat)
  proc SecondaryColor3d(red: GLdouble, green: GLdouble, blue: GLdouble)
  proc VertexAttrib4sARB(index: GLuint, x: GLshort, y: GLshort, z: GLshort, w: GLshort)
  proc NamedProgramLocalParameterI4iEXT(program: GLuint, target: GLenum, index: GLuint, x: GLint, y: GLint, z: GLint, w: GLint)
  proc ProgramUniform2iEXT(program: GLuint, location: GLint, v0: GLint, v1: GLint)
  proc PopAttrib()
  proc GetnColorTableARB(target: GLenum, format: GLenum, `type`: GLenum, bufSize: GLsizei, table: pointer)
  proc MatrixLoadIdentityEXT(mode: GLenum)
  proc GetNamedProgramivEXT(program: GLuint, target: GLenum, pname: GLenum, params: ptr GLint)
  proc CopyTextureSubImage2DEXT(texture: GLuint, target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, x: GLint, y: GLint, width: GLsizei, height: GLsizei)
  proc Uniform4i64NV(location: GLint, x: GLint64Ext, y: GLint64Ext, z: GLint64Ext, w: GLint64Ext)
  proc DeleteTexturesEXT(n: GLsizei, textures: ptr GLuint)
  proc MultiTexCoord1dv(target: GLenum, v: ptr GLdouble)
  proc MultiTexRenderbufferEXT(texunit: GLenum, target: GLenum, renderbuffer: GLuint)
  proc MultiDrawArraysIndirect(mode: GLenum, indirect: ptr pointer, drawcount: GLsizei, stride: GLsizei)
  proc GetUniformfvARB(programObj: GLhandleArb, location: GLint, params: ptr GLfloat)
  proc BufferDataARB(target: GLenum, size: GLsizeiptrArb, data: pointer, usage: GLenum)
  proc TexCoord2d(s: GLdouble, t: GLdouble)
  proc GetArrayObjectfvATI(`array`: GLenum, pname: GLenum, params: ptr GLfloat)
  proc ShaderOp1EXT(op: GLenum, res: GLuint, arg1: GLuint)
  proc Color3s(red: GLshort, green: GLshort, blue: GLshort)
  proc StencilFuncSeparate(face: GLenum, fun: GLenum, `ref`: GLint, mask: GLuint)
  proc TextureImage2DMultisampleCoverageNV(texture: GLuint, target: GLenum, coverageSamples: GLsizei, colorSamples: GLsizei, internalFormat: GLint, width: GLsizei, height: GLsizei, fixedSampleLocations: GLboolean)
  proc MultiTexCoord2xvOES(texture: GLenum, coords: ptr GLfixed)
  proc GetVertexAttribLui64vNV(index: GLuint, pname: GLenum, params: ptr GLuint64Ext)
  proc Normal3xOES(nx: GLfixed, ny: GLfixed, nz: GLfixed)
  proc MapBufferRangeEXT(target: GLenum, offset: GLintptr, length: GLsizeiptr, access: GLbitfield)
  proc CreateShader(`type`: GLenum): GLuint
  proc DrawRangeElementArrayAPPLE(mode: GLenum, start: GLuint, `end`: GLuint, first: GLint, count: GLsizei)
  proc Vertex2bOES(x: GLbyte)
  proc GetMapxvOES(target: GLenum, query: GLenum, v: ptr GLfixed)
  proc RasterPos3sv(v: ptr GLshort)
  proc DeleteQueriesARB(n: GLsizei, ids: ptr GLuint)
  proc ProgramUniform1iv(program: GLuint, location: GLint, count: GLsizei, value: ptr GLint)
  proc VertexStream2dvATI(stream: GLenum, coords: ptr GLdouble)
  proc BindVertexArrayOES(`array`: GLuint)
  proc LightModelfv(pname: GLenum, params: ptr GLfloat)
  proc EvalCoord2dv(u: ptr GLdouble)
  proc Color3hNV(red: GLhalfNv, green: GLhalfNv, blue: GLhalfNv)
  proc SecondaryColor3iEXT(red: GLint, green: GLint, blue: GLint)
  proc BindTexture(target: GLenum, texture: GLuint)
  proc UniformBufferEXT(program: GLuint, location: GLint, buffer: GLuint)
  proc GetCombinerInputParameterfvNV(stage: GLenum, portion: GLenum, variable: GLenum, pname: GLenum, params: ptr GLfloat)
  proc Uniform2ui64vNV(location: GLint, count: GLsizei, value: ptr GLuint64Ext)
  proc MatrixMultTransposefEXT(mode: GLenum, m: ptr GLfloat)
  proc LineWidth(width: GLfloat)
  proc Rotatef(angle: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat)
  proc NormalStream3svATI(stream: GLenum, coords: ptr GLshort)
  proc TexCoordP4ui(`type`: GLenum, coords: GLuint)
  proc ImageTransformParameterfvHP(target: GLenum, pname: GLenum, params: ptr GLfloat)
  proc Uniform3uiEXT(location: GLint, v0: GLuint, v1: GLuint, v2: GLuint)
  proc GetInvariantIntegervEXT(id: GLuint, value: GLenum, data: ptr GLint)
  proc GetTransformFeedbackVaryingEXT(program: GLuint, index: GLuint, bufSize: GLsizei, length: ptr GLsizei, size: ptr GLsizei, `type`: ptr GLenum, name: cstring)
  proc SamplerParameterIuiv(sampler: GLuint, pname: GLenum, param: ptr GLuint)
  proc ProgramUniform2fEXT(program: GLuint, location: GLint, v0: GLfloat, v1: GLfloat)
  proc MultiTexCoord2hvNV(target: GLenum, v: ptr GLhalfNv)
  proc DeleteRenderbuffersOES(n: GLsizei, renderbuffers: ptr GLuint)
  proc RenderbufferStorageMultisampleCoverageNV(target: GLenum, coverageSamples: GLsizei, colorSamples: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei)
  proc StencilClearTagEXT(stencilTagBits: GLsizei, stencilClearTag: GLuint)
  proc ConvolutionParameteriv(target: GLenum, pname: GLenum, params: ptr GLint)
  proc FenceSyncAPPLE(condition: GLenum, flags: GLbitfield): GLsync
  proc GetVariantArrayObjectivATI(id: GLuint, pname: GLenum, params: ptr GLint)
  proc ProgramUniform4dvEXT(program: GLuint, location: GLint, count: GLsizei, value: ptr GLdouble)
  proc PushDebugGroupKHR(source: GLenum, id: GLuint, length: GLsizei, message: cstring)
  proc FragmentLightivSGIX(light: GLenum, pname: GLenum, params: ptr GLint)
  proc FramebufferTexture2DEXT(target: GLenum, attachment: GLenum, textarget: GLenum, texture: GLuint, level: GLint)
  proc GetActiveSubroutineUniformiv(program: GLuint, shadertype: GLenum, index: GLuint, pname: GLenum, values: ptr GLint)
  proc Frustumf(left: GLfloat, right: GLfloat, bottom: GLfloat, top: GLfloat, nearVal: GLfloat, farVal: GLfloat)
  proc EndQueryIndexed(target: GLenum, index: GLuint)
  proc CompressedTextureSubImage3DEXT(texture: GLuint, target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, format: GLenum, imageSize: GLsizei, bits: pointer)
  proc GetProgramPipelineInfoLogEXT(pipeline: GLuint, bufSize: GLsizei, length: ptr GLsizei, infoLog: cstring)
  proc GetVertexAttribfvNV(index: GLuint, pname: GLenum, params: ptr GLfloat)
  proc VertexArrayIndexOffsetEXT(vaobj: GLuint, buffer: GLuint, `type`: GLenum, stride: GLsizei, offset: GLintptr)
  proc DrawTexsvOES(coords: ptr GLshort)
  proc MultiTexCoord1hNV(target: GLenum, s: GLhalfNv)
  proc WindowPos2iv(v: ptr GLint)
  proc MultiTexCoordP1ui(texture: GLenum, `type`: GLenum, coords: GLuint)
  proc TexCoord1i(s: GLint)
  proc Vertex4hvNV(v: ptr GLhalfNv)
  proc CallLists(n: GLsizei, `type`: GLenum, lists: pointer)
  proc IndexFormatNV(`type`: GLenum, stride: GLsizei)
  proc PointParameterfARB(pname: GLenum, param: GLfloat)
  proc ProgramUniform1dv(program: GLuint, location: GLint, count: GLsizei, value: ptr GLdouble)
  proc GetVertexAttribArrayObjectfvATI(index: GLuint, pname: GLenum, params: ptr GLfloat)
  proc VDPAUUnmapSurfacesNV(numSurface: GLsizei, surfaces: ptr GLvdpauSurfaceNv)
  proc VertexAttribIFormat(attribindex: GLuint, size: GLint, `type`: GLenum, relativeoffset: GLuint)
  proc ClearColorx(red: GLfixed, green: GLfixed, blue: GLfixed, alpha: GLfixed)
  proc Color3bv(v: ptr GLbyte)
  proc NamedProgramLocalParameter4dEXT(program: GLuint, target: GLenum, index: GLuint, x: GLdouble, y: GLdouble, z: GLdouble, w: GLdouble)
  proc VertexPointer(size: GLint, `type`: GLenum, stride: GLsizei, `pointer`: pointer)
  proc GetObjectLabelKHR(identifier: GLenum, name: GLuint, bufSize: GLsizei, length: ptr GLsizei, label: cstring)
  proc CombinerStageParameterfvNV(stage: GLenum, pname: GLenum, params: ptr GLfloat)
  proc Normal3hvNV(v: ptr GLhalfNv)
  proc Uniform2i64NV(location: GLint, x: GLint64Ext, y: GLint64Ext)
  proc MultiTexCoord2iv(target: GLenum, v: ptr GLint)
  proc ProgramUniform3i(program: GLuint, location: GLint, v0: GLint, v1: GLint, v2: GLint)
  proc DeleteAsyncMarkersSGIX(marker: GLuint, range: GLsizei)
  proc StencilOp(fail: GLenum, zfail: GLenum, zpass: GLenum)
  proc ColorP4ui(`type`: GLenum, color: GLuint)
  proc FinishAsyncSGIX(markerp: ptr GLuint): GLint
  proc DrawTexsOES(x: GLshort, y: GLshort, z: GLshort, width: GLshort, height: GLshort)
  proc LineStipple(factor: GLint, pattern: GLushort)
  proc AlphaFragmentOp1ATI(op: GLenum, dst: GLuint, dstMod: GLuint, arg1: GLuint, arg1Rep: GLuint, arg1Mod: GLuint)
  proc MapTexture2DINTEL(texture: GLuint, level: GLint, access: GLbitfield, stride: ptr GLint, layout: ptr GLenum)
  proc Vertex4f(x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat)
  proc FramebufferTextureARB(target: GLenum, attachment: GLenum, texture: GLuint, level: GLint)
  proc ProgramUniform3ui64NV(program: GLuint, location: GLint, x: GLuint64Ext, y: GLuint64Ext, z: GLuint64Ext)
  proc MultTransposeMatrixxOES(m: ptr GLfixed)
  proc Normal3fv(v: ptr GLfloat)
  proc Uniform4fARB(location: GLint, v0: GLfloat, v1: GLfloat, v2: GLfloat, v3: GLfloat)
  proc Binormal3bEXT(bx: GLbyte, by: GLbyte, bz: GLbyte)
  proc GenProgramPipelinesEXT(n: GLsizei, pipelines: ptr GLuint)
  proc DispatchComputeIndirect(indirect: GLintptr)
  proc GetPerfMonitorCounterDataAMD(monitor: GLuint, pname: GLenum, dataSize: GLsizei, data: ptr GLuint, bytesWritten: ptr GLint)
  proc StencilOpValueAMD(face: GLenum, value: GLuint)
  proc Tangent3fvEXT(v: ptr GLfloat)
  proc Uniform3iARB(location: GLint, v0: GLint, v1: GLint, v2: GLint)
  proc MatrixScalefEXT(mode: GLenum, x: GLfloat, y: GLfloat, z: GLfloat)
  proc VertexAttrib2dARB(index: GLuint, x: GLdouble, y: GLdouble)
  proc IsVertexArray(`array`: GLuint): GLboolean
  proc GetMaterialx(face: GLenum, pname: GLenum, param: GLfixed)
  proc MultiTexCoord1dARB(target: GLenum, s: GLdouble)
  proc Color3usv(v: ptr GLushort)
  proc VertexStream3svATI(stream: GLenum, coords: ptr GLshort)
  proc RasterPos3s(x: GLshort, y: GLshort, z: GLshort)
  proc MultiTexCoord2bOES(texture: GLenum, s: GLbyte, t: GLbyte)
  proc GetClipPlanefOES(plane: GLenum, equation: ptr GLfloat)
  proc FramebufferTextureEXT(target: GLenum, attachment: GLenum, texture: GLuint, level: GLint)
  proc VertexAttrib1dNV(index: GLuint, x: GLdouble)
  proc SampleCoverageOES(value: GLfixed, invert: GLboolean)
  proc CompressedTexSubImage2DARB(target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, width: GLsizei, height: GLsizei, format: GLenum, imageSize: GLsizei, data: pointer)
  proc Uniform1iv(location: GLint, count: GLsizei, value: ptr GLint)
  proc ExtGetProgramsQCOM(programs: ptr GLuint, maxPrograms: GLint, numPrograms: ptr GLint)
  proc Fogx(pname: GLenum, param: GLfixed)
  proc MultiTexCoord3hNV(target: GLenum, s: GLhalfNv, t: GLhalfNv, r: GLhalfNv)
  proc ClipPlane(plane: GLenum, equation: ptr GLdouble)
  proc ConvolutionParameterxvOES(target: GLenum, pname: GLenum, params: ptr GLfixed)
  proc InvalidateBufferData(buffer: GLuint)
  proc CheckNamedFramebufferStatusEXT(framebuffer: GLuint, target: GLenum): GLenum
  proc LinkProgram(program: GLuint)
  proc CheckFramebufferStatus(target: GLenum): GLenum
  proc BlendFunci(buf: GLuint, src: GLenum, dst: GLenum)
  proc ProgramUniform4uiv(program: GLuint, location: GLint, count: GLsizei, value: ptr GLuint)
  proc ConvolutionFilter2D(target: GLenum, internalformat: GLenum, width: GLsizei, height: GLsizei, format: GLenum, `type`: GLenum, image: pointer)
  proc Vertex4bvOES(coords: ptr GLbyte)
  proc CopyTextureSubImage1DEXT(texture: GLuint, target: GLenum, level: GLint, xoffset: GLint, x: GLint, y: GLint, width: GLsizei)
  proc Color4uiv(v: ptr GLuint)
  proc GetBufferParameteri64v(target: GLenum, pname: GLenum, params: ptr GLint64)
  proc GetLocalConstantBooleanvEXT(id: GLuint, value: GLenum, data: ptr GLboolean)
  proc CoverStrokePathNV(path: GLuint, coverMode: GLenum)
  proc Scaled(x: GLdouble, y: GLdouble, z: GLdouble)
  proc Lightfv(light: GLenum, pname: GLenum, params: ptr GLfloat)
  proc TexParameterIiv(target: GLenum, pname: GLenum, params: ptr GLint)
  proc MakeImageHandleResidentNV(handle: GLuint64, access: GLenum)
  proc WindowPos3iARB(x: GLint, y: GLint, z: GLint)
  proc ListBase(base: GLuint)
  proc FlushMappedBufferRangeEXT(target: GLenum, offset: GLintptr, length: GLsizeiptr)
  proc Normal3dv(v: ptr GLdouble)
  proc ProgramUniform4d(program: GLuint, location: GLint, v0: GLdouble, v1: GLdouble, v2: GLdouble, v3: GLdouble)
  proc CreateShaderProgramEXT(`type`: GLenum, string: cstring): GLuint
  proc GetLightxvOES(light: GLenum, pname: GLenum, params: ptr GLfixed)
  proc GetObjectPtrLabelKHR(`ptr`: ptr pointer, bufSize: GLsizei, length: ptr GLsizei, label: cstring)
  proc TransformPathNV(resultPath: GLuint, srcPath: GLuint, transformType: GLenum, transformValues: ptr GLfloat)
  proc MultTransposeMatrixf(m: ptr GLfloat)
  proc MapVertexAttrib2dAPPLE(index: GLuint, size: GLuint, u1: GLdouble, u2: GLdouble, ustride: GLint, uorder: GLint, v1: GLdouble, v2: GLdouble, vstride: GLint, vorder: GLint, points: ptr GLdouble)
  proc IsSync(sync: GLsync): GLboolean
  proc MultMatrixx(m: ptr GLfixed)
  proc InterpolatePathsNV(resultPath: GLuint, pathA: GLuint, pathB: GLuint, weight: GLfloat)
  proc EnableClientStateIndexedEXT(`array`: GLenum, index: GLuint)
  proc ProgramEnvParameter4fARB(target: GLenum, index: GLuint, x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat)
  proc VertexAttrib2svARB(index: GLuint, v: ptr GLshort)
  proc Lighti(light: GLenum, pname: GLenum, param: GLint)
  proc SelectBuffer(size: GLsizei, buffer: ptr GLuint)
  proc ReplacementCodeusvSUN(code: ptr GLushort)
  proc MapVertexAttrib1fAPPLE(index: GLuint, size: GLuint, u1: GLfloat, u2: GLfloat, stride: GLint, order: GLint, points: ptr GLfloat)
  proc Materialx(face: GLenum, pname: GLenum, param: GLfixed)
  proc DrawTransformFeedback(mode: GLenum, id: GLuint)
  proc WindowPos2i(x: GLint, y: GLint)
  proc MultiTexEnviEXT(texunit: GLenum, target: GLenum, pname: GLenum, param: GLint)
  proc ProgramUniform1fv(program: GLuint, location: GLint, count: GLsizei, value: ptr GLfloat)
  proc DrawBuffersARB(n: GLsizei, bufs: ptr GLenum)
  proc GetUniformLocationARB(programObj: GLhandleArb, name: cstring): GLint
  proc ResumeTransformFeedback()
  proc Map1f(target: GLenum, u1: GLfloat, u2: GLfloat, stride: GLint, order: GLint, points: ptr GLfloat)
  proc Vertex3xOES(x: GLfixed, y: GLfixed)
  proc PathCoordsNV(path: GLuint, numCoords: GLsizei, coordType: GLenum, coords: pointer)
  proc ListParameterfSGIX(list: GLuint, pname: GLenum, param: GLfloat)
  proc GetUniformivARB(programObj: GLhandleArb, location: GLint, params: ptr GLint)
  proc Binormal3bvEXT(v: ptr GLbyte)
  proc VertexAttribP3ui(index: GLuint, `type`: GLenum, normalized: GLboolean, value: GLuint)
  proc GetVertexArrayPointeri_vEXT(vaobj: GLuint, index: GLuint, pname: GLenum, param: ptr pointer)
  proc ProgramParameter4fvNV(target: GLenum, index: GLuint, v: ptr GLfloat)
  proc DiscardFramebufferEXT(target: GLenum, numAttachments: GLsizei, attachments: ptr GLenum)
  proc GetDebugMessageLogARB(count: GLuint, bufsize: GLsizei, sources: ptr GLenum, types: ptr GLenum, ids: ptr GLuint, severities: ptr GLenum, lengths: ptr GLsizei, messageLog: cstring): GLuint
  proc ResolveMultisampleFramebufferAPPLE()
  proc GetIntegeri_vEXT(target: GLenum, index: GLuint, data: ptr GLint)
  proc DepthBoundsdNV(zmin: GLdouble, zmax: GLdouble)
  proc End()
  proc BindBufferBaseEXT(target: GLenum, index: GLuint, buffer: GLuint)
  proc VertexAttribDivisor(index: GLuint, divisor: GLuint)
  proc FogCoorddEXT(coord: GLdouble)
  proc FrontFace(mode: GLenum)
  proc VertexAttrib1hNV(index: GLuint, x: GLhalfNv)
  proc NamedProgramLocalParametersI4uivEXT(program: GLuint, target: GLenum, index: GLuint, count: GLsizei, params: ptr GLuint)
  proc TexCoord1dv(v: ptr GLdouble)
  proc BindVideoCaptureStreamTextureNV(video_capture_slot: GLuint, stream: GLuint, frame_region: GLenum, target: GLenum, texture: GLuint)
  proc WindowPos2iARB(x: GLint, y: GLint)
  proc VertexAttribFormatNV(index: GLuint, size: GLint, `type`: GLenum, normalized: GLboolean, stride: GLsizei)
  proc Uniform1uivEXT(location: GLint, count: GLsizei, value: ptr GLuint)
  proc GetVideoivNV(video_slot: GLuint, pname: GLenum, params: ptr GLint)
  proc VertexAttrib3fvARB(index: GLuint, v: ptr GLfloat)
  proc VertexArraySecondaryColorOffsetEXT(vaobj: GLuint, buffer: GLuint, size: GLint, `type`: GLenum, stride: GLsizei, offset: GLintptr)
  proc SecondaryColor3bv(v: ptr GLbyte)
  proc DispatchComputeGroupSizeARB(num_groups_x: GLuint, num_groups_y: GLuint, num_groups_z: GLuint, group_size_x: GLuint, group_size_y: GLuint, group_size_z: GLuint)
  proc NamedCopyBufferSubDataEXT(readBuffer: GLuint, writeBuffer: GLuint, readOffset: GLintptr, writeOffset: GLintptr, size: GLsizeiptr)
  proc SampleCoverage(value: GLfloat, invert: GLboolean)
  proc GetnMapfvARB(target: GLenum, query: GLenum, bufSize: GLsizei, v: ptr GLfloat)
  proc VertexStream2svATI(stream: GLenum, coords: ptr GLshort)
  proc ProgramParameters4fvNV(target: GLenum, index: GLuint, count: GLsizei, v: ptr GLfloat)
  proc VertexAttrib4fARB(index: GLuint, x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat)
  proc Indexd(c: GLdouble)
  proc GetInteger64v(pname: GLenum, params: ptr GLint64)
  proc GetMultiTexImageEXT(texunit: GLenum, target: GLenum, level: GLint, format: GLenum, `type`: GLenum, pixels: pointer)
  proc LightModelx(pname: GLenum, param: GLfixed)
  proc Map2f(target: GLenum, u1: GLfloat, u2: GLfloat, ustride: GLint, uorder: GLint, v1: GLfloat, v2: GLfloat, vstride: GLint, vorder: GLint, points: ptr GLfloat)
  proc SecondaryColorPointerListIBM(size: GLint, `type`: GLenum, stride: GLint, `pointer`: ptr pointer, ptrstride: GLint)
  proc VertexArrayVertexAttribIOffsetEXT(vaobj: GLuint, buffer: GLuint, index: GLuint, size: GLint, `type`: GLenum, stride: GLsizei, offset: GLintptr)
  proc ProgramUniformHandleui64vARB(program: GLuint, location: GLint, count: GLsizei, values: ptr GLuint64)
  proc ActiveProgramEXT(program: GLuint)
  proc ProgramUniformMatrix4x3fv(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat)
  proc CompressedTexSubImage3DARB(target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, format: GLenum, imageSize: GLsizei, data: pointer)
  proc BindProgramPipelineEXT(pipeline: GLuint)
  proc DetailTexFuncSGIS(target: GLenum, n: GLsizei, points: ptr GLfloat)
  proc SecondaryColor3ubEXT(red: GLubyte, green: GLubyte, blue: GLubyte)
  proc DrawArraysInstanced(mode: GLenum, first: GLint, count: GLsizei, instancecount: GLsizei)
  proc WindowPos3fARB(x: GLfloat, y: GLfloat, z: GLfloat)
  proc NamedProgramLocalParameter4fEXT(program: GLuint, target: GLenum, index: GLuint, x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat)
  proc TextureParameterfvEXT(texture: GLuint, target: GLenum, pname: GLenum, params: ptr GLfloat)
  proc ProgramUniformHandleui64ARB(program: GLuint, location: GLint, value: GLuint64)
  proc HistogramEXT(target: GLenum, width: GLsizei, internalformat: GLenum, sink: GLboolean)
  proc ResumeTransformFeedbackNV()
  proc GetMaterialxv(face: GLenum, pname: GLenum, params: ptr GLfixed)
  proc MultiTexCoord1sv(target: GLenum, v: ptr GLshort)
  proc ReadInstrumentsSGIX(marker: GLint)
  proc TexCoord4hNV(s: GLhalfNv, t: GLhalfNv, r: GLhalfNv, q: GLhalfNv)
  proc VertexAttribL4i64vNV(index: GLuint, v: ptr GLint64Ext)
  proc EnableVariantClientStateEXT(id: GLuint)
  proc SyncTextureINTEL(texture: GLuint)
  proc GetObjectPtrLabel(`ptr`: ptr pointer, bufSize: GLsizei, length: ptr GLsizei, label: cstring)
  proc CopyTexSubImage1D(target: GLenum, level: GLint, xoffset: GLint, x: GLint, y: GLint, width: GLsizei)
  proc OrthofOES(left: GLfloat, right: GLfloat, bottom: GLfloat, top: GLfloat, nearVal: GLfloat, farVal: GLfloat)
  proc WindowPos3sARB(x: GLshort, y: GLshort, z: GLshort)
  proc IsBufferARB(buffer: GLuint): GLboolean
  proc Color3sv(v: ptr GLshort)
  proc EvalMesh1(mode: GLenum, i1: GLint, i2: GLint)
  proc MultiDrawArrays(mode: GLenum, first: ptr GLint, count: ptr GLsizei, drawcount: GLsizei)
  proc GetMultiTexEnvfvEXT(texunit: GLenum, target: GLenum, pname: GLenum, params: ptr GLfloat)
  proc WindowPos3fMESA(x: GLfloat, y: GLfloat, z: GLfloat)
  proc ExtGetFramebuffersQCOM(framebuffers: ptr GLuint, maxFramebuffers: GLint, numFramebuffers: ptr GLint)
  proc TexSubImage3D(target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, format: GLenum, `type`: GLenum, pixels: pointer)
  proc VertexAttrib4uiv(index: GLuint, v: ptr GLuint)
  proc ProgramUniformui64NV(program: GLuint, location: GLint, value: GLuint64Ext)
  proc MultiTexCoord2ivARB(target: GLenum, v: ptr GLint)
  proc ProgramUniform4i64NV(program: GLuint, location: GLint, x: GLint64Ext, y: GLint64Ext, z: GLint64Ext, w: GLint64Ext)
  proc WindowPos2svMESA(v: ptr GLshort)
  proc VertexAttrib3dv(index: GLuint, v: ptr GLdouble)
  proc Color4i(red: GLint, green: GLint, blue: GLint, alpha: GLint)
  proc ClampColor(target: GLenum, clamp: GLenum)
  proc VertexP2ui(`type`: GLenum, value: GLuint)
  proc GenQueries(n: GLsizei, ids: ptr GLuint)
  proc BindBufferOffsetNV(target: GLenum, index: GLuint, buffer: GLuint, offset: GLintptr)
  proc GetFragDataLocation(program: GLuint, name: cstring): GLint
  proc VertexAttribs2svNV(index: GLuint, count: GLsizei, v: ptr GLshort)
  proc GetPathLengthNV(path: GLuint, startSegment: GLsizei, numSegments: GLsizei): GLfloat
  proc VertexAttrib3dARB(index: GLuint, x: GLdouble, y: GLdouble, z: GLdouble)
  proc MultiTexGenfvEXT(texunit: GLenum, coord: GLenum, pname: GLenum, params: ptr GLfloat)
  proc FlushPixelDataRangeNV(target: GLenum)
  proc ReplacementCodeuiNormal3fVertex3fSUN(rc: GLuint, nx: GLfloat, ny: GLfloat, nz: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat)
  proc PathParameteriNV(path: GLuint, pname: GLenum, value: GLint)
  proc VertexAttribI2iEXT(index: GLuint, x: GLint, y: GLint)
  proc PixelStorei(pname: GLenum, param: GLint)
  proc GetNamedFramebufferParameterivEXT(framebuffer: GLuint, pname: GLenum, params: ptr GLint)
  proc GetTexEnvxv(target: GLenum, pname: GLenum, params: ptr GLfixed)
  proc PathStringNV(path: GLuint, format: GLenum, length: GLsizei, pathString: pointer)
  proc DepthMask(flag: GLboolean)
  proc CopyTexImage1D(target: GLenum, level: GLint, internalformat: GLenum, x: GLint, y: GLint, width: GLsizei, border: GLint)
  proc DepthRangexOES(n: GLfixed, f: GLfixed)
  proc Uniform2i64vNV(location: GLint, count: GLsizei, value: ptr GLint64Ext)
  proc SetFragmentShaderConstantATI(dst: GLuint, value: ptr GLfloat)
  proc AttachShader(program: GLuint, shader: GLuint)
  proc GetFramebufferParameterivEXT(framebuffer: GLuint, pname: GLenum, params: ptr GLint)
  proc PointParameteriNV(pname: GLenum, param: GLint)
  proc WindowPos2dMESA(x: GLdouble, y: GLdouble)
  proc GetTextureParameterfvEXT(texture: GLuint, target: GLenum, pname: GLenum, params: ptr GLfloat)
  proc TexBumpParameterfvATI(pname: GLenum, param: ptr GLfloat)
  proc CompressedTexImage1DARB(target: GLenum, level: GLint, internalformat: GLenum, width: GLsizei, border: GLint, imageSize: GLsizei, data: pointer)
  proc GetTexGendv(coord: GLenum, pname: GLenum, params: ptr GLdouble)
  proc GetFragmentMaterialfvSGIX(face: GLenum, pname: GLenum, params: ptr GLfloat)
  proc BeginConditionalRenderNVX(id: GLuint)
  proc LightModelxOES(pname: GLenum, param: GLfixed)
  proc TexCoord2xOES(s: GLfixed, t: GLfixed)
  proc ProgramUniformMatrix2x4fvEXT(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat)
  proc RasterPos2xvOES(coords: ptr GLfixed)
  proc GetMapiv(target: GLenum, query: GLenum, v: ptr GLint)
  proc GetImageHandleARB(texture: GLuint, level: GLint, layered: GLboolean, layer: GLint, format: GLenum): GLuint64
  proc VDPAURegisterVideoSurfaceNV(vdpSurface: pointer, target: GLenum, numTextureNames: GLsizei, textureNames: ptr GLuint): GLvdpauSurfaceNv
  proc VertexAttribL2dEXT(index: GLuint, x: GLdouble, y: GLdouble)
  proc VertexAttrib1dvNV(index: GLuint, v: ptr GLdouble)
  proc PollAsyncSGIX(markerp: ptr GLuint): GLint
  proc CullParameterfvEXT(pname: GLenum, params: ptr GLfloat)
  proc MakeNamedBufferResidentNV(buffer: GLuint, access: GLenum)
  proc PointParameterfSGIS(pname: GLenum, param: GLfloat)
  proc GenLists(range: GLsizei): GLuint
  proc GetTexBumpParameterfvATI(pname: GLenum, param: ptr GLfloat)
  proc CompressedMultiTexSubImage2DEXT(texunit: GLenum, target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, width: GLsizei, height: GLsizei, format: GLenum, imageSize: GLsizei, bits: pointer)
  proc FinishFenceNV(fence: GLuint)
  proc PointSize(size: GLfloat)
  proc CompressedTextureImage2DEXT(texture: GLuint, target: GLenum, level: GLint, internalformat: GLenum, width: GLsizei, height: GLsizei, border: GLint, imageSize: GLsizei, bits: pointer)
  proc GetUniformui64vNV(program: GLuint, location: GLint, params: ptr GLuint64Ext)
  proc GetMapControlPointsNV(target: GLenum, index: GLuint, `type`: GLenum, ustride: GLsizei, vstride: GLsizei, packed: GLboolean, points: pointer)
  proc GetPathColorGenfvNV(color: GLenum, pname: GLenum, value: ptr GLfloat)
  proc TexCoord2f(s: GLfloat, t: GLfloat)
  proc SampleMaski(index: GLuint, mask: GLbitfield)
  proc ReadBufferIndexedEXT(src: GLenum, index: GLint)
  proc CoverFillPathNV(path: GLuint, coverMode: GLenum)
  proc ColorTableParameterfvSGI(target: GLenum, pname: GLenum, params: ptr GLfloat)
  proc DeleteVertexArraysAPPLE(n: GLsizei, arrays: ptr GLuint)
  proc GetVertexAttribIiv(index: GLuint, pname: GLenum, params: ptr GLint)
  proc WeightbvARB(size: GLint, weights: ptr GLbyte)
  proc GetNamedBufferPointervEXT(buffer: GLuint, pname: GLenum, params: ptr pointer)
  proc TexCoordPointer(size: GLint, `type`: GLenum, stride: GLsizei, `pointer`: pointer)
  proc Color4fv(v: ptr GLfloat)
  proc GetnUniformfvARB(program: GLuint, location: GLint, bufSize: GLsizei, params: ptr GLfloat)
  proc MaterialxOES(face: GLenum, pname: GLenum, param: GLfixed)
  proc GetFixedv(pname: GLenum, params: ptr GLfixed)
  proc Materialf(face: GLenum, pname: GLenum, param: GLfloat)
  proc VideoCaptureStreamParameterfvNV(video_capture_slot: GLuint, stream: GLuint, pname: GLenum, params: ptr GLfloat)
  proc GetDebugMessageLogAMD(count: GLuint, bufsize: GLsizei, categories: ptr GLenum, severities: ptr GLuint, ids: ptr GLuint, lengths: ptr GLsizei, message: cstring): GLuint
  proc ProgramUniform2uiv(program: GLuint, location: GLint, count: GLsizei, value: ptr GLuint)
  proc MatrixMultTransposedEXT(mode: GLenum, m: ptr GLdouble)
  proc IsPointInStrokePathNV(path: GLuint, x: GLfloat, y: GLfloat): GLboolean
  proc Disable(cap: GLenum)
  proc CompileShader(shader: GLuint)
  proc LoadTransposeMatrixd(m: ptr GLdouble)
  proc GetMultiTexParameterIuivEXT(texunit: GLenum, target: GLenum, pname: GLenum, params: ptr GLuint)
  proc GetHistogram(target: GLenum, reset: GLboolean, format: GLenum, `type`: GLenum, values: pointer)
  proc MultiTexCoord3fvARB(target: GLenum, v: ptr GLfloat)
  proc Color4xvOES(components: ptr GLfixed)
  proc IsBuffer(buffer: GLuint): GLboolean
  proc Vertex2dv(v: ptr GLdouble)
  proc NamedProgramLocalParameterI4uivEXT(program: GLuint, target: GLenum, index: GLuint, params: ptr GLuint)
  proc PixelTexGenParameteriSGIS(pname: GLenum, param: GLint)
  proc BindVertexBuffers(first: GLuint, count: GLsizei, buffers: ptr GLuint, offsets: ptr GLintptr, strides: ptr GLsizei)
  proc Uniform1ui64vNV(location: GLint, count: GLsizei, value: ptr GLuint64Ext)
  proc Color4ub(red: GLubyte, green: GLubyte, blue: GLubyte, alpha: GLubyte)
  proc ConvolutionParameterfv(target: GLenum, pname: GLenum, params: ptr GLfloat)
  proc ReplacementCodeuiColor4fNormal3fVertex3fSUN(rc: GLuint, r: GLfloat, g: GLfloat, b: GLfloat, a: GLfloat, nx: GLfloat, ny: GLfloat, nz: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat)
  proc VertexAttribI2ui(index: GLuint, x: GLuint, y: GLuint)
  proc DeleteNamesAMD(identifier: GLenum, num: GLuint, names: ptr GLuint)
  proc PixelTransferxOES(pname: GLenum, param: GLfixed)
  proc VertexAttrib4ivARB(index: GLuint, v: ptr GLint)
  proc LightModeli(pname: GLenum, param: GLint)
  proc GetHistogramEXT(target: GLenum, reset: GLboolean, format: GLenum, `type`: GLenum, values: pointer)
  proc WindowPos3svMESA(v: ptr GLshort)
  proc RasterPos3iv(v: ptr GLint)
  proc CopyTextureSubImage3DEXT(texture: GLuint, target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, x: GLint, y: GLint, width: GLsizei, height: GLsizei)
  proc TextureStorage3DMultisampleEXT(texture: GLuint, target: GLenum, samples: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei, depth: GLsizei, fixedsamplelocations: GLboolean)
  proc IsNameAMD(identifier: GLenum, name: GLuint): GLboolean
  proc ProgramUniformMatrix3fv(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat)
  proc GetProgramParameterfvNV(target: GLenum, index: GLuint, pname: GLenum, params: ptr GLfloat)
  proc TexStorage3D(target: GLenum, levels: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei, depth: GLsizei)
  proc MultiTexCoord2xOES(texture: GLenum, s: GLfixed, t: GLfixed)
  proc WindowPos2fARB(x: GLfloat, y: GLfloat)
  proc GetProgramResourceIndex(program: GLuint, programInterface: GLenum, name: cstring): GLuint
  proc ProgramUniform2uivEXT(program: GLuint, location: GLint, count: GLsizei, value: ptr GLuint)
  proc MakeImageHandleNonResidentNV(handle: GLuint64)
  proc NamedProgramLocalParameter4fvEXT(program: GLuint, target: GLenum, index: GLuint, params: ptr GLfloat)
  proc InvalidateFramebuffer(target: GLenum, numAttachments: GLsizei, attachments: ptr GLenum)
  proc TexStorage3DMultisample(target: GLenum, samples: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei, depth: GLsizei, fixedsamplelocations: GLboolean)
  proc MapVertexAttrib2fAPPLE(index: GLuint, size: GLuint, u1: GLfloat, u2: GLfloat, ustride: GLint, uorder: GLint, v1: GLfloat, v2: GLfloat, vstride: GLint, vorder: GLint, points: ptr GLfloat)
  proc CombinerParameterfNV(pname: GLenum, param: GLfloat)
  proc CopyMultiTexImage2DEXT(texunit: GLenum, target: GLenum, level: GLint, internalformat: GLenum, x: GLint, y: GLint, width: GLsizei, height: GLsizei, border: GLint)
  proc BindVertexShaderEXT(id: GLuint)
  proc PathGlyphsNV(firstPathName: GLuint, fontTarget: GLenum, fontName: pointer, fontStyle: GLbitfield, numGlyphs: GLsizei, `type`: GLenum, charcodes: pointer, handleMissingGlyphs: GLenum, pathParameterTemplate: GLuint, emScale: GLfloat)
  proc ProgramLocalParametersI4uivNV(target: GLenum, index: GLuint, count: GLsizei, params: ptr GLuint)
  proc MultiTexCoord3hvNV(target: GLenum, v: ptr GLhalfNv)
  proc MultiTexCoordP2uiv(texture: GLenum, `type`: GLenum, coords: ptr GLuint)
  proc DisableVariantClientStateEXT(id: GLuint)
  proc GetTexLevelParameterxvOES(target: GLenum, level: GLint, pname: GLenum, params: ptr GLfixed)
  proc RasterPos2sv(v: ptr GLshort)
  proc WeightPathsNV(resultPath: GLuint, numPaths: GLsizei, paths: ptr GLuint, weights: ptr GLfloat)
  proc DrawBuffersNV(n: GLsizei, bufs: ptr GLenum)
  proc BindBufferARB(target: GLenum, buffer: GLuint)
  proc VariantbvEXT(id: GLuint, `addr`: ptr GLbyte)
  proc ColorP3uiv(`type`: GLenum, color: ptr GLuint)
  proc BlendEquationEXT(mode: GLenum)
  proc ProgramLocalParameterI4uivNV(target: GLenum, index: GLuint, params: ptr GLuint)
  proc RenderMode(mode: GLenum): GLint
  proc VertexStream4fATI(stream: GLenum, x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat)
  proc GetObjectLabelEXT(`type`: GLenum, `object`: GLuint, bufSize: GLsizei, length: ptr GLsizei, label: cstring)
  proc NamedFramebufferTexture3DEXT(framebuffer: GLuint, attachment: GLenum, textarget: GLenum, texture: GLuint, level: GLint, zoffset: GLint)
  proc LoadMatrixf(m: ptr GLfloat)
  proc GetQueryObjectuivEXT(id: GLuint, pname: GLenum, params: ptr GLuint)
  proc BindVideoCaptureStreamBufferNV(video_capture_slot: GLuint, stream: GLuint, frame_region: GLenum, offset: GLintPtrArb)
  proc MatrixOrthoEXT(mode: GLenum, left: GLdouble, right: GLdouble, bottom: GLdouble, top: GLdouble, zNear: GLdouble, zFar: GLdouble)
  proc BlendFunc(sfactor: GLenum, dfactor: GLenum)
  proc TexGenxvOES(coord: GLenum, pname: GLenum, params: ptr GLfixed)
  proc MatrixMode(mode: GLenum)
  proc ColorTableParameterivSGI(target: GLenum, pname: GLenum, params: ptr GLint)
  proc GetProgramInfoLog(program: GLuint, bufSize: GLsizei, length: ptr GLsizei, infoLog: cstring)
  proc GetSeparableFilter(target: GLenum, format: GLenum, `type`: GLenum, row: pointer, column: pointer, span: pointer)
  proc Fogfv(pname: GLenum, params: ptr GLfloat)
  proc DrawTexfvOES(coords: ptr GLfloat)
  proc ClipPlanexIMG(p: GLenum, eqn: ptr GLfixed)
  proc ResetHistogramEXT(target: GLenum)
  proc MemoryBarrier(barriers: GLbitfield)
  proc GetPixelMapusv(map: GLenum, values: ptr GLushort)
  proc EvalCoord2f(u: GLfloat, v: GLfloat)
  proc Uniform4uiv(location: GLint, count: GLsizei, value: ptr GLuint)
  proc IsProgramARB(program: GLuint): GLboolean
  proc PointParameterfv(pname: GLenum, params: ptr GLfloat)
  proc TexBuffer(target: GLenum, internalformat: GLenum, buffer: GLuint)
  proc VertexAttrib1s(index: GLuint, x: GLshort)
  proc RenderbufferStorageMultisampleEXT(target: GLenum, samples: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei)
  proc MapNamedBufferEXT(buffer: GLuint, access: GLenum)
  proc DebugMessageCallbackAMD(callback: GLdebugProcAmd, userParam: ptr pointer)
  proc GetTexEnvfv(target: GLenum, pname: GLenum, params: ptr GLfloat)
  proc VertexAttribI3uivEXT(index: GLuint, v: ptr GLuint)
  proc MultiTexEnvfEXT(texunit: GLenum, target: GLenum, pname: GLenum, param: GLfloat)
  proc GetUniformiv(program: GLuint, location: GLint, params: ptr GLint)
  proc ProgramLocalParameters4fvEXT(target: GLenum, index: GLuint, count: GLsizei, params: ptr GLfloat)
  proc StencilStrokePathInstancedNV(numPaths: GLsizei, pathNameType: GLenum, paths: pointer, pathBase: GLuint, reference: GLint, mask: GLuint, transformType: GLenum, transformValues: ptr GLfloat)
  proc BeginConditionalRender(id: GLuint, mode: GLenum)
  proc VertexAttribI3uiEXT(index: GLuint, x: GLuint, y: GLuint, z: GLuint)
  proc VDPAUMapSurfacesNV(numSurfaces: GLsizei, surfaces: ptr GLvdpauSurfaceNv)
  proc GetProgramResourceName(program: GLuint, programInterface: GLenum, index: GLuint, bufSize: GLsizei, length: ptr GLsizei, name: cstring)
  proc MultiTexCoord4f(target: GLenum, s: GLfloat, t: GLfloat, r: GLfloat, q: GLfloat)
  proc VertexAttrib2hNV(index: GLuint, x: GLhalfNv, y: GLhalfNv)
  proc DrawArraysInstancedNV(mode: GLenum, first: GLint, count: GLsizei, primcount: GLsizei)
  proc ClearAccum(red: GLfloat, green: GLfloat, blue: GLfloat, alpha: GLfloat)
  proc VertexAttribI4usv(index: GLuint, v: ptr GLushort)
  proc GetProgramNamedParameterfvNV(id: GLuint, len: GLsizei, name: ptr GLubyte, params: ptr GLfloat)
  proc TextureLightEXT(pname: GLenum)
  proc PathSubCoordsNV(path: GLuint, coordStart: GLsizei, numCoords: GLsizei, coordType: GLenum, coords: pointer)
  proc BindImageTexture(unit: GLuint, texture: GLuint, level: GLint, layered: GLboolean, layer: GLint, access: GLenum, format: GLenum)
  proc GenVertexArraysAPPLE(n: GLsizei, arrays: ptr GLuint)
  proc FogCoordf(coord: GLfloat)
  proc FrameTerminatorGREMEDY()
  proc ValidateProgramPipelineEXT(pipeline: GLuint)
  proc ScalexOES(x: GLfixed, y: GLfixed, z: GLfixed)
  proc ReplacementCodeuiColor3fVertex3fvSUN(rc: ptr GLuint, c: ptr GLfloat, v: ptr GLfloat)
  proc ProgramNamedParameter4dNV(id: GLuint, len: GLsizei, name: ptr GLubyte, x: GLdouble, y: GLdouble, z: GLdouble, w: GLdouble)
  proc MultiDrawElementsIndirectCountARB(mode: GLenum, `type`: GLenum, indirect: GLintptr, drawcount: GLintptr, maxdrawcount: GLsizei, stride: GLsizei)
  proc ReferencePlaneSGIX(equation: ptr GLdouble)
  proc NormalStream3iATI(stream: GLenum, nx: GLint, ny: GLint, nz: GLint)
  proc GetColorTableParameterfvEXT(target: GLenum, pname: GLenum, params: ptr GLfloat)
  proc GetAttribLocation(program: GLuint, name: cstring): GLint
  proc MultiTexParameterfEXT(texunit: GLenum, target: GLenum, pname: GLenum, param: GLfloat)
  proc GenFencesNV(n: GLsizei, fences: ptr GLuint)
  proc Uniform4dv(location: GLint, count: GLsizei, value: ptr GLdouble)
  proc GetTexLevelParameterfv(target: GLenum, level: GLint, pname: GLenum, params: ptr GLfloat)
  proc ProgramUniform1ivEXT(program: GLuint, location: GLint, count: GLsizei, value: ptr GLint)
  proc ProgramUniform1dvEXT(program: GLuint, location: GLint, count: GLsizei, value: ptr GLdouble)
  proc LoadTransposeMatrixdARB(m: ptr GLdouble)
  proc VertexAttrib2fvARB(index: GLuint, v: ptr GLfloat)
  proc MultiTexGendEXT(texunit: GLenum, coord: GLenum, pname: GLenum, param: GLdouble)
  proc ProgramUniformMatrix4x3dvEXT(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble)
  proc Uniform4ui(location: GLint, v0: GLuint, v1: GLuint, v2: GLuint, v3: GLuint)
  proc TexSubImage2D(target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, width: GLsizei, height: GLsizei, format: GLenum, `type`: GLenum, pixels: pointer)
  proc VertexAttrib3hNV(index: GLuint, x: GLhalfNv, y: GLhalfNv, z: GLhalfNv)
  proc RotatexOES(angle: GLfixed, x: GLfixed, y: GLfixed, z: GLfixed)
  proc GenTextures(n: GLsizei, textures: ptr GLuint)
  proc CheckFramebufferStatusOES(target: GLenum): GLenum
  proc GetVideoCaptureStreamdvNV(video_capture_slot: GLuint, stream: GLuint, pname: GLenum, params: ptr GLdouble)
  proc CompressedTextureSubImage1DEXT(texture: GLuint, target: GLenum, level: GLint, xoffset: GLint, width: GLsizei, format: GLenum, imageSize: GLsizei, bits: pointer)
  proc CurrentPaletteMatrixOES(matrixpaletteindex: GLuint)
  proc CompressedMultiTexSubImage1DEXT(texunit: GLenum, target: GLenum, level: GLint, xoffset: GLint, width: GLsizei, format: GLenum, imageSize: GLsizei, bits: pointer)
  proc Normal3d(nx: GLdouble, ny: GLdouble, nz: GLdouble)
  proc MultiTexCoord1fv(target: GLenum, v: ptr GLfloat)
  proc ProgramUniform2uiEXT(program: GLuint, location: GLint, v0: GLuint, v1: GLuint)
  proc MultiTexCoord3fARB(target: GLenum, s: GLfloat, t: GLfloat, r: GLfloat)
  proc RasterPos3xOES(x: GLfixed, y: GLfixed, z: GLfixed)
  proc EGLImageTargetRenderbufferStorageOES(target: GLenum, image: GLeglImageOes)
  proc GetAttribLocationARB(programObj: GLhandleArb, name: cstring): GLint
  proc ProgramNamedParameter4dvNV(id: GLuint, len: GLsizei, name: ptr GLubyte, v: ptr GLdouble)
  proc ProgramLocalParameterI4uiNV(target: GLenum, index: GLuint, x: GLuint, y: GLuint, z: GLuint, w: GLuint)
  proc NamedFramebufferTextureFaceEXT(framebuffer: GLuint, attachment: GLenum, texture: GLuint, level: GLint, face: GLenum)
  proc Indexf(c: GLfloat)
  proc ExtTexObjectStateOverrideiQCOM(target: GLenum, pname: GLenum, param: GLint)
  proc CoverageOperationNV(operation: GLenum)
  proc ColorP4uiv(`type`: GLenum, color: ptr GLuint)
  proc DeleteSync(sync: GLsync)
  proc GetHistogramParameterfvEXT(target: GLenum, pname: GLenum, params: ptr GLfloat)
  proc TexCoord4fColor4fNormal3fVertex4fSUN(s: GLfloat, t: GLfloat, p: GLfloat, q: GLfloat, r: GLfloat, g: GLfloat, b: GLfloat, a: GLfloat, nx: GLfloat, ny: GLfloat, nz: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat)
  proc EndPerfMonitorAMD(monitor: GLuint)
  proc GetInternalformati64v(target: GLenum, internalformat: GLenum, pname: GLenum, bufSize: GLsizei, params: ptr GLint64)
  proc GenNamesAMD(identifier: GLenum, num: GLuint, names: ptr GLuint)
  proc DrawElementsInstancedBaseVertexBaseInstance(mode: GLenum, count: GLsizei, `type`: GLenum, indices: ptr pointer, instancecount: GLsizei, basevertex: GLint, baseinstance: GLuint)
  proc MultiTexCoord4i(target: GLenum, s: GLint, t: GLint, r: GLint, q: GLint)
  proc VertexAttribL1dv(index: GLuint, v: ptr GLdouble)
  proc GetProgramNamedParameterdvNV(id: GLuint, len: GLsizei, name: ptr GLubyte, params: ptr GLdouble)
  proc SetLocalConstantEXT(id: GLuint, `type`: GLenum, `addr`: pointer)
  proc ProgramBinary(program: GLuint, binaryFormat: GLenum, binary: pointer, length: GLsizei)
  proc VideoCaptureNV(video_capture_slot: GLuint, sequence_num: ptr GLuint, capture_time: ptr GLuint64Ext): GLenum
  proc DebugMessageEnableAMD(category: GLenum, severity: GLenum, count: GLsizei, ids: ptr GLuint, enabled: GLboolean)
  proc VertexAttribI1i(index: GLuint, x: GLint)
  proc VertexWeighthNV(weight: GLhalfNv)
  proc TextureParameterIivEXT(texture: GLuint, target: GLenum, pname: GLenum, params: ptr GLint)
  proc ClipPlanefIMG(p: GLenum, eqn: ptr GLfloat)
  proc GetLightxv(light: GLenum, pname: GLenum, params: ptr GLfixed)
  proc GetAttachedObjectsARB(containerObj: GLhandleArb, maxCount: GLsizei, count: ptr GLsizei, obj: ptr GLhandleArb)
  proc VertexAttrib4fv(index: GLuint, v: ptr GLfloat)
  proc DisableVertexAttribArrayARB(index: GLuint)
  proc WindowPos3fvARB(v: ptr GLfloat)
  proc ClearDepthdNV(depth: GLdouble)
  proc MapParameterivNV(target: GLenum, pname: GLenum, params: ptr GLint)
  proc EndConditionalRenderNVX()
  proc GetFragmentLightivSGIX(light: GLenum, pname: GLenum, params: ptr GLint)
  proc ProgramUniformMatrix4fv(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat)
  proc VertexStream1iATI(stream: GLenum, x: GLint)
  proc ColorP3ui(`type`: GLenum, color: GLuint)
  proc GetLightxOES(light: GLenum, pname: GLenum, params: ptr GLfixed)
  proc GetLightiv(light: GLenum, pname: GLenum, params: ptr GLint)
  proc VertexStream3dATI(stream: GLenum, x: GLdouble, y: GLdouble, z: GLdouble)
  proc ProgramUniform1iEXT(program: GLuint, location: GLint, v0: GLint)
  proc SecondaryColorFormatNV(size: GLint, `type`: GLenum, stride: GLsizei)
  proc DrawElementsBaseVertex(mode: GLenum, count: GLsizei, `type`: GLenum, indices: pointer, basevertex: GLint)
  proc GenFencesAPPLE(n: GLsizei, fences: ptr GLuint)
  proc Binormal3svEXT(v: ptr GLshort)
  proc UseProgramStagesEXT(pipeline: GLuint, stages: GLbitfield, program: GLuint)
  proc DebugMessageCallbackKHR(callback: GLdebugProcKhr, userParam: ptr pointer)
  proc CopyMultiTexSubImage3DEXT(texunit: GLenum, target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, x: GLint, y: GLint, width: GLsizei, height: GLsizei)
  proc Color4hvNV(v: ptr GLhalfNv)
  proc FenceSync(condition: GLenum, flags: GLbitfield): GLsync
  proc TexCoordPointerListIBM(size: GLint, `type`: GLenum, stride: GLint, `pointer`: ptr pointer, ptrstride: GLint)
  proc PopName()
  proc Color3fVertex3fvSUN(c: ptr GLfloat, v: ptr GLfloat)
  proc GetUniformfv(program: GLuint, location: GLint, params: ptr GLfloat)
  proc MultiTexCoord2hNV(target: GLenum, s: GLhalfNv, t: GLhalfNv)
  proc Lightxv(light: GLenum, pname: GLenum, params: ptr GLfixed)
  proc VideoCaptureStreamParameterivNV(video_capture_slot: GLuint, stream: GLuint, pname: GLenum, params: ptr GLint)
  proc EvalCoord1xvOES(coords: ptr GLfixed)
  proc GetProgramEnvParameterIivNV(target: GLenum, index: GLuint, params: ptr GLint)
  proc ObjectPurgeableAPPLE(objectType: GLenum, name: GLuint, option: GLenum): GLenum
  proc RequestResidentProgramsNV(n: GLsizei, programs: ptr GLuint)
  proc IsImageHandleResidentNV(handle: GLuint64): GLboolean
  proc Color3hvNV(v: ptr GLhalfNv)
  proc MultiTexCoord2dARB(target: GLenum, s: GLdouble, t: GLdouble)
  proc DeletePathsNV(path: GLuint, range: GLsizei)
  proc VertexAttrib4Nsv(index: GLuint, v: ptr GLshort)
  proc TexEnvf(target: GLenum, pname: GLenum, param: GLfloat)
  proc GlobalAlphaFactoriSUN(factor: GLint)
  proc BlendColorEXT(red: GLfloat, green: GLfloat, blue: GLfloat, alpha: GLfloat)
  proc SecondaryColor3usvEXT(v: ptr GLushort)
  proc ProgramEnvParameterI4uiNV(target: GLenum, index: GLuint, x: GLuint, y: GLuint, z: GLuint, w: GLuint)
  proc TexImage4DSGIS(target: GLenum, level: GLint, internalformat: GLenum, width: GLsizei, height: GLsizei, depth: GLsizei, size4d: GLsizei, border: GLint, format: GLenum, `type`: GLenum, pixels: pointer)
  proc MatrixPushEXT(mode: GLenum)
  proc GetPixelTexGenParameterivSGIS(pname: GLenum, params: ptr GLint)
  proc VariantuivEXT(id: GLuint, `addr`: ptr GLuint)
  proc TexParameterfv(target: GLenum, pname: GLenum, params: ptr GLfloat)
  proc GetSubroutineUniformLocation(program: GLuint, shadertype: GLenum, name: cstring): GLint
  proc ProgramUniformMatrix3fvEXT(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat)
  proc DrawBuffersATI(n: GLsizei, bufs: ptr GLenum)
  proc GetVertexAttribivNV(index: GLuint, pname: GLenum, params: ptr GLint)
  proc MultiTexCoord4bvOES(texture: GLenum, coords: ptr GLbyte)
  proc CompressedTexSubImage1DARB(target: GLenum, level: GLint, xoffset: GLint, width: GLsizei, format: GLenum, imageSize: GLsizei, data: pointer)
  proc ClientActiveTexture(texture: GLenum)
  proc VertexAttrib2fARB(index: GLuint, x: GLfloat, y: GLfloat)
  proc ProgramUniform2fvEXT(program: GLuint, location: GLint, count: GLsizei, value: ptr GLfloat)
  proc GetBufferParameterui64vNV(target: GLenum, pname: GLenum, params: ptr GLuint64Ext)
  proc VertexStream3dvATI(stream: GLenum, coords: ptr GLdouble)
  proc ReplacementCodeuiNormal3fVertex3fvSUN(rc: ptr GLuint, n: ptr GLfloat, v: ptr GLfloat)
  proc VertexAttrib4svNV(index: GLuint, v: ptr GLshort)
  proc ClearBufferSubData(target: GLenum, internalformat: GLenum, offset: GLintptr, size: GLsizeiptr, format: GLenum, `type`: GLenum, data: ptr pointer)
  proc VertexStream2sATI(stream: GLenum, x: GLshort, y: GLshort)
  proc TextureImage2DEXT(texture: GLuint, target: GLenum, level: GLint, internalformat: GLint, width: GLsizei, height: GLsizei, border: GLint, format: GLenum, `type`: GLenum, pixels: pointer)
  proc GetListParameterfvSGIX(list: GLuint, pname: GLenum, params: ptr GLfloat)
  proc Uniform3uiv(location: GLint, count: GLsizei, value: ptr GLuint)
  proc IsTexture(texture: GLuint): GLboolean
  proc ObjectUnpurgeableAPPLE(objectType: GLenum, name: GLuint, option: GLenum): GLenum
  proc GetVertexAttribdv(index: GLuint, pname: GLenum, params: ptr GLdouble)
  proc GetPointeri_vEXT(pname: GLenum, index: GLuint, params: ptr pointer)
  proc SampleCoveragex(value: GLclampx, invert: GLboolean)
  proc Color3f(red: GLfloat, green: GLfloat, blue: GLfloat)
  proc GetnMapivARB(target: GLenum, query: GLenum, bufSize: GLsizei, v: ptr GLint)
  proc MakeTextureHandleResidentARB(handle: GLuint64)
  proc SecondaryColorP3ui(`type`: GLenum, color: GLuint)
  proc MultiTexCoord4sARB(target: GLenum, s: GLshort, t: GLshort, r: GLshort, q: GLshort)
  proc Uniform3i64NV(location: GLint, x: GLint64Ext, y: GLint64Ext, z: GLint64Ext)
  proc VDPAUGetSurfaceivNV(surface: GLvdpauSurfaceNv, pname: GLenum, bufSize: GLsizei, length: ptr GLsizei, values: ptr GLint)
  proc TexBufferEXT(target: GLenum, internalformat: GLenum, buffer: GLuint)
  proc VertexAttribI4ubvEXT(index: GLuint, v: ptr GLubyte)
  proc DeleteFramebuffersOES(n: GLsizei, framebuffers: ptr GLuint)
  proc Color3fVertex3fSUN(r: GLfloat, g: GLfloat, b: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat)
  proc CombinerInputNV(stage: GLenum, portion: GLenum, variable: GLenum, input: GLenum, mapping: GLenum, componentUsage: GLenum)
  proc PolygonOffsetEXT(factor: GLfloat, bias: GLfloat)
  proc WindowPos4dMESA(x: GLdouble, y: GLdouble, z: GLdouble, w: GLdouble)
  proc Vertex3f(x: GLfloat, y: GLfloat, z: GLfloat)
  proc TexCoord3f(s: GLfloat, t: GLfloat, r: GLfloat)
  proc MultiTexCoord1fARB(target: GLenum, s: GLfloat)
  proc VertexAttrib4f(index: GLuint, x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat)
  proc GetFragDataLocationEXT(program: GLuint, name: cstring): GLint
  proc FlushMappedNamedBufferRangeEXT(buffer: GLuint, offset: GLintptr, length: GLsizeiptr)
  proc VertexAttrib1sARB(index: GLuint, x: GLshort)
  proc BitmapxOES(width: GLsizei, height: GLsizei, xorig: GLfixed, yorig: GLfixed, xmove: GLfixed, ymove: GLfixed, bitmap: ptr GLubyte)
  proc EnableVertexArrayAttribEXT(vaobj: GLuint, index: GLuint)
  proc DeleteRenderbuffers(n: GLsizei, renderbuffers: ptr GLuint)
  proc FramebufferRenderbuffer(target: GLenum, attachment: GLenum, renderbuffertarget: GLenum, renderbuffer: GLuint)
  proc InvalidateTexImage(texture: GLuint, level: GLint)
  proc ProgramUniform2i64NV(program: GLuint, location: GLint, x: GLint64Ext, y: GLint64Ext)
  proc TextureImage3DMultisampleNV(texture: GLuint, target: GLenum, samples: GLsizei, internalFormat: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, fixedSampleLocations: GLboolean)
  proc ValidateProgram(program: GLuint)
  proc Uniform1dv(location: GLint, count: GLsizei, value: ptr GLdouble)
  proc NormalStream3dvATI(stream: GLenum, coords: ptr GLdouble)
  proc MultiDrawElementsIndirect(mode: GLenum, `type`: GLenum, indirect: ptr pointer, drawcount: GLsizei, stride: GLsizei)
  proc VertexBlendARB(count: GLint)
  proc IsSampler(sampler: GLuint): GLboolean
  proc VariantdvEXT(id: GLuint, `addr`: ptr GLdouble)
  proc ProgramUniformMatrix3x2fvEXT(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat)
  proc VertexStream4fvATI(stream: GLenum, coords: ptr GLfloat)
  proc OrthoxOES(left: GLfixed, right: GLfixed, bottom: GLfixed, top: GLfixed, nearVal: GLfixed, farVal: GLfixed)
  proc ColorFormatNV(size: GLint, `type`: GLenum, stride: GLsizei)
  proc FogCoordPointer(`type`: GLenum, stride: GLsizei, `pointer`: pointer)
  proc VertexAttrib3dvARB(index: GLuint, v: ptr GLdouble)
  proc Vertex3bOES(x: GLbyte, y: GLbyte)
  proc VertexAttribFormat(attribindex: GLuint, size: GLint, `type`: GLenum, normalized: GLboolean, relativeoffset: GLuint)
  proc TexCoord4fVertex4fSUN(s: GLfloat, t: GLfloat, p: GLfloat, q: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat)
  proc EnableDriverControlQCOM(driverControl: GLuint)
  proc PointParameteri(pname: GLenum, param: GLint)
  proc VertexAttribI2i(index: GLuint, x: GLint, y: GLint)
  proc GetDriverControlStringQCOM(driverControl: GLuint, bufSize: GLsizei, length: ptr GLsizei, driverControlString: cstring)
  proc GetTexLevelParameteriv(target: GLenum, level: GLint, pname: GLenum, params: ptr GLint)
  proc GetHandleARB(pname: GLenum): GLhandleArb
  proc Indexubv(c: ptr GLubyte)
  proc BlendFunciARB(buf: GLuint, src: GLenum, dst: GLenum)
  proc Color4usv(v: ptr GLushort)
  proc BlendEquationSeparateOES(modeRgb: GLenum, modeAlpha: GLenum)
  proc VertexAttribI4ui(index: GLuint, x: GLuint, y: GLuint, z: GLuint, w: GLuint)
  proc ProgramUniform3f(program: GLuint, location: GLint, v0: GLfloat, v1: GLfloat, v2: GLfloat)
  proc VertexAttribL3i64vNV(index: GLuint, v: ptr GLint64Ext)
  proc WeightdvARB(size: GLint, weights: ptr GLdouble)
  proc VertexArrayRangeAPPLE(length: GLsizei, `pointer`: pointer)
  proc MapGrid2d(un: GLint, u1: GLdouble, u2: GLdouble, vn: GLint, v1: GLdouble, v2: GLdouble)
  proc Fogiv(pname: GLenum, params: ptr GLint)
  proc Uniform2f(location: GLint, v0: GLfloat, v1: GLfloat)
  proc GetDoublei_v(target: GLenum, index: GLuint, data: ptr GLdouble)
  proc GetVertexAttribfv(index: GLuint, pname: GLenum, params: ptr GLfloat)
  proc VertexAttribI2ivEXT(index: GLuint, v: ptr GLint)
  proc IsProgramNV(id: GLuint): GLboolean
  proc TexCoord1hNV(s: GLhalfNv)
  proc MinSampleShadingARB(value: GLfloat)
  proc MultiDrawElements(mode: GLenum, count: ptr GLsizei, `type`: GLenum, indices: ptr pointer, drawcount: GLsizei)
  proc GetQueryObjectuiv(id: GLuint, pname: GLenum, params: ptr GLuint)
  proc ReadBuffer(mode: GLenum)
  proc MultiTexCoordP3uiv(texture: GLenum, `type`: GLenum, coords: ptr GLuint)
  proc UniformMatrix3x2fv(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat)
  proc BindRenderbuffer(target: GLenum, renderbuffer: GLuint)
  proc Binormal3sEXT(bx: GLshort, by: GLshort, bz: GLshort)
  proc Uniform4iARB(location: GLint, v0: GLint, v1: GLint, v2: GLint, v3: GLint)
  proc GetUniformOffsetEXT(program: GLuint, location: GLint): GLintptr
  proc DeleteLists(list: GLuint, range: GLsizei)
  proc VertexAttribI1iEXT(index: GLuint, x: GLint)
  proc FramebufferTexture1D(target: GLenum, attachment: GLenum, textarget: GLenum, texture: GLuint, level: GLint)
  proc VertexAttribI2uiv(index: GLuint, v: ptr GLuint)
  proc BindFragDataLocation(program: GLuint, color: GLuint, name: cstring)
  proc ClearStencil(s: GLint)
  proc VertexAttrib4Nubv(index: GLuint, v: ptr GLubyte)
  proc ConvolutionFilter2DEXT(target: GLenum, internalformat: GLenum, width: GLsizei, height: GLsizei, format: GLenum, `type`: GLenum, image: pointer)
  proc GenFramebuffersEXT(n: GLsizei, framebuffers: ptr GLuint)
  proc FogCoordfvEXT(coord: ptr GLfloat)
  proc GetRenderbufferParameterivEXT(target: GLenum, pname: GLenum, params: ptr GLint)
  proc VertexAttribs1fvNV(index: GLuint, count: GLsizei, v: ptr GLfloat)
  proc TexCoord2fColor3fVertex3fSUN(s: GLfloat, t: GLfloat, r: GLfloat, g: GLfloat, b: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat)
  proc RasterPos3i(x: GLint, y: GLint, z: GLint)
  proc MultiTexSubImage2DEXT(texunit: GLenum, target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, width: GLsizei, height: GLsizei, format: GLenum, `type`: GLenum, pixels: pointer)
  proc ConvolutionParameteriEXT(target: GLenum, pname: GLenum, params: GLint)
  proc VertexAttribI4iEXT(index: GLuint, x: GLint, y: GLint, z: GLint, w: GLint)
  proc VertexAttribL2i64vNV(index: GLuint, v: ptr GLint64Ext)
  proc BlendColor(red: GLfloat, green: GLfloat, blue: GLfloat, alpha: GLfloat)
  proc GetPathColorGenivNV(color: GLenum, pname: GLenum, value: ptr GLint)
  proc CompressedTextureImage1DEXT(texture: GLuint, target: GLenum, level: GLint, internalformat: GLenum, width: GLsizei, border: GLint, imageSize: GLsizei, bits: pointer)
  proc DrawElementsInstanced(mode: GLenum, count: GLsizei, `type`: GLenum, indices: pointer, instancecount: GLsizei)
  proc FogCoordd(coord: GLdouble)
  proc TexParameterxvOES(target: GLenum, pname: GLenum, params: ptr GLfixed)
  proc WindowPos3svARB(v: ptr GLshort)
  proc GetVertexArrayPointervEXT(vaobj: GLuint, pname: GLenum, param: ptr pointer)
  proc DrawTextureNV(texture: GLuint, sampler: GLuint, x0: GLfloat, y0: GLfloat, x1: GLfloat, y1: GLfloat, z: GLfloat, s0: GLfloat, t0: GLfloat, s1: GLfloat, t1: GLfloat)
  proc UniformMatrix2dv(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble)
  proc TexImage3DOES(target: GLenum, level: GLint, internalformat: GLenum, width: GLsizei, height: GLsizei, depth: GLsizei, border: GLint, format: GLenum, `type`: GLenum, pixels: pointer)
  proc ClampColorARB(target: GLenum, clamp: GLenum)
  proc TexParameteri(target: GLenum, pname: GLenum, param: GLint)
  proc WindowPos4svMESA(v: ptr GLshort)
  proc MultiTexCoordP4ui(texture: GLenum, `type`: GLenum, coords: GLuint)
  proc VertexP4uiv(`type`: GLenum, value: ptr GLuint)
  proc ProgramUniform4iEXT(program: GLuint, location: GLint, v0: GLint, v1: GLint, v2: GLint, v3: GLint)
  proc TexCoord3xvOES(coords: ptr GLfixed)
  proc CopyTexImage2DEXT(target: GLenum, level: GLint, internalformat: GLenum, x: GLint, y: GLint, width: GLsizei, height: GLsizei, border: GLint)
  proc GenSamplers(count: GLsizei, samplers: ptr GLuint)
  proc RasterPos4iv(v: ptr GLint)
  proc WindowPos4sMESA(x: GLshort, y: GLshort, z: GLshort, w: GLshort)
  proc ProgramUniform2dvEXT(program: GLuint, location: GLint, count: GLsizei, value: ptr GLdouble)
  proc PrioritizeTexturesEXT(n: GLsizei, textures: ptr GLuint, priorities: ptr GLclampf)
  proc Rects(x1: GLshort, y1: GLshort, x2: GLshort, y2: GLshort)
  proc MultiDrawElementsBaseVertex(mode: GLenum, count: ptr GLsizei, `type`: GLenum, indices: ptr pointer, drawcount: GLsizei, basevertex: ptr GLint)
  proc ProgramBinaryOES(program: GLuint, binaryFormat: GLenum, binary: pointer, length: GLint)
  proc ReplacementCodeuiTexCoord2fColor4fNormal3fVertex3fvSUN(rc: ptr GLuint, tc: ptr GLfloat, c: ptr GLfloat, n: ptr GLfloat, v: ptr GLfloat)
  proc GetMinmaxParameterfv(target: GLenum, pname: GLenum, params: ptr GLfloat)
  proc Color4fNormal3fVertex3fSUN(r: GLfloat, g: GLfloat, b: GLfloat, a: GLfloat, nx: GLfloat, ny: GLfloat, nz: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat)
  proc WindowPos2d(x: GLdouble, y: GLdouble)
  proc GetPerfMonitorGroupStringAMD(group: GLuint, bufSize: GLsizei, length: ptr GLsizei, groupString: cstring)
  proc UniformHandleui64vNV(location: GLint, count: GLsizei, value: ptr GLuint64)
  proc BlendEquation(mode: GLenum)
  proc MapBufferARB(target: GLenum, access: GLenum)
  proc GetMaterialxvOES(face: GLenum, pname: GLenum, params: ptr GLfixed)
  proc VertexAttribI1ivEXT(index: GLuint, v: ptr GLint)
  proc TexCoord4hvNV(v: ptr GLhalfNv)
  proc VertexArrayVertexAttribLOffsetEXT(vaobj: GLuint, buffer: GLuint, index: GLuint, size: GLint, `type`: GLenum, stride: GLsizei, offset: GLintptr)
  proc ExtGetShadersQCOM(shaders: ptr GLuint, maxShaders: GLint, numShaders: ptr GLint)
  proc WindowPos4ivMESA(v: ptr GLint)
  proc VertexAttrib1sNV(index: GLuint, x: GLshort)
  proc NormalStream3ivATI(stream: GLenum, coords: ptr GLint)
  proc SecondaryColor3fEXT(red: GLfloat, green: GLfloat, blue: GLfloat)
  proc VertexArrayFogCoordOffsetEXT(vaobj: GLuint, buffer: GLuint, `type`: GLenum, stride: GLsizei, offset: GLintptr)
  proc GetTextureImageEXT(texture: GLuint, target: GLenum, level: GLint, format: GLenum, `type`: GLenum, pixels: pointer)
  proc VertexAttrib4hNV(index: GLuint, x: GLhalfNv, y: GLhalfNv, z: GLhalfNv, w: GLhalfNv)
  proc ReplacementCodeusSUN(code: GLushort)
  proc PixelTexGenSGIX(mode: GLenum)
  proc MultiDrawRangeElementArrayAPPLE(mode: GLenum, start: GLuint, `end`: GLuint, first: ptr GLint, count: ptr GLsizei, primcount: GLsizei)
  proc DrawElements(mode: GLenum, count: GLsizei, `type`: GLenum, indices: pointer)
  proc TexCoord1hvNV(v: ptr GLhalfNv)
  proc GetPixelMapuiv(map: GLenum, values: ptr GLuint)
  proc RasterPos4d(x: GLdouble, y: GLdouble, z: GLdouble, w: GLdouble)
  proc TexImage1D(target: GLenum, level: GLint, internalformat: GLint, width: GLsizei, border: GLint, format: GLenum, `type`: GLenum, pixels: pointer)
  proc ConvolutionParameterxOES(target: GLenum, pname: GLenum, param: GLfixed)
  proc SecondaryColor3dEXT(red: GLdouble, green: GLdouble, blue: GLdouble)
  proc GetCombinerOutputParameterivNV(stage: GLenum, portion: GLenum, pname: GLenum, params: ptr GLint)
  proc QueryCounter(id: GLuint, target: GLenum)
  proc GetUniformi64vNV(program: GLuint, location: GLint, params: ptr GLint64Ext)
  proc TexCoord2fv(v: ptr GLfloat)
  proc WindowPos3d(x: GLdouble, y: GLdouble, z: GLdouble)
  proc BlendFuncSeparateINGR(sfactorRgb: GLenum, dfactorRgb: GLenum, sfactorAlpha: GLenum, dfactorAlpha: GLenum)
  proc TextureNormalEXT(mode: GLenum)
  proc VertexStream2fATI(stream: GLenum, x: GLfloat, y: GLfloat)
  proc ViewportIndexedf(index: GLuint, x: GLfloat, y: GLfloat, w: GLfloat, h: GLfloat)
  proc MultiTexCoord4ivARB(target: GLenum, v: ptr GLint)
  proc BindBufferOffsetEXT(target: GLenum, index: GLuint, buffer: GLuint, offset: GLintptr)
  proc TexCoord3sv(v: ptr GLshort)
  proc VertexArrayVertexAttribBindingEXT(vaobj: GLuint, attribindex: GLuint, bindingindex: GLuint)
  proc VertexAttrib2f(index: GLuint, x: GLfloat, y: GLfloat)
  proc MultiTexGenivEXT(texunit: GLenum, coord: GLenum, pname: GLenum, params: ptr GLint)
  proc Uniformui64vNV(location: GLint, count: GLsizei, value: ptr GLuint64Ext)
  proc GetInfoLogARB(obj: GLhandleArb, maxLength: GLsizei, length: ptr GLsizei, infoLog: cstring)
  proc GetNamedProgramLocalParameterIivEXT(program: GLuint, target: GLenum, index: GLuint, params: ptr GLint)
  proc VertexAttrib4s(index: GLuint, x: GLshort, y: GLshort, z: GLshort, w: GLshort)
  proc UniformMatrix4x2dv(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble)
  proc VertexAttribs3dvNV(index: GLuint, count: GLsizei, v: ptr GLdouble)
  proc SecondaryColor3dvEXT(v: ptr GLdouble)
  proc TextureRenderbufferEXT(texture: GLuint, target: GLenum, renderbuffer: GLuint)
  proc VertexAttribL2ui64vNV(index: GLuint, v: ptr GLuint64Ext)
  proc BlendFuncSeparateOES(srcRgb: GLenum, dstRgb: GLenum, srcAlpha: GLenum, dstAlpha: GLenum)
  proc VertexAttribDivisorARB(index: GLuint, divisor: GLuint)
  proc WindowPos2sv(v: ptr GLshort)
  proc MultiTexCoord3svARB(target: GLenum, v: ptr GLshort)
  proc CombinerParameterfvNV(pname: GLenum, params: ptr GLfloat)
  proc GetImageTransformParameterfvHP(target: GLenum, pname: GLenum, params: ptr GLfloat)
  proc TexParameteriv(target: GLenum, pname: GLenum, params: ptr GLint)
  proc GetArrayObjectivATI(`array`: GLenum, pname: GLenum, params: ptr GLint)
  proc GetTexParameterIuiv(target: GLenum, pname: GLenum, params: ptr GLuint)
  proc GetProgramPipelineInfoLog(pipeline: GLuint, bufSize: GLsizei, length: ptr GLsizei, infoLog: cstring)
  proc GetOcclusionQueryuivNV(id: GLuint, pname: GLenum, params: ptr GLuint)
  proc VertexAttrib4bvARB(index: GLuint, v: ptr GLbyte)
  proc ListParameterfvSGIX(list: GLuint, pname: GLenum, params: ptr GLfloat)
  proc DeleteSamplers(count: GLsizei, samplers: ptr GLuint)
  proc NormalStream3dATI(stream: GLenum, nx: GLdouble, ny: GLdouble, nz: GLdouble)
  proc ProgramUniform4i64vNV(program: GLuint, location: GLint, count: GLsizei, value: ptr GLint64Ext)
  proc BlendFuncSeparateiARB(buf: GLuint, srcRgb: GLenum, dstRgb: GLenum, srcAlpha: GLenum, dstAlpha: GLenum)
  proc EndTransformFeedbackEXT()
  proc MultiTexCoord3i(target: GLenum, s: GLint, t: GLint, r: GLint)
  proc MakeBufferResidentNV(target: GLenum, access: GLenum)
  proc Tangent3dvEXT(v: ptr GLdouble)
  proc MatrixPopEXT(mode: GLenum)
  proc VertexAttrib4NivARB(index: GLuint, v: ptr GLint)
  proc ProgramUniform2ui64NV(program: GLuint, location: GLint, x: GLuint64Ext, y: GLuint64Ext)
  proc WeightPointerARB(size: GLint, `type`: GLenum, stride: GLsizei, `pointer`: pointer)
  proc CullParameterdvEXT(pname: GLenum, params: ptr GLdouble)
  proc FramebufferTexture2D(target: GLenum, attachment: GLenum, textarget: GLenum, texture: GLuint, level: GLint)
  proc GenVertexArrays(n: GLsizei, arrays: ptr GLuint)
  proc UniformHandleui64NV(location: GLint, value: GLuint64)
  proc IndexPointer(`type`: GLenum, stride: GLsizei, `pointer`: pointer)
  proc GetProgramSubroutineParameteruivNV(target: GLenum, index: GLuint, param: ptr GLuint)
  proc VertexAttrib1svARB(index: GLuint, v: ptr GLshort)
  proc DetachObjectARB(containerObj: GLhandleArb, attachedObj: GLhandleArb)
  proc CompressedTexImage3D(target: GLenum, level: GLint, internalformat: GLenum, width: GLsizei, height: GLsizei, depth: GLsizei, border: GLint, imageSize: GLsizei, data: pointer)
  proc BlendFuncSeparate(sfactorRgb: GLenum, dfactorRgb: GLenum, sfactorAlpha: GLenum, dfactorAlpha: GLenum)
  proc ExecuteProgramNV(target: GLenum, id: GLuint, params: ptr GLfloat)
  proc AttachObjectARB(containerObj: GLhandleArb, obj: GLhandleArb)
  proc CompressedTexSubImage1D(target: GLenum, level: GLint, xoffset: GLint, width: GLsizei, format: GLenum, imageSize: GLsizei, data: pointer)
  proc ProgramUniform4iv(program: GLuint, location: GLint, count: GLsizei, value: ptr GLint)
  proc VertexAttrib3sv(index: GLuint, v: ptr GLshort)
  proc TexCoord3bvOES(coords: ptr GLbyte)
  proc GenTexturesEXT(n: GLsizei, textures: ptr GLuint)
  proc Color4f(red: GLfloat, green: GLfloat, blue: GLfloat, alpha: GLfloat)
  proc GetFramebufferAttachmentParameterivOES(target: GLenum, attachment: GLenum, pname: GLenum, params: ptr GLint)
  proc ClearColor(red: GLfloat, green: GLfloat, blue: GLfloat, alpha: GLfloat)
  proc NamedProgramLocalParametersI4ivEXT(program: GLuint, target: GLenum, index: GLuint, count: GLsizei, params: ptr GLint)
  proc MakeImageHandleNonResidentARB(handle: GLuint64)
  proc GenRenderbuffers(n: GLsizei, renderbuffers: ptr GLuint)
  proc VertexAttribL1ui64vARB(index: GLuint, v: ptr GLuint64Ext)
  proc BindFramebufferEXT(target: GLenum, framebuffer: GLuint)
  proc ProgramUniform2dEXT(program: GLuint, location: GLint, x: GLdouble, y: GLdouble)
  proc CompressedMultiTexImage2DEXT(texunit: GLenum, target: GLenum, level: GLint, internalformat: GLenum, width: GLsizei, height: GLsizei, border: GLint, imageSize: GLsizei, bits: pointer)
  proc DeleteSyncAPPLE(sync: GLsync)
  proc DebugMessageInsertAMD(category: GLenum, severity: GLenum, id: GLuint, length: GLsizei, buf: cstring)
  proc SecondaryColorPointerEXT(size: GLint, `type`: GLenum, stride: GLsizei, `pointer`: pointer)
  proc TextureImage2DMultisampleNV(texture: GLuint, target: GLenum, samples: GLsizei, internalFormat: GLint, width: GLsizei, height: GLsizei, fixedSampleLocations: GLboolean)
  proc BeginFragmentShaderATI()
  proc ClearDepth(depth: GLdouble)
  proc BindTextures(first: GLuint, count: GLsizei, textures: ptr GLuint)
  proc EvalCoord1d(u: GLdouble)
  proc SecondaryColor3b(red: GLbyte, green: GLbyte, blue: GLbyte)
  proc ExtGetTexSubImageQCOM(target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, format: GLenum, `type`: GLenum, texels: pointer)
  proc ClearColorIiEXT(red: GLint, green: GLint, blue: GLint, alpha: GLint)
  proc Vertex2xOES(x: GLfixed)
  proc VertexAttrib2s(index: GLuint, x: GLshort, y: GLshort)
  proc UniformHandleui64vARB(location: GLint, count: GLsizei, value: ptr GLuint64)
  proc AreTexturesResidentEXT(n: GLsizei, textures: ptr GLuint, residences: ptr GLboolean): GLboolean
  proc DrawElementsInstancedBaseInstance(mode: GLenum, count: GLsizei, `type`: GLenum, indices: ptr pointer, instancecount: GLsizei, baseinstance: GLuint)
  proc GetString(name: GLenum): ptr GLubyte
  proc DrawTransformFeedbackStream(mode: GLenum, id: GLuint, stream: GLuint)
  proc SecondaryColor3uiv(v: ptr GLuint)
  proc NamedFramebufferParameteriEXT(framebuffer: GLuint, pname: GLenum, param: GLint)
  proc VertexAttrib4hvNV(index: GLuint, v: ptr GLhalfNv)
  proc GetnUniformuivARB(program: GLuint, location: GLint, bufSize: GLsizei, params: ptr GLuint)
  proc ProgramUniform4ui(program: GLuint, location: GLint, v0: GLuint, v1: GLuint, v2: GLuint, v3: GLuint)
  proc PointParameterxvOES(pname: GLenum, params: ptr GLfixed)
  proc IsEnabledi(target: GLenum, index: GLuint): GLboolean
  proc ColorPointerEXT(size: GLint, `type`: GLenum, stride: GLsizei, count: GLsizei, `pointer`: pointer)
  proc FragmentLightModelfvSGIX(pname: GLenum, params: ptr GLfloat)
  proc RasterPos3f(x: GLfloat, y: GLfloat, z: GLfloat)
  proc DeleteObjectARB(obj: GLhandleArb)
  proc SetFenceNV(fence: GLuint, condition: GLenum)
  proc TransformFeedbackAttribsNV(count: GLuint, attribs: ptr GLint, bufferMode: GLenum)
  proc ProgramUniformMatrix2fvEXT(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat)
  proc GetPointerv(pname: GLenum, params: ptr pointer)
  proc WindowPos2dvMESA(v: ptr GLdouble)
  proc TexImage2DMultisample(target: GLenum, samples: GLsizei, internalformat: GLint, width: GLsizei, height: GLsizei, fixedsamplelocations: GLboolean)
  proc GenFragmentShadersATI(range: GLuint): GLuint
  proc TexCoord4fv(v: ptr GLfloat)
  proc CompressedTexImage1D(target: GLenum, level: GLint, internalformat: GLenum, width: GLsizei, border: GLint, imageSize: GLsizei, data: pointer)
  proc GetNamedBufferSubDataEXT(buffer: GLuint, offset: GLintptr, size: GLsizeiptr, data: pointer)
  proc Finish()
  proc DeleteVertexShaderEXT(id: GLuint)
  proc FinishObjectAPPLE(`object`: GLenum, name: GLint)
  proc GetActiveAttribARB(programObj: GLhandleArb, index: GLuint, maxLength: GLsizei, length: ptr GLsizei, size: ptr GLint, `type`: ptr GLenum, name: cstring)
  proc PointParameterx(pname: GLenum, param: GLfixed)
  proc ProgramUniformui64vNV(program: GLuint, location: GLint, count: GLsizei, value: ptr GLuint64Ext)
  proc SecondaryColor3ubv(v: ptr GLubyte)
  proc GetProgramLocalParameterIivNV(target: GLenum, index: GLuint, params: ptr GLint)
  proc DeleteProgramPipelinesEXT(n: GLsizei, pipelines: ptr GLuint)
  proc VertexAttrib4fNV(index: GLuint, x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat)
  proc GetColorTableParameterfvSGI(target: GLenum, pname: GLenum, params: ptr GLfloat)
  proc GetFloati_v(target: GLenum, index: GLuint, data: ptr GLfloat)
  proc GenBuffers(n: GLsizei, buffers: ptr GLuint)
  proc Normal3b(nx: GLbyte, ny: GLbyte, nz: GLbyte)
  proc DrawArraysInstancedARB(mode: GLenum, first: GLint, count: GLsizei, primcount: GLsizei)
  proc TexStorage2DMultisample(target: GLenum, samples: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei, fixedsamplelocations: GLboolean)
  proc GetVariantIntegervEXT(id: GLuint, value: GLenum, data: ptr GLint)
  proc Color3ubv(v: ptr GLubyte)
  proc VertexAttribP4uiv(index: GLuint, `type`: GLenum, normalized: GLboolean, value: ptr GLuint)
  proc ProgramUniform2ivEXT(program: GLuint, location: GLint, count: GLsizei, value: ptr GLint)
  proc VertexStream4dATI(stream: GLenum, x: GLdouble, y: GLdouble, z: GLdouble, w: GLdouble)
  proc VertexAttribL2ui64NV(index: GLuint, x: GLuint64Ext, y: GLuint64Ext)
  proc SecondaryColor3bEXT(red: GLbyte, green: GLbyte, blue: GLbyte)
  proc GetBufferPointervOES(target: GLenum, pname: GLenum, params: ptr pointer)
  proc GetMaterialfv(face: GLenum, pname: GLenum, params: ptr GLfloat)
  proc VertexStream3sATI(stream: GLenum, x: GLshort, y: GLshort, z: GLshort)
  proc Uniform1i(location: GLint, v0: GLint)
  proc VertexAttribL2d(index: GLuint, x: GLdouble, y: GLdouble)
  proc TestObjectAPPLE(`object`: GLenum, name: GLuint): GLboolean
  proc GetTransformFeedbackVarying(program: GLuint, index: GLuint, bufSize: GLsizei, length: ptr GLsizei, size: ptr GLsizei, `type`: ptr GLenum, name: cstring)
  proc FramebufferRenderbufferOES(target: GLenum, attachment: GLenum, renderbuffertarget: GLenum, renderbuffer: GLuint)
  proc VertexStream3iATI(stream: GLenum, x: GLint, y: GLint, z: GLint)
  proc MakeTextureHandleNonResidentNV(handle: GLuint64)
  proc VertexAttrib4fvNV(index: GLuint, v: ptr GLfloat)
  proc ArrayElement(i: GLint)
  proc ClearBufferData(target: GLenum, internalformat: GLenum, format: GLenum, `type`: GLenum, data: ptr pointer)
  proc SecondaryColor3usEXT(red: GLushort, green: GLushort, blue: GLushort)
  proc RenderbufferStorageMultisample(target: GLenum, samples: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei)
  proc TexCoord2xvOES(coords: ptr GLfixed)
  proc WindowPos3f(x: GLfloat, y: GLfloat, z: GLfloat)
  proc Tangent3svEXT(v: ptr GLshort)
  proc PointParameterf(pname: GLenum, param: GLfloat)
  proc VertexAttribI4uivEXT(index: GLuint, v: ptr GLuint)
  proc ColorTableParameteriv(target: GLenum, pname: GLenum, params: ptr GLint)
  proc MatrixMultdEXT(mode: GLenum, m: ptr GLdouble)
  proc UseProgramStages(pipeline: GLuint, stages: GLbitfield, program: GLuint)
  proc VertexStream4sATI(stream: GLenum, x: GLshort, y: GLshort, z: GLshort, w: GLshort)
  proc DrawElementsInstancedNV(mode: GLenum, count: GLsizei, `type`: GLenum, indices: pointer, primcount: GLsizei)
  proc Uniform3d(location: GLint, x: GLdouble, y: GLdouble, z: GLdouble)
  proc DebugMessageControlARB(source: GLenum, `type`: GLenum, severity: GLenum, count: GLsizei, ids: ptr GLuint, enabled: GLboolean)
  proc VertexAttribs3svNV(index: GLuint, count: GLsizei, v: ptr GLshort)
  proc ElementPointerATI(`type`: GLenum, `pointer`: pointer)
  proc Color4fNormal3fVertex3fvSUN(c: ptr GLfloat, n: ptr GLfloat, v: ptr GLfloat)
  proc GetPerfMonitorCountersAMD(group: GLuint, numCounters: ptr GLint, maxActiveCounters: ptr GLint, counterSize: GLsizei, counters: ptr GLuint)
  proc DispatchCompute(num_groups_x: GLuint, num_groups_y: GLuint, num_groups_z: GLuint)
  proc VertexAttribDivisorNV(index: GLuint, divisor: GLuint)
  proc ProgramUniform3uiEXT(program: GLuint, location: GLint, v0: GLuint, v1: GLuint, v2: GLuint)
  proc RenderbufferStorageMultisampleNV(target: GLenum, samples: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei)
  proc BinormalPointerEXT(`type`: GLenum, stride: GLsizei, `pointer`: pointer)
  proc RectxvOES(v1: ptr GLfixed, v2: ptr GLfixed)
  proc GenVertexArraysOES(n: GLsizei, arrays: ptr GLuint)
  proc DebugMessageControlKHR(source: GLenum, `type`: GLenum, severity: GLenum, count: GLsizei, ids: ptr GLuint, enabled: GLboolean)
  proc ProgramUniform1uiEXT(program: GLuint, location: GLint, v0: GLuint)
  proc PixelTransferi(pname: GLenum, param: GLint)
  proc IsPointInFillPathNV(path: GLuint, mask: GLuint, x: GLfloat, y: GLfloat): GLboolean
  proc VertexBindingDivisor(bindingindex: GLuint, divisor: GLuint)
  proc GetVertexAttribLui64vARB(index: GLuint, pname: GLenum, params: ptr GLuint64Ext)
  proc ProgramUniformMatrix3dvEXT(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble)
  proc DrawBuffer(mode: GLenum)
  proc MultiTexCoord1sARB(target: GLenum, s: GLshort)
  proc SeparableFilter2DEXT(target: GLenum, internalformat: GLenum, width: GLsizei, height: GLsizei, format: GLenum, `type`: GLenum, row: pointer, column: pointer)
  proc Tangent3bvEXT(v: ptr GLbyte)
  proc TexParameterIuiv(target: GLenum, pname: GLenum, params: ptr GLuint)
  proc VertexAttribL4i64NV(index: GLuint, x: GLint64Ext, y: GLint64Ext, z: GLint64Ext, w: GLint64Ext)
  proc DebugMessageCallbackARB(callback: GLdebugProcArb, userParam: ptr pointer)
  proc MultiTexCoordP1uiv(texture: GLenum, `type`: GLenum, coords: ptr GLuint)
  proc LabelObjectEXT(`type`: GLenum, `object`: GLuint, length: GLsizei, label: cstring)
  proc GetnPolygonStippleARB(bufSize: GLsizei, pattern: ptr GLubyte)
  proc TexCoord3xOES(s: GLfixed, t: GLfixed, r: GLfixed)
  proc CopyPixels(x: GLint, y: GLint, width: GLsizei, height: GLsizei, `type`: GLenum)
  proc GetnUniformfvEXT(program: GLuint, location: GLint, bufSize: GLsizei, params: ptr GLfloat)
  proc ColorMaski(index: GLuint, r: GLboolean, g: GLboolean, b: GLboolean, a: GLboolean)
  proc RasterPos2fv(v: ptr GLfloat)
  proc BindBuffersBase(target: GLenum, first: GLuint, count: GLsizei, buffers: ptr GLuint)
  proc SpriteParameterfvSGIX(pname: GLenum, params: ptr GLfloat)
  proc GetSyncivAPPLE(sync: GLsync, pname: GLenum, bufSize: GLsizei, length: ptr GLsizei, values: ptr GLint)
  proc VertexAttribI3i(index: GLuint, x: GLint, y: GLint, z: GLint)
  proc PixelTransformParameteriEXT(target: GLenum, pname: GLenum, param: GLint)
  proc MultiDrawArraysEXT(mode: GLenum, first: ptr GLint, count: ptr GLsizei, primcount: GLsizei)
  proc GetTextureHandleNV(texture: GLuint): GLuint64
  proc TexCoordP2ui(`type`: GLenum, coords: GLuint)
  proc DeleteQueries(n: GLsizei, ids: ptr GLuint)
  proc GetVertexAttribArrayObjectivATI(index: GLuint, pname: GLenum, params: ptr GLint)
  proc VertexArrayVertexBindingDivisorEXT(vaobj: GLuint, bindingindex: GLuint, divisor: GLuint)
  proc Vertex3i(x: GLint, y: GLint, z: GLint)
  proc BlendEquationSeparatei(buf: GLuint, modeRgb: GLenum, modeAlpha: GLenum)
  proc GetMapAttribParameterivNV(target: GLenum, index: GLuint, pname: GLenum, params: ptr GLint)
  proc GetVideoCaptureivNV(video_capture_slot: GLuint, pname: GLenum, params: ptr GLint)
  proc FragmentMaterialfvSGIX(face: GLenum, pname: GLenum, params: ptr GLfloat)
  proc EGLImageTargetTexture2DOES(target: GLenum, image: GLeglImageOes)
  proc CopyImageSubDataNV(srcName: GLuint, srcTarget: GLenum, srcLevel: GLint, srcX: GLint, srcY: GLint, srcZ: GLint, dstName: GLuint, dstTarget: GLenum, dstLevel: GLint, dstX: GLint, dstY: GLint, dstZ: GLint, width: GLsizei, height: GLsizei, depth: GLsizei)
  proc Uniform2i(location: GLint, v0: GLint, v1: GLint)
  proc VertexAttrib3fvNV(index: GLuint, v: ptr GLfloat)
  proc NamedBufferStorageEXT(buffer: GLuint, size: GLsizeiptr, data: ptr pointer, flags: GLbitfield)
  proc ProgramEnvParameterI4uivNV(target: GLenum, index: GLuint, params: ptr GLuint)
  proc GetVertexAttribdvARB(index: GLuint, pname: GLenum, params: ptr GLdouble)
  proc VertexAttribL3ui64vNV(index: GLuint, v: ptr GLuint64Ext)
  proc Uniform4fvARB(location: GLint, count: GLsizei, value: ptr GLfloat)
  proc WeightsvARB(size: GLint, weights: ptr GLshort)
  proc MakeTextureHandleNonResidentARB(handle: GLuint64)
  proc EvalCoord1xOES(u: GLfixed)
  proc VertexAttrib2sv(index: GLuint, v: ptr GLshort)
  proc VertexAttrib4dvNV(index: GLuint, v: ptr GLdouble)
  proc ProgramNamedParameter4fNV(id: GLuint, len: GLsizei, name: ptr GLubyte, x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat)
  proc CompileShaderARB(shaderObj: GLhandleArb)
  proc ProgramEnvParameter4fvARB(target: GLenum, index: GLuint, params: ptr GLfloat)
  proc GetVertexAttribiv(index: GLuint, pname: GLenum, params: ptr GLint)
  proc EvalPoint1(i: GLint)
  proc EvalMapsNV(target: GLenum, mode: GLenum)
  proc GetTexGenxvOES(coord: GLenum, pname: GLenum, params: ptr GLfixed)
  proc BlendEquationSeparate(modeRgb: GLenum, modeAlpha: GLenum)
  proc GetColorTableParameterfv(target: GLenum, pname: GLenum, params: ptr GLfloat)
  proc QueryCounterEXT(id: GLuint, target: GLenum)
  proc ExtGetProgramBinarySourceQCOM(program: GLuint, shadertype: GLenum, source: cstring, length: ptr GLint)
  proc GetConvolutionParameteriv(target: GLenum, pname: GLenum, params: ptr GLint)
  proc IsProgramPipeline(pipeline: GLuint): GLboolean
  proc VertexWeightfvEXT(weight: ptr GLfloat)
  proc DisableDriverControlQCOM(driverControl: GLuint)
  proc VertexStream1fvATI(stream: GLenum, coords: ptr GLfloat)
  proc MakeTextureHandleResidentNV(handle: GLuint64)
  proc SamplerParameteriv(sampler: GLuint, pname: GLenum, param: ptr GLint)
  proc TexEnvxOES(target: GLenum, pname: GLenum, param: GLfixed)
  proc EndOcclusionQueryNV()
  proc FlushMappedBufferRangeAPPLE(target: GLenum, offset: GLintptr, size: GLsizeiptr)
  proc Vertex4iv(v: ptr GLint)
  proc VertexArrayVertexAttribIFormatEXT(vaobj: GLuint, attribindex: GLuint, size: GLint, `type`: GLenum, relativeoffset: GLuint)
  proc DisableIndexedEXT(target: GLenum, index: GLuint)
  proc VertexAttribL1dEXT(index: GLuint, x: GLdouble)
  proc BeginPerfMonitorAMD(monitor: GLuint)
  proc ConvolutionFilter1DEXT(target: GLenum, internalformat: GLenum, width: GLsizei, format: GLenum, `type`: GLenum, image: pointer)
  proc PrimitiveRestartIndex(index: GLuint)
  proc WindowPos2dv(v: ptr GLdouble)
  proc BindFramebufferOES(target: GLenum, framebuffer: GLuint)
  proc TessellationModeAMD(mode: GLenum)
  proc IsVariantEnabledEXT(id: GLuint, cap: GLenum): GLboolean
  proc Color3iv(v: ptr GLint)
  proc FogCoordFormatNV(`type`: GLenum, stride: GLsizei)
  proc ClearNamedBufferDataEXT(buffer: GLuint, internalformat: GLenum, format: GLenum, `type`: GLenum, data: ptr pointer)
  proc TextureRangeAPPLE(target: GLenum, length: GLsizei, `pointer`: pointer)
  proc TexCoord4bvOES(coords: ptr GLbyte)
  proc Rotated(angle: GLdouble, x: GLdouble, y: GLdouble, z: GLdouble)
  proc Accum(op: GLenum, value: GLfloat)
  proc Vertex3d(x: GLdouble, y: GLdouble, z: GLdouble)
  proc GetPathMetricRangeNV(metricQueryMask: GLbitfield, firstPathName: GLuint, numPaths: GLsizei, stride: GLsizei, metrics: ptr GLfloat)
  proc Uniform4d(location: GLint, x: GLdouble, y: GLdouble, z: GLdouble, w: GLdouble)
  proc TextureSubImage2DEXT(texture: GLuint, target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, width: GLsizei, height: GLsizei, format: GLenum, `type`: GLenum, pixels: pointer)
  proc MultiTexCoord1iv(target: GLenum, v: ptr GLint)
  proc FogFuncSGIS(n: GLsizei, points: ptr GLfloat)
  proc GetMaterialxOES(face: GLenum, pname: GLenum, param: GLfixed)
  proc GlobalAlphaFactorbSUN(factor: GLbyte)
  proc GetProgramLocalParameterdvARB(target: GLenum, index: GLuint, params: ptr GLdouble)
  proc DeleteProgramsARB(n: GLsizei, programs: ptr GLuint)
  proc VertexStream1sATI(stream: GLenum, x: GLshort)
  proc MatrixTranslatedEXT(mode: GLenum, x: GLdouble, y: GLdouble, z: GLdouble)
  proc TexSubImage1D(target: GLenum, level: GLint, xoffset: GLint, width: GLsizei, format: GLenum, `type`: GLenum, pixels: pointer)
  proc GetBufferSubData(target: GLenum, offset: GLintptr, size: GLsizeiptr, data: pointer)
  proc Uniform4uiEXT(location: GLint, v0: GLuint, v1: GLuint, v2: GLuint, v3: GLuint)
  proc GetShaderiv(shader: GLuint, pname: GLenum, params: ptr GLint)
  proc GetQueryIndexediv(target: GLenum, index: GLuint, pname: GLenum, params: ptr GLint)
  proc DebugMessageInsert(source: GLenum, `type`: GLenum, id: GLuint, severity: GLenum, length: GLsizei, buf: cstring)
  proc VertexAttribs2dvNV(index: GLuint, count: GLsizei, v: ptr GLdouble)
  proc GetFixedvOES(pname: GLenum, params: ptr GLfixed)
  proc Uniform2iv(location: GLint, count: GLsizei, value: ptr GLint)
  proc TextureView(texture: GLuint, target: GLenum, origtexture: GLuint, internalformat: GLenum, minlevel: GLuint, numlevels: GLuint, minlayer: GLuint, numlayers: GLuint)
  proc MultiTexCoord1xvOES(texture: GLenum, coords: ptr GLfixed)
  proc TexBufferRange(target: GLenum, internalformat: GLenum, buffer: GLuint, offset: GLintptr, size: GLsizeiptr)
  proc MultiTexCoordPointerEXT(texunit: GLenum, size: GLint, `type`: GLenum, stride: GLsizei, `pointer`: pointer)
  proc BlendColorxOES(red: GLfixed, green: GLfixed, blue: GLfixed, alpha: GLfixed)
  proc ReadPixels(x: GLint, y: GLint, width: GLsizei, height: GLsizei, format: GLenum, `type`: GLenum, pixels: pointer)
  proc WindowPos3dARB(x: GLdouble, y: GLdouble, z: GLdouble)
  proc PixelTexGenParameterivSGIS(pname: GLenum, params: ptr GLint)
  proc SecondaryColor3svEXT(v: ptr GLshort)
  proc PopGroupMarkerEXT()
  proc ImportSyncEXT(external_sync_type: GLenum, external_sync: GLintptr, flags: GLbitfield): GLsync
  proc VertexAttribLFormatNV(index: GLuint, size: GLint, `type`: GLenum, stride: GLsizei)
  proc VertexAttrib2sNV(index: GLuint, x: GLshort, y: GLshort)
  proc GetIntegeri_v(target: GLenum, index: GLuint, data: ptr GLint)
  proc ProgramUniform3uiv(program: GLuint, location: GLint, count: GLsizei, value: ptr GLuint)
  proc GetActiveUniformBlockiv(program: GLuint, uniformBlockIndex: GLuint, pname: GLenum, params: ptr GLint)
  proc CreateShaderProgramv(`type`: GLenum, count: GLsizei, strings: cstringArray): GLuint
  proc Uniform2fARB(location: GLint, v0: GLfloat, v1: GLfloat)
  proc VertexStream4ivATI(stream: GLenum, coords: ptr GLint)
  proc NormalP3uiv(`type`: GLenum, coords: ptr GLuint)
  proc VertexAttribLFormat(attribindex: GLuint, size: GLint, `type`: GLenum, relativeoffset: GLuint)
  proc TexCoord2bvOES(coords: ptr GLbyte)
  proc GetActiveUniformName(program: GLuint, uniformIndex: GLuint, bufSize: GLsizei, length: ptr GLsizei, uniformName: cstring)
  proc TexCoord2sv(v: ptr GLshort)
  proc VertexAttrib2dNV(index: GLuint, x: GLdouble, y: GLdouble)
  proc GetFogFuncSGIS(points: ptr GLfloat)
  proc SetFenceAPPLE(fence: GLuint)
  proc RasterPos2f(x: GLfloat, y: GLfloat)
  proc VertexWeightPointerEXT(size: GLint, `type`: GLenum, stride: GLsizei, `pointer`: pointer)
  proc EndList()
  proc VDPAUFiniNV()
  proc TbufferMask3DFX(mask: GLuint)
  proc VertexP4ui(`type`: GLenum, value: GLuint)
  proc TexEnviv(target: GLenum, pname: GLenum, params: ptr GLint)
  proc Color4xOES(red: GLfixed, green: GLfixed, blue: GLfixed, alpha: GLfixed)
  proc BlendEquationi(buf: GLuint, mode: GLenum)
  proc LoadMatrixxOES(m: ptr GLfixed)
  proc FogxOES(pname: GLenum, param: GLfixed)
  proc TexCoord4dv(v: ptr GLdouble)
  proc FogCoordPointerListIBM(`type`: GLenum, stride: GLint, `pointer`: ptr pointer, ptrstride: GLint)
  proc GetPerfMonitorGroupsAMD(numGroups: ptr GLint, groupsSize: GLsizei, groups: ptr GLuint)
  proc Vertex2hNV(x: GLhalfNv, y: GLhalfNv)
  proc DeleteFragmentShaderATI(id: GLuint)
  proc GetSamplerParameterIiv(sampler: GLuint, pname: GLenum, params: ptr GLint)
  proc Uniform2fvARB(location: GLint, count: GLsizei, value: ptr GLfloat)
  proc Fogf(pname: GLenum, param: GLfloat)
  proc MultiTexCoord1iARB(target: GLenum, s: GLint)
  proc GetActiveUniformARB(programObj: GLhandleArb, index: GLuint, maxLength: GLsizei, length: ptr GLsizei, size: ptr GLint, `type`: ptr GLenum, name: cstring)
  proc MapGrid1xOES(n: GLint, u1: GLfixed, u2: GLfixed)
  proc Indexsv(c: ptr GLshort)
  proc FragmentMaterialfSGIX(face: GLenum, pname: GLenum, param: GLfloat)
  proc BindTextureEXT(target: GLenum, texture: GLuint)
  proc Rectiv(v1: ptr GLint, v2: ptr GLint)
  proc Tangent3dEXT(tx: GLdouble, ty: GLdouble, tz: GLdouble)
  proc ProgramUniformMatrix3x4fvEXT(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat)
  proc Normal3hNV(nx: GLhalfNv, ny: GLhalfNv, nz: GLhalfNv)
  proc PushClientAttribDefaultEXT(mask: GLbitfield)
  proc UnmapBufferARB(target: GLenum): GLboolean
  proc VertexAttribs1dvNV(index: GLuint, count: GLsizei, v: ptr GLdouble)
  proc UniformMatrix2x3dv(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble)
  proc Uniform3f(location: GLint, v0: GLfloat, v1: GLfloat, v2: GLfloat)
  proc TexEnvxv(target: GLenum, pname: GLenum, params: ptr GLfixed)
  proc MapBufferOES(target: GLenum, access: GLenum)
  proc BufferData(target: GLenum, size: GLsizeiptr, data: pointer, usage: GLenum)
  proc DrawElementsInstancedANGLE(mode: GLenum, count: GLsizei, `type`: GLenum, indices: ptr pointer, primcount: GLsizei)
  proc GetTextureHandleARB(texture: GLuint): GLuint64
  proc Normal3f(nx: GLfloat, ny: GLfloat, nz: GLfloat)
  proc TexCoordP3uiv(`type`: GLenum, coords: ptr GLuint)
  proc TexParameterx(target: GLenum, pname: GLenum, param: GLfixed)
  proc MapBufferRange(target: GLenum, offset: GLintptr, length: GLsizeiptr, access: GLbitfield)
  proc TexCoord2fVertex3fSUN(s: GLfloat, t: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat)
  proc VariantArrayObjectATI(id: GLuint, `type`: GLenum, stride: GLsizei, buffer: GLuint, offset: GLuint)
  proc GetnHistogramARB(target: GLenum, reset: GLboolean, format: GLenum, `type`: GLenum, bufSize: GLsizei, values: pointer)
  proc WindowPos3sv(v: ptr GLshort)
  proc GetVariantPointervEXT(id: GLuint, value: GLenum, data: ptr pointer)
  proc GetLightfv(light: GLenum, pname: GLenum, params: ptr GLfloat)
  proc GetnTexImageARB(target: GLenum, level: GLint, format: GLenum, `type`: GLenum, bufSize: GLsizei, img: pointer)
  proc GenRenderbuffersEXT(n: GLsizei, renderbuffers: ptr GLuint)
  proc MultiDrawArraysIndirectBindlessNV(mode: GLenum, indirect: pointer, drawCount: GLsizei, stride: GLsizei, vertexBufferCount: GLint)
  proc DisableClientStateIndexedEXT(`array`: GLenum, index: GLuint)
  proc MapGrid1f(un: GLint, u1: GLfloat, u2: GLfloat)
  proc TexStorage2D(target: GLenum, levels: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei)
  proc ShaderStorageBlockBinding(program: GLuint, storageBlockIndex: GLuint, storageBlockBinding: GLuint)
  proc BlendBarrierNV()
  proc GetVideoui64vNV(video_slot: GLuint, pname: GLenum, params: ptr GLuint64Ext)
  proc Uniform3ui64NV(location: GLint, x: GLuint64Ext, y: GLuint64Ext, z: GLuint64Ext)
  proc Uniform4ivARB(location: GLint, count: GLsizei, value: ptr GLint)
  proc GetQueryObjectivARB(id: GLuint, pname: GLenum, params: ptr GLint)
  proc CompressedTexSubImage3DOES(target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, format: GLenum, imageSize: GLsizei, data: pointer)
  proc EnableIndexedEXT(target: GLenum, index: GLuint)
  proc NamedRenderbufferStorageMultisampleCoverageEXT(renderbuffer: GLuint, coverageSamples: GLsizei, colorSamples: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei)
  proc VertexAttribI3iEXT(index: GLuint, x: GLint, y: GLint, z: GLint)
  proc Uniform4uivEXT(location: GLint, count: GLsizei, value: ptr GLuint)
  proc GetUniformLocation(program: GLuint, name: cstring): GLint
  proc CurrentPaletteMatrixARB(index: GLint)
  proc VertexAttribLPointerEXT(index: GLuint, size: GLint, `type`: GLenum, stride: GLsizei, `pointer`: pointer)
  proc FogCoorddvEXT(coord: ptr GLdouble)
  proc InitNames()
  proc GetPathSpacingNV(pathListMode: GLenum, numPaths: GLsizei, pathNameType: GLenum, paths: pointer, pathBase: GLuint, advanceScale: GLfloat, kerningScale: GLfloat, transformType: GLenum, returnedSpacing: ptr GLfloat)
  proc Normal3fVertex3fvSUN(n: ptr GLfloat, v: ptr GLfloat)
  proc TexCoord2iv(v: ptr GLint)
  proc WindowPos3s(x: GLshort, y: GLshort, z: GLshort)
  proc ProgramUniformMatrix3x4fv(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat)
  proc VertexAttribP4ui(index: GLuint, `type`: GLenum, normalized: GLboolean, value: GLuint)
  proc VertexAttribs4ubvNV(index: GLuint, count: GLsizei, v: ptr GLubyte)
  proc ProgramLocalParameterI4iNV(target: GLenum, index: GLuint, x: GLint, y: GLint, z: GLint, w: GLint)
  proc StencilMaskSeparate(face: GLenum, mask: GLuint)
  proc ClientWaitSync(sync: GLsync, flags: GLbitfield, timeout: GLuint64): GLenum
  proc PolygonOffsetx(factor: GLfixed, units: GLfixed)
  proc CreateProgramObjectARB(): GLhandleArb
  proc ClearColorIuiEXT(red: GLuint, green: GLuint, blue: GLuint, alpha: GLuint)
  proc DeleteTransformFeedbacksNV(n: GLsizei, ids: ptr GLuint)
  proc FramebufferDrawBuffersEXT(framebuffer: GLuint, n: GLsizei, bufs: ptr GLenum)
  proc AreTexturesResident(n: GLsizei, textures: ptr GLuint, residences: ptr GLboolean): GLboolean
  proc NamedBufferDataEXT(buffer: GLuint, size: GLsizeiptr, data: pointer, usage: GLenum)
  proc GetInvariantFloatvEXT(id: GLuint, value: GLenum, data: ptr GLfloat)
  proc MultiTexCoord4d(target: GLenum, s: GLdouble, t: GLdouble, r: GLdouble, q: GLdouble)
  proc GetPixelTransformParameterfvEXT(target: GLenum, pname: GLenum, params: ptr GLfloat)
  proc GetStringi(name: GLenum, index: GLuint): ptr GLubyte
  proc MakeBufferNonResidentNV(target: GLenum)
  proc Vertex4bOES(x: GLbyte, y: GLbyte, z: GLbyte)
  proc GetObjectLabel(identifier: GLenum, name: GLuint, bufSize: GLsizei, length: ptr GLsizei, label: cstring)
  proc ClipPlanexOES(plane: GLenum, equation: ptr GLfixed)
  proc ElementPointerAPPLE(`type`: GLenum, `pointer`: pointer)
  proc IsAsyncMarkerSGIX(marker: GLuint): GLboolean
  proc UseShaderProgramEXT(`type`: GLenum, program: GLuint)
  proc ReplacementCodeuiColor4ubVertex3fSUN(rc: GLuint, r: GLubyte, g: GLubyte, b: GLubyte, a: GLubyte, x: GLfloat, y: GLfloat, z: GLfloat)
  proc IsTransformFeedback(id: GLuint): GLboolean
  proc EdgeFlag(flag: GLboolean)
  proc GetTexGeniv(coord: GLenum, pname: GLenum, params: ptr GLint)
  proc BeginQueryEXT(target: GLenum, id: GLuint)
  proc Uniform1uiEXT(location: GLint, v0: GLuint)
  proc ProgramUniform3fvEXT(program: GLuint, location: GLint, count: GLsizei, value: ptr GLfloat)
  proc GetVideoi64vNV(video_slot: GLuint, pname: GLenum, params: ptr GLint64Ext)
  proc ProgramUniform3ui(program: GLuint, location: GLint, v0: GLuint, v1: GLuint, v2: GLuint)
  proc SecondaryColor3uiEXT(red: GLuint, green: GLuint, blue: GLuint)
  proc PathStencilFuncNV(fun: GLenum, `ref`: GLint, mask: GLuint)
  proc VertexAttribP1ui(index: GLuint, `type`: GLenum, normalized: GLboolean, value: GLuint)
  proc StencilFillPathInstancedNV(numPaths: GLsizei, pathNameType: GLenum, paths: pointer, pathBase: GLuint, fillMode: GLenum, mask: GLuint, transformType: GLenum, transformValues: ptr GLfloat)
  proc FogCoordfEXT(coord: GLfloat)
  proc TextureParameterIuivEXT(texture: GLuint, target: GLenum, pname: GLenum, params: ptr GLuint)
  proc ProgramUniform4dEXT(program: GLuint, location: GLint, x: GLdouble, y: GLdouble, z: GLdouble, w: GLdouble)
  proc FramebufferTextureFaceARB(target: GLenum, attachment: GLenum, texture: GLuint, level: GLint, face: GLenum)
  proc TexCoord3s(s: GLshort, t: GLshort, r: GLshort)
  proc GetFramebufferAttachmentParameteriv(target: GLenum, attachment: GLenum, pname: GLenum, params: ptr GLint)
  proc EndVideoCaptureNV(video_capture_slot: GLuint)
  proc ProgramUniformMatrix2x4dv(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble)
  proc GetFloatIndexedvEXT(target: GLenum, index: GLuint, data: ptr GLfloat)
  proc TexCoord1xOES(s: GLfixed)
  proc TexCoord4f(s: GLfloat, t: GLfloat, r: GLfloat, q: GLfloat)
  proc ShaderSource(shader: GLuint, count: GLsizei, string: cstringArray, length: ptr GLint)
  proc GetDetailTexFuncSGIS(target: GLenum, points: ptr GLfloat)
  proc ResetHistogram(target: GLenum)
  proc VertexAttribP2ui(index: GLuint, `type`: GLenum, normalized: GLboolean, value: GLuint)
  proc DrawTransformFeedbackNV(mode: GLenum, id: GLuint)
  proc WindowPos2fMESA(x: GLfloat, y: GLfloat)
  proc ObjectLabelKHR(identifier: GLenum, name: GLuint, length: GLsizei, label: cstring)
  proc MultiTexCoord2iARB(target: GLenum, s: GLint, t: GLint)
  proc VertexAttrib4usv(index: GLuint, v: ptr GLushort)
  proc GetGraphicsResetStatusARB(): GLenum
  proc ProgramUniform3dEXT(program: GLuint, location: GLint, x: GLdouble, y: GLdouble, z: GLdouble)
  proc PathSubCommandsNV(path: GLuint, commandStart: GLsizei, commandsToDelete: GLsizei, numCommands: GLsizei, commands: ptr GLubyte, numCoords: GLsizei, coordType: GLenum, coords: pointer)
  proc EndTransformFeedbackNV()
  proc WindowPos2sMESA(x: GLshort, y: GLshort)
  proc Tangent3sEXT(tx: GLshort, ty: GLshort, tz: GLshort)
  proc LineWidthx(width: GLfixed)
  proc GetUniformBufferSizeEXT(program: GLuint, location: GLint): GLint
  proc TexCoord2bOES(s: GLbyte, t: GLbyte)
  proc WindowPos3iMESA(x: GLint, y: GLint, z: GLint)
  proc TexGend(coord: GLenum, pname: GLenum, param: GLdouble)
  proc RenderbufferStorageMultisampleANGLE(target: GLenum, samples: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei)
  proc GetProgramiv(program: GLuint, pname: GLenum, params: ptr GLint)
  proc DrawTransformFeedbackStreamInstanced(mode: GLenum, id: GLuint, stream: GLuint, instancecount: GLsizei)
  proc MatrixTranslatefEXT(mode: GLenum, x: GLfloat, y: GLfloat, z: GLfloat)
  proc Color4iv(v: ptr GLint)
  proc SecondaryColor3ivEXT(v: ptr GLint)
  proc IsNamedStringARB(namelen: GLint, name: cstring): GLboolean
  proc VertexAttribL4dv(index: GLuint, v: ptr GLdouble)
  proc EndTransformFeedback()
  proc VertexStream3fvATI(stream: GLenum, coords: ptr GLfloat)
  proc ProgramUniformMatrix4x2dv(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble)
  proc TextureBufferRangeEXT(texture: GLuint, target: GLenum, internalformat: GLenum, buffer: GLuint, offset: GLintptr, size: GLsizeiptr)
  proc TexCoord2fNormal3fVertex3fvSUN(tc: ptr GLfloat, n: ptr GLfloat, v: ptr GLfloat)
  proc ProgramUniform2f(program: GLuint, location: GLint, v0: GLfloat, v1: GLfloat)
  proc MultiTexCoord2sv(target: GLenum, v: ptr GLshort)
  proc TexCoord3bOES(s: GLbyte, t: GLbyte, r: GLbyte)
  proc GenFramebuffersOES(n: GLsizei, framebuffers: ptr GLuint)
  proc MultiTexCoord3sv(target: GLenum, v: ptr GLshort)
  proc VertexAttrib4Nub(index: GLuint, x: GLubyte, y: GLubyte, z: GLubyte, w: GLubyte)
  proc Color3d(red: GLdouble, green: GLdouble, blue: GLdouble)
  proc GetActiveAttrib(program: GLuint, index: GLuint, bufSize: GLsizei, length: ptr GLsizei, size: ptr GLint, `type`: ptr GLenum, name: cstring)
  proc ConvolutionParameterfEXT(target: GLenum, pname: GLenum, params: GLfloat)
  proc TexSubImage2DEXT(target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, width: GLsizei, height: GLsizei, format: GLenum, `type`: GLenum, pixels: pointer)
  proc Binormal3fvEXT(v: ptr GLfloat)
  proc DebugMessageControl(source: GLenum, `type`: GLenum, severity: GLenum, count: GLsizei, ids: ptr GLuint, enabled: GLboolean)
  proc ProgramUniform3uivEXT(program: GLuint, location: GLint, count: GLsizei, value: ptr GLuint)
  proc PNTrianglesiATI(pname: GLenum, param: GLint)
  proc GetPerfMonitorCounterInfoAMD(group: GLuint, counter: GLuint, pname: GLenum, data: pointer)
  proc VertexAttribL3ui64NV(index: GLuint, x: GLuint64Ext, y: GLuint64Ext, z: GLuint64Ext)
  proc IsRenderbufferOES(renderbuffer: GLuint): GLboolean
  proc ColorSubTable(target: GLenum, start: GLsizei, count: GLsizei, format: GLenum, `type`: GLenum, data: pointer)
  proc CompressedMultiTexImage1DEXT(texunit: GLenum, target: GLenum, level: GLint, internalformat: GLenum, width: GLsizei, border: GLint, imageSize: GLsizei, bits: pointer)
  proc BindSampler(unit: GLuint, sampler: GLuint)
  proc VariantubvEXT(id: GLuint, `addr`: ptr GLubyte)
  proc Disablei(target: GLenum, index: GLuint)
  proc VertexAttribI2uiEXT(index: GLuint, x: GLuint, y: GLuint)
  proc DrawElementArrayATI(mode: GLenum, count: GLsizei)
  proc TagSampleBufferSGIX()
  proc VertexPointerEXT(size: GLint, `type`: GLenum, stride: GLsizei, count: GLsizei, `pointer`: pointer)
  proc FragmentLightiSGIX(light: GLenum, pname: GLenum, param: GLint)
  proc LoadTransposeMatrixxOES(m: ptr GLfixed)
  proc ProgramLocalParameter4fvARB(target: GLenum, index: GLuint, params: ptr GLfloat)
  proc GetVariantFloatvEXT(id: GLuint, value: GLenum, data: ptr GLfloat)
  proc ProgramUniform4ui64vNV(program: GLuint, location: GLint, count: GLsizei, value: ptr GLuint64Ext)
  proc FragmentLightfSGIX(light: GLenum, pname: GLenum, param: GLfloat)
  proc IsVertexArrayAPPLE(`array`: GLuint): GLboolean
  proc TexCoord1bvOES(coords: ptr GLbyte)
  proc Uniform4fv(location: GLint, count: GLsizei, value: ptr GLfloat)
  proc PixelDataRangeNV(target: GLenum, length: GLsizei, `pointer`: pointer)
  proc UniformMatrix4x2fv(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat)
  proc Rectf(x1: GLfloat, y1: GLfloat, x2: GLfloat, y2: GLfloat)
  proc CoverageMaskNV(mask: GLboolean)
  proc PointParameterfvSGIS(pname: GLenum, params: ptr GLfloat)
  proc ProgramUniformMatrix4x2dvEXT(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble)
  proc FragmentLightModelfSGIX(pname: GLenum, param: GLfloat)
  proc DisableVertexAttribAPPLE(index: GLuint, pname: GLenum)
  proc MultiTexCoord3dvARB(target: GLenum, v: ptr GLdouble)
  proc TexCoord4iv(v: ptr GLint)
  proc Uniform1f(location: GLint, v0: GLfloat)
  proc VertexAttribParameteriAMD(index: GLuint, pname: GLenum, param: GLint)
  proc GetConvolutionParameterfv(target: GLenum, pname: GLenum, params: ptr GLfloat)
  proc Recti(x1: GLint, y1: GLint, x2: GLint, y2: GLint)
  proc TexEnvxvOES(target: GLenum, pname: GLenum, params: ptr GLfixed)
  proc GetRenderbufferParameteriv(target: GLenum, pname: GLenum, params: ptr GLint)
  proc BlendFuncIndexedAMD(buf: GLuint, src: GLenum, dst: GLenum)
  proc ProgramUniformMatrix3x2fv(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat)
  proc DrawArraysInstancedANGLE(mode: GLenum, first: GLint, count: GLsizei, primcount: GLsizei)
  proc TextureBarrierNV()
  proc DrawBuffersIndexedEXT(n: GLint, location: ptr GLenum, indices: ptr GLint)
  proc UniformMatrix4fvARB(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat)
  proc InstrumentsBufferSGIX(size: GLsizei, buffer: ptr GLint)
  proc AlphaFuncQCOM(fun: GLenum, `ref`: GLclampf)
  proc UniformMatrix4fv(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat)
  proc GetMinmaxParameteriv(target: GLenum, pname: GLenum, params: ptr GLint)
  proc GetInvariantBooleanvEXT(id: GLuint, value: GLenum, data: ptr GLboolean)
  proc VDPAUIsSurfaceNV(surface: GLvdpauSurfaceNv)
  proc GenProgramsARB(n: GLsizei, programs: ptr GLuint)
  proc DrawRangeElementArrayATI(mode: GLenum, start: GLuint, `end`: GLuint, count: GLsizei)
  proc FramebufferRenderbufferEXT(target: GLenum, attachment: GLenum, renderbuffertarget: GLenum, renderbuffer: GLuint)
  proc ClearIndex(c: GLfloat)
  proc DepthRangeIndexed(index: GLuint, n: GLdouble, f: GLdouble)
  proc DrawTexivOES(coords: ptr GLint)
  proc Tangent3iEXT(tx: GLint, ty: GLint, tz: GLint)
  proc StringMarkerGREMEDY(len: GLsizei, string: pointer)
  proc TexCoordP1ui(`type`: GLenum, coords: GLuint)
  proc Orthox(left: GLfixed, right: GLfixed, bottom: GLfixed, top: GLfixed, nearVal: GLfixed, farVal: GLfixed)
  proc ReplacementCodeuiVertex3fvSUN(rc: ptr GLuint, v: ptr GLfloat)
  proc MultiTexCoord1bvOES(texture: GLenum, coords: ptr GLbyte)
  proc DrawArraysInstancedBaseInstance(mode: GLenum, first: GLint, count: GLsizei, instancecount: GLsizei, baseinstance: GLuint)
  proc MultMatrixf(m: ptr GLfloat)
  proc ProgramUniform4i(program: GLuint, location: GLint, v0: GLint, v1: GLint, v2: GLint, v3: GLint)
  proc ScissorArrayv(first: GLuint, count: GLsizei, v: ptr GLint)
  proc GetnUniformivEXT(program: GLuint, location: GLint, bufSize: GLsizei, params: ptr GLint)
  proc GetTexEnvxvOES(target: GLenum, pname: GLenum, params: ptr GLfixed)
  proc WindowPos3ivARB(v: ptr GLint)
  proc ProgramStringARB(target: GLenum, format: GLenum, len: GLsizei, string: pointer)
  proc TextureColorMaskSGIS(red: GLboolean, green: GLboolean, blue: GLboolean, alpha: GLboolean)
  proc MultiTexCoord4fv(target: GLenum, v: ptr GLfloat)
  proc UniformMatrix4x3fv(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat)
  proc IsPathNV(path: GLuint): GLboolean
  proc StartTilingQCOM(x: GLuint, y: GLuint, width: GLuint, height: GLuint, preserveMask: GLbitfield)
  proc VariantivEXT(id: GLuint, `addr`: ptr GLint)
  proc GetnMinmaxARB(target: GLenum, reset: GLboolean, format: GLenum, `type`: GLenum, bufSize: GLsizei, values: pointer)
  proc TransformFeedbackVaryings(program: GLuint, count: GLsizei, varyings: cstringArray, bufferMode: GLenum)
  proc ShaderOp2EXT(op: GLenum, res: GLuint, arg1: GLuint, arg2: GLuint)
  proc VertexAttribPointer(index: GLuint, size: GLint, `type`: GLenum, normalized: GLboolean, stride: GLsizei, `pointer`: pointer)
  proc MultiTexCoord4dvARB(target: GLenum, v: ptr GLdouble)
  proc ProgramUniform1ui64NV(program: GLuint, location: GLint, x: GLuint64Ext)
  proc GetShaderSourceARB(obj: GLhandleArb, maxLength: GLsizei, length: ptr GLsizei, source: cstring)
  proc GetBufferSubDataARB(target: GLenum, offset: GLintPtrArb, size: GLsizeiptrArb, data: pointer)
  proc CopyTexSubImage2D(target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, x: GLint, y: GLint, width: GLsizei, height: GLsizei)
  proc ProgramEnvParameterI4iNV(target: GLenum, index: GLuint, x: GLint, y: GLint, z: GLint, w: GLint)
  proc GetVertexAttribivARB(index: GLuint, pname: GLenum, params: ptr GLint)
  proc GetFinalCombinerInputParameterivNV(variable: GLenum, pname: GLenum, params: ptr GLint)
  proc IndexFuncEXT(fun: GLenum, `ref`: GLclampf)
  proc ProgramUniformMatrix3dv(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble)
  proc TexStorage1DEXT(target: GLenum, levels: GLsizei, internalformat: GLenum, width: GLsizei)
  proc UniformMatrix2fv(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat)
  proc ConvolutionParameterf(target: GLenum, pname: GLenum, params: GLfloat)
  proc GlobalAlphaFactordSUN(factor: GLdouble)
  proc CopyTextureImage2DEXT(texture: GLuint, target: GLenum, level: GLint, internalformat: GLenum, x: GLint, y: GLint, width: GLsizei, height: GLsizei, border: GLint)
  proc Vertex4xOES(x: GLfixed, y: GLfixed, z: GLfixed)
  proc ClearDepthx(depth: GLfixed)
  proc GetColorTableParameteriv(target: GLenum, pname: GLenum, params: ptr GLint)
  proc GenProgramPipelines(n: GLsizei, pipelines: ptr GLuint)
  proc VertexAttribL4ui64vNV(index: GLuint, v: ptr GLuint64Ext)
  proc Uniform1fARB(location: GLint, v0: GLfloat)
  proc UniformMatrix3fv(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat)
  proc Uniform3dv(location: GLint, count: GLsizei, value: ptr GLdouble)
  proc VertexAttribI4iv(index: GLuint, v: ptr GLint)
  proc PixelZoom(xfactor: GLfloat, yfactor: GLfloat)
  proc ShadeModel(mode: GLenum)
  proc FramebufferTexture3DOES(target: GLenum, attachment: GLenum, textarget: GLenum, texture: GLuint, level: GLint, zoffset: GLint)
  proc MultiTexCoord2i(target: GLenum, s: GLint, t: GLint)
  proc BlendEquationSeparateIndexedAMD(buf: GLuint, modeRgb: GLenum, modeAlpha: GLenum)
  proc IsEnabled(cap: GLenum): GLboolean
  proc TexImage2D(target: GLenum, level: GLint, internalformat: GLint, width: GLsizei, height: GLsizei, border: GLint, format: GLenum, `type`: GLenum, pixels: pointer)
  proc PolygonOffsetxOES(factor: GLfixed, units: GLfixed)
  proc DrawBuffersEXT(n: GLsizei, bufs: ptr GLenum)
  proc PixelTexGenParameterfSGIS(pname: GLenum, param: GLfloat)
  proc ExtGetRenderbuffersQCOM(renderbuffers: ptr GLuint, maxRenderbuffers: GLint, numRenderbuffers: ptr GLint)
  proc BindImageTextures(first: GLuint, count: GLsizei, textures: ptr GLuint)
  proc VertexAttribP2uiv(index: GLuint, `type`: GLenum, normalized: GLboolean, value: ptr GLuint)
  proc TextureImage3DMultisampleCoverageNV(texture: GLuint, target: GLenum, coverageSamples: GLsizei, colorSamples: GLsizei, internalFormat: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, fixedSampleLocations: GLboolean)
  proc RasterPos2s(x: GLshort, y: GLshort)
  proc VertexAttrib4dvARB(index: GLuint, v: ptr GLdouble)
  proc ProgramUniformMatrix2x3fvEXT(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat)
  proc ProgramUniformMatrix2x4dvEXT(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble)
  proc MultiTexCoord1d(target: GLenum, s: GLdouble)
  proc GetProgramParameterdvNV(target: GLenum, index: GLuint, pname: GLenum, params: ptr GLdouble)
  proc PNTrianglesfATI(pname: GLenum, param: GLfloat)
  proc UniformMatrix3x4fv(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat)
  proc VertexAttrib3sNV(index: GLuint, x: GLshort, y: GLshort, z: GLshort)
  proc GetVideoCaptureStreamfvNV(video_capture_slot: GLuint, stream: GLuint, pname: GLenum, params: ptr GLfloat)
  proc CombinerParameterivNV(pname: GLenum, params: ptr GLint)
  proc GetTexGenfvOES(coord: GLenum, pname: GLenum, params: ptr GLfloat)
  proc CopyTexSubImage2DEXT(target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, x: GLint, y: GLint, width: GLsizei, height: GLsizei)
  proc GetProgramLocalParameterfvARB(target: GLenum, index: GLuint, params: ptr GLfloat)
  proc TexCoord3iv(v: ptr GLint)
  proc VertexAttribs2hvNV(index: GLuint, n: GLsizei, v: ptr GLhalfNv)
  proc Normal3sv(v: ptr GLshort)
  proc Uniform2dv(location: GLint, count: GLsizei, value: ptr GLdouble)
  proc SecondaryColor3hvNV(v: ptr GLhalfNv)
  proc DrawArraysInstancedEXT(mode: GLenum, start: GLint, count: GLsizei, primcount: GLsizei)
  proc BeginTransformFeedback(primitiveMode: GLenum)
  proc TexParameterIuivEXT(target: GLenum, pname: GLenum, params: ptr GLuint)
  proc ProgramBufferParametersfvNV(target: GLenum, bindingIndex: GLuint, wordIndex: GLuint, count: GLsizei, params: ptr GLfloat)
  proc VertexArrayBindVertexBufferEXT(vaobj: GLuint, bindingindex: GLuint, buffer: GLuint, offset: GLintptr, stride: GLsizei)
  proc PathParameterfNV(path: GLuint, pname: GLenum, value: GLfloat)
  proc GetClipPlanexOES(plane: GLenum, equation: ptr GLfixed)
  proc SecondaryColor3ubvEXT(v: ptr GLubyte)
  proc GetPixelMapxv(map: GLenum, size: GLint, values: ptr GLfixed)
  proc VertexAttribI1uivEXT(index: GLuint, v: ptr GLuint)
  proc MultiTexImage3DEXT(texunit: GLenum, target: GLenum, level: GLint, internalformat: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, border: GLint, format: GLenum, `type`: GLenum, pixels: pointer)
  proc AlphaFuncxOES(fun: GLenum, `ref`: GLfixed)
  proc MultiTexCoord2dv(target: GLenum, v: ptr GLdouble)
  proc BindRenderbufferOES(target: GLenum, renderbuffer: GLuint)
  proc PathStencilDepthOffsetNV(factor: GLfloat, units: GLfloat)
  proc PointParameterfvEXT(pname: GLenum, params: ptr GLfloat)
  proc SampleCoverageARB(value: GLfloat, invert: GLboolean)
  proc VertexAttrib3dNV(index: GLuint, x: GLdouble, y: GLdouble, z: GLdouble)
  proc NamedProgramLocalParameter4dvEXT(program: GLuint, target: GLenum, index: GLuint, params: ptr GLdouble)
  proc GenFramebuffers(n: GLsizei, framebuffers: ptr GLuint)
  proc MultiDrawElementsEXT(mode: GLenum, count: ptr GLsizei, `type`: GLenum, indices: ptr pointer, primcount: GLsizei)
  proc VertexAttrib2fNV(index: GLuint, x: GLfloat, y: GLfloat)
  proc ProgramUniform4ivEXT(program: GLuint, location: GLint, count: GLsizei, value: ptr GLint)
  proc TexGeniOES(coord: GLenum, pname: GLenum, param: GLint)
  proc BindProgramPipeline(pipeline: GLuint)
  proc BindSamplers(first: GLuint, count: GLsizei, samplers: ptr GLuint)
  proc ColorTableSGI(target: GLenum, internalformat: GLenum, width: GLsizei, format: GLenum, `type`: GLenum, table: pointer)
  proc MultiTexCoord3xOES(texture: GLenum, s: GLfixed, t: GLfixed, r: GLfixed)
  proc IsQueryEXT(id: GLuint): GLboolean
  proc GenBuffersARB(n: GLsizei, buffers: ptr GLuint)
  proc Vertex4xvOES(coords: ptr GLfixed)
  proc PixelMapuiv(map: GLenum, mapsize: GLsizei, values: ptr GLuint)
  proc DrawTexfOES(x: GLfloat, y: GLfloat, z: GLfloat, width: GLfloat, height: GLfloat)
  proc PointParameterfEXT(pname: GLenum, param: GLfloat)
  proc PathDashArrayNV(path: GLuint, dashCount: GLsizei, dashArray: ptr GLfloat)
  proc ClearTexImage(texture: GLuint, level: GLint, format: GLenum, `type`: GLenum, data: ptr pointer)
  proc Indexdv(c: ptr GLdouble)
  proc MultTransposeMatrixfARB(m: ptr GLfloat)
  proc VertexAttribL3d(index: GLuint, x: GLdouble, y: GLdouble, z: GLdouble)
  proc Uniform3fv(location: GLint, count: GLsizei, value: ptr GLfloat)
  proc GetProgramInterfaceiv(program: GLuint, programInterface: GLenum, pname: GLenum, params: ptr GLint)
  proc FogCoordfv(coord: ptr GLfloat)
  proc TexSubImage3DOES(target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, format: GLenum, `type`: GLenum, pixels: pointer)
  proc GetPolygonStipple(mask: ptr GLubyte)
  proc GetQueryObjectivEXT(id: GLuint, pname: GLenum, params: ptr GLint)
  proc Color3xOES(red: GLfixed, green: GLfixed, blue: GLfixed)
  proc MultiTexParameterIivEXT(texunit: GLenum, target: GLenum, pname: GLenum, params: ptr GLint)
  proc GetMaterialiv(face: GLenum, pname: GLenum, params: ptr GLint)
  proc Vertex2fv(v: ptr GLfloat)
  proc ConvolutionParameterivEXT(target: GLenum, pname: GLenum, params: ptr GLint)
  proc GenOcclusionQueriesNV(n: GLsizei, ids: ptr GLuint)
  proc GetVertexAttribdvNV(index: GLuint, pname: GLenum, params: ptr GLdouble)
  proc VertexAttribs4fvNV(index: GLuint, count: GLsizei, v: ptr GLfloat)
  proc VertexAttribL3dv(index: GLuint, v: ptr GLdouble)
  proc TexEnvi(target: GLenum, pname: GLenum, param: GLint)
  proc ObjectPtrLabel(`ptr`: ptr pointer, length: GLsizei, label: cstring)
  proc GetTexGenfv(coord: GLenum, pname: GLenum, params: ptr GLfloat)
  proc MapVertexAttrib1dAPPLE(index: GLuint, size: GLuint, u1: GLdouble, u2: GLdouble, stride: GLint, order: GLint, points: ptr GLdouble)
  proc TexCoord3dv(v: ptr GLdouble)
  proc IsEnabledIndexedEXT(target: GLenum, index: GLuint): GLboolean
  proc GlobalAlphaFactoruiSUN(factor: GLuint)
  proc MatrixIndexPointerARB(size: GLint, `type`: GLenum, stride: GLsizei, `pointer`: pointer)
  proc UniformHandleui64ARB(location: GLint, value: GLuint64)
  proc Uniform1fvARB(location: GLint, count: GLsizei, value: ptr GLfloat)
  proc GetActiveSubroutineUniformName(program: GLuint, shadertype: GLenum, index: GLuint, bufsize: GLsizei, length: ptr GLsizei, name: cstring)
  proc ProgramUniformMatrix4x2fvEXT(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat)
  proc MultiTexCoord4fARB(target: GLenum, s: GLfloat, t: GLfloat, r: GLfloat, q: GLfloat)
  proc GetDriverControlsQCOM(num: ptr GLint, size: GLsizei, driverControls: ptr GLuint)
  proc BindBufferRange(target: GLenum, index: GLuint, buffer: GLuint, offset: GLintptr, size: GLsizeiptr)
  proc MapGrid2f(un: GLint, u1: GLfloat, u2: GLfloat, vn: GLint, v1: GLfloat, v2: GLfloat)
  proc Uniform2fv(location: GLint, count: GLsizei, value: ptr GLfloat)
  proc Ortho(left: GLdouble, right: GLdouble, bottom: GLdouble, top: GLdouble, zNear: GLdouble, zFar: GLdouble)
  proc GetImageHandleNV(texture: GLuint, level: GLint, layered: GLboolean, layer: GLint, format: GLenum): GLuint64
  proc IsImageHandleResidentARB(handle: GLuint64): GLboolean
  proc GetConvolutionParameterivEXT(target: GLenum, pname: GLenum, params: ptr GLint)
  proc LineWidthxOES(width: GLfixed)
  proc PathCommandsNV(path: GLuint, numCommands: GLsizei, commands: ptr GLubyte, numCoords: GLsizei, coordType: GLenum, coords: pointer)
  proc MaterialxvOES(face: GLenum, pname: GLenum, param: ptr GLfixed)
  proc PauseTransformFeedbackNV()
  proc TexCoord4d(s: GLdouble, t: GLdouble, r: GLdouble, q: GLdouble)
  proc Uniform3ui64vNV(location: GLint, count: GLsizei, value: ptr GLuint64Ext)
  proc MultiTexCoord3dARB(target: GLenum, s: GLdouble, t: GLdouble, r: GLdouble)
  proc ProgramUniform3fEXT(program: GLuint, location: GLint, v0: GLfloat, v1: GLfloat, v2: GLfloat)
  proc TexImage3DMultisampleCoverageNV(target: GLenum, coverageSamples: GLsizei, colorSamples: GLsizei, internalFormat: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, fixedSampleLocations: GLboolean)
  proc NormalPointerEXT(`type`: GLenum, stride: GLsizei, count: GLsizei, `pointer`: pointer)
  proc PathColorGenNV(color: GLenum, genMode: GLenum, colorFormat: GLenum, coeffs: ptr GLfloat)
  proc GetMultiTexGendvEXT(texunit: GLenum, coord: GLenum, pname: GLenum, params: ptr GLdouble)
  proc Color3i(red: GLint, green: GLint, blue: GLint)
  proc PointSizex(size: GLfixed)
  proc GetConvolutionFilterEXT(target: GLenum, format: GLenum, `type`: GLenum, image: pointer)
  proc BindBufferBaseNV(target: GLenum, index: GLuint, buffer: GLuint)
  proc InsertComponentEXT(res: GLuint, src: GLuint, num: GLuint)
  proc Vertex2d(x: GLdouble, y: GLdouble)
  proc GetPathDashArrayNV(path: GLuint, dashArray: ptr GLfloat)
  proc VertexAttrib2sARB(index: GLuint, x: GLshort, y: GLshort)
  proc Scissor(x: GLint, y: GLint, width: GLsizei, height: GLsizei)
  proc LoadMatrixd(m: ptr GLdouble)
  proc Vertex2bvOES(coords: ptr GLbyte)
  proc TexCoord2i(s: GLint, t: GLint)
  proc WriteMaskEXT(res: GLuint, `in`: GLuint, outX: GLenum, outY: GLenum, outZ: GLenum, outW: GLenum)
  proc ClientWaitSyncAPPLE(sync: GLsync, flags: GLbitfield, timeout: GLuint64): GLenum
  proc GetObjectBufferivATI(buffer: GLuint, pname: GLenum, params: ptr GLint)
  proc GetNamedBufferParameterivEXT(buffer: GLuint, pname: GLenum, params: ptr GLint)
  proc TexCoord1bOES(s: GLbyte)
  proc VertexAttrib4dARB(index: GLuint, x: GLdouble, y: GLdouble, z: GLdouble, w: GLdouble)
  proc Uniform3fARB(location: GLint, v0: GLfloat, v1: GLfloat, v2: GLfloat)
  proc WindowPos2ivARB(v: ptr GLint)
  proc CreateShaderProgramvEXT(`type`: GLenum, count: GLsizei, strings: cstringArray): GLuint
  proc ListParameterivSGIX(list: GLuint, pname: GLenum, params: ptr GLint)
  proc GetGraphicsResetStatusEXT(): GLenum
  proc ActiveShaderProgramEXT(pipeline: GLuint, program: GLuint)
  proc TexCoordP1uiv(`type`: GLenum, coords: ptr GLuint)
  proc VideoCaptureStreamParameterdvNV(video_capture_slot: GLuint, stream: GLuint, pname: GLenum, params: ptr GLdouble)
  proc GetVertexAttribPointerv(index: GLuint, pname: GLenum, `pointer`: ptr pointer)
  proc GetCompressedMultiTexImageEXT(texunit: GLenum, target: GLenum, lod: GLint, img: pointer)
  proc WindowPos4fMESA(x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat)
  proc DrawElementsInstancedARB(mode: GLenum, count: GLsizei, `type`: GLenum, indices: pointer, primcount: GLsizei)
  proc VertexStream1dATI(stream: GLenum, x: GLdouble)
  proc MatrixMultfEXT(mode: GLenum, m: ptr GLfloat)
  proc GetPathParameterivNV(path: GLuint, pname: GLenum, value: ptr GLint)
  proc CombinerParameteriNV(pname: GLenum, param: GLint)
  proc UpdateObjectBufferATI(buffer: GLuint, offset: GLuint, size: GLsizei, `pointer`: pointer, preserve: GLenum)
  proc VertexAttrib4uivARB(index: GLuint, v: ptr GLuint)
  proc VertexAttrib4iv(index: GLuint, v: ptr GLint)
  proc Frustum(left: GLdouble, right: GLdouble, bottom: GLdouble, top: GLdouble, zNear: GLdouble, zFar: GLdouble)
  proc DrawTexxvOES(coords: ptr GLfixed)
  proc TexCoord2fColor4ubVertex3fSUN(s: GLfloat, t: GLfloat, r: GLubyte, g: GLubyte, b: GLubyte, a: GLubyte, x: GLfloat, y: GLfloat, z: GLfloat)
  proc MultiTexCoord2fARB(target: GLenum, s: GLfloat, t: GLfloat)
  proc GenTransformFeedbacksNV(n: GLsizei, ids: ptr GLuint)
  proc MultiTexGenfEXT(texunit: GLenum, coord: GLenum, pname: GLenum, param: GLfloat)
  proc GetMinmax(target: GLenum, reset: GLboolean, format: GLenum, `type`: GLenum, values: pointer)
  proc BindTransformFeedback(target: GLenum, id: GLuint)
  proc EnableVertexAttribArrayARB(index: GLuint)
  proc IsFenceAPPLE(fence: GLuint): GLboolean
  proc MultiTexGendvEXT(texunit: GLenum, coord: GLenum, pname: GLenum, params: ptr GLdouble)
  proc Rotatex(angle: GLfixed, x: GLfixed, y: GLfixed, z: GLfixed)
  proc GetFragmentLightfvSGIX(light: GLenum, pname: GLenum, params: ptr GLfloat)
  proc MultiTexCoord4dv(target: GLenum, v: ptr GLdouble)
  proc BlendFuncSeparateEXT(sfactorRgb: GLenum, dfactorRgb: GLenum, sfactorAlpha: GLenum, dfactorAlpha: GLenum)
  proc MultiTexCoord1f(target: GLenum, s: GLfloat)
  proc WindowPos2f(x: GLfloat, y: GLfloat)
  proc GetPathTexGenivNV(texCoordSet: GLenum, pname: GLenum, value: ptr GLint)
  proc IndexxvOES(component: ptr GLfixed)
  proc DisableVertexArrayAttribEXT(vaobj: GLuint, index: GLuint)
  proc GetProgramivARB(target: GLenum, pname: GLenum, params: ptr GLint)
  proc PatchParameteri(pname: GLenum, value: GLint)
  proc MultiTexCoord2fv(target: GLenum, v: ptr GLfloat)
  proc TexSubImage3DEXT(target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, format: GLenum, `type`: GLenum, pixels: pointer)
  proc FramebufferTexture1DEXT(target: GLenum, attachment: GLenum, textarget: GLenum, texture: GLuint, level: GLint)
  proc Tangent3fEXT(tx: GLfloat, ty: GLfloat, tz: GLfloat)
  proc IsVertexAttribEnabledAPPLE(index: GLuint, pname: GLenum): GLboolean
  proc GetShaderInfoLog(shader: GLuint, bufSize: GLsizei, length: ptr GLsizei, infoLog: cstring)
  proc Frustumx(left: GLfixed, right: GLfixed, bottom: GLfixed, top: GLfixed, nearVal: GLfixed, farVal: GLfixed)
  proc TexGenfv(coord: GLenum, pname: GLenum, params: ptr GLfloat)
  proc CompressedTexImage2DARB(target: GLenum, level: GLint, internalformat: GLenum, width: GLsizei, height: GLsizei, border: GLint, imageSize: GLsizei, data: pointer)
  proc MultiTexCoord2bvOES(texture: GLenum, coords: ptr GLbyte)
  proc GetTexBumpParameterivATI(pname: GLenum, param: ptr GLint)
  proc MultiTexCoord2svARB(target: GLenum, v: ptr GLshort)
  proc ProgramBufferParametersIivNV(target: GLenum, bindingIndex: GLuint, wordIndex: GLuint, count: GLsizei, params: ptr GLint)
  proc IsQueryARB(id: GLuint): GLboolean
  proc FramebufferTextureLayer(target: GLenum, attachment: GLenum, texture: GLuint, level: GLint, layer: GLint)
  proc Uniform4i(location: GLint, v0: GLint, v1: GLint, v2: GLint, v3: GLint)
  proc DrawArrays(mode: GLenum, first: GLint, count: GLsizei)
  proc WeightubvARB(size: GLint, weights: ptr GLubyte)
  proc GetUniformSubroutineuiv(shadertype: GLenum, location: GLint, params: ptr GLuint)
  proc MultTransposeMatrixdARB(m: ptr GLdouble)
  proc ReplacementCodeuiTexCoord2fNormal3fVertex3fvSUN(rc: ptr GLuint, tc: ptr GLfloat, n: ptr GLfloat, v: ptr GLfloat)
  proc GetMapdv(target: GLenum, query: GLenum, v: ptr GLdouble)
  proc GetMultisamplefvNV(pname: GLenum, index: GLuint, val: ptr GLfloat)
  proc Vertex2hvNV(v: ptr GLhalfNv)
  proc ProgramUniformMatrix2x3fv(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat)
  proc ProgramUniform3iEXT(program: GLuint, location: GLint, v0: GLint, v1: GLint, v2: GLint)
  proc GetnPixelMapusvARB(map: GLenum, bufSize: GLsizei, values: ptr GLushort)
  proc VertexWeighthvNV(weight: ptr GLhalfNv)
  proc DrawTransformFeedbackInstanced(mode: GLenum, id: GLuint, instancecount: GLsizei)
  proc FlushStaticDataIBM(target: GLenum)
  proc WindowPos2fvARB(v: ptr GLfloat)
  proc MultiTexCoord3sARB(target: GLenum, s: GLshort, t: GLshort, r: GLshort)
  proc WindowPos3fv(v: ptr GLfloat)
  proc FlushVertexArrayRangeNV()
  proc Tangent3bEXT(tx: GLbyte, ty: GLbyte, tz: GLbyte)
  proc IglooInterfaceSGIX(pname: GLenum, params: pointer)
  proc ProgramUniformMatrix4x2fv(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat)
  proc VertexAttribIFormatNV(index: GLuint, size: GLint, `type`: GLenum, stride: GLsizei)
  proc NamedRenderbufferStorageMultisampleEXT(renderbuffer: GLuint, samples: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei)
  proc CopyTexImage1DEXT(target: GLenum, level: GLint, internalformat: GLenum, x: GLint, y: GLint, width: GLsizei, border: GLint)
  proc BindTexGenParameterEXT(unit: GLenum, coord: GLenum, value: GLenum): GLuint
  proc Vertex4hNV(x: GLhalfNv, y: GLhalfNv, z: GLhalfNv, w: GLhalfNv)
  proc GetMapfv(target: GLenum, query: GLenum, v: ptr GLfloat)
  proc SamplePatternEXT(pattern: GLenum)
  proc IndexxOES(component: GLfixed)
  proc VertexAttrib4ubv(index: GLuint, v: ptr GLubyte)
  proc GetColorTable(target: GLenum, format: GLenum, `type`: GLenum, table: pointer)
  proc FragmentLightModelivSGIX(pname: GLenum, params: ptr GLint)
  proc PixelTransformParameterfEXT(target: GLenum, pname: GLenum, param: GLfloat)
  proc SamplerParameterfv(sampler: GLuint, pname: GLenum, param: ptr GLfloat)
  proc BindTextureUnitParameterEXT(unit: GLenum, value: GLenum): GLuint
  proc Color3ub(red: GLubyte, green: GLubyte, blue: GLubyte)
  proc GetMultiTexGenivEXT(texunit: GLenum, coord: GLenum, pname: GLenum, params: ptr GLint)
  proc VariantusvEXT(id: GLuint, `addr`: ptr GLushort)
  proc Materialiv(face: GLenum, pname: GLenum, params: ptr GLint)
  proc PassTexCoordATI(dst: GLuint, coord: GLuint, swizzle: GLenum)
  proc GetIntegerui64vNV(value: GLenum, result: ptr GLuint64Ext)
  proc ProgramParameteriEXT(program: GLuint, pname: GLenum, value: GLint)
  proc VertexArrayEdgeFlagOffsetEXT(vaobj: GLuint, buffer: GLuint, stride: GLsizei, offset: GLintptr)
  proc GetCombinerInputParameterivNV(stage: GLenum, portion: GLenum, variable: GLenum, pname: GLenum, params: ptr GLint)
  proc LogicOp(opcode: GLenum)
  proc ConvolutionParameterfvEXT(target: GLenum, pname: GLenum, params: ptr GLfloat)
  proc IsBufferResidentNV(target: GLenum): GLboolean
  proc IsProgram(program: GLuint): GLboolean
  proc EndQueryARB(target: GLenum)
  proc RenderbufferStorage(target: GLenum, internalformat: GLenum, width: GLsizei, height: GLsizei)
  proc Materialfv(face: GLenum, pname: GLenum, params: ptr GLfloat)
  proc Translatex(x: GLfixed, y: GLfixed, z: GLfixed)
  proc PathParameterivNV(path: GLuint, pname: GLenum, value: ptr GLint)
  proc LightxOES(light: GLenum, pname: GLenum, param: GLfixed)
  proc SampleMaskEXT(value: GLclampf, invert: GLboolean)
  proc ReplacementCodeubvSUN(code: ptr GLubyte)
  proc VertexAttribArrayObjectATI(index: GLuint, size: GLint, `type`: GLenum, normalized: GLboolean, stride: GLsizei, buffer: GLuint, offset: GLuint)
  proc BeginTransformFeedbackNV(primitiveMode: GLenum)
  proc EvalCoord1fv(u: ptr GLfloat)
  proc ProgramUniformMatrix2x3dvEXT(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble)
  proc Materialxv(face: GLenum, pname: GLenum, param: ptr GLfixed)
  proc GetIntegerui64i_vNV(value: GLenum, index: GLuint, result: ptr GLuint64Ext)
  proc UniformBlockBinding(program: GLuint, uniformBlockIndex: GLuint, uniformBlockBinding: GLuint)
  proc Color4ui(red: GLuint, green: GLuint, blue: GLuint, alpha: GLuint)
  proc Color4ubVertex2fvSUN(c: ptr GLubyte, v: ptr GLfloat)
  proc Rectd(x1: GLdouble, y1: GLdouble, x2: GLdouble, y2: GLdouble)
  proc GenVertexShadersEXT(range: GLuint): GLuint
  proc LinkProgramARB(programObj: GLhandleArb)
  proc VertexAttribL4dEXT(index: GLuint, x: GLdouble, y: GLdouble, z: GLdouble, w: GLdouble)
  proc BlitFramebuffer(srcX0: GLint, srcY0: GLint, srcX1: GLint, srcY1: GLint, dstX0: GLint, dstY0: GLint, dstX1: GLint, dstY1: GLint, mask: GLbitfield, filter: GLenum)
  proc UseProgram(program: GLuint)
  proc NamedProgramLocalParameterI4ivEXT(program: GLuint, target: GLenum, index: GLuint, params: ptr GLint)
  proc MatrixLoadTransposedEXT(mode: GLenum, m: ptr GLdouble)
  proc Translatef(x: GLfloat, y: GLfloat, z: GLfloat)
  proc GetBooleani_v(target: GLenum, index: GLuint, data: ptr GLboolean)
  proc EndFragmentShaderATI()
  proc VertexAttribI4ivEXT(index: GLuint, v: ptr GLint)
  proc MultiDrawElementsIndirectBindlessNV(mode: GLenum, `type`: GLenum, indirect: pointer, drawCount: GLsizei, stride: GLsizei, vertexBufferCount: GLint)
  proc TexCoord2s(s: GLshort, t: GLshort)
  proc ProgramUniform1i64vNV(program: GLuint, location: GLint, count: GLsizei, value: ptr GLint64Ext)
  proc PointSizePointerOES(`type`: GLenum, stride: GLsizei, `pointer`: ptr pointer)
  proc GetTexFilterFuncSGIS(target: GLenum, filter: GLenum, weights: ptr GLfloat)
  proc MapGrid2xOES(n: GLint, u1: GLfixed, u2: GLfixed, v1: GLfixed, v2: GLfixed)
  proc RasterPos4xvOES(coords: ptr GLfixed)
  proc GetProgramBinary(program: GLuint, bufSize: GLsizei, length: ptr GLsizei, binaryFormat: ptr GLenum, binary: pointer)
  proc NamedProgramLocalParameterI4uiEXT(program: GLuint, target: GLenum, index: GLuint, x: GLuint, y: GLuint, z: GLuint, w: GLuint)
  proc GetTexImage(target: GLenum, level: GLint, format: GLenum, `type`: GLenum, pixels: pointer)
  proc Color4d(red: GLdouble, green: GLdouble, blue: GLdouble, alpha: GLdouble)
  proc TexCoord2fColor4fNormal3fVertex3fSUN(s: GLfloat, t: GLfloat, r: GLfloat, g: GLfloat, b: GLfloat, a: GLfloat, nx: GLfloat, ny: GLfloat, nz: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat)
  proc Indexi(c: GLint)
  proc GetSamplerParameterIuiv(sampler: GLuint, pname: GLenum, params: ptr GLuint)
  proc GetnUniformivARB(program: GLuint, location: GLint, bufSize: GLsizei, params: ptr GLint)
  proc CopyTexSubImage3DEXT(target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, x: GLint, y: GLint, width: GLsizei, height: GLsizei)
  proc VertexAttribI2uivEXT(index: GLuint, v: ptr GLuint)
  proc VertexStream2fvATI(stream: GLenum, coords: ptr GLfloat)
  proc ArrayElementEXT(i: GLint)
  proc VertexAttrib2fv(index: GLuint, v: ptr GLfloat)
  proc CopyMultiTexSubImage1DEXT(texunit: GLenum, target: GLenum, level: GLint, xoffset: GLint, x: GLint, y: GLint, width: GLsizei)
  proc TexCoord4sv(v: ptr GLshort)
  proc TexGenfvOES(coord: GLenum, pname: GLenum, params: ptr GLfloat)
  proc PointParameteriv(pname: GLenum, params: ptr GLint)
  proc GetNamedRenderbufferParameterivEXT(renderbuffer: GLuint, pname: GLenum, params: ptr GLint)
  proc ProgramVertexLimitNV(target: GLenum, limit: GLint)
  proc SetMultisamplefvAMD(pname: GLenum, index: GLuint, val: ptr GLfloat)
  proc LoadIdentityDeformationMapSGIX(mask: GLbitfield)
  proc IsSyncAPPLE(sync: GLsync): GLboolean
  proc ProgramUniform1ui64vNV(program: GLuint, location: GLint, count: GLsizei, value: ptr GLuint64Ext)
  proc EdgeFlagPointerListIBM(stride: GLint, `pointer`: ptr ptr GLboolean, ptrstride: GLint)
  proc BeginVertexShaderEXT()
  proc GetIntegerv(pname: GLenum, params: ptr GLint)
  proc VertexAttrib2dvARB(index: GLuint, v: ptr GLdouble)
  proc BeginConditionalRenderNV(id: GLuint, mode: GLenum)
  proc EdgeFlagv(flag: ptr GLboolean)
  proc ReplacementCodeubSUN(code: GLubyte)
  proc ObjectLabel(identifier: GLenum, name: GLuint, length: GLsizei, label: cstring)
  proc MultiTexCoord3xvOES(texture: GLenum, coords: ptr GLfixed)
  proc Normal3iv(v: ptr GLint)
  proc SamplerParameteri(sampler: GLuint, pname: GLenum, param: GLint)
  proc TextureStorage1DEXT(texture: GLuint, target: GLenum, levels: GLsizei, internalformat: GLenum, width: GLsizei)
  proc VertexStream4dvATI(stream: GLenum, coords: ptr GLdouble)
  proc WindowPos2fv(v: ptr GLfloat)
  proc TexCoord4i(s: GLint, t: GLint, r: GLint, q: GLint)
  proc VertexAttrib4NusvARB(index: GLuint, v: ptr GLushort)
  proc VertexAttribL4d(index: GLuint, x: GLdouble, y: GLdouble, z: GLdouble, w: GLdouble)
  proc VertexAttribDivisorANGLE(index: GLuint, divisor: GLuint)
  proc MatrixIndexPointerOES(size: GLint, `type`: GLenum, stride: GLsizei, `pointer`: pointer)
  proc MultMatrixxOES(m: ptr GLfixed)
  proc MultiTexCoordP2ui(texture: GLenum, `type`: GLenum, coords: GLuint)
  proc DeformationMap3dSGIX(target: GLenum, u1: GLdouble, u2: GLdouble, ustride: GLint, uorder: GLint, v1: GLdouble, v2: GLdouble, vstride: GLint, vorder: GLint, w1: GLdouble, w2: GLdouble, wstride: GLint, worder: GLint, points: ptr GLdouble)
  proc ClearDepthfOES(depth: GLclampf)
  proc VertexStream1ivATI(stream: GLenum, coords: ptr GLint)
  proc Hint(target: GLenum, mode: GLenum)
  proc Vertex3fv(v: ptr GLfloat)
  proc WaitSyncAPPLE(sync: GLsync, flags: GLbitfield, timeout: GLuint64)
  proc WindowPos3i(x: GLint, y: GLint, z: GLint)
  proc CompressedTexImage3DARB(target: GLenum, level: GLint, internalformat: GLenum, width: GLsizei, height: GLsizei, depth: GLsizei, border: GLint, imageSize: GLsizei, data: pointer)
  proc VertexAttrib1fvARB(index: GLuint, v: ptr GLfloat)
  proc MultiTexCoord4xOES(texture: GLenum, s: GLfixed, t: GLfixed, r: GLfixed, q: GLfixed)
  proc Uniform4ui64NV(location: GLint, x: GLuint64Ext, y: GLuint64Ext, z: GLuint64Ext, w: GLuint64Ext)
  proc ProgramUniform4uiEXT(program: GLuint, location: GLint, v0: GLuint, v1: GLuint, v2: GLuint, v3: GLuint)
  proc UnmapNamedBufferEXT(buffer: GLuint): GLboolean
  proc Bitmap(width: GLsizei, height: GLsizei, xorig: GLfloat, yorig: GLfloat, xmove: GLfloat, ymove: GLfloat, bitmap: ptr GLubyte)
  proc NamedProgramLocalParameters4fvEXT(program: GLuint, target: GLenum, index: GLuint, count: GLsizei, params: ptr GLfloat)
  proc GetPathCommandsNV(path: GLuint, commands: ptr GLubyte)
  proc VertexAttrib3fNV(index: GLuint, x: GLfloat, y: GLfloat, z: GLfloat)
  proc NamedProgramStringEXT(program: GLuint, target: GLenum, format: GLenum, len: GLsizei, string: pointer)
  proc MatrixIndexusvARB(size: GLint, indices: ptr GLushort)
  proc BlitFramebufferNV(srcX0: GLint, srcY0: GLint, srcX1: GLint, srcY1: GLint, dstX0: GLint, dstY0: GLint, dstX1: GLint, dstY1: GLint, mask: GLbitfield, filter: GLenum)
  proc VertexAttribI1uiv(index: GLuint, v: ptr GLuint)
  proc EndConditionalRenderNV()
  proc FeedbackBuffer(size: GLsizei, `type`: GLenum, buffer: ptr GLfloat)
  proc MultiTexCoord3bvOES(texture: GLenum, coords: ptr GLbyte)
  proc CopyColorTableSGI(target: GLenum, internalformat: GLenum, x: GLint, y: GLint, width: GLsizei)
  proc ActiveTexture(texture: GLenum)
  proc FogCoordhNV(fog: GLhalfNv)
  proc ColorMaskIndexedEXT(index: GLuint, r: GLboolean, g: GLboolean, b: GLboolean, a: GLboolean)
  proc GetCompressedTexImage(target: GLenum, level: GLint, img: pointer)
  proc RasterPos2iv(v: ptr GLint)
  proc GetBufferParameterivARB(target: GLenum, pname: GLenum, params: ptr GLint)
  proc ProgramUniform3d(program: GLuint, location: GLint, v0: GLdouble, v1: GLdouble, v2: GLdouble)
  proc RasterPos3xvOES(coords: ptr GLfixed)
  proc GetTextureParameterIuivEXT(texture: GLuint, target: GLenum, pname: GLenum, params: ptr GLuint)
  proc BindImageTextureEXT(index: GLuint, texture: GLuint, level: GLint, layered: GLboolean, layer: GLint, access: GLenum, format: GLint)
  proc WindowPos2iMESA(x: GLint, y: GLint)
  proc VertexPointervINTEL(size: GLint, `type`: GLenum, `pointer`: ptr pointer)
  proc PixelTexGenParameterfvSGIS(pname: GLenum, params: ptr GLfloat)
  proc Uniform1iARB(location: GLint, v0: GLint)
  proc TextureSubImage3DEXT(texture: GLuint, target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, format: GLenum, `type`: GLenum, pixels: pointer)
  proc StencilOpSeparate(face: GLenum, sfail: GLenum, dpfail: GLenum, dppass: GLenum)
  proc VertexAttrib1dARB(index: GLuint, x: GLdouble)
  proc GetVideoCaptureStreamivNV(video_capture_slot: GLuint, stream: GLuint, pname: GLenum, params: ptr GLint)
  proc IsFramebufferEXT(framebuffer: GLuint): GLboolean
  proc PointParameterxv(pname: GLenum, params: ptr GLfixed)
  proc ProgramUniform4dv(program: GLuint, location: GLint, count: GLsizei, value: ptr GLdouble)
  proc PassThrough(token: GLfloat)
  proc GetProgramPipelineiv(pipeline: GLuint, pname: GLenum, params: ptr GLint)
  proc ApplyTextureEXT(mode: GLenum)
  proc VertexArrayNormalOffsetEXT(vaobj: GLuint, buffer: GLuint, `type`: GLenum, stride: GLsizei, offset: GLintptr)
  proc TexFilterFuncSGIS(target: GLenum, filter: GLenum, n: GLsizei, weights: ptr GLfloat)
  proc RenderbufferStorageOES(target: GLenum, internalformat: GLenum, width: GLsizei, height: GLsizei)
  proc BindParameterEXT(value: GLenum): GLuint
  proc Vertex4s(x: GLshort, y: GLshort, z: GLshort, w: GLshort)
  proc LoadTransposeMatrixf(m: ptr GLfloat)
  proc DepthFunc(fun: GLenum)
  proc GetFramebufferAttachmentParameterivEXT(target: GLenum, attachment: GLenum, pname: GLenum, params: ptr GLint)
  proc SampleMaskSGIS(value: GLclampf, invert: GLboolean)
  proc GetPointerIndexedvEXT(target: GLenum, index: GLuint, data: ptr pointer)
  proc VertexStream4iATI(stream: GLenum, x: GLint, y: GLint, z: GLint, w: GLint)
  proc UnlockArraysEXT()
  proc ReplacementCodeuivSUN(code: ptr GLuint)
  proc MatrixScaledEXT(mode: GLenum, x: GLdouble, y: GLdouble, z: GLdouble)
  proc MultiTexImage2DEXT(texunit: GLenum, target: GLenum, level: GLint, internalformat: GLint, width: GLsizei, height: GLsizei, border: GLint, format: GLenum, `type`: GLenum, pixels: pointer)
  proc FeedbackBufferxOES(n: GLsizei, `type`: GLenum, buffer: ptr GLfixed)
  proc LightEnviSGIX(pname: GLenum, param: GLint)
  proc MultiTexCoord4dARB(target: GLenum, s: GLdouble, t: GLdouble, r: GLdouble, q: GLdouble)
  proc ExtGetTexLevelParameterivQCOM(texture: GLuint, face: GLenum, level: GLint, pname: GLenum, params: ptr GLint)
  proc VertexAttribI4usvEXT(index: GLuint, v: ptr GLushort)
  proc WindowPos2dvARB(v: ptr GLdouble)
  proc BindFramebuffer(target: GLenum, framebuffer: GLuint)
  proc GetProgramPipelineivEXT(pipeline: GLuint, pname: GLenum, params: ptr GLint)
  proc ProgramUniformHandleui64vNV(program: GLuint, location: GLint, count: GLsizei, values: ptr GLuint64)
  proc FogCoordhvNV(fog: ptr GLhalfNv)
  proc TextureImage1DEXT(texture: GLuint, target: GLenum, level: GLint, internalformat: GLint, width: GLsizei, border: GLint, format: GLenum, `type`: GLenum, pixels: pointer)
  proc GetActiveAtomicCounterBufferiv(program: GLuint, bufferIndex: GLuint, pname: GLenum, params: ptr GLint)
  proc BeginQueryARB(target: GLenum, id: GLuint)
  proc GetTexParameterIuivEXT(target: GLenum, pname: GLenum, params: ptr GLuint)
  proc Uniform4ui64vNV(location: GLint, count: GLsizei, value: ptr GLuint64Ext)
  proc ClearAccumxOES(red: GLfixed, green: GLfixed, blue: GLfixed, alpha: GLfixed)
  proc FreeObjectBufferATI(buffer: GLuint)
  proc GetVideouivNV(video_slot: GLuint, pname: GLenum, params: ptr GLuint)
  proc VertexAttribL4ui64NV(index: GLuint, x: GLuint64Ext, y: GLuint64Ext, z: GLuint64Ext, w: GLuint64Ext)
  proc GetUniformBlockIndex(program: GLuint, uniformBlockName: cstring): GLuint
  proc CopyMultiTexSubImage2DEXT(texunit: GLenum, target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, x: GLint, y: GLint, width: GLsizei, height: GLsizei)
  proc Vertex3bvOES(coords: ptr GLbyte)
  proc MultiDrawElementArrayAPPLE(mode: GLenum, first: ptr GLint, count: ptr GLsizei, primcount: GLsizei)
  proc PrimitiveRestartNV()
  proc Materiali(face: GLenum, pname: GLenum, param: GLint)
  proc Begin(mode: GLenum)
  proc FogCoordPointerEXT(`type`: GLenum, stride: GLsizei, `pointer`: pointer)
  proc TexCoord1sv(v: ptr GLshort)
  proc VertexAttribI4sv(index: GLuint, v: ptr GLshort)
  proc TexEnvx(target: GLenum, pname: GLenum, param: GLfixed)
  proc TexParameterIivEXT(target: GLenum, pname: GLenum, params: ptr GLint)
  proc LoadTransposeMatrixfARB(m: ptr GLfloat)
  proc GetTextureSamplerHandleARB(texture: GLuint, sampler: GLuint): GLuint64
  proc VertexP3uiv(`type`: GLenum, value: ptr GLuint)
  proc ProgramUniform2dv(program: GLuint, location: GLint, count: GLsizei, value: ptr GLdouble)
  proc TexCoord4xvOES(coords: ptr GLfixed)
  proc TexStorage1D(target: GLenum, levels: GLsizei, internalformat: GLenum, width: GLsizei)
  proc TextureParameterfEXT(texture: GLuint, target: GLenum, pname: GLenum, param: GLfloat)
  proc VertexAttrib1d(index: GLuint, x: GLdouble)
  proc GetnPixelMapfvARB(map: GLenum, bufSize: GLsizei, values: ptr GLfloat)
  proc DisableVertexAttribArray(index: GLuint)
  proc UniformMatrix4x3dv(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble)
  proc RasterPos4f(x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat)
  proc ProgramUniform1fEXT(program: GLuint, location: GLint, v0: GLfloat)
  proc PathTexGenNV(texCoordSet: GLenum, genMode: GLenum, components: GLint, coeffs: ptr GLfloat)
  proc Uniform3ui(location: GLint, v0: GLuint, v1: GLuint, v2: GLuint)
  proc VDPAURegisterOutputSurfaceNV(vdpSurface: pointer, target: GLenum, numTextureNames: GLsizei, textureNames: ptr GLuint): GLvdpauSurfaceNv
  proc GetProgramLocalParameterIuivNV(target: GLenum, index: GLuint, params: ptr GLuint)
  proc IsTextureHandleResidentNV(handle: GLuint64): GLboolean
  proc ProgramEnvParameters4fvEXT(target: GLenum, index: GLuint, count: GLsizei, params: ptr GLfloat)
  proc ReplacementCodeuiTexCoord2fNormal3fVertex3fSUN(rc: GLuint, s: GLfloat, t: GLfloat, nx: GLfloat, ny: GLfloat, nz: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat)
  proc GetMultiTexEnvivEXT(texunit: GLenum, target: GLenum, pname: GLenum, params: ptr GLint)
  proc GetFloatv(pname: GLenum, params: ptr GLfloat)
  proc InsertEventMarkerEXT(length: GLsizei, marker: cstring)
  proc RasterPos3d(x: GLdouble, y: GLdouble, z: GLdouble)
  proc NamedFramebufferRenderbufferEXT(framebuffer: GLuint, attachment: GLenum, renderbuffertarget: GLenum, renderbuffer: GLuint)
  proc GetConvolutionFilter(target: GLenum, format: GLenum, `type`: GLenum, image: pointer)
  proc IsOcclusionQueryNV(id: GLuint): GLboolean
  proc GetnPixelMapuivARB(map: GLenum, bufSize: GLsizei, values: ptr GLuint)
  proc MapParameterfvNV(target: GLenum, pname: GLenum, params: ptr GLfloat)
  proc PushDebugGroup(source: GLenum, id: GLuint, length: GLsizei, message: cstring)
  proc MakeImageHandleResidentARB(handle: GLuint64, access: GLenum)
  proc ProgramUniformMatrix2fv(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat)
  proc Uniform3i64vNV(location: GLint, count: GLsizei, value: ptr GLint64Ext)
  proc ImageTransformParameteriHP(target: GLenum, pname: GLenum, param: GLint)
  proc MultiTexCoord1s(target: GLenum, s: GLshort)
  proc VertexAttribL4dvEXT(index: GLuint, v: ptr GLdouble)
  proc GetProgramEnvParameterfvARB(target: GLenum, index: GLuint, params: ptr GLfloat)
  proc VertexArrayColorOffsetEXT(vaobj: GLuint, buffer: GLuint, size: GLint, `type`: GLenum, stride: GLsizei, offset: GLintptr)
  proc GetHistogramParameterivEXT(target: GLenum, pname: GLenum, params: ptr GLint)
  proc GetRenderbufferParameterivOES(target: GLenum, pname: GLenum, params: ptr GLint)
  proc GetBufferPointerv(target: GLenum, pname: GLenum, params: ptr pointer)
  proc SecondaryColor3ui(red: GLuint, green: GLuint, blue: GLuint)
  proc GetDebugMessageLog(count: GLuint, bufsize: GLsizei, sources: ptr GLenum, types: ptr GLenum, ids: ptr GLuint, severities: ptr GLenum, lengths: ptr GLsizei, messageLog: cstring): GLuint
  proc Normal3i(nx: GLint, ny: GLint, nz: GLint)
  proc TestFenceNV(fence: GLuint): GLboolean
  proc SecondaryColor3usv(v: ptr GLushort)
  proc GenPathsNV(range: GLsizei): GLuint
  proc DeleteBuffersARB(n: GLsizei, buffers: ptr GLuint)
  proc ProgramUniform4fvEXT(program: GLuint, location: GLint, count: GLsizei, value: ptr GLfloat)
  proc GetSharpenTexFuncSGIS(target: GLenum, points: ptr GLfloat)
  proc DrawMeshArraysSUN(mode: GLenum, first: GLint, count: GLsizei, width: GLsizei)
  proc VertexAttribs4hvNV(index: GLuint, n: GLsizei, v: ptr GLhalfNv)
  proc GetClipPlane(plane: GLenum, equation: ptr GLdouble)
  proc EvalCoord2fv(u: ptr GLfloat)
  proc AsyncMarkerSGIX(marker: GLuint)
  proc GetSynciv(sync: GLsync, pname: GLenum, bufSize: GLsizei, length: ptr GLsizei, values: ptr GLint)
  proc GetPathTexGenfvNV(texCoordSet: GLenum, pname: GLenum, value: ptr GLfloat)
  proc TexParameterf(target: GLenum, pname: GLenum, param: GLfloat)
  proc MultiTexCoord1fvARB(target: GLenum, v: ptr GLfloat)
  proc NormalPointerListIBM(`type`: GLenum, stride: GLint, `pointer`: ptr pointer, ptrstride: GLint)
  proc FragmentLightfvSGIX(light: GLenum, pname: GLenum, params: ptr GLfloat)
  proc ViewportArrayv(first: GLuint, count: GLsizei, v: ptr GLfloat)
  proc Normal3fVertex3fSUN(nx: GLfloat, ny: GLfloat, nz: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat)
  proc MultiTexCoord2dvARB(target: GLenum, v: ptr GLdouble)
  proc CopyColorSubTable(target: GLenum, start: GLsizei, x: GLint, y: GLint, width: GLsizei)
  proc TexCoord2hvNV(v: ptr GLhalfNv)
  proc GetQueryObjectiv(id: GLuint, pname: GLenum, params: ptr GLint)
  proc Color4hNV(red: GLhalfNv, green: GLhalfNv, blue: GLhalfNv, alpha: GLhalfNv)
  proc ProgramUniform2fv(program: GLuint, location: GLint, count: GLsizei, value: ptr GLfloat)
  proc MultiTexCoord4hNV(target: GLenum, s: GLhalfNv, t: GLhalfNv, r: GLhalfNv, q: GLhalfNv)
  proc WindowPos2fvMESA(v: ptr GLfloat)
  proc VertexAttrib3s(index: GLuint, x: GLshort, y: GLshort, z: GLshort)
  proc GetIntegerIndexedvEXT(target: GLenum, index: GLuint, data: ptr GLint)
  proc VertexAttrib4Niv(index: GLuint, v: ptr GLint)
  proc ProgramLocalParameter4dvARB(target: GLenum, index: GLuint, params: ptr GLdouble)
  proc FramebufferTextureLayerEXT(target: GLenum, attachment: GLenum, texture: GLuint, level: GLint, layer: GLint)
  proc VertexAttribI1ui(index: GLuint, x: GLuint)
  proc FogCoorddv(coord: ptr GLdouble)
  proc LightModelxv(pname: GLenum, param: ptr GLfixed)
  proc GetCombinerOutputParameterfvNV(stage: GLenum, portion: GLenum, pname: GLenum, params: ptr GLfloat)
  proc FramebufferReadBufferEXT(framebuffer: GLuint, mode: GLenum)
  proc GetActiveUniformsiv(program: GLuint, uniformCount: GLsizei, uniformIndices: ptr GLuint, pname: GLenum, params: ptr GLint)
  proc GetProgramStringNV(id: GLuint, pname: GLenum, program: ptr GLubyte)
  proc CopyConvolutionFilter2D(target: GLenum, internalformat: GLenum, x: GLint, y: GLint, width: GLsizei, height: GLsizei)
  proc MultiTexCoord3iARB(target: GLenum, s: GLint, t: GLint, r: GLint)
  proc PushName(name: GLuint)
  proc ProgramParameter4dNV(target: GLenum, index: GLuint, x: GLdouble, y: GLdouble, z: GLdouble, w: GLdouble)
  proc VertexAttrib4svARB(index: GLuint, v: ptr GLshort)
  proc SecondaryColor3iv(v: ptr GLint)
  proc CopyColorSubTableEXT(target: GLenum, start: GLsizei, x: GLint, y: GLint, width: GLsizei)
  proc CallList(list: GLuint)
  proc GetMultiTexLevelParameterivEXT(texunit: GLenum, target: GLenum, level: GLint, pname: GLenum, params: ptr GLint)
  proc ProgramUniformMatrix2x4fv(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat)
  proc TexBumpParameterivATI(pname: GLenum, param: ptr GLint)
  proc TexGeni(coord: GLenum, pname: GLenum, param: GLint)
  proc SecondaryColor3dv(v: ptr GLdouble)
  proc GetnUniformdvARB(program: GLuint, location: GLint, bufSize: GLsizei, params: ptr GLdouble)
  proc GetNamedProgramLocalParameterdvEXT(program: GLuint, target: GLenum, index: GLuint, params: ptr GLdouble)
  proc GetVertexAttribPointervARB(index: GLuint, pname: GLenum, `pointer`: ptr pointer)
  proc CopyColorTable(target: GLenum, internalformat: GLenum, x: GLint, y: GLint, width: GLsizei)
  proc NamedFramebufferTextureLayerEXT(framebuffer: GLuint, attachment: GLenum, texture: GLuint, level: GLint, layer: GLint)
  proc LoadProgramNV(target: GLenum, id: GLuint, len: GLsizei, program: ptr GLubyte)
  proc AlphaFragmentOp2ATI(op: GLenum, dst: GLuint, dstMod: GLuint, arg1: GLuint, arg1Rep: GLuint, arg1Mod: GLuint, arg2: GLuint, arg2Rep: GLuint, arg2Mod: GLuint)
  proc BindLightParameterEXT(light: GLenum, value: GLenum): GLuint
  proc VertexAttrib1fv(index: GLuint, v: ptr GLfloat)
  proc LoadIdentity()
  proc FramebufferTexture2DMultisampleEXT(target: GLenum, attachment: GLenum, textarget: GLenum, texture: GLuint, level: GLint, samples: GLsizei)
  proc VertexAttrib1dvARB(index: GLuint, v: ptr GLdouble)
  proc DrawRangeElementsBaseVertex(mode: GLenum, start: GLuint, `end`: GLuint, count: GLsizei, `type`: GLenum, indices: pointer, basevertex: GLint)
  proc PixelMapfv(map: GLenum, mapsize: GLsizei, values: ptr GLfloat)
  proc PointParameterxOES(pname: GLenum, param: GLfixed)
  proc BindBufferRangeNV(target: GLenum, index: GLuint, buffer: GLuint, offset: GLintptr, size: GLsizeiptr)
  proc DepthBoundsEXT(zmin: GLclampd, zmax: GLclampd)
  proc ProgramUniformMatrix2dv(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble)
  proc SecondaryColor3s(red: GLshort, green: GLshort, blue: GLshort)
  proc EdgeFlagPointerEXT(stride: GLsizei, count: GLsizei, `pointer`: ptr GLboolean)
  proc VertexStream1fATI(stream: GLenum, x: GLfloat)
  proc Uniformui64NV(location: GLint, value: GLuint64Ext)
  proc TexCoordP4uiv(`type`: GLenum, coords: ptr GLuint)
  proc TexCoord3d(s: GLdouble, t: GLdouble, r: GLdouble)
  proc DeleteProgramPipelines(n: GLsizei, pipelines: ptr GLuint)
  proc Vertex2iv(v: ptr GLint)
  proc GetMultisamplefv(pname: GLenum, index: GLuint, val: ptr GLfloat)
  proc StartInstrumentsSGIX()
  proc GetOcclusionQueryivNV(id: GLuint, pname: GLenum, params: ptr GLint)
  proc DebugMessageCallback(callback: GLdebugProc, userParam: ptr pointer)
  proc PixelZoomxOES(xfactor: GLfixed, yfactor: GLfixed)
  proc TexCoord3i(s: GLint, t: GLint, r: GLint)
  proc EdgeFlagFormatNV(stride: GLsizei)
  proc ProgramUniform2i(program: GLuint, location: GLint, v0: GLint, v1: GLint)
  proc Color3b(red: GLbyte, green: GLbyte, blue: GLbyte)
  proc DepthRangefOES(n: GLclampf, f: GLclampf)
  proc EndVertexShaderEXT()
  proc BindVertexArrayAPPLE(`array`: GLuint)
  proc Color4bv(v: ptr GLbyte)
  proc NamedFramebufferTexture2DEXT(framebuffer: GLuint, attachment: GLenum, textarget: GLenum, texture: GLuint, level: GLint)
  proc TexCoord1f(s: GLfloat)
  proc Uniform3fvARB(location: GLint, count: GLsizei, value: ptr GLfloat)
  proc GetQueryObjectuivARB(id: GLuint, pname: GLenum, params: ptr GLuint)
  proc VertexAttrib4bv(index: GLuint, v: ptr GLbyte)
  proc GetPixelTransformParameterivEXT(target: GLenum, pname: GLenum, params: ptr GLint)
  proc VertexAttrib3svNV(index: GLuint, v: ptr GLshort)
  proc DeleteQueriesEXT(n: GLsizei, ids: ptr GLuint)
  proc Uniform3ivARB(location: GLint, count: GLsizei, value: ptr GLint)
  proc Normal3xvOES(coords: ptr GLfixed)
  proc MatrixLoadfEXT(mode: GLenum, m: ptr GLfloat)
  proc GetNamedFramebufferAttachmentParameterivEXT(framebuffer: GLuint, attachment: GLenum, pname: GLenum, params: ptr GLint)
  proc SeparableFilter2D(target: GLenum, internalformat: GLenum, width: GLsizei, height: GLsizei, format: GLenum, `type`: GLenum, row: pointer, column: pointer)
  proc VertexAttribI3uiv(index: GLuint, v: ptr GLuint)
  proc TextureStorageSparseAMD(texture: GLuint, target: GLenum, internalFormat: GLenum, width: GLsizei, height: GLsizei, depth: GLsizei, layers: GLsizei, flags: GLbitfield)
  proc MultiDrawArraysIndirectCountARB(mode: GLenum, indirect: GLintptr, drawcount: GLintptr, maxdrawcount: GLsizei, stride: GLsizei)
  proc Translated(x: GLdouble, y: GLdouble, z: GLdouble)
  proc ColorPointer(size: GLint, `type`: GLenum, stride: GLsizei, `pointer`: pointer)
  proc DrawElementsInstancedBaseVertex(mode: GLenum, count: GLsizei, `type`: GLenum, indices: pointer, instancecount: GLsizei, basevertex: GLint)
  proc BindAttribLocationARB(programObj: GLhandleArb, index: GLuint, name: cstring)
  proc TexGendv(coord: GLenum, pname: GLenum, params: ptr GLdouble)
  proc GetPathCoordsNV(path: GLuint, coords: ptr GLfloat)
  proc GetMapParameterivNV(target: GLenum, pname: GLenum, params: ptr GLint)
  proc ClientAttribDefaultEXT(mask: GLbitfield)
  proc ProgramUniformMatrix4x3fvEXT(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat)
  proc Enable(cap: GLenum)
  proc GetVertexAttribPointervNV(index: GLuint, pname: GLenum, `pointer`: ptr pointer)
  proc BindMultiTextureEXT(texunit: GLenum, target: GLenum, texture: GLuint)
  proc GetConvolutionParameterfvEXT(target: GLenum, pname: GLenum, params: ptr GLfloat)
  proc LightModelxvOES(pname: GLenum, param: ptr GLfixed)
  proc MultiTexCoord4sv(target: GLenum, v: ptr GLshort)
  proc GetColorTableParameterivSGI(target: GLenum, pname: GLenum, params: ptr GLint)
  proc FramebufferTexture2DOES(target: GLenum, attachment: GLenum, textarget: GLenum, texture: GLuint, level: GLint)
  proc ClearDepthxOES(depth: GLfixed)
  proc DisableClientStateiEXT(`array`: GLenum, index: GLuint)
  proc WindowPos2dARB(x: GLdouble, y: GLdouble)
  proc VertexAttrib1fvNV(index: GLuint, v: ptr GLfloat)
  proc DepthRangedNV(zNear: GLdouble, zFar: GLdouble)
  proc Clear(mask: GLbitfield)
  proc UnmapTexture2DINTEL(texture: GLuint, level: GLint)
  proc SecondaryColor3ub(red: GLubyte, green: GLubyte, blue: GLubyte)
  proc VertexAttribI4bv(index: GLuint, v: ptr GLbyte)
  proc TexRenderbufferNV(target: GLenum, renderbuffer: GLuint)
  proc Color4ubVertex3fvSUN(c: ptr GLubyte, v: ptr GLfloat)
  proc VertexAttrib2svNV(index: GLuint, v: ptr GLshort)
  proc MultiTexCoord1ivARB(target: GLenum, v: ptr GLint)
  proc UniformMatrix3x2dv(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble)
  proc VertexAttribL3dvEXT(index: GLuint, v: ptr GLdouble)
  proc MultiTexSubImage1DEXT(texunit: GLenum, target: GLenum, level: GLint, xoffset: GLint, width: GLsizei, format: GLenum, `type`: GLenum, pixels: pointer)
  proc GetBufferPointervARB(target: GLenum, pname: GLenum, params: ptr pointer)
  proc GetMultiTexLevelParameterfvEXT(texunit: GLenum, target: GLenum, level: GLint, pname: GLenum, params: ptr GLfloat)
  proc MultiTexParameterIuivEXT(texunit: GLenum, target: GLenum, pname: GLenum, params: ptr GLuint)
  proc GetShaderSource(shader: GLuint, bufSize: GLsizei, length: ptr GLsizei, source: cstring)
  proc StencilFunc(fun: GLenum, `ref`: GLint, mask: GLuint)
  proc VertexAttribI4bvEXT(index: GLuint, v: ptr GLbyte)
  proc VertexAttrib4NuivARB(index: GLuint, v: ptr GLuint)
  proc IsObjectBufferATI(buffer: GLuint): GLboolean
  proc RasterPos2xOES(x: GLfixed, y: GLfixed)
  proc IsFenceNV(fence: GLuint): GLboolean
  proc GetFramebufferParameteriv(target: GLenum, pname: GLenum, params: ptr GLint)
  proc ClearBufferfv(buffer: GLenum, drawbuffer: GLint, value: ptr GLfloat)
  proc ClearColorxOES(red: GLfixed, green: GLfixed, blue: GLfixed, alpha: GLfixed)
  proc VertexWeightfEXT(weight: GLfloat)
  proc ExtIsProgramBinaryQCOM(program: GLuint): GLboolean
  proc TextureStorage2DMultisampleEXT(texture: GLuint, target: GLenum, samples: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei, fixedsamplelocations: GLboolean)
  proc GetHistogramParameterxvOES(target: GLenum, pname: GLenum, params: ptr GLfixed)
  proc VertexAttrib4dNV(index: GLuint, x: GLdouble, y: GLdouble, z: GLdouble, w: GLdouble)
  proc GetPerfMonitorCounterStringAMD(group: GLuint, counter: GLuint, bufSize: GLsizei, length: ptr GLsizei, counterString: cstring)
  proc MultiTexCoord2sARB(target: GLenum, s: GLshort, t: GLshort)
  proc SpriteParameterivSGIX(pname: GLenum, params: ptr GLint)
  proc CompressedTextureImage3DEXT(texture: GLuint, target: GLenum, level: GLint, internalformat: GLenum, width: GLsizei, height: GLsizei, depth: GLsizei, border: GLint, imageSize: GLsizei, bits: pointer)
  proc BufferSubData(target: GLenum, offset: GLintptr, size: GLsizeiptr, data: pointer)
  proc BlendParameteriNV(pname: GLenum, value: GLint)
  proc VertexAttrib2fvNV(index: GLuint, v: ptr GLfloat)
  proc GetVariantBooleanvEXT(id: GLuint, value: GLenum, data: ptr GLboolean)
  proc ProgramParameteri(program: GLuint, pname: GLenum, value: GLint)
  proc GetLocalConstantIntegervEXT(id: GLuint, value: GLenum, data: ptr GLint)
  proc FragmentMaterialiSGIX(face: GLenum, pname: GLenum, param: GLint)
  proc GetNamedStringivARB(namelen: GLint, name: cstring, pname: GLenum, params: ptr GLint)
  proc Binormal3ivEXT(v: ptr GLint)
  proc CheckFramebufferStatusEXT(target: GLenum): GLenum
  proc VertexAttrib1fNV(index: GLuint, x: GLfloat)
  proc NamedRenderbufferStorageEXT(renderbuffer: GLuint, internalformat: GLenum, width: GLsizei, height: GLsizei)
  proc PresentFrameKeyedNV(video_slot: GLuint, minPresentTime: GLuint64Ext, beginPresentTimeId: GLuint, presentDurationId: GLuint, `type`: GLenum, target0: GLenum, fill0: GLuint, key0: GLuint, target1: GLenum, fill1: GLuint, key1: GLuint)
  proc GetObjectParameterfvARB(obj: GLhandleArb, pname: GLenum, params: ptr GLfloat)
  proc Vertex3sv(v: ptr GLshort)
  proc Color4s(red: GLshort, green: GLshort, blue: GLshort, alpha: GLshort)
  proc GetQueryObjecti64vEXT(id: GLuint, pname: GLenum, params: ptr GLint64)
  proc EvalMesh2(mode: GLenum, i1: GLint, i2: GLint, j1: GLint, j2: GLint)
  proc BeginTransformFeedbackEXT(primitiveMode: GLenum)
  proc BufferAddressRangeNV(pname: GLenum, index: GLuint, address: GLuint64Ext, length: GLsizeiptr)
  proc PointParameterfvARB(pname: GLenum, params: ptr GLfloat)
  proc GetActiveVaryingNV(program: GLuint, index: GLuint, bufSize: GLsizei, length: ptr GLsizei, size: ptr GLsizei, `type`: ptr GLenum, name: cstring)
  proc IndexMask(mask: GLuint)
  proc VertexAttribBinding(attribindex: GLuint, bindingindex: GLuint)
  proc DeleteFencesNV(n: GLsizei, fences: ptr GLuint)
  proc VertexAttribI4ubv(index: GLuint, v: ptr GLubyte)
  proc PathParameterfvNV(path: GLuint, pname: GLenum, value: ptr GLfloat)
  proc VertexStream3fATI(stream: GLenum, x: GLfloat, y: GLfloat, z: GLfloat)
  proc VertexAttribs4svNV(index: GLuint, count: GLsizei, v: ptr GLshort)
  proc VertexAttrib4sNV(index: GLuint, x: GLshort, y: GLshort, z: GLshort, w: GLshort)
  proc AlphaFragmentOp3ATI(op: GLenum, dst: GLuint, dstMod: GLuint, arg1: GLuint, arg1Rep: GLuint, arg1Mod: GLuint, arg2: GLuint, arg2Rep: GLuint, arg2Mod: GLuint, arg3: GLuint, arg3Rep: GLuint, arg3Mod: GLuint)
  proc GetHistogramParameterfv(target: GLenum, pname: GLenum, params: ptr GLfloat)
  proc VertexAttribL1ui64NV(index: GLuint, x: GLuint64Ext)
  proc VertexAttribs3fvNV(index: GLuint, count: GLsizei, v: ptr GLfloat)
  proc MultiTexCoord3ivARB(target: GLenum, v: ptr GLint)
  proc ClipPlanefOES(plane: GLenum, equation: ptr GLfloat)
  proc Vertex3s(x: GLshort, y: GLshort, z: GLshort)
  proc Vertex3dv(v: ptr GLdouble)
  proc WeightPointerOES(size: GLint, `type`: GLenum, stride: GLsizei, `pointer`: pointer)
  proc BindBufferBase(target: GLenum, index: GLuint, buffer: GLuint)
  proc Indexs(c: GLshort)
  proc TessellationFactorAMD(factor: GLfloat)
  proc Color4ubVertex3fSUN(r: GLubyte, g: GLubyte, b: GLubyte, a: GLubyte, x: GLfloat, y: GLfloat, z: GLfloat)
  proc PauseTransformFeedback()
  proc ImageTransformParameterivHP(target: GLenum, pname: GLenum, params: ptr GLint)
  proc Color3dv(v: ptr GLdouble)
  proc RasterPos4sv(v: ptr GLshort)
  proc InvalidateTexSubImage(texture: GLuint, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, width: GLsizei, height: GLsizei, depth: GLsizei)
  proc NormalStream3bvATI(stream: GLenum, coords: ptr GLbyte)
  proc UniformMatrix2x4fv(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat)
  proc Minmax(target: GLenum, internalformat: GLenum, sink: GLboolean)
  proc GetProgramStageiv(program: GLuint, shadertype: GLenum, pname: GLenum, values: ptr GLint)
  proc Scalex(x: GLfixed, y: GLfixed, z: GLfixed)
  proc TexBufferARB(target: GLenum, internalformat: GLenum, buffer: GLuint)
  proc DrawArraysIndirect(mode: GLenum, indirect: pointer)
  proc MatrixLoadTransposefEXT(mode: GLenum, m: ptr GLfloat)
  proc MultiTexCoord2f(target: GLenum, s: GLfloat, t: GLfloat)
  proc DrawRangeElements(mode: GLenum, start: GLuint, `end`: GLuint, count: GLsizei, `type`: GLenum, indices: pointer)
  proc VertexAttrib4NubARB(index: GLuint, x: GLubyte, y: GLubyte, z: GLubyte, w: GLubyte)
  proc MultiTexCoord4xvOES(texture: GLenum, coords: ptr GLfixed)
  proc VertexArrayVertexAttribOffsetEXT(vaobj: GLuint, buffer: GLuint, index: GLuint, size: GLint, `type`: GLenum, normalized: GLboolean, stride: GLsizei, offset: GLintptr)
  proc VertexAttribL1i64vNV(index: GLuint, v: ptr GLint64Ext)
  proc MapBuffer(target: GLenum, access: GLenum)
  proc Uniform1ui(location: GLint, v0: GLuint)
  proc GetPixelMapfv(map: GLenum, values: ptr GLfloat)
  proc TexImage2DMultisampleCoverageNV(target: GLenum, coverageSamples: GLsizei, colorSamples: GLsizei, internalFormat: GLint, width: GLsizei, height: GLsizei, fixedSampleLocations: GLboolean)
  proc Uniform2ivARB(location: GLint, count: GLsizei, value: ptr GLint)
  proc VertexAttribI3ui(index: GLuint, x: GLuint, y: GLuint, z: GLuint)
  proc GetProgramResourceiv(program: GLuint, programInterface: GLenum, index: GLuint, propCount: GLsizei, props: ptr GLenum, bufSize: GLsizei, length: ptr GLsizei, params: ptr GLint)
  proc Uniform4iv(location: GLint, count: GLsizei, value: ptr GLint)
  proc VertexAttrib3f(index: GLuint, x: GLfloat, y: GLfloat, z: GLfloat)
  proc ClientActiveVertexStreamATI(stream: GLenum)
  proc TexCoord4fColor4fNormal3fVertex4fvSUN(tc: ptr GLfloat, c: ptr GLfloat, n: ptr GLfloat, v: ptr GLfloat)
  proc Color3xvOES(components: ptr GLfixed)
  proc VertexPointerListIBM(size: GLint, `type`: GLenum, stride: GLint, `pointer`: ptr pointer, ptrstride: GLint)
  proc ProgramEnvParameter4dARB(target: GLenum, index: GLuint, x: GLdouble, y: GLdouble, z: GLdouble, w: GLdouble)
  proc GetLocalConstantFloatvEXT(id: GLuint, value: GLenum, data: ptr GLfloat)
  proc TexCoordPointerEXT(size: GLint, `type`: GLenum, stride: GLsizei, count: GLsizei, `pointer`: pointer)
  proc TexCoordPointervINTEL(size: GLint, `type`: GLenum, `pointer`: ptr pointer)
  proc SelectPerfMonitorCountersAMD(monitor: GLuint, enable: GLboolean, group: GLuint, numCounters: GLint, counterList: ptr GLuint)
  proc VertexStream4svATI(stream: GLenum, coords: ptr GLshort)
  proc Color3ui(red: GLuint, green: GLuint, blue: GLuint)
  proc BindTransformFeedbackNV(target: GLenum, id: GLuint)
  proc DeformSGIX(mask: GLbitfield)
  proc DeformationMap3fSGIX(target: GLenum, u1: GLfloat, u2: GLfloat, ustride: GLint, uorder: GLint, v1: GLfloat, v2: GLfloat, vstride: GLint, vorder: GLint, w1: GLfloat, w2: GLfloat, wstride: GLint, worder: GLint, points: ptr GLfloat)
  proc NamedBufferSubDataEXT(buffer: GLuint, offset: GLintptr, size: GLsizeiptr, data: pointer)
  proc GetNamedProgramStringEXT(program: GLuint, target: GLenum, pname: GLenum, string: pointer)
  proc CopyPathNV(resultPath: GLuint, srcPath: GLuint)
  proc MapControlPointsNV(target: GLenum, index: GLuint, `type`: GLenum, ustride: GLsizei, vstride: GLsizei, uorder: GLint, vorder: GLint, packed: GLboolean, points: pointer)
  proc GetBufferParameteriv(target: GLenum, pname: GLenum, params: ptr GLint)
  proc UnmapObjectBufferATI(buffer: GLuint)
  proc GetProgramResourceLocation(program: GLuint, programInterface: GLenum, name: cstring): GLint
  proc Uniform4i64vNV(location: GLint, count: GLsizei, value: ptr GLint64Ext)
  proc ImageTransformParameterfHP(target: GLenum, pname: GLenum, param: GLfloat)
  proc ArrayObjectATI(`array`: GLenum, size: GLint, `type`: GLenum, stride: GLsizei, buffer: GLuint, offset: GLuint)
  proc BindBufferRangeEXT(target: GLenum, index: GLuint, buffer: GLuint, offset: GLintptr, size: GLsizeiptr)
  proc VertexArrayVertexAttribFormatEXT(vaobj: GLuint, attribindex: GLuint, size: GLint, `type`: GLenum, normalized: GLboolean, relativeoffset: GLuint)
  proc BindRenderbufferEXT(target: GLenum, renderbuffer: GLuint)
  proc ListParameteriSGIX(list: GLuint, pname: GLenum, param: GLint)
  proc ProgramUniformMatrix2dvEXT(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble)
  proc ProgramUniform2i64vNV(program: GLuint, location: GLint, count: GLsizei, value: ptr GLint64Ext)
  proc ObjectPtrLabelKHR(`ptr`: ptr pointer, length: GLsizei, label: cstring)
  proc VertexAttribL1i64NV(index: GLuint, x: GLint64Ext)
  proc MultiTexBufferEXT(texunit: GLenum, target: GLenum, internalformat: GLenum, buffer: GLuint)
  proc CoverFillPathInstancedNV(numPaths: GLsizei, pathNameType: GLenum, paths: pointer, pathBase: GLuint, coverMode: GLenum, transformType: GLenum, transformValues: ptr GLfloat)
  proc GetVertexAttribIivEXT(index: GLuint, pname: GLenum, params: ptr GLint)
  proc Lightf(light: GLenum, pname: GLenum, param: GLfloat)
  proc GetMinmaxParameterfvEXT(target: GLenum, pname: GLenum, params: ptr GLfloat)
  proc Uniform1d(location: GLint, x: GLdouble)
  proc Lightiv(light: GLenum, pname: GLenum, params: ptr GLint)
  proc VertexAttrib2dvNV(index: GLuint, v: ptr GLdouble)
  proc NormalP3ui(`type`: GLenum, coords: GLuint)
  proc FinalCombinerInputNV(variable: GLenum, input: GLenum, mapping: GLenum, componentUsage: GLenum)
  proc Uniform1uiv(location: GLint, count: GLsizei, value: ptr GLuint)
  proc ValidateProgramARB(programObj: GLhandleArb)
  proc NormalPointer(`type`: GLenum, stride: GLsizei, `pointer`: pointer)
  proc ProgramNamedParameter4fvNV(id: GLuint, len: GLsizei, name: ptr GLubyte, v: ptr GLfloat)
  proc GetBooleanv(pname: GLenum, params: ptr GLboolean)
  proc Tangent3ivEXT(v: ptr GLint)
  proc TexImage3DMultisample(target: GLenum, samples: GLsizei, internalformat: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, fixedsamplelocations: GLboolean)
  proc GetUniformIndices(program: GLuint, uniformCount: GLsizei, uniformNames: cstringArray, uniformIndices: ptr GLuint)
  proc VDPAUInitNV(vdpDevice: pointer, getProcAddress: pointer)
  proc GetMinmaxParameterivEXT(target: GLenum, pname: GLenum, params: ptr GLint)
  proc MultiTexCoord2fvARB(target: GLenum, v: ptr GLfloat)
  proc ProgramEnvParametersI4ivNV(target: GLenum, index: GLuint, count: GLsizei, params: ptr GLint)
  proc ClearTexSubImage(texture: GLuint, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, format: GLenum, `type`: GLenum, data: ptr pointer)
  proc RectxOES(x1: GLfixed, y1: GLfixed, x2: GLfixed, y2: GLfixed)
  proc BlendEquationOES(mode: GLenum)
  proc FramebufferTexture(target: GLenum, attachment: GLenum, texture: GLuint, level: GLint)
  proc GetInstrumentsSGIX(): GLint
  proc FramebufferParameteri(target: GLenum, pname: GLenum, param: GLint)
  proc PathCoverDepthFuncNV(fun: GLenum)
  proc GetTranslatedShaderSourceANGLE(shader: GLuint, bufsize: GLsizei, length: ptr GLsizei, source: cstring)
  proc Indexfv(c: ptr GLfloat)
  proc GetActiveUniformBlockName(program: GLuint, uniformBlockIndex: GLuint, bufSize: GLsizei, length: ptr GLsizei, uniformBlockName: cstring)
  proc Normal3s(nx: GLshort, ny: GLshort, nz: GLshort)
  proc ColorFragmentOp3ATI(op: GLenum, dst: GLuint, dstMask: GLuint, dstMod: GLuint, arg1: GLuint, arg1Rep: GLuint, arg1Mod: GLuint, arg2: GLuint, arg2Rep: GLuint, arg2Mod: GLuint, arg3: GLuint, arg3Rep: GLuint, arg3Mod: GLuint)
  proc GetProgramResourceLocationIndex(program: GLuint, programInterface: GLenum, name: cstring): GLint
  proc GetBooleanIndexedvEXT(target: GLenum, index: GLuint, data: ptr GLboolean)
  proc GenPerfMonitorsAMD(n: GLsizei, monitors: ptr GLuint)
  proc DrawRangeElementsEXT(mode: GLenum, start: GLuint, `end`: GLuint, count: GLsizei, `type`: GLenum, indices: pointer)
  proc FramebufferTexture3D(target: GLenum, attachment: GLenum, textarget: GLenum, texture: GLuint, level: GLint, zoffset: GLint)
  proc GetTexParameterxvOES(target: GLenum, pname: GLenum, params: ptr GLfixed)
  proc CompileShaderIncludeARB(shader: GLuint, count: GLsizei, path: cstringArray, length: ptr GLint)
  proc GetMultiTexParameterfvEXT(texunit: GLenum, target: GLenum, pname: GLenum, params: ptr GLfloat)
  proc EvalPoint2(i: GLint, j: GLint)
  proc GetProgramivNV(id: GLuint, pname: GLenum, params: ptr GLint)
  proc ProgramParameter4fNV(target: GLenum, index: GLuint, x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat)
  proc MultiTexParameterfvEXT(texunit: GLenum, target: GLenum, pname: GLenum, params: ptr GLfloat)
  proc VertexAttrib3svARB(index: GLuint, v: ptr GLshort)
  proc DrawElementArrayAPPLE(mode: GLenum, first: GLint, count: GLsizei)
  proc MultiTexCoord4x(texture: GLenum, s: GLfixed, t: GLfixed, r: GLfixed, q: GLfixed)
  proc UniformMatrix3dv(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble)
  proc VertexAttribPointerARB(index: GLuint, size: GLint, `type`: GLenum, normalized: GLboolean, stride: GLsizei, `pointer`: pointer)
  proc ProgramUniformMatrix3x4dv(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble)
  proc GetFloati_vEXT(pname: GLenum, index: GLuint, params: ptr GLfloat)
  proc GetObjectParameterivAPPLE(objectType: GLenum, name: GLuint, pname: GLenum, params: ptr GLint)
  proc PushGroupMarkerEXT(length: GLsizei, marker: cstring)
  proc ProgramUniform4uivEXT(program: GLuint, location: GLint, count: GLsizei, value: ptr GLuint)
  proc ReplacementCodeuiVertex3fSUN(rc: GLuint, x: GLfloat, y: GLfloat, z: GLfloat)
  proc TexSubImage1DEXT(target: GLenum, level: GLint, xoffset: GLint, width: GLsizei, format: GLenum, `type`: GLenum, pixels: pointer)
  proc ProgramUniform1uivEXT(program: GLuint, location: GLint, count: GLsizei, value: ptr GLuint)
  proc GetFenceivNV(fence: GLuint, pname: GLenum, params: ptr GLint)
  proc GetnCompressedTexImageARB(target: GLenum, lod: GLint, bufSize: GLsizei, img: pointer)
  proc TexGenfOES(coord: GLenum, pname: GLenum, param: GLfloat)
  proc VertexAttrib4dv(index: GLuint, v: ptr GLdouble)
  proc VertexAttribL1ui64vNV(index: GLuint, v: ptr GLuint64Ext)
  proc VertexAttrib4fvARB(index: GLuint, v: ptr GLfloat)
  proc DeleteVertexArraysOES(n: GLsizei, arrays: ptr GLuint)
  proc SamplerParameterIiv(sampler: GLuint, pname: GLenum, param: ptr GLint)
  proc MapGrid1d(un: GLint, u1: GLdouble, u2: GLdouble)
  proc TranslatexOES(x: GLfixed, y: GLfixed, z: GLfixed)
  proc CullFace(mode: GLenum)
  proc PrioritizeTextures(n: GLsizei, textures: ptr GLuint, priorities: ptr GLfloat)
  proc GetSeparableFilterEXT(target: GLenum, format: GLenum, `type`: GLenum, row: pointer, column: pointer, span: pointer)
  proc VertexAttrib4NubvARB(index: GLuint, v: ptr GLubyte)
  proc GetTransformFeedbackVaryingNV(program: GLuint, index: GLuint, location: ptr GLint)
  proc TexCoord4xOES(s: GLfixed, t: GLfixed, r: GLfixed, q: GLfixed)
  proc GetProgramEnvParameterdvARB(target: GLenum, index: GLuint, params: ptr GLdouble)
  proc WindowPos2ivMESA(v: ptr GLint)
  proc GlobalAlphaFactorfSUN(factor: GLfloat)
  proc NormalStream3fvATI(stream: GLenum, coords: ptr GLfloat)
  proc RasterPos4i(x: GLint, y: GLint, z: GLint, w: GLint)
  proc ReleaseShaderCompiler()
  proc ProgramUniformMatrix4fvEXT(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat)
  proc CopyMultiTexImage1DEXT(texunit: GLenum, target: GLenum, level: GLint, internalformat: GLenum, x: GLint, y: GLint, width: GLsizei, border: GLint)
  proc ColorTableParameterfv(target: GLenum, pname: GLenum, params: ptr GLfloat)
  proc SecondaryColor3bvEXT(v: ptr GLbyte)
  proc Map1xOES(target: GLenum, u1: GLfixed, u2: GLfixed, stride: GLint, order: GLint, points: GLfixed)
  proc VertexStream1svATI(stream: GLenum, coords: ptr GLshort)
  proc IsRenderbuffer(renderbuffer: GLuint): GLboolean
  proc PatchParameterfv(pname: GLenum, values: ptr GLfloat)
  proc ProgramUniformMatrix4dvEXT(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble)
  proc VertexAttrib4ubNV(index: GLuint, x: GLubyte, y: GLubyte, z: GLubyte, w: GLubyte)
  proc Vertex2i(x: GLint, y: GLint)
  proc PushClientAttrib(mask: GLbitfield)
  proc DrawArraysEXT(mode: GLenum, first: GLint, count: GLsizei)
  proc CreateProgram(): GLuint
  proc PolygonStipple(mask: ptr GLubyte)
  proc GetColorTableEXT(target: GLenum, format: GLenum, `type`: GLenum, data: pointer)
  proc SharpenTexFuncSGIS(target: GLenum, n: GLsizei, points: ptr GLfloat)
  proc NamedFramebufferTextureEXT(framebuffer: GLuint, attachment: GLenum, texture: GLuint, level: GLint)
  proc WindowPos3fvMESA(v: ptr GLfloat)
  proc Binormal3iEXT(bx: GLint, by: GLint, bz: GLint)
  proc EnableClientStateiEXT(`array`: GLenum, index: GLuint)
  proc ProgramUniform3iv(program: GLuint, location: GLint, count: GLsizei, value: ptr GLint)
  proc ProgramUniform1dEXT(program: GLuint, location: GLint, x: GLdouble)
  proc PollInstrumentsSGIX(marker_p: ptr GLint): GLint
  proc SecondaryColor3f(red: GLfloat, green: GLfloat, blue: GLfloat)
  proc DeleteTransformFeedbacks(n: GLsizei, ids: ptr GLuint)
  proc CoverStrokePathInstancedNV(numPaths: GLsizei, pathNameType: GLenum, paths: pointer, pathBase: GLuint, coverMode: GLenum, transformType: GLenum, transformValues: ptr GLfloat)
  proc IsTextureHandleResidentARB(handle: GLuint64): GLboolean
  proc VariantsvEXT(id: GLuint, `addr`: ptr GLshort)
  proc TexCoordFormatNV(size: GLint, `type`: GLenum, stride: GLsizei)
  proc TexStorage3DEXT(target: GLenum, levels: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei, depth: GLsizei)
  proc Uniform2ui(location: GLint, v0: GLuint, v1: GLuint)
  proc ReplacementCodePointerSUN(`type`: GLenum, stride: GLsizei, `pointer`: ptr pointer)
  proc FramebufferTextureLayerARB(target: GLenum, attachment: GLenum, texture: GLuint, level: GLint, layer: GLint)
  proc Binormal3dvEXT(v: ptr GLdouble)
  proc ProgramUniform2ui64vNV(program: GLuint, location: GLint, count: GLsizei, value: ptr GLuint64Ext)
  proc GetnConvolutionFilterARB(target: GLenum, format: GLenum, `type`: GLenum, bufSize: GLsizei, image: pointer)
  proc StopInstrumentsSGIX(marker: GLint)
  proc VertexAttrib1svNV(index: GLuint, v: ptr GLshort)
  proc VertexAttribs2fvNV(index: GLuint, count: GLsizei, v: ptr GLfloat)
  proc GetInternalformativ(target: GLenum, internalformat: GLenum, pname: GLenum, bufSize: GLsizei, params: ptr GLint)
  proc IsProgramPipelineEXT(pipeline: GLuint): GLboolean
  proc MatrixIndexubvARB(size: GLint, indices: ptr GLubyte)
  proc TexCoord4bOES(s: GLbyte, t: GLbyte, r: GLbyte, q: GLbyte)
  proc SecondaryColor3us(red: GLushort, green: GLushort, blue: GLushort)
  proc GlobalAlphaFactorubSUN(factor: GLubyte)
  proc NamedStringARB(`type`: GLenum, namelen: GLint, name: cstring, stringlen: GLint, string: cstring)
  proc GetAttachedShaders(program: GLuint, maxCount: GLsizei, count: ptr GLsizei, shaders: ptr GLuint)
  proc MatrixRotatefEXT(mode: GLenum, angle: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat)
  proc VertexStream3ivATI(stream: GLenum, coords: ptr GLint)
  proc MatrixIndexuivARB(size: GLint, indices: ptr GLuint)
  proc MatrixRotatedEXT(mode: GLenum, angle: GLdouble, x: GLdouble, y: GLdouble, z: GLdouble)
  proc PathFogGenNV(genMode: GLenum)
  proc MultiTexCoord4hvNV(target: GLenum, v: ptr GLhalfNv)
  proc VertexAttribIPointer(index: GLuint, size: GLint, `type`: GLenum, stride: GLsizei, `pointer`: pointer)
  proc MultiTexCoord3bOES(texture: GLenum, s: GLbyte, t: GLbyte, r: GLbyte)
  proc ResizeBuffersMESA()
  proc PrimitiveRestartIndexNV(index: GLuint)
  proc ProgramUniform4f(program: GLuint, location: GLint, v0: GLfloat, v1: GLfloat, v2: GLfloat, v3: GLfloat)
  proc Color4ubVertex2fSUN(r: GLubyte, g: GLubyte, b: GLubyte, a: GLubyte, x: GLfloat, y: GLfloat)
  proc GetColorTableParameterivEXT(target: GLenum, pname: GLenum, params: ptr GLint)
  proc DepthRangef(n: GLfloat, f: GLfloat)
  proc VertexArrayVertexOffsetEXT(vaobj: GLuint, buffer: GLuint, size: GLint, `type`: GLenum, stride: GLsizei, offset: GLintptr)
  proc MatrixLoaddEXT(mode: GLenum, m: ptr GLdouble)
  proc VariantfvEXT(id: GLuint, `addr`: ptr GLfloat)
  proc ReplacementCodeuiTexCoord2fVertex3fvSUN(rc: ptr GLuint, tc: ptr GLfloat, v: ptr GLfloat)
  proc SamplePatternSGIS(pattern: GLenum)
  proc ProgramUniform3i64NV(program: GLuint, location: GLint, x: GLint64Ext, y: GLint64Ext, z: GLint64Ext)
  proc Uniform3uivEXT(location: GLint, count: GLsizei, value: ptr GLuint)
  proc GetImageTransformParameterivHP(target: GLenum, pname: GLenum, params: ptr GLint)
  proc PopMatrix()
  proc VertexAttrib3sARB(index: GLuint, x: GLshort, y: GLshort, z: GLshort)
  proc GenQueriesEXT(n: GLsizei, ids: ptr GLuint)
  proc GetQueryObjectui64v(id: GLuint, pname: GLenum, params: ptr GLuint64)
  proc WeightusvARB(size: GLint, weights: ptr GLushort)
  proc WindowPos2sARB(x: GLshort, y: GLshort)
  proc GetTextureLevelParameterivEXT(texture: GLuint, target: GLenum, level: GLint, pname: GLenum, params: ptr GLint)
  proc BufferParameteriAPPLE(target: GLenum, pname: GLenum, param: GLint)
  proc MultiModeDrawArraysIBM(mode: ptr GLenum, first: ptr GLint, count: ptr GLsizei, primcount: GLsizei, modestride: GLint)
  proc UniformMatrix2x3fv(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLfloat)
  proc TangentPointerEXT(`type`: GLenum, stride: GLsizei, `pointer`: pointer)
  proc ResetMinmax(target: GLenum)
  proc VertexAttribP1uiv(index: GLuint, `type`: GLenum, normalized: GLboolean, value: ptr GLuint)
  proc PixelMapx(map: GLenum, size: GLint, values: ptr GLfixed)
  proc PixelStoref(pname: GLenum, param: GLfloat)
  proc Binormal3dEXT(bx: GLdouble, by: GLdouble, bz: GLdouble)
  proc VertexAttribs1hvNV(index: GLuint, n: GLsizei, v: ptr GLhalfNv)
  proc VertexAttrib4usvARB(index: GLuint, v: ptr GLushort)
  proc UnmapBuffer(target: GLenum): GLboolean
  proc FlushRasterSGIX()
  proc Color3uiv(v: ptr GLuint)
  proc InvalidateBufferSubData(buffer: GLuint, offset: GLintptr, length: GLsizeiptr)
  proc PassThroughxOES(token: GLfixed)
  proc LockArraysEXT(first: GLint, count: GLsizei)
  proc StencilFuncSeparateATI(frontfunc: GLenum, backfunc: GLenum, `ref`: GLint, mask: GLuint)
  proc ProgramUniform3dvEXT(program: GLuint, location: GLint, count: GLsizei, value: ptr GLdouble)
  proc GenTransformFeedbacks(n: GLsizei, ids: ptr GLuint)
  proc CopyTexSubImage3DOES(target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, x: GLint, y: GLint, width: GLsizei, height: GLsizei)
  proc IsNamedBufferResidentNV(buffer: GLuint): GLboolean
  proc SampleMaskIndexedNV(index: GLuint, mask: GLbitfield)
  proc VDPAUSurfaceAccessNV(surface: GLvdpauSurfaceNv, access: GLenum)
  proc ProgramUniform3dv(program: GLuint, location: GLint, count: GLsizei, value: ptr GLdouble)
  proc DeleteProgram(program: GLuint)
  proc ConvolutionFilter1D(target: GLenum, internalformat: GLenum, width: GLsizei, format: GLenum, `type`: GLenum, image: pointer)
  proc Vertex2f(x: GLfloat, y: GLfloat)
  proc WindowPos4dvMESA(v: ptr GLdouble)
  proc Color4us(red: GLushort, green: GLushort, blue: GLushort, alpha: GLushort)
  proc ColorMask(red: GLboolean, green: GLboolean, blue: GLboolean, alpha: GLboolean)
  proc GetTexEnviv(target: GLenum, pname: GLenum, params: ptr GLint)
  proc ProgramUniform3ivEXT(program: GLuint, location: GLint, count: GLsizei, value: ptr GLint)
  proc SecondaryColor3i(red: GLint, green: GLint, blue: GLint)
  proc GetSamplerParameteriv(sampler: GLuint, pname: GLenum, params: ptr GLint)
  proc DeleteFramebuffersEXT(n: GLsizei, framebuffers: ptr GLuint)
  proc CompressedTexSubImage3D(target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, format: GLenum, imageSize: GLsizei, data: pointer)
  proc Vertex2s(x: GLshort, y: GLshort)
  proc IsQuery(id: GLuint): GLboolean
  proc Fogxv(pname: GLenum, param: ptr GLfixed)
  proc AreProgramsResidentNV(n: GLsizei, programs: ptr GLuint, residences: ptr GLboolean): GLboolean
  proc ShaderSourceARB(shaderObj: GLhandleArb, count: GLsizei, string: cstringArray, length: ptr GLint)
  proc PointSizexOES(size: GLfixed)
  proc PixelTransferf(pname: GLenum, param: GLfloat)
  proc ExtractComponentEXT(res: GLuint, src: GLuint, num: GLuint)
  proc Uniform1fv(location: GLint, count: GLsizei, value: ptr GLfloat)
  proc GetNamedStringARB(namelen: GLint, name: cstring, bufSize: GLsizei, stringlen: ptr GLint, string: cstring)
  proc GetProgramBinaryOES(program: GLuint, bufSize: GLsizei, length: ptr GLsizei, binaryFormat: ptr GLenum, binary: pointer)
  proc DeleteOcclusionQueriesNV(n: GLsizei, ids: ptr GLuint)
  proc EnableClientState(`array`: GLenum)
  proc ProgramBufferParametersIuivNV(target: GLenum, bindingIndex: GLuint, wordIndex: GLuint, count: GLsizei, params: ptr GLuint)
  proc ProgramUniform2ui(program: GLuint, location: GLint, v0: GLuint, v1: GLuint)
  proc ReplacementCodeuiSUN(code: GLuint)
  proc MultMatrixd(m: ptr GLdouble)
  proc InvalidateSubFramebuffer(target: GLenum, numAttachments: GLsizei, attachments: ptr GLenum, x: GLint, y: GLint, width: GLsizei, height: GLsizei)
  proc GenerateMultiTexMipmapEXT(texunit: GLenum, target: GLenum)
  proc DepthRangex(n: GLfixed, f: GLfixed)
  proc GetInteger64i_v(target: GLenum, index: GLuint, data: ptr GLint64)
  proc DrawBuffers(n: GLsizei, bufs: ptr GLenum)
  proc GetPointervEXT(pname: GLenum, params: ptr pointer)
  proc FogxvOES(pname: GLenum, param: ptr GLfixed)
  proc TexCoordP2uiv(`type`: GLenum, coords: ptr GLuint)
  proc VertexFormatNV(size: GLint, `type`: GLenum, stride: GLsizei)
  proc ColorPointervINTEL(size: GLint, `type`: GLenum, `pointer`: ptr pointer)
  proc GetMultiTexParameterivEXT(texunit: GLenum, target: GLenum, pname: GLenum, params: ptr GLint)
  proc MultiTexCoordP4uiv(texture: GLenum, `type`: GLenum, coords: ptr GLuint)
  proc ResetMinmaxEXT(target: GLenum)
  proc CopyBufferSubData(readTarget: GLenum, writeTarget: GLenum, readOffset: GLintptr, writeOffset: GLintptr, size: GLsizeiptr)
  proc SecondaryColor3sv(v: ptr GLshort)
  proc PixelStorex(pname: GLenum, param: GLfixed)
  proc WaitSync(sync: GLsync, flags: GLbitfield, timeout: GLuint64)
  proc VertexAttribI1iv(index: GLuint, v: ptr GLint)
  proc ColorSubTableEXT(target: GLenum, start: GLsizei, count: GLsizei, format: GLenum, `type`: GLenum, data: pointer)
  proc GetDoublev(pname: GLenum, params: ptr GLdouble)
  proc MultiTexParameterivEXT(texunit: GLenum, target: GLenum, pname: GLenum, params: ptr GLint)
  proc MultiTexCoord4svARB(target: GLenum, v: ptr GLshort)
  proc ColorPointerListIBM(size: GLint, `type`: GLenum, stride: GLint, `pointer`: ptr pointer, ptrstride: GLint)
  proc ScissorIndexed(index: GLuint, left: GLint, bottom: GLint, width: GLsizei, height: GLsizei)
  proc StencilOpSeparateATI(face: GLenum, sfail: GLenum, dpfail: GLenum, dppass: GLenum)
  proc LoadName(name: GLuint)
  proc IsTransformFeedbackNV(id: GLuint): GLboolean
  proc PopDebugGroup()
  proc ClipPlanef(p: GLenum, eqn: ptr GLfloat)
  proc DeleteFencesAPPLE(n: GLsizei, fences: ptr GLuint)
  proc GetQueryObjecti64v(id: GLuint, pname: GLenum, params: ptr GLint64)
  proc AlphaFunc(fun: GLenum, `ref`: GLfloat)
  proc IndexPointerEXT(`type`: GLenum, stride: GLsizei, count: GLsizei, `pointer`: pointer)
  proc VertexAttribI3ivEXT(index: GLuint, v: ptr GLint)
  proc Indexub(c: GLubyte)
  proc VertexP2uiv(`type`: GLenum, value: ptr GLuint)
  proc ProgramUniform1uiv(program: GLuint, location: GLint, count: GLsizei, value: ptr GLuint)
  proc DebugMessageInsertKHR(source: GLenum, `type`: GLenum, id: GLuint, severity: GLenum, length: GLsizei, buf: cstring)
  proc Color4b(red: GLbyte, green: GLbyte, blue: GLbyte, alpha: GLbyte)
  proc RenderbufferStorageMultisampleAPPLE(target: GLenum, samples: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei)
  proc MinSampleShading(value: GLfloat)
  proc BindProgramNV(target: GLenum, id: GLuint)
  proc WindowPos3dMESA(x: GLdouble, y: GLdouble, z: GLdouble)
  proc EdgeFlagPointer(stride: GLsizei, `pointer`: pointer)
  proc GetFragDataIndex(program: GLuint, name: cstring): GLint
  proc TexCoord3hNV(s: GLhalfNv, t: GLhalfNv, r: GLhalfNv)
  proc MultiDrawArraysIndirectAMD(mode: GLenum, indirect: pointer, primcount: GLsizei, stride: GLsizei)
  proc FragmentColorMaterialSGIX(face: GLenum, mode: GLenum)
  proc TexGenf(coord: GLenum, pname: GLenum, param: GLfloat)
  proc VertexAttrib4ubvARB(index: GLuint, v: ptr GLubyte)
  proc ClearBufferiv(buffer: GLenum, drawbuffer: GLint, value: ptr GLint)
  proc GenQueriesARB(n: GLsizei, ids: ptr GLuint)
  proc Rectdv(v1: ptr GLdouble, v2: ptr GLdouble)
  proc BlendEquationSeparateEXT(modeRgb: GLenum, modeAlpha: GLenum)
  proc TestFenceAPPLE(fence: GLuint): GLboolean
  proc TexGeniv(coord: GLenum, pname: GLenum, params: ptr GLint)
  proc PolygonMode(face: GLenum, mode: GLenum)
  proc FrameZoomSGIX(factor: GLint)
  proc ReplacementCodeuiTexCoord2fVertex3fSUN(rc: GLuint, s: GLfloat, t: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat)
  proc UniformSubroutinesuiv(shadertype: GLenum, count: GLsizei, indices: ptr GLuint)
  proc BeginQueryIndexed(target: GLenum, index: GLuint, id: GLuint)
  proc MultiTexGeniEXT(texunit: GLenum, coord: GLenum, pname: GLenum, param: GLint)
  proc RasterPos3fv(v: ptr GLfloat)
  proc MapObjectBufferATI(buffer: GLuint)
  proc Indexiv(c: ptr GLint)
  proc VertexAttribLPointer(index: GLuint, size: GLint, `type`: GLenum, stride: GLsizei, `pointer`: pointer)
  proc MultiTexCoord4s(target: GLenum, s: GLshort, t: GLshort, r: GLshort, q: GLshort)
  proc SecondaryColorP3uiv(`type`: GLenum, color: ptr GLuint)
  proc NormalFormatNV(`type`: GLenum, stride: GLsizei)
  proc Vertex4i(x: GLint, y: GLint, z: GLint, w: GLint)
  proc Uniform1ui64NV(location: GLint, x: GLuint64Ext)
  proc ScissorIndexedv(index: GLuint, v: ptr GLint)
  proc ProgramUniform1i(program: GLuint, location: GLint, v0: GLint)
  proc CompressedMultiTexSubImage3DEXT(texunit: GLenum, target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, format: GLenum, imageSize: GLsizei, bits: pointer)
  proc FinishTextureSUNX()
  proc FramebufferTexture3DEXT(target: GLenum, attachment: GLenum, textarget: GLenum, texture: GLuint, level: GLint, zoffset: GLint)
  proc SetInvariantEXT(id: GLuint, `type`: GLenum, `addr`: pointer)
  proc GetTexParameterIivEXT(target: GLenum, pname: GLenum, params: ptr GLint)
  proc MultiTexCoordP3ui(texture: GLenum, `type`: GLenum, coords: GLuint)
  proc MultiTexCoord3f(target: GLenum, s: GLfloat, t: GLfloat, r: GLfloat)
  proc NormalStream3fATI(stream: GLenum, nx: GLfloat, ny: GLfloat, nz: GLfloat)
  proc ActiveShaderProgram(pipeline: GLuint, program: GLuint)
  proc DisableVertexArrayEXT(vaobj: GLuint, `array`: GLenum)
  proc VertexAttribI3iv(index: GLuint, v: ptr GLint)
  proc ProvokingVertex(mode: GLenum)
  proc TexCoord1fv(v: ptr GLfloat)
  proc VertexAttrib3fv(index: GLuint, v: ptr GLfloat)
  proc WindowPos3iv(v: ptr GLint)
  proc ProgramUniform4ui64NV(program: GLuint, location: GLint, x: GLuint64Ext, y: GLuint64Ext, z: GLuint64Ext, w: GLuint64Ext)
  proc ProgramUniform2d(program: GLuint, location: GLint, v0: GLdouble, v1: GLdouble)
  proc DebugMessageInsertARB(source: GLenum, `type`: GLenum, id: GLuint, severity: GLenum, length: GLsizei, buf: cstring)
  proc MultiTexSubImage3DEXT(texunit: GLenum, target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, format: GLenum, `type`: GLenum, pixels: pointer)
  proc Map1d(target: GLenum, u1: GLdouble, u2: GLdouble, stride: GLint, order: GLint, points: ptr GLdouble)
  proc DeleteShader(shader: GLuint)
  proc TexturePageCommitmentEXT(texture: GLuint, target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, resident: GLboolean)
  proc FramebufferDrawBufferEXT(framebuffer: GLuint, mode: GLenum)
  proc TexCoord2fNormal3fVertex3fSUN(s: GLfloat, t: GLfloat, nx: GLfloat, ny: GLfloat, nz: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat)
  proc DeleteProgramsNV(n: GLsizei, programs: ptr GLuint)
  proc PointAlongPathNV(path: GLuint, startSegment: GLsizei, numSegments: GLsizei, distance: GLfloat, x: ptr GLfloat, y: ptr GLfloat, tangentX: ptr GLfloat, tangentY: ptr GLfloat): GLboolean
  proc TexCoord1d(s: GLdouble)
  proc StencilStrokePathNV(path: GLuint, reference: GLint, mask: GLuint)
  proc QueryMatrixxOES(mantissa: ptr GLfixed, exponent: ptr GLint): GLbitfield
  proc GetNamedProgramLocalParameterIuivEXT(program: GLuint, target: GLenum, index: GLuint, params: ptr GLuint)
  proc GenerateMipmapOES(target: GLenum)
  proc RenderbufferStorageMultisampleIMG(target: GLenum, samples: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei)
  proc VertexBlendEnviATI(pname: GLenum, param: GLint)
  proc PushAttrib(mask: GLbitfield)
  proc ShaderOp3EXT(op: GLenum, res: GLuint, arg1: GLuint, arg2: GLuint, arg3: GLuint)
  proc EnableVertexAttribArray(index: GLuint)
  proc VertexAttrib4Nbv(index: GLuint, v: ptr GLbyte)
  proc ExtGetBuffersQCOM(buffers: ptr GLuint, maxBuffers: GLint, numBuffers: ptr GLint)
  proc CopyTexSubImage3D(target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, x: GLint, y: GLint, width: GLsizei, height: GLsizei)
  proc DeletePerfMonitorsAMD(n: GLsizei, monitors: ptr GLuint)
  proc GetTrackMatrixivNV(target: GLenum, address: GLuint, pname: GLenum, params: ptr GLint)
  proc EndConditionalRender()
  proc VertexAttribL3i64NV(index: GLuint, x: GLint64Ext, y: GLint64Ext, z: GLint64Ext)
  proc ProgramLocalParametersI4ivNV(target: GLenum, index: GLuint, count: GLsizei, params: ptr GLint)
  proc Flush()
  proc GetNamedBufferParameterui64vNV(buffer: GLuint, pname: GLenum, params: ptr GLuint64Ext)
  proc GetVertexArrayIntegeri_vEXT(vaobj: GLuint, index: GLuint, pname: GLenum, param: ptr GLint)
  proc ReadnPixelsEXT(x: GLint, y: GLint, width: GLsizei, height: GLsizei, format: GLenum, `type`: GLenum, bufSize: GLsizei, data: pointer)
  proc MultiTexImage1DEXT(texunit: GLenum, target: GLenum, level: GLint, internalformat: GLint, width: GLsizei, border: GLint, format: GLenum, `type`: GLenum, pixels: pointer)
  proc GetVaryingLocationNV(program: GLuint, name: cstring): GLint
  proc MultiTexCoord4fvARB(target: GLenum, v: ptr GLfloat)
  proc MultiTexCoord3iv(target: GLenum, v: ptr GLint)
  proc VertexAttribL2dvEXT(index: GLuint, v: ptr GLdouble)
  proc TexParameterxOES(target: GLenum, pname: GLenum, param: GLfixed)
  proc SecondaryColor3uivEXT(v: ptr GLuint)
  proc ReadnPixelsARB(x: GLint, y: GLint, width: GLsizei, height: GLsizei, format: GLenum, `type`: GLenum, bufSize: GLsizei, data: pointer)
  proc CopyTexSubImage1DEXT(target: GLenum, level: GLint, xoffset: GLint, x: GLint, y: GLint, width: GLsizei)
  proc GetDoublei_vEXT(pname: GLenum, index: GLuint, params: ptr GLdouble)
  proc VariantPointerEXT(id: GLuint, `type`: GLenum, stride: GLuint, `addr`: pointer)
  proc ProgramUniform3ui64vNV(program: GLuint, location: GLint, count: GLsizei, value: ptr GLuint64Ext)
  proc TexCoord2fColor3fVertex3fvSUN(tc: ptr GLfloat, c: ptr GLfloat, v: ptr GLfloat)
  proc ProgramUniform3fv(program: GLuint, location: GLint, count: GLsizei, value: ptr GLfloat)
  proc BindFragDataLocationIndexed(program: GLuint, colorNumber: GLuint, index: GLuint, name: cstring)
  proc GetnSeparableFilterARB(target: GLenum, format: GLenum, `type`: GLenum, rowBufSize: GLsizei, row: pointer, columnBufSize: GLsizei, column: pointer, span: pointer)
  proc TextureParameteriEXT(texture: GLuint, target: GLenum, pname: GLenum, param: GLint)
  proc GetUniformuivEXT(program: GLuint, location: GLint, params: ptr GLuint)
  proc FragmentMaterialivSGIX(face: GLenum, pname: GLenum, params: ptr GLint)
  proc MultiTexCoord1svARB(target: GLenum, v: ptr GLshort)
  proc ClientActiveTextureARB(texture: GLenum)
  proc VertexAttrib1fARB(index: GLuint, x: GLfloat)
  proc VertexAttrib4NbvARB(index: GLuint, v: ptr GLbyte)
  proc RasterPos2d(x: GLdouble, y: GLdouble)
  proc MultiTexCoord4iARB(target: GLenum, s: GLint, t: GLint, r: GLint, q: GLint)
  proc GetPixelTexGenParameterfvSGIS(pname: GLenum, params: ptr GLfloat)
  proc VertexAttribL2dv(index: GLuint, v: ptr GLdouble)
  proc GetProgramStringARB(target: GLenum, pname: GLenum, string: pointer)
  proc RasterPos2i(x: GLint, y: GLint)
  proc TexCoord2fColor4fNormal3fVertex3fvSUN(tc: ptr GLfloat, c: ptr GLfloat, n: ptr GLfloat, v: ptr GLfloat)
  proc MultiTexCoord3s(target: GLenum, s: GLshort, t: GLshort, r: GLshort)
  proc MultTransposeMatrixd(m: ptr GLdouble)
  proc ActiveVaryingNV(program: GLuint, name: cstring)
  proc ProgramUniform1f(program: GLuint, location: GLint, v0: GLfloat)
  proc GetActiveSubroutineName(program: GLuint, shadertype: GLenum, index: GLuint, bufsize: GLsizei, length: ptr GLsizei, name: cstring)
  proc ClipPlanex(plane: GLenum, equation: ptr GLfixed)
  proc MultiTexCoord4iv(target: GLenum, v: ptr GLint)
  proc TransformFeedbackVaryingsEXT(program: GLuint, count: GLsizei, varyings: cstringArray, bufferMode: GLenum)
  proc BlendEquationSeparateiARB(buf: GLuint, modeRgb: GLenum, modeAlpha: GLenum)
  proc Vertex2sv(v: ptr GLshort)
  proc AccumxOES(op: GLenum, value: GLfixed)
  proc ProgramLocalParameter4dARB(target: GLenum, index: GLuint, x: GLdouble, y: GLdouble, z: GLdouble, w: GLdouble)
  proc IsRenderbufferEXT(renderbuffer: GLuint): GLboolean
  proc MultiDrawElementsIndirectAMD(mode: GLenum, `type`: GLenum, indirect: pointer, primcount: GLsizei, stride: GLsizei)
  proc VertexAttribI4uiEXT(index: GLuint, x: GLuint, y: GLuint, z: GLuint, w: GLuint)
  proc Vertex4fv(v: ptr GLfloat)
  proc GenerateMipmapEXT(target: GLenum)
  proc VertexP3ui(`type`: GLenum, value: GLuint)
  proc TexCoord2dv(v: ptr GLdouble)
  proc FlushMappedBufferRange(target: GLenum, offset: GLintptr, length: GLsizeiptr)
  proc TrackMatrixNV(target: GLenum, address: GLuint, matrix: GLenum, transform: GLenum)
  proc FragmentLightModeliSGIX(pname: GLenum, param: GLint)
  proc VertexAttrib4Nusv(index: GLuint, v: ptr GLushort)
  proc Scalef(x: GLfloat, y: GLfloat, z: GLfloat)
  proc LightxvOES(light: GLenum, pname: GLenum, params: ptr GLfixed)
  proc TextureParameterivEXT(texture: GLuint, target: GLenum, pname: GLenum, params: ptr GLint)
  proc CompressedMultiTexImage3DEXT(texunit: GLenum, target: GLenum, level: GLint, internalformat: GLenum, width: GLsizei, height: GLsizei, depth: GLsizei, border: GLint, imageSize: GLsizei, bits: pointer)
  proc VertexAttribL1d(index: GLuint, x: GLdouble)
  proc VertexAttrib3fARB(index: GLuint, x: GLfloat, y: GLfloat, z: GLfloat)
  proc VertexAttrib3hvNV(index: GLuint, v: ptr GLhalfNv)
  proc SpriteParameteriSGIX(pname: GLenum, param: GLint)
  proc FrustumxOES(left: GLfixed, right: GLfixed, bottom: GLfixed, top: GLfixed, nearVal: GLfixed, farVal: GLfixed)
  proc GetnMapdvARB(target: GLenum, query: GLenum, bufSize: GLsizei, v: ptr GLdouble)
  proc GetMinmaxEXT(target: GLenum, reset: GLboolean, format: GLenum, `type`: GLenum, values: pointer)
  proc ProgramUniformHandleui64NV(program: GLuint, location: GLint, value: GLuint64)
  proc WindowPos4fvMESA(v: ptr GLfloat)
  proc ExtGetTexturesQCOM(textures: ptr GLuint, maxTextures: GLint, numTextures: ptr GLint)
  proc ProgramSubroutineParametersuivNV(target: GLenum, count: GLsizei, params: ptr GLuint)
  proc SampleCoveragexOES(value: GLclampx, invert: GLboolean)
  proc MultiTexEnvivEXT(texunit: GLenum, target: GLenum, pname: GLenum, params: ptr GLint)
  proc GetFinalCombinerInputParameterfvNV(variable: GLenum, pname: GLenum, params: ptr GLfloat)
  proc LightModeliv(pname: GLenum, params: ptr GLint)
  proc Uniform4f(location: GLint, v0: GLfloat, v1: GLfloat, v2: GLfloat, v3: GLfloat)
  proc DepthRange(near: GLdouble, far: GLdouble)
  proc ProgramUniformMatrix4x3dv(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble)
  proc ProgramUniform4fv(program: GLuint, location: GLint, count: GLsizei, value: ptr GLfloat)
  proc GetTexParameterIiv(target: GLenum, pname: GLenum, params: ptr GLint)
  proc VertexAttribs4dvNV(index: GLuint, count: GLsizei, v: ptr GLdouble)
  proc ConvolutionParameteri(target: GLenum, pname: GLenum, params: GLint)
  proc VertexAttribI4uiv(index: GLuint, v: ptr GLuint)
  proc EvalCoord1dv(u: ptr GLdouble)
  proc IsFramebuffer(framebuffer: GLuint): GLboolean
  proc EvalCoord2d(u: GLdouble, v: GLdouble)
  proc ClearDepthf(d: GLfloat)
  proc CompressedTexSubImage2D(target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, width: GLsizei, height: GLsizei, format: GLenum, imageSize: GLsizei, data: pointer)
  proc ProgramUniformMatrix3x2dvEXT(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble)
  proc GetTexParameterxv(target: GLenum, pname: GLenum, params: ptr GLfixed)
  proc Binormal3fEXT(bx: GLfloat, by: GLfloat, bz: GLfloat)
  proc ProgramParameteriARB(program: GLuint, pname: GLenum, value: GLint)
  proc WindowPos3ivMESA(v: ptr GLint)
  proc ReplacementCodeuiColor4fNormal3fVertex3fvSUN(rc: ptr GLuint, c: ptr GLfloat, n: ptr GLfloat, v: ptr GLfloat)
  proc PresentFrameDualFillNV(video_slot: GLuint, minPresentTime: GLuint64Ext, beginPresentTimeId: GLuint, presentDurationId: GLuint, `type`: GLenum, target0: GLenum, fill0: GLuint, target1: GLenum, fill1: GLuint, target2: GLenum, fill2: GLuint, target3: GLenum, fill3: GLuint)
  proc IndexPointerListIBM(`type`: GLenum, stride: GLint, `pointer`: ptr pointer, ptrstride: GLint)
  proc VertexStream2dATI(stream: GLenum, x: GLdouble, y: GLdouble)
  proc UniformMatrix3x4dv(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble)
  proc MapNamedBufferRangeEXT(buffer: GLuint, offset: GLintptr, length: GLsizeiptr, access: GLbitfield)
  proc Color4sv(v: ptr GLshort)
  proc StencilFillPathNV(path: GLuint, fillMode: GLenum, mask: GLuint)
  proc GetVertexAttribfvARB(index: GLuint, pname: GLenum, params: ptr GLfloat)
  proc WindowPos3dv(v: ptr GLdouble)
  proc HintPGI(target: GLenum, mode: GLint)
  proc VertexAttribs3hvNV(index: GLuint, n: GLsizei, v: ptr GLhalfNv)
  proc ProgramUniform1i64NV(program: GLuint, location: GLint, x: GLint64Ext)
  proc ReplacementCodeuiColor3fVertex3fSUN(rc: GLuint, r: GLfloat, g: GLfloat, b: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat)
  proc Uniform2iARB(location: GLint, v0: GLint, v1: GLint)
  proc Viewport(x: GLint, y: GLint, width: GLsizei, height: GLsizei)
  proc BlendFuncSeparateIndexedAMD(buf: GLuint, srcRgb: GLenum, dstRgb: GLenum, srcAlpha: GLenum, dstAlpha: GLenum)
  proc Color3us(red: GLushort, green: GLushort, blue: GLushort)
  proc VertexAttrib2hvNV(index: GLuint, v: ptr GLhalfNv)
  proc GenerateMipmap(target: GLenum)
  proc GetProgramEnvParameterIuivNV(target: GLenum, index: GLuint, params: ptr GLuint)
  proc BlendEquationiARB(buf: GLuint, mode: GLenum)
  proc ReadBufferNV(mode: GLenum)
  proc ProvokingVertexEXT(mode: GLenum)
  proc PointParameterivNV(pname: GLenum, params: ptr GLint)
  proc BlitFramebufferANGLE(srcX0: GLint, srcY0: GLint, srcX1: GLint, srcY1: GLint, dstX0: GLint, dstY0: GLint, dstX1: GLint, dstY1: GLint, mask: GLbitfield, filter: GLenum)
  proc GetObjectParameterivARB(obj: GLhandleArb, pname: GLenum, params: ptr GLint)
  proc GetSubroutineIndex(program: GLuint, shadertype: GLenum, name: cstring): GLuint
  proc Map2d(target: GLenum, u1: GLdouble, u2: GLdouble, ustride: GLint, uorder: GLint, v1: GLdouble, v2: GLdouble, vstride: GLint, vorder: GLint, points: ptr GLdouble)
  proc Rectfv(v1: ptr GLfloat, v2: ptr GLfloat)
  proc DepthRangeArrayv(first: GLuint, count: GLsizei, v: ptr GLdouble)
  proc MultiTexParameteriEXT(texunit: GLenum, target: GLenum, pname: GLenum, param: GLint)
  proc TexStorageSparseAMD(target: GLenum, internalFormat: GLenum, width: GLsizei, height: GLsizei, depth: GLsizei, layers: GLsizei, flags: GLbitfield)
  proc GenerateTextureMipmapEXT(texture: GLuint, target: GLenum)
  proc CopyConvolutionFilter1D(target: GLenum, internalformat: GLenum, x: GLint, y: GLint, width: GLsizei)
  proc Vertex4d(x: GLdouble, y: GLdouble, z: GLdouble, w: GLdouble)
  proc GetPathParameterfvNV(path: GLuint, pname: GLenum, value: ptr GLfloat)
  proc DetachShader(program: GLuint, shader: GLuint)
  proc GetColorTableSGI(target: GLenum, format: GLenum, `type`: GLenum, table: pointer)
  proc PixelTransformParameterfvEXT(target: GLenum, pname: GLenum, params: ptr GLfloat)
  proc BufferSubDataARB(target: GLenum, offset: GLintPtrArb, size: GLsizeiptrArb, data: pointer)
  proc VertexAttrib4ubvNV(index: GLuint, v: ptr GLubyte)
  proc CopyTextureImage1DEXT(texture: GLuint, target: GLenum, level: GLint, internalformat: GLenum, x: GLint, y: GLint, width: GLsizei, border: GLint)
  proc GetQueryivARB(target: GLenum, pname: GLenum, params: ptr GLint)
  proc VertexAttribIPointerEXT(index: GLuint, size: GLint, `type`: GLenum, stride: GLsizei, `pointer`: pointer)
  proc VertexAttribL3dEXT(index: GLuint, x: GLdouble, y: GLdouble, z: GLdouble)
  proc GetQueryObjectui64vEXT(id: GLuint, pname: GLenum, params: ptr GLuint64)
  proc Color4x(red: GLfixed, green: GLfixed, blue: GLfixed, alpha: GLfixed)
  proc ProgramUniformMatrix3x2dv(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble)
  proc VertexAttribI4i(index: GLuint, x: GLint, y: GLint, z: GLint, w: GLint)
  proc VertexAttrib1f(index: GLuint, x: GLfloat)
  proc UnmapBufferOES(target: GLenum): GLboolean
  proc VertexStream2ivATI(stream: GLenum, coords: ptr GLint)
  proc BeginOcclusionQueryNV(id: GLuint)
  proc Vertex4sv(v: ptr GLshort)
  proc Enablei(target: GLenum, index: GLuint)
  proc UseProgramObjectARB(programObj: GLhandleArb)
  proc GetVertexAttribLdvEXT(index: GLuint, pname: GLenum, params: ptr GLdouble)
  proc Uniform2d(location: GLint, x: GLdouble, y: GLdouble)
  proc MinmaxEXT(target: GLenum, internalformat: GLenum, sink: GLboolean)
  proc TexImage3D(target: GLenum, level: GLint, internalformat: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, border: GLint, format: GLenum, `type`: GLenum, pixels: pointer)
  proc GenSymbolsEXT(datatype: GLenum, storagetype: GLenum, range: GLenum, components: GLuint): GLuint
  proc VertexAttribI4svEXT(index: GLuint, v: ptr GLshort)
  proc ProgramEnvParameter4dvARB(target: GLenum, index: GLuint, params: ptr GLdouble)
  proc ProgramUniformMatrix4dv(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble)
  proc GetSamplerParameterfv(sampler: GLuint, pname: GLenum, params: ptr GLfloat)
  proc PopClientAttrib()
  proc Histogram(target: GLenum, width: GLsizei, internalformat: GLenum, sink: GLboolean)
  proc TexEnvfv(target: GLenum, pname: GLenum, params: ptr GLfloat)
  proc MultiTexCoord1dvARB(target: GLenum, v: ptr GLdouble)
  proc GetTexGenivOES(coord: GLenum, pname: GLenum, params: ptr GLint)
  proc Uniform1ivARB(location: GLint, count: GLsizei, value: ptr GLint)
  proc TexCoord3fv(v: ptr GLfloat)
  proc Vertex2xvOES(coords: ptr GLfixed)
  proc TexCoord4fVertex4fvSUN(tc: ptr GLfloat, v: ptr GLfloat)
  proc Uniform2uiv(location: GLint, count: GLsizei, value: ptr GLuint)
  proc MultiTexEnvfvEXT(texunit: GLenum, target: GLenum, pname: GLenum, params: ptr GLfloat)
  proc GetTextureParameterIivEXT(texture: GLuint, target: GLenum, pname: GLenum, params: ptr GLint)
  proc MemoryBarrierEXT(barriers: GLbitfield)
  proc GetTexParameterPointervAPPLE(target: GLenum, pname: GLenum, params: ptr pointer)
  proc WindowPos2svARB(v: ptr GLshort)
  proc EndQuery(target: GLenum)
  proc BlitFramebufferEXT(srcX0: GLint, srcY0: GLint, srcX1: GLint, srcY1: GLint, dstX0: GLint, dstY0: GLint, dstX1: GLint, dstY1: GLint, mask: GLbitfield, filter: GLenum)
  proc ProgramEnvParametersI4uivNV(target: GLenum, index: GLuint, count: GLsizei, params: ptr GLuint)
  proc GetActiveUniform(program: GLuint, index: GLuint, bufSize: GLsizei, length: ptr GLsizei, size: ptr GLint, `type`: ptr GLenum, name: cstring)
  proc GenAsyncMarkersSGIX(range: GLsizei): GLuint
  proc ClipControlARB(origin: GLenum, depth: GLenum)
  proc DrawElementsInstancedEXT(mode: GLenum, count: GLsizei, `type`: GLenum, indices: pointer, primcount: GLsizei)
  proc GetFragmentMaterialivSGIX(face: GLenum, pname: GLenum, params: ptr GLint)
  proc SwizzleEXT(res: GLuint, `in`: GLuint, outX: GLenum, outY: GLenum, outZ: GLenum, outW: GLenum)
  proc MultiTexCoord1bOES(texture: GLenum, s: GLbyte)
  proc ProgramParameters4dvNV(target: GLenum, index: GLuint, count: GLsizei, v: ptr GLdouble)
  proc WindowPos2s(x: GLshort, y: GLshort)
  proc BlendFuncSeparatei(buf: GLuint, srcRgb: GLenum, dstRgb: GLenum, srcAlpha: GLenum, dstAlpha: GLenum)
  proc MultiModeDrawElementsIBM(mode: ptr GLenum, count: ptr GLsizei, `type`: GLenum, indices: ptr pointer, primcount: GLsizei, modestride: GLint)
  proc Normal3x(nx: GLfixed, ny: GLfixed, nz: GLfixed)
  proc ProgramUniform1fvEXT(program: GLuint, location: GLint, count: GLsizei, value: ptr GLfloat)
  proc TexCoord2hNV(s: GLhalfNv, t: GLhalfNv)
  proc ViewportIndexedfv(index: GLuint, v: ptr GLfloat)
  proc DrawTexxOES(x: GLfixed, y: GLfixed, z: GLfixed, width: GLfixed, height: GLfixed)
  proc ProgramParameter4dvNV(target: GLenum, index: GLuint, v: ptr GLdouble)
  proc DeleteBuffers(n: GLsizei, buffers: ptr GLuint)
  proc GetVertexArrayIntegervEXT(vaobj: GLuint, pname: GLenum, param: ptr GLint)
  proc BindFragDataLocationEXT(program: GLuint, color: GLuint, name: cstring)
  proc GenProgramsNV(n: GLsizei, programs: ptr GLuint)
  proc MultiTexCoord1i(target: GLenum, s: GLint)
  proc CompressedTexImage3DOES(target: GLenum, level: GLint, internalformat: GLenum, width: GLsizei, height: GLsizei, depth: GLsizei, border: GLint, imageSize: GLsizei, data: pointer)
  proc GetQueryivEXT(target: GLenum, pname: GLenum, params: ptr GLint)
  proc ExtGetBufferPointervQCOM(target: GLenum, params: ptr pointer)
  proc Vertex3iv(v: ptr GLint)
  proc VertexAttribL1dvEXT(index: GLuint, v: ptr GLdouble)
  proc ValidateProgramPipeline(pipeline: GLuint)
  proc BindVertexArray(`array`: GLuint)
  proc Uniform2uiEXT(location: GLint, v0: GLuint, v1: GLuint)
  proc Uniform3i(location: GLint, v0: GLint, v1: GLint, v2: GLint)
  proc GetVertexAttribIuiv(index: GLuint, pname: GLenum, params: ptr GLuint)
  proc VertexArrayParameteriAPPLE(pname: GLenum, param: GLint)
  proc VertexAttribL2i64NV(index: GLuint, x: GLint64Ext, y: GLint64Ext)
  proc TexGenivOES(coord: GLenum, pname: GLenum, params: ptr GLint)
  proc IsFramebufferOES(framebuffer: GLuint): GLboolean
  proc Color4ubv(v: ptr GLubyte)
  proc DeleteNamedStringARB(namelen: GLint, name: cstring)
  proc CopyConvolutionFilter1DEXT(target: GLenum, internalformat: GLenum, x: GLint, y: GLint, width: GLsizei)
  proc BufferStorage(target: GLenum, size: GLsizeiptr, data: ptr pointer, flags: GLbitfield)
  proc DrawTexiOES(x: GLint, y: GLint, z: GLint, width: GLint, height: GLint)
  proc RasterPos3dv(v: ptr GLdouble)
  proc IndexMaterialEXT(face: GLenum, mode: GLenum)
  proc GetClipPlanex(plane: GLenum, equation: ptr GLfixed)
  proc IsVertexArrayOES(`array`: GLuint): GLboolean
  proc ColorTableEXT(target: GLenum, internalFormat: GLenum, width: GLsizei, format: GLenum, `type`: GLenum, table: pointer)
  proc CompressedTexImage2D(target: GLenum, level: GLint, internalformat: GLenum, width: GLsizei, height: GLsizei, border: GLint, imageSize: GLsizei, data: pointer)
  proc Lightx(light: GLenum, pname: GLenum, param: GLfixed)
  proc GetTexParameterfv(target: GLenum, pname: GLenum, params: ptr GLfloat)
  proc VertexAttrib4NsvARB(index: GLuint, v: ptr GLshort)
  proc InterleavedArrays(format: GLenum, stride: GLsizei, `pointer`: pointer)
  proc ProgramLocalParameter4fARB(target: GLenum, index: GLuint, x: GLfloat, y: GLfloat, z: GLfloat, w: GLfloat)
  proc PopDebugGroupKHR()
  proc VDPAUUnregisterSurfaceNV(surface: GLvdpauSurfaceNv)
  proc TexCoord1s(s: GLshort)
  proc FramebufferTexture2DMultisampleIMG(target: GLenum, attachment: GLenum, textarget: GLenum, texture: GLuint, level: GLint, samples: GLsizei)
  proc ShaderBinary(count: GLsizei, shaders: ptr GLuint, binaryformat: GLenum, binary: pointer, length: GLsizei)
  proc VertexAttrib2dv(index: GLuint, v: ptr GLdouble)
  proc UniformMatrix4dv(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble)
  proc WeightivARB(size: GLint, weights: ptr GLint)
  proc GetMultiTexParameterIivEXT(texunit: GLenum, target: GLenum, pname: GLenum, params: ptr GLint)
  proc CopyConvolutionFilter2DEXT(target: GLenum, internalformat: GLenum, x: GLint, y: GLint, width: GLsizei, height: GLsizei)
  proc SecondaryColor3hNV(red: GLhalfNv, green: GLhalfNv, blue: GLhalfNv)
  proc VertexAttrib1sv(index: GLuint, v: ptr GLshort)
  proc FrustumfOES(left: GLfloat, right: GLfloat, bottom: GLfloat, top: GLfloat, nearVal: GLfloat, farVal: GLfloat)
  proc VertexStream2iATI(stream: GLenum, x: GLint, y: GLint)
  proc NormalStream3bATI(stream: GLenum, nx: GLbyte, ny: GLbyte, nz: GLbyte)
  proc VertexArrayTexCoordOffsetEXT(vaobj: GLuint, buffer: GLuint, size: GLint, `type`: GLenum, stride: GLsizei, offset: GLintptr)
  proc GetQueryiv(target: GLenum, pname: GLenum, params: ptr GLint)
  proc TransformFeedbackStreamAttribsNV(count: GLsizei, attribs: ptr GLint, nbuffers: GLsizei, bufstreams: ptr GLint, bufferMode: GLenum)
  proc TextureStorage3DEXT(texture: GLuint, target: GLenum, levels: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei, depth: GLsizei)
  proc WindowPos3dvMESA(v: ptr GLdouble)
  proc Uniform2uivEXT(location: GLint, count: GLsizei, value: ptr GLuint)
  proc TextureStorage2DEXT(texture: GLuint, target: GLenum, levels: GLsizei, internalformat: GLenum, width: GLsizei, height: GLsizei)
  proc VertexArrayMultiTexCoordOffsetEXT(vaobj: GLuint, buffer: GLuint, texunit: GLenum, size: GLint, `type`: GLenum, stride: GLsizei, offset: GLintptr)
  proc VertexStream1dvATI(stream: GLenum, coords: ptr GLdouble)
  proc CopyImageSubData(srcName: GLuint, srcTarget: GLenum, srcLevel: GLint, srcX: GLint, srcY: GLint, srcZ: GLint, dstName: GLuint, dstTarget: GLenum, dstLevel: GLint, dstX: GLint, dstY: GLint, dstZ: GLint, srcWidth: GLsizei, srcHeight: GLsizei, srcDepth: GLsizei)
  proc ClearNamedBufferSubDataEXT(buffer: GLuint, internalformat: GLenum, format: GLenum, `type`: GLenum, offset: GLsizeiptr, size: GLsizeiptr, data: ptr pointer)
  proc BindBuffersRange(target: GLenum, first: GLuint, count: GLsizei, buffers: ptr GLuint, offsets: ptr GLintptr, sizes: ptr GLsizeiptr)
  proc GetVertexAttribIuivEXT(index: GLuint, pname: GLenum, params: ptr GLuint)
  proc LoadMatrixx(m: ptr GLfixed)
  proc TransformFeedbackVaryingsNV(program: GLuint, count: GLsizei, locations: ptr GLint, bufferMode: GLenum)
  proc Uniform1i64vNV(location: GLint, count: GLsizei, value: ptr GLint64Ext)
  proc VertexArrayVertexAttribLFormatEXT(vaobj: GLuint, attribindex: GLuint, size: GLint, `type`: GLenum, relativeoffset: GLuint)
  proc ClearBufferuiv(buffer: GLenum, drawbuffer: GLint, value: ptr GLuint)
  proc CombinerOutputNV(stage: GLenum, portion: GLenum, abOutput: GLenum, cdOutput: GLenum, sumOutput: GLenum, scale: GLenum, bias: GLenum, abDotProduct: GLboolean, cdDotProduct: GLboolean, muxSum: GLboolean)
  proc TexImage3DEXT(target: GLenum, level: GLint, internalformat: GLenum, width: GLsizei, height: GLsizei, depth: GLsizei, border: GLint, format: GLenum, `type`: GLenum, pixels: pointer)
  proc PixelTransformParameterivEXT(target: GLenum, pname: GLenum, params: ptr GLint)
  proc ActiveStencilFaceEXT(face: GLenum)
  proc CreateShaderObjectARB(shaderType: GLenum): GLhandleArb
  proc GetTextureParameterivEXT(texture: GLuint, target: GLenum, pname: GLenum, params: ptr GLint)
  proc CopyTextureLevelsAPPLE(destinationTexture: GLuint, sourceTexture: GLuint, sourceBaseLevel: GLint, sourceLevelCount: GLsizei)
  proc VertexAttrib4Nuiv(index: GLuint, v: ptr GLuint)
  proc DrawPixels(width: GLsizei, height: GLsizei, format: GLenum, `type`: GLenum, pixels: pointer)
  proc WindowPos3dvARB(v: ptr GLdouble)
  proc ProgramLocalParameterI4ivNV(target: GLenum, index: GLuint, params: ptr GLint)
  proc RasterPos4s(x: GLshort, y: GLshort, z: GLshort, w: GLshort)
  proc TexCoord2fVertex3fvSUN(tc: ptr GLfloat, v: ptr GLfloat)
  proc GetPathMetricsNV(metricQueryMask: GLbitfield, numPaths: GLsizei, pathNameType: GLenum, paths: pointer, pathBase: GLuint, stride: GLsizei, metrics: ptr GLfloat)
  proc MultiTexCoord4bOES(texture: GLenum, s: GLbyte, t: GLbyte, r: GLbyte, q: GLbyte)
  proc TextureBufferEXT(texture: GLuint, target: GLenum, internalformat: GLenum, buffer: GLuint)
  proc SecondaryColor3fv(v: ptr GLfloat)
  proc MultiTexCoord3fv(target: GLenum, v: ptr GLfloat)
  proc GetTexParameteriv(target: GLenum, pname: GLenum, params: ptr GLint)
  proc Map2xOES(target: GLenum, u1: GLfixed, u2: GLfixed, ustride: GLint, uorder: GLint, v1: GLfixed, v2: GLfixed, vstride: GLint, vorder: GLint, points: GLfixed)
  proc FlushVertexArrayRangeAPPLE(length: GLsizei, `pointer`: pointer)
  proc ActiveTextureARB(texture: GLenum)
  proc GetVertexAttribLi64vNV(index: GLuint, pname: GLenum, params: ptr GLint64Ext)
  proc Normal3bv(v: ptr GLbyte)
  proc CreateSyncFromCLeventARB(context: ptr ClContext, event: ptr ClContext, flags: GLbitfield): GLsync
  proc RenderbufferStorageEXT(target: GLenum, internalformat: GLenum, width: GLsizei, height: GLsizei)
  proc GetCompressedTextureImageEXT(texture: GLuint, target: GLenum, lod: GLint, img: pointer)
  proc ColorFragmentOp2ATI(op: GLenum, dst: GLuint, dstMask: GLuint, dstMod: GLuint, arg1: GLuint, arg1Rep: GLuint, arg1Mod: GLuint, arg2: GLuint, arg2Rep: GLuint, arg2Mod: GLuint)
  proc PixelMapusv(map: GLenum, mapsize: GLsizei, values: ptr GLushort)
  proc GlobalAlphaFactorsSUN(factor: GLshort)
  proc TexParameterxv(target: GLenum, pname: GLenum, params: ptr GLfixed)
  proc EvalCoord2xOES(u: GLfixed, v: GLfixed)
  proc IsList(list: GLuint): GLboolean
  proc VertexAttrib3d(index: GLuint, x: GLdouble, y: GLdouble, z: GLdouble)
  proc SpriteParameterfSGIX(pname: GLenum, param: GLfloat)
  proc PathGlyphRangeNV(firstPathName: GLuint, fontTarget: GLenum, fontName: pointer, fontStyle: GLbitfield, firstGlyph: GLuint, numGlyphs: GLsizei, handleMissingGlyphs: GLenum, pathParameterTemplate: GLuint, emScale: GLfloat)
  proc Uniform3iv(location: GLint, count: GLsizei, value: ptr GLint)
  proc ClearBufferfi(buffer: GLenum, drawbuffer: GLint, depth: GLfloat, stencil: GLint)
  proc WindowPos3sMESA(x: GLshort, y: GLshort, z: GLshort)
  proc GetMapParameterfvNV(target: GLenum, pname: GLenum, params: ptr GLfloat)
  proc BindFragmentShaderATI(id: GLuint)
  proc TexCoord4s(s: GLshort, t: GLshort, r: GLshort, q: GLshort)
  proc GetMultiTexGenfvEXT(texunit: GLenum, coord: GLenum, pname: GLenum, params: ptr GLfloat)
  proc ColorMaterial(face: GLenum, mode: GLenum)
  proc VertexAttribs1svNV(index: GLuint, count: GLsizei, v: ptr GLshort)
  proc EnableVertexAttribAPPLE(index: GLuint, pname: GLenum)
  proc GetDoubleIndexedvEXT(target: GLenum, index: GLuint, data: ptr GLdouble)
  proc Orthof(left: GLfloat, right: GLfloat, bottom: GLfloat, top: GLfloat, nearVal: GLfloat, farVal: GLfloat)
  proc VertexBlendEnvfATI(pname: GLenum, param: GLfloat)
  proc UniformMatrix2x4dv(location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble)
  proc PrioritizeTexturesxOES(n: GLsizei, textures: ptr GLuint, priorities: ptr GLfixed)
  proc GetTextureSamplerHandleNV(texture: GLuint, sampler: GLuint): GLuint64
  proc DeleteVertexArrays(n: GLsizei, arrays: ptr GLuint)
  proc MultiTexCoord1xOES(texture: GLenum, s: GLfixed)
  proc GlobalAlphaFactorusSUN(factor: GLushort)
  proc GetConvolutionParameterxvOES(target: GLenum, pname: GLenum, params: ptr GLfixed)
  proc ProgramUniform4fEXT(program: GLuint, location: GLint, v0: GLfloat, v1: GLfloat, v2: GLfloat, v3: GLfloat)
  proc ProgramUniformMatrix3x4dvEXT(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble)
  proc BindVertexBuffer(bindingindex: GLuint, buffer: GLuint, offset: GLintptr, stride: GLsizei)
  proc GetHistogramParameteriv(target: GLenum, pname: GLenum, params: ptr GLint)
  proc GetShaderPrecisionFormat(shadertype: GLenum, precisiontype: GLenum, range: ptr GLint, precision: ptr GLint)
  proc TextureMaterialEXT(face: GLenum, mode: GLenum)
  proc EvalCoord2xvOES(coords: ptr GLfixed)
  proc WeightuivARB(size: GLint, weights: ptr GLuint)
  proc GetTextureLevelParameterfvEXT(texture: GLuint, target: GLenum, level: GLint, pname: GLenum, params: ptr GLfloat)
  proc VertexAttribP3uiv(index: GLuint, `type`: GLenum, normalized: GLboolean, value: ptr GLuint)
  proc ProgramEnvParameterI4ivNV(target: GLenum, index: GLuint, params: ptr GLint)
  proc Fogi(pname: GLenum, param: GLint)
  proc TexCoord1iv(v: ptr GLint)
  proc ReplacementCodeuiColor4ubVertex3fvSUN(rc: ptr GLuint, c: ptr GLubyte, v: ptr GLfloat)
  proc ProgramUniform1ui(program: GLuint, location: GLint, v0: GLuint)
  proc MultiTexCoord3d(target: GLenum, s: GLdouble, t: GLdouble, r: GLdouble)
  proc BeginVideoCaptureNV(video_capture_slot: GLuint)
  proc EvalCoord1f(u: GLfloat)
  proc MultiTexCoord1hvNV(target: GLenum, v: ptr GLhalfNv)
  proc SecondaryColor3sEXT(red: GLshort, green: GLshort, blue: GLshort)
  proc TextureImage3DEXT(texture: GLuint, target: GLenum, level: GLint, internalformat: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, border: GLint, format: GLenum, `type`: GLenum, pixels: pointer)
  proc CopyTexImage2D(target: GLenum, level: GLint, internalformat: GLenum, x: GLint, y: GLint, width: GLsizei, height: GLsizei, border: GLint)
  proc FinishFenceAPPLE(fence: GLuint)
  proc VertexArrayRangeNV(length: GLsizei, `pointer`: pointer)
  proc LightModelf(pname: GLenum, param: GLfloat)
  proc VertexAttribL1ui64ARB(index: GLuint, x: GLuint64Ext)
  proc PolygonOffset(factor: GLfloat, units: GLfloat)
  proc RasterPos4xOES(x: GLfixed, y: GLfixed, z: GLfixed, w: GLfixed)
  proc VertexAttrib3dvNV(index: GLuint, v: ptr GLdouble)
  proc BeginQuery(target: GLenum, id: GLuint)
  proc WeightfvARB(size: GLint, weights: ptr GLfloat)
  proc GetUniformuiv(program: GLuint, location: GLint, params: ptr GLuint)
  proc IsTextureEXT(texture: GLuint): GLboolean
  proc GetClipPlanef(plane: GLenum, equation: ptr GLfloat)
  proc TexGenxOES(coord: GLenum, pname: GLenum, param: GLfixed)
  proc FramebufferTextureFaceEXT(target: GLenum, attachment: GLenum, texture: GLuint, level: GLint, face: GLenum)
  proc DisableClientState(`array`: GLenum)
  proc TexPageCommitmentARB(target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, resident: GLboolean)
  proc RasterPos4dv(v: ptr GLdouble)
  proc GetLightx(light: GLenum, pname: GLenum, params: ptr GLfixed)
  proc VertexAttrib1hvNV(index: GLuint, v: ptr GLhalfNv)
  proc MultiTexCoord2s(target: GLenum, s: GLshort, t: GLshort)
  proc ProgramUniform2iv(program: GLuint, location: GLint, count: GLsizei, value: ptr GLint)
  proc GetListParameterivSGIX(list: GLuint, pname: GLenum, params: ptr GLint)
  proc ColorFragmentOp1ATI(op: GLenum, dst: GLuint, dstMask: GLuint, dstMod: GLuint, arg1: GLuint, arg1Rep: GLuint, arg1Mod: GLuint)
  proc ReplacementCodeuiTexCoord2fColor4fNormal3fVertex3fSUN(rc: GLuint, s: GLfloat, t: GLfloat, r: GLfloat, g: GLfloat, b: GLfloat, a: GLfloat, nx: GLfloat, ny: GLfloat, nz: GLfloat, x: GLfloat, y: GLfloat, z: GLfloat)
  proc SampleMapATI(dst: GLuint, interp: GLuint, swizzle: GLenum)
  proc ProgramUniform1d(program: GLuint, location: GLint, v0: GLdouble)
  proc BindAttribLocation(program: GLuint, index: GLuint, name: cstring)
  proc GetCombinerStageParameterfvNV(stage: GLenum, pname: GLenum, params: ptr GLfloat)
  proc TexSubImage4DSGIS(target: GLenum, level: GLint, xoffset: GLint, yoffset: GLint, zoffset: GLint, woffset: GLint, width: GLsizei, height: GLsizei, depth: GLsizei, size4d: GLsizei, format: GLenum, `type`: GLenum, pixels: pointer)
  proc GetMapAttribParameterfvNV(target: GLenum, index: GLuint, pname: GLenum, params: ptr GLfloat)
  proc NewObjectBufferATI(size: GLsizei, `pointer`: pointer, usage: GLenum): GLuint
  proc WindowPos4iMESA(x: GLint, y: GLint, z: GLint, w: GLint)
  proc NewList(list: GLuint, mode: GLenum)
  proc Uniform1i64NV(location: GLint, x: GLint64Ext)
  proc TexCoordP3ui(`type`: GLenum, coords: GLuint)
  proc EndQueryEXT(target: GLenum)
  proc GetVertexAttribLdv(index: GLuint, pname: GLenum, params: ptr GLdouble)
  proc StencilMask(mask: GLuint)
  proc VertexAttrib4sv(index: GLuint, v: ptr GLshort)
  proc Rectsv(v1: ptr GLshort, v2: ptr GLshort)
  proc GetVariantArrayObjectfvATI(id: GLuint, pname: GLenum, params: ptr GLfloat)
  proc TexCoord3hvNV(v: ptr GLhalfNv)
  proc GetUniformdv(program: GLuint, location: GLint, params: ptr GLdouble)
  proc SecondaryColor3fvEXT(v: ptr GLfloat)
  proc AlphaFuncx(fun: GLenum, `ref`: GLfixed)
  proc VertexAttribPointerNV(index: GLuint, fsize: GLint, `type`: GLenum, stride: GLsizei, `pointer`: pointer)
  proc ColorTable(target: GLenum, internalformat: GLenum, width: GLsizei, format: GLenum, `type`: GLenum, table: pointer)
  proc ProgramUniformMatrix2x3dv(program: GLuint, location: GLint, count: GLsizei, transpose: GLboolean, value: ptr GLdouble)
{.pop.} # stdcall, hint[XDeclaredButNotUsed]: off.

const
  cUNSIGNED_BYTE* = 0x1401
  cUNSIGNED_SHORT* = 0x1403

  c2X_BIT_ATI* = 0x00000001
  MODELVIEW6_ARB* = 0x8726
  CULL_FACE_MODE* = 0x0B45
  TEXTURE_MAG_FILTER* = 0x2800
  cTRANSFORM_FEEDBACK_VARYINGS_EXT* = 0x8C83
  PATH_JOIN_STYLE_NV* = 0x9079
  FEEDBACK_BUFFER_SIZE* = 0x0DF1
  FRAGMENT_LIGHT0_SGIX* = 0x840C
  DRAW_BUFFER7_ARB* = 0x882C
  POINT_SPRITE_OES* = 0x8861
  INT_SAMPLER_RENDERBUFFER_NV* = 0x8E57
  POST_CONVOLUTION_COLOR_TABLE_SGI* = 0x80D1
  ZOOM_X* = 0x0D16
  DRAW_FRAMEBUFFER_NV* = 0x8CA9
  RGB_FLOAT16_ATI* = 0x881B
  NUM_COMPRESSED_TEXTURE_FORMATS* = 0x86A2
  LINE_STRIP* = 0x0003
  PROXY_POST_COLOR_MATRIX_COLOR_TABLE_SGI* = 0x80D5
  CURRENT_TIME_NV* = 0x8E28
  FRAMEBUFFER_UNSUPPORTED* = 0x8CDD
  PIXEL_TEX_GEN_Q_CEILING_SGIX* = 0x8184
  TRANSFORM_FEEDBACK_VARYING_MAX_LENGTH_EXT* = 0x8C76
  MAP_PERSISTENT_BIT* = 0x0040
  IMAGE_2D_MULTISAMPLE_ARRAY_EXT* = 0x9056
  CON_16_ATI* = 0x8951
  DEPTH_BUFFER_BIT1_QCOM* = 0x00000200
  TEXTURE30_ARB* = 0x84DE
  SAMPLER_BUFFER* = 0x8DC2
  MAX_COLOR_TEXTURE_SAMPLES* = 0x910E
  DEPTH_STENCIL* = 0x84F9
  C4F_N3F_V3F* = 0x2A26
  ZOOM_Y* = 0x0D17
  RGB10* = 0x8052
  PRESERVE_ATI* = 0x8762
  MAX_COMBINED_TEXTURE_IMAGE_UNITS_ARB* = 0x8B4D
  COLOR_ATTACHMENT12_NV* = 0x8CEC
  GREEN_MAX_CLAMP_INGR* = 0x8565
  CURRENT_VERTEX_ATTRIB* = 0x8626
  TEXTURE_SHARED_SIZE* = 0x8C3F
  NORMAL_ARRAY_TYPE* = 0x807E
  DYNAMIC_READ* = 0x88E9
  ALPHA4_EXT* = 0x803B
  REPLACEMENT_CODE_ARRAY_SUN* = 0x85C0
  OFFSET_PROJECTIVE_TEXTURE_RECTANGLE_NV* = 0x8852
  MAX_VERTEX_ATTRIBS_ARB* = 0x8869
  VIDEO_COLOR_CONVERSION_MIN_NV* = 0x902B
  SOURCE3_RGB_NV* = 0x8583
  ALPHA* = 0x1906
  OUTPUT_TEXTURE_COORD16_EXT* = 0x87AD
  cBLEND_EQUATION_EXT* = 0x8009
  BIAS_BIT_ATI* = 0x00000008
  BLEND_EQUATION_RGB* = 0x8009
  SHADER_BINARY_DMP* = 0x9250
  IMAGE_FORMAT_COMPATIBILITY_BY_SIZE* = 0x90C8
  Z4Y12Z4CB12Z4CR12_444_NV* = 0x9037
  READ_PIXELS_TYPE* = 0x828E
  CONVOLUTION_HINT_SGIX* = 0x8316
  TRANSPOSE_AFFINE_3D_NV* = 0x9098
  PIXEL_MAP_B_TO_B* = 0x0C78
  cVERTEX_BLEND_ARB* = 0x86A7
  LIGHT2* = 0x4002
  cBYTE* = 0x1400
  MAX_TESS_CONTROL_ATOMIC_COUNTERS* = 0x92D3
  DOMAIN* = 0x0A02
  PROGRAM_NATIVE_TEMPORARIES_ARB* = 0x88A6
  RELATIVE_CUBIC_CURVE_TO_NV* = 0x0D
  TEXTURE_DEPTH_TYPE_ARB* = 0x8C16
  STENCIL_BACK_PASS_DEPTH_PASS* = 0x8803
  MAX_FRAGMENT_PROGRAM_LOCAL_PARAMETERS_NV* = 0x8868
  ATTRIB_STACK_DEPTH* = 0x0BB0
  DEPTH_COMPONENT16_ARB* = 0x81A5
  cTESSELLATION_MODE_AMD* = 0x9004
  UNSIGNED_INT8_VEC3_NV* = 0x8FEE
  DOUBLE_VEC4* = 0x8FFE
  MAX_TESS_CONTROL_TOTAL_OUTPUT_COMPONENTS* = 0x8E85
  TEXTURE_GREEN_TYPE_ARB* = 0x8C11
  PIXEL_PACK_BUFFER* = 0x88EB
  VERTEX_WEIGHT_ARRAY_EXT* = 0x850C
  HALF_FLOAT* = 0x140B
  REG_0_ATI* = 0x8921
  DEPTH_BUFFER_BIT4_QCOM* = 0x00001000
  UNSIGNED_INT_5_9_9_9_REV_EXT* = 0x8C3E
  DEPTH_COMPONENT16_SGIX* = 0x81A5
  COMPRESSED_RGBA_ASTC_8x5_KHR* = 0x93B5
  EDGE_FLAG_ARRAY_LENGTH_NV* = 0x8F30
  CON_17_ATI* = 0x8952
  PARAMETER_BUFFER_ARB* = 0x80EE
  COLOR_ATTACHMENT6_EXT* = 0x8CE6
  INDEX_ARRAY_EXT* = 0x8077
  ALPHA_SCALE* = 0x0D1C
  LINE_QUALITY_HINT_SGIX* = 0x835B
  SLUMINANCE8* = 0x8C47
  DEBUG_OUTPUT_KHR* = 0x92E0
  TEXTURE_LIGHTING_MODE_HP* = 0x8167
  SPOT_DIRECTION* = 0x1204
  V3F* = 0x2A21
  ALPHA16_EXT* = 0x803E
  DRAW_BUFFER15_NV* = 0x8834
  MIN_PROGRAM_TEXEL_OFFSET_EXT* = 0x8904
  ACTIVE_VARYING_MAX_LENGTH_NV* = 0x8C82
  COLOR_ATTACHMENT10* = 0x8CEA
  COLOR_ARRAY_LIST_STRIDE_IBM* = 103082
  TEXTURE_TARGET_QCOM* = 0x8BDA
  DRAW_BUFFER12_ARB* = 0x8831
  SAMPLE_MASK* = 0x8E51
  TEXTURE_FORMAT_QCOM* = 0x8BD6
  TEXTURE_COMPONENTS* = 0x1003
  PROGRAM_PIPELINE_BINDING* = 0x825A
  HIGH_INT* = 0x8DF5
  MAP_INVALIDATE_BUFFER_BIT* = 0x0008
  LAYOUT_LINEAR_CPU_CACHED_INTEL* = 2
  TEXTURE_DS_SIZE_NV* = 0x871D
  HALF_FLOAT_NV* = 0x140B
  PROXY_POST_COLOR_MATRIX_COLOR_TABLE* = 0x80D5
  UNIFORM_BLOCK_REFERENCED_BY_GEOMETRY_SHADER* = 0x8A45
  COMPRESSED_SRGB8_ALPHA8_ASTC_10x10_KHR* = 0x93DB
  REG_18_ATI* = 0x8933
  MAX_COMBINED_COMPUTE_UNIFORM_COMPONENTS* = 0x8266
  UNPACK_FLIP_Y_WEBGL* = 0x9240
  POLYGON_STIPPLE_BIT* = 0x00000010
  MULTISAMPLE_BUFFER_BIT6_QCOM* = 0x40000000
  ONE_MINUS_SRC_ALPHA* = 0x0303
  RASTERIZER_DISCARD_EXT* = 0x8C89
  BGRA_INTEGER* = 0x8D9B
  MAX_TESS_EVALUATION_ATOMIC_COUNTER_BUFFERS* = 0x92CE
  MODELVIEW1_EXT* = 0x850A
  VERTEX_ELEMENT_SWIZZLE_AMD* = 0x91A4
  MAP1_GRID_SEGMENTS* = 0x0DD1
  PATH_ERROR_POSITION_NV* = 0x90AB
  FOG_COORDINATE_ARRAY_EXT* = 0x8457
  NUM_INPUT_INTERPOLATOR_COMPONENTS_ATI* = 0x8973
  MAX_PROGRAM_TEX_INDIRECTIONS_ARB* = 0x880D
  PATH_GEN_COLOR_FORMAT_NV* = 0x90B2
  BUFFER_VARIABLE* = 0x92E5
  PROXY_TEXTURE_CUBE_MAP_ARB* = 0x851B
  COMPRESSED_SRGB_ALPHA_BPTC_UNORM_ARB* = 0x8E8D
  TEXT_FRAGMENT_SHADER_ATI* = 0x8200
  ALPHA_MAX_SGIX* = 0x8321
  UNPACK_ALIGNMENT* = 0x0CF5
  POST_COLOR_MATRIX_RED_SCALE* = 0x80B4
  CIRCULAR_CW_ARC_TO_NV* = 0xFA
  MAX_SAMPLES_APPLE* = 0x8D57
  c4PASS_3_SGIS* = 0x80A7
  SAMPLER_3D_OES* = 0x8B5F
  UNSIGNED_INT16_VEC2_NV* = 0x8FF1
  UNSIGNED_INT_SAMPLER_1D_ARRAY* = 0x8DD6
  REG_8_ATI* = 0x8929
  UNSIGNED_SHORT_1_5_5_5_REV_EXT* = 0x8366
  QUERY_RESULT_AVAILABLE_EXT* = 0x8867
  INTENSITY8_EXT* = 0x804B
  OUTPUT_TEXTURE_COORD9_EXT* = 0x87A6
  TEXTURE_BINDING_RECTANGLE_NV* = 0x84F6
  OFFSET_PROJECTIVE_TEXTURE_RECTANGLE_SCALE_NV* = 0x8853
  IMAGE_FORMAT_COMPATIBILITY_TYPE* = 0x90C7
  WRITE_ONLY* = 0x88B9
  SAMPLER_1D_SHADOW* = 0x8B61
  DISPATCH_INDIRECT_BUFFER_BINDING* = 0x90EF
  VERTEX_PROGRAM_BINDING_NV* = 0x864A
  RGB8_EXT* = 0x8051
  COMPRESSED_SRGB8_ALPHA8_ASTC_8x8_KHR* = 0x93D7
  CON_5_ATI* = 0x8946
  DUAL_INTENSITY8_SGIS* = 0x8119
  MAX_SAMPLES_EXT* = 0x8D57
  VERTEX_ARRAY_POINTER_EXT* = 0x808E
  COMBINE_EXT* = 0x8570
  MULTISAMPLE_BUFFER_BIT1_QCOM* = 0x02000000
  MAGNITUDE_SCALE_NV* = 0x8712
  SYNC_CONDITION_APPLE* = 0x9113
  RGBA_S3TC* = 0x83A2
  LINE_STIPPLE_REPEAT* = 0x0B26
  TEXTURE_COMPRESSION_HINT* = 0x84EF
  TEXTURE_COMPARE_MODE* = 0x884C
  RGBA_FLOAT_MODE_ATI* = 0x8820
  OPERAND0_RGB* = 0x8590
  SIGNED_RGB8_UNSIGNED_ALPHA8_NV* = 0x870D
  POST_COLOR_MATRIX_GREEN_SCALE_SGI* = 0x80B5
  Z6Y10Z6CB10Z6Y10Z6CR10_422_NV* = 0x9033
  UNPACK_ROW_LENGTH* = 0x0CF2
  DOUBLE_MAT2_EXT* = 0x8F46
  TEXTURE_GEQUAL_R_SGIX* = 0x819D
  UNSIGNED_INT_8_24_REV_MESA* = 0x8752
  DSDT8_NV* = 0x8709
  RESAMPLE_DECIMATE_SGIX* = 0x8430
  DEBUG_SOURCE_OTHER_KHR* = 0x824B
  FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS_ARB* = 0x8DA8
  MAX_VERTEX_UNITS_OES* = 0x86A4
  ISOLINES* = 0x8E7A
  INCR_WRAP* = 0x8507
  BUFFER_MAP_POINTER* = 0x88BD
  INT_SAMPLER_CUBE_MAP_ARRAY* = 0x900E
  UNSIGNED_INT_VEC2* = 0x8DC6
  RENDERBUFFER_HEIGHT_OES* = 0x8D43
  COMPRESSED_RGBA_ASTC_10x10_KHR* = 0x93BB
  PIXEL_TEX_GEN_ALPHA_MS_SGIX* = 0x818A
  LINEAR_SHARPEN_COLOR_SGIS* = 0x80AF
  COLOR_ATTACHMENT5_EXT* = 0x8CE5
  VERTEX_ATTRIB_ARRAY9_NV* = 0x8659
  FOG_COORDINATE_ARRAY_BUFFER_BINDING* = 0x889D
  BLEND_DST_RGB* = 0x80C8
  VERTEX_ARRAY_EXT* = 0x8074
  VERTEX_ARRAY_RANGE_POINTER_NV* = 0x8521
  DEBUG_SEVERITY_MEDIUM_ARB* = 0x9147
  OPERAND0_ALPHA* = 0x8598
  TEXTURE_BINDING_CUBE_MAP* = 0x8514
  ADD_ATI* = 0x8963
  AUX1* = 0x040A
  FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING_EXT* = 0x8210
  FRAMEBUFFER_INCOMPLETE_DIMENSIONS* = 0x8CD9
  MINUS_NV* = 0x929F
  RGB4* = 0x804F
  COMPRESSED_RGBA_ASTC_12x12_KHR* = 0x93BD
  MAX_GEOMETRY_OUTPUT_VERTICES* = 0x8DE0
  SURFACE_STATE_NV* = 0x86EB
  COLOR_MATERIAL_FACE* = 0x0B55
  TEXTURE18_ARB* = 0x84D2
  COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2_OES* = 0x9277
  LOWER_LEFT* = 0x8CA1
  DRAW_BUFFER8_ATI* = 0x882D
  TEXTURE_CONSTANT_DATA_SUNX* = 0x81D6
  SAMPLER_1D* = 0x8B5D
  cPOLYGON_OFFSET_EXT* = 0x8037
  EQUIV* = 0x1509
  QUERY_BUFFER_BINDING* = 0x9193
  COMBINE_ARB* = 0x8570
  MATRIX0_NV* = 0x8630
  CLAMP_TO_BORDER_SGIS* = 0x812D
  INTENSITY8UI_EXT* = 0x8D7F
  TRACK_MATRIX_TRANSFORM_NV* = 0x8649
  SURFACE_MAPPED_NV* = 0x8700
  INT_VEC3_ARB* = 0x8B54
  IMAGE_TRANSFORM_2D_HP* = 0x8161
  PROGRAM_BINARY_RETRIEVABLE_HINT* = 0x8257
  DRAW_BUFFER8_EXT* = 0x882D
  DEPTH_STENCIL_EXT* = 0x84F9
  CONTEXT_PROFILE_MASK* = 0x9126
  MAX_PROGRAM_NATIVE_INSTRUCTIONS_ARB* = 0x88A3
  MATRIX5_ARB* = 0x88C5
  FRAMEBUFFER_UNDEFINED_OES* = 0x8219
  UNPACK_CMYK_HINT_EXT* = 0x800F
  UNSIGNED_NORMALIZED_EXT* = 0x8C17
  ONE* = 1
  EDGE_FLAG_ARRAY_BUFFER_BINDING_ARB* = 0x889B
  TRANSPOSE_PROJECTION_MATRIX* = 0x84E4
  MAX_PROGRAM_TOTAL_OUTPUT_COMPONENTS_NV* = 0x8C28
  CLIP_DISTANCE3* = 0x3003
  c4PASS_1_SGIS* = 0x80A5
  MAX_FRAGMENT_LIGHTS_SGIX* = 0x8404
  TEXTURE_3D_OES* = 0x806F
  TEXTURE0* = 0x84C0
  INT_IMAGE_CUBE_EXT* = 0x905B
  INNOCENT_CONTEXT_RESET_ARB* = 0x8254
  INDEX_ARRAY_TYPE_EXT* = 0x8085
  SAMPLER_OBJECT_AMD* = 0x9155
  INDEX_ARRAY_BUFFER_BINDING_ARB* = 0x8899
  RENDERBUFFER_DEPTH_SIZE_OES* = 0x8D54
  MAX_SAMPLE_MASK_WORDS* = 0x8E59
  COMBINER2_NV* = 0x8552
  COLOR_ARRAY_BUFFER_BINDING_ARB* = 0x8898
  VERTEX_ATTRIB_ARRAY_NORMALIZED_ARB* = 0x886A
  STREAM_DRAW* = 0x88E0
  RGB8I* = 0x8D8F
  cBLEND_COLOR_EXT* = 0x8005
  MAX_VARYING_VECTORS* = 0x8DFC
  COPY_WRITE_BUFFER_BINDING* = 0x8F37
  FIXED_ONLY_ARB* = 0x891D
  INT_VEC4* = 0x8B55
  PROGRAM_PIPELINE_BINDING_EXT* = 0x825A
  UNSIGNED_NORMALIZED_ARB* = 0x8C17
  NUM_INSTRUCTIONS_PER_PASS_ATI* = 0x8971
  PIXEL_MODE_BIT* = 0x00000020
  COMPRESSED_RED_RGTC1* = 0x8DBB
  SHADER_IMAGE_ACCESS_BARRIER_BIT_EXT* = 0x00000020
  VARIANT_DATATYPE_EXT* = 0x87E5
  DARKEN_NV* = 0x9297
  POINT_SIZE_MAX_SGIS* = 0x8127
  OBJECT_ATTACHED_OBJECTS_ARB* = 0x8B85
  SLUMINANCE_ALPHA_EXT* = 0x8C44
  UNSIGNED_INT_IMAGE_CUBE_MAP_ARRAY* = 0x906A
  EDGE_FLAG_ARRAY* = 0x8079
  LINEAR_CLIPMAP_NEAREST_SGIX* = 0x844F
  LUMINANCE_ALPHA32F_EXT* = 0x8819
  NORMAL_BIT_PGI* = 0x08000000
  SECONDARY_COLOR_ARRAY* = 0x845E
  CLIP_PLANE1_IMG* = 0x3001
  REG_19_ATI* = 0x8934
  PIXEL_PACK_BUFFER_BINDING* = 0x88ED
  PIXEL_GROUP_COLOR_SGIS* = 0x8356
  SELECTION_BUFFER_SIZE* = 0x0DF4
  SRC_OUT_NV* = 0x928C
  TEXTURE7* = 0x84C7
  COMPARE_R_TO_TEXTURE* = 0x884E
  DUDV_ATI* = 0x8779
  TEXTURE_BASE_LEVEL* = 0x813C
  PN_TRIANGLES_POINT_MODE_LINEAR_ATI* = 0x87F5
  LAYOUT_LINEAR_INTEL* = 1
  DEPTH_BUFFER_BIT2_QCOM* = 0x00000400
  MAX_TESS_EVALUATION_UNIFORM_BLOCKS* = 0x8E8A
  LIGHT3* = 0x4003
  ALPHA_MAX_CLAMP_INGR* = 0x8567
  RG_INTEGER* = 0x8228
  FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL* = 0x8CD2
  TEXTURE_STACK_DEPTH* = 0x0BA5
  ALREADY_SIGNALED* = 0x911A
  TEXTURE_CUBE_MAP_OES* = 0x8513
  N3F_V3F* = 0x2A25
  SUBTRACT_ARB* = 0x84E7
  ELEMENT_ARRAY_LENGTH_NV* = 0x8F33
  NORMAL_ARRAY_EXT* = 0x8075
  POLYGON_OFFSET_FACTOR_EXT* = 0x8038
  EIGHTH_BIT_ATI* = 0x00000020
  UNSIGNED_INT_SAMPLER_2D_RECT* = 0x8DD5
  OBJECT_ACTIVE_ATTRIBUTES_ARB* = 0x8B89
  MAX_VERTEX_VARYING_COMPONENTS_ARB* = 0x8DDE
  TEXTURE_COORD_ARRAY_STRIDE_EXT* = 0x808A
  c4_BYTES* = 0x1409
  SAMPLE_SHADING* = 0x8C36
  FOG_MODE* = 0x0B65
  CON_7_ATI* = 0x8948
  DRAW_FRAMEBUFFER* = 0x8CA9
  TEXTURE_MEMORY_LAYOUT_INTEL* = 0x83FF
  RGB32I_EXT* = 0x8D83
  VERTEX_ARRAY_STRIDE* = 0x807C
  COLOR_ATTACHMENT3_NV* = 0x8CE3
  NORMAL_ARRAY_PARALLEL_POINTERS_INTEL* = 0x83F6
  CONTRAST_NV* = 0x92A1
  RGBA32F* = 0x8814
  YCBAYCR8A_4224_NV* = 0x9032
  MAX_VERTEX_ATTRIB_RELATIVE_OFFSET* = 0x82D9
  TEXTURE22* = 0x84D6
  TEXTURE_3D* = 0x806F
  STENCIL_PASS_DEPTH_FAIL* = 0x0B95
  PROXY_HISTOGRAM_EXT* = 0x8025
  ATOMIC_COUNTER_BUFFER_ACTIVE_ATOMIC_COUNTERS* = 0x92C5
  MAX_ATOMIC_COUNTER_BUFFER_SIZE* = 0x92D8
  FOG_COORD_ARRAY_TYPE* = 0x8454
  MAP2_VERTEX_4* = 0x0DB8
  PACK_COMPRESSED_SIZE_SGIX* = 0x831C
  POST_TEXTURE_FILTER_SCALE_RANGE_SGIX* = 0x817C
  ITALIC_BIT_NV* = 0x02
  COMPRESSED_LUMINANCE_ALPHA* = 0x84EB
  COLOR_TABLE_SCALE_SGI* = 0x80D6
  DOUBLE_MAT2x4_EXT* = 0x8F4A
  FRAMEBUFFER_ATTACHMENT_ALPHA_SIZE* = 0x8215
  MATRIX11_ARB* = 0x88CB
  REG_5_ATI* = 0x8926
  RGBA2_EXT* = 0x8055
  DISCARD_NV* = 0x8530
  TEXTURE7_ARB* = 0x84C7
  LUMINANCE32UI_EXT* = 0x8D74
  ACTIVE_UNIFORM_BLOCKS* = 0x8A36
  UNSIGNED_INT16_VEC4_NV* = 0x8FF3
  VERTEX_ATTRIB_ARRAY5_NV* = 0x8655
  DOUBLE_MAT3x4* = 0x8F4C
  BOOL* = 0x8B56
  NUM_COMPRESSED_TEXTURE_FORMATS_ARB* = 0x86A2
  COMPRESSED_RGB_ARB* = 0x84ED
  DEBUG_TYPE_MARKER_KHR* = 0x8268
  TEXTURE_DEPTH_QCOM* = 0x8BD4
  VARIABLE_F_NV* = 0x8528
  MAX_PIXEL_MAP_TABLE* = 0x0D34
  DST_COLOR* = 0x0306
  OR_INVERTED* = 0x150D
  cTRANSFORM_FEEDBACK_VARYINGS_NV* = 0x8C83
  RGB_INTEGER* = 0x8D98
  cCOLOR_MATERIAL* = 0x0B57
  DEBUG_SEVERITY_LOW_AMD* = 0x9148
  MIRROR_CLAMP_TO_BORDER_EXT* = 0x8912
  TEXTURE1_ARB* = 0x84C1
  MIN_MAP_BUFFER_ALIGNMENT* = 0x90BC
  MATRIX16_ARB* = 0x88D0
  TEXTURE_ALPHA_TYPE_ARB* = 0x8C13
  PROGRAM_POINT_SIZE* = 0x8642
  COMBINER_AB_OUTPUT_NV* = 0x854A
  COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2_OES* = 0x9276
  RGB4_S3TC* = 0x83A1
  TEXTURE_EXTERNAL_OES* = 0x8D65
  MAX_MAP_TESSELLATION_NV* = 0x86D6
  AUX_DEPTH_STENCIL_APPLE* = 0x8A14
  MAX_DEBUG_LOGGED_MESSAGES_AMD* = 0x9144
  CONSTANT_BORDER* = 0x8151
  RESAMPLE_ZERO_FILL_OML* = 0x8987
  POST_CONVOLUTION_ALPHA_SCALE_EXT* = 0x801F
  OBJECT_VALIDATE_STATUS_ARB* = 0x8B83
  DST_ALPHA* = 0x0304
  COMBINER5_NV* = 0x8555
  VERSION_ES_CL_1_1* = 1
  MOVE_TO_CONTINUES_NV* = 0x90B6
  IMAGE_MAG_FILTER_HP* = 0x815C
  TEXTURE_FREE_MEMORY_ATI* = 0x87FC
  DEBUG_TYPE_PORTABILITY_KHR* = 0x824F
  BUFFER_UPDATE_BARRIER_BIT* = 0x00000200
  FUNC_ADD* = 0x8006
  PN_TRIANGLES_POINT_MODE_ATI* = 0x87F2
  DEBUG_CALLBACK_USER_PARAM_ARB* = 0x8245
  CURRENT_SECONDARY_COLOR* = 0x8459
  DEPENDENT_RGB_TEXTURE_CUBE_MAP_NV* = 0x885A
  FRAGMENT_LIGHT7_SGIX* = 0x8413
  MAP2_TEXTURE_COORD_4* = 0x0DB6
  PACK_ALIGNMENT* = 0x0D05
  VERTEX23_BIT_PGI* = 0x00000004
  MAX_CLIPMAP_DEPTH_SGIX* = 0x8177
  TEXTURE_3D_BINDING_EXT* = 0x806A
  COLOR_ATTACHMENT1* = 0x8CE1
  NEAREST* = 0x2600
  MAX_DEBUG_LOGGED_MESSAGES* = 0x9144
  COMBINER6_NV* = 0x8556
  COLOR_SUM_EXT* = 0x8458
  CONVOLUTION_WIDTH* = 0x8018
  SAMPLE_ALPHA_TO_COVERAGE_ARB* = 0x809E
  DRAW_FRAMEBUFFER_EXT* = 0x8CA9
  PROXY_HISTOGRAM* = 0x8025
  PIXEL_FRAGMENT_ALPHA_SOURCE_SGIS* = 0x8355
  COMPRESSED_RGBA_ASTC_10x5_KHR* = 0x93B8
  SMOOTH_CUBIC_CURVE_TO_NV* = 0x10
  BGR_EXT* = 0x80E0
  PROGRAM_UNDER_NATIVE_LIMITS_ARB* = 0x88B6
  VIBRANCE_BIAS_NV* = 0x8719
  UNPACK_COLORSPACE_CONVERSION_WEBGL* = 0x9243
  SLUMINANCE8_NV* = 0x8C47
  TEXTURE_MAX_LEVEL_SGIS* = 0x813D
  UNIFORM_ATOMIC_COUNTER_BUFFER_INDEX* = 0x92DA
  RGB9_E5_EXT* = 0x8C3D
  CULL_VERTEX_IBM* = 103050
  PROXY_COLOR_TABLE* = 0x80D3
  FRAMEBUFFER_ATTACHMENT_DEPTH_SIZE* = 0x8216
  MAX_FRAGMENT_UNIFORM_COMPONENTS* = 0x8B49
  CCW* = 0x0901
  COLOR_WRITEMASK* = 0x0C23
  TEXTURE19_ARB* = 0x84D3
  VERTEX_STREAM3_ATI* = 0x876F
  ONE_EXT* = 0x87DE
  MAX_SAMPLES* = 0x8D57
  STENCIL_PASS_DEPTH_PASS* = 0x0B96
  PERFMON_RESULT_AVAILABLE_AMD* = 0x8BC4
  RETURN* = 0x0102
  DETAIL_TEXTURE_LEVEL_SGIS* = 0x809A
  UNSIGNED_INT_IMAGE_CUBE_EXT* = 0x9066
  FOG_OFFSET_VALUE_SGIX* = 0x8199
  TEXTURE_MAX_LOD_SGIS* = 0x813B
  TRANSPOSE_COLOR_MATRIX_ARB* = 0x84E6
  DEBUG_SOURCE_APPLICATION_ARB* = 0x824A
  SIGNED_ALPHA_NV* = 0x8705
  UNSIGNED_INT_IMAGE_2D_EXT* = 0x9063
  SHADER_IMAGE_ACCESS_BARRIER_BIT* = 0x00000020
  ATOMIC_COUNTER_BARRIER_BIT* = 0x00001000
  COLOR3_BIT_PGI* = 0x00010000
  MATERIAL_SIDE_HINT_PGI* = 0x1A22C
  LIGHT_MODEL_SPECULAR_VECTOR_APPLE* = 0x85B0
  LINEAR_SHARPEN_SGIS* = 0x80AD
  LUMINANCE_SNORM* = 0x9011
  TEXTURE_LUMINANCE_SIZE* = 0x8060
  REPLACE_MIDDLE_SUN* = 0x0002
  TEXTURE_DEFORMATION_SGIX* = 0x8195
  MULTISAMPLE_BUFFER_BIT7_QCOM* = 0x80000000
  FONT_HAS_KERNING_BIT_NV* = 0x10000000
  COPY* = 0x1503
  cREAD_BUFFER_NV* = 0x0C02
  TRANSPOSE_CURRENT_MATRIX_ARB* = 0x88B7
  VERTEX_ARRAY_OBJECT_AMD* = 0x9154
  TIMEOUT_EXPIRED* = 0x911B
  DYNAMIC_COPY* = 0x88EA
  DRAW_BUFFER2_ARB* = 0x8827
  OUTPUT_TEXTURE_COORD10_EXT* = 0x87A7
  SIGNED_RGBA8_NV* = 0x86FC
  MATRIX6_ARB* = 0x88C6
  OP_SUB_EXT* = 0x8796
  NO_RESET_NOTIFICATION_EXT* = 0x8261
  TEXTURE_BASE_LEVEL_SGIS* = 0x813C
  ALPHA_INTEGER* = 0x8D97
  TEXTURE13* = 0x84CD
  EYE_LINEAR* = 0x2400
  INTENSITY4_EXT* = 0x804A
  SOURCE1_RGB_EXT* = 0x8581
  AUX_BUFFERS* = 0x0C00
  SOURCE0_ALPHA* = 0x8588
  RGB32I* = 0x8D83
  MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS* = 0x8C8A
  VIEW_CLASS_S3TC_DXT1_RGBA* = 0x82CD
  TRANSFORM_FEEDBACK_BUFFER_SIZE_NV* = 0x8C85
  SAMPLER_KHR* = 0x82E6
  WRITEONLY_RENDERING_QCOM* = 0x8823
  PACK_SKIP_ROWS* = 0x0D03
  MAP1_VERTEX_ATTRIB0_4_NV* = 0x8660
  PATH_STENCIL_VALUE_MASK_NV* = 0x90B9
  REPLACE_EXT* = 0x8062
  MODELVIEW3_ARB* = 0x8723
  ONE_MINUS_CONSTANT_ALPHA* = 0x8004
  DSDT8_MAG8_INTENSITY8_NV* = 0x870B
  CURRENT_QUERY_ARB* = 0x8865
  LUMINANCE8_ALPHA8_OES* = 0x8045
  ARRAY_ELEMENT_LOCK_COUNT_EXT* = 0x81A9
  MODELVIEW19_ARB* = 0x8733
  MAX_VERTEX_SHADER_INSTRUCTIONS_EXT* = 0x87C5
  MAX_PROGRAM_NATIVE_TEX_INDIRECTIONS_ARB* = 0x8810
  UNSIGNED_INT_IMAGE_2D_MULTISAMPLE_ARRAY_EXT* = 0x906C
  NORMAL_ARRAY_BUFFER_BINDING* = 0x8897
  AMBIENT* = 0x1200
  TEXTURE_MATERIAL_PARAMETER_EXT* = 0x8352
  COMPRESSED_SRGB8_ALPHA8_ASTC_10x8_KHR* = 0x93DA
  MAX_TESS_CONTROL_UNIFORM_COMPONENTS* = 0x8E7F
  COMPRESSED_LUMINANCE_ALPHA_ARB* = 0x84EB
  MODELVIEW14_ARB* = 0x872E
  INTERLACE_READ_OML* = 0x8981
  RENDERBUFFER_FREE_MEMORY_ATI* = 0x87FD
  EMBOSS_MAP_NV* = 0x855F
  POINT_SIZE_RANGE* = 0x0B12
  FOG_COORDINATE* = 0x8451
  MAJOR_VERSION* = 0x821B
  FRAME_NV* = 0x8E26
  CURRENT_TEXTURE_COORDS* = 0x0B03
  PACK_RESAMPLE_OML* = 0x8984
  DEPTH24_STENCIL8_OES* = 0x88F0
  PROGRAM_BINARY_FORMATS_OES* = 0x87FF
  TRANSLATE_3D_NV* = 0x9091
  TEXTURE_GEN_Q* = 0x0C63
  COLOR_ATTACHMENT0_EXT* = 0x8CE0
  ALPHA12* = 0x803D
  INCR_WRAP_EXT* = 0x8507
  TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN* = 0x8C88
  DUAL_ALPHA12_SGIS* = 0x8112
  EYE_LINE_SGIS* = 0x81F6
  TEXTURE_MAX_LEVEL_APPLE* = 0x813D
  TRIANGLE_FAN* = 0x0006
  DEBUG_GROUP_STACK_DEPTH* = 0x826D
  IMAGE_CLASS_1_X_16* = 0x82BE
  COMPILE* = 0x1300
  LINE_SMOOTH* = 0x0B20
  FEEDBACK_BUFFER_POINTER* = 0x0DF0
  CURRENT_SECONDARY_COLOR_EXT* = 0x8459
  DRAW_BUFFER2_ATI* = 0x8827
  PN_TRIANGLES_NORMAL_MODE_ATI* = 0x87F3
  MODELVIEW0_ARB* = 0x1700
  SRGB8_ALPHA8* = 0x8C43
  TEXTURE_BLUE_TYPE* = 0x8C12
  POST_CONVOLUTION_ALPHA_BIAS* = 0x8023
  PATH_STROKE_BOUNDING_BOX_NV* = 0x90A2
  RGBA16UI* = 0x8D76
  OFFSET_HILO_TEXTURE_2D_NV* = 0x8854
  PREVIOUS_ARB* = 0x8578
  BINORMAL_ARRAY_EXT* = 0x843A
  UNSIGNED_INT_IMAGE_CUBE* = 0x9066
  REG_30_ATI* = 0x893F
  VIEWPORT_SUBPIXEL_BITS* = 0x825C
  VERSION* = 0x1F02
  COMPUTE_PROGRAM_PARAMETER_BUFFER_NV* = 0x90FC
  DEBUG_CATEGORY_SHADER_COMPILER_AMD* = 0x914E
  CONVOLUTION_FILTER_SCALE_EXT* = 0x8014
  HALF_BIT_ATI* = 0x00000008
  SPRITE_AXIS_SGIX* = 0x814A
  INDEX_ARRAY_STRIDE* = 0x8086
  PROGRAM_NATIVE_ADDRESS_REGISTERS_ARB* = 0x88B2
  EVAL_VERTEX_ATTRIB0_NV* = 0x86C6
  COUNTER_RANGE_AMD* = 0x8BC1
  VERTEX_WEIGHTING_EXT* = 0x8509
  POST_CONVOLUTION_GREEN_SCALE* = 0x801D
  UNSIGNED_INT8_NV* = 0x8FEC
  CURRENT_MATRIX_STACK_DEPTH_NV* = 0x8640
  STENCIL_INDEX1_OES* = 0x8D46
  SLUMINANCE_NV* = 0x8C46
  UNSIGNED_INT_8_8_8_8_REV_EXT* = 0x8367
  HISTOGRAM_FORMAT* = 0x8027
  LUMINANCE12_ALPHA4_EXT* = 0x8046
  FLOAT_MAT3* = 0x8B5B
  MAX_PROGRAM_TEXEL_OFFSET_NV* = 0x8905
  PALETTE8_RGBA4_OES* = 0x8B98
  UNPACK_SKIP_IMAGES_EXT* = 0x806D
  TEXTURE_CUBE_MAP_NEGATIVE_Y* = 0x8518
  UNPACK_SUBSAMPLE_RATE_SGIX* = 0x85A1
  NORMAL_ARRAY_LENGTH_NV* = 0x8F2C
  VERTEX_ATTRIB_ARRAY4_NV* = 0x8654
  FRAMEBUFFER_INCOMPLETE_DIMENSIONS_OES* = 0x8CD9
  UNSIGNED_BYTE* = 0x1401
  RGB2_EXT* = 0x804E
  TEXTURE_BUFFER_SIZE* = 0x919E
  MAP_STENCIL* = 0x0D11
  TIMEOUT_EXPIRED_APPLE* = 0x911B
  MAX_GEOMETRY_TEXTURE_IMAGE_UNITS* = 0x8C29
  CON_14_ATI* = 0x894F
  RGBA12* = 0x805A
  MAX_SPARSE_ARRAY_TEXTURE_LAYERS* = 0x919A
  CON_20_ATI* = 0x8955
  LOCAL_CONSTANT_DATATYPE_EXT* = 0x87ED
  DUP_FIRST_CUBIC_CURVE_TO_NV* = 0xF2
  SECONDARY_COLOR_ARRAY_ADDRESS_NV* = 0x8F27
  TEXTURE_COORD_ARRAY* = 0x8078
  LUMINANCE8I_EXT* = 0x8D92
  REPLACE_OLDEST_SUN* = 0x0003
  TEXTURE_SHADER_NV* = 0x86DE
  UNSIGNED_INT_8_8_8_8_EXT* = 0x8035
  SAMPLE_COVERAGE_INVERT* = 0x80AB
  FOG_COORD_ARRAY_ADDRESS_NV* = 0x8F28
  GPU_DISJOINT_EXT* = 0x8FBB
  STENCIL_BACK_PASS_DEPTH_PASS_ATI* = 0x8803
  TEXTURE_GREEN_SIZE_EXT* = 0x805D
  INTERLEAVED_ATTRIBS* = 0x8C8C
  cFOG_FUNC_SGIS* = 0x812A
  TEXTURE_DEPTH_SIZE_ARB* = 0x884A
  MAP_COHERENT_BIT* = 0x0080
  COMPRESSED_SLUMINANCE_ALPHA* = 0x8C4B
  RGB32UI* = 0x8D71
  SEPARABLE_2D* = 0x8012
  MATRIX10_ARB* = 0x88CA
  FLOAT_RGBA32_NV* = 0x888B
  MAX_SPARSE_3D_TEXTURE_SIZE_ARB* = 0x9199
  TEXTURE_RENDERBUFFER_DATA_STORE_BINDING_NV* = 0x8E54
  REG_9_ATI* = 0x892A
  MAP2_VERTEX_ATTRIB14_4_NV* = 0x867E
  OP_EXP_BASE_2_EXT* = 0x8791
  INT_IMAGE_BUFFER_EXT* = 0x905C
  TEXTURE_WRAP_R_EXT* = 0x8072
  DOUBLE_VEC3* = 0x8FFD
  DRAW_BUFFER5_EXT* = 0x882A
  OUTPUT_TEXTURE_COORD7_EXT* = 0x87A4
  DEBUG_OUTPUT_SYNCHRONOUS_ARB* = 0x8242
  MAX_TESS_GEN_LEVEL* = 0x8E7E
  ELEMENT_ARRAY_BUFFER_BINDING_ARB* = 0x8895
  RGBA16I_EXT* = 0x8D88
  REG_10_ATI* = 0x892B
  MAT_EMISSION_BIT_PGI* = 0x00800000
  TEXTURE_COORD_ARRAY_SIZE_EXT* = 0x8088
  RED_BIAS* = 0x0D15
  RGB16F_ARB* = 0x881B
  ANY_SAMPLES_PASSED_CONSERVATIVE* = 0x8D6A
  BLUE_MAX_CLAMP_INGR* = 0x8566
  FLOAT* = 0x1406
  STENCIL_INDEX8_EXT* = 0x8D48
  POINT_SIZE_ARRAY_OES* = 0x8B9C
  INT16_NV* = 0x8FE4
  PALETTE4_RGB8_OES* = 0x8B90
  RENDERBUFFER_GREEN_SIZE_OES* = 0x8D51
  SEPARATE_ATTRIBS_NV* = 0x8C8D
  BOOL_VEC3_ARB* = 0x8B58
  ATOMIC_COUNTER_BUFFER_ACTIVE_ATOMIC_COUNTER_INDICES* = 0x92C6
  STACK_UNDERFLOW_KHR* = 0x0504
  TEXTURE_CUBE_MAP_POSITIVE_Z_ARB* = 0x8519
  COMPRESSED_INTENSITY_ARB* = 0x84EC
  MAX_ASYNC_TEX_IMAGE_SGIX* = 0x835F
  TEXTURE_4D_SGIS* = 0x8134
  TEXCOORD3_BIT_PGI* = 0x40000000
  PIXEL_MAP_I_TO_R_SIZE* = 0x0CB2
  NORMAL_MAP_ARB* = 0x8511
  MAX_CONVOLUTION_HEIGHT* = 0x801B
  COMPRESSED_INTENSITY* = 0x84EC
  FONT_Y_MAX_BOUNDS_BIT_NV* = 0x00080000
  FLOAT_MAT2* = 0x8B5A
  TEXTURE_SRGB_DECODE_EXT* = 0x8A48
  FRAMEBUFFER_BLEND* = 0x828B
  TEXTURE_COORD_ARRAY_LIST_IBM* = 103074
  REG_12_ATI* = 0x892D
  UNSIGNED_INT_ATOMIC_COUNTER* = 0x92DB
  DETAIL_TEXTURE_2D_BINDING_SGIS* = 0x8096
  OCCLUSION_TEST_HP* = 0x8165
  TEXTURE11_ARB* = 0x84CB
  COMPRESSED_SRGB8_ALPHA8_ETC2_EAC* = 0x9279
  BUFFER_MAPPED* = 0x88BC
  VARIANT_ARRAY_STRIDE_EXT* = 0x87E6
  CONVOLUTION_BORDER_COLOR_HP* = 0x8154
  UNPACK_RESAMPLE_OML* = 0x8985
  TRANSFORM_FEEDBACK_BUFFER_SIZE* = 0x8C85
  PROXY_TEXTURE_2D_ARRAY_EXT* = 0x8C1B
  RGBA4_EXT* = 0x8056
  ALPHA32I_EXT* = 0x8D84
  ATOMIC_COUNTER_BUFFER_DATA_SIZE* = 0x92C4
  FRAGMENT_LIGHT_MODEL_AMBIENT_SGIX* = 0x840A
  BINORMAL_ARRAY_TYPE_EXT* = 0x8440
  VIEW_CLASS_S3TC_DXT5_RGBA* = 0x82CF
  TEXTURE_CLIPMAP_OFFSET_SGIX* = 0x8173
  RESTART_SUN* = 0x0001
  PERTURB_EXT* = 0x85AE
  UNSIGNED_BYTE_3_3_2_EXT* = 0x8032
  LUMINANCE16I_EXT* = 0x8D8C
  TEXTURE3_ARB* = 0x84C3
  POINT_SIZE_MIN_EXT* = 0x8126
  OUTPUT_TEXTURE_COORD1_EXT* = 0x879E
  COMPARE_REF_TO_TEXTURE* = 0x884E
  KEEP* = 0x1E00
  FLOAT_MAT2x4* = 0x8B66
  FLOAT_VEC4_ARB* = 0x8B52
  BIAS_BY_NEGATIVE_ONE_HALF_NV* = 0x8541
  BGR* = 0x80E0
  SHADER_BINARY_FORMATS* = 0x8DF8
  CND0_ATI* = 0x896B
  MIRRORED_REPEAT_IBM* = 0x8370
  REFLECTION_MAP_OES* = 0x8512
  MAX_VERTEX_BINDABLE_UNIFORMS_EXT* = 0x8DE2
  R* = 0x2002
  MAX_SHADER_STORAGE_BLOCK_SIZE* = 0x90DE
  ATTRIB_ARRAY_STRIDE_NV* = 0x8624
  VARIABLE_E_NV* = 0x8527
  cHISTOGRAM_EXT* = 0x8024
  TEXTURE_BINDING_BUFFER_ARB* = 0x8C2C
  MAX_SPARSE_TEXTURE_SIZE_ARB* = 0x9198
  TEXTURE5* = 0x84C5
  NUM_ACTIVE_VARIABLES* = 0x9304
  DEPTH_STENCIL_ATTACHMENT* = 0x821A
  WEIGHT_ARRAY_BUFFER_BINDING_ARB* = 0x889E
  AMBIENT_AND_DIFFUSE* = 0x1602
  LAYER_NV* = 0x8DAA
  GLYPH_HORIZONTAL_BEARING_Y_BIT_NV* = 0x08
  TEXTURE8* = 0x84C8
  MODELVIEW5_ARB* = 0x8725
  MAX_COMBINED_ATOMIC_COUNTER_BUFFERS* = 0x92D1
  MAX_TESS_CONTROL_ATOMIC_COUNTER_BUFFERS* = 0x92CD
  BLUE_MIN_CLAMP_INGR* = 0x8562
  MAX_TESS_EVALUATION_SHADER_STORAGE_BLOCKS* = 0x90D9
  TEXTURE_CUBE_MAP_POSITIVE_Z_OES* = 0x8519
  MAX_SAMPLES_IMG* = 0x9135
  QUERY_BY_REGION_WAIT* = 0x8E15
  T* = 0x2001
  VIEW_CLASS_RGTC2_RG* = 0x82D1
  TEXTURE_ENV_MODE* = 0x2200
  COMPRESSED_SRGB8_ETC2* = 0x9275
  MAP_FLUSH_EXPLICIT_BIT* = 0x0010
  COLOR_MATERIAL_PARAMETER* = 0x0B56
  HALF_FLOAT_ARB* = 0x140B
  NOTEQUAL* = 0x0205
  MAP_INVALIDATE_BUFFER_BIT_EXT* = 0x0008
  MAX_GEOMETRY_TEXTURE_IMAGE_UNITS_EXT* = 0x8C29
  DUAL_TEXTURE_SELECT_SGIS* = 0x8124
  TEXTURE31* = 0x84DF
  EVAL_TRIANGULAR_2D_NV* = 0x86C1
  VIDEO_COLOR_CONVERSION_OFFSET_NV* = 0x902C
  COMPRESSED_R11_EAC_OES* = 0x9270
  RGB8_OES* = 0x8051
  CLIP_PLANE2* = 0x3002
  HINT_BIT* = 0x00008000
  TEXTURE6_ARB* = 0x84C6
  FLOAT_VEC2* = 0x8B50
  TRANSFORM_FEEDBACK_BUFFER_SIZE_EXT* = 0x8C85
  MAX_EVAL_ORDER* = 0x0D30
  DUAL_LUMINANCE8_SGIS* = 0x8115
  ALPHA16I_EXT* = 0x8D8A
  IDENTITY_NV* = 0x862A
  VIEW_CLASS_BPTC_UNORM* = 0x82D2
  PATH_DASH_CAPS_NV* = 0x907B
  IGNORE_BORDER_HP* = 0x8150
  PN_TRIANGLES_POINT_MODE_CUBIC_ATI* = 0x87F6
  MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS_EXT* = 0x8C8B
  DRAW_BUFFER1_ATI* = 0x8826
  TEXTURE_MIN_FILTER* = 0x2801
  EVAL_VERTEX_ATTRIB12_NV* = 0x86D2
  INT_IMAGE_2D_ARRAY* = 0x905E
  SRC0_RGB* = 0x8580
  MIN_EXT* = 0x8007
  PROGRAM_PIPELINE_OBJECT_EXT* = 0x8A4F
  STENCIL_BUFFER_BIT* = 0x00000400
  SCREEN_COORDINATES_REND* = 0x8490
  DOUBLE_VEC3_EXT* = 0x8FFD
  SUBSAMPLE_DISTANCE_AMD* = 0x883F
  VERTEX_SHADER_LOCALS_EXT* = 0x87D3
  VERTEX_ATTRIB_ARRAY13_NV* = 0x865D
  COMPRESSED_SRGB8_ALPHA8_ASTC_10x6_KHR* = 0x93D9
  UNSIGNED_NORMALIZED* = 0x8C17
  DRAW_BUFFER10_NV* = 0x882F
  PATH_STROKE_MASK_NV* = 0x9084
  MAX_PROGRAM_NATIVE_TEMPORARIES_ARB* = 0x88A7
  SRGB_ALPHA_EXT* = 0x8C42
  CONST_EYE_NV* = 0x86E5
  MODELVIEW1_ARB* = 0x850A
  FORMAT_SUBSAMPLE_244_244_OML* = 0x8983
  LOGIC_OP_MODE* = 0x0BF0
  CLIP_DISTANCE4* = 0x3004
  DEBUG_CATEGORY_WINDOW_SYSTEM_AMD* = 0x914A
  SAMPLES* = 0x80A9
  UNSIGNED_SHORT_5_5_5_1_EXT* = 0x8034
  POINT_DISTANCE_ATTENUATION* = 0x8129
  c3D_COLOR* = 0x0602
  BGRA* = 0x80E1
  PARAMETER_BUFFER_BINDING_ARB* = 0x80EF
  EDGE_FLAG_ARRAY_LIST_STRIDE_IBM* = 103085
  HSL_LUMINOSITY_NV* = 0x92B0
  PROJECTION_STACK_DEPTH* = 0x0BA4
  COMBINER_BIAS_NV* = 0x8549
  AND* = 0x1501
  TEXTURE27* = 0x84DB
  VERTEX_PROGRAM_CALLBACK_DATA_MESA* = 0x8BB7
  DRAW_BUFFER13_ATI* = 0x8832
  UNSIGNED_SHORT_5_5_5_1* = 0x8034
  PERFMON_GLOBAL_MODE_QCOM* = 0x8FA0
  RED_EXT* = 0x1903
  INNOCENT_CONTEXT_RESET_EXT* = 0x8254
  UNIFORM_BUFFER_START* = 0x8A29
  MAX_UNIFORM_BUFFER_BINDINGS* = 0x8A2F
  SLICE_ACCUM_SUN* = 0x85CC
  DRAW_BUFFER9_ATI* = 0x882E
  VERTEX_PROGRAM_PARAMETER_BUFFER_NV* = 0x8DA2
  READ_FRAMEBUFFER_BINDING_APPLE* = 0x8CAA
  INDEX_ARRAY_LENGTH_NV* = 0x8F2E
  DETAIL_TEXTURE_MODE_SGIS* = 0x809B
  MATRIX13_ARB* = 0x88CD
  ADD_SIGNED_ARB* = 0x8574
  UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE* = 0x910A
  DEPTH_BITS* = 0x0D56
  LUMINANCE_ALPHA_SNORM* = 0x9012
  VIEW_CLASS_RGTC1_RED* = 0x82D0
  cLINE_WIDTH* = 0x0B21
  DRAW_BUFFER14_ATI* = 0x8833
  CON_30_ATI* = 0x895F
  POST_COLOR_MATRIX_BLUE_BIAS* = 0x80BA
  PIXEL_TRANSFORM_2D_EXT* = 0x8330
  CONTEXT_LOST_WEBGL* = 0x9242
  COLOR_TABLE_BLUE_SIZE_SGI* = 0x80DC
  CONSTANT_EXT* = 0x8576
  IMPLEMENTATION_COLOR_READ_TYPE* = 0x8B9A
  HSL_COLOR_NV* = 0x92AF
  LOAD* = 0x0101
  TEXTURE_BIT* = 0x00040000
  FRAMEBUFFER_INCOMPLETE_DIMENSIONS_EXT* = 0x8CD9
  IMAGE_ROTATE_ORIGIN_X_HP* = 0x815A
  DEPTH_BUFFER_BIT6_QCOM* = 0x00004000
  QUERY* = 0x82E3
  INVALID_VALUE* = 0x0501
  PACK_COMPRESSED_BLOCK_HEIGHT* = 0x912C
  MAX_PROGRAM_GENERIC_RESULTS_NV* = 0x8DA6
  BACK_PRIMARY_COLOR_NV* = 0x8C77
  ALPHA8_OES* = 0x803C
  INDEX* = 0x8222
  ATTRIB_ARRAY_SIZE_NV* = 0x8623
  INT_IMAGE_1D_ARRAY* = 0x905D
  LOCATION* = 0x930E
  FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT* = 0x8CD7
  SIMULTANEOUS_TEXTURE_AND_STENCIL_WRITE* = 0x82AF
  RESAMPLE_ZERO_FILL_SGIX* = 0x842F
  VERTEX_ARRAY_BINDING_OES* = 0x85B5
  MATRIX4_ARB* = 0x88C4
  NEXT_BUFFER_NV* = -2
  ELEMENT_ARRAY_BARRIER_BIT* = 0x00000002
  RGBA16_EXT* = 0x805B
  SEPARABLE_2D_EXT* = 0x8012
  R11F_G11F_B10F_EXT* = 0x8C3A
  FRAMEBUFFER_ATTACHMENT_TEXTURE_LAYER_EXT* = 0x8CD4
  IMAGE_2D_EXT* = 0x904D
  DRAW_BUFFER6_NV* = 0x882B
  TEXTURE_RANGE_LENGTH_APPLE* = 0x85B7
  TEXTURE_RED_TYPE_ARB* = 0x8C10
  ALPHA16F_ARB* = 0x881C
  DEBUG_LOGGED_MESSAGES_ARB* = 0x9145
  TRANSPOSE_MODELVIEW_MATRIX_ARB* = 0x84E3
  TRANSFORM_FEEDBACK_BUFFER_BINDING_EXT* = 0x8C8F
  MAX_CONVOLUTION_WIDTH* = 0x801A
  MIN_FRAGMENT_INTERPOLATION_OFFSET_NV* = 0x8E5B
  PIXEL_TILE_CACHE_SIZE_SGIX* = 0x8145
  c4PASS_0_SGIS* = 0x80A4
  PRIMITIVE_RESTART* = 0x8F9D
  RG16_SNORM* = 0x8F99
  SAMPLER_2D_SHADOW_EXT* = 0x8B62
  FRONT* = 0x0404
  PROXY_TEXTURE_2D_MULTISAMPLE_ARRAY* = 0x9103
  SAMPLER_BINDING* = 0x8919
  TEXTURE_2D_STACK_MESAX* = 0x875A
  ASYNC_HISTOGRAM_SGIX* = 0x832C
  IMPLEMENTATION_COLOR_READ_FORMAT_OES* = 0x8B9B
  OP_SET_LT_EXT* = 0x878D
  INTERNALFORMAT_RED_TYPE* = 0x8278
  AUX2* = 0x040B
  CLAMP_FRAGMENT_COLOR* = 0x891B
  BROWSER_DEFAULT_WEBGL* = 0x9244
  IMAGE_CLASS_11_11_10* = 0x82C2
  BUMP_ENVMAP_ATI* = 0x877B
  FLOAT_32_UNSIGNED_INT_24_8_REV_NV* = 0x8DAD
  RG_SNORM* = 0x8F91
  BUMP_ROT_MATRIX_ATI* = 0x8775
  UNIFORM_TYPE* = 0x8A37
  FRAGMENT_COLOR_MATERIAL_PARAMETER_SGIX* = 0x8403
  TEXTURE_BINDING_CUBE_MAP_ARRAY* = 0x900A
  LUMINANCE12* = 0x8041
  QUERY_NO_WAIT_NV* = 0x8E14
  TEXTURE_CUBE_MAP_ARRAY_ARB* = 0x9009
  QUERY_BY_REGION_NO_WAIT_NV* = 0x8E16
  FOG_END* = 0x0B64
  OBJECT_LINK_STATUS_ARB* = 0x8B82
  TEXTURE_COORD_ARRAY_SIZE* = 0x8088
  SOURCE0_ALPHA_ARB* = 0x8588
  TEXTURE_CUBE_MAP_NEGATIVE_Y_ARB* = 0x8518
  FRAGMENT_LIGHT_MODEL_NORMAL_INTERPOLATION_SGIX* = 0x840B
  STATIC_COPY* = 0x88E6
  LINE_WIDTH_RANGE* = 0x0B22
  VERTEX_SOURCE_ATI* = 0x8774
  FLOAT_MAT4x3* = 0x8B6A
  HALF_APPLE* = 0x140B
  TEXTURE11* = 0x84CB
  DECODE_EXT* = 0x8A49
  VERTEX_ARRAY_STRIDE_EXT* = 0x807C
  SAMPLER_BUFFER_EXT* = 0x8DC2
  TEXTURE_LOD_BIAS_EXT* = 0x8501
  MODULATE_SIGNED_ADD_ATI* = 0x8745
  DEPTH_CLEAR_VALUE* = 0x0B73
  COMPRESSED_ALPHA* = 0x84E9
  TEXTURE_1D_STACK_MESAX* = 0x8759
  TEXTURE_FIXED_SAMPLE_LOCATIONS* = 0x9107
  LARGE_CCW_ARC_TO_NV* = 0x16
  COMBINER1_NV* = 0x8551
  ARRAY_SIZE* = 0x92FB
  MAX_COMPUTE_IMAGE_UNIFORMS* = 0x91BD
  TEXTURE_BINDING_EXTERNAL_OES* = 0x8D67
  REG_26_ATI* = 0x893B
  MUL_ATI* = 0x8964
  STENCIL_BUFFER_BIT6_QCOM* = 0x00400000
  INVALID_OPERATION* = 0x0502
  COLOR_SUM* = 0x8458
  OP_CROSS_PRODUCT_EXT* = 0x8797
  COLOR_ATTACHMENT4_NV* = 0x8CE4
  MAX_RECTANGLE_TEXTURE_SIZE_NV* = 0x84F8
  BOOL_ARB* = 0x8B56
  VERTEX_ATTRIB_ARRAY_TYPE_ARB* = 0x8625
  MODELVIEW8_ARB* = 0x8728
  STENCIL_TEST* = 0x0B90
  SRC_OVER_NV* = 0x9288
  COMPRESSED_LUMINANCE* = 0x84EA
  MAX_GEOMETRY_PROGRAM_INVOCATIONS_NV* = 0x8E5A
  WEIGHT_ARRAY_TYPE_ARB* = 0x86A9
  WRITE_PIXEL_DATA_RANGE_POINTER_NV* = 0x887C
  COLOR_ARRAY_STRIDE_EXT* = 0x8083
  BLEND_SRC_ALPHA_EXT* = 0x80CB
  MAX_PROGRAM_LOCAL_PARAMETERS_ARB* = 0x88B4
  SCALAR_EXT* = 0x87BE
  DEBUG_SEVERITY_MEDIUM_KHR* = 0x9147
  IMAGE_SCALE_X_HP* = 0x8155
  LUMINANCE6_ALPHA2_EXT* = 0x8044
  OUTPUT_TEXTURE_COORD22_EXT* = 0x87B3
  CURRENT_PROGRAM* = 0x8B8D
  FRAGMENT_PROGRAM_ARB* = 0x8804
  INFO_LOG_LENGTH* = 0x8B84
  TEXTURE_CUBE_MAP_POSITIVE_Z* = 0x8519
  PROJECTION_MATRIX_FLOAT_AS_INT_BITS_OES* = 0x898E
  PRIMITIVE_RESTART_FIXED_INDEX* = 0x8D69
  ARRAY_BUFFER_ARB* = 0x8892
  DEPTH_STENCIL_MESA* = 0x8750
  LUMINANCE8_OES* = 0x8040
  REFLECTION_MAP_EXT* = 0x8512
  PRIMITIVES_GENERATED* = 0x8C87
  IMAGE_PIXEL_FORMAT* = 0x82A9
  VERTEX_ARRAY_LIST_STRIDE_IBM* = 103080
  MAP2_COLOR_4* = 0x0DB0
  MULTIPLY_NV* = 0x9294
  UNIFORM_BARRIER_BIT_EXT* = 0x00000004
  STENCIL_BUFFER_BIT3_QCOM* = 0x00080000
  REG_7_ATI* = 0x8928
  STATIC_READ_ARB* = 0x88E5
  MATRIX2_ARB* = 0x88C2
  STENCIL_BUFFER_BIT5_QCOM* = 0x00200000
  MAX_VERTEX_TEXTURE_IMAGE_UNITS_ARB* = 0x8B4C
  COMPRESSED_RGBA_PVRTC_2BPPV1_IMG* = 0x8C03
  R1UI_T2F_N3F_V3F_SUN* = 0x85CA
  TEXTURE27_ARB* = 0x84DB
  FRAMEBUFFER_INCOMPLETE_FORMATS_OES* = 0x8CDA
  MAX_PROGRAM_TEXEL_OFFSET* = 0x8905
  INT_SAMPLER_2D_ARRAY_EXT* = 0x8DCF
  DRAW_BUFFER9_EXT* = 0x882E
  RGB5_A1_EXT* = 0x8057
  FIELDS_NV* = 0x8E27
  MAX_TRACK_MATRIX_STACK_DEPTH_NV* = 0x862E
  SHADER_COMPILER* = 0x8DFA
  SRC2_ALPHA* = 0x858A
  TRACE_NAME_MESA* = 0x8756
  MIRROR_CLAMP_TO_EDGE* = 0x8743
  OPERAND0_RGB_EXT* = 0x8590
  UNSIGNED_BYTE_2_3_3_REV_EXT* = 0x8362
  UNSIGNED_INT_2_10_10_10_REV* = 0x8368
  MAX_CLIP_DISTANCES* = 0x0D32
  MAP2_TEXTURE_COORD_3* = 0x0DB5
  DUAL_LUMINANCE16_SGIS* = 0x8117
  TEXTURE_UPDATE_BARRIER_BIT_EXT* = 0x00000100
  IMAGE_BUFFER_EXT* = 0x9051
  REDUCE_EXT* = 0x8016
  EVAL_VERTEX_ATTRIB9_NV* = 0x86CF
  IMAGE_CLASS_4_X_32* = 0x82B9
  MAX_FRAGMENT_BINDABLE_UNIFORMS_EXT* = 0x8DE3
  FRAGMENTS_INSTRUMENT_MAX_SGIX* = 0x8315
  REG_28_ATI* = 0x893D
  VARIABLE_B_NV* = 0x8524
  GET_TEXTURE_IMAGE_TYPE* = 0x8292
  PERCENTAGE_AMD* = 0x8BC3
  MAX_GEOMETRY_TOTAL_OUTPUT_COMPONENTS_ARB* = 0x8DE1
  MAX_COMPUTE_UNIFORM_BLOCKS* = 0x91BB
  FRAMEBUFFER_INCOMPLETE_MULTISAMPLE_APPLE* = 0x8D56
  cPROVOKING_VERTEX* = 0x8E4F
  FRAMEZOOM_FACTOR_SGIX* = 0x818C
  COLOR_TABLE_ALPHA_SIZE* = 0x80DD
  PIXEL_TEXTURE_SGIS* = 0x8353
  MODELVIEW26_ARB* = 0x873A
  MAX_DEBUG_MESSAGE_LENGTH_KHR* = 0x9143
  TEXTURE_CUBE_MAP_POSITIVE_Z_EXT* = 0x8519
  VERTEX_SHADER_LOCAL_CONSTANTS_EXT* = 0x87D2
  DRAW_INDIRECT_LENGTH_NV* = 0x8F42
  OPERAND2_RGB_ARB* = 0x8592
  TESS_EVALUATION_SHADER* = 0x8E87
  INTERLACE_SGIX* = 0x8094
  HARDLIGHT_NV* = 0x929B
  FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE_EXT* = 0x8CD0
  OUTPUT_TEXTURE_COORD6_EXT* = 0x87A3
  SIGNED_LUMINANCE_NV* = 0x8701
  CON_13_ATI* = 0x894E
  CURRENT_TANGENT_EXT* = 0x843B
  UNSIGNED_INT_IMAGE_3D* = 0x9064
  MODELVIEW24_ARB* = 0x8738
  EVAL_FRACTIONAL_TESSELLATION_NV* = 0x86C5
  POINT_SPRITE_NV* = 0x8861
  MULTISAMPLE_EXT* = 0x809D
  INT64_VEC3_NV* = 0x8FEA
  ABGR_EXT* = 0x8000
  MAX_GENERAL_COMBINERS_NV* = 0x854D
  NUM_PROGRAM_BINARY_FORMATS* = 0x87FE
  TEXTURE_LO_SIZE_NV* = 0x871C
  INT_IMAGE_1D_ARRAY_EXT* = 0x905D
  MULTISAMPLE_BUFFER_BIT3_QCOM* = 0x08000000
  TEXTURE_GEN_MODE_OES* = 0x2500
  SECONDARY_COLOR_ARRAY_STRIDE* = 0x845C
  ELEMENT_ARRAY_TYPE_APPLE* = 0x8A0D
  UNPACK_IMAGE_HEIGHT_EXT* = 0x806E
  PALETTE4_R5_G6_B5_OES* = 0x8B92
  TEXTURE_RED_SIZE* = 0x805C
  COLOR_ATTACHMENT7_EXT* = 0x8CE7
  MAX_PROGRAM_TEXTURE_GATHER_OFFSET* = 0x8E5F
  DRAW_BUFFER11* = 0x8830
  MODELVIEW0_MATRIX_EXT* = 0x0BA6
  LAYER_PROVOKING_VERTEX* = 0x825E
  TEXTURE14* = 0x84CE
  ALPHA8_EXT* = 0x803C
  GENERIC_ATTRIB_NV* = 0x8C7D
  FRAGMENT_SHADER_DERIVATIVE_HINT_OES* = 0x8B8B
  STENCIL_ATTACHMENT_OES* = 0x8D20
  MAX_VARYING_FLOATS* = 0x8B4B
  RGB_SNORM* = 0x8F92
  SECONDARY_COLOR_ARRAY_TYPE_EXT* = 0x845B
  MAX_PROGRAM_LOOP_DEPTH_NV* = 0x88F7
  FRAMEBUFFER_ATTACHMENT_TEXTURE_LAYER* = 0x8CD4
  MAX_MODELVIEW_STACK_DEPTH* = 0x0D36
  CON_23_ATI* = 0x8958
  VERTEX_ARRAY_RANGE_POINTER_APPLE* = 0x8521
  VERTEX_ARRAY_BUFFER_BINDING* = 0x8896
  VERTEX_STREAM2_ATI* = 0x876E
  STENCIL* = 0x1802
  IMAGE_2D_ARRAY_EXT* = 0x9053
  RGBA8* = 0x8058
  TEXTURE_SPARSE_ARB* = 0x91A6
  PIXEL_TEX_GEN_ALPHA_NO_REPLACE_SGIX* = 0x8188
  SECONDARY_INTERPOLATOR_ATI* = 0x896D
  MAX_COMBINED_DIMENSIONS* = 0x8282
  DEBUG_TYPE_POP_GROUP* = 0x826A
  IMAGE_CLASS_4_X_8* = 0x82BF
  VERTEX_ARRAY_RANGE_VALID_NV* = 0x851F
  LUMINANCE_ALPHA8UI_EXT* = 0x8D81
  RGBA32F_ARB* = 0x8814
  GLYPH_HEIGHT_BIT_NV* = 0x02
  FOG_COORD_ARRAY_BUFFER_BINDING* = 0x889D
  TRACE_OPERATIONS_BIT_MESA* = 0x0001
  INT8_VEC4_NV* = 0x8FE3
  VERTEX_BINDING_STRIDE* = 0x82D8
  LIGHT_ENV_MODE_SGIX* = 0x8407
  PROXY_TEXTURE_1D_EXT* = 0x8063
  CON_31_ATI* = 0x8960
  TEXTURE_BORDER_COLOR* = 0x1004
  ELEMENT_ARRAY_POINTER_APPLE* = 0x8A0E
  NAME_LENGTH* = 0x92F9
  PIXEL_COUNT_AVAILABLE_NV* = 0x8867
  IUI_V3F_EXT* = 0x81AE
  OBJECT_LINE_SGIS* = 0x81F7
  T2F_N3F_V3F* = 0x2A2B
  TRUE* = GLboolean(1)
  COMPARE_REF_TO_TEXTURE_EXT* = 0x884E
  MAX_3D_TEXTURE_SIZE* = 0x8073
  LUMINANCE16_ALPHA16_EXT* = 0x8048
  DRAW_INDIRECT_ADDRESS_NV* = 0x8F41
  TEXTURE_IMAGE_FORMAT* = 0x828F
  MODELVIEW_MATRIX_FLOAT_AS_INT_BITS_OES* = 0x898D
  TEXTURE_RECTANGLE_ARB* = 0x84F5
  TEXTURE_INDEX_SIZE_EXT* = 0x80ED
  VERTEX_ATTRIB_ARRAY_LENGTH_NV* = 0x8F2A
  DEBUG_CALLBACK_USER_PARAM* = 0x8245
  INTENSITY8_SNORM* = 0x9017
  DISTANCE_ATTENUATION_EXT* = 0x8129
  MAX_TESS_EVALUATION_IMAGE_UNIFORMS* = 0x90CC
  ATTRIB_ARRAY_POINTER_NV* = 0x8645
  OBJECT_TYPE* = 0x9112
  PROGRAM_KHR* = 0x82E2
  SOURCE0_ALPHA_EXT* = 0x8588
  PIXEL_MAP_I_TO_G_SIZE* = 0x0CB3
  RGBA_MODE* = 0x0C31
  COMPRESSED_SRGB8_ALPHA8_ASTC_8x6_KHR* = 0x93D6
  MAX_ELEMENTS_VERTICES_EXT* = 0x80E8
  DEBUG_SOURCE_SHADER_COMPILER* = 0x8248
  ARC_TO_NV* = 0xFE
  CON_6_ATI* = 0x8947
  MAX_OPTIMIZED_VERTEX_SHADER_LOCALS_EXT* = 0x87CE
  VERTEX_ATTRIB_MAP1_DOMAIN_APPLE* = 0x8A05
  R16_SNORM* = 0x8F98
  DOUBLE_VEC2_EXT* = 0x8FFC
  UNSIGNED_INT8_VEC4_NV* = 0x8FEF
  POST_CONVOLUTION_RED_SCALE* = 0x801C
  FULL_STIPPLE_HINT_PGI* = 0x1A219
  ACTIVE_ATTRIBUTES* = 0x8B89
  TEXTURE_MATERIAL_FACE_EXT* = 0x8351
  INCR_WRAP_OES* = 0x8507
  UNPACK_COMPRESSED_BLOCK_WIDTH* = 0x9127
  COMPRESSED_SIGNED_LUMINANCE_ALPHA_LATC2_EXT* = 0x8C73
  MAX_VERTEX_SHADER_LOCALS_EXT* = 0x87C9
  NUM_VIDEO_CAPTURE_STREAMS_NV* = 0x9024
  DRAW_BUFFER3_ARB* = 0x8828
  COMBINER_COMPONENT_USAGE_NV* = 0x8544
  ELEMENT_ARRAY_POINTER_ATI* = 0x876A
  RGB8UI_EXT* = 0x8D7D
  RGBA8I* = 0x8D8E
  TEXTURE_WIDTH_QCOM* = 0x8BD2
  DOT3_RGB* = 0x86AE
  VIDEO_CAPTURE_FIELD_LOWER_HEIGHT_NV* = 0x903B
  TEXTURE_CUBE_MAP_NEGATIVE_X* = 0x8516
  UNIFORM_BUFFER_SIZE* = 0x8A2A
  OPERAND1_ALPHA* = 0x8599
  TEXTURE_INTENSITY_SIZE_EXT* = 0x8061
  DEBUG_TYPE_OTHER* = 0x8251
  MAX_TESS_PATCH_COMPONENTS* = 0x8E84
  UNIFORM_BUFFER_BINDING* = 0x8A28
  INTENSITY_FLOAT16_APPLE* = 0x881D
  TEXTURE_BLUE_SIZE* = 0x805E
  TEXTURE_BUFFER_OFFSET_ALIGNMENT* = 0x919F
  TEXTURE_SWIZZLE_G* = 0x8E43
  MAX_PROGRAM_TEXEL_OFFSET_EXT* = 0x8905
  COLOR_BUFFER_BIT* = 0x00004000
  ALPHA_FLOAT32_APPLE* = 0x8816
  PROXY_TEXTURE_2D_EXT* = 0x8064
  STENCIL_COMPONENTS* = 0x8285
  VIDEO_CAPTURE_TO_422_SUPPORTED_NV* = 0x9026
  TEXTURE_COMPRESSED_ARB* = 0x86A1
  OBJECT_SUBTYPE_ARB* = 0x8B4F
  MAX_PROGRAM_PARAMETERS_ARB* = 0x88A9
  OFFSET_TEXTURE_2D_MATRIX_NV* = 0x86E1
  PN_TRIANGLES_NORMAL_MODE_LINEAR_ATI* = 0x87F7
  PATCH_VERTICES* = 0x8E72
  NEGATIVE_Y_EXT* = 0x87DA
  INT_2_10_10_10_REV* = 0x8D9F
  READ_FRAMEBUFFER_BINDING_NV* = 0x8CAA
  POST_COLOR_MATRIX_COLOR_TABLE_SGI* = 0x80D2
  MAX_FRAGMENT_SHADER_STORAGE_BLOCKS* = 0x90DA
  IMAGE_COMPATIBILITY_CLASS* = 0x82A8
  FLOAT_MAT4* = 0x8B5C
  FIELD_LOWER_NV* = 0x9023
  UNPACK_IMAGE_HEIGHT* = 0x806E
  PATH_COMMAND_COUNT_NV* = 0x909D
  UNSIGNED_SHORT_4_4_4_4_EXT* = 0x8033
  VIEW_CLASS_S3TC_DXT3_RGBA* = 0x82CE
  STENCIL_BUFFER_BIT1_QCOM* = 0x00020000
  BLOCK_INDEX* = 0x92FD
  BUMP_TARGET_ATI* = 0x877C
  PATH_STROKE_COVER_MODE_NV* = 0x9083
  INT_IMAGE_2D_RECT* = 0x905A
  VECTOR_EXT* = 0x87BF
  INDEX_ARRAY_BUFFER_BINDING* = 0x8899
  SAMPLER_2D_SHADOW* = 0x8B62
  OBJECT_BUFFER_SIZE_ATI* = 0x8764
  NORMALIZED_RANGE_EXT* = 0x87E0
  DEPTH_COMPONENT32_OES* = 0x81A7
  CON_9_ATI* = 0x894A
  VIRTUAL_PAGE_SIZE_X_ARB* = 0x9195
  LESS* = 0x0201
  FRAMEBUFFER_UNSUPPORTED_OES* = 0x8CDD
  CON_19_ATI* = 0x8954
  PROGRAM_NATIVE_INSTRUCTIONS_ARB* = 0x88A2
  MAX_TEXTURE_COORDS_ARB* = 0x8871
  TRANSFORM_FEEDBACK_BUFFER_MODE* = 0x8C7F
  TEXTURE_1D_BINDING_EXT* = 0x8068
  LINE_TOKEN* = 0x0702
  FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT_OES* = 0x8CD7
  Z4Y12Z4CB12Z4A12Z4Y12Z4CR12Z4A12_4224_NV* = 0x9036
  TEXTURE_SWIZZLE_R* = 0x8E42
  PIXEL_UNPACK_BUFFER_ARB* = 0x88EC
  UNKNOWN_CONTEXT_RESET_EXT* = 0x8255
  PROGRAM_ERROR_POSITION_NV* = 0x864B
  ONE_MINUS_CONSTANT_COLOR* = 0x8002
  POST_COLOR_MATRIX_GREEN_SCALE* = 0x80B5
  TEXTURE_CUBE_MAP_SEAMLESS* = 0x884F
  DRAW_BUFFER2* = 0x8827
  STENCIL_INDEX* = 0x1901
  FOG_DENSITY* = 0x0B62
  MATRIX27_ARB* = 0x88DB
  CURRENT_NORMAL* = 0x0B02
  AFFINE_3D_NV* = 0x9094
  STATIC_COPY_ARB* = 0x88E6
  c4X_BIT_ATI* = 0x00000002
  COLOR_BUFFER_BIT3_QCOM* = 0x00000008
  TEXTURE_MATRIX* = 0x0BA8
  UNDEFINED_APPLE* = 0x8A1C
  COLOR_TABLE_LUMINANCE_SIZE_SGI* = 0x80DE
  INT_IMAGE_2D_MULTISAMPLE_ARRAY* = 0x9061
  RELATIVE_ARC_TO_NV* = 0xFF
  UNPACK_PREMULTIPLY_ALPHA_WEBGL* = 0x9241
  READ_FRAMEBUFFER_BINDING_EXT* = 0x8CAA
  TEXTURE_WRAP_R_OES* = 0x8072
  MAX_GEOMETRY_VARYING_COMPONENTS_EXT* = 0x8DDD
  TEXTURE_CUBE_MAP_EXT* = 0x8513
  COMMAND_BARRIER_BIT_EXT* = 0x00000040
  DEBUG_SEVERITY_NOTIFICATION* = 0x826B
  COMPRESSED_SRGB8_ALPHA8_ASTC_10x5_KHR* = 0x93D8
  MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS* = 0x8C8B
  MAX_DEEP_3D_TEXTURE_WIDTH_HEIGHT_NV* = 0x90D0
  INT_IMAGE_2D_EXT* = 0x9058
  RGB_S3TC* = 0x83A0
  SUCCESS_NV* = 0x902F
  MATRIX_INDEX_ARRAY_SIZE_OES* = 0x8846
  VIEW_CLASS_8_BITS* = 0x82CB
  DONT_CARE* = 0x1100
  FOG_COORDINATE_ARRAY* = 0x8457
  DRAW_BUFFER9* = 0x882E
  TEXTURE28_ARB* = 0x84DC
  MAX_PROGRAM_TEXTURE_GATHER_OFFSET_ARB* = 0x8E5F
  TEXTURE21* = 0x84D5
  TRANSLATE_Y_NV* = 0x908F
  MODELVIEW17_ARB* = 0x8731
  ALPHA_FLOAT16_ATI* = 0x881C
  DEPTH_STENCIL_OES* = 0x84F9
  QUAD_MESH_SUN* = 0x8614
  PROGRAM_ADDRESS_REGISTERS_ARB* = 0x88B0
  VERTEX_BINDING_OFFSET* = 0x82D7
  FIRST_TO_REST_NV* = 0x90AF
  cSHADE_MODEL* = 0x0B54
  INT_IMAGE_2D_ARRAY_EXT* = 0x905E
  cFRONT_FACE* = 0x0B46
  cPRIMITIVE_RESTART_INDEX* = 0x8F9E
  LUMINANCE8* = 0x8040
  COVERAGE_ALL_FRAGMENTS_NV* = 0x8ED5
  FRAGMENT_ALPHA_MODULATE_IMG* = 0x8C08
  CLIP_PLANE3_IMG* = 0x3003
  EVAL_VERTEX_ATTRIB15_NV* = 0x86D5
  SYNC_GPU_COMMANDS_COMPLETE* = 0x9117
  FALSE* = GLboolean(0)
  MAX_DEBUG_GROUP_STACK_DEPTH_KHR* = 0x826C
  STENCIL_ATTACHMENT_EXT* = 0x8D20
  DST_ATOP_NV* = 0x928F
  REPLACEMENT_CODE_ARRAY_TYPE_SUN* = 0x85C1
  COMBINE4_NV* = 0x8503
  MINMAX_SINK_EXT* = 0x8030
  RG16I* = 0x8239
  BGRA_IMG* = 0x80E1
  REFERENCED_BY_COMPUTE_SHADER* = 0x930B
  MIN_LOD_WARNING_AMD* = 0x919C
  READ_BUFFER_EXT* = 0x0C02
  RGBA8UI_EXT* = 0x8D7C
  LINE_BIT* = 0x00000004
  CONDITION_SATISFIED* = 0x911C
  SLUMINANCE_ALPHA* = 0x8C44
  FOG_COORDINATE_ARRAY_TYPE* = 0x8454
  EXPAND_NORMAL_NV* = 0x8538
  TEXTURE_2D_ARRAY_EXT* = 0x8C1A
  SAMPLER_2D_RECT_ARB* = 0x8B63
  CLAMP_TO_BORDER_NV* = 0x812D
  MAX_GEOMETRY_OUTPUT_VERTICES_ARB* = 0x8DE0
  TEXCOORD2_BIT_PGI* = 0x20000000
  MATRIX0_ARB* = 0x88C0
  STENCIL_BUFFER_BIT2_QCOM* = 0x00040000
  COLOR_MATRIX_SGI* = 0x80B1
  PN_TRIANGLES_TESSELATION_LEVEL_ATI* = 0x87F4
  FRAMEBUFFER_INCOMPLETE_READ_BUFFER_EXT* = 0x8CDC
  LEFT* = 0x0406
  LO_SCALE_NV* = 0x870F
  STRICT_DEPTHFUNC_HINT_PGI* = 0x1A216
  MAX_COMBINED_TESS_CONTROL_UNIFORM_COMPONENTS* = 0x8E1E
  REPEAT* = 0x2901
  DEBUG_TYPE_PORTABILITY_ARB* = 0x824F
  MAX_FRAMEBUFFER_LAYERS* = 0x9317
  TRIANGLE_STRIP* = 0x0005
  RECLAIM_MEMORY_HINT_PGI* = 0x1A1FE
  RELATIVE_LINE_TO_NV* = 0x05
  MAX_LIGHTS* = 0x0D31
  MULTISAMPLE_BIT* = 0x20000000
  cREAD_PIXELS* = 0x828C
  DISCRETE_AMD* = 0x9006
  QUAD_TEXTURE_SELECT_SGIS* = 0x8125
  CON_25_ATI* = 0x895A
  BUFFER_IMMUTABLE_STORAGE* = 0x821F
  FLOAT_R16_NV* = 0x8884
  GREEN_INTEGER_EXT* = 0x8D95
  cFIXED* = 0x140C
  LIST_PRIORITY_SGIX* = 0x8182
  DRAW_BUFFER6_EXT* = 0x882B
  OFFSET_TEXTURE_BIAS_NV* = 0x86E3
  VERTEX_ATTRIB_ARRAY_POINTER_ARB* = 0x8645
  MALI_SHADER_BINARY_ARM* = 0x8F60
  RGB_422_APPLE* = 0x8A1F
  R1UI_N3F_V3F_SUN* = 0x85C7
  VERTEX_ARRAY_OBJECT_EXT* = 0x9154
  UNSIGNED_INT_10F_11F_11F_REV* = 0x8C3B
  VERSION_ES_CM_1_1* = 1
  CLEAR_TEXTURE* = 0x9365
  FLOAT16_VEC3_NV* = 0x8FFA
  TEXTURE_LUMINANCE_TYPE* = 0x8C14
  TRANSFORM_FEEDBACK* = 0x8E22
  POST_CONVOLUTION_COLOR_TABLE* = 0x80D1
  DEPTH_TEST* = 0x0B71
  CON_1_ATI* = 0x8942
  FRAGMENT_SHADER_ATI* = 0x8920
  SAMPLER_1D_ARRAY_SHADOW* = 0x8DC3
  SHADER_STORAGE_BUFFER_OFFSET_ALIGNMENT* = 0x90DF
  MAX_SERVER_WAIT_TIMEOUT* = 0x9111
  VERTEX_SHADER_BIT_EXT* = 0x00000001
  TEXTURE_BINDING_CUBE_MAP_OES* = 0x8514
  PIXEL_MAP_S_TO_S_SIZE* = 0x0CB1
  CURRENT_OCCLUSION_QUERY_ID_NV* = 0x8865
  TIMEOUT_IGNORED_APPLE* = 0xFFFFFFFFFFFFFFFF
  MAX_COMPUTE_UNIFORM_COMPONENTS* = 0x8263
  COPY_PIXEL_TOKEN* = 0x0706
  SPOT_CUTOFF* = 0x1206
  FRACTIONAL_EVEN* = 0x8E7C
  MAP1_VERTEX_ATTRIB6_4_NV* = 0x8666
  TRIANGLE_LIST_SUN* = 0x81D7
  ATOMIC_COUNTER_BUFFER_START* = 0x92C2
  MAX_ELEMENTS_VERTICES* = 0x80E8
  COLOR_ATTACHMENT9_EXT* = 0x8CE9
  ACCUM_CLEAR_VALUE* = 0x0B80
  TEXTURE_COORD_ARRAY_LENGTH_NV* = 0x8F2F
  DRAW_BUFFER3_EXT* = 0x8828
  TEXTURE_CUBE_MAP_POSITIVE_Y_EXT* = 0x8517
  C4UB_V3F* = 0x2A23
  MAX_PROGRAM_ATTRIBS_ARB* = 0x88AD
  PIXEL_TILE_CACHE_INCREMENT_SGIX* = 0x813F
  FRAMEBUFFER_INCOMPLETE_LAYER_COUNT_ARB* = 0x8DA9
  CON_8_ATI* = 0x8949
  POST_COLOR_MATRIX_ALPHA_BIAS* = 0x80BB
  RENDERBUFFER_WIDTH* = 0x8D42
  VERTEX_ID_NV* = 0x8C7B
  STRICT_LIGHTING_HINT_PGI* = 0x1A217
  COMPRESSED_RGBA8_ETC2_EAC_OES* = 0x9278
  PACK_COMPRESSED_BLOCK_WIDTH* = 0x912B
  ZERO_EXT* = 0x87DD
  DEBUG_SOURCE_OTHER* = 0x824B
  MAP_UNSYNCHRONIZED_BIT* = 0x0020
  VERTEX_ARRAY_POINTER* = 0x808E
  FLOAT_RGBA_NV* = 0x8883
  WEIGHT_ARRAY_STRIDE_OES* = 0x86AA
  UNPACK_ROW_BYTES_APPLE* = 0x8A16
  CURRENT_COLOR* = 0x0B00
  FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT_EXT* = 0x8CD7
  MAX_NAME_STACK_DEPTH* = 0x0D37
  SHADER_STORAGE_BUFFER_START* = 0x90D4
  TRANSFORM_FEEDBACK_BUFFER_MODE_EXT* = 0x8C7F
  PATH_GEN_COMPONENTS_NV* = 0x90B3
  AUTO_GENERATE_MIPMAP* = 0x8295
  UNSIGNED_INT_5_9_9_9_REV* = 0x8C3E
  cVIEWPORT* = 0x0BA2
  MAX_VERTEX_STREAMS_ATI* = 0x876B
  MAX_OPTIMIZED_VERTEX_SHADER_VARIANTS_EXT* = 0x87CB
  STENCIL_CLEAR_VALUE* = 0x0B91
  UNSIGNED_INT_IMAGE_2D_ARRAY_EXT* = 0x9069
  FRAGMENT_LIGHT_MODEL_TWO_SIDE_SGIX* = 0x8409
  FRAGMENT_SHADER_BIT_EXT* = 0x00000002
  COLOR_SUM_ARB* = 0x8458
  RGBA4_DXT5_S3TC* = 0x83A5
  INT_IMAGE_CUBE* = 0x905B
  ACTIVE_ATOMIC_COUNTER_BUFFERS* = 0x92D9
  INTERNALFORMAT_GREEN_SIZE* = 0x8272
  OFFSET_HILO_TEXTURE_RECTANGLE_NV* = 0x8855
  MAX_PN_TRIANGLES_TESSELATION_LEVEL_ATI* = 0x87F1
  REG_24_ATI* = 0x8939
  MULT* = 0x0103
  RGBA2* = 0x8055
  CONVOLUTION_WIDTH_EXT* = 0x8018
  STENCIL_EXT* = 0x1802
  PATH_STROKE_WIDTH_NV* = 0x9075
  DEBUG_SOURCE_WINDOW_SYSTEM_ARB* = 0x8247
  QUERY_COUNTER_BITS* = 0x8864
  OUTPUT_FOG_EXT* = 0x87BD
  POST_COLOR_MATRIX_RED_BIAS* = 0x80B8
  UNSIGNED_INT_10_10_10_2* = 0x8036
  INT_SAMPLER_1D* = 0x8DC9
  INT_IMAGE_2D_MULTISAMPLE_EXT* = 0x9060
  RENDERBUFFER_INTERNAL_FORMAT_OES* = 0x8D44
  TRACE_PIXELS_BIT_MESA* = 0x0010
  FAILURE_NV* = 0x9030
  INT_SAMPLER_3D_EXT* = 0x8DCB
  MAX_PROGRAM_PARAMETER_BUFFER_SIZE_NV* = 0x8DA1
  OBJECT_DISTANCE_TO_POINT_SGIS* = 0x81F1
  BLEND_SRC_RGB_OES* = 0x80C9
  LUMINANCE4_ALPHA4_OES* = 0x8043
  REG_4_ATI* = 0x8925
  SHADING_LANGUAGE_VERSION_ARB* = 0x8B8C
  RGBA16F_ARB* = 0x881A
  R32F* = 0x822E
  COMPRESSED_SRGB_S3TC_DXT1_NV* = 0x8C4C
  TESS_CONTROL_OUTPUT_VERTICES* = 0x8E75
  ONE_MINUS_DST_COLOR* = 0x0307
  MATRIX19_ARB* = 0x88D3
  INT_SAMPLER_2D_RECT* = 0x8DCD
  POST_CONVOLUTION_GREEN_SCALE_EXT* = 0x801D
  CLIP_DISTANCE5* = 0x3005
  HISTOGRAM_RED_SIZE_EXT* = 0x8028
  INTENSITY_FLOAT32_APPLE* = 0x8817
  MODULATE_ADD_ATI* = 0x8744
  NEGATIVE_X_EXT* = 0x87D9
  REG_21_ATI* = 0x8936
  STENCIL_RENDERABLE* = 0x8288
  FOG_COORD_ARRAY_STRIDE* = 0x8455
  FACTOR_MAX_AMD* = 0x901D
  LUMINANCE16_EXT* = 0x8042
  VARIANT_ARRAY_POINTER_EXT* = 0x87E9
  DECAL* = 0x2101
  SIGNED_ALPHA8_NV* = 0x8706
  ALPHA_BITS* = 0x0D55
  MATRIX29_ARB* = 0x88DD
  FOG* = 0x0B60
  INDEX_ARRAY_LIST_STRIDE_IBM* = 103083
  IMAGE_FORMAT_COMPATIBILITY_BY_CLASS* = 0x90C9
  RGBA4_S3TC* = 0x83A3
  LUMINANCE16_ALPHA16* = 0x8048
  PROXY_TEXTURE_RECTANGLE* = 0x84F7
  FRAGMENT_PROGRAM_PARAMETER_BUFFER_NV* = 0x8DA4
  UNIFORM_BLOCK_REFERENCED_BY_TESS_CONTROL_SHADER* = 0x84F0
  FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE* = 0x8CD3
  COLOR_TABLE_GREEN_SIZE_SGI* = 0x80DB
  TEXTURE_PRE_SPECULAR_HP* = 0x8169
  SHADOW_ATTENUATION_EXT* = 0x834E
  SIGNED_RGB_NV* = 0x86FE
  CLIENT_ALL_ATTRIB_BITS* = 0xFFFFFFFF
  DEPTH_ATTACHMENT_EXT* = 0x8D00
  DEBUG_SOURCE_API_KHR* = 0x8246
  COLOR_INDEXES* = 0x1603
  DEBUG_NEXT_LOGGED_MESSAGE_LENGTH* = 0x8243
  TEXTURE_BINDING_1D* = 0x8068
  UNSIGNED_INT_SAMPLER_2D* = 0x8DD2
  DRAW_BUFFER9_NV* = 0x882E
  RED* = 0x1903
  LINE_STRIP_ADJACENCY_EXT* = 0x000B
  NUM_PASSES_ATI* = 0x8970
  MAT_DIFFUSE_BIT_PGI* = 0x00400000
  LUMINANCE_INTEGER_EXT* = 0x8D9C
  PIXEL_MAP_I_TO_I* = 0x0C70
  SLUMINANCE8_ALPHA8_NV* = 0x8C45
  RGBA4_OES* = 0x8056
  COMPRESSED_SIGNED_R11_EAC* = 0x9271
  FRAGMENT_LIGHT4_SGIX* = 0x8410
  MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS_NV* = 0x8C80
  COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT* = 0x8C4D
  READ_FRAMEBUFFER_APPLE* = 0x8CA8
  DRAW_BUFFER15_ARB* = 0x8834
  INSTRUMENT_MEASUREMENTS_SGIX* = 0x8181
  REG_15_ATI* = 0x8930
  UNSIGNED_INT_IMAGE_1D_ARRAY* = 0x9068
  COMPUTE_LOCAL_WORK_SIZE* = 0x8267
  RGBA32I* = 0x8D82
  VERTEX_ATTRIB_MAP2_APPLE* = 0x8A01
  DEBUG_TYPE_DEPRECATED_BEHAVIOR* = 0x824D
  READ_FRAMEBUFFER_BINDING_ANGLE* = 0x8CAA
  DEBUG_SOURCE_WINDOW_SYSTEM_KHR* = 0x8247
  OP_FRAC_EXT* = 0x8789
  RGB_FLOAT32_APPLE* = 0x8815
  UNIFORM_BLOCK_REFERENCED_BY_VERTEX_SHADER* = 0x8A44
  NORMAL_ARRAY* = 0x8075
  TEXTURE21_ARB* = 0x84D5
  WRITE_ONLY_OES* = 0x88B9
  TEXTURE0_ARB* = 0x84C0
  SPRITE_OBJECT_ALIGNED_SGIX* = 0x814D
  POSITION* = 0x1203
  DEBUG_TYPE_UNDEFINED_BEHAVIOR* = 0x824E
  GEOMETRY_OUTPUT_TYPE_ARB* = 0x8DDC
  IMAGE_PIXEL_TYPE* = 0x82AA
  UNSIGNED_INT64_AMD* = 0x8BC2
  LIST_INDEX* = 0x0B33
  UNSIGNED_INT_8_8_S8_S8_REV_NV* = 0x86DB
  MAP_ATTRIB_U_ORDER_NV* = 0x86C3
  PROXY_TEXTURE_RECTANGLE_ARB* = 0x84F7
  CLIP_NEAR_HINT_PGI* = 0x1A220
  POST_TEXTURE_FILTER_BIAS_RANGE_SGIX* = 0x817B
  MAX_UNIFORM_BLOCK_SIZE* = 0x8A30
  FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER* = 0x8CDB
  SAMPLE_MASK_INVERT_EXT* = 0x80AB
  MAP1_VERTEX_ATTRIB14_4_NV* = 0x866E
  SYNC_FLAGS* = 0x9115
  COMPRESSED_RGBA* = 0x84EE
  TEXTURE_COMPRESSED_BLOCK_HEIGHT* = 0x82B2
  INDEX_ARRAY_STRIDE_EXT* = 0x8086
  CLIP_DISTANCE_NV* = 0x8C7A
  UNSIGNED_INT_VEC4* = 0x8DC8
  COMPRESSED_RGB_BPTC_SIGNED_FLOAT_ARB* = 0x8E8E
  MIRRORED_REPEAT_OES* = 0x8370
  WEIGHT_ARRAY_SIZE_ARB* = 0x86AB
  MIN_SAMPLE_SHADING_VALUE* = 0x8C37
  SOURCE0_RGB* = 0x8580
  RG32I* = 0x823B
  QUERY_BUFFER_BINDING_AMD* = 0x9193
  OFFSET_PROJECTIVE_TEXTURE_2D_SCALE_NV* = 0x8851
  POST_CONVOLUTION_BLUE_SCALE_EXT* = 0x801E
  DOUBLE_MAT3x4_EXT* = 0x8F4C
  MAX_VERTEX_HINT_PGI* = 0x1A22D
  ADD* = 0x0104
  PATH_FORMAT_SVG_NV* = 0x9070
  VIDEO_BUFFER_BINDING_NV* = 0x9021
  NUM_EXTENSIONS* = 0x821D
  cDEPTH_RANGE* = 0x0B70
  FRAGMENT_SUBROUTINE* = 0x92EC
  DEPTH24_STENCIL8_EXT* = 0x88F0
  COMPRESSED_RGBA_S3TC_DXT3_EXT* = 0x83F2
  cCOLOR_TABLE_SGI* = 0x80D0
  OBJECT_ACTIVE_UNIFORMS_ARB* = 0x8B86
  RGBA16F* = 0x881A
  COORD_REPLACE_ARB* = 0x8862
  SAMPLE_POSITION_NV* = 0x8E50
  SRC_ALPHA* = 0x0302
  COMBINE_ALPHA* = 0x8572
  cCLEAR* = 0x1500
  HSL_HUE_NV* = 0x92AD
  SCISSOR_TEST* = 0x0C11
  UNSIGNED_INT_SAMPLER_BUFFER_EXT* = 0x8DD8
  RGB16UI* = 0x8D77
  MATRIX9_ARB* = 0x88C9
  COLOR_ATTACHMENT13* = 0x8CED
  BUMP_ROT_MATRIX_SIZE_ATI* = 0x8776
  PIXEL_PACK_BUFFER_BINDING_ARB* = 0x88ED
  FONT_X_MAX_BOUNDS_BIT_NV* = 0x00040000
  MODELVIEW31_ARB* = 0x873F
  DRAW_BUFFER14_ARB* = 0x8833
  EDGEFLAG_BIT_PGI* = 0x00040000
  TEXTURE_LOD_BIAS_R_SGIX* = 0x8190
  FIELD_UPPER_NV* = 0x9022
  CLIP_PLANE3* = 0x3003
  FRAGMENT_LIGHT_MODEL_LOCAL_VIEWER_SGIX* = 0x8408
  BLUE* = 0x1905
  LUMINANCE_ALPHA_FLOAT32_ATI* = 0x8819
  MATRIX31_ARB* = 0x88DF
  OR_REVERSE* = 0x150B
  INTERPOLATE_EXT* = 0x8575
  MODELVIEW13_ARB* = 0x872D
  UTF16_NV* = 0x909B
  READ_FRAMEBUFFER_ANGLE* = 0x8CA8
  LUMINANCE16F_EXT* = 0x881E
  VERTEX_ATTRIB_ARRAY7_NV* = 0x8657
  MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS_EXT* = 0x8C8A
  PRIMARY_COLOR_EXT* = 0x8577
  VERTEX_ATTRIB_RELATIVE_OFFSET* = 0x82D5
  LARGE_CW_ARC_TO_NV* = 0x18
  PROGRAM_PARAMETER_NV* = 0x8644
  cASYNC_MARKER_SGIX* = 0x8329
  TEXTURE24_ARB* = 0x84D8
  PIXEL_SUBSAMPLE_4242_SGIX* = 0x85A4
  RGB10_A2_EXT* = 0x8059
  IMAGE_CLASS_2_X_32* = 0x82BA
  TEXTURE_INTENSITY_TYPE* = 0x8C15
  TEXTURE_LOD_BIAS_S_SGIX* = 0x818E
  PROGRAM_BINARY_LENGTH* = 0x8741
  CURRENT_RASTER_NORMAL_SGIX* = 0x8406
  DETAIL_TEXTURE_2D_SGIS* = 0x8095
  MAX_FRAGMENT_INTERPOLATION_OFFSET_NV* = 0x8E5C
  CONVOLUTION_FILTER_BIAS_EXT* = 0x8015
  DT_BIAS_NV* = 0x8717
  RESET_NOTIFICATION_STRATEGY_EXT* = 0x8256
  SHADER_STORAGE_BUFFER* = 0x90D2
  RESET_NOTIFICATION_STRATEGY_ARB* = 0x8256
  FRAMEBUFFER_ATTACHMENT_OBJECT_NAME_EXT* = 0x8CD1
  SRC_NV* = 0x9286
  POINT_FADE_THRESHOLD_SIZE* = 0x8128
  DEPENDENT_RGB_TEXTURE_3D_NV* = 0x8859
  QUERY_RESULT_ARB* = 0x8866
  GEOMETRY_VERTICES_OUT* = 0x8916
  MAX_COMPUTE_FIXED_GROUP_INVOCATIONS_ARB* = 0x90EB
  MODELVIEW27_ARB* = 0x873B
  DRAW_BUFFER11_NV* = 0x8830
  COLOR_ATTACHMENT9_NV* = 0x8CE9
  BLEND_SRC* = 0x0BE1
  CONVOLUTION_2D_EXT* = 0x8011
  MAX_ELEMENTS_INDICES* = 0x80E9
  LUMINANCE_ALPHA_FLOAT32_APPLE* = 0x8819
  INT_IMAGE_1D* = 0x9057
  CONSTANT_COLOR* = 0x8001
  FRAMEBUFFER_BARRIER_BIT* = 0x00000400
  POST_CONVOLUTION_BLUE_SCALE* = 0x801E
  DEBUG_SOURCE_SHADER_COMPILER_ARB* = 0x8248
  RGB16I* = 0x8D89
  MAX_WIDTH* = 0x827E
  LIGHT_MODEL_AMBIENT* = 0x0B53
  COVERAGE_ATTACHMENT_NV* = 0x8ED2
  PROGRAM* = 0x82E2
  IMAGE_ROTATE_ANGLE_HP* = 0x8159
  SRC2_RGB* = 0x8582
  DEBUG_TYPE_UNDEFINED_BEHAVIOR_KHR* = 0x824E
  PASS_THROUGH_NV* = 0x86E6
  HALF_BIAS_NEGATE_NV* = 0x853B
  SAMPLER_CUBE_SHADOW_EXT* = 0x8DC5
  COMPRESSED_RGBA_BPTC_UNORM_ARB* = 0x8E8C
  MAX_SERVER_WAIT_TIMEOUT_APPLE* = 0x9111
  STORAGE_PRIVATE_APPLE* = 0x85BD
  VERTEX_SHADER_BIT* = 0x00000001
  POST_COLOR_MATRIX_BLUE_SCALE_SGI* = 0x80B6
  VERTEX_SHADER_VARIANTS_EXT* = 0x87D0
  TRANSFORM_FEEDBACK_ACTIVE* = 0x8E24
  ACTIVE_UNIFORMS* = 0x8B86
  MULTISAMPLE_BUFFER_BIT0_QCOM* = 0x01000000
  OFFSET_TEXTURE_SCALE_NV* = 0x86E2
  VERTEX_ATTRIB_ARRAY_DIVISOR_ARB* = 0x88FE
  BEVEL_NV* = 0x90A6
  MAX_DRAW_BUFFERS_NV* = 0x8824
  MAP1_TANGENT_EXT* = 0x8444
  ANY_SAMPLES_PASSED* = 0x8C2F
  MAX_IMAGE_SAMPLES* = 0x906D
  PIXEL_UNPACK_BUFFER_BINDING* = 0x88EF
  SRGB8_ALPHA8_EXT* = 0x8C43
  c2PASS_1_SGIS* = 0x80A3
  PROGRAM_POINT_SIZE_ARB* = 0x8642
  ALLOW_DRAW_WIN_HINT_PGI* = 0x1A20F
  INTERNALFORMAT_RED_SIZE* = 0x8271
  FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE_OES* = 0x8CD3
  c4PASS_2_SGIS* = 0x80A6
  PROGRAM_OBJECT_EXT* = 0x8B40
  SIMULTANEOUS_TEXTURE_AND_STENCIL_TEST* = 0x82AD
  LIGHTING_BIT* = 0x00000040
  DRAW_BUFFER13_EXT* = 0x8832
  STREAM_DRAW_ARB* = 0x88E0
  INDEX_ARRAY_TYPE* = 0x8085
  DEBUG_SOURCE_THIRD_PARTY* = 0x8249
  DYNAMIC_COPY_ARB* = 0x88EA
  COMPARE_R_TO_TEXTURE_ARB* = 0x884E
  FRAGMENTS_INSTRUMENT_COUNTERS_SGIX* = 0x8314
  SPARSE_TEXTURE_FULL_ARRAY_CUBE_MIPMAPS_ARB* = 0x91A9
  MAX_GEOMETRY_UNIFORM_COMPONENTS* = 0x8DDF
  READ_PIXEL_DATA_RANGE_POINTER_NV* = 0x887D
  BUFFER_MAPPED_OES* = 0x88BC
  COLOR_ARRAY_COUNT_EXT* = 0x8084
  SET_AMD* = 0x874A
  BLEND_DST_RGB_OES* = 0x80C8
  MAX_CONVOLUTION_HEIGHT_EXT* = 0x801B
  DEBUG_SEVERITY_MEDIUM* = 0x9147
  TEXTURE_INTENSITY_TYPE_ARB* = 0x8C15
  IMAGE_CLASS_10_10_10_2* = 0x82C3
  TEXTURE_BORDER_COLOR_NV* = 0x1004
  VERTEX_ATTRIB_ARRAY12_NV* = 0x865C
  MAX_GEOMETRY_SHADER_INVOCATIONS* = 0x8E5A
  NEAREST_CLIPMAP_NEAREST_SGIX* = 0x844D
  MAP2_VERTEX_ATTRIB12_4_NV* = 0x867C
  TEXTURE_COORD_ARRAY_BUFFER_BINDING* = 0x889A
  SEPARATE_SPECULAR_COLOR_EXT* = 0x81FA
  MATRIX_INDEX_ARRAY_SIZE_ARB* = 0x8846
  TEXTURE_CUBE_MAP_POSITIVE_Y_ARB* = 0x8517
  DECR* = 0x1E03
  DEPTH_BUFFER_BIT7_QCOM* = 0x00008000
  LOCAL_EXT* = 0x87C4
  FUNC_REVERSE_SUBTRACT_OES* = 0x800B
  FLOAT_VEC3* = 0x8B51
  POINT_SIZE_GRANULARITY* = 0x0B13
  COLOR_ATTACHMENT9* = 0x8CE9
  MAT_SPECULAR_BIT_PGI* = 0x04000000
  VERTEX_ATTRIB_MAP1_APPLE* = 0x8A00
  DEBUG_SOURCE_WINDOW_SYSTEM* = 0x8247
  NEAREST_MIPMAP_NEAREST* = 0x2700
  MODELVIEW7_ARB* = 0x8727
  OUTPUT_VERTEX_EXT* = 0x879A
  FRAMEBUFFER_EXT* = 0x8D40
  ATC_RGBA_EXPLICIT_ALPHA_AMD* = 0x8C93
  RENDERBUFFER_WIDTH_OES* = 0x8D42
  TEXTURE_VIEW_MIN_LAYER* = 0x82DD
  TEXTURE25_ARB* = 0x84D9
  LIGHT7* = 0x4007
  TESS_EVALUATION_SHADER_BIT* = 0x00000010
  FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL_EXT* = 0x8CD2
  COLOR_ATTACHMENT15_NV* = 0x8CEF
  RED_SNORM* = 0x8F90
  VIVIDLIGHT_NV* = 0x92A6
  OBJECT_COMPILE_STATUS_ARB* = 0x8B81
  INTERNALFORMAT_PREFERRED* = 0x8270
  OUT_OF_MEMORY* = 0x0505
  c422_REV_EXT* = 0x80CD
  DOT_PRODUCT_TEXTURE_CUBE_MAP_NV* = 0x86F0
  PROXY_TEXTURE_1D* = 0x8063
  FRAGMENT_PROGRAM_CALLBACK_FUNC_MESA* = 0x8BB2
  YCBCR_422_APPLE* = 0x85B9
  DRAW_BUFFER10_ATI* = 0x882F
  COLOR_TABLE_ALPHA_SIZE_SGI* = 0x80DD
  MAX_TESS_EVALUATION_OUTPUT_COMPONENTS* = 0x8E86
  MAX_PROGRAM_OUTPUT_VERTICES_NV* = 0x8C27
  IMAGE_2D_MULTISAMPLE_EXT* = 0x9055
  cACTIVE_TEXTURE_ARB* = 0x84E0
  FONT_MAX_ADVANCE_HEIGHT_BIT_NV* = 0x02000000
  QUERY_WAIT_NV* = 0x8E13
  MAX_ELEMENT_INDEX* = 0x8D6B
  OP_LOG_BASE_2_EXT* = 0x8792
  ADD_SIGNED* = 0x8574
  CONVOLUTION_FORMAT* = 0x8017
  RENDERBUFFER_RED_SIZE_EXT* = 0x8D50
  RENDERBUFFER_INTERNAL_FORMAT* = 0x8D44
  COLOR_ATTACHMENT11_NV* = 0x8CEB
  MATRIX14_ARB* = 0x88CE
  COLOR_TABLE_RED_SIZE_SGI* = 0x80DA
  CON_22_ATI* = 0x8957
  TEXTURE_SWIZZLE_B_EXT* = 0x8E44
  SAMPLES_SGIS* = 0x80A9
  WRITE_PIXEL_DATA_RANGE_LENGTH_NV* = 0x887A
  FONT_X_MIN_BOUNDS_BIT_NV* = 0x00010000
  c3_BYTES* = 0x1408
  TEXTURE_MAX_CLAMP_S_SGIX* = 0x8369
  PROXY_TEXTURE_CUBE_MAP_EXT* = 0x851B
  VERTEX_ATTRIB_ARRAY_DIVISOR_ANGLE* = 0x88FE
  VERTEX_DATA_HINT_PGI* = 0x1A22A
  VERTEX_WEIGHT_ARRAY_SIZE_EXT* = 0x850D
  MAX_INTEGER_SAMPLES* = 0x9110
  TEXTURE_BUFFER_ARB* = 0x8C2A
  FOG_COORD_ARRAY_POINTER* = 0x8456
  UNSIGNED_SHORT_1_15_REV_MESA* = 0x8754
  IMAGE_CUBIC_WEIGHT_HP* = 0x815E
  FRAMEBUFFER_INCOMPLETE_ATTACHMENT_OES* = 0x8CD6
  RGBA_DXT5_S3TC* = 0x83A4
  INT_IMAGE_2D_MULTISAMPLE* = 0x9060
  ACTIVE_RESOURCES* = 0x92F5
  TEXTURE_BINDING_2D* = 0x8069
  cSAMPLE_COVERAGE* = 0x80A0
  SMOOTH* = 0x1D01
  SAMPLER_1D_SHADOW_ARB* = 0x8B61
  VIRTUAL_PAGE_SIZE_Y_AMD* = 0x9196
  HORIZONTAL_LINE_TO_NV* = 0x06
  HISTOGRAM_GREEN_SIZE_EXT* = 0x8029
  COLOR_FLOAT_APPLE* = 0x8A0F
  NUM_SHADER_BINARY_FORMATS* = 0x8DF9
  TIMESTAMP* = 0x8E28
  SRGB_EXT* = 0x8C40
  MAX_VERTEX_UNIFORM_BLOCKS* = 0x8A2B
  COLOR_ATTACHMENT2_EXT* = 0x8CE2
  DEBUG_CALLBACK_FUNCTION_KHR* = 0x8244
  DISPLAY_LIST* = 0x82E7
  MAP1_NORMAL* = 0x0D92
  COMPUTE_TEXTURE* = 0x82A0
  MAX_COMPUTE_SHADER_STORAGE_BLOCKS* = 0x90DB
  W_EXT* = 0x87D8
  SAMPLE_SHADING_ARB* = 0x8C36
  FRAGMENT_INTERPOLATION_OFFSET_BITS* = 0x8E5D
  IMAGE_CLASS_4_X_16* = 0x82BC
  FRAGMENT_DEPTH_EXT* = 0x8452
  EVAL_BIT* = 0x00010000
  UNSIGNED_INT_8_8_8_8* = 0x8035
  MAX_TESS_CONTROL_INPUT_COMPONENTS* = 0x886C
  FRAGMENT_PROGRAM_CALLBACK_DATA_MESA* = 0x8BB3
  SLUMINANCE8_ALPHA8* = 0x8C45
  MODULATE_COLOR_IMG* = 0x8C04
  TEXTURE20* = 0x84D4
  ALPHA_INTEGER_EXT* = 0x8D97
  TEXTURE_BINDING_CUBE_MAP_EXT* = 0x8514
  BACK_LEFT* = 0x0402
  MAX_COMBINED_IMAGE_UNITS_AND_FRAGMENT_OUTPUTS_EXT* = 0x8F39
  MAX_TRANSFORM_FEEDBACK_BUFFERS* = 0x8E70
  TRANSFORM_BIT* = 0x00001000
  RGB4_EXT* = 0x804F
  FRAGMENT_COLOR_EXT* = 0x834C
  PIXEL_MAP_S_TO_S* = 0x0C71
  COMPRESSED_RGBA_S3TC_DXT5_EXT* = 0x83F3
  PATH_STENCIL_DEPTH_OFFSET_FACTOR_NV* = 0x90BD
  SOURCE0_RGB_EXT* = 0x8580
  PIXEL_COUNTER_BITS_NV* = 0x8864
  ALIASED_LINE_WIDTH_RANGE* = 0x846E
  DRAW_BUFFER10* = 0x882F
  T4F_C4F_N3F_V4F* = 0x2A2D
  cBLEND_EQUATION_OES* = 0x8009
  DEPTH_COMPONENT32* = 0x81A7
  MAX_OPTIMIZED_VERTEX_SHADER_INSTRUCTIONS_EXT* = 0x87CA
  DEPTH_BUFFER_BIT5_QCOM* = 0x00002000
  RED_MIN_CLAMP_INGR* = 0x8560
  RGBA_INTEGER_MODE_EXT* = 0x8D9E
  DOUBLE_MAT4_EXT* = 0x8F48
  OBJECT_DELETE_STATUS_ARB* = 0x8B80
  FOG_COORD_ARRAY_LENGTH_NV* = 0x8F32
  SECONDARY_COLOR_ARRAY_BUFFER_BINDING* = 0x889C
  MAP1_VERTEX_ATTRIB7_4_NV* = 0x8667
  BLEND_SRC_RGB_EXT* = 0x80C9
  VERTEX_PROGRAM_POINT_SIZE_ARB* = 0x8642
  STENCIL_INDEX1_EXT* = 0x8D46
  TEXTURE_CUBE_MAP_NEGATIVE_X_EXT* = 0x8516
  FRAGMENT_SHADER_DISCARDS_SAMPLES_EXT* = 0x8A52
  FOG_COORD_SRC* = 0x8450
  ANY_SAMPLES_PASSED_EXT* = 0x8C2F
  ALPHA4* = 0x803B
  TEXTURE_GEN_MODE* = 0x2500
  FLOAT_MAT3_ARB* = 0x8B5B
  PIXEL_MAP_A_TO_A_SIZE* = 0x0CB9
  FRAGMENT_SHADER_DERIVATIVE_HINT_ARB* = 0x8B8B
  STENCIL_BACK_PASS_DEPTH_FAIL_ATI* = 0x8802
  COPY_READ_BUFFER_BINDING* = 0x8F36
  YCRCB_444_SGIX* = 0x81BC
  SLUMINANCE_EXT* = 0x8C46
  EDGE_FLAG_ARRAY_EXT* = 0x8079
  STENCIL_INDEX8_OES* = 0x8D48
  RGBA32UI* = 0x8D70
  TEXTURE_CUBE_MAP* = 0x8513
  STREAM_COPY* = 0x88E2
  VIEWPORT_BOUNDS_RANGE* = 0x825D
  ASYNC_READ_PIXELS_SGIX* = 0x835E
  VERTEX_ATTRIB_ARRAY_INTEGER* = 0x88FD
  INTERNALFORMAT_STENCIL_TYPE* = 0x827D
  OUTPUT_TEXTURE_COORD28_EXT* = 0x87B9
  cMATRIX_MODE* = 0x0BA0
  MULTISAMPLE_SGIS* = 0x809D
  R1UI_V3F_SUN* = 0x85C4
  FLOAT_R32_NV* = 0x8885
  MAX_DRAW_BUFFERS* = 0x8824
  CIRCULAR_CCW_ARC_TO_NV* = 0xF8
  PROGRAM_OUTPUT* = 0x92E4
  MAX_CUBE_MAP_TEXTURE_SIZE* = 0x851C
  TRIANGLE_STRIP_ADJACENCY_ARB* = 0x000D
  UNIFORM_BUFFER_OFFSET_ALIGNMENT* = 0x8A34
  SRGB* = 0x8C40
  BUFFER_ACCESS* = 0x88BB
  TEXTURE_WRAP_S* = 0x2802
  cTRANSFORM_FEEDBACK_VARYINGS* = 0x8C83
  RG16UI* = 0x823A
  DUAL_LUMINANCE4_SGIS* = 0x8114
  DOT_PRODUCT_DEPTH_REPLACE_NV* = 0x86ED
  READ_FRAMEBUFFER_BINDING* = 0x8CAA
  MAX_FOG_FUNC_POINTS_SGIS* = 0x812C
  QUERY_RESULT_NO_WAIT* = 0x9194
  FILE_NAME_NV* = 0x9074
  DRAW_FRAMEBUFFER_BINDING* = 0x8CA6
  FRAGMENT_SHADER* = 0x8B30
  VIBRANCE_SCALE_NV* = 0x8713
  PATH_FILL_COVER_MODE_NV* = 0x9082
  LINEAR_MIPMAP_LINEAR* = 0x2703
  TEXTURE29* = 0x84DD
  SCISSOR_BOX* = 0x0C10
  PACK_SKIP_IMAGES* = 0x806B
  BUFFER_MAP_OFFSET* = 0x9121
  SLUMINANCE8_EXT* = 0x8C47
  CONVOLUTION_1D* = 0x8010
  MAX_GEOMETRY_IMAGE_UNIFORMS* = 0x90CD
  MAP1_VERTEX_ATTRIB11_4_NV* = 0x866B
  COLOR_LOGIC_OP* = 0x0BF2
  SYNC_FLAGS_APPLE* = 0x9115
  ACCUM_RED_BITS* = 0x0D58
  VIEW_CLASS_128_BITS* = 0x82C4
  INT_VEC3* = 0x8B54
  INTENSITY12* = 0x804C
  UNIFORM_BLOCK_REFERENCED_BY_COMPUTE_SHADER* = 0x90EC
  REQUIRED_TEXTURE_IMAGE_UNITS_OES* = 0x8D68
  MAX_COLOR_MATRIX_STACK_DEPTH* = 0x80B3
  GLOBAL_ALPHA_FACTOR_SUN* = 0x81DA
  PACK_RESAMPLE_SGIX* = 0x842C
  MAX_COMPUTE_FIXED_GROUP_SIZE_ARB* = 0x91BF
  DEPTH_BUFFER_FLOAT_MODE_NV* = 0x8DAF
  SIGNED_LUMINANCE_ALPHA_NV* = 0x8703
  OP_MIN_EXT* = 0x878B
  TRANSFORM_FEEDBACK_BUFFER_MODE_NV* = 0x8C7F
  COLOR_INDEX12_EXT* = 0x80E6
  AUTO_NORMAL* = 0x0D80
  ARRAY_BUFFER* = 0x8892
  MAX_GEOMETRY_TOTAL_OUTPUT_COMPONENTS_EXT* = 0x8DE1
  VIDEO_CAPTURE_SURFACE_ORIGIN_NV* = 0x903C
  ACCUM_BLUE_BITS* = 0x0D5A
  RENDERBUFFER_SAMPLES_ANGLE* = 0x8CAB
  MAX_ASYNC_HISTOGRAM_SGIX* = 0x832D
  GLYPH_HAS_KERNING_BIT_NV* = 0x100
  TESS_CONTROL_SUBROUTINE_UNIFORM* = 0x92EF
  DRAW_BUFFER1* = 0x8826
  INT8_NV* = 0x8FE0
  c2PASS_0_EXT* = 0x80A2
  TRANSFORM_FEEDBACK_BUFFER_INDEX* = 0x934B
  NUM_VIRTUAL_PAGE_SIZES_ARB* = 0x91A8
  INT_SAMPLER_3D* = 0x8DCB
  RASTERIZER_DISCARD* = 0x8C89
  SOURCE2_RGB_ARB* = 0x8582
  LOCAL_CONSTANT_EXT* = 0x87C3
  FRAMEBUFFER_INCOMPLETE_LAYER_COUNT_EXT* = 0x8DA9
  MODELVIEW12_ARB* = 0x872C
  VERTEX_SUBROUTINE_UNIFORM* = 0x92EE
  OPERAND0_ALPHA_ARB* = 0x8598
  DEPTH24_STENCIL8* = 0x88F0
  RENDERBUFFER_RED_SIZE* = 0x8D50
  FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING* = 0x8210
  DRAW_BUFFER10_ARB* = 0x882F
  UNSIGNED_INT_SAMPLER_3D* = 0x8DD3
  SKIP_COMPONENTS2_NV* = -5
  PROGRAM_BINARY_LENGTH_OES* = 0x8741
  VERTEX_ATTRIB_MAP1_SIZE_APPLE* = 0x8A02
  QUERY_RESULT_EXT* = 0x8866
  CONSTANT_COLOR0_NV* = 0x852A
  MAX_ASYNC_DRAW_PIXELS_SGIX* = 0x8360
  DOT_PRODUCT_DIFFUSE_CUBE_MAP_NV* = 0x86F1
  ALPHA_TEST_REF* = 0x0BC2
  MAX_4D_TEXTURE_SIZE_SGIS* = 0x8138
  INT_SAMPLER_2D_MULTISAMPLE* = 0x9109
  DRAW_BUFFER6_ATI* = 0x882B
  INTENSITY16UI_EXT* = 0x8D79
  POINT_FADE_THRESHOLD_SIZE_ARB* = 0x8128
  VERTEX_ATTRIB_ARRAY_BUFFER_BINDING* = 0x889F
  RENDERBUFFER_WIDTH_EXT* = 0x8D42
  FIXED_ONLY* = 0x891D
  HISTOGRAM_BLUE_SIZE* = 0x802A
  PROGRAM_TEX_INSTRUCTIONS_ARB* = 0x8806
  MAX_VERTEX_SHADER_VARIANTS_EXT* = 0x87C6
  UNSIGNED_INT_10_10_10_2_EXT* = 0x8036
  SAMPLE_ALPHA_TO_ONE_EXT* = 0x809F
  INDEX_ARRAY* = 0x8077
  GEQUAL* = 0x0206
  MAX_TESS_CONTROL_SHADER_STORAGE_BLOCKS* = 0x90D8
  DITHER* = 0x0BD0
  ATTACHED_SHADERS* = 0x8B85
  FUNC_SUBTRACT* = 0x800A
  ATOMIC_COUNTER_BARRIER_BIT_EXT* = 0x00001000
  LUMINANCE4* = 0x803F
  BLEND_EQUATION_RGB_EXT* = 0x8009
  TEXTURE_MULTI_BUFFER_HINT_SGIX* = 0x812E
  DEBUG_SEVERITY_LOW_KHR* = 0x9148
  UNPACK_COMPRESSED_BLOCK_HEIGHT* = 0x9128
  CULL_VERTEX_OBJECT_POSITION_EXT* = 0x81AC
  POST_COLOR_MATRIX_ALPHA_BIAS_SGI* = 0x80BB
  ADD_SIGNED_EXT* = 0x8574
  VERTEX_ARRAY_PARALLEL_POINTERS_INTEL* = 0x83F5
  CURRENT_RASTER_SECONDARY_COLOR* = 0x845F
  MAX_PROGRAM_TEXTURE_GATHER_OFFSET_NV* = 0x8E5F
  CONTINUOUS_AMD* = 0x9007
  R1UI_T2F_C4F_N3F_V3F_SUN* = 0x85CB
  COMPUTE_SHADER* = 0x91B9
  CLIP_DISTANCE6* = 0x3006
  SRC_ATOP_NV* = 0x928E
  DEPTH_COMPONENT16_OES* = 0x81A5
  DOUBLE_MAT4* = 0x8F48
  MAT_SHININESS_BIT_PGI* = 0x02000000
  SAMPLER_BUFFER_AMD* = 0x9001
  ARRAY_BUFFER_BINDING_ARB* = 0x8894
  VOLATILE_APPLE* = 0x8A1A
  ALPHA32UI_EXT* = 0x8D72
  COLOR_BUFFER_BIT1_QCOM* = 0x00000002
  VERTEX_PROGRAM_CALLBACK_MESA* = 0x8BB4
  CULL_VERTEX_EXT* = 0x81AA
  RENDERBUFFER_STENCIL_SIZE_EXT* = 0x8D55
  SELECT* = 0x1C02
  LUMINANCE12_ALPHA4* = 0x8046
  IMAGE_BINDING_LEVEL_EXT* = 0x8F3B
  MATRIX_PALETTE_ARB* = 0x8840
  DUAL_ALPHA4_SGIS* = 0x8110
  BACK_NORMALS_HINT_PGI* = 0x1A223
  UNSIGNED_SHORT_15_1_MESA* = 0x8753
  UNSIGNED_SHORT_4_4_4_4_REV* = 0x8365
  BUFFER* = 0x82E0
  RENDERBUFFER_INTERNAL_FORMAT_EXT* = 0x8D44
  MATRIX5_NV* = 0x8635
  ATOMIC_COUNTER_BUFFER* = 0x92C0
  SMOOTH_QUADRATIC_CURVE_TO_NV* = 0x0E
  VARIABLE_D_NV* = 0x8526
  PINLIGHT_NV* = 0x92A8
  VERTEX_ATTRIB_ARRAY_INTEGER_EXT* = 0x88FD
  MAX_GEOMETRY_ATOMIC_COUNTER_BUFFERS* = 0x92CF
  Z6Y10Z6CB10Z6A10Z6Y10Z6CR10Z6A10_4224_NV* = 0x9034
  RESAMPLE_REPLICATE_SGIX* = 0x842E
  UNSIGNED_SHORT_5_6_5_REV* = 0x8364
  VERTEX_ATTRIB_ARRAY2_NV* = 0x8652
  c3D_COLOR_TEXTURE* = 0x0603
  MAX_VERTEX_TEXTURE_IMAGE_UNITS* = 0x8B4C
  DEBUG_TYPE_PERFORMANCE_KHR* = 0x8250
  MATRIX_INDEX_ARRAY_OES* = 0x8844
  TEXTURE_TOO_LARGE_EXT* = 0x8065
  PACK_IMAGE_HEIGHT_EXT* = 0x806C
  YCBYCR8_422_NV* = 0x9031
  COLOR_ATTACHMENT8* = 0x8CE8
  cSAMPLE_COVERAGE_ARB* = 0x80A0
  CURRENT_VERTEX_EXT* = 0x87E2
  LINEAR* = 0x2601
  STENCIL_TAG_BITS_EXT* = 0x88F2
  T2F_IUI_V3F_EXT* = 0x81B2
  TEXTURE_3D_BINDING_OES* = 0x806A
  PATH_CLIENT_LENGTH_NV* = 0x907F
  MAT_AMBIENT_BIT_PGI* = 0x00100000
  DOUBLE_MAT4x3* = 0x8F4E
  QUERY_BY_REGION_WAIT_NV* = 0x8E15
  LEQUAL* = 0x0203
  PROGRAM_ATTRIBS_ARB* = 0x88AC
  BUFFER_MAPPED_ARB* = 0x88BC
  VERTEX_SHADER_ARB* = 0x8B31
  SOURCE1_ALPHA_EXT* = 0x8589
  UNSIGNED_INT16_VEC3_NV* = 0x8FF2
  MAX_PROGRAM_ADDRESS_REGISTERS_ARB* = 0x88B1
  RGB16* = 0x8054
  TEXTURE15_ARB* = 0x84CF
  TEXTURE_GATHER_SHADOW* = 0x82A3
  FENCE_APPLE* = 0x8A0B
  TRIANGLES* = 0x0004
  DOT4_ATI* = 0x8967
  CURRENT_FOG_COORD* = 0x8453
  DEPTH_CLAMP_NEAR_AMD* = 0x901E
  SYNC_FENCE* = 0x9116
  UNSIGNED_INT64_VEC3_NV* = 0x8FF6
  DEPTH* = 0x1801
  TEXTURE_COORD_NV* = 0x8C79
  COMBINE* = 0x8570
  MAX_VERTEX_UNITS_ARB* = 0x86A4
  COLOR_INDEX2_EXT* = 0x80E3
  POST_IMAGE_TRANSFORM_COLOR_TABLE_HP* = 0x8162
  INT_SAMPLER_CUBE_MAP_ARRAY_ARB* = 0x900E
  MIRROR_CLAMP_EXT* = 0x8742
  STENCIL_VALUE_MASK* = 0x0B93
  UNSIGNED_INT_SAMPLER_BUFFER* = 0x8DD8
  cTRACK_MATRIX_NV* = 0x8648
  MAP1_VERTEX_3* = 0x0D97
  OP_MOV_EXT* = 0x8799
  MAP_INVALIDATE_RANGE_BIT_EXT* = 0x0004
  MAX_CONVOLUTION_WIDTH_EXT* = 0x801A
  TEXTURE_CUBE_MAP_NEGATIVE_Y_OES* = 0x8518
  RGBA_SNORM* = 0x8F93
  MAX_TRACK_MATRICES_NV* = 0x862F
  MAX_TESS_EVALUATION_INPUT_COMPONENTS* = 0x886D
  DOUBLE_VEC4_EXT* = 0x8FFE
  COLOR_TABLE_BLUE_SIZE* = 0x80DC
  T2F_C3F_V3F* = 0x2A2A
  INTENSITY16_SNORM* = 0x901B
  INT_IMAGE_CUBE_MAP_ARRAY_EXT* = 0x905F
  DEBUG_CATEGORY_UNDEFINED_BEHAVIOR_AMD* = 0x914C
  NORMAL_MAP_EXT* = 0x8511
  MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS_NV* = 0x8C8B
  DRAW_BUFFER4_EXT* = 0x8829
  PIXEL_MAP_G_TO_G* = 0x0C77
  TESS_GEN_POINT_MODE* = 0x8E79
  MAX_VERTEX_ATOMIC_COUNTER_BUFFERS* = 0x92CC
  UNSIGNED_INT_SAMPLER_2D_RECT_EXT* = 0x8DD5
  MULTISAMPLE_BUFFER_BIT2_QCOM* = 0x04000000
  POST_COLOR_MATRIX_GREEN_BIAS_SGI* = 0x80B9
  POST_COLOR_MATRIX_GREEN_BIAS* = 0x80B9
  TEXTURE10* = 0x84CA
  RGB32F* = 0x8815
  DYNAMIC_READ_ARB* = 0x88E9
  MODELVIEW22_ARB* = 0x8736
  VERTEX_STREAM0_ATI* = 0x876C
  TEXTURE_FETCH_BARRIER_BIT_EXT* = 0x00000008
  cCOMBINER_INPUT_NV* = 0x8542
  DRAW_BUFFER0_NV* = 0x8825
  ALPHA_TEST* = 0x0BC0
  PIXEL_UNPACK_BUFFER* = 0x88EC
  SRC_IN_NV* = 0x928A
  COMPRESSED_SIGNED_RED_RGTC1_EXT* = 0x8DBC
  PACK_SUBSAMPLE_RATE_SGIX* = 0x85A0
  FRAMEBUFFER_DEFAULT_SAMPLES* = 0x9313
  ARRAY_OBJECT_OFFSET_ATI* = 0x8767
  TEXTURE_CUBE_MAP_POSITIVE_X_OES* = 0x8515
  STENCIL_BITS* = 0x0D57
  DEPTH_COMPONENT24_OES* = 0x81A6
  FRAMEBUFFER* = 0x8D40
  c8X_BIT_ATI* = 0x00000004
  TEXTURE_BINDING_2D_MULTISAMPLE_ARRAY* = 0x9105
  BOOL_VEC2* = 0x8B57
  EXP* = 0x0800
  TEXTURE_CUBE_MAP_NEGATIVE_Z_EXT* = 0x851A
  STENCIL_INDEX16* = 0x8D49
  FRAGMENT_LIGHTING_SGIX* = 0x8400
  PACK_SKIP_PIXELS* = 0x0D04
  TEXTURE_MIN_LOD* = 0x813A
  COMPRESSED_RGB* = 0x84ED
  MAP1_VERTEX_ATTRIB2_4_NV* = 0x8662
  CONJOINT_NV* = 0x9284
  MAX_COMPUTE_SHARED_MEMORY_SIZE* = 0x8262
  INTENSITY8* = 0x804B
  SAMPLER_2D_MULTISAMPLE* = 0x9108
  MAX_LIST_NESTING* = 0x0B31
  DOUBLE_MAT3* = 0x8F47
  TEXTURE_DEPTH* = 0x8071
  QUADS_FOLLOW_PROVOKING_VERTEX_CONVENTION* = 0x8E4C
  TEXTURE12_ARB* = 0x84CC
  R1UI_T2F_V3F_SUN* = 0x85C9
  REPLACE* = 0x1E01
  MAX_NUM_ACTIVE_VARIABLES* = 0x92F7
  RGBA_INTEGER_EXT* = 0x8D99
  TEXTURE_COMPRESSED_BLOCK_SIZE* = 0x82B3
  INDEX_CLEAR_VALUE* = 0x0C20
  PROGRAM_ERROR_POSITION_ARB* = 0x864B
  LINEARBURN_NV* = 0x92A5
  TEXTURE_BINDING_CUBE_MAP_ARB* = 0x8514
  cTESSELLATION_FACTOR_AMD* = 0x9005
  SHADER_IMAGE_STORE* = 0x82A5
  COMPRESSED_SLUMINANCE_ALPHA_EXT* = 0x8C4B
  MAX_PALETTE_MATRICES_ARB* = 0x8842
  UNPACK_CONSTANT_DATA_SUNX* = 0x81D5
  FLOAT_MAT3x4* = 0x8B68
  DRAW_BUFFER8_NV* = 0x882D
  ATTENUATION_EXT* = 0x834D
  REG_25_ATI* = 0x893A
  UNSIGNED_INT_SAMPLER_1D* = 0x8DD1
  TEXTURE_1D_STACK_BINDING_MESAX* = 0x875D
  SYNC_STATUS_APPLE* = 0x9114
  TEXTURE_CUBE_MAP_ARRAY* = 0x9009
  EXP2* = 0x0801
  COMPRESSED_SIGNED_LUMINANCE_LATC1_EXT* = 0x8C71
  BUFFER_ACCESS_ARB* = 0x88BB
  LO_BIAS_NV* = 0x8715
  MIRROR_CLAMP_ATI* = 0x8742
  SAMPLE_COVERAGE_VALUE* = 0x80AA
  UNSIGNED_INT_24_8_EXT* = 0x84FA
  TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN_EXT* = 0x8C88
  R16UI* = 0x8234
  BLEND_PREMULTIPLIED_SRC_NV* = 0x9280
  COLOR_ATTACHMENT0* = 0x8CE0
  GEOMETRY_VERTICES_OUT_EXT* = 0x8DDA
  SAMPLE_MASK_NV* = 0x8E51
  BGRA_INTEGER_EXT* = 0x8D9B
  PALETTE8_RGBA8_OES* = 0x8B96
  MAX_ARRAY_TEXTURE_LAYERS_EXT* = 0x88FF
  TEXTURE_COLOR_TABLE_SGI* = 0x80BC
  MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS_EXT* = 0x8C80
  TEXTURE10_ARB* = 0x84CA
  TRIANGLES_ADJACENCY* = 0x000C
  COLOR_ARRAY_EXT* = 0x8076
  MAX_FRAMEBUFFER_SAMPLES* = 0x9318
  VERTEX_ATTRIB_ARRAY_BUFFER_BINDING_ARB* = 0x889F
  IMAGE_TEXEL_SIZE* = 0x82A7
  MAGNITUDE_BIAS_NV* = 0x8718
  SHADOW_AMBIENT_SGIX* = 0x80BF
  BUFFER_SERIALIZED_MODIFY_APPLE* = 0x8A12
  TEXTURE_COORD_ARRAY_COUNT_EXT* = 0x808B
  MAX_DRAW_BUFFERS_ARB* = 0x8824
  MAX_OPTIMIZED_VERTEX_SHADER_INVARIANTS_EXT* = 0x87CD
  PASS_THROUGH_TOKEN* = 0x0700
  cBLEND_EQUATION* = 0x8009
  FOG_HINT* = 0x0C54
  FLOAT_RGB16_NV* = 0x8888
  OUTPUT_TEXTURE_COORD18_EXT* = 0x87AF
  T2F_IUI_N3F_V2F_EXT* = 0x81B3
  SAMPLER_EXTERNAL_OES* = 0x8D66
  MAX_SUBROUTINES* = 0x8DE7
  RED_BIT_ATI* = 0x00000001
  SOURCE2_ALPHA* = 0x858A
  AUX0* = 0x0409
  OPERAND1_ALPHA_ARB* = 0x8599
  TEXTURE_MAX_ANISOTROPY_EXT* = 0x84FE
  VERTEX_PROGRAM_POINT_SIZE_NV* = 0x8642
  MULTIVIEW_EXT* = 0x90F1
  FOG_OFFSET_SGIX* = 0x8198
  COLOR_ARRAY_PARALLEL_POINTERS_INTEL* = 0x83F7
  ELEMENT_ARRAY_ATI* = 0x8768
  ALPHA16_SNORM* = 0x9018
  COMPRESSED_SLUMINANCE_EXT* = 0x8C4A
  TEXTURE_OBJECT_VALID_QCOM* = 0x8BDB
  STENCIL_BACK_FUNC* = 0x8800
  cCULL_FACE* = 0x0B44
  MAP1_COLOR_4* = 0x0D90
  SHADER_OBJECT_ARB* = 0x8B48
  COMPRESSED_RGB_PVRTC_2BPPV1_IMG* = 0x8C01
  TANGENT_ARRAY_EXT* = 0x8439
  NUM_FRAGMENT_CONSTANTS_ATI* = 0x896F
  COLOR_RENDERABLE* = 0x8286
  MAX_COMBINED_TEXTURE_IMAGE_UNITS* = 0x8B4D
  TRANSFORM_FEEDBACK_RECORD_NV* = 0x8C86
  COLOR_ATTACHMENT1_NV* = 0x8CE1
  ALPHA_SNORM* = 0x9010
  PIXEL_TRANSFORM_2D_MATRIX_EXT* = 0x8338
  SMOOTH_POINT_SIZE_GRANULARITY* = 0x0B13
  R8I* = 0x8231
  FRAMEBUFFER_INCOMPLETE_MULTISAMPLE_EXT* = 0x8D56
  POLYGON_OFFSET_BIAS_EXT* = 0x8039
  DEPTH_COMPONENT24* = 0x81A6
  TEXTURE_SWIZZLE_B* = 0x8E44
  MAX_TESS_CONTROL_TEXTURE_IMAGE_UNITS* = 0x8E81
  MAP2_INDEX* = 0x0DB1
  SAMPLER_CUBE_MAP_ARRAY* = 0x900C
  FRAMEBUFFER_INCOMPLETE_ATTACHMENT_EXT* = 0x8CD6
  UNSIGNED_INT_8_8_8_8_REV* = 0x8367
  PATH_GEN_COEFF_NV* = 0x90B1
  OPERAND3_ALPHA_NV* = 0x859B
  LUMINANCE* = 0x1909
  MAX_SUBROUTINE_UNIFORM_LOCATIONS* = 0x8DE8
  MAP_READ_BIT* = 0x0001
  MAX_TEXTURE_STACK_DEPTH* = 0x0D39
  ORDER* = 0x0A01
  PATH_FILL_MODE_NV* = 0x9080
  RENDERBUFFER_BLUE_SIZE* = 0x8D52
  TEXTURE_INTENSITY_SIZE* = 0x8061
  DRAW_BUFFER1_NV* = 0x8826
  SCREEN_NV* = 0x9295
  RGB8I_EXT* = 0x8D8F
  MIN_PROGRAM_TEXTURE_GATHER_OFFSET* = 0x8E5E
  DUAL_INTENSITY12_SGIS* = 0x811A
  SPARE1_NV* = 0x852F
  PALETTE8_R5_G6_B5_OES* = 0x8B97
  COLOR_ATTACHMENT7_NV* = 0x8CE7
  TEXTURE_HEIGHT* = 0x1001
  RENDERBUFFER_BINDING* = 0x8CA7
  DRAW_BUFFER7_EXT* = 0x882C
  cHISTOGRAM* = 0x8024
  COLOR_ATTACHMENT0_OES* = 0x8CE0
  BINORMAL_ARRAY_STRIDE_EXT* = 0x8441
  DEBUG_SEVERITY_HIGH_AMD* = 0x9146
  MIN_SPARSE_LEVEL_AMD* = 0x919B
  MAP1_VERTEX_ATTRIB10_4_NV* = 0x866A
  COEFF* = 0x0A00
  COMPRESSED_RGBA_ASTC_6x5_KHR* = 0x93B3
  TEXTURE_4D_BINDING_SGIS* = 0x814F
  BUFFER_USAGE* = 0x8765
  YCBCR_MESA* = 0x8757
  CLAMP_VERTEX_COLOR* = 0x891A
  RGBA8_EXT* = 0x8058
  BITMAP_TOKEN* = 0x0704
  IMAGE_SCALE_Y_HP* = 0x8156
  OUTPUT_TEXTURE_COORD25_EXT* = 0x87B6
  DEBUG_SOURCE_API* = 0x8246
  STACK_UNDERFLOW* = 0x0504
  COMBINER_CD_DOT_PRODUCT_NV* = 0x8546
  FRAMEBUFFER_BINDING_EXT* = 0x8CA6
  REG_20_ATI* = 0x8935
  MAP1_TEXTURE_COORD_4* = 0x0D96
  DEBUG_OUTPUT_SYNCHRONOUS* = 0x8242
  ACCUM_ALPHA_BITS* = 0x0D5B
  INT_10_10_10_2_OES* = 0x8DF7
  FLOAT_MAT2_ARB* = 0x8B5A
  FRONT_RIGHT* = 0x0401
  COMBINER_AB_DOT_PRODUCT_NV* = 0x8545
  LUMINANCE_ALPHA* = 0x190A
  C4UB_V2F* = 0x2A22
  COMBINER_MUX_SUM_NV* = 0x8547
  MODELVIEW_STACK_DEPTH* = 0x0BA3
  SAMPLES_ARB* = 0x80A9
  ALPHA_TEST_FUNC* = 0x0BC1
  DEPTH_CLAMP* = 0x864F
  MAP2_VERTEX_ATTRIB8_4_NV* = 0x8678
  INVALID_INDEX* = 0xFFFFFFFF
  COMBINER_SCALE_NV* = 0x8548
  ATOMIC_COUNTER_BUFFER_REFERENCED_BY_FRAGMENT_SHADER* = 0x92CB
  DOT_PRODUCT_TEXTURE_RECTANGLE_NV* = 0x864E
  RELATIVE_SMALL_CW_ARC_TO_NV* = 0x15
  UNSIGNED_INT_10_10_10_2_OES* = 0x8DF6
  DISCARD_ATI* = 0x8763
  cPRIMITIVE_RESTART_INDEX_NV* = 0x8559
  IMAGE_CLASS_2_X_8* = 0x82C0
  MANUAL_GENERATE_MIPMAP* = 0x8294
  FLOAT_R_NV* = 0x8880
  SATURATE_BIT_ATI* = 0x00000040
  BUFFER_SIZE* = 0x8764
  FRAMEBUFFER_BARRIER_BIT_EXT* = 0x00000400
  LUMINANCE8UI_EXT* = 0x8D80
  T2F_IUI_V2F_EXT* = 0x81B1
  OUTPUT_TEXTURE_COORD15_EXT* = 0x87AC
  COVERAGE_AUTOMATIC_NV* = 0x8ED7
  TEXTURE_INTERNAL_FORMAT_QCOM* = 0x8BD5
  INT_IMAGE_CUBE_MAP_ARRAY* = 0x905F
  BUFFER_UPDATE_BARRIER_BIT_EXT* = 0x00000200
  GLYPH_WIDTH_BIT_NV* = 0x01
  OP_MAX_EXT* = 0x878A
  MINMAX_FORMAT_EXT* = 0x802F
  R16I* = 0x8233
  PROGRAM_NATIVE_TEX_INSTRUCTIONS_ARB* = 0x8809
  TEXTURE_MAX_LEVEL* = 0x813D
  GEOMETRY_SHADER* = 0x8DD9
  MAX_RENDERBUFFER_SIZE* = 0x84E8
  RGB16_EXT* = 0x8054
  DUAL_INTENSITY16_SGIS* = 0x811B
  FRAMEBUFFER_INCOMPLETE_ATTACHMENT* = 0x8CD6
  BLUE_SCALE* = 0x0D1A
  RGBA_FLOAT16_APPLE* = 0x881A
  RGBA8UI* = 0x8D7C
  COLOR_ATTACHMENT5* = 0x8CE5
  UNSIGNED_IDENTITY_NV* = 0x8536
  COMPRESSED_RGBA_ASTC_10x8_KHR* = 0x93BA
  FRAGMENT_SHADER_ARB* = 0x8B30
  R8* = 0x8229
  IMAGE_BINDING_LAYERED* = 0x8F3C
  RGBA_FLOAT32_ATI* = 0x8814
  TEXTURE_RED_SIZE_EXT* = 0x805C
  INT8_VEC2_NV* = 0x8FE1
  NEGATE_BIT_ATI* = 0x00000004
  ALL_BARRIER_BITS_EXT* = 0xFFFFFFFF
  LIGHT_MODEL_COLOR_CONTROL_EXT* = 0x81F8
  LUMINANCE_ALPHA16UI_EXT* = 0x8D7B
  COUNT_UP_NV* = 0x9088
  QUERY_RESULT_AVAILABLE_ARB* = 0x8867
  DRAW_INDIRECT_BUFFER* = 0x8F3F
  FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE_EXT* = 0x8CD3
  OP_DOT3_EXT* = 0x8784
  COLOR_ATTACHMENT10_NV* = 0x8CEA
  STENCIL_INDEX4_OES* = 0x8D47
  LUMINANCE_FLOAT32_ATI* = 0x8818
  DRAW_BUFFER9_ARB* = 0x882E
  RG8_EXT* = 0x822B
  FONT_DESCENDER_BIT_NV* = 0x00400000
  TEXTURE_ALPHA_SIZE_EXT* = 0x805F
  Y_EXT* = 0x87D6
  MAX_GEOMETRY_BINDABLE_UNIFORMS_EXT* = 0x8DE4
  SAMPLER_3D_ARB* = 0x8B5F
  INVERT_OVG_NV* = 0x92B4
  REFERENCED_BY_TESS_EVALUATION_SHADER* = 0x9308
  TEXTURE_COORD_ARRAY_PARALLEL_POINTERS_INTEL* = 0x83F8
  LIGHT4* = 0x4004
  VERTEX_STATE_PROGRAM_NV* = 0x8621
  ZERO* = 0
  SAMPLER_CUBE_MAP_ARRAY_ARB* = 0x900C
  cSAMPLE_MASK_EXT* = 0x80A0
  COMBINER_CD_OUTPUT_NV* = 0x854B
  SAMPLE_ALPHA_TO_MASK_SGIS* = 0x809E
  RGBA16* = 0x805B
  PATH_TERMINAL_DASH_CAP_NV* = 0x907D
  SECONDARY_COLOR_ARRAY_BUFFER_BINDING_ARB* = 0x889C
  DEBUG_SEVERITY_HIGH_KHR* = 0x9146
  DRAW_BUFFER14_EXT* = 0x8833
  READ_FRAMEBUFFER* = 0x8CA8
  UNSIGNED_SHORT_8_8_APPLE* = 0x85BA
  OR* = 0x1507
  ONE_MINUS_DST_ALPHA* = 0x0305
  RGB12* = 0x8053
  FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER_OES* = 0x8CDB
  OUTPUT_TEXTURE_COORD26_EXT* = 0x87B7
  LOCAL_CONSTANT_VALUE_EXT* = 0x87EC
  SURFACE_REGISTERED_NV* = 0x86FD
  FRAGMENT_PROGRAM_INTERPOLATION_OFFSET_BITS_NV* = 0x8E5D
  COMPRESSED_RG_RGTC2* = 0x8DBD
  MAX_VERTEX_ATTRIB_STRIDE* = 0x82E5
  COLOR_ARRAY_ADDRESS_NV* = 0x8F23
  MATRIX_INDEX_ARRAY_POINTER_ARB* = 0x8849
  DUAL_ALPHA8_SGIS* = 0x8111
  TEXTURE_MAX_LOD* = 0x813B
  INTERNALFORMAT_SHARED_SIZE* = 0x8277
  LINEAR_DETAIL_SGIS* = 0x8097
  RG16F_EXT* = 0x822F
  LIST_MODE* = 0x0B30
  VIEWPORT_INDEX_PROVOKING_VERTEX* = 0x825F
  SAMPLER_CUBE_MAP_ARRAY_SHADOW* = 0x900D
  COLOR_TABLE_LUMINANCE_SIZE* = 0x80DE
  COLOR_ARRAY_POINTER* = 0x8090
  MAX_TEXTURE_MAX_ANISOTROPY_EXT* = 0x84FF
  LUMINANCE32F_EXT* = 0x8818
  FRAMEBUFFER_COMPLETE_OES* = 0x8CD5
  MAX_PROGRAM_TEXTURE_GATHER_COMPONENTS_ARB* = 0x8F9F
  FEEDBACK* = 0x1C01
  UNSIGNED_INT_IMAGE_2D_ARRAY* = 0x9069
  VERTEX_STREAM1_ATI* = 0x876D
  SLUMINANCE_ALPHA_NV* = 0x8C44
  MAX_TEXTURE_UNITS_ARB* = 0x84E2
  MODELVIEW11_ARB* = 0x872B
  DRAW_FRAMEBUFFER_BINDING_ANGLE* = 0x8CA6
  NEGATIVE_W_EXT* = 0x87DC
  MODELVIEW25_ARB* = 0x8739
  NORMAL_ARRAY_LIST_STRIDE_IBM* = 103081
  CON_0_ATI* = 0x8941
  VERTEX_SHADER_INSTRUCTIONS_EXT* = 0x87CF
  TRANSPOSE_PROGRAM_MATRIX_EXT* = 0x8E2E
  TEXTURE_DEPTH_TYPE* = 0x8C16
  PROGRAM_TARGET_NV* = 0x8646
  MAX_OPTIMIZED_VERTEX_SHADER_LOCAL_CONSTANTS_EXT* = 0x87CC
  NORMAL_ARRAY_STRIDE_EXT* = 0x807F
  INT_SAMPLER_2D* = 0x8DCA
  MAP2_VERTEX_ATTRIB10_4_NV* = 0x867A
  STEREO* = 0x0C33
  UNSIGNED_INT_IMAGE_2D_RECT_EXT* = 0x9065
  TESS_EVALUATION_PROGRAM_PARAMETER_BUFFER_NV* = 0x8C75
  TRACE_ERRORS_BIT_MESA* = 0x0020
  MAX_GEOMETRY_UNIFORM_BLOCKS* = 0x8A2C
  CONVOLUTION_2D* = 0x8011
  RGB_SCALE_ARB* = 0x8573
  VIDEO_COLOR_CONVERSION_MAX_NV* = 0x902A
  MAX_SHADER_STORAGE_BUFFER_BINDINGS* = 0x90DD
  TABLE_TOO_LARGE_EXT* = 0x8031
  TRANSFORM_FEEDBACK_BINDING_NV* = 0x8E25
  TEXTURE16_ARB* = 0x84D0
  FRAGMENT_SHADER_DERIVATIVE_HINT* = 0x8B8B
  IUI_N3F_V2F_EXT* = 0x81AF
  CLIP_PLANE2_IMG* = 0x3002
  VERTEX_ATTRIB_ARRAY10_NV* = 0x865A
  TEXTURE_FETCH_BARRIER_BIT* = 0x00000008
  DOT3_RGBA_EXT* = 0x8741
  RENDERBUFFER_GREEN_SIZE_EXT* = 0x8D51
  MAX_CLIENT_ATTRIB_STACK_DEPTH* = 0x0D3B
  UNPACK_COMPRESSED_BLOCK_SIZE* = 0x912A
  SAMPLE_BUFFERS_SGIS* = 0x80A8
  MAP1_VERTEX_ATTRIB1_4_NV* = 0x8661
  BUFFER_OBJECT_EXT* = 0x9151
  INT_SAMPLER_1D_ARRAY* = 0x8DCE
  POST_TEXTURE_FILTER_SCALE_SGIX* = 0x817A
  RED_MAX_CLAMP_INGR* = 0x8564
  POST_COLOR_MATRIX_RED_SCALE_SGI* = 0x80B4
  TEXTURE_COORD_ARRAY_TYPE* = 0x8089
  COMPRESSED_SIGNED_RG11_EAC* = 0x9273
  MULTISAMPLE_FILTER_HINT_NV* = 0x8534
  COMPRESSED_RGBA8_ETC2_EAC* = 0x9278
  FONT_UNDERLINE_THICKNESS_BIT_NV* = 0x08000000
  READ_WRITE_ARB* = 0x88BA
  cRENDER_MODE* = 0x0C40
  MAX_NUM_COMPATIBLE_SUBROUTINES* = 0x92F8
  PN_TRIANGLES_NORMAL_MODE_QUADRATIC_ATI* = 0x87F8
  MODELVIEW0_STACK_DEPTH_EXT* = 0x0BA3
  CONTEXT_FLAG_DEBUG_BIT* = 0x00000002
  TRANSFORM_FEEDBACK_BUFFER_START_EXT* = 0x8C84
  POINT_SIZE_MAX_EXT* = 0x8127
  COLOR_ARRAY_LENGTH_NV* = 0x8F2D
  COLOR_COMPONENTS* = 0x8283
  LINEARDODGE_NV* = 0x92A4
  TEXTURE20_ARB* = 0x84D4
  UNSIGNED_INT64_VEC4_NV* = 0x8FF7
  TEXTURE28* = 0x84DC
  HISTOGRAM_FORMAT_EXT* = 0x8027
  PROGRAM_MATRIX_EXT* = 0x8E2D
  PIXEL_PACK_BUFFER_EXT* = 0x88EB
  TEXTURE_CUBE_MAP_POSITIVE_X_EXT* = 0x8515
  STANDARD_FONT_NAME_NV* = 0x9072
  REG_13_ATI* = 0x892E
  GREEN_SCALE* = 0x0D18
  COLOR_BUFFER_BIT7_QCOM* = 0x00000080
  MAX_COMPUTE_ATOMIC_COUNTER_BUFFERS* = 0x8264
  LUMINANCE8_ALPHA8_SNORM* = 0x9016
  GCCSO_SHADER_BINARY_FJ* = 0x9260
  COORD_REPLACE_NV* = 0x8862
  SOURCE2_RGB_EXT* = 0x8582
  IR_INSTRUMENT1_SGIX* = 0x817F
  CONTEXT_FLAG_DEBUG_BIT_KHR* = 0x00000002
  SWIZZLE_STR_ATI* = 0x8976
  OUTPUT_TEXTURE_COORD17_EXT* = 0x87AE
  MODELVIEW2_ARB* = 0x8722
  R1UI_C4F_N3F_V3F_SUN* = 0x85C8
  MAX_TEXTURE_BUFFER_SIZE_ARB* = 0x8C2B
  OUTPUT_TEXTURE_COORD0_EXT* = 0x879D
  POINT_FADE_THRESHOLD_SIZE_EXT* = 0x8128
  OUTPUT_TEXTURE_COORD30_EXT* = 0x87BB
  EVAL_VERTEX_ATTRIB3_NV* = 0x86C9
  SPHERE_MAP* = 0x2402
  SHADER_IMAGE_ATOMIC* = 0x82A6
  INDEX_BITS* = 0x0D51
  INTERNALFORMAT_ALPHA_TYPE* = 0x827B
  CON_15_ATI* = 0x8950
  TESS_EVALUATION_TEXTURE* = 0x829D
  EDGE_FLAG_ARRAY_STRIDE* = 0x808C
  VERTEX_ATTRIB_ARRAY8_NV* = 0x8658
  POST_COLOR_MATRIX_COLOR_TABLE* = 0x80D2
  CLOSE_PATH_NV* = 0x00
  SCALE_BY_TWO_NV* = 0x853E
  PALETTE8_RGB8_OES* = 0x8B95
  MAX_COMPUTE_ATOMIC_COUNTERS* = 0x8265
  VERTEX_ATTRIB_ARRAY_NORMALIZED* = 0x886A
  MAX_VERTEX_ATTRIBS* = 0x8869
  PROGRAM_POINT_SIZE_EXT* = 0x8642
  TRANSLATED_SHADER_SOURCE_LENGTH_ANGLE* = 0x93A0
  SIGNED_NORMALIZED* = 0x8F9C
  MAX_CUBE_MAP_TEXTURE_SIZE_OES* = 0x851C
  OFFSET_TEXTURE_2D_SCALE_NV* = 0x86E2
  COMPRESSED_SLUMINANCE* = 0x8C4A
  MAX_TESS_EVALUATION_UNIFORM_COMPONENTS* = 0x8E80
  RASTER_POSITION_UNCLIPPED_IBM* = 0x19262
  COMPRESSED_TEXTURE_FORMATS_ARB* = 0x86A3
  TRANSPOSE_MODELVIEW_MATRIX* = 0x84E3
  ALPHA_FLOAT16_APPLE* = 0x881C
  PIXEL_MIN_FILTER_EXT* = 0x8332
  MAX_SPARSE_TEXTURE_SIZE_AMD* = 0x9198
  UNSIGNED_SHORT_5_6_5_REV_EXT* = 0x8364
  DU8DV8_ATI* = 0x877A
  COLOR_ARRAY_LIST_IBM* = 103072
  RGBA8I_EXT* = 0x8D8E
  MULTISAMPLE_BUFFER_BIT4_QCOM* = 0x10000000
  DEBUG_TYPE_DEPRECATED_BEHAVIOR_ARB* = 0x824D
  MODELVIEW20_ARB* = 0x8734
  COLOR_TABLE_RED_SIZE* = 0x80DA
  UNIFORM_BARRIER_BIT* = 0x00000004
  TEXTURE* = 0x1702
  CLIP_PLANE0* = 0x3000
  FOG_COORDINATE_ARRAY_POINTER* = 0x8456
  CONSTANT_ALPHA_EXT* = 0x8003
  NAME_STACK_DEPTH* = 0x0D70
  COMPRESSED_RGBA_S3TC_DXT3_ANGLE* = 0x83F2
  LINEAR_DETAIL_ALPHA_SGIS* = 0x8098
  EDGE_FLAG_ARRAY_POINTER_EXT* = 0x8093
  UNSIGNED_SHORT* = 0x1403
  MAP2_VERTEX_ATTRIB1_4_NV* = 0x8671
  DEPTH_CLAMP_FAR_AMD* = 0x901F
  OPERAND3_RGB_NV* = 0x8593
  TEXTURE_SWIZZLE_R_EXT* = 0x8E42
  PATCHES* = 0x000E
  TEXTURE12* = 0x84CC
  COLOR_ATTACHMENT12_EXT* = 0x8CEC
  MAP2_VERTEX_ATTRIB15_4_NV* = 0x867F
  DRAW_BUFFER15_ATI* = 0x8834
  GEOMETRY_INPUT_TYPE* = 0x8917
  COMPRESSED_SRGB8_ALPHA8_ETC2_EAC_OES* = 0x9279
  RGBA32UI_EXT* = 0x8D70
  RGBA_FLOAT32_APPLE* = 0x8814
  NORMAL_MAP_OES* = 0x8511
  MAP2_GRID_DOMAIN* = 0x0DD2
  RELATIVE_HORIZONTAL_LINE_TO_NV* = 0x07
  TANGENT_ARRAY_STRIDE_EXT* = 0x843F
  FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER_EXT* = 0x8CDB
  OBJECT_POINT_SGIS* = 0x81F5
  IMAGE_2D_ARRAY* = 0x9053
  MAX_GEOMETRY_UNIFORM_COMPONENTS_ARB* = 0x8DDF
  SPRITE_MODE_SGIX* = 0x8149
  WEIGHT_ARRAY_OES* = 0x86AD
  MAX_VERTEX_STREAMS* = 0x8E71
  R16F_EXT* = 0x822D
  VERSION_ES_CL_1_0* = 1
  PROXY_TEXTURE_COLOR_TABLE_SGI* = 0x80BD
  MAX_PROGRAM_INSTRUCTIONS_ARB* = 0x88A1
  PURGEABLE_APPLE* = 0x8A1D
  TEXTURE_SWIZZLE_G_EXT* = 0x8E43
  FIRST_VERTEX_CONVENTION_EXT* = 0x8E4D
  DEBUG_SEVERITY_LOW* = 0x9148
  VERTEX_ATTRIB_ARRAY_BARRIER_BIT* = 0x00000001
  OBJECT_ACTIVE_ATTRIBUTE_MAX_LENGTH_ARB* = 0x8B8A
  COMPRESSED_SRGB8_ALPHA8_ASTC_6x6_KHR* = 0x93D4
  DOT_PRODUCT_CONST_EYE_REFLECT_CUBE_MAP_NV* = 0x86F3
  RENDERBUFFER_DEPTH_SIZE* = 0x8D54
  OPERAND1_RGB_ARB* = 0x8591
  REFLECTION_MAP_NV* = 0x8512
  MATRIX17_ARB* = 0x88D1
  EYE_PLANE_ABSOLUTE_NV* = 0x855C
  SRC1_ALPHA* = 0x8589
  UNSIGNED_BYTE_2_3_3_REV* = 0x8362
  RGB5_EXT* = 0x8050
  TEXTURE_2D_ARRAY* = 0x8C1A
  TEXTURE_CUBE_MAP_POSITIVE_X_ARB* = 0x8515
  TEXTURE26* = 0x84DA
  MAX_3D_TEXTURE_SIZE_OES* = 0x8073
  PIXEL_TILE_WIDTH_SGIX* = 0x8140
  PIXEL_UNPACK_BUFFER_BINDING_EXT* = 0x88EF
  TEXTURE_ALPHA_SIZE* = 0x805F
  RELATIVE_QUADRATIC_CURVE_TO_NV* = 0x0B
  POINT_SIZE_ARRAY_BUFFER_BINDING_OES* = 0x8B9F
  GEOMETRY_DEFORMATION_BIT_SGIX* = 0x00000002
  FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS* = 0x8DA8
  NAMED_STRING_LENGTH_ARB* = 0x8DE9
  IMAGE_1D_ARRAY* = 0x9052
  FRAMEBUFFER_ATTACHMENT_TEXTURE_3D_ZOFFSET_OES* = 0x8CD4
  MATRIX28_ARB* = 0x88DC
  FRAGMENT_LIGHT1_SGIX* = 0x840D
  HARDMIX_NV* = 0x92A9
  DEBUG_SOURCE_THIRD_PARTY_KHR* = 0x8249
  PACK_SWAP_BYTES* = 0x0D00
  MAX_VERTEX_UNIFORM_COMPONENTS_ARB* = 0x8B4A
  SOURCE2_ALPHA_EXT* = 0x858A
  DOUBLE_MAT2x4* = 0x8F4A
  MEDIUM_FLOAT* = 0x8DF1
  PIXEL_TILE_BEST_ALIGNMENT_SGIX* = 0x813E
  UNPACK_SKIP_ROWS* = 0x0CF3
  PACK_COMPRESSED_BLOCK_SIZE* = 0x912E
  UNSIGNED_INT_IMAGE_2D* = 0x9063
  COLOR_ARRAY_TYPE_EXT* = 0x8082
  BUFFER_MAP_POINTER_ARB* = 0x88BD
  CALLIGRAPHIC_FRAGMENT_SGIX* = 0x8183
  ONE_MINUS_CONSTANT_COLOR_EXT* = 0x8002
  COMPRESSED_RGBA_FXT1_3DFX* = 0x86B1
  CLIP_PLANE1* = 0x3001
  COVERAGE_BUFFERS_NV* = 0x8ED3
  ADD_BLEND_IMG* = 0x8C09
  COMPRESSED_SRGB8_ALPHA8_ASTC_8x5_KHR* = 0x93D5
  PIXEL_TILE_HEIGHT_SGIX* = 0x8141
  SAMPLE_COVERAGE_INVERT_ARB* = 0x80AB
  MAP1_VERTEX_ATTRIB9_4_NV* = 0x8669
  COLOR_TABLE_BIAS_SGI* = 0x80D7
  EDGE_FLAG_ARRAY_COUNT_EXT* = 0x808D
  SAMPLE_BUFFERS_EXT* = 0x80A8
  COLOR_INDEX* = 0x1900
  REPLACEMENT_CODE_SUN* = 0x81D8
  INT_SAMPLER_CUBE_EXT* = 0x8DCC
  FRAMEBUFFER_INCOMPLETE_MULTISAMPLE_ANGLE* = 0x8D56
  VERTEX_ATTRIB_ARRAY_UNIFIED_NV* = 0x8F1E
  DUAL_LUMINANCE_ALPHA8_SGIS* = 0x811D
  PIXEL_TEX_GEN_ALPHA_LS_SGIX* = 0x8189
  CLIP_DISTANCE7* = 0x3007
  DOT3_RGB_ARB* = 0x86AE
  TEXTURE_WRAP_T* = 0x2803
  LUMINANCE12_EXT* = 0x8041
  TEXTURE_CLIPMAP_VIRTUAL_DEPTH_SGIX* = 0x8174
  TEXTURE_COMPRESSED_IMAGE_SIZE_ARB* = 0x86A0
  EVAL_2D_NV* = 0x86C0
  FRAMEBUFFER_DEFAULT_FIXED_SAMPLE_LOCATIONS* = 0x9314
  CURRENT_WEIGHT_ARB* = 0x86A8
  DEBUG_SOURCE_API_ARB* = 0x8246
  FOG_SPECULAR_TEXTURE_WIN* = 0x80EC
  BOOL_VEC4* = 0x8B59
  FRAGMENTS_INSTRUMENT_SGIX* = 0x8313
  GEOMETRY_OUTPUT_TYPE_EXT* = 0x8DDC
  TEXTURE_2D* = 0x0DE1
  MAT_AMBIENT_AND_DIFFUSE_BIT_PGI* = 0x00200000
  TEXTURE_BINDING_RECTANGLE_ARB* = 0x84F6
  SAMPLE_BUFFERS_3DFX* = 0x86B3
  INDEX_OFFSET* = 0x0D13
  MAX_COLOR_ATTACHMENTS* = 0x8CDF
  PLUS_CLAMPED_NV* = 0x92B1
  SIGNED_NEGATE_NV* = 0x853D
  PROXY_TEXTURE_2D_STACK_MESAX* = 0x875C
  MAX_VERTEX_UNIFORM_COMPONENTS* = 0x8B4A
  SAMPLE_MASK_VALUE_SGIS* = 0x80AA
  QUADRATIC_ATTENUATION* = 0x1209
  LUMINANCE32F_ARB* = 0x8818
  COVERAGE_COMPONENT4_NV* = 0x8ED1
  MINMAX_FORMAT* = 0x802F
  SRGB_DECODE_ARB* = 0x8299
  FRAMEBUFFER_INCOMPLETE_FORMATS_EXT* = 0x8CDA
  UNSIGNED_INT_SAMPLER_CUBE_EXT* = 0x8DD4
  COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2* = 0x9277
  DISJOINT_NV* = 0x9283
  TEXTURE_ENV_BIAS_SGIX* = 0x80BE
  PROXY_TEXTURE_3D_EXT* = 0x8070
  SGX_BINARY_IMG* = 0x8C0A
  COPY_READ_BUFFER* = 0x8F36
  POINT_FADE_THRESHOLD_SIZE_SGIS* = 0x8128
  UNIFORM_MATRIX_STRIDE* = 0x8A3D
  UNIFORM_BLOCK_NAME_LENGTH* = 0x8A41
  HISTOGRAM_LUMINANCE_SIZE* = 0x802C
  UNSIGNED_SHORT_4_4_4_4* = 0x8033
  MAX_DEPTH* = 0x8280
  IMAGE_1D* = 0x904C
  LUMINANCE8_ALPHA8_EXT* = 0x8045
  MAX_TEXTURE_IMAGE_UNITS* = 0x8872
  MODELVIEW16_ARB* = 0x8730
  cCURRENT_PALETTE_MATRIX_OES* = 0x8843
  SIGNED_HILO_NV* = 0x86F9
  FRAMEBUFFER_DEFAULT_HEIGHT* = 0x9311
  UNPACK_SKIP_IMAGES* = 0x806D
  c2_BYTES* = 0x1407
  ALLOW_DRAW_FRG_HINT_PGI* = 0x1A210
  INTENSITY16I_EXT* = 0x8D8B
  MAX_SAMPLES_NV* = 0x8D57
  VERTEX_ARRAY_STORAGE_HINT_APPLE* = 0x851F
  LINE_STRIP_ADJACENCY_ARB* = 0x000B
  COORD_REPLACE* = 0x8862
  INDEX_MATERIAL_FACE_EXT* = 0x81BA
  MODELVIEW15_ARB* = 0x872F
  TEXTURE19* = 0x84D3
  UNSIGNED_INT_IMAGE_1D_ARRAY_EXT* = 0x9068
  SIGNED_INTENSITY8_NV* = 0x8708
  TEXTURE_MAG_SIZE_NV* = 0x871F
  DISPATCH_INDIRECT_BUFFER* = 0x90EE
  MAP1_INDEX* = 0x0D91
  TEXTURE_BUFFER_DATA_STORE_BINDING* = 0x8C2D
  MAX_HEIGHT* = 0x827F
  BLEND_DST_ALPHA* = 0x80CA
  R1UI_C3F_V3F_SUN* = 0x85C6
  TEXTURE_PRIORITY_EXT* = 0x8066
  INT_IMAGE_2D* = 0x9058
  MAX_MULTISAMPLE_COVERAGE_MODES_NV* = 0x8E11
  DRAW_BUFFER4_ATI* = 0x8829
  MAX_GEOMETRY_VARYING_COMPONENTS_ARB* = 0x8DDD
  DEPTH_EXT* = 0x1801
  SAMPLE_POSITION* = 0x8E50
  INTERNALFORMAT_DEPTH_TYPE* = 0x827C
  MATRIX23_ARB* = 0x88D7
  DEBUG_TYPE_PUSH_GROUP* = 0x8269
  POLYGON_OFFSET_FILL* = 0x8037
  FRAGMENT_PROGRAM_BINDING_NV* = 0x8873
  FRAMEBUFFER_SRGB_CAPABLE_EXT* = 0x8DBA
  cVERTEX_ATTRIB_BINDING* = 0x82D4
  UNSIGNED_INT8_VEC2_NV* = 0x8FED
  POLYGON_OFFSET_FACTOR* = 0x8038
  BOLD_BIT_NV* = 0x01
  CLAMP_TO_BORDER_ARB* = 0x812D
  INDEX_MODE* = 0x0C30
  SAMPLER_CUBE_SHADOW_NV* = 0x8DC5
  COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT* = 0x8C4F
  MATRIX21_ARB* = 0x88D5
  UNPACK_ROW_LENGTH_EXT* = 0x0CF2
  FRAGMENT_NORMAL_EXT* = 0x834A
  DOT3_ATI* = 0x8966
  IMPLEMENTATION_COLOR_READ_TYPE_OES* = 0x8B9A
  IMAGE_BINDING_ACCESS_EXT* = 0x8F3E
  SYNC_CL_EVENT_ARB* = 0x8240
  UNSIGNED_INT_24_8* = 0x84FA
  c2PASS_1_EXT* = 0x80A3
  POST_TEXTURE_FILTER_BIAS_SGIX* = 0x8179
  TEXTURE_COMPRESSED_IMAGE_SIZE* = 0x86A0
  LUMINANCE_ALPHA32UI_EXT* = 0x8D75
  FORCE_BLUE_TO_ONE_NV* = 0x8860
  FRAMEBUFFER_DEFAULT* = 0x8218
  VIRTUAL_PAGE_SIZE_Z_ARB* = 0x9197
  cTEXTURE_LIGHT_EXT* = 0x8350
  MULTISAMPLE_BUFFER_BIT5_QCOM* = 0x20000000
  UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE_ARRAY* = 0x910D
  SYNC_CONDITION* = 0x9113
  PERFMON_RESULT_SIZE_AMD* = 0x8BC5
  PROGRAM_OBJECT_ARB* = 0x8B40
  MAX_SHININESS_NV* = 0x8504
  PROGRAM_NATIVE_TEX_INDIRECTIONS_ARB* = 0x880A
  RENDERBUFFER_COLOR_SAMPLES_NV* = 0x8E10
  MAX_COMBINED_VERTEX_UNIFORM_COMPONENTS* = 0x8A31
  ACTIVE_SUBROUTINE_UNIFORM_MAX_LENGTH* = 0x8E49
  MODELVIEW29_ARB* = 0x873D
  PROXY_TEXTURE_CUBE_MAP_ARRAY_ARB* = 0x900B
  SIGNED_HILO16_NV* = 0x86FA
  TRANSFORM_HINT_APPLE* = 0x85B1
  STENCIL_INDEX4* = 0x8D47
  EXTENSIONS* = 0x1F03
  RG16F* = 0x822F
  MAP_UNSYNCHRONIZED_BIT_EXT* = 0x0020
  LUMINANCE16F_ARB* = 0x881E
  UNSIGNED_INT_IMAGE_BUFFER* = 0x9067
  COMPRESSED_RGBA_ASTC_8x8_KHR* = 0x93B7
  AVERAGE_HP* = 0x8160
  cINDEX_MATERIAL_EXT* = 0x81B8
  cCOLOR_TABLE* = 0x80D0
  FOG_COORDINATE_ARRAY_LIST_IBM* = 103076
  DEBUG_CATEGORY_OTHER_AMD* = 0x9150
  R1UI_C4UB_V3F_SUN* = 0x85C5
  SYSTEM_FONT_NAME_NV* = 0x9073
  STATIC_VERTEX_ARRAY_IBM* = 103061
  VERTEX_ATTRIB_ARRAY_DIVISOR_NV* = 0x88FE
  SCALE_BY_ONE_HALF_NV* = 0x8540
  INTENSITY_FLOAT32_ATI* = 0x8817
  FRAGMENT_LIGHT6_SGIX* = 0x8412
  DECR_WRAP_OES* = 0x8508
  MODELVIEW23_ARB* = 0x8737
  PROXY_TEXTURE_1D_ARRAY* = 0x8C19
  REFERENCED_BY_VERTEX_SHADER* = 0x9306
  MAX_NAME_LENGTH* = 0x92F6
  AFFINE_2D_NV* = 0x9092
  SYNC_OBJECT_APPLE* = 0x8A53
  PLUS_DARKER_NV* = 0x9292
  TESS_CONTROL_PROGRAM_NV* = 0x891E
  RGB_SCALE* = 0x8573
  RGBA16UI_EXT* = 0x8D76
  COMPATIBLE_SUBROUTINES* = 0x8E4B
  COLOR_TABLE_WIDTH* = 0x80D9
  MAX_COMBINED_UNIFORM_BLOCKS* = 0x8A2E
  BACK_SECONDARY_COLOR_NV* = 0x8C78
  MAX_COMPUTE_VARIABLE_GROUP_INVOCATIONS_ARB* = 0x9344
  SECONDARY_COLOR_NV* = 0x852D
  RGB16UI_EXT* = 0x8D77
  SHADER_STORAGE_BUFFER_SIZE* = 0x90D5
  VERTEX_SUBROUTINE* = 0x92E8
  MAP_COLOR* = 0x0D10
  OBJECT_TYPE_ARB* = 0x8B4E
  LAST_VIDEO_CAPTURE_STATUS_NV* = 0x9027
  RGB12_EXT* = 0x8053
  UNSIGNED_INT_IMAGE_3D_EXT* = 0x9064
  LUMINANCE8_ALPHA8* = 0x8045
  FLOAT_RGBA_MODE_NV* = 0x888E
  CURRENT_RASTER_COLOR* = 0x0B04
  CURRENT_RASTER_POSITION* = 0x0B07
  UNIFORM_BLOCK_DATA_SIZE* = 0x8A40
  MALI_PROGRAM_BINARY_ARM* = 0x8F61
  QUERY_COUNTER_BITS_ARB* = 0x8864
  VARIANT_ARRAY_EXT* = 0x87E8
  VIDEO_CAPTURE_FIELD_UPPER_HEIGHT_NV* = 0x903A
  DEPTH_COMPONENT24_ARB* = 0x81A6
  UNSIGNED_INVERT_NV* = 0x8537
  TEXTURE_IMMUTABLE_LEVELS* = 0x82DF
  DRAW_BUFFER12_ATI* = 0x8831
  MAP_FLUSH_EXPLICIT_BIT_EXT* = 0x0010
  INDEX_WRITEMASK* = 0x0C21
  POLYGON_SMOOTH* = 0x0B41
  COMPRESSED_SIGNED_R11_EAC_OES* = 0x9271
  TEXTURE_SWIZZLE_A_EXT* = 0x8E45
  TEXTURE_COORD_ARRAY_STRIDE* = 0x808A
  PIXEL_MAP_I_TO_R* = 0x0C72
  CONVOLUTION_HEIGHT* = 0x8019
  SIGNALED* = 0x9119
  UNSIGNED_INT_24_8_OES* = 0x84FA
  DRAW_BUFFER6_ARB* = 0x882B
  BUFFER_SIZE_ARB* = 0x8764
  CLEAR_BUFFER* = 0x82B4
  LUMINANCE16UI_EXT* = 0x8D7A
  FRAMEBUFFER_ATTACHMENT_ANGLE* = 0x93A3
  STENCIL_ATTACHMENT* = 0x8D20
  ALL_COMPLETED_NV* = 0x84F2
  MIN* = 0x8007
  COLOR_ATTACHMENT11* = 0x8CEB
  cPATH_STENCIL_FUNC_NV* = 0x90B7
  MAX_LABEL_LENGTH* = 0x82E8
  WEIGHT_ARRAY_TYPE_OES* = 0x86A9
  ACCUM_BUFFER_BIT* = 0x00000200
  WEIGHT_ARRAY_POINTER_ARB* = 0x86AC
  WEIGHT_SUM_UNITY_ARB* = 0x86A6
  COMPRESSED_SRGB_EXT* = 0x8C48
  ATTRIB_ARRAY_TYPE_NV* = 0x8625
  RED_INTEGER_EXT* = 0x8D94
  ALWAYS_SOFT_HINT_PGI* = 0x1A20D
  COMPRESSED_SRGB8_ETC2_OES* = 0x9275
  LOW_FLOAT* = 0x8DF0
  PIXEL_FRAGMENT_RGB_SOURCE_SGIS* = 0x8354
  TEXTURE_LEQUAL_R_SGIX* = 0x819C
  CONTEXT_COMPATIBILITY_PROFILE_BIT* = 0x00000002
  INCR* = 0x1E02
  c3D* = 0x0601
  SHADER_KHR* = 0x82E1
  SRC_COLOR* = 0x0300
  DRAW_BUFFER7_NV* = 0x882C
  VERTEX_ARRAY_SIZE* = 0x807A
  SAMPLER_2D_RECT* = 0x8B63
  UNSIGNED_SHORT_4_4_4_4_REV_IMG* = 0x8365
  READ_PIXEL_DATA_RANGE_NV* = 0x8879
  cEDGE_FLAG* = 0x0B43
  TEXTURE_3D_EXT* = 0x806F
  DOT_PRODUCT_TEXTURE_1D_NV* = 0x885C
  COLOR_SUM_CLAMP_NV* = 0x854F
  RGB10_A2* = 0x8059
  BOOL_VEC3* = 0x8B58
  REG_3_ATI* = 0x8924
  LINEAR_SHARPEN_ALPHA_SGIS* = 0x80AE
  FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS_EXT* = 0x8DA8
  MAP1_VERTEX_ATTRIB5_4_NV* = 0x8665
  MAX_COMBINED_IMAGE_UNITS_AND_FRAGMENT_OUTPUTS* = 0x8F39
  PIXEL_MAP_I_TO_B_SIZE* = 0x0CB4
  TRANSFORM_FEEDBACK_BARRIER_BIT_EXT* = 0x00000800
  COLOR_BUFFER_BIT6_QCOM* = 0x00000040
  PROGRAM_TEMPORARIES_ARB* = 0x88A4
  ELEMENT_ARRAY_BUFFER* = 0x8893
  ALWAYS_FAST_HINT_PGI* = 0x1A20C
  INTENSITY_FLOAT16_ATI* = 0x881D
  ACTIVE_ATTRIBUTE_MAX_LENGTH* = 0x8B8A
  CON_12_ATI* = 0x894D
  LINEAR_MIPMAP_NEAREST* = 0x2701
  TEXTURE_COVERAGE_SAMPLES_NV* = 0x9045
  MAX_PROGRAM_NATIVE_PARAMETERS_ARB* = 0x88AB
  DEPTH_SCALE* = 0x0D1E
  SOURCE3_ALPHA_NV* = 0x858B
  ACTIVE_VERTEX_UNITS_ARB* = 0x86A5
  SWIZZLE_STR_DR_ATI* = 0x8978
  RGB16I_EXT* = 0x8D89
  INT_IMAGE_2D_RECT_EXT* = 0x905A
  GREEN_BIAS* = 0x0D19
  FRAMEBUFFER_RENDERABLE_LAYERED* = 0x828A
  COMPRESSED_RGB8_ETC2* = 0x9274
  COMPRESSED_RGBA_ARB* = 0x84EE
  MAX_VERTEX_ATOMIC_COUNTERS* = 0x92D2
  RGBA32I_EXT* = 0x8D82
  WAIT_FAILED* = 0x911D
  FOG_COORDINATE_SOURCE_EXT* = 0x8450
  SAMPLE_MASK_VALUE_NV* = 0x8E52
  OP_MUL_EXT* = 0x8786
  FRAGMENT_TEXTURE* = 0x829F
  GEOMETRY_PROGRAM_NV* = 0x8C26
  MATRIX20_ARB* = 0x88D4
  SECONDARY_COLOR_ARRAY_STRIDE_EXT* = 0x845C
  UNSIGNED_INT_2_10_10_10_REV_EXT* = 0x8368
  PHONG_HINT_WIN* = 0x80EB
  EYE_DISTANCE_TO_LINE_SGIS* = 0x81F2
  SAMPLES_PASSED* = 0x8914
  MAX_COLOR_ATTACHMENTS_NV* = 0x8CDF
  WEIGHT_ARRAY_POINTER_OES* = 0x86AC
  MAX_DEBUG_GROUP_STACK_DEPTH* = 0x826C
  TEXTURE_2D_STACK_BINDING_MESAX* = 0x875E
  VARIANT_VALUE_EXT* = 0x87E4
  TEXTURE_GEN_R* = 0x0C62
  COMPRESSED_RG11_EAC* = 0x9272
  IMAGE_ROTATE_ORIGIN_Y_HP* = 0x815B
  BLEND_ADVANCED_COHERENT_NV* = 0x9285
  DEBUG_CALLBACK_FUNCTION* = 0x8244
  PROXY_TEXTURE_4D_SGIS* = 0x8135
  OCCLUSION_TEST_RESULT_HP* = 0x8166
  COLOR_ATTACHMENT13_EXT* = 0x8CED
  LINE_STRIP_ADJACENCY* = 0x000B
  DEBUG_CATEGORY_APPLICATION_AMD* = 0x914F
  CIRCULAR_TANGENT_ARC_TO_NV* = 0xFC
  MAX_PROGRAM_NATIVE_ADDRESS_REGISTERS_ARB* = 0x88B3
  VERTEX_ATTRIB_ARRAY_STRIDE* = 0x8624
  COMPRESSED_SRGB_ALPHA_EXT* = 0x8C49
  UNSIGNED_INT_SAMPLER_CUBE_MAP_ARRAY* = 0x900F
  UNSIGNED_INT_IMAGE_2D_MULTISAMPLE_ARRAY* = 0x906C
  LIGHT_MODEL_COLOR_CONTROL* = 0x81F8
  INT_VEC2_ARB* = 0x8B53
  PARALLEL_ARRAYS_INTEL* = 0x83F4
  COLOR_ATTACHMENT11_EXT* = 0x8CEB
  SAMPLE_ALPHA_TO_ONE_SGIS* = 0x809F
  FUNC_ADD_OES* = 0x8006
  COMBINER_MAPPING_NV* = 0x8543
  INT_IMAGE_BUFFER* = 0x905C
  TEXTURE_SWIZZLE_A* = 0x8E45
  FRAMEBUFFER_ATTACHMENT_LAYERED_ARB* = 0x8DA7
  EXPAND_NEGATE_NV* = 0x8539
  COVERAGE_EDGE_FRAGMENTS_NV* = 0x8ED6
  PATH_OBJECT_BOUNDING_BOX_NV* = 0x908A
  MAX_RECTANGLE_TEXTURE_SIZE* = 0x84F8
  FONT_ASCENDER_BIT_NV* = 0x00200000
  INDEX_SHIFT* = 0x0D12
  LUMINANCE6_ALPHA2* = 0x8044
  FLOAT_CLEAR_COLOR_VALUE_NV* = 0x888D
  V2F* = 0x2A20
  DRAW_BUFFER12_NV* = 0x8831
  RIGHT* = 0x0407
  CON_28_ATI* = 0x895D
  SAMPLER_CUBE_ARB* = 0x8B60
  OUTPUT_TEXTURE_COORD27_EXT* = 0x87B8
  MAX_DEPTH_TEXTURE_SAMPLES* = 0x910F
  MODULATE* = 0x2100
  NUM_FILL_STREAMS_NV* = 0x8E29
  DT_SCALE_NV* = 0x8711
  ONE_MINUS_SRC_COLOR* = 0x0301
  OPERAND2_ALPHA* = 0x859A
  MATRIX15_ARB* = 0x88CF
  MULTISAMPLE* = 0x809D
  DEPTH32F_STENCIL8* = 0x8CAD
  COMPRESSED_RGBA_ASTC_4x4_KHR* = 0x93B0
  DUAL_ALPHA16_SGIS* = 0x8113
  COMPRESSED_RGB_FXT1_3DFX* = 0x86B0
  PROXY_TEXTURE_2D_ARRAY* = 0x8C1B
  UNIFORM_NAME_LENGTH* = 0x8A39
  COMPILE_AND_EXECUTE* = 0x1301
  COMPRESSED_RGBA_PVRTC_4BPPV2_IMG* = 0x9138
  PIXEL_CUBIC_WEIGHT_EXT* = 0x8333
  GREEN_MIN_CLAMP_INGR* = 0x8561
  MAX_TEXTURE_LOD_BIAS* = 0x84FD
  NORMAL_MAP_NV* = 0x8511
  PIXEL_UNPACK_BUFFER_BINDING_ARB* = 0x88EF
  LUMINANCE_ALPHA32F_ARB* = 0x8819
  LUMINANCE_FLOAT16_APPLE* = 0x881E
  FACTOR_MIN_AMD* = 0x901C
  BUFFER_GPU_ADDRESS_NV* = 0x8F1D
  DEBUG_TYPE_PERFORMANCE_ARB* = 0x8250
  TEXTURE_RESIDENT* = 0x8067
  TESS_CONTROL_SHADER_BIT* = 0x00000008
  VERTEX_SHADER* = 0x8B31
  COLOR_ATTACHMENT15_EXT* = 0x8CEF
  DRAW_BUFFER2_NV* = 0x8827
  UNSIGNED_INT* = 0x1405
  TEXTURE_SHARED_SIZE_EXT* = 0x8C3F
  LIGHT5* = 0x4005
  VERTEX_ARRAY_SIZE_EXT* = 0x807A
  YCRCB_SGIX* = 0x8318
  ATOMIC_COUNTER_BUFFER_REFERENCED_BY_TESS_EVALUATION_SHADER* = 0x92C9
  FRAMEBUFFER_ATTACHMENT_OBJECT_NAME_OES* = 0x8CD1
  QUADRATIC_CURVE_TO_NV* = 0x0A
  POINTS* = 0x0000
  OPERAND1_RGB* = 0x8591
  POINT_DISTANCE_ATTENUATION_ARB* = 0x8129
  QUERY_BUFFER_BARRIER_BIT* = 0x00008000
  QUAD_LUMINANCE4_SGIS* = 0x8120
  GENERATE_MIPMAP_SGIS* = 0x8191
  FRAMEBUFFER_UNSUPPORTED_EXT* = 0x8CDD
  PALETTE4_RGB5_A1_OES* = 0x8B94
  TEXTURE_CROP_RECT_OES* = 0x8B9D
  COMPUTE_SHADER_BIT* = 0x00000020
  OUTPUT_TEXTURE_COORD2_EXT* = 0x879F
  PALETTE4_RGBA4_OES* = 0x8B93
  TEXTURE_CLIPMAP_CENTER_SGIX* = 0x8171
  BLUE_BITS* = 0x0D54
  RELATIVE_LARGE_CCW_ARC_TO_NV* = 0x17
  UNSIGNED_SHORT_5_6_5_EXT* = 0x8363
  MAX_GEOMETRY_TOTAL_OUTPUT_COMPONENTS* = 0x8DE1
  UNCORRELATED_NV* = 0x9282
  TESS_EVALUATION_SUBROUTINE* = 0x92EA
  MIN_PROGRAM_TEXTURE_GATHER_OFFSET_ARB* = 0x8E5E
  CON_11_ATI* = 0x894C
  cACTIVE_TEXTURE* = 0x84E0
  ASYNC_TEX_IMAGE_SGIX* = 0x835C
  COLOR_CLEAR_VALUE* = 0x0C22
  INT_SAMPLER_2D_MULTISAMPLE_ARRAY* = 0x910C
  TESS_CONTROL_TEXTURE* = 0x829C
  TEXTURE_CUBE_MAP_NEGATIVE_Z_OES* = 0x851A
  HISTOGRAM_BLUE_SIZE_EXT* = 0x802A
  PATCH_DEFAULT_OUTER_LEVEL* = 0x8E74
  PROGRAM_MATRIX_STACK_DEPTH_EXT* = 0x8E2F
  RENDERBUFFER_BINDING_ANGLE* = 0x8CA7
  CONSTANT_ATTENUATION* = 0x1207
  SHADER_CONSISTENT_NV* = 0x86DD
  MAX_TESS_EVALUATION_ATOMIC_COUNTERS* = 0x92D4
  EXTERNAL_VIRTUAL_MEMORY_BUFFER_AMD* = 0x9160
  DETAIL_TEXTURE_FUNC_POINTS_SGIS* = 0x809C
  INT_IMAGE_2D_MULTISAMPLE_ARRAY_EXT* = 0x9061
  COUNT_DOWN_NV* = 0x9089
  MATRIX12_ARB* = 0x88CC
  MAX_VERTEX_SHADER_INVARIANTS_EXT* = 0x87C7
  REPLICATE_BORDER_HP* = 0x8153
  MODELVIEW9_ARB* = 0x8729
  ANY_SAMPLES_PASSED_CONSERVATIVE_EXT* = 0x8D6A
  PROGRAM_PARAMETERS_ARB* = 0x88A8
  LIST_BIT* = 0x00020000
  MAX_GEOMETRY_ATOMIC_COUNTERS* = 0x92D5
  CONSTANT_COLOR1_NV* = 0x852B
  AVERAGE_EXT* = 0x8335
  SINGLE_COLOR_EXT* = 0x81F9
  VERTEX_ARRAY* = 0x8074
  COLOR_INDEX1_EXT* = 0x80E2
  COMPUTE_PROGRAM_NV* = 0x90FB
  LINES_ADJACENCY* = 0x000A
  OP_ROUND_EXT* = 0x8790
  TRANSFORM_FEEDBACK_BUFFER_STRIDE* = 0x934C
  MAX_DEEP_3D_TEXTURE_DEPTH_NV* = 0x90D1
  REG_11_ATI* = 0x892C
  SAMPLES_EXT* = 0x80A9
  FUNC_REVERSE_SUBTRACT* = 0x800B
  POINT_SPRITE_COORD_ORIGIN* = 0x8CA0
  REG_27_ATI* = 0x893C
  TEXTURE_VIEW_MIN_LEVEL* = 0x82DB
  NICEST* = 0x1102
  CLIP_PLANE4_IMG* = 0x3004
  ARRAY_BUFFER_BINDING* = 0x8894
  c422_AVERAGE_EXT* = 0x80CE
  RENDERER* = 0x1F01
  OVERLAY_NV* = 0x9296
  TEXTURE_SAMPLES_IMG* = 0x9136
  DEBUG_SOURCE_SHADER_COMPILER_KHR* = 0x8248
  EYE_DISTANCE_TO_POINT_SGIS* = 0x81F0
  MAX_PROGRAM_GENERIC_ATTRIBS_NV* = 0x8DA5
  FILTER4_SGIS* = 0x8146
  LIGHT_MODEL_LOCAL_VIEWER* = 0x0B51
  TRIANGLE_MESH_SUN* = 0x8615
  SAMPLER_CUBE_MAP_ARRAY_SHADOW_ARB* = 0x900D
  DEPTH_COMPONENTS* = 0x8284
  NUM_GENERAL_COMBINERS_NV* = 0x854E
  cCLIENT_ACTIVE_TEXTURE_ARB* = 0x84E1
  FRAGMENT_DEPTH* = 0x8452
  SEPARATE_ATTRIBS* = 0x8C8D
  HALF_FLOAT_OES* = 0x8D61
  PROXY_TEXTURE_2D* = 0x8064
  VARIANT_ARRAY_TYPE_EXT* = 0x87E7
  DRAW_BUFFER11_ATI* = 0x8830
  MATRIX_INDEX_ARRAY_POINTER_OES* = 0x8849
  CURRENT_INDEX* = 0x0B01
  UNSIGNED_INT_24_8_MESA* = 0x8751
  PROGRAM_SEPARABLE* = 0x8258
  TEXTURE8_ARB* = 0x84C8
  OPERAND0_ALPHA_EXT* = 0x8598
  PER_STAGE_CONSTANTS_NV* = 0x8535
  LINE_LOOP* = 0x0002
  DRAW_PIXEL_TOKEN* = 0x0705
  DRAW_BUFFER3* = 0x8828
  GEOMETRY_DEFORMATION_SGIX* = 0x8194
  MAX_CUBE_MAP_TEXTURE_SIZE_EXT* = 0x851C
  GLYPH_VERTICAL_BEARING_X_BIT_NV* = 0x20
  TEXTURE30* = 0x84DE
  c4PASS_1_EXT* = 0x80A5
  RGB16F_EXT* = 0x881B
  c2PASS_0_SGIS* = 0x80A2
  CON_27_ATI* = 0x895C
  SAMPLE_ALPHA_TO_ONE* = 0x809F
  POLYGON_SMOOTH_HINT* = 0x0C53
  COLOR_ATTACHMENT_EXT* = 0x90F0
  PATCH_DEFAULT_INNER_LEVEL* = 0x8E73
  TEXTURE_MAX_CLAMP_T_SGIX* = 0x836A
  WEIGHT_ARRAY_BUFFER_BINDING_OES* = 0x889E
  TEXTURE1* = 0x84C1
  LINES* = 0x0001
  PIXEL_TILE_GRID_DEPTH_SGIX* = 0x8144
  TEXTURE2* = 0x84C2
  IMAGE_CUBE_MAP_ARRAY_EXT* = 0x9054
  DRAW_BUFFER4* = 0x8829
  DRAW_BUFFER_EXT* = 0x0C01
  STENCIL_INDEX1* = 0x8D46
  DEPTH_COMPONENT32F_NV* = 0x8DAB
  VERTEX_ATTRIB_ARRAY_POINTER* = 0x8645
  DOUBLE_MAT4x2* = 0x8F4D
  MOVE_TO_NV* = 0x02
  OP_RECIP_SQRT_EXT* = 0x8795
  SAMPLER_1D_ARRAY* = 0x8DC0
  MIN_FRAGMENT_INTERPOLATION_OFFSET* = 0x8E5B
  TEXTURE_DEPTH_EXT* = 0x8071
  STENCIL_INDEX8* = 0x8D48
  MAX_PROGRAM_TEX_INSTRUCTIONS_ARB* = 0x880C
  INTERNALFORMAT_DEPTH_SIZE* = 0x8275
  STATE_RESTORE* = 0x8BDC
  SMALL_CW_ARC_TO_NV* = 0x14
  LUMINANCE16* = 0x8042
  VERTEX_ATTRIB_ARRAY1_NV* = 0x8651
  TEXTURE_MAX_CLAMP_R_SGIX* = 0x836B
  LUMINANCE_FLOAT16_ATI* = 0x881E
  MAX_TEXTURE_UNITS* = 0x84E2
  DRAW_BUFFER4_ARB* = 0x8829
  DRAW_BUFFER12* = 0x8831
  R8UI* = 0x8232
  STENCIL_REF* = 0x0B97
  VARIANT_EXT* = 0x87C1
  VERTEX_ATTRIB_MAP2_DOMAIN_APPLE* = 0x8A09
  QUERY_OBJECT_AMD* = 0x9153
  PLUS_NV* = 0x9291
  UNPACK_SWAP_BYTES* = 0x0CF0
  MAX_UNIFORM_LOCATIONS* = 0x826E
  GUILTY_CONTEXT_RESET_EXT* = 0x8253
  DOT3_RGBA_IMG* = 0x86AF
  X_EXT* = 0x87D5
  UNSIGNED_INT_SAMPLER_CUBE_MAP_ARRAY_ARB* = 0x900F
  TEXTURE_COMPARE_FAIL_VALUE_ARB* = 0x80BF
  ETC1_RGB8_OES* = 0x8D64
  LUMINANCE_ALPHA_INTEGER_EXT* = 0x8D9D
  MINMAX_SINK* = 0x8030
  RG32F* = 0x8230
  PROXY_TEXTURE_2D_MULTISAMPLE* = 0x9101
  RGBA_UNSIGNED_DOT_PRODUCT_MAPPING_NV* = 0x86D9
  R16* = 0x822A
  BOUNDING_BOX_NV* = 0x908D
  INVALID_ENUM* = 0x0500
  MOVE_TO_RESETS_NV* = 0x90B5
  SYNC_GPU_COMMANDS_COMPLETE_APPLE* = 0x9117
  MAX_RECTANGLE_TEXTURE_SIZE_ARB* = 0x84F8
  UNSIGNED_INT_10F_11F_11F_REV_EXT* = 0x8C3B
  VERTEX_PRECLIP_HINT_SGIX* = 0x83EF
  CLIENT_VERTEX_ARRAY_BIT* = 0x00000002
  MAT_COLOR_INDEXES_BIT_PGI* = 0x01000000
  PERFORMANCE_MONITOR_AMD* = 0x9152
  QUAD_STRIP* = 0x0008
  MAX_TEXTURE_COORDS_NV* = 0x8871
  TESS_EVALUATION_SUBROUTINE_UNIFORM* = 0x92F0
  DRAW_BUFFER1_EXT* = 0x8826
  TEXTURE18* = 0x84D2
  COLOR_ATTACHMENT5_NV* = 0x8CE5
  MAX_COMPUTE_WORK_GROUP_SIZE* = 0x91BF
  T2F_C4UB_V3F* = 0x2A29
  MAP1_GRID_DOMAIN* = 0x0DD0
  DEBUG_TYPE_PUSH_GROUP_KHR* = 0x8269
  STATIC_READ* = 0x88E5
  MAX_PROGRAM_NATIVE_ALU_INSTRUCTIONS_ARB* = 0x880E
  DOUBLE_EXT* = 0x140A
  MAX_FRAGMENT_UNIFORM_VECTORS* = 0x8DFD
  R32F_EXT* = 0x822E
  MAX_RENDERBUFFER_SIZE_EXT* = 0x84E8
  COMPRESSED_TEXTURE_FORMATS* = 0x86A3
  MAX_EXT* = 0x8008
  VERTEX_ATTRIB_ARRAY_ENABLED_ARB* = 0x8622
  INTERPOLATE* = 0x8575
  QUERY_RESULT_NO_WAIT_AMD* = 0x9194
  TEXTURE_CUBE_MAP_NEGATIVE_X_OES* = 0x8516
  LUMINANCE16_ALPHA16_SNORM* = 0x901A
  SRC_ALPHA_SATURATE* = 0x0308
  DRAW_INDIRECT_BUFFER_BINDING* = 0x8F43
  T2F_IUI_N3F_V3F_EXT* = 0x81B4
  MAX_FRAGMENT_UNIFORM_COMPONENTS_ARB* = 0x8B49
  MAX_ASYNC_READ_PIXELS_SGIX* = 0x8361
  cVERTEX_ARRAY_RANGE_APPLE* = 0x851D
  SAMPLER_2D_SHADOW_ARB* = 0x8B62
  ETC1_SRGB8_NV* = 0x88EE
  COLORBURN_NV* = 0x929A
  SAMPLER_2D_ARRAY_SHADOW_EXT* = 0x8DC4
  ALL_BARRIER_BITS* = 0xFFFFFFFF
  TRIANGLE_STRIP_ADJACENCY_EXT* = 0x000D
  MAX_TEXTURE_BUFFER_SIZE* = 0x8C2B
  ALIASED_POINT_SIZE_RANGE* = 0x846D
  STENCIL_BACK_VALUE_MASK* = 0x8CA4
  CMYK_EXT* = 0x800C
  OPERAND1_ALPHA_EXT* = 0x8599
  TEXTURE_SHADOW* = 0x82A1
  LINEAR_CLIPMAP_LINEAR_SGIX* = 0x8170
  MIPMAP* = 0x8293
  LINE_SMOOTH_HINT* = 0x0C52
  DEPTH_STENCIL_TEXTURE_MODE* = 0x90EA
  BUFFER_ACCESS_OES* = 0x88BB
  PROXY_TEXTURE_1D_ARRAY_EXT* = 0x8C19
  OBJECT_LINEAR* = 0x2401
  MAP1_TEXTURE_COORD_3* = 0x0D95
  TEXTURE_RENDERBUFFER_NV* = 0x8E55
  FRAMEBUFFER_RENDERABLE* = 0x8289
  DOT3_RGB_EXT* = 0x8740
  QUAD_LUMINANCE8_SGIS* = 0x8121
  UNIFORM_BLOCK_INDEX* = 0x8A3A
  DS_SCALE_NV* = 0x8710
  TYPE* = 0x92FA
  MATRIX_EXT* = 0x87C0
  VERTEX_STREAM4_ATI* = 0x8770
  TOP_LEVEL_ARRAY_STRIDE* = 0x930D
  INT_SAMPLER_2D_EXT* = 0x8DCA
  PATH_FORMAT_PS_NV* = 0x9071
  COMPRESSED_SRGB8_ALPHA8_ASTC_5x5_KHR* = 0x93D2
  MAX_TEXTURE_COORDS* = 0x8871
  MAX_FRAGMENT_INTERPOLATION_OFFSET* = 0x8E5C
  REG_17_ATI* = 0x8932
  WAIT_FAILED_APPLE* = 0x911D
  TEXTURE_BINDING_3D* = 0x806A
  cTEXTURE_VIEW* = 0x82B5
  DOT3_RGBA_ARB* = 0x86AF
  MAX_VARYING_FLOATS_ARB* = 0x8B4B
  UNIFORM_IS_ROW_MAJOR* = 0x8A3E
  FRAGMENT_SHADER_BIT* = 0x00000002
  MATRIX_INDEX_ARRAY_ARB* = 0x8844
  PIXEL_PACK_BUFFER_BINDING_EXT* = 0x88ED
  MATRIX_PALETTE_OES* = 0x8840
  INTENSITY_SNORM* = 0x9013
  COLOR_BUFFER_BIT0_QCOM* = 0x00000001
  cBITMAP* = 0x1A00
  CURRENT_MATRIX_NV* = 0x8641
  QUERY_BUFFER_AMD* = 0x9192
  EDGE_FLAG_ARRAY_BUFFER_BINDING* = 0x889B
  c4PASS_3_EXT* = 0x80A7
  TEXTURE_4DSIZE_SGIS* = 0x8136
  PATH_COORD_COUNT_NV* = 0x909E
  SLUMINANCE* = 0x8C46
  POINT_SMOOTH_HINT* = 0x0C51
  ADJACENT_PAIRS_NV* = 0x90AE
  BUFFER_BINDING* = 0x9302
  ARRAY_OBJECT_BUFFER_ATI* = 0x8766
  PATH_INITIAL_DASH_CAP_NV* = 0x907C
  RGBA4* = 0x8056
  PACK_LSB_FIRST* = 0x0D01
  IMAGE_BINDING_NAME_EXT* = 0x8F3A
  UNSIGNED_INT_SAMPLER_2D_EXT* = 0x8DD2
  RGBA12_EXT* = 0x805A
  COMBINER0_NV* = 0x8550
  COLOR_BUFFER_BIT4_QCOM* = 0x00000010
  TIME_ELAPSED* = 0x88BF
  TRANSFORM_FEEDBACK_BUFFER_START* = 0x8C84
  COMPRESSED_RGBA_ASTC_5x5_KHR* = 0x93B2
  MAX_SPARSE_3D_TEXTURE_SIZE_AMD* = 0x9199
  RENDERBUFFER_HEIGHT_EXT* = 0x8D43
  QUARTER_BIT_ATI* = 0x00000010
  TEXTURE_COMPRESSION_HINT_ARB* = 0x84EF
  DRAW_BUFFER13* = 0x8832
  CURRENT_MATRIX_STACK_DEPTH_ARB* = 0x8640
  DEPENDENT_HILO_TEXTURE_2D_NV* = 0x8858
  DST_NV* = 0x9287
  DEBUG_OBJECT_MESA* = 0x8759
  NUM_INSTRUCTIONS_TOTAL_ATI* = 0x8972
  FLAT* = 0x1D00
  EVAL_VERTEX_ATTRIB8_NV* = 0x86CE
  VERTEX_PROGRAM_CALLBACK_FUNC_MESA* = 0x8BB6
  TEXTURE_COORD_ARRAY_EXT* = 0x8078
  LOCATION_INDEX* = 0x930F
  SLIM10U_SGIX* = 0x831E
  PHONG_WIN* = 0x80EA
  EVAL_VERTEX_ATTRIB1_NV* = 0x86C7
  SMOOTH_LINE_WIDTH_RANGE* = 0x0B22
  SAMPLER_RENDERBUFFER_NV* = 0x8E56
  UNPACK_LSB_FIRST* = 0x0CF1
  SELECTION_BUFFER_POINTER* = 0x0DF3
  PIXEL_SUBSAMPLE_4444_SGIX* = 0x85A2
  COMPRESSED_R11_EAC* = 0x9270
  MAX_CLIP_PLANES* = 0x0D32
  POST_CONVOLUTION_GREEN_BIAS* = 0x8021
  COLOR_EXT* = 0x1800
  VENDOR* = 0x1F00
  MAP1_VERTEX_ATTRIB8_4_NV* = 0x8668
  TEXTURE_ALPHA_TYPE* = 0x8C13
  CURRENT_VERTEX_ATTRIB_ARB* = 0x8626
  COLOR_BUFFER_BIT2_QCOM* = 0x00000004
  VERTEX_ATTRIB_ARRAY15_NV* = 0x865F
  OFFSET_PROJECTIVE_TEXTURE_2D_NV* = 0x8850
  DRAW_BUFFER5_ARB* = 0x882A
  SAMPLES_PASSED_ARB* = 0x8914
  cPRIMITIVE_RESTART_NV* = 0x8558
  FRAGMENT_LIGHT3_SGIX* = 0x840F
  COLOR_INDEX16_EXT* = 0x80E7
  RGBA8_OES* = 0x8058
  PACK_CMYK_HINT_EXT* = 0x800E
  FRAMEBUFFER_ATTACHMENT_BLUE_SIZE* = 0x8214
  MODELVIEW0_EXT* = 0x1700
  RETAINED_APPLE* = 0x8A1B
  DRAW_PIXELS_APPLE* = 0x8A0A
  POINT_BIT* = 0x00000002
  PIXEL_MAP_B_TO_B_SIZE* = 0x0CB8
  RELATIVE_SMALL_CCW_ARC_TO_NV* = 0x13
  VERTEX_ATTRIB_ARRAY_STRIDE_ARB* = 0x8624
  DOT_PRODUCT_AFFINE_DEPTH_REPLACE_NV* = 0x885D
  CON_2_ATI* = 0x8943
  SAMPLER_2D_ARRAY* = 0x8DC1
  LINE_STIPPLE_PATTERN* = 0x0B25
  IMPLEMENTATION_COLOR_READ_FORMAT* = 0x8B9B
  TRANSPOSE_AFFINE_2D_NV* = 0x9096
  COLOR_ATTACHMENT7* = 0x8CE7
  COLOR_ATTACHMENT14* = 0x8CEE
  SHADER* = 0x82E1
  SKIP_MISSING_GLYPH_NV* = 0x90A9
  VERTEX_ARRAY_TYPE* = 0x807B
  OP_POWER_EXT* = 0x8793
  MAX_BINDABLE_UNIFORM_SIZE_EXT* = 0x8DED
  SRGB8* = 0x8C41
  INTERNALFORMAT_ALPHA_SIZE* = 0x8274
  IMAGE_2D_MULTISAMPLE* = 0x9055
  VIDEO_CAPTURE_FRAME_HEIGHT_NV* = 0x9039
  NEVER* = 0x0200
  MAP2_TEXTURE_COORD_2* = 0x0DB4
  PROGRAM_RESULT_COMPONENTS_NV* = 0x8907
  SHADER_STORAGE_BARRIER_BIT* = 0x00002000
  SLIM8U_SGIX* = 0x831D
  DRAW_BUFFER7_ATI* = 0x882C
  CLAMP_TO_EDGE* = 0x812F
  LUMINANCE32I_EXT* = 0x8D86
  NORMAL_ARRAY_POINTER* = 0x808F
  ALPHA_TEST_REF_QCOM* = 0x0BC2
  MATRIX7_NV* = 0x8637
  REFERENCED_BY_FRAGMENT_SHADER* = 0x930A
  COMPRESSED_RGBA_PVRTC_4BPPV1_IMG* = 0x8C02
  DEBUG_TYPE_MARKER* = 0x8268
  DEBUG_OUTPUT_SYNCHRONOUS_KHR* = 0x8242
  CON_26_ATI* = 0x895B
  COMBINER7_NV* = 0x8557
  MAP2_TANGENT_EXT* = 0x8445
  COMPRESSED_RGBA_ASTC_10x6_KHR* = 0x93B9
  RG8* = 0x822B
  INT_SAMPLER_1D_ARRAY_EXT* = 0x8DCE
  POINT_SPRITE_R_MODE_NV* = 0x8863
  ATOMIC_COUNTER_BUFFER_BINDING* = 0x92C1
  INTENSITY16F_ARB* = 0x881D
  DEFORMATIONS_MASK_SGIX* = 0x8196
  PATH_TERMINAL_END_CAP_NV* = 0x9078
  cVERTEX_BINDING_DIVISOR* = 0x82D6
  WIDE_LINE_HINT_PGI* = 0x1A222
  LIGHTING* = 0x0B50
  CURRENT_BIT* = 0x00000001
  LOSE_CONTEXT_ON_RESET_ARB* = 0x8252
  COLOR_ATTACHMENT15* = 0x8CEF
  REGISTER_COMBINERS_NV* = 0x8522
  UNSIGNED_INT64_VEC2_NV* = 0x8FF5
  TEXTURE_CLIPMAP_DEPTH_SGIX* = 0x8176
  HISTOGRAM_WIDTH* = 0x8026
  RENDERBUFFER_ALPHA_SIZE* = 0x8D53
  POST_CONVOLUTION_BLUE_BIAS_EXT* = 0x8022
  SCALED_RESOLVE_FASTEST_EXT* = 0x90BA
  DRAW_BUFFER15* = 0x8834
  LUMINANCE4_ALPHA4* = 0x8043
  SWIZZLE_STRQ_DQ_ATI* = 0x897B
  OP_MADD_EXT* = 0x8788
  MAX_ATTRIB_STACK_DEPTH* = 0x0D35
  DEBUG_GROUP_STACK_DEPTH_KHR* = 0x826D
  ACTIVE_VARYINGS_NV* = 0x8C81
  DEBUG_SEVERITY_HIGH* = 0x9146
  SRGB8_EXT* = 0x8C41
  STENCIL_WRITEMASK* = 0x0B98
  REG_14_ATI* = 0x892F
  PROGRAM_BINARY_ANGLE* = 0x93A6
  RENDERBUFFER_DEPTH_SIZE_EXT* = 0x8D54
  ALPHA_BIAS* = 0x0D1D
  STATIC_ATI* = 0x8760
  MATRIX_INDEX_ARRAY_BUFFER_BINDING_OES* = 0x8B9E
  SOFTLIGHT_NV* = 0x929C
  INDEX_ARRAY_COUNT_EXT* = 0x8087
  RENDERBUFFER_BLUE_SIZE_EXT* = 0x8D52
  SHARED_TEXTURE_PALETTE_EXT* = 0x81FB
  VERTEX_SHADER_OPTIMIZED_EXT* = 0x87D4
  MAX_SAMPLE_MASK_WORDS_NV* = 0x8E59
  MAX_MATRIX_PALETTE_STACK_DEPTH_ARB* = 0x8841
  MATRIX30_ARB* = 0x88DE
  NORMAL_ARRAY_POINTER_EXT* = 0x808F
  PIXEL_MAP_A_TO_A* = 0x0C79
  MATRIX18_ARB* = 0x88D2
  UNPACK_SKIP_ROWS_EXT* = 0x0CF3
  INVARIANT_DATATYPE_EXT* = 0x87EB
  INT_IMAGE_1D_EXT* = 0x9057
  OUTPUT_TEXTURE_COORD24_EXT* = 0x87B5
  MAP_WRITE_BIT_EXT* = 0x0002
  MODELVIEW28_ARB* = 0x873C
  MAX_VARYING_COMPONENTS_EXT* = 0x8B4B
  OUTPUT_TEXTURE_COORD4_EXT* = 0x87A1
  UNSIGNED_INT_VEC2_EXT* = 0x8DC6
  READ_ONLY* = 0x88B8
  SECONDARY_COLOR_ARRAY_LIST_STRIDE_IBM* = 103087
  UNSIGNED_INT64_NV* = 0x140F
  REPLACEMENT_CODE_ARRAY_STRIDE_SUN* = 0x85C2
  DEPTH_BUFFER_BIT0_QCOM* = 0x00000100
  VERTEX_ATTRIB_MAP2_SIZE_APPLE* = 0x8A06
  POST_CONVOLUTION_ALPHA_SCALE* = 0x801F
  TEXTURE_COLOR_SAMPLES_NV* = 0x9046
  DEBUG_SEVERITY_HIGH_ARB* = 0x9146
  MAP_WRITE_BIT* = 0x0002
  SRC1_RGB* = 0x8581
  LIGHT0* = 0x4000
  READ_PIXELS_FORMAT* = 0x828D
  COMBINE_RGB_EXT* = 0x8571
  MATRIX2_NV* = 0x8632
  INT16_VEC4_NV* = 0x8FE7
  INT_SAMPLER_CUBE* = 0x8DCC
  LUMINANCE_ALPHA8I_EXT* = 0x8D93
  TRIANGLE_STRIP_ADJACENCY* = 0x000D
  MAX_TEXTURE_BUFFER_SIZE_EXT* = 0x8C2B
  COLOR_TABLE_BIAS* = 0x80D7
  MAX_GEOMETRY_INPUT_COMPONENTS* = 0x9123
  TEXTURE_RANGE_POINTER_APPLE* = 0x85B8
  PIXEL_SUBSAMPLE_2424_SGIX* = 0x85A3
  RESAMPLE_REPLICATE_OML* = 0x8986
  ALL_STATIC_DATA_IBM* = 103060
  DEBUG_CATEGORY_PERFORMANCE_AMD* = 0x914D
  ALPHA_TEST_QCOM* = 0x0BC0
  PREVIOUS_TEXTURE_INPUT_NV* = 0x86E4
  SIGNED_RGBA_NV* = 0x86FB
  GLOBAL_ALPHA_SUN* = 0x81D9
  RGB_FLOAT16_APPLE* = 0x881B
  PROGRAM_NATIVE_ALU_INSTRUCTIONS_ARB* = 0x8808
  UTF8_NV* = 0x909A
  ALLOW_DRAW_OBJ_HINT_PGI* = 0x1A20E
  INT_IMAGE_3D* = 0x9059
  PACK_ROW_LENGTH* = 0x0D02
  MAX_TEXTURE_LOD_BIAS_EXT* = 0x84FD
  SCALED_RESOLVE_NICEST_EXT* = 0x90BB
  c422_EXT* = 0x80CC
  SAMPLER_1D_ARRAY_SHADOW_EXT* = 0x8DC3
  PIXEL_TRANSFORM_2D_STACK_DEPTH_EXT* = 0x8336
  COMPRESSED_RED* = 0x8225
  MAX_RATIONAL_EVAL_ORDER_NV* = 0x86D7
  MAX_COMBINED_IMAGE_UNIFORMS* = 0x90CF
  GLYPH_HORIZONTAL_BEARING_ADVANCE_BIT_NV* = 0x10
  TEXTURE_BINDING_1D_ARRAY* = 0x8C1C
  FRAMEBUFFER_COMPLETE* = 0x8CD5
  RG8I* = 0x8237
  COLOR_ATTACHMENT2_NV* = 0x8CE2
  INT64_VEC4_NV* = 0x8FEB
  OP_SET_GE_EXT* = 0x878C
  READ_WRITE* = 0x88BA
  OPERAND1_RGB_EXT* = 0x8591
  SHADER_STORAGE_BLOCK* = 0x92E6
  TEXTURE_UPDATE_BARRIER_BIT* = 0x00000100
  MAX_FRAGMENT_ATOMIC_COUNTERS* = 0x92D6
  SHADER_INCLUDE_ARB* = 0x8DAE
  UNSIGNED_SHORT_1_5_5_5_REV* = 0x8366
  PROGRAM_PIPELINE* = 0x82E4
  MAP1_TEXTURE_COORD_2* = 0x0D94
  FOG_COORDINATE_ARRAY_STRIDE_EXT* = 0x8455
  WEIGHT_ARRAY_SIZE_OES* = 0x86AB
  R11F_G11F_B10F* = 0x8C3A
  WRITE_PIXEL_DATA_RANGE_NV* = 0x8878
  UNSIGNED_SHORT_8_8_REV_APPLE* = 0x85BB
  CND_ATI* = 0x896A
  IMAGE_2D_MULTISAMPLE_ARRAY* = 0x9056
  MAX_TEXTURE_IMAGE_UNITS_NV* = 0x8872
  COMPRESSED_SIGNED_RG11_EAC_OES* = 0x9273
  DOT_PRODUCT_TEXTURE_3D_NV* = 0x86EF
  IMAGE_TRANSLATE_Y_HP* = 0x8158
  NORMAL_ARRAY_TYPE_EXT* = 0x807E
  PIXEL_COUNT_NV* = 0x8866
  INT_IMAGE_3D_EXT* = 0x9059
  TEXTURE_TYPE_QCOM* = 0x8BD7
  COMBINE_ALPHA_EXT* = 0x8572
  POINT_TOKEN* = 0x0701
  QUAD_ALPHA4_SGIS* = 0x811E
  SIGNED_HILO8_NV* = 0x885F
  MULTISAMPLE_ARB* = 0x809D
  TEXTURE25* = 0x84D9
  CURRENT_VERTEX_WEIGHT_EXT* = 0x850B
  BLEND_DST_ALPHA_OES* = 0x80CA
  UNSIGNED_SHORT_8_8_REV_MESA* = 0x85BB
  CLAMP_TO_EDGE_SGIS* = 0x812F
  PATH_STENCIL_REF_NV* = 0x90B8
  DEBUG_OUTPUT* = 0x92E0
  OBJECT_TYPE_APPLE* = 0x9112
  TEXTURE_COMPARE_MODE_ARB* = 0x884C
  CONSTANT* = 0x8576
  RGB5_A1_OES* = 0x8057
  INT16_VEC2_NV* = 0x8FE5
  CONVOLUTION_BORDER_MODE_EXT* = 0x8013
  CONTEXT_FLAGS* = 0x821E
  MAX_PROGRAM_SUBROUTINE_NUM_NV* = 0x8F45
  SPRITE_SGIX* = 0x8148
  CURRENT_QUERY* = 0x8865
  cSTENCIL_OP_VALUE_AMD* = 0x874C
  UNIFORM* = 0x92E1
  TEXTURE_BINDING_RECTANGLE* = 0x84F6
  TRIANGLES_ADJACENCY_EXT* = 0x000C
  cPROVOKING_VERTEX_EXT* = 0x8E4F
  INT64_VEC2_NV* = 0x8FE9
  INVERSE_NV* = 0x862B
  CON_29_ATI* = 0x895E
  TRANSFORM_FEEDBACK_BUFFER_ACTIVE_NV* = 0x8E24
  FRONT_AND_BACK* = 0x0408
  MAX_LABEL_LENGTH_KHR* = 0x82E8
  TRANSFORM_FEEDBACK_BUFFER_START_NV* = 0x8C84
  EQUAL* = 0x0202
  RGB10_EXT* = 0x8052
  MAX_GEOMETRY_TEXTURE_IMAGE_UNITS_ARB* = 0x8C29
  OP_ADD_EXT* = 0x8787
  REPLACEMENT_CODE_ARRAY_POINTER_SUN* = 0x85C3
  NORMAL_ARRAY_LIST_IBM* = 103071
  RENDERBUFFER_GREEN_SIZE* = 0x8D51
  TESS_CONTROL_PROGRAM_PARAMETER_BUFFER_NV* = 0x8C74
  cCURRENT_PALETTE_MATRIX_ARB* = 0x8843
  DEBUG_TYPE_ERROR* = 0x824C
  UNIFORM_BUFFER* = 0x8A11
  NEAREST_CLIPMAP_LINEAR_SGIX* = 0x844E
  LAST_VERTEX_CONVENTION* = 0x8E4E
  COMPRESSED_RGBA_ASTC_12x10_KHR* = 0x93BC
  FENCE_STATUS_NV* = 0x84F3
  POST_CONVOLUTION_BLUE_BIAS* = 0x8022
  BLEND_OVERLAP_NV* = 0x9281
  COMBINE_RGB_ARB* = 0x8571
  TESS_GEN_MODE* = 0x8E76
  TEXTURE_ENV* = 0x2300
  VERTEX_ATTRIB_ARRAY11_NV* = 0x865B
  SHININESS* = 0x1601
  DYNAMIC_STORAGE_BIT* = 0x0100
  MODELVIEW30_ARB* = 0x873E
  WRAP_BORDER_SUN* = 0x81D4
  SKIP_COMPONENTS1_NV* = -6
  DEPTH_CLAMP_NV* = 0x864F
  PROGRAM_BINARY_FORMATS* = 0x87FF
  CURRENT_RASTER_POSITION_VALID* = 0x0B08
  ATOMIC_COUNTER_BUFFER_REFERENCED_BY_TESS_CONTROL_SHADER* = 0x92C8
  T2F_C4F_N3F_V3F* = 0x2A2C
  R16F* = 0x822D
  SECONDARY_COLOR_ARRAY_LENGTH_NV* = 0x8F31
  SEPARATE_ATTRIBS_EXT* = 0x8C8D
  NEGATIVE_Z_EXT* = 0x87DB
  Z400_BINARY_AMD* = 0x8740
  DRAW_INDIRECT_UNIFIED_NV* = 0x8F40
  MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS_NV* = 0x8C8A
  UNSIGNED_INT_S8_S8_8_8_NV* = 0x86DA
  SRGB8_NV* = 0x8C41
  DEBUG_SEVERITY_MEDIUM_AMD* = 0x9147
  MAX_DRAW_BUFFERS_ATI* = 0x8824
  TEXTURE_COORD_ARRAY_POINTER_EXT* = 0x8092
  RESAMPLE_AVERAGE_OML* = 0x8988
  NO_ERROR* = 0
  RGB5* = 0x8050
  OP_CLAMP_EXT* = 0x878E
  PROGRAM_RESIDENT_NV* = 0x8647
  PROGRAM_ALU_INSTRUCTIONS_ARB* = 0x8805
  ELEMENT_ARRAY_UNIFIED_NV* = 0x8F1F
  SECONDARY_COLOR_ARRAY_LIST_IBM* = 103077
  INTENSITY12_EXT* = 0x804C
  STENCIL_BUFFER_BIT7_QCOM* = 0x00800000
  SAMPLER* = 0x82E6
  MAD_ATI* = 0x8968
  STENCIL_BACK_FAIL* = 0x8801
  LIGHT_MODEL_TWO_SIDE* = 0x0B52
  UNPACK_SKIP_PIXELS* = 0x0CF4
  cPIXEL_TEX_GEN_SGIX* = 0x8139
  FRACTIONAL_ODD* = 0x8E7B
  LOW_INT* = 0x8DF3
  MODELVIEW* = 0x1700
  POST_CONVOLUTION_RED_SCALE_EXT* = 0x801C
  DRAW_BUFFER11_EXT* = 0x8830
  ACTIVE_UNIFORM_BLOCK_MAX_NAME_LENGTH* = 0x8A35
  CONVOLUTION_BORDER_MODE* = 0x8013
  COMPRESSED_ALPHA_ARB* = 0x84E9
  DEPTH_ATTACHMENT* = 0x8D00
  ALPHA8_SNORM* = 0x9014
  DOUBLE_MAT4x3_EXT* = 0x8F4E
  INTERNALFORMAT_STENCIL_SIZE* = 0x8276
  BOOL_VEC2_ARB* = 0x8B57
  FASTEST* = 0x1101
  MAX_FRAGMENT_INPUT_COMPONENTS* = 0x9125
  STENCIL_BACK_FUNC_ATI* = 0x8800
  POLYGON* = 0x0009
  SAMPLER_1D_ARRAY_EXT* = 0x8DC0
  OUTPUT_COLOR1_EXT* = 0x879C
  IMAGE_2D_RECT* = 0x904F
  RECT_NV* = 0xF6
  OUTPUT_TEXTURE_COORD21_EXT* = 0x87B2
  NOR* = 0x1508
  FOG_COORD_ARRAY* = 0x8457
  TEXTURE_CUBE_MAP_POSITIVE_Y_OES* = 0x8517
  TANGENT_ARRAY_POINTER_EXT* = 0x8442
  DST_OUT_NV* = 0x928D
  RENDERBUFFER_BINDING_OES* = 0x8CA7
  COMPRESSED_SRGB8_ALPHA8_ASTC_6x5_KHR* = 0x93D3
  TEXTURE_GEN_S* = 0x0C60
  SLIM12S_SGIX* = 0x831F
  VERTEX_ARRAY_BINDING* = 0x85B5
  TRACE_PRIMITIVES_BIT_MESA* = 0x0002
  MAX_DEBUG_MESSAGE_LENGTH* = 0x9143
  EVAL_VERTEX_ATTRIB4_NV* = 0x86CA
  ACTIVE_SUBROUTINE_UNIFORMS* = 0x8DE6
  ACCUM_ADJACENT_PAIRS_NV* = 0x90AD
  NEGATIVE_ONE_EXT* = 0x87DF
  UNPACK_RESAMPLE_SGIX* = 0x842D
  ACTIVE_SUBROUTINE_MAX_LENGTH* = 0x8E48
  TEXTURE_CUBE_MAP_NEGATIVE_Y_EXT* = 0x8518
  DEBUG_CATEGORY_API_ERROR_AMD* = 0x9149
  INTERNALFORMAT_BLUE_SIZE* = 0x8273
  DRAW_BUFFER13_NV* = 0x8832
  DEBUG_SOURCE_THIRD_PARTY_ARB* = 0x8249
  R8_EXT* = 0x8229
  cGENERATE_MIPMAP* = 0x8191
  cSHORT* = 0x1402
  PACK_REVERSE_ROW_ORDER_ANGLE* = 0x93A4
  PATH_DASH_OFFSET_RESET_NV* = 0x90B4
  PACK_SKIP_VOLUMES_SGIS* = 0x8130
  TEXTURE_RED_TYPE* = 0x8C10
  MAX_COLOR_ATTACHMENTS_EXT* = 0x8CDF
  MAP2_VERTEX_ATTRIB5_4_NV* = 0x8675
  CONSTANT_ALPHA* = 0x8003
  COLOR_INDEX8_EXT* = 0x80E5
  DOUBLE_MAT3_EXT* = 0x8F47
  ATOMIC_COUNTER_BUFFER_INDEX* = 0x9301
  LINES_ADJACENCY_EXT* = 0x000A
  RENDERBUFFER_SAMPLES_IMG* = 0x9133
  COLOR_TABLE_FORMAT* = 0x80D8
  VERTEX_ATTRIB_ARRAY_TYPE* = 0x8625
  QUERY_OBJECT_EXT* = 0x9153
  STREAM_READ_ARB* = 0x88E1
  MIRROR_CLAMP_TO_EDGE_ATI* = 0x8743
  FRAGMENT_SUBROUTINE_UNIFORM* = 0x92F2
  cUNIFORM_BUFFER_EXT* = 0x8DEE
  SOURCE2_RGB* = 0x8582
  PROGRAM_NATIVE_ATTRIBS_ARB* = 0x88AE
  LUMINANCE12_ALPHA12* = 0x8047
  INT_SAMPLER_1D_EXT* = 0x8DC9
  FRAMEBUFFER_ATTACHMENT_TEXTURE_SAMPLES_EXT* = 0x8D6C
  DEPTH_RENDERABLE* = 0x8287
  INTERNALFORMAT_BLUE_TYPE* = 0x827A
  SLUMINANCE8_ALPHA8_EXT* = 0x8C45
  TEXTURE_BINDING_CUBE_MAP_ARRAY_ARB* = 0x900A
  COLOR_MATRIX* = 0x80B1
  RGB8_SNORM* = 0x8F96
  COLOR_ARRAY_SIZE* = 0x8081
  DRAW_BUFFER4_NV* = 0x8829
  VIDEO_BUFFER_INTERNAL_FORMAT_NV* = 0x902D
  PRESENT_TIME_NV* = 0x8E2A
  COPY_WRITE_BUFFER* = 0x8F37
  UNPACK_SKIP_PIXELS_EXT* = 0x0CF4
  PRIMITIVES_GENERATED_NV* = 0x8C87
  INT_SAMPLER_BUFFER* = 0x8DD0
  GLYPH_HORIZONTAL_BEARING_X_BIT_NV* = 0x04
  FOG_COORDINATE_EXT* = 0x8451
  VERTEX_ARRAY_ADDRESS_NV* = 0x8F21
  RENDERBUFFER_RED_SIZE_OES* = 0x8D50
  BGR_INTEGER_EXT* = 0x8D9A
  UNSIGNED_BYTE_3_3_2* = 0x8032
  VBO_FREE_MEMORY_ATI* = 0x87FB
  PATH_COMPUTED_LENGTH_NV* = 0x90A0
  COLOR_MATRIX_STACK_DEPTH_SGI* = 0x80B2
  STACK_OVERFLOW* = 0x0503
  MODELVIEW1_MATRIX_EXT* = 0x8506
  CURRENT_BINORMAL_EXT* = 0x843C
  OP_MULTIPLY_MATRIX_EXT* = 0x8798
  CLIENT_ATTRIB_STACK_DEPTH* = 0x0BB1
  VERTEX_PROGRAM_TWO_SIDE_NV* = 0x8643
  HISTOGRAM_WIDTH_EXT* = 0x8026
  OBJECT_INFO_LOG_LENGTH_ARB* = 0x8B84
  SAMPLER_2D_ARRAY_SHADOW* = 0x8DC4
  UNSIGNED_INT_IMAGE_1D* = 0x9062
  MAX_IMAGE_UNITS* = 0x8F38
  TEXTURE31_ARB* = 0x84DF
  CUBIC_HP* = 0x815F
  OFFSET_HILO_PROJECTIVE_TEXTURE_2D_NV* = 0x8856
  ARRAY_STRIDE* = 0x92FE
  DEPTH_PASS_INSTRUMENT_SGIX* = 0x8310
  COMMAND_BARRIER_BIT* = 0x00000040
  STATIC_DRAW_ARB* = 0x88E4
  RGB16F* = 0x881B
  INDEX_MATERIAL_PARAMETER_EXT* = 0x81B9
  UNPACK_SKIP_VOLUMES_SGIS* = 0x8132
  TEXTURE_1D* = 0x0DE0
  VERTEX_PROGRAM_NV* = 0x8620
  COLOR_ATTACHMENT0_NV* = 0x8CE0
  READ_PIXEL_DATA_RANGE_LENGTH_NV* = 0x887B
  FLOAT_32_UNSIGNED_INT_24_8_REV* = 0x8DAD
  LINE_RESET_TOKEN* = 0x0707
  WEIGHT_ARRAY_ARB* = 0x86AD
  TEXTURE17* = 0x84D1
  DEPTH_COMPONENT32_ARB* = 0x81A7
  REFERENCED_BY_TESS_CONTROL_SHADER* = 0x9307
  INVERT* = 0x150A
  FOG_COORDINATE_ARRAY_STRIDE* = 0x8455
  COMPRESSED_SIGNED_RG_RGTC2* = 0x8DBE
  UNSIGNED_SHORT_8_8_MESA* = 0x85BA
  ELEMENT_ARRAY_TYPE_ATI* = 0x8769
  CLAMP_VERTEX_COLOR_ARB* = 0x891A
  POINT_SIZE_ARRAY_STRIDE_OES* = 0x898B
  RGB8* = 0x8051
  MATRIX1_ARB* = 0x88C1
  TEXTURE_POST_SPECULAR_HP* = 0x8168
  TEXTURE_WRAP_Q_SGIS* = 0x8137
  SAMPLER_2D_MULTISAMPLE_ARRAY* = 0x910B
  INVALID_FRAMEBUFFER_OPERATION_OES* = 0x0506
  VERTEX_ID_SWIZZLE_AMD* = 0x91A5
  USE_MISSING_GLYPH_NV* = 0x90AA
  LUMINANCE8_EXT* = 0x8040
  INT_VEC2* = 0x8B53
  TEXTURE9* = 0x84C9
  RGB32UI_EXT* = 0x8D71
  FENCE_CONDITION_NV* = 0x84F4
  QUADS_FOLLOW_PROVOKING_VERTEX_CONVENTION_EXT* = 0x8E4C
  HSL_SATURATION_NV* = 0x92AE
  CMYKA_EXT* = 0x800D
  TRANSFORM_FEEDBACK_BUFFER_NV* = 0x8C8E
  BUFFER_MAP_POINTER_OES* = 0x88BD
  STORAGE_CLIENT_APPLE* = 0x85B4
  VERTEX_ARRAY_BUFFER_BINDING_ARB* = 0x8896
  TEXTURE_INTERNAL_FORMAT* = 0x1003
  TRANSFORM_FEEDBACK_BUFFER_PAUSED* = 0x8E23
  UNSIGNED_INT_VEC3* = 0x8DC7
  TRACE_MASK_MESA* = 0x8755
  MAP_READ_BIT_EXT* = 0x0001
  READ_FRAMEBUFFER_EXT* = 0x8CA8
  HISTOGRAM_GREEN_SIZE* = 0x8029
  COLOR_TABLE_INTENSITY_SIZE_SGI* = 0x80DF
  SMALL_CCW_ARC_TO_NV* = 0x12
  RELATIVE_LARGE_CW_ARC_TO_NV* = 0x19
  POST_COLOR_MATRIX_BLUE_BIAS_SGI* = 0x80BA
  SCISSOR_BIT* = 0x00080000
  DRAW_BUFFER0_ATI* = 0x8825
  GEOMETRY_SHADER_BIT* = 0x00000004
  CLIP_FAR_HINT_PGI* = 0x1A221
  TEXTURE_COMPARE_FUNC_EXT* = 0x884D
  IS_ROW_MAJOR* = 0x9300
  MAP1_VERTEX_4* = 0x0D98
  OUTPUT_TEXTURE_COORD8_EXT* = 0x87A5
  MAX_VERTEX_IMAGE_UNIFORMS* = 0x90CA
  FRAMEBUFFER_ATTACHMENT_COMPONENT_TYPE* = 0x8211
  SOURCE1_ALPHA_ARB* = 0x8589
  VIRTUAL_PAGE_SIZE_X_AMD* = 0x9195
  CULL_FRAGMENT_NV* = 0x86E7
  MAX_ATOMIC_COUNTER_BUFFER_BINDINGS* = 0x92DC
  QUERY_COUNTER_BITS_EXT* = 0x8864
  RGB565* = 0x8D62
  OFFSET_TEXTURE_RECTANGLE_NV* = 0x864C
  CONVOLUTION_FORMAT_EXT* = 0x8017
  EYE_POINT_SGIS* = 0x81F4
  ALPHA32F_ARB* = 0x8816
  TEXTURE_DEPTH_SIZE* = 0x884A
  COMPRESSED_SRGB8_ALPHA8_ASTC_5x4_KHR* = 0x93D1
  PRIMARY_COLOR_NV* = 0x852C
  BLEND_DST_ALPHA_EXT* = 0x80CA
  NORMALIZE* = 0x0BA1
  POST_CONVOLUTION_GREEN_BIAS_EXT* = 0x8021
  HI_SCALE_NV* = 0x870E
  TESS_EVALUATION_PROGRAM_NV* = 0x891F
  MAX_DUAL_SOURCE_DRAW_BUFFERS* = 0x88FC
  SWIZZLE_STRQ_ATI* = 0x897A
  READ_FRAMEBUFFER_NV* = 0x8CA8
  MATRIX_INDEX_ARRAY_STRIDE_OES* = 0x8848
  MIN_SPARSE_LEVEL_ARB* = 0x919B
  RG32UI* = 0x823C
  SAMPLER_2D_ARRAY_EXT* = 0x8DC1
  TEXTURE22_ARB* = 0x84D6
  MAX_COMBINED_GEOMETRY_UNIFORM_COMPONENTS* = 0x8A32
  CULL_VERTEX_EYE_POSITION_EXT* = 0x81AB
  TEXTURE_BUFFER* = 0x8C2A
  MAX_CUBE_MAP_TEXTURE_SIZE_ARB* = 0x851C
  NORMAL_ARRAY_COUNT_EXT* = 0x8080
  FRAMEBUFFER_INCOMPLETE_MULTISAMPLE_NV* = 0x8D56
  ELEMENT_ARRAY_BARRIER_BIT_EXT* = 0x00000002
  VERTEX_ARRAY_COUNT_EXT* = 0x807D
  PROGRAM_ERROR_STRING_NV* = 0x8874
  INVALID_FRAMEBUFFER_OPERATION* = 0x0506
  RGB9_E5* = 0x8C3D
  GREEN_BITS* = 0x0D53
  CLIP_DISTANCE0* = 0x3000
  COMBINER_SUM_OUTPUT_NV* = 0x854C
  COLOR_ARRAY* = 0x8076
  RGBA8_SNORM* = 0x8F97
  PROGRAM_BINDING_ARB* = 0x8677
  c4PASS_0_EXT* = 0x80A4
  STATIC_DRAW* = 0x88E4
  TEXTURE_COMPRESSED_BLOCK_WIDTH* = 0x82B1
  TEXTURE_STORAGE_SPARSE_BIT_AMD* = 0x00000001
  MEDIUM_INT* = 0x8DF4
  TEXTURE13_ARB* = 0x84CD
  LUMINANCE_ALPHA16F_ARB* = 0x881F
  CONTEXT_CORE_PROFILE_BIT* = 0x00000001
  LOCATION_COMPONENT* = 0x934A
  TEXTURE_RECTANGLE* = 0x84F5
  SAMPLER_2D_ARB* = 0x8B5E
  FLOAT_RG32_NV* = 0x8887
  SKIP_DECODE_EXT* = 0x8A4A
  LIGHT6* = 0x4006
  ATC_RGBA_INTERPOLATED_ALPHA_AMD* = 0x87EE
  NOOP* = 0x1505
  DEPTH_BUFFER_BIT* = 0x00000100
  FRAMEBUFFER_BINDING_ANGLE* = 0x8CA6
  DEBUG_TYPE_POP_GROUP_KHR* = 0x826A
  SAMPLER_2D_RECT_SHADOW* = 0x8B64
  CONSERVE_MEMORY_HINT_PGI* = 0x1A1FD
  QUERY_BY_REGION_NO_WAIT* = 0x8E16
  UNSIGNED_INT_SAMPLER_CUBE* = 0x8DD4
  LUMINANCE4_EXT* = 0x803F
  COLOR_ARRAY_STRIDE* = 0x8083
  SAMPLER_2D_ARRAY_SHADOW_NV* = 0x8DC4
  REFERENCED_BY_GEOMETRY_SHADER* = 0x9309
  SIGNED_RGB_UNSIGNED_ALPHA_NV* = 0x870C
  OBJECT_PLANE* = 0x2501
  Q* = 0x2003
  MAX_SPOT_EXPONENT_NV* = 0x8505
  VERTEX_ATTRIB_ARRAY_LONG* = 0x874E
  COLOR_ATTACHMENT3* = 0x8CE3
  TEXTURE_BINDING_RENDERBUFFER_NV* = 0x8E53
  EXCLUSION_NV* = 0x92A0
  EDGE_FLAG_ARRAY_ADDRESS_NV* = 0x8F26
  PRIMARY_COLOR_ARB* = 0x8577
  LUMINANCE_ALPHA_FLOAT16_ATI* = 0x881F
  TRACE_TEXTURES_BIT_MESA* = 0x0008
  FRAMEBUFFER_OES* = 0x8D40
  PIXEL_MAG_FILTER_EXT* = 0x8331
  IMAGE_BINDING_LAYERED_EXT* = 0x8F3C
  PATH_MITER_LIMIT_NV* = 0x907A
  PROJECTION_MATRIX* = 0x0BA7
  TEXTURE23_ARB* = 0x84D7
  VERTEX_ATTRIB_MAP2_COEFF_APPLE* = 0x8A07
  RGB32F_ARB* = 0x8815
  RED_SCALE* = 0x0D14
  GEOMETRY_INPUT_TYPE_ARB* = 0x8DDB
  EVAL_VERTEX_ATTRIB13_NV* = 0x86D3
  INT64_NV* = 0x140E
  VIEW_CLASS_24_BITS* = 0x82C9
  FRAGMENT_LIGHT2_SGIX* = 0x840E
  LUMINANCE12_ALPHA12_EXT* = 0x8047
  MAP2_VERTEX_ATTRIB2_4_NV* = 0x8672
  POINT_SIZE_MIN_SGIS* = 0x8126
  DEBUG_TYPE_OTHER_ARB* = 0x8251
  MAP2_VERTEX_ATTRIB0_4_NV* = 0x8670
  DEBUG_PRINT_MESA* = 0x875A
  TEXTURE_PRIORITY* = 0x8066
  PIXEL_MAP_I_TO_G* = 0x0C73
  VERTEX_ATTRIB_ARRAY_DIVISOR* = 0x88FE
  TEXTURE_CUBE_MAP_ARB* = 0x8513
  LUMINANCE8_SNORM* = 0x9015
  CLIENT_MAPPED_BUFFER_BARRIER_BIT* = 0x00004000
  MAX_COMBINED_TESS_EVALUATION_UNIFORM_COMPONENTS* = 0x8E1F
  BUFFER_STORAGE_FLAGS* = 0x8220
  DEPTH_COMPONENT24_SGIX* = 0x81A6
  UNIFORM_OFFSET* = 0x8A3B
  TEXTURE_DT_SIZE_NV* = 0x871E
  POST_COLOR_MATRIX_ALPHA_SCALE_SGI* = 0x80B7
  DEPTH32F_STENCIL8_NV* = 0x8DAC
  cSTENCIL_FUNC* = 0x0B92
  NEAREST_MIPMAP_LINEAR* = 0x2702
  COMPRESSED_LUMINANCE_LATC1_EXT* = 0x8C70
  TEXTURE_BORDER* = 0x1005
  COLOR_ATTACHMENT14_NV* = 0x8CEE
  TEXTURE_STORAGE_HINT_APPLE* = 0x85BC
  cVERTEX_ARRAY_RANGE_NV* = 0x851D
  COLOR_ARRAY_SIZE_EXT* = 0x8081
  INTERNALFORMAT_SUPPORTED* = 0x826F
  MULTISAMPLE_BIT_ARB* = 0x20000000
  RGB* = 0x1907
  TRANSFORM_FEEDBACK_PAUSED* = 0x8E23
  ALPHA8* = 0x803C
  STENCIL_FAIL* = 0x0B94
  PACK_SKIP_IMAGES_EXT* = 0x806B
  FOG_COORDINATE_ARRAY_TYPE_EXT* = 0x8454
  RESCALE_NORMAL_EXT* = 0x803A
  LERP_ATI* = 0x8969
  MATRIX_INDEX_ARRAY_STRIDE_ARB* = 0x8848
  PROGRAM_LENGTH_NV* = 0x8627
  UNSIGNED_INT_SAMPLER_3D_EXT* = 0x8DD3
  COMPRESSED_SIGNED_RED_GREEN_RGTC2_EXT* = 0x8DBE
  UNSIGNED_INT_24_8_NV* = 0x84FA
  POINT_SIZE_MIN_ARB* = 0x8126
  COMP_BIT_ATI* = 0x00000002
  NORMAL_ARRAY_ADDRESS_NV* = 0x8F22
  TEXTURE9_ARB* = 0x84C9
  MAX_GEOMETRY_OUTPUT_COMPONENTS* = 0x9124
  DOUBLEBUFFER* = 0x0C32
  OFFSET_TEXTURE_2D_BIAS_NV* = 0x86E3
  cACTIVE_PROGRAM_EXT* = 0x8B8D
  PARTIAL_SUCCESS_NV* = 0x902E
  SUBTRACT* = 0x84E7
  DUAL_INTENSITY4_SGIS* = 0x8118
  FILL* = 0x1B02
  COMPRESSED_SRGB_ALPHA* = 0x8C49
  RENDERBUFFER_OES* = 0x8D41
  PIXEL_MAP_R_TO_R_SIZE* = 0x0CB6
  TEXTURE_LUMINANCE_TYPE_ARB* = 0x8C14
  TEXTURE_BUFFER_FORMAT_EXT* = 0x8C2E
  OUTPUT_TEXTURE_COORD13_EXT* = 0x87AA
  LINES_ADJACENCY_ARB* = 0x000A
  MAX_PROGRAM_SUBROUTINE_PARAMETERS_NV* = 0x8F44
  INTENSITY32UI_EXT* = 0x8D73
  PACK_IMAGE_HEIGHT* = 0x806C
  HI_BIAS_NV* = 0x8714
  DEBUG_TYPE_UNDEFINED_BEHAVIOR_ARB* = 0x824E
  cLINE_STIPPLE* = 0x0B24
  INDEX_LOGIC_OP* = 0x0BF1
  CON_18_ATI* = 0x8953
  QUERY_RESULT* = 0x8866
  FRAGMENT_PROGRAM_NV* = 0x8870
  MATRIX1_NV* = 0x8631
  FUNC_SUBTRACT_OES* = 0x800A
  PIXEL_MAP_I_TO_A_SIZE* = 0x0CB5
  UNSIGNED_SHORT_4_4_4_4_REV_EXT* = 0x8365
  OUTPUT_TEXTURE_COORD20_EXT* = 0x87B1
  VERTEX_ATTRIB_ARRAY_BARRIER_BIT_EXT* = 0x00000001
  TRIANGULAR_NV* = 0x90A5
  TEXTURE_COMPARE_MODE_EXT* = 0x884C
  SECONDARY_COLOR_ARRAY_SIZE_EXT* = 0x845A
  FRAMEBUFFER_ATTACHMENT_LAYERED_EXT* = 0x8DA7
  COMPRESSED_RGBA_S3TC_DXT5_ANGLE* = 0x83F3
  MAX_COMPUTE_VARIABLE_GROUP_SIZE_ARB* = 0x9345
  TEXTURE_COORD_ARRAY_BUFFER_BINDING_ARB* = 0x889A
  PROGRAM_FORMAT_ARB* = 0x8876
  QUAD_INTENSITY4_SGIS* = 0x8122
  REPLICATE_BORDER* = 0x8153
  PN_TRIANGLES_ATI* = 0x87F0
  DEPTH_TEXTURE_MODE* = 0x884B
  VARIABLE_C_NV* = 0x8525
  CLIP_PLANE0_IMG* = 0x3000
  FRONT_LEFT* = 0x0400
  MATRIX3_ARB* = 0x88C3
  BLEND_EQUATION_ALPHA_EXT* = 0x883D
  BGRA8_EXT* = 0x93A1
  INTERLACE_READ_INGR* = 0x8568
  TRANSFORM_FEEDBACK_BUFFER_ACTIVE* = 0x8E24
  MAP1_VERTEX_ATTRIB13_4_NV* = 0x866D
  PIXEL_TEX_GEN_Q_FLOOR_SGIX* = 0x8186
  UNSIGNED_INT_SAMPLER_2D_ARRAY* = 0x8DD7
  ALL_SHADER_BITS_EXT* = 0xFFFFFFFF
  ONE_MINUS_SRC1_ALPHA* = 0x88FB
  VERTEX_ARRAY_RANGE_LENGTH_APPLE* = 0x851E
  PROXY_COLOR_TABLE_SGI* = 0x80D3
  MAX_RENDERBUFFER_SIZE_OES* = 0x84E8
  VERTEX_ATTRIB_ARRAY_ENABLED* = 0x8622
  TEXTURE_BINDING_2D_MULTISAMPLE* = 0x9104
  STENCIL_BUFFER_BIT0_QCOM* = 0x00010000
  IMAGE_BINDING_FORMAT_EXT* = 0x906E
  RENDERBUFFER_SAMPLES_NV* = 0x8CAB
  ACCUM_GREEN_BITS* = 0x0D59
  ATOMIC_COUNTER_BUFFER_REFERENCED_BY_COMPUTE_SHADER* = 0x90ED
  FRAMEBUFFER_UNDEFINED* = 0x8219
  OFFSET_TEXTURE_2D_NV* = 0x86E8
  POST_CONVOLUTION_RED_BIAS* = 0x8020
  DRAW_BUFFER8* = 0x882D
  MAP_INVALIDATE_RANGE_BIT* = 0x0004
  ALWAYS* = 0x0207
  ALPHA_MIN_SGIX* = 0x8320
  SOURCE0_RGB_ARB* = 0x8580
  POINT_SIZE_ARRAY_POINTER_OES* = 0x898C
  CUBIC_EXT* = 0x8334
  MAP2_NORMAL* = 0x0DB2
  TEXTURE_RESIDENT_EXT* = 0x8067
  TEXTURE_BUFFER_DATA_STORE_BINDING_ARB* = 0x8C2D
  BUMP_NUM_TEX_UNITS_ATI* = 0x8777
  TEXTURE_LOD_BIAS_T_SGIX* = 0x818F
  FONT_UNDERLINE_POSITION_BIT_NV* = 0x04000000
  NORMAL_ARRAY_STRIDE* = 0x807F
  CONDITION_SATISFIED_APPLE* = 0x911C
  POINT_SIZE_MIN* = 0x8126
  SPARE0_PLUS_SECONDARY_COLOR_NV* = 0x8532
  LAYOUT_DEFAULT_INTEL* = 0
  FRAMEBUFFER_BINDING* = 0x8CA6
  HIGH_FLOAT* = 0x8DF2
  NO_RESET_NOTIFICATION_ARB* = 0x8261
  OFFSET_TEXTURE_RECTANGLE_SCALE_NV* = 0x864D
  VERTEX_ATTRIB_ARRAY_ADDRESS_NV* = 0x8F20
  VIEW_CLASS_96_BITS* = 0x82C5
  BACK_RIGHT* = 0x0403
  BLEND_EQUATION_ALPHA* = 0x883D
  DISTANCE_ATTENUATION_SGIS* = 0x8129
  PROXY_TEXTURE_CUBE_MAP_ARRAY* = 0x900B
  RG16* = 0x822C
  UNDEFINED_VERTEX* = 0x8260
  PATH_DASH_OFFSET_NV* = 0x907E
  ALL_ATTRIB_BITS* = 0xFFFFFFFF
  VERTEX_ATTRIB_MAP1_ORDER_APPLE* = 0x8A04
  MAX_COLOR_MATRIX_STACK_DEPTH_SGI* = 0x80B3
  TIME_ELAPSED_EXT* = 0x88BF
  MAP2_VERTEX_3* = 0x0DB7
  MAX_PROGRAM_RESULT_COMPONENTS_NV* = 0x8909
  SAMPLER_2D_RECT_SHADOW_ARB* = 0x8B64
  cREFERENCE_PLANE_SGIX* = 0x817D
  LUMINANCE4_ALPHA4_EXT* = 0x8043
  PATH_FILL_MASK_NV* = 0x9081
  FILTER* = 0x829A
  INT_SAMPLER_2D_ARRAY* = 0x8DCF
  MAX_PROGRAM_ATTRIB_COMPONENTS_NV* = 0x8908
  EVAL_VERTEX_ATTRIB2_NV* = 0x86C8
  NAND* = 0x150E
  BLEND_SRC_RGB* = 0x80C9
  OPERAND2_ALPHA_EXT* = 0x859A
  IMAGE_1D_EXT* = 0x904C
  CONVOLUTION_FILTER_SCALE* = 0x8014
  IMAGE_CLASS_2_X_16* = 0x82BD
  VIEW_CLASS_BPTC_FLOAT* = 0x82D3
  PROGRAM_INPUT* = 0x92E3
  c1PASS_SGIS* = 0x80A1
  FOG_DISTANCE_MODE_NV* = 0x855A
  STENCIL_INDEX16_EXT* = 0x8D49
  POST_CONVOLUTION_RED_BIAS_EXT* = 0x8020
  PIXEL_MAP_R_TO_R* = 0x0C76
  c3DC_XY_AMD* = 0x87FA
  POINT_SIZE_MAX* = 0x8127
  DOUBLE_MAT3x2* = 0x8F4B
  DOUBLE_MAT4x2_EXT* = 0x8F4D
  TEXTURE_HI_SIZE_NV* = 0x871B
  MATRIX4_NV* = 0x8634
  SPRITE_TRANSLATION_SGIX* = 0x814B
  TEXTURE_FILTER_CONTROL_EXT* = 0x8500
  SMOOTH_LINE_WIDTH_GRANULARITY* = 0x0B23
  TEXTURE_BINDING_BUFFER* = 0x8C2C
  INTENSITY4* = 0x804A
  MAX_IMAGE_SAMPLES_EXT* = 0x906D
  COLOR_ATTACHMENT12* = 0x8CEC
  CLAMP_READ_COLOR* = 0x891C
  ELEMENT_ARRAY_BUFFER_ARB* = 0x8893
  MAP2_VERTEX_ATTRIB6_4_NV* = 0x8676
  CONVOLUTION_HEIGHT_EXT* = 0x8019
  SGX_PROGRAM_BINARY_IMG* = 0x9130
  MAP1_TEXTURE_COORD_1* = 0x0D93
  COMPRESSED_RGBA_ASTC_6x6_KHR* = 0x93B4
  TEXTURE_APPLICATION_MODE_EXT* = 0x834F
  TEXTURE_GATHER* = 0x82A2
  MAX_COMBINED_SHADER_STORAGE_BLOCKS* = 0x90DC
  DEBUG_LOGGED_MESSAGES_KHR* = 0x9145
  TEXTURE_VIEW_NUM_LEVELS* = 0x82DC
  ENABLE_BIT* = 0x00002000
  VERTEX_PROGRAM_TWO_SIDE_ARB* = 0x8643
  INDEX_TEST_EXT* = 0x81B5
  TEXTURE_WRAP_R* = 0x8072
  MAX* = 0x8008
  UNPACK_IMAGE_DEPTH_SGIS* = 0x8133
  COLOR_ATTACHMENT13_NV* = 0x8CED
  FOG_BIT* = 0x00000080
  GEOMETRY_SHADER_EXT* = 0x8DD9
  ALPHA_TEST_FUNC_QCOM* = 0x0BC1
  DRAW_BUFFER10_EXT* = 0x882F
  MAX_PROGRAM_NATIVE_TEX_INSTRUCTIONS_ARB* = 0x880F
  STENCIL_BACK_REF* = 0x8CA3
  SAMPLER_1D_ARB* = 0x8B5D
  cDRAW_BUFFER* = 0x0C01
  CLIENT_PIXEL_STORE_BIT* = 0x00000001
  TEXTURE_STENCIL_SIZE* = 0x88F1
  ELEMENT_ARRAY_APPLE* = 0x8A0C
  CON_21_ATI* = 0x8956
  ATOMIC_COUNTER_BUFFER_REFERENCED_BY_VERTEX_SHADER* = 0x92C7
  PIXEL_MAP_I_TO_B* = 0x0C74
  VERTEX_ATTRIB_MAP1_COEFF_APPLE* = 0x8A03
  FOG_INDEX* = 0x0B61
  PROXY_POST_CONVOLUTION_COLOR_TABLE_SGI* = 0x80D4
  OUTPUT_TEXTURE_COORD29_EXT* = 0x87BA
  TESS_CONTROL_SUBROUTINE* = 0x92E9
  IMAGE_CUBE_MAP_ARRAY* = 0x9054
  RGB_FLOAT32_ATI* = 0x8815
  OBJECT_SHADER_SOURCE_LENGTH_ARB* = 0x8B88
  COLOR_INDEX4_EXT* = 0x80E4
  DRAW_BUFFER14* = 0x8833
  PATH_STENCIL_DEPTH_OFFSET_UNITS_NV* = 0x90BE
  NATIVE_GRAPHICS_HANDLE_PGI* = 0x1A202
  UNSIGNED_SHORT_5_6_5* = 0x8363
  GREATER* = 0x0204
  DATA_BUFFER_AMD* = 0x9151
  GLYPH_VERTICAL_BEARING_Y_BIT_NV* = 0x40
  COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2* = 0x9276
  RELATIVE_MOVE_TO_NV* = 0x03
  BLUE_INTEGER* = 0x8D96
  BLUE_BIAS* = 0x0D1B
  SHADER_TYPE* = 0x8B4F
  TRANSFORM_FEEDBACK_BINDING* = 0x8E25
  TEXTURE17_ARB* = 0x84D1
  GREEN* = 0x1904
  MAX_TESS_CONTROL_UNIFORM_BLOCKS* = 0x8E89
  DRAW_BUFFER6* = 0x882B
  VALIDATE_STATUS* = 0x8B83
  TEXTURE_COORD_ARRAY_ADDRESS_NV* = 0x8F25
  MVP_MATRIX_EXT* = 0x87E3
  PIXEL_BUFFER_BARRIER_BIT_EXT* = 0x00000080
  MAX_VERTEX_VARYING_COMPONENTS_EXT* = 0x8DDE
  STACK_OVERFLOW_KHR* = 0x0503
  MAX_PROJECTION_STACK_DEPTH* = 0x0D38
  SKIP_COMPONENTS3_NV* = -4
  DEBUG_ASSERT_MESA* = 0x875B
  INSTRUMENT_BUFFER_POINTER_SGIX* = 0x8180
  SAMPLE_ALPHA_TO_MASK_EXT* = 0x809E
  REG_29_ATI* = 0x893E
  COMPRESSED_SRGB_ALPHA_S3TC_DXT3_NV* = 0x8C4E
  DEBUG_CATEGORY_DEPRECATION_AMD* = 0x914B
  DEPTH_STENCIL_TO_BGRA_NV* = 0x886F
  UNSIGNED_INT_VEC3_EXT* = 0x8DC7
  VERTEX_SHADER_EXT* = 0x8780
  cLIST_BASE* = 0x0B32
  TEXTURE_STENCIL_SIZE_EXT* = 0x88F1
  ACTIVE_PROGRAM* = 0x8259
  RGBA_SIGNED_COMPONENTS_EXT* = 0x8C3C
  COMPRESSED_SRGB8_ALPHA8_ASTC_12x10_KHR* = 0x93DC
  FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE* = 0x8CD0
  FRAMEBUFFER_ATTACHMENT_STENCIL_SIZE* = 0x8217
  MATRIX7_ARB* = 0x88C7
  FLOAT_VEC3_ARB* = 0x8B51
  PACK_ROW_BYTES_APPLE* = 0x8A15
  PIXEL_TILE_GRID_HEIGHT_SGIX* = 0x8143
  UNIFORM_BLOCK* = 0x92E2
  VIEWPORT_BIT* = 0x00000800
  RENDERBUFFER_COVERAGE_SAMPLES_NV* = 0x8CAB
  MAP1_BINORMAL_EXT* = 0x8446
  SAMPLER_3D* = 0x8B5F
  RENDERBUFFER_SAMPLES_APPLE* = 0x8CAB
  DEPTH_WRITEMASK* = 0x0B72
  MAP2_VERTEX_ATTRIB9_4_NV* = 0x8679
  TEXTURE_COMPARE_FUNC* = 0x884D
  CONTEXT_FLAG_ROBUST_ACCESS_BIT_ARB* = 0x00000004
  cREAD_BUFFER* = 0x0C02
  ONE_MINUS_SRC1_COLOR* = 0x88FA
  PROGRAM_FORMAT_ASCII_ARB* = 0x8875
  DRAW_FRAMEBUFFER_APPLE* = 0x8CA9
  FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE_OES* = 0x8CD0
  BLEND_DST* = 0x0BE0
  SHADER_OBJECT_EXT* = 0x8B48
  UNSIGNALED* = 0x9118
  VERTEX4_BIT_PGI* = 0x00000008
  DRAW_FRAMEBUFFER_BINDING_APPLE* = 0x8CA6
  IMAGE_CUBE_EXT* = 0x9050
  CONTEXT_ROBUST_ACCESS_EXT* = 0x90F3
  TEXTURE14_ARB* = 0x84CE
  TEXTURE_CUBE_MAP_POSITIVE_Y* = 0x8517
  OFFSET_HILO_PROJECTIVE_TEXTURE_RECTANGLE_NV* = 0x8857
  COMPRESSED_RG11_EAC_OES* = 0x9272
  OP_DOT4_EXT* = 0x8785
  FRAMEBUFFER_COMPLETE_EXT* = 0x8CD5
  TEXTURE_COMPARE_FUNC_ARB* = 0x884D
  TEXTURE_FILTER4_SIZE_SGIS* = 0x8147
  ELEMENT_ARRAY_BUFFER_BINDING* = 0x8895
  UNSIGNED_INT_IMAGE_BUFFER_EXT* = 0x9067
  IMAGE_1D_ARRAY_EXT* = 0x9052
  CLAMP_READ_COLOR_ARB* = 0x891C
  COMPUTE_SUBROUTINE* = 0x92ED
  R3_G3_B2* = 0x2A10
  PATH_DASH_ARRAY_COUNT_NV* = 0x909F
  SPOT_EXPONENT* = 0x1205
  NUM_PROGRAM_BINARY_FORMATS_OES* = 0x87FE
  SWIZZLE_STQ_ATI* = 0x8977
  SYNC_FLUSH_COMMANDS_BIT_APPLE* = 0x00000001
  VERTEX_STREAM6_ATI* = 0x8772
  cFRAGMENT_COLOR_MATERIAL_SGIX* = 0x8401
  DYNAMIC_ATI* = 0x8761
  SUB_ATI* = 0x8965
  PREVIOUS_EXT* = 0x8578
  MAP2_TEXTURE_COORD_1* = 0x0DB3
  COLOR_SAMPLES_NV* = 0x8E20
  HILO_NV* = 0x86F4
  SHADER_STORAGE_BUFFER_BINDING* = 0x90D3
  DUP_LAST_CUBIC_CURVE_TO_NV* = 0xF4
  ACTIVE_SUBROUTINES* = 0x8DE5
  FRAMEBUFFER_INCOMPLETE_MULTISAMPLE_IMG* = 0x9134
  INTENSITY16* = 0x804D
  MAX_PROGRAM_NATIVE_ATTRIBS_ARB* = 0x88AF
  TIMESTAMP_EXT* = 0x8E28
  cCLIENT_ACTIVE_TEXTURE* = 0x84E1
  TEXTURE_BINDING_2D_ARRAY* = 0x8C1D
  INT_SAMPLER_2D_RECT_EXT* = 0x8DCD
  PREFER_DOUBLEBUFFER_HINT_PGI* = 0x1A1F8
  TEXTURE_WIDTH* = 0x1000
  CPU_OPTIMIZED_QCOM* = 0x8FB1
  TEXTURE_IMAGE_TYPE* = 0x8290
  MAX_VERTEX_UNIFORM_VECTORS* = 0x8DFB
  MODULATE_SUBTRACT_ATI* = 0x8746
  SYNC_STATUS* = 0x9114
  IMAGE_2D_RECT_EXT* = 0x904F
  MATRIX6_NV* = 0x8636
  SOURCE1_RGB_ARB* = 0x8581
  MAX_COMBINED_ATOMIC_COUNTERS* = 0x92D7
  MAX_COMPUTE_LOCAL_INVOCATIONS* = 0x90EB
  SAMPLER_CUBE* = 0x8B60
  ALPHA_FLOAT32_ATI* = 0x8816
  COMPRESSED_LUMINANCE_ARB* = 0x84EA
  COMPRESSED_RGB8_ETC2_OES* = 0x9274
  DEBUG_NEXT_LOGGED_MESSAGE_LENGTH_KHR* = 0x8243
  MINUS_CLAMPED_NV* = 0x92B3
  REG_31_ATI* = 0x8940
  ELEMENT_ARRAY_ADDRESS_NV* = 0x8F29
  SRC1_COLOR* = 0x88F9
  DEBUG_SEVERITY_LOW_ARB* = 0x9148
  CON_3_ATI* = 0x8944
  R32I* = 0x8235
  cBLEND_COLOR* = 0x8005
  CLIP_PLANE4* = 0x3004
  CONTEXT_FLAG_FORWARD_COMPATIBLE_BIT* = 0x00000001
  FLOAT16_VEC4_NV* = 0x8FFB
  DST_IN_NV* = 0x928B
  VIRTUAL_PAGE_SIZE_Y_ARB* = 0x9196
  COLOR_ATTACHMENT8_NV* = 0x8CE8
  TESS_GEN_VERTEX_ORDER* = 0x8E78
  LOSE_CONTEXT_ON_RESET_EXT* = 0x8252
  PROGRAM_INSTRUCTIONS_ARB* = 0x88A0
  TEXTURE_IMAGE_VALID_QCOM* = 0x8BD8
  SAMPLE_MASK_VALUE_EXT* = 0x80AA
  CURRENT_MATRIX_ARB* = 0x8641
  DECR_WRAP_EXT* = 0x8508
  BLUE_INTEGER_EXT* = 0x8D96
  COMPRESSED_RG* = 0x8226
  MAX_PROGRAM_EXEC_INSTRUCTIONS_NV* = 0x88F4
  cMINMAX_EXT* = 0x802E
  FLOAT_MAT4_ARB* = 0x8B5C
  TEXTURE_CLIPMAP_FRAME_SGIX* = 0x8172
  PIXEL_UNPACK_BUFFER_EXT* = 0x88EC
  TEXTURE5_ARB* = 0x84C5
  UNSIGNED_INT_IMAGE_2D_RECT* = 0x9065
  MAX_COMPUTE_TEXTURE_IMAGE_UNITS* = 0x91BC
  DEPTH_COMPONENT* = 0x1902
  RG32F_EXT* = 0x8230
  FACTOR_ALPHA_MODULATE_IMG* = 0x8C07
  VERTEX_ARRAY_TYPE_EXT* = 0x807B
  DS_BIAS_NV* = 0x8716
  NATIVE_GRAPHICS_BEGIN_HINT_PGI* = 0x1A203
  ALPHA16UI_EXT* = 0x8D78
  DOUBLE_VEC2* = 0x8FFC
  MAP1_VERTEX_ATTRIB12_4_NV* = 0x866C
  c4D_COLOR_TEXTURE* = 0x0604
  MAX_VERTEX_SHADER_STORAGE_BLOCKS* = 0x90D6
  SPECULAR* = 0x1202
  TOP_LEVEL_ARRAY_SIZE* = 0x930C
  MAX_SPARSE_ARRAY_TEXTURE_LAYERS_ARB* = 0x919A
  COVERAGE_SAMPLES_NV* = 0x8ED4
  SIGNALED_APPLE* = 0x9119
  DEBUG_TYPE_DEPRECATED_BEHAVIOR_KHR* = 0x824D
  BUFFER_KHR* = 0x82E0
  GEOMETRY_TEXTURE* = 0x829E
  MIN_PROGRAM_TEXTURE_GATHER_OFFSET_NV* = 0x8E5E
  EVAL_VERTEX_ATTRIB7_NV* = 0x86CD
  GLYPH_VERTICAL_BEARING_ADVANCE_BIT_NV* = 0x80
  BINORMAL_ARRAY_POINTER_EXT* = 0x8443
  AUX3* = 0x040C
  MULTISAMPLE_BIT_EXT* = 0x20000000
  COLOR_TABLE_FORMAT_SGI* = 0x80D8
  VERTEX_PROGRAM_POINT_SIZE* = 0x8642
  LINE_WIDTH_GRANULARITY* = 0x0B23
  MAX_VERTEX_ATTRIB_BINDINGS* = 0x82DA
  TEXTURE_BINDING_2D_ARRAY_EXT* = 0x8C1D
  SIMULTANEOUS_TEXTURE_AND_DEPTH_TEST* = 0x82AC
  SCALE_BY_FOUR_NV* = 0x853F
  VIRTUAL_PAGE_SIZE_Z_AMD* = 0x9197
  TEXTURE16* = 0x84D0
  DSDT8_MAG8_NV* = 0x870A
  OP_FLOOR_EXT* = 0x878F
  MAX_PROGRAM_IF_DEPTH_NV* = 0x88F6
  VERTEX_ARRAY_LIST_IBM* = 103070
  COMPRESSED_SIGNED_RED_RGTC1* = 0x8DBC
  CUBIC_CURVE_TO_NV* = 0x0C
  PROXY_POST_CONVOLUTION_COLOR_TABLE* = 0x80D4
  SIGNED_IDENTITY_NV* = 0x853C
  EVAL_VERTEX_ATTRIB6_NV* = 0x86CC
  MODELVIEW10_ARB* = 0x872A
  MULTISAMPLE_3DFX* = 0x86B2
  COMPRESSED_RGB_PVRTC_4BPPV1_IMG* = 0x8C00
  DSDT_MAG_VIB_NV* = 0x86F7
  TEXCOORD4_BIT_PGI* = 0x80000000
  TRANSFORM_FEEDBACK_BARRIER_BIT* = 0x00000800
  EVAL_VERTEX_ATTRIB10_NV* = 0x86D0
  DRAW_BUFFER13_ARB* = 0x8832
  RENDERBUFFER_STENCIL_SIZE_OES* = 0x8D55
  INTENSITY8I_EXT* = 0x8D91
  STENCIL_BACK_PASS_DEPTH_FAIL* = 0x8802
  INTENSITY32F_ARB* = 0x8817
  CURRENT_ATTRIB_NV* = 0x8626
  POLYGON_BIT* = 0x00000008
  COMBINE_RGB* = 0x8571
  MAX_FRAMEBUFFER_HEIGHT* = 0x9316
  FRAMEBUFFER_BINDING_OES* = 0x8CA6
  TEXTURE_GREEN_TYPE* = 0x8C11
  LINE_TO_NV* = 0x04
  FUNC_ADD_EXT* = 0x8006
  TEXTURE_LOD_BIAS* = 0x8501
  QUAD_INTENSITY8_SGIS* = 0x8123
  SECONDARY_COLOR_ARRAY_EXT* = 0x845E
  UNPACK_COMPRESSED_SIZE_SGIX* = 0x831A
  RGBA_INTEGER* = 0x8D99
  ATOMIC_COUNTER_BUFFER_SIZE* = 0x92C3
  FRAMEBUFFER_INCOMPLETE_MULTISAMPLE* = 0x8D56
  OBJECT_DISTANCE_TO_LINE_SGIS* = 0x81F3
  DEPTH_BUFFER_BIT3_QCOM* = 0x00000800
  RGB16_SNORM* = 0x8F9A
  MATRIX_INDEX_ARRAY_TYPE_ARB* = 0x8847
  TRANSLATE_X_NV* = 0x908E
  BUFFER_ACCESS_FLAGS* = 0x911F
  IS_PER_PATCH* = 0x92E7
  PATH_GEN_MODE_NV* = 0x90B0
  ALPHA_MIN_CLAMP_INGR* = 0x8563
  LUMINANCE_ALPHA32I_EXT* = 0x8D87
  BUFFER_USAGE_ARB* = 0x8765
  cPOINT_SIZE* = 0x0B11
  INVARIANT_EXT* = 0x87C2
  IMAGE_BINDING_NAME* = 0x8F3A
  BLEND_SRC_ALPHA* = 0x80CB
  OUTPUT_TEXTURE_COORD23_EXT* = 0x87B4
  EYE_PLANE* = 0x2502
  BOOL_VEC4_ARB* = 0x8B59
  MITER_REVERT_NV* = 0x90A7
  SYNC_X11_FENCE_EXT* = 0x90E1
  GEOMETRY_SHADER_INVOCATIONS* = 0x887F
  DRAW_BUFFER5_ATI* = 0x882A
  FOG_COORDINATE_ARRAY_BUFFER_BINDING_ARB* = 0x889D
  UNSIGNED_INT_IMAGE_2D_MULTISAMPLE_EXT* = 0x906B
  PIXEL_TEX_GEN_Q_ROUND_SGIX* = 0x8185
  DOUBLE_MAT3x2_EXT* = 0x8F4B
  TEXTURE_CUBE_MAP_NEGATIVE_X_ARB* = 0x8516
  MOV_ATI* = 0x8961
  COLOR4_BIT_PGI* = 0x00020000
  COMPRESSED_SRGB8_ALPHA8_ASTC_12x12_KHR* = 0x93DD
  DEPTH_BOUNDS_TEST_EXT* = 0x8890
  DST_OVER_NV* = 0x9289
  PIXEL_MAP_I_TO_I_SIZE* = 0x0CB0
  ALPHA16F_EXT* = 0x881C
  RENDERBUFFER_BINDING_EXT* = 0x8CA7
  MATRIX25_ARB* = 0x88D9
  OUTPUT_TEXTURE_COORD19_EXT* = 0x87B0
  NORMAL_MAP* = 0x8511
  GPU_ADDRESS_NV* = 0x8F34
  STREAM_READ* = 0x88E1
  MIRRORED_REPEAT* = 0x8370
  TEXTURE_SWIZZLE_RGBA* = 0x8E46
  HALF_BIAS_NORMAL_NV* = 0x853A
  STENCIL_BACK_OP_VALUE_AMD* = 0x874D
  TEXTURE_BLUE_TYPE_ARB* = 0x8C12
  MODELVIEW_PROJECTION_NV* = 0x8629
  ACTIVE_UNIFORM_MAX_LENGTH* = 0x8B87
  TEXTURE_SWIZZLE_RGBA_EXT* = 0x8E46
  TEXTURE_GEN_T* = 0x0C61
  HILO16_NV* = 0x86F8
  CURRENT_QUERY_EXT* = 0x8865
  FLOAT16_VEC2_NV* = 0x8FF9
  RGBA_FLOAT_MODE_ARB* = 0x8820
  POINT_SIZE_ARRAY_TYPE_OES* = 0x898A
  GENERATE_MIPMAP_HINT* = 0x8192
  c1PASS_EXT* = 0x80A1
  SWIZZLE_STQ_DQ_ATI* = 0x8979
  VERTICAL_LINE_TO_NV* = 0x08
  cMINMAX* = 0x802E
  RENDERBUFFER_ALPHA_SIZE_EXT* = 0x8D53
  DEPTH_COMPONENT32F* = 0x8CAC
  NEXT_VIDEO_CAPTURE_BUFFER_STATUS_NV* = 0x9025
  CLIP_PLANE5_IMG* = 0x3005
  TEXTURE_2D_MULTISAMPLE* = 0x9100
  PREVIOUS* = 0x8578
  CULL_MODES_NV* = 0x86E0
  TRACE_ARRAYS_BIT_MESA* = 0x0004
  MAX_ACTIVE_LIGHTS_SGIX* = 0x8405
  PRIMITIVE_ID_NV* = 0x8C7C
  DEPTH_COMPONENT16* = 0x81A5
  FRAMEBUFFER_ATTACHMENT_LAYERED* = 0x8DA7
  MAX_FRAGMENT_UNIFORM_BLOCKS* = 0x8A2D
  OUTPUT_COLOR0_EXT* = 0x879B
  RGBA16F_EXT* = 0x881A
  MAX_PALETTE_MATRICES_OES* = 0x8842
  VIEW_CLASS_64_BITS* = 0x82C6
  TRACE_ALL_BITS_MESA* = 0xFFFF
  REPLACE_VALUE_AMD* = 0x874B
  PROXY_POST_IMAGE_TRANSFORM_COLOR_TABLE_HP* = 0x8163
  BGR_INTEGER* = 0x8D9A
  MAX_DEBUG_LOGGED_MESSAGES_ARB* = 0x9144
  FOG_COLOR* = 0x0B66
  MAX_MULTIVIEW_BUFFERS_EXT* = 0x90F2
  TRANSFORM_FEEDBACK_BUFFER* = 0x8C8E
  E_TIMES_F_NV* = 0x8531
  COLOR_TABLE_WIDTH_SGI* = 0x80D9
  VERTEX_ATTRIB_ARRAY_SIZE* = 0x8623
  c422_REV_AVERAGE_EXT* = 0x80CF
  WRITE_DISCARD_NV* = 0x88BE
  DRAW_BUFFER0_EXT* = 0x8825
  FONT_HEIGHT_BIT_NV* = 0x00800000
  INTERLACE_OML* = 0x8980
  FUNC_REVERSE_SUBTRACT_EXT* = 0x800B
  MAX_VERTEX_SHADER_LOCAL_CONSTANTS_EXT* = 0x87C8
  PRIMARY_COLOR* = 0x8577
  RGBA16I* = 0x8D88
  TEXTURE6* = 0x84C6
  PATH_FILL_BOUNDING_BOX_NV* = 0x90A1
  WEIGHT_ARRAY_BUFFER_BINDING* = 0x889E
  COLOR_CLEAR_UNCLAMPED_VALUE_ATI* = 0x8835
  YCRCB_422_SGIX* = 0x81BB
  RGB5_A1* = 0x8057
  FRAMEBUFFER_ATTACHMENT_COMPONENT_TYPE_EXT* = 0x8211
  DRAW_FRAMEBUFFER_BINDING_EXT* = 0x8CA6
  TEXTURE_1D_ARRAY* = 0x8C18
  CLAMP_FRAGMENT_COLOR_ARB* = 0x891B
  FULL_RANGE_EXT* = 0x87E1
  GEOMETRY_PROGRAM_PARAMETER_BUFFER_NV* = 0x8DA3
  CON_24_ATI* = 0x8959
  c2D* = 0x0600
  DRAW_BUFFER5_NV* = 0x882A
  PALETTE4_RGBA8_OES* = 0x8B91
  READ_ONLY_ARB* = 0x88B8
  NUM_SAMPLE_COUNTS* = 0x9380
  MATRIX_STRIDE* = 0x92FF
  HISTOGRAM_RED_SIZE* = 0x8028
  COLOR_ATTACHMENT4* = 0x8CE4
  PATH_INITIAL_END_CAP_NV* = 0x9077
  TEXTURE_USAGE_ANGLE* = 0x93A2
  DOUBLE_MAT2* = 0x8F46
  FRAMEBUFFER_ATTACHMENT_RED_SIZE* = 0x8212
  SECONDARY_COLOR_ARRAY_POINTER* = 0x845D
  MAX_VIEWPORTS* = 0x825B
  TRANSFORM_FEEDBACK_BUFFER_EXT* = 0x8C8E
  FRAMEBUFFER_SRGB_EXT* = 0x8DB9
  STORAGE_SHARED_APPLE* = 0x85BF
  TRANSFORM_FEEDBACK_VARYING_MAX_LENGTH* = 0x8C76
  TRANSFORM_FEEDBACK_NV* = 0x8E22
  MIRRORED_REPEAT_ARB* = 0x8370
  MAX_VERTEX_OUTPUT_COMPONENTS* = 0x9122
  BUFFER_MAP_LENGTH* = 0x9120
  BUFFER_OBJECT_APPLE* = 0x85B3
  INT_VEC4_ARB* = 0x8B55
  COMBINER3_NV* = 0x8553
  INT16_VEC3_NV* = 0x8FE6
  MAX_3D_TEXTURE_SIZE_EXT* = 0x8073
  GENERATE_MIPMAP_HINT_SGIS* = 0x8192
  SRC0_ALPHA* = 0x8588
  IMAGE_2D* = 0x904D
  VIEW_CLASS_S3TC_DXT1_RGB* = 0x82CC
  DOT3_RGBA* = 0x86AF
  TEXTURE_GREEN_SIZE* = 0x805D
  DOUBLE_MAT2x3* = 0x8F49
  COORD_REPLACE_OES* = 0x8862
  MAX_DEBUG_MESSAGE_LENGTH_ARB* = 0x9143
  TEXTURE_IMMUTABLE_FORMAT_EXT* = 0x912F
  INDEX_ARRAY_POINTER_EXT* = 0x8091
  NUM_SHADING_LANGUAGE_VERSIONS* = 0x82E9
  DEBUG_CALLBACK_FUNCTION_ARB* = 0x8244
  OFFSET_TEXTURE_MATRIX_NV* = 0x86E1
  INTENSITY32I_EXT* = 0x8D85
  BUMP_TEX_UNITS_ATI* = 0x8778
  RENDERBUFFER* = 0x8D41
  UPPER_LEFT* = 0x8CA2
  GUILTY_CONTEXT_RESET_ARB* = 0x8253
  MAP2_GRID_SEGMENTS* = 0x0DD3
  REG_23_ATI* = 0x8938
  UNSIGNED_INT16_NV* = 0x8FF0
  TEXTURE_COORD_ARRAY_LIST_STRIDE_IBM* = 103084
  INVARIANT_VALUE_EXT* = 0x87EA
  TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN_NV* = 0x8C88
  TEXTURE2_ARB* = 0x84C2
  UNSIGNED_INT_SAMPLER_2D_ARRAY_EXT* = 0x8DD7
  IMAGE_CUBE* = 0x9050
  MAX_PROGRAM_MATRICES_ARB* = 0x862F
  SIGNED_LUMINANCE8_ALPHA8_NV* = 0x8704
  INDEX_ARRAY_LIST_IBM* = 103073
  EVAL_VERTEX_ATTRIB5_NV* = 0x86CB
  SHADER_SOURCE_LENGTH* = 0x8B88
  TEXTURE4* = 0x84C4
  VERTEX_ATTRIB_ARRAY6_NV* = 0x8656
  PROXY_TEXTURE_1D_STACK_MESAX* = 0x875B
  MAP_ATTRIB_V_ORDER_NV* = 0x86C4
  DSDT_NV* = 0x86F5
  DEBUG_SEVERITY_NOTIFICATION_KHR* = 0x826B
  FOG_COORDINATE_ARRAY_LIST_STRIDE_IBM* = 103086
  COMPRESSED_RGBA_ASTC_8x6_KHR* = 0x93B6
  LINEAR_ATTENUATION* = 0x1208
  Z4Y12Z4CB12Z4Y12Z4CR12_422_NV* = 0x9035
  CONVOLUTION_FILTER_BIAS* = 0x8015
  IMAGE_MIN_FILTER_HP* = 0x815D
  EYE_RADIAL_NV* = 0x855B
  TEXTURE_MIN_LOD_SGIS* = 0x813A
  TRANSFORM_FEEDBACK_BUFFER_BINDING_NV* = 0x8C8F
  TRANSLATE_2D_NV* = 0x9090
  CONSTANT_ARB* = 0x8576
  FLOAT_MAT2x3* = 0x8B65
  MULTISAMPLE_COVERAGE_MODES_NV* = 0x8E12
  TRANSPOSE_COLOR_MATRIX* = 0x84E6
  PROGRAM_STRING_NV* = 0x8628
  UNSIGNED_INT_SAMPLER_1D_EXT* = 0x8DD1
  BLEND_SRC_ALPHA_OES* = 0x80CB
  RGB32F_EXT* = 0x8815
  FRAMEBUFFER_ATTACHMENT_TEXTURE_3D_ZOFFSET_EXT* = 0x8CD4
  RESTART_PATH_NV* = 0xF0
  MAP2_VERTEX_ATTRIB11_4_NV* = 0x867B
  VIEW_CLASS_16_BITS* = 0x82CA
  BUFFER_DATA_SIZE* = 0x9303
  BUFFER_FLUSHING_UNMAP_APPLE* = 0x8A13
  RELATIVE_VERTICAL_LINE_TO_NV* = 0x09
  SRGB_WRITE* = 0x8298
  TEXTURE_LUMINANCE_SIZE_EXT* = 0x8060
  VERTEX_PRECLIP_SGIX* = 0x83EE
  LINEAR_DETAIL_COLOR_SGIS* = 0x8099
  SOURCE2_ALPHA_ARB* = 0x858A
  PATH_FOG_GEN_MODE_NV* = 0x90AC
  RGB10_A2UI* = 0x906F
  MULTISAMPLE_BIT_3DFX* = 0x20000000
  PIXEL_MAP_G_TO_G_SIZE* = 0x0CB7
  COVERAGE_BUFFER_BIT_NV* = 0x00008000
  TEXTURE_COMPRESSED* = 0x86A1
  ATOMIC_COUNTER_BUFFER_REFERENCED_BY_GEOMETRY_SHADER* = 0x92CA
  NAMED_STRING_TYPE_ARB* = 0x8DEA
  RESCALE_NORMAL* = 0x803A
  OUTPUT_TEXTURE_COORD3_EXT* = 0x87A0
  RENDERBUFFER_EXT* = 0x8D41
  QUERY_NO_WAIT* = 0x8E14
  SAMPLE_ALPHA_TO_COVERAGE* = 0x809E
  RG8UI* = 0x8238
  MATRIX3_NV* = 0x8633
  SAMPLE_BUFFERS_ARB* = 0x80A8
  VERTEX_CONSISTENT_HINT_PGI* = 0x1A22B
  SPRITE_AXIAL_SGIX* = 0x814C
  MODELVIEW_MATRIX* = 0x0BA6
  cSAMPLE_PATTERN_SGIS* = 0x80AC
  UNSIGNED_INT_IMAGE_2D_MULTISAMPLE* = 0x906B
  FLOAT_RG16_NV* = 0x8886
  IMAGE_TRANSLATE_X_HP* = 0x8157
  FRAMEBUFFER_SRGB* = 0x8DB9
  DRAW_BUFFER7* = 0x882C
  CONVOLUTION_BORDER_COLOR* = 0x8154
  DRAW_BUFFER5* = 0x882A
  GEOMETRY_INPUT_TYPE_EXT* = 0x8DDB
  IUI_V2F_EXT* = 0x81AD
  FLOAT_RG_NV* = 0x8881
  VERTEX_SHADER_INVARIANTS_EXT* = 0x87D1
  COMPRESSED_SRGB_ALPHA_S3TC_DXT1_NV* = 0x8C4D
  MAX_PROGRAM_MATRIX_STACK_DEPTH_ARB* = 0x862E
  cSAMPLE_PATTERN_EXT* = 0x80AC
  DIFFERENCE_NV* = 0x929E
  POST_CONVOLUTION_ALPHA_BIAS_EXT* = 0x8023
  COLOR_ATTACHMENT1_EXT* = 0x8CE1
  TEXTURE_ALPHA_MODULATE_IMG* = 0x8C06
  TRANSFORM_FEEDBACK_BUFFER_PAUSED_NV* = 0x8E23
  MAX_TEXTURE_IMAGE_UNITS_ARB* = 0x8872
  FIXED_OES* = 0x140C
  ALREADY_SIGNALED_APPLE* = 0x911A
  SET* = 0x150F
  PERFMON_RESULT_AMD* = 0x8BC6
  VARIABLE_G_NV* = 0x8529
  DRAW_FRAMEBUFFER_ANGLE* = 0x8CA9
  GEOMETRY_SUBROUTINE_UNIFORM* = 0x92F1
  COMPARE_REF_DEPTH_TO_TEXTURE_EXT* = 0x884E
  POINT* = 0x1B00
  FONT_MAX_ADVANCE_WIDTH_BIT_NV* = 0x01000000
  MAX_TESS_CONTROL_IMAGE_UNIFORMS* = 0x90CB
  PLUS_CLAMPED_ALPHA_NV* = 0x92B2
  DRAW_BUFFER3_ATI* = 0x8828
  LUMINANCE_ALPHA16I_EXT* = 0x8D8D
  SUBPIXEL_BITS* = 0x0D50
  POINT_SPRITE* = 0x8861
  DRAW_BUFFER0* = 0x8825
  DEPTH_BIAS* = 0x0D1F
  COLOR_ARRAY_TYPE* = 0x8082
  DEPENDENT_GB_TEXTURE_2D_NV* = 0x86EA
  MAX_SAMPLES_ANGLE* = 0x8D57
  ALLOW_DRAW_MEM_HINT_PGI* = 0x1A211
  GEOMETRY_OUTPUT_TYPE* = 0x8918
  MAX_DEBUG_LOGGED_MESSAGES_KHR* = 0x9144
  VERTEX_ATTRIB_ARRAY0_NV* = 0x8650
  PRIMITIVES_GENERATED_EXT* = 0x8C87
  TEXTURE_FLOAT_COMPONENTS_NV* = 0x888C
  CLIP_VOLUME_CLIPPING_HINT_EXT* = 0x80F0
  FRAGMENT_PROGRAM_POSITION_MESA* = 0x8BB0
  MAX_FRAGMENT_IMAGE_UNIFORMS* = 0x90CE
  VERTEX_ARRAY_BINDING_APPLE* = 0x85B5
  SHADER_GLOBAL_ACCESS_BARRIER_BIT_NV* = 0x00000010
  FIRST_VERTEX_CONVENTION* = 0x8E4D
  DECR_WRAP* = 0x8508
  IMAGE_CLASS_1_X_32* = 0x82BB
  MAX_CLIP_PLANES_IMG* = 0x0D32
  MAX_VARYING_COMPONENTS* = 0x8B4B
  POST_COLOR_MATRIX_RED_BIAS_SGI* = 0x80B8
  DSDT_MAG_NV* = 0x86F6
  DEBUG_SOURCE_APPLICATION* = 0x824A
  OPERAND0_RGB_ARB* = 0x8590
  SIMULTANEOUS_TEXTURE_AND_DEPTH_WRITE* = 0x82AE
  VIDEO_COLOR_CONVERSION_MATRIX_NV* = 0x9029
  MAP2_VERTEX_ATTRIB13_4_NV* = 0x867D
  DOT2_ADD_ATI* = 0x896C
  MAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS* = 0x8A33
  IMAGE_BINDING_LAYER_EXT* = 0x8F3D
  FRAGMENT_COLOR_MATERIAL_FACE_SGIX* = 0x8402
  PACK_IMAGE_DEPTH_SGIS* = 0x8131
  MAX_GEOMETRY_UNIFORM_COMPONENTS_EXT* = 0x8DDF
  Z_EXT* = 0x87D7
  MAP1_VERTEX_ATTRIB15_4_NV* = 0x866F
  RG8_SNORM* = 0x8F95
  OUTPUT_TEXTURE_COORD5_EXT* = 0x87A2
  TEXTURE_BINDING_1D_ARRAY_EXT* = 0x8C1C
  OBJECT_ACTIVE_UNIFORM_MAX_LENGTH_ARB* = 0x8B87
  PATH_END_CAPS_NV* = 0x9076
  COLOR_TABLE_GREEN_SIZE* = 0x80DB
  MAX_ELEMENTS_INDICES_EXT* = 0x80E9
  TEXTURE_IMMUTABLE_FORMAT* = 0x912F
  WRITE_ONLY_ARB* = 0x88B9
  COLOR_ATTACHMENT10_EXT* = 0x8CEA
  INVERT_RGB_NV* = 0x92A3
  CURRENT_RASTER_DISTANCE* = 0x0B09
  DEPTH_STENCIL_TO_RGBA_NV* = 0x886E
  INVERTED_SCREEN_W_REND* = 0x8491
  TABLE_TOO_LARGE* = 0x8031
  REG_16_ATI* = 0x8931
  BLEND_EQUATION_ALPHA_OES* = 0x883D
  DRAW_FRAMEBUFFER_BINDING_NV* = 0x8CA6
  ACTIVE_SUBROUTINE_UNIFORM_LOCATIONS* = 0x8E47
  TEXTURE_BLUE_SIZE_EXT* = 0x805E
  TEXTURE_BORDER_VALUES_NV* = 0x871A
  PROGRAM_LENGTH_ARB* = 0x8627
  BOUNDING_BOX_OF_BOUNDING_BOXES_NV* = 0x909C
  DOT_PRODUCT_NV* = 0x86EC
  TRANSPOSE_PROJECTION_MATRIX_ARB* = 0x84E4
  TEXTURE_2D_MULTISAMPLE_ARRAY* = 0x9102
  MIN_PROGRAM_TEXEL_OFFSET_NV* = 0x8904
  MAP2_BINORMAL_EXT* = 0x8447
  COLOR_ARRAY_BUFFER_BINDING* = 0x8898
  TEXTURE_COORD_ARRAY_POINTER* = 0x8092
  TEXTURE4_ARB* = 0x84C4
  VARIABLE_A_NV* = 0x8523
  CURRENT_FOG_COORDINATE_EXT* = 0x8453
  TEXTURE_CUBE_MAP_POSITIVE_X* = 0x8515
  DEPENDENT_AR_TEXTURE_2D_NV* = 0x86E9
  TEXTURE29_ARB* = 0x84DD
  INVERSE_TRANSPOSE_NV* = 0x862D
  TEXTURE_COLOR_WRITEMASK_SGIS* = 0x81EF
  HISTOGRAM_SINK* = 0x802D
  ALPHA12_EXT* = 0x803D
  TEXTURE_CLIPMAP_LOD_OFFSET_SGIX* = 0x8175
  DSDT_MAG_INTENSITY_NV* = 0x86DC
  ATC_RGB_AMD* = 0x8C92
  PROGRAM_ATTRIB_COMPONENTS_NV* = 0x8906
  cUNIFORM_BLOCK_BINDING* = 0x8A3F
  cPOLYGON_STIPPLE* = 0x0B42
  BACK* = 0x0405
  DEPTH_COMPONENT16_NONLINEAR_NV* = 0x8E2C
  ALPHA32F_EXT* = 0x8816
  CLAMP_TO_BORDER* = 0x812D
  FLOAT_RGBA16_NV* = 0x888A
  VERTEX_ARRAY_RANGE_LENGTH_NV* = 0x851E
  UNSIGNED_INT_SAMPLER_RENDERBUFFER_NV* = 0x8E58
  SAMPLER_2D* = 0x8B5E
  SMOOTH_POINT_SIZE_RANGE* = 0x0B12
  DEPTH_PASS_INSTRUMENT_MAX_SGIX* = 0x8312
  INTERPOLATE_ARB* = 0x8575
  VERTEX_ARRAY_LENGTH_NV* = 0x8F2B
  FUNC_SUBTRACT_EXT* = 0x800A
  OUTPUT_TEXTURE_COORD14_EXT* = 0x87AB
  HISTOGRAM_SINK_EXT* = 0x802D
  RG_EXT* = 0x8227
  SHARPEN_TEXTURE_FUNC_POINTS_SGIS* = 0x80B0
  COLOR_TABLE_SCALE* = 0x80D6
  CURRENT_RASTER_TEXTURE_COORDS* = 0x0B06
  PIXEL_BUFFER_BARRIER_BIT* = 0x00000080
  SHADING_LANGUAGE_VERSION* = 0x8B8C
  TEXTURE_MATRIX_FLOAT_AS_INT_BITS_OES* = 0x898F
  DUAL_LUMINANCE_ALPHA4_SGIS* = 0x811C
  CLAMP* = 0x2900
  c4PASS_2_EXT* = 0x80A6
  POLYGON_OFFSET_LINE* = 0x2A02
  cLOGIC_OP* = 0x0BF1
  RENDERBUFFER_HEIGHT* = 0x8D43
  COPY_INVERTED* = 0x150C
  NONE* = 0
  COLOR_ENCODING* = 0x8296
  ONE_MINUS_CONSTANT_ALPHA_EXT* = 0x8004
  DEBUG_TYPE_ERROR_KHR* = 0x824C
  PIXEL_TILE_GRID_WIDTH_SGIX* = 0x8142
  UNIFORM_SIZE* = 0x8A38
  VERTEX_SHADER_BINDING_EXT* = 0x8781
  BLEND_DST_RGB_EXT* = 0x80C8
  QUADS* = 0x0007
  INT* = 0x1404
  PIXEL_TEX_GEN_MODE_SGIX* = 0x832B
  COMPRESSED_RGB_BPTC_UNSIGNED_FLOAT_ARB* = 0x8E8F
  SAMPLE_ALPHA_TO_ONE_ARB* = 0x809F
  RGBA32F_EXT* = 0x8814
  VERTEX_PROGRAM_POSITION_MESA* = 0x8BB4
  GEOMETRY_SUBROUTINE* = 0x92EB
  UNSIGNED_INT_SAMPLER_1D_ARRAY_EXT* = 0x8DD6
  IMAGE_BINDING_LAYER* = 0x8F3D
  PIXEL_PACK_BUFFER_ARB* = 0x88EB
  UNIFORM_BLOCK_REFERENCED_BY_TESS_EVALUATION_SHADER* = 0x84F1
  VERTEX_ATTRIB_ARRAY_SIZE_ARB* = 0x8623
  ALPHA8UI_EXT* = 0x8D7E
  RELATIVE_SMOOTH_CUBIC_CURVE_TO_NV* = 0x11
  CAVEAT_SUPPORT* = 0x82B8
  cACCUM* = 0x0100
  DRAW_BUFFER3_NV* = 0x8828
  DEBUG_TYPE_OTHER_KHR* = 0x8251
  TESS_GEN_SPACING* = 0x8E77
  FLOAT_MAT4x2* = 0x8B69
  TEXTURE_GEN_STR_OES* = 0x8D60
  NUM_COMPATIBLE_SUBROUTINES* = 0x8E4A
  CLIP_DISTANCE1* = 0x3001
  DEPTH_COMPONENT32_SGIX* = 0x81A7
  cFRAMEZOOM_SGIX* = 0x818B
  COLOR_ATTACHMENT14_EXT* = 0x8CEE
  POLYGON_TOKEN* = 0x0703
  FRAMEBUFFER_ATTACHMENT_GREEN_SIZE* = 0x8213
  DRAW_BUFFER2_EXT* = 0x8827
  MATRIX_INDEX_ARRAY_TYPE_OES* = 0x8847
  HISTOGRAM_LUMINANCE_SIZE_EXT* = 0x802C
  cDEPTH_BOUNDS_EXT* = 0x8891
  TEXTURE24* = 0x84D8
  UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES* = 0x8A43
  MAX_PATCH_VERTICES* = 0x8E7D
  COMPILE_STATUS* = 0x8B81
  MODELVIEW4_ARB* = 0x8724
  SHADER_BINARY_VIV* = 0x8FC4
  CON_10_ATI* = 0x894B
  FRAGMENT_LIGHT5_SGIX* = 0x8411
  CONVOLUTION_1D_EXT* = 0x8010
  CONSTANT_BORDER_HP* = 0x8151
  SAMPLE_BUFFERS* = 0x80A8
  RGB8UI* = 0x8D7D
  FRAGMENT_MATERIAL_EXT* = 0x8349
  OP_RECIP_EXT* = 0x8794
  SHADER_OPERATION_NV* = 0x86DF
  COMPUTE_SUBROUTINE_UNIFORM* = 0x92F3
  VIDEO_BUFFER_PITCH_NV* = 0x9028
  UNKNOWN_CONTEXT_RESET_ARB* = 0x8255
  COLOR_ATTACHMENT3_EXT* = 0x8CE3
  QUERY_WAIT* = 0x8E13
  SOURCE1_RGB* = 0x8581
  DELETE_STATUS* = 0x8B80
  DEBUG_NEXT_LOGGED_MESSAGE_LENGTH_ARB* = 0x8243
  HILO8_NV* = 0x885E
  UNSIGNED_INT_IMAGE_CUBE_MAP_ARRAY_EXT* = 0x906A
  LUMINANCE_ALPHA_FLOAT16_APPLE* = 0x881F
  LUMINANCE16_SNORM* = 0x9019
  MAX_CLIPMAP_VIRTUAL_DEPTH_SGIX* = 0x8178
  RENDER* = 0x1C00
  RED_INTEGER* = 0x8D94
  DEBUG_TYPE_ERROR_ARB* = 0x824C
  IMAGE_BINDING_ACCESS* = 0x8F3E
  COVERAGE_COMPONENT_NV* = 0x8ED0
  TEXTURE_BINDING_BUFFER_EXT* = 0x8C2C
  MAX_PROGRAM_PATCH_ATTRIBS_NV* = 0x86D8
  DUAL_LUMINANCE12_SGIS* = 0x8116
  QUAD_ALPHA8_SGIS* = 0x811F
  COMPRESSED_RED_GREEN_RGTC2_EXT* = 0x8DBD
  PACK_INVERT_MESA* = 0x8758
  OUTPUT_TEXTURE_COORD11_EXT* = 0x87A8
  DYNAMIC_DRAW_ARB* = 0x88E8
  RGB565_OES* = 0x8D62
  LINE* = 0x1B01
  T2F_V3F* = 0x2A27
  DIFFUSE* = 0x1201
  FOG_COORDINATE_SOURCE* = 0x8450
  TEXTURE_1D_ARRAY_EXT* = 0x8C18
  TEXTURE_RECTANGLE_NV* = 0x84F5
  STENCIL_INDEX4_EXT* = 0x8D47
  VERTEX_PROGRAM_TWO_SIDE* = 0x8643
  REDUCE* = 0x8016
  DEBUG_CALLBACK_USER_PARAM_KHR* = 0x8245
  DEBUG_LOGGED_MESSAGES_AMD* = 0x9145
  FONT_UNITS_PER_EM_BIT_NV* = 0x00100000
  INVALID_FRAMEBUFFER_OPERATION_EXT* = 0x0506
  NORMAL_ARRAY_BUFFER_BINDING_ARB* = 0x8897
  SAMPLE_MASK_INVERT_SGIS* = 0x80AB
  MAX_SHADER_BUFFER_ADDRESS_NV* = 0x8F35
  PIXEL_MAP_I_TO_A* = 0x0C75
  MINOR_VERSION* = 0x821C
  cTEXTURE_BUFFER_EXT* = 0x8C2A
  SKIP_COMPONENTS4_NV* = -3
  FLOAT16_NV* = 0x8FF8
  FEEDBACK_BUFFER_TYPE* = 0x0DF2
  COMPRESSED_LUMINANCE_ALPHA_LATC2_EXT* = 0x8C72
  REG_6_ATI* = 0x8927
  EDGE_FLAG_ARRAY_LIST_IBM* = 103075
  MATRIX26_ARB* = 0x88DA
  ALPHA16* = 0x803E
  FRAMEBUFFER_ATTACHMENT_OBJECT_NAME* = 0x8CD1
  HISTOGRAM_ALPHA_SIZE* = 0x802B
  COLOR_MATRIX_STACK_DEPTH* = 0x80B2
  INTERNALFORMAT_GREEN_TYPE* = 0x8279
  YCRCBA_SGIX* = 0x8319
  VIEW_CLASS_48_BITS* = 0x82C7
  VERTEX_ATTRIB_ARRAY3_NV* = 0x8653
  CLIENT_STORAGE_BIT* = 0x0200
  MIN_SAMPLE_SHADING_VALUE_ARB* = 0x8C37
  PROXY_TEXTURE_CUBE_MAP* = 0x851B
  MAX_COMBINED_SHADER_OUTPUT_RESOURCES* = 0x8F39
  TEXTURE15* = 0x84CF
  COLOR* = 0x1800
  LIGHT1* = 0x4001
  LUMINANCE_ALPHA16F_EXT* = 0x881F
  TEXTURE_VIEW_NUM_LAYERS* = 0x82DE
  MAX_TESS_EVALUATION_TEXTURE_IMAGE_UNITS* = 0x8E82
  INTERLEAVED_ATTRIBS_NV* = 0x8C8C
  INT_SAMPLER_BUFFER_EXT* = 0x8DD0
  EVAL_VERTEX_ATTRIB14_NV* = 0x86D4
  FRAGMENT_PROGRAM_CALLBACK_MESA* = 0x8BB1
  EMISSION* = 0x1600
  WEIGHT_ARRAY_STRIDE_ARB* = 0x86AA
  ACTIVE_VARIABLES* = 0x9305
  TIMEOUT_IGNORED* = 0xFFFFFFFFFFFFFFFF
  VERTEX_STREAM5_ATI* = 0x8771
  INDEX_ARRAY_POINTER* = 0x8091
  POST_COLOR_MATRIX_ALPHA_SCALE* = 0x80B7
  TESS_CONTROL_SHADER* = 0x8E88
  cPOLYGON_MODE* = 0x0B40
  ASYNC_DRAW_PIXELS_SGIX* = 0x835D
  RGBA16_SNORM* = 0x8F9B
  cTEXTURE_NORMAL_EXT* = 0x85AF
  REG_22_ATI* = 0x8937
  FRAMEBUFFER_DEFAULT_WIDTH* = 0x9310
  TEXCOORD1_BIT_PGI* = 0x10000000
  REFERENCE_PLANE_EQUATION_SGIX* = 0x817E
  COLOR_ALPHA_PAIRING_ATI* = 0x8975
  SINGLE_COLOR* = 0x81F9
  MODELVIEW21_ARB* = 0x8735
  FORMAT_SUBSAMPLE_24_24_OML* = 0x8982
  SOURCE1_ALPHA* = 0x8589
  LINEARLIGHT_NV* = 0x92A7
  REG_2_ATI* = 0x8923
  QUERY_RESULT_AVAILABLE* = 0x8867
  PERSPECTIVE_CORRECTION_HINT* = 0x0C50
  COMBINE_ALPHA_ARB* = 0x8572
  HISTOGRAM_ALPHA_SIZE_EXT* = 0x802B
  SIGNED_RGB8_NV* = 0x86FF
  DEPTH_TEXTURE_MODE_ARB* = 0x884B
  PRESENT_DURATION_NV* = 0x8E2B
  TRIANGLES_ADJACENCY_ARB* = 0x000C
  TEXTURE_BUFFER_OFFSET* = 0x919D
  cPROGRAM_STRING_ARB* = 0x8628
  UNSIGNED_INT_IMAGE_1D_EXT* = 0x9062
  COLOR_ATTACHMENT2* = 0x8CE2
  DOT_PRODUCT_TEXTURE_2D_NV* = 0x86EE
  QUERY_BUFFER* = 0x9192
  TEXTURE_CUBE_MAP_NEGATIVE_Z* = 0x851A
  PIXEL_TEX_GEN_ALPHA_REPLACE_SGIX* = 0x8187
  FULL_SUPPORT* = 0x82B7
  MAX_PROGRAM_ENV_PARAMETERS_ARB* = 0x88B5
  MAX_COMPUTE_WORK_GROUP_COUNT* = 0x91BE
  DEBUG_TYPE_PERFORMANCE* = 0x8250
  DRAW_BUFFER12_EXT* = 0x8831
  UNSIGNED_INT_SAMPLER_BUFFER_AMD* = 0x9003
  CURRENT_FOG_COORDINATE* = 0x8453
  INTENSITY_EXT* = 0x8049
  TRANSPOSE_NV* = 0x862C
  COMPRESSED_SRGB_ALPHA_S3TC_DXT5_NV* = 0x8C4F
  MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS* = 0x8C80
  COLOR_ARRAY_POINTER_EXT* = 0x8090
  TEXTURE_BUFFER_DATA_STORE_BINDING_EXT* = 0x8C2D
  GEOMETRY_VERTICES_OUT_ARB* = 0x8DDA
  RELATIVE_SMOOTH_QUADRATIC_CURVE_TO_NV* = 0x0F
  OP_INDEX_EXT* = 0x8782
  REG_1_ATI* = 0x8922
  OFFSET* = 0x92FC
  cPATH_COVER_DEPTH_FUNC_NV* = 0x90BF
  UNPACK_COMPRESSED_BLOCK_DEPTH* = 0x9129
  POLYGON_OFFSET_UNITS* = 0x2A00
  INDEX_TEST_FUNC_EXT* = 0x81B6
  POINT_SMOOTH* = 0x0B10
  SCALEBIAS_HINT_SGIX* = 0x8322
  COMPRESSED_RGBA_ASTC_5x4_KHR* = 0x93B1
  SEPARATE_SPECULAR_COLOR* = 0x81FA
  VERTEX_ATTRIB_ARRAY14_NV* = 0x865E
  INTENSITY16_EXT* = 0x804D
  R8_SNORM* = 0x8F94
  DEBUG_LOGGED_MESSAGES* = 0x9145
  ALPHA8I_EXT* = 0x8D90
  OPERAND2_RGB* = 0x8592
  EMBOSS_LIGHT_NV* = 0x855D
  EDGE_FLAG_ARRAY_STRIDE_EXT* = 0x808C
  VERTEX_ATTRIB_ARRAY_INTEGER_NV* = 0x88FD
  NUM_LOOPBACK_COMPONENTS_ATI* = 0x8974
  DEBUG_SOURCE_APPLICATION_KHR* = 0x824A
  COMPRESSED_RGB_S3TC_DXT1_EXT* = 0x83F0
  DEBUG_SOURCE_OTHER_ARB* = 0x824B
  cDOUBLE* = 0x140A
  STENCIL_TEST_TWO_SIDE_EXT* = 0x8910
  MIN_PROGRAM_TEXEL_OFFSET* = 0x8904
  c3DC_X_AMD* = 0x87F9
  FLOAT_RGB32_NV* = 0x8889
  SECONDARY_COLOR_ARRAY_POINTER_EXT* = 0x845D
  OPERAND2_ALPHA_ARB* = 0x859A
  IMAGE_3D* = 0x904E
  SECONDARY_COLOR_ARRAY_SIZE* = 0x845A
  RELEASED_APPLE* = 0x8A19
  RENDER_DIRECT_TO_FRAMEBUFFER_QCOM* = 0x8FB3
  FRAMEBUFFER_DEFAULT_LAYERS* = 0x9312
  INTENSITY* = 0x8049
  RENDERBUFFER_BLUE_SIZE_OES* = 0x8D52
  FLOAT_RGB_NV* = 0x8882
  ARRAY_ELEMENT_LOCK_FIRST_EXT* = 0x81A8
  CON_4_ATI* = 0x8945
  ROUND_NV* = 0x90A4
  CLIP_DISTANCE2* = 0x3002
  MAX_PROGRAM_ALU_INSTRUCTIONS_ARB* = 0x880B
  PROGRAM_ERROR_STRING_ARB* = 0x8874
  STORAGE_CACHED_APPLE* = 0x85BE
  LIGHTEN_NV* = 0x9298
  TEXTURE23* = 0x84D7
  SAMPLER_CUBE_SHADOW* = 0x8DC5
  VERTEX_PROGRAM_ARB* = 0x8620
  COMPRESSED_SRGB_ALPHA_S3TC_DXT3_EXT* = 0x8C4E
  TEXTURE_CUBE_MAP_NEGATIVE_Z_ARB* = 0x851A
  RENDERBUFFER_SAMPLES* = 0x8CAB
  RENDERBUFFER_STENCIL_SIZE* = 0x8D55
  VIRTUAL_PAGE_SIZE_INDEX_ARB* = 0x91A7
  CLIP_PLANE5* = 0x3005
  VERTEX_WEIGHT_ARRAY_POINTER_EXT* = 0x8510
  COLOR_BUFFER_BIT5_QCOM* = 0x00000020
  DOUBLE_MAT2x3_EXT* = 0x8F49
  UNIFORM_BLOCK_ACTIVE_UNIFORMS* = 0x8A42
  COLOR_ATTACHMENT8_EXT* = 0x8CE8
  UNIFORM_BUFFER_BINDING_EXT* = 0x8DEF
  MATRIX8_ARB* = 0x88C8
  COUNTER_TYPE_AMD* = 0x8BC0
  INT8_VEC3_NV* = 0x8FE2
  TEXTURE_BINDING_3D_OES* = 0x806A
  DEPTH_PASS_INSTRUMENT_COUNTERS_SGIX* = 0x8311
  IMAGE_BINDING_LEVEL* = 0x8F3B
  STENCIL_BACK_FAIL_ATI* = 0x8801
  cTRANSFORM_FEEDBACK_ATTRIBS_NV* = 0x8C7E
  COLOR_TABLE_INTENSITY_SIZE* = 0x80DF
  TEXTURE_2D_BINDING_EXT* = 0x8069
  CW* = 0x0900
  COLOR_ATTACHMENT6* = 0x8CE6
  R32UI* = 0x8236
  PROXY_TEXTURE_3D* = 0x8070
  FLOAT_VEC2_ARB* = 0x8B50
  C3F_V3F* = 0x2A24
  MAX_PROGRAM_PARAMETER_BUFFER_BINDINGS_NV* = 0x8DA0
  EVAL_VERTEX_ATTRIB11_NV* = 0x86D1
  MAX_VERTEX_ARRAY_RANGE_ELEMENT_NV* = 0x8520
  FRAMEBUFFER_INCOMPLETE_READ_BUFFER_OES* = 0x8CDC
  MAX_VIEWPORT_DIMS* = 0x0D3A
  STENCIL_CLEAR_TAG_VALUE_EXT* = 0x88F3
  TEXTURE_BUFFER_FORMAT_ARB* = 0x8C2E
  PROGRAM_NATIVE_PARAMETERS_ARB* = 0x88AA
  FLOAT_MAT3x2* = 0x8B67
  BLUE_BIT_ATI* = 0x00000004
  COLOR_ATTACHMENT6_NV* = 0x8CE6
  AND_INVERTED* = 0x1504
  MAX_GEOMETRY_SHADER_STORAGE_BLOCKS* = 0x90D7
  COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR* = 0x93D0
  PACK_COMPRESSED_BLOCK_DEPTH* = 0x912D
  TEXTURE_COMPARE_SGIX* = 0x819A
  SYNC_CL_EVENT_COMPLETE_ARB* = 0x8241
  DEBUG_TYPE_PORTABILITY* = 0x824F
  IMAGE_BINDING_FORMAT* = 0x906E
  RESAMPLE_DECIMATE_OML* = 0x8989
  MAX_PROGRAM_TEMPORARIES_ARB* = 0x88A5
  ALL_SHADER_BITS* = 0xFFFFFFFF
  TRANSFORM_FEEDBACK_VARYING* = 0x92F4
  TRANSFORM_FEEDBACK_BUFFER_BINDING* = 0x8C8F
  cACTIVE_STENCIL_FACE_EXT* = 0x8911
  MAP1_VERTEX_ATTRIB4_4_NV* = 0x8664
  LINK_STATUS* = 0x8B82
  SYNC_FLUSH_COMMANDS_BIT* = 0x00000001
  BLEND* = 0x0BE2
  OUTPUT_TEXTURE_COORD12_EXT* = 0x87A9
  DRAW_BUFFER11_ARB* = 0x8830
  OBJECT_BUFFER_USAGE_ATI* = 0x8765
  COLORDODGE_NV* = 0x9299
  SHADER_IMAGE_LOAD* = 0x82A4
  EMBOSS_CONSTANT_NV* = 0x855E
  MAP_TESSELLATION_NV* = 0x86C2
  MAX_DRAW_BUFFERS_EXT* = 0x8824
  VERTEX_WEIGHT_ARRAY_TYPE_EXT* = 0x850E
  TEXTURE_ENV_COLOR* = 0x2201
  UNIFORM_BLOCK_REFERENCED_BY_FRAGMENT_SHADER* = 0x8A46
  DOT_PRODUCT_REFLECT_CUBE_MAP_NV* = 0x86F2
  QUERY_KHR* = 0x82E3
  RG* = 0x8227
  MAX_TEXTURE_SIZE* = 0x0D33
  TEXTURE_NUM_LEVELS_QCOM* = 0x8BD9
  MAP2_VERTEX_ATTRIB3_4_NV* = 0x8673
  LUMINANCE_FLOAT32_APPLE* = 0x8818
  MAP2_VERTEX_ATTRIB7_4_NV* = 0x8677
  GEOMETRY_SHADER_ARB* = 0x8DD9
  SYNC_FENCE_APPLE* = 0x9116
  SAMPLE_MASK_VALUE* = 0x8E52
  PROXY_TEXTURE_RECTANGLE_NV* = 0x84F7
  cDEPTH_FUNC* = 0x0B74
  S* = 0x2000
  CONSTANT_COLOR_EXT* = 0x8001
  MAX_PROGRAM_LOOP_COUNT_NV* = 0x88F8
  VIEW_COMPATIBILITY_CLASS* = 0x82B6
  INT_SAMPLER_BUFFER_AMD* = 0x9002
  COMPRESSED_SRGB* = 0x8C48
  PROGRAM_SEPARABLE_EXT* = 0x8258
  FOG_FUNC_POINTS_SGIS* = 0x812B
  MITER_TRUNCATE_NV* = 0x90A8
  POLYGON_OFFSET_POINT* = 0x2A01
  SRGB_READ* = 0x8297
  INDEX_ARRAY_ADDRESS_NV* = 0x8F24
  MAX_FRAMEBUFFER_WIDTH* = 0x9315
  COMPRESSED_RED_RGTC1_EXT* = 0x8DBB
  RGB_INTEGER_EXT* = 0x8D98
  OP_NEGATE_EXT* = 0x8783
  POINT_SIZE_MAX_ARB* = 0x8127
  TEXTURE_DEFORMATION_BIT_SGIX* = 0x00000001
  SIGNED_LUMINANCE8_NV* = 0x8702
  OPERAND2_RGB_EXT* = 0x8592
  MAX_PIXEL_TRANSFORM_2D_STACK_DEPTH_EXT* = 0x8337
  RECIP_ADD_SIGNED_ALPHA_IMG* = 0x8C05
  VERTEX_STREAM7_ATI* = 0x8773
  MODELVIEW1_STACK_DEPTH_EXT* = 0x8502
  DYNAMIC_DRAW* = 0x88E8
  DRAW_BUFFER15_EXT* = 0x8834
  TEXTURE_COMPARE_OPERATOR_SGIX* = 0x819B
  SQUARE_NV* = 0x90A3
  COMPRESSED_SRGB_S3TC_DXT1_EXT* = 0x8C4C
  DRAW_BUFFER0_ARB* = 0x8825
  GPU_OPTIMIZED_QCOM* = 0x8FB2
  VERTEX_WEIGHT_ARRAY_STRIDE_EXT* = 0x850F
  SPRITE_EYE_ALIGNED_SGIX* = 0x814E
  MAP1_VERTEX_ATTRIB3_4_NV* = 0x8663
  cSAMPLE_MASK_SGIS* = 0x80A0
  TEXTURE_SAMPLES* = 0x9106
  AND_REVERSE* = 0x1502
  COMBINER4_NV* = 0x8554
  FONT_Y_MIN_BOUNDS_BIT_NV* = 0x00020000
  VIEW_CLASS_32_BITS* = 0x82C8
  BGRA_EXT* = 0x80E1
  TANGENT_ARRAY_TYPE_EXT* = 0x843E
  BLEND_EQUATION_RGB_OES* = 0x8009
  TRANSPOSE_TEXTURE_MATRIX_ARB* = 0x84E5
  GET_TEXTURE_IMAGE_FORMAT* = 0x8291
  PACK_MAX_COMPRESSED_SIZE_SGIX* = 0x831B
  UNIFORM_ARRAY_STRIDE* = 0x8A3C
  REFLECTION_MAP_ARB* = 0x8512
  RGBA_FLOAT16_ATI* = 0x881A
  MAX_TESS_CONTROL_OUTPUT_COMPONENTS* = 0x8E83
  RED_BITS* = 0x0D52
  VERTEX_TEXTURE* = 0x829B
  UNSIGNALED_APPLE* = 0x9118
  RENDERBUFFER_ALPHA_SIZE_OES* = 0x8D53
  DRAW_BUFFER14_NV* = 0x8833
  STREAM_COPY_ARB* = 0x88E2
  SECONDARY_COLOR_ARRAY_TYPE* = 0x845B
  MATRIX22_ARB* = 0x88D6
  VERTEX_ARRAY_RANGE_WITHOUT_FLUSH_NV* = 0x8533
  IUI_N3F_V3F_EXT* = 0x81B0
  SPARE0_NV* = 0x852E
  FOG_COORD* = 0x8451
  DRAW_BUFFER8_ARB* = 0x882D
  MATRIX24_ARB* = 0x88D8
  MAX_DEBUG_MESSAGE_LENGTH_AMD* = 0x9143
  POST_COLOR_MATRIX_BLUE_SCALE* = 0x80B6
  TEXTURE_HEIGHT_QCOM* = 0x8BD3
  NUM_FRAGMENT_REGISTERS_ATI* = 0x896E
  IMAGE_3D_EXT* = 0x904E
  TEXTURE_FILTER_CONTROL* = 0x8500
  VIDEO_BUFFER_NV* = 0x9020
  CURRENT_MATRIX_INDEX_ARB* = 0x8845
  STENCIL_BUFFER_BIT4_QCOM* = 0x00100000
  SIGNED_INTENSITY_NV* = 0x8707
  RASTERIZER_DISCARD_NV* = 0x8C89
  MAX_DEFORMATION_ORDER_SGIX* = 0x8197
  SAMPLES_3DFX* = 0x86B4
  DOT_PRODUCT_PASS_THROUGH_NV* = 0x885B
  RGB_SCALE_EXT* = 0x8573
  TEXTURE_UNSIGNED_REMAP_MODE_NV* = 0x888F
  MIRROR_CLAMP_TO_EDGE_EXT* = 0x8743
  NATIVE_GRAPHICS_END_HINT_PGI* = 0x1A204
  UNPACK_CLIENT_STORAGE_APPLE* = 0x85B2
  FRAMEBUFFER_INCOMPLETE_READ_BUFFER* = 0x8CDC
  FOG_START* = 0x0B63
  MAX_PROGRAM_CALL_DEPTH_NV* = 0x88F5
  MODELVIEW18_ARB* = 0x8732
  MAX_FRAMEZOOM_FACTOR_SGIX* = 0x818D
  EDGE_FLAG_ARRAY_POINTER* = 0x8093
  GREEN_INTEGER* = 0x8D95
  IMAGE_BUFFER* = 0x9051
  PROJECTION* = 0x1701
  UNSIGNED_INT_VEC4_EXT* = 0x8DC8
  PALETTE8_RGB5_A1_OES* = 0x8B99
  RENDERBUFFER_SAMPLES_EXT* = 0x8CAB
  TEXTURE3* = 0x84C3
  CURRENT_RASTER_INDEX* = 0x0B05
  INTERLEAVED_ATTRIBS_EXT* = 0x8C8C
  STENCIL_BACK_WRITEMASK* = 0x8CA5
  POINT_SPRITE_ARB* = 0x8861
  TRANSPOSE_TEXTURE_MATRIX* = 0x84E5
  DRAW_BUFFER1_ARB* = 0x8826
  MAX_FRAGMENT_ATOMIC_COUNTER_BUFFERS* = 0x92D0
  DEPTH_ATTACHMENT_OES* = 0x8D00
  COMPRESSED_RGBA_PVRTC_2BPPV2_IMG* = 0x9137
  SRGB_ALPHA* = 0x8C42
  UNSIGNED_INT64_ARB* = 0x140F
  LAST_VERTEX_CONVENTION_EXT* = 0x8E4E
  IMAGE_CLASS_1_X_8* = 0x82C1
  COMPRESSED_RGBA_S3TC_DXT1_EXT* = 0x83F1
  REFLECTION_MAP* = 0x8512
  MAX_IMAGE_UNITS_EXT* = 0x8F38
  DEPTH_STENCIL_NV* = 0x84F9
  PROGRAM_TEX_INDIRECTIONS_ARB* = 0x8807
  BINNING_CONTROL_HINT_QCOM* = 0x8FB0
  T4F_V4F* = 0x2A28
  FLOAT_VEC4* = 0x8B52
  CONVEX_HULL_NV* = 0x908B
  TEXTURE26_ARB* = 0x84DA
  INDEX_BIT_PGI* = 0x00080000
  TEXTURE_COORD_ARRAY_TYPE_EXT* = 0x8089
  FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL_OES* = 0x8CD2
  MAX_ARRAY_TEXTURE_LAYERS* = 0x88FF
  COLOR_ATTACHMENT4_EXT* = 0x8CE4
  SAMPLE_COVERAGE_VALUE_ARB* = 0x80AA
  VERTEX_ATTRIB_MAP2_ORDER_APPLE* = 0x8A08
  MAX_LAYERS* = 0x8281
  FOG_COORDINATE_ARRAY_POINTER_EXT* = 0x8456
  INDEX_TEST_REF_EXT* = 0x81B7
  GREEN_BIT_ATI* = 0x00000002
  STRICT_SCISSOR_HINT_PGI* = 0x1A218
  MAP2_VERTEX_ATTRIB4_4_NV* = 0x8674
  MAX_GEOMETRY_OUTPUT_VERTICES_EXT* = 0x8DE0
  OUTPUT_TEXTURE_COORD31_EXT* = 0x87BC
  XOR* = 0x1506
  VIDEO_CAPTURE_FRAME_WIDTH_NV* = 0x9038
  RGBA* = 0x1908
