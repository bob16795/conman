import 
  x11/[xlib, x, xrender],
  fontconfig, unicode

type
  TXftDraw = object
  PXftDraw = ptr TXftDraw
  PXftFont = ptr TXftFont
  TXftFont = object
    ascent, descent: cint
    height, max_advance_width: cint
    charset: ptr TFcCharSet
    pattern: PFcPattern 
  PCur* = ptr Cur
  Cur* = object
    cursor*: TCursor
  PClr* = PXColor
  Clr* = TXColor
  Drw* = object
    w, h: cuint
    dpy: PDisplay
    screen: cint
    root: TWindow
    drawable: TDrawable
    gc*: TGC
    scheme: seq[PClr]
    fonts*: seq[PFnt]
  PDrw* = ptr Drw
  Fnt* = object
    xfont*: PXftFont
    dpy*: PDisplay
    h*: uint
    pattern*: PFcPattern
  PFnt* = ptr Fnt

const
  SchemeNorm* = 0
  SchemeSel* = 1

  ColFg* = 2
  ColBg* = 1
  ColBorder* = 0

const
  libXft = "libXft.so(.2|)"


proc XftColorAllocName(dpy: PDisplay, v: PVisual, c: TColorMap, clrname: cstring, dest: PClr): cint {.cdecl, dynlib: libXft, importc.}
proc XftFontOpenName(dpy: PDisplay, screen: cint, arg1: cstring): PXftFont {.cdecl, dynlib: libXft, importc.} 
proc XftFontOpenPattern(dpy: PDisplay, arg1: PFcPattern): PXftFont {.cdecl, dynlib: libXft, importc.} 
proc XftFontClose(dpy: PDisplay, font: PXftFont) {.cdecl, dynlib: libXft, importc.} 
proc XftFontMatch(dpy: PDisplay, screen: cint, pattern: PFcPattern, result: ptr TFcResult): PFcPattern{.cdecl, dynlib: libXft, importc.} 
proc XftCharExists(dpy: PDisplay, font: PXftFont, c: TFcChar32): TFcBool {.cdecl, dynlib: libXft, importc.} 
proc XftDrawCreate(dpy: PDisplay, d: TDrawable, v: PVisual, c: TColorMap): PXftDraw {.cdecl, dynlib: libXft, importc.} 
proc XftDrawDestroy(drw: PXftDraw) {.cdecl, dynlib: libXft, importc.} 
proc XftTextExtentsUtf8(dpy: PDisplay, font: PXftFont, arg1: cstring, l: cint, e: PXGlyphInfo): cint {.cdecl, dynlib: libXft, importc.} 
proc XftDrawStringUtf8(d: PXftDraw, col: PClr, font: PXftFont, x, y: cint, buf: cstring, l: csize_t) {.cdecl, dynlib: libXft, importc.} 

proc die(msg: cstring) =
  stderr.write(msg)
  quit 0

# proc utf8decodebyte(c: char, i: ptr csize_t): clong = 
#   i[] = 0
#   while i[] < (UTF_SIZ + 1):
#     if (cast[cuchar](c) and utfmask[i[]]) == utfbyte[i[]]:
#       return (cast[cuchar](c) and not utfmask[i[]]).clong
#     inc((i[]))
#   return 0

# proc utf8validate(u: ptr clong, i: csize_t): csize_t =
#   var ni = i
#   if (not(BETWEEN(u[], utfmin[ni], utfmax[ni]))):
#     u[] = UTF_INVALID
#   ni = 1
#   while u[] > utfmax[ni]:
#     inc(ni)
#   return ni.csize_t

# proc utf8decode(c: cstring, u: ptr clong, clen: csize_t): csize_t =
#   var i, j, l, t: csize_t
#   var udecoded: clong
#   u[] = UTF_INVALID

#   if clen == 0:
#     return 0
#   udecoded = utf8decodebyte(c[0], addr l)
#   if (not BETWEEN(l, 1, UTF_SIZ)):
#     return 1
#   i = 1
#   j = 1
#   while i < clen and j < l:
#     udecoded = (udecoded shl 6) or utf8decodebyte(c[i], addr t)
#     if t != 0:
#       return j
#     inc(i)
#     inc(j)
#   if (j < l):
#     return 0
#   u[] = udecoded
#   discard utf8validate(u, l)

#   return l

proc xfont_free(font: PFnt) =
  if (font == nil):
    return
  if (font.pattern != nil):
    FcPatternDestroy(font.pattern);
  XftFontClose(font.dpy, font.xfont);

proc xfont_create(drw: PDrw, fontname: ptr cstring, fontpattern: PFcPattern): PFnt =
  var font: PFnt
  var xfont: PXftFont = nil
  var pattern: PFcPattern = nil
  if fontname != nil:
    xfont = XftFontOpenName(drw.dpy, drw.screen, fontname[])
    if xfont == nil:
      return
    var name: ptr TFcChar8
    {.emit: ["name = (", TFcChar8, " *) ", fontname, ";"].}
    pattern = FcNameParse(name)
    if pattern == nil:
      XftFontClose(drw.dpy, xfont);
      return
  elif fontpattern != nil:
    xfont = XftFontOpenPattern(drw.dpy, fontpattern)
    if xfont == nil:
      return
  else:
    die("no font specified.")
  font = cast[PFnt](alloc(sizeof(Fnt)))
  font.xfont = xfont
  font.pattern = pattern
  font.h = (xfont.ascent + xfont.descent).uint
  font.dpy = drw.dpy
  return font


proc drw_create*(dpy: PDisplay, screen: cint, root: TWindow, w, h: cuint): PDrw =
  var drw = cast[ptr Drw](alloc(sizeof(Drw)))

  drw.dpy = dpy
  drw.screen = screen
  drw.root = root
  drw.w = w
  drw.h = h
  drw.drawable = XCreatePixmap(dpy, root, w, h, DefaultDepth(dpy, screen).cuint)
  drw.gc = XCreateGC(dpy, root, 0, nil)
  discard XSetLineAttributes(dpy, drw.gc, 1, LineSolid, CapButt, JoinMiter)

  return drw

proc drw_resize*(drw: PDrw, w, h: cuint) =
  if drw == nil:
    return

  drw.w = w
  drw.h = h
  discard XFreePixmap(drw.dpy, drw.drawable);
  drw.drawable = XCreatePixmap(drw.dpy, drw.root, w, h, DefaultDepth(drw.dpy, drw.screen).cuint)

proc drw_free*(drw: PDrw) =
  discard XFreePixmap(drw.dpy, drw.drawable);
  discard XFreeGC(drw.dpy, drw.gc);
  #dealloc(drw)

proc drw_clr_create*(drw: PDrw, clrname: string): TXColor =
  if (drw == nil) or (clrname == ""):
    return
  var lol: Clr
  var res: cint
  #res = xallocnamedcolor(drw.dpy, DefaultColormap(drw.dpy, drw.screen),
  #                                clrname, addr lol, addr nop)\
  res = XftColorAllocName(drw.dpy, DefaultVisual(drw.dpy, drw.screen),
                          DefaultColormap(drw.dpy, drw.screen), clrname, addr lol)
  if (0 == res):
    die("error, cannot allocate color '" & clrname & "'")
  return lol

proc drw_scm_create*(drw: PDrw, clrnames: array[0..2, string]): seq[PClr]=
  var ret: seq[PClr]

  if (drw == nil):
    return
  for i in 0..<len(clrnames):
     ret.add(cast[PXColor](alloc(sizeof(TXcolor))))
     ret[i][] = drw_clr_create(drw, clrnames[i])
  return ret

proc drw_cur_create*(drw: PDrw, shape: cuint): PCur =
  var cur: PCur
  cur = cast[PCur](alloc(sizeof(Cur)))
  if (drw == nil):
    return

  cur.cursor = XCreateFontCursor(drw.dpy, shape)

  return cur


proc drw_fontset_create*(drw: PDrw, fonts: var seq[cstring]): seq[PFnt] =
  var cur: PFnt
  var ret: seq[PFnt]

  if (drw == nil):
    return
  if drw.fonts != []:
    return

  for i in 0..high(fonts):
      cur = xfont_create(drw, addr fonts[high(fonts) - i], nil)
      if (cur != nil):
        ret.add(cur)
  drw.fonts = ret
  return ret

proc drw_font_getexts(font: PFnt, text: cstring, l: cint , w, h: ptr cint) =
  var ext: TXGlyphInfo

  if (font == nil) or (text == ""):
    return

  discard XftTextExtentsUtf8(font.dpy, font.xfont, text, l, addr ext);
  if (w != nil):
    w[] = ext.xOff
  if (h != nil):
    h[] = font.h.cint

proc drw_text*(drw: PDrw, x, y: cint, w, h, lpad: cuint, text: cstring, invert: bool): cuint =
  var t = text
  var buf: cstring
  var ty: int
  var ew: cint
  var d: PXftDraw
  var usedfont, nextfont: PFnt
  var l: csize_t
  var utf8strlen: cint
  var utf8charlen: cint
  var render: cuint = x.cuint or y.cuint or w or h
  var utf8codepoint: clong = 0
  var utf8str: cstring
  var fccharset: ptr TFcCharSet
  var fcpattern, match: PFcPattern
  var res: TFcResult
  var charexists: bool = false
  if (drw == nil) or (render != 0 and drw.scheme == @[]) or (t == "") or (drw.fonts == @[]):
    return 0
  var nw: cuint = w.cuint
  var nx: cint = x
  if render == 0:
    nw = not nw
  else:
    if invert:
      discard XSetForeground(drw.dpy, drw.gc, drw.scheme[ColFg].pixel)
    else:
      discard XSetForeground(drw.dpy, drw.gc, drw.scheme[ColBg].pixel)
    discard XFillRectangle(drw.dpy, drw.drawable, drw.gc, x, y, w.cuint, h.cuint)
    d = XftDrawCreate(drw.dpy, drw.drawable,
                      DefaultVisual(drw.dpy, drw.screen),
                      DefaultColormap(drw.dpy, drw.screen))
    nx += lpad.cint
    nw -= lpad
  usedfont = drw.fonts[0]
  while true:
    utf8strlen = 0
    utf8str = t
    nextfont = nil
    while t != "":
      #utf8charlen = utf8decode(t, addr utf8codepoint, UTF_SIZ).cint
      utf8codepoint = runeat($t, 0).clong
      utf8charlen = graphemeLen($t, 0).cint
      for curfont in drw.fonts:
        charexists = charexists or XftCharExists(drw.dpy, curfont.xfont, utf8codepoint.cuint) == 1
        if charexists:
          if curfont == usedfont:
            utf8strlen += utf8charlen
            t = ($t)[utf8charlen..^1].cstring
          else:
            nextfont = curfont
          break
      if (not charexists) or (nextfont != nil):
        break
      else:
        charexists = false
    if utf8strlen != 0:
      drw_font_getexts(usedfont, utf8str, utf8strlen, addr ew, nil)
      # shorten text if necessary
      l = utf8strlen.csize_t
      while l != 0 and ew.cuint > nw:
        drw_font_getexts(usedfont, utf8str, l.cint, addr ew, nil);
        l -= 1
      if (l != 0):
        buf = utf8str
        # if (l < utf8strlen.csize_t):
        #   buf.add("" * )
        if (render != 0):
          ty = y + ((h - usedfont.h).int / 2).cint + usedfont.xfont.ascent
          var col = ColFg
          if invert:
            col = ColBg
          XftDrawStringUtf8(d, drw.scheme[col],
                            usedfont.xfont, nx, ty.cint, buf, l)
        nx += ew
        nw -= ew.cuint
    if t == "":
      break
    elif (nextfont != nil):
      charexists = false
      usedfont = nextfont
    else:
      charexists = true
      fccharset = FcCharSetCreate()
      discard FcCharSetAddChar(fccharset, utf8codepoint.cuint);
      if (drw.fonts[0].pattern == nil):
        die("the first font in the cache must be loaded from a font string.");

      fcpattern = FcPatternDuplicate(drw.fonts[0].pattern);
      discard FcPatternAddCharSet(fcpattern, FC_CHARSET, fccharset);
      discard FcPatternAddBool(fcpattern, FC_SCALABLE, FcTrue)
      # discard FcPatternAddBool(fcpattern, FC_COLOR, FcFalse)

      #discard FcConfigSubstitute(nil, fcpattern, FcMatchPattern)
      FcDefaultSubstitute(fcpattern)
      match = XftFontMatch(drw.dpy, drw.screen, fcpattern, addr res)
      FcCharSetDestroy(fccharset)
      FcPatternDestroy(fcpattern)

      if match != nil:
        usedfont = xfont_create(drw, nil, match)
        if (usedfont != nil) and 0 != XftCharExists(drw.dpy, usedfont.xfont, utf8codepoint.cuint):
          drw.fonts.add(usedfont)
        else:
          xfont_free(usedfont)
          usedfont = drw.fonts[0]
  if (d != nil):
    XftDrawDestroy(d)
  if render != 0:
    return (nx.clong + nw.clong).cuint
  return nx.cuint

proc drw_fontset_getwidth*(drw: PDrw, text: cstring): cuint =
  if (drw == nil) or (drw.fonts == @[]):
    return 0
  return drw_text(drw, 0, 0, 0, 0, 0, text, false)

proc drw_map*(drw: PDrw, win: TWindow, x, y: cint, w, h: cuint) =
  if drw == nil:
    return
  discard XCopyArea(drw.dpy, drw.drawable, cast[TDrawable](win), drw.gc, x, y, w, h, x, y)
  discard XSync(drw.dpy, false.TBool)

proc drw_setscheme*(drw: PDrw, scm: seq[PClr]) =
  if drw != nil:
    drw.scheme = scm

proc drw_rect*(drw: PDrw, x, y: cint, w, h: cuint, filled, invert, border: bool) =
  if (drw == nil) or (drw.scheme == []):
    return
  if invert:
    discard XSetForeground(drw.dpy, drw.gc, drw.scheme[ColFg].pixel)
  else:
    discard XSetForeground(drw.dpy, drw.gc, drw.scheme[ColBg].pixel)
  if border:
    discard XSetForeground(drw.dpy, drw.gc, drw.scheme[ColBorder].pixel)
  if (filled):
    discard XFillRectangle(drw.dpy, drw.drawable, drw.gc, x, y, w, h);
  else:
    discard XDrawRectangle(drw.dpy, drw.drawable, drw.gc, x, y, w - 1, h - 1)
