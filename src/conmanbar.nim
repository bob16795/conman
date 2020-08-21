import
  x11/[xlib, xutil, x, keysym, xatom, xinerama, cursorfont, xresource],
  osproc, posix, tables, draw, strutils, algorithm, times, ipc

template INTERSECT(v, x,y,w,h,m) =
  v = (max(0, min((x)+(w),(m).wx+(m).ww) - max((x),(m).wx)) * max(0, min((y)+(h),(m).wy+(m).wh) - max((y),(m).wy)))

template TEXTW(X): untyped =
  drw_fontset_getwidth(drw, (X))

template WIDTH(X): untyped =
  X.w + 2 * X.bw

template HEIGHT(X): untyped =
  X.h + 2 * X.bw

template doWhile(a, b: untyped): untyped =
  b
  while a:
    b

template XRDB_LOAD_COLOR(R,V): untyped =
  if XrmGetResource(xrdb, R, nil, addr t, addr value) == true.TBool:
    var strvalue: cstring = V[]
    {.emit: ["""if (strnlen(""", value.address, """, 8) == 7) {
                  strncpy(""",strvalue,""", """, value.address, """, 7);
              """, strvalue, "[7] = '\0';}"]}
    var broken = false
    if (value.address != nil and strvalue.len == 7) and strvalue[0] == '#':
      for i in 1..6:
        if not(strvalue[i] in "1234567890abcdefABCDEF"):
          broken = true
          break
      if not broken:
        V[] = $strvalue


const
  EXIT_FAILURE = 0
  BUTTONMASK = (ButtonPressMask or ButtonReleaseMask)
  MOUSEMASK = (BUTTONMASK or PointerMotionMask)

type
  xcb_connection_t {.importc: "xcb_connection_t", header: "<xcb/res.h>".} = object
  xcb_res_client_id_spec_t {.importc: "xcb_res_client_id_spec_t", header: "<xcb/res.h>".} = object
    client: TWindow
    mask: culong
  xcb_generic_error_t = object
  xcb_res_query_client_ids_cookie_t {.importc: "xcb_res_query_client_ids_cookie_t", header: "<xcb/res.h>".} = object
  xcb_res_query_client_ids_reply_t {.importc: "xcb_res_query_client_ids_reply_t", header: "<xcb/res.h>".} = object
  xcb_res_client_id_value_iterator_t {.importc: "xcb_res_client_id_value_iterator_t", header: "<xcb/res.h>".} = object
    rem: cint
    data: ptr xcb_res_client_id_value_t
  xcb_res_client_id_value_t {.importc: "xcb_res_client_id_value_t", header: "<xcb/res.h>".} = object
    spec: xcb_res_client_id_spec_t
  Client = object
    x, y, w, h, bw: cint
    oldx, oldy, oldw, oldh, oldbw: int
    basew, baseh, incw, inch, maxw, maxh, minw, minh: cint
    mina, maxa: float
    neverfocus: bool
    isurgent, isfullscreen, isfloating: bool
    isfixed: bool
    lockname: bool
    container: int
    title: string
    name, realname, icon: string
    pid: cint
    noswallow: int
    swallowing: PClient
    isterm: bool
    win, framewin: TWindow
    mon: PMonitor
    con: PContainer
    mapped, oldstate: bool
  Statusblock = object
    command: string
    icon: bool
  PSystray = ptr Systray
  Systray = object
    win: TWindow
    icons: seq[PClient]
  PClient = ptr Client
  Container = object
    num: int
    cx, cy, cw, ch: cint
    clients: seq[PClient]
    isframe: bool
  PContainer = ptr Container
  Monitor = object
    hsplit, vsplit: cint
    mx, my, mw, mh: cint
    wx, wy, ww, wh: cint
    by: cint
    num: cint
    sel: PClient
    clients: seq[PClient]
    containers: array[0..3, PContainer]
    barwin: TWindow
    showbar: bool
    igappsena, ogappsena: bool
    igapps, ogapps: cint
  Rule = object
    title, class, instance: string
    settitle: string
    container: int
    icon: string
    noswallow: int
    isterm: bool
  PMonitor = ptr Monitor
  Arg = object
    v: seq[string]
    i: int
  Pk = object
    p: proc(a: Arg)
  Pe = object
    p: proc(ev: TXEvent)
  cursors = enum
    CurNormal, CurResize,
    CurMove, CurLast
  wmatome = enum
    WMProtocols,
    WMDelete,
    WMState,
    WMTakeFocus,
    WMLast
  netatome = enum
    NetSupported, NetWMName, NetWMState, NetWMCheck,
    NetSystemTray, NetSystemTrayOP, NetSystemTrayOrientation, NetSystemTrayOrientationHorz,
    NetWMFullscreen, NetActiveWindow, NetWMWindowType,
    NetWMWindowTypeDialog, NetClientList, NetDesktopNames, NetDesktopViewport, NetNumberOfDesktops, NetCurrentDesktop, NetLast
    Manager, Xembed, XembedInfo, XLast
  ButtonPressType = enum
    ClkRootWin
    ClkClientWin
    ClkLtSymbol
    ClkStatusTextR
    ClkStatusTextL
    ClkSystray
    ClkWinTitle

proc `%`(x, y: cint): cint
proc applyrules(c: PClient)
proc applysizehints(c: PClient, x, y, w, h: ptr cint, interact: bool): bool
proc arrange(m: PMonitor)
proc buttonpress(ev: TXEvent)
proc center(A: Arg)
proc center(c: PClient)
proc checkotherwm(dpy: PDisplay)
proc clickbarl(a: Arg)
proc clickbarr(a: Arg)
proc clientmessage(ev: TXEvent)
proc configure(c: PClient)
proc configurerequest(ev: TXEvent)
proc configurenotify(ev: TXEvent)
proc createmon(): PMonitor
proc cyclefocus(a: Arg)
proc destroynotify(ev: TXEvent)
proc die(msg: cstring)
proc drawframe(c: PClient)
proc enternotify(ev: TXEvent)
proc expose(ev: TXEvent)
proc focus(a: Arg)
proc focus(cli: PClient)
proc focusin(ev: TXEvent)
proc frame(c: PClient)
proc getatomprop(c: PCLient, prop: TAtom): TAtom
proc getparentprocess(p: cint): cint
proc getlayoutname(m: PMonitor): string
proc getstatus(): string
proc getsystraywidth(): uint
proc gettitle(m: PMonitor): string
proc gettextprop(w: TWindow, atom: TAtom): string
proc grabbuttons(c: PClient, focused: bool)
proc grabkeys()
proc isdescprocess(p, c: cint): cint
proc isuniquegeom(unique: PXineramaScreenInfo, n: cuint, info: PXineramaScreenInfo): bool
proc keypress(ev: TXEvent)
proc killclient(a: Arg)
proc killwm(a: Arg)
proc loadxrdb()
proc main()
proc manage(w: TWindow, wa: TXWindowAttributes)
proc mappingnotify(ev: TXEvent)
proc maprequest(ev: TXEvent)
proc motionnotify(ev: TXEvent)
proc movemouse(a: Arg)
proc movesplith(a: Arg)
proc movesplitv(a: Arg)
proc movetocon(a: Arg)
proc movetocon(c: PClient, connum: int)
proc propertynotify(ev: TXEvent)
proc recttomon(x, y, w, h: cint): PMonitor
proc removesystrayicon(i: PClient)
proc resize(c: PClient, x, y, w, h: cint, move: bool = false)
proc resizebarwin(m: PMonitor)
proc resizeclient(c: PClient, x, y, w, h: cint)
proc resizemouse(a: Arg)
proc resizerequest(ev: TXEvent)
proc restack(m: PMonitor)
proc sendevent(w: TWindow, proto: TAtom, mask: cint, d0, d1, d2, d3, d4: TAtom): bool
proc sendmon(c: PClient, m: PMonitor)
proc setclientstate(c: PClient, state: clong)
proc setdefault(a: Arg)
proc setfocus(c: PClient)
proc setfullscreen(c: PClient, fullscreen: bool)
proc setup()
proc spawn(a: Arg)
proc swallow(p, c: PClient)
proc swallowingclient(w: TWindow): PClient
proc systraytomon(m: PMonitor): PMonitor
proc termforwin(w: PClient): PClient
proc toggleadvancedtitle(arg: Arg)
proc togglebar(arg: Arg)
proc togglefloating(arg: Arg)
proc togglefloating(c: PClient)
proc togglefullscreen(arg: Arg)
proc toggleigapps(arg: Arg)
proc toggleiconl(arg: Arg)
proc toggleiconr(arg: Arg)
proc toggleogapps(arg: Arg)
proc unfocus(c: PClient, setfocus: bool)
proc unframe(c: PClient)
proc unmanage(c: PClient, destroyed: bool)
proc unmapnotify(ev: TXEvent)
proc unswallow(c: PClient)
proc updatebarpos(m: PMonitor)
proc updatebars()
proc updateclientlist()
proc updatecons(m: PMonitor)
proc updateipc()
proc updatenumlockmask()
proc updatesizehints(c: PClient)
proc updatestext(m: PMonitor, force: bool)
proc updatesystray()
proc updatesystrayicongeom(i: PClient, w, h: cint)
proc updatesystrayiconstate(i: PClient, ev: PXPropertyEvent)
proc updatetitle(c: PClient)
proc updatewmhints(c: PClient)
proc updategeom(): bool
proc winpid(w: TWindow): cint
proc wintoclient(w: TWindow): PClient
proc wintomon(w: TWindow): PMonitor
proc wintosystrayicon(w: TWindow): PClient
proc xerror(dpy: PDisplay, ee: PXErrorEvent): cint {.cdecl.}
proc xerrorstart(dpy: PDisplay, ee: PXErrorEvent): cint {.cdecl.}
proc xrdb(a: Arg)

const LIB_XCB = "libxcb-res.so.0.0.0"
{.pragma: xcb, cdecl, dynlib: LIB_XCB.}
proc xcb_res_query_client_ids(con: ptr xcb_connection_t, lol: int, p: ptr xcb_res_client_id_spec_t): xcb_res_query_client_ids_cookie_t {.importc: "xcb_res_query_client_ids", xcb.}
proc xcb_res_query_client_ids_reply(con: ptr xcb_connection_t, lol: xcb_res_query_client_ids_cookie_t, e: ptr xcb_generic_error_t): ptr xcb_res_query_client_ids_reply_t {.importc: "xcb_res_query_client_ids_reply", xcb.}
proc xcb_res_query_client_ids_ids_iterator(r: ptr xcb_res_query_client_ids_reply_t): xcb_res_client_id_value_iterator_t {.importc: "xcb_res_query_client_ids_ids_iterator", xcb.}
proc xcb_res_client_id_value_next(i: ptr xcb_res_client_id_value_iterator_t) {.importc: "xcb_res_client_id_value_next", xcb.}
proc xcb_res_client_id_value_value(i: ptr xcb_res_client_id_value_t): ptr uint32  {.importc: "xcb_res_client_id_value_value", xcb.}
proc XGetXCBConnection(dpy: PDisplay): ptr xcb_connection_t {.importc: "XGetXCBConnection", cdecl, dynlib: "libX11-xcb.so".}

var
  xcon: ptr xcb_connection_t
  ipccommands: Table[string, Pk]
  advancedtitle: bool
  stext: string
  status: array[2, seq[Statusblock]]
  keys: seq[tuple[mods: int, key: TKeySym, call: Pk, args: Arg]]
  buttons: seq[tuple[theType: ButtonPressType, mods: int, button: int, call: Pk, args: Arg]]
  evhandler: Table[int, Pe]
  selmon: PMonitor
  mons: seq[PMonitor]
  drw: PDrw
  dpy = XOpenDisplay(nil)
  ev: TXEvent
  root: TWindow
  screen: cint
  wmatom: Table[wmatome, TAtom]
  netatom: Table[netatome, TAtom]
  vxatom: Table[netatome, TAtom]
  scheme: Table[int, seq[PClr]]
  colors: Table[int, array[0..2, string]]
  bh: cint
  sw, sh: cuint
  cursor: Table[cursors, PCur]
  fonts: seq[cstring]
  frameicons: bool
  onebar: bool
  rules: seq[Rule]
  lastbar = epochTime()
  systray: PSystray = nil
  numlockmask: int

#include "config.nim.old"
include "config.nim"

var
  acsplit: cint = DEFACSPLIT.cint
  absplit: cint = DEFABSPLIT.cint
  bdsplit: cint = DEFBDSPLIT.cint

# error handlers
var oldxerror: proc (dpy: PDisplay, ee: PXErrorEvent): cint {.cdecl.}

proc `%`(x, y: cint): cint =
  if y == 0:
    return 0
  var add = x
  while add < 0:
    add += y
  return add mod (y)

proc applyrules(c: PClient) =
  c.bw = DEFBORDER.cint
  c.noswallow = -1
  c.isfloating = true
  c.icon = ""
  var ch: TXClassHint
  discard XGetClassHint(dpy, c.win, addr ch);
  var class = ch.res_class
  var instance = ch.res_name
  var applyed = false
  for r in rules:
    if (((r.title == "") or (r.title == c.title)) and
        ((r.class == "") or (r.class == class)) and
        ((r.instance == "") or (r.instance == instance))):
      applyed = true
      if r.settitle != "":
        c.name = r.settitle
        c.lockname = true
      if r.container != 0:
        movetocon(c, r.container)
      if r.icon != "":
        c.icon = r.icon
      c.noswallow = r.noswallow
      c.isterm = r.isterm
  if not applyed:
    center(c)

proc applysizehints(c: PClient, x, y, w, h: ptr cint, interact: bool): bool =
  var baseismin: bool
  var m: PMonitor = c.mon

  w[] = max(1, w[])
  h[] = max(1, h[])
  if interact:
    if x[] > sw.cint:
      x[] = sw.cint - WIDTH(c).cint
    if y[] > sh.cint:
      y[] = sh.cint - HEIGHT(c).cint
    if x[] + w[] + 2 * c.bw < 0:
      x[] = 0
    if y[] + h[] + 2 * c.bw < 0:
      y[] = 0
  else:
    if x[] >= m.wx + m.ww:
      x[] = m.wx + m.ww - WIDTH(c)
    if y[] >= m.wy + m.wh:
      y[] = m.wy + m.wh - HEIGHT(c)
    if x[] + w[] + 2 * c.bw < m.wx:
      x[] = m.wx
    if y[] + h[] + 2 * c.bw < m.wy:
      y[] = m.wy
  if h[] < bh:
    h[] = bh
  if w[] < bh:
    w[] = bh
  if c.isfloating:
    baseismin = c.basew == c.minw and c.baseh == c.minh
    if not baseismin:
      w[] -= c.basew
      h[] -= c.baseh
    if c.mina > 0 and c.maxa > 0:
      if (c.maxa < w[] / h[]):
        w[] = ((h[].float * c.maxa) + 0.5).cint
      if (c.mina < h[] / w[]):
        h[] = ((w[].float * c.mina) + 0.5).cint
    if baseismin:
      w[] -= c.basew
      h[] -= c.baseh
    if c.incw != 0:
      w[] -= w[] mod c.incw
    if c.inch != 0:
      h[] -= h[] mod c.inch
    w[] = max(w[] + c.basew, c.minw)
    h[] = max(h[] + c.baseh, c.minh)
    if c.maxw != 0:
      w[] = min(w[], c.maxw)
    if c.maxh != 0:
      h[] = min(h[], c.maxh)
  return x[] != c.x or y[] != c.y or w[] != c.w or h[] != c.h

proc arrange(m: PMonitor) =
  if m == nil:
    return
  updatecons(m)
  restack(m)
  for con in m.containers:
    if con.clients != @[]:
      for c in con.clients:
        if c.isfloating:
          continue
        var nx, ny, nw, nh: cint
        nx = con.cx
        ny = con.cy
        nw = con.cw
        nh = con.ch
        if m.igappsena:
          nx += m.igapps
          nw -= 2 * m.igapps
          ny += m.igapps
          nh -= 2 * m.igapps
        resize(c, m.wx + nx % m.ww, m.wy + ny % m.wh, (nw-2*c.bw) % m.ww, (nh-2*c.bw) % m.wh)

proc buttonpress(ev: TXEvent) =
  var click: ButtonPressType
  var c: PClient
  var m: PMonitor
  var e: TXButtonPressedEvent
  e = ev.xbutton

  click = ClkRootWin
  m = wintomon(e.window)
  if (m != nil) and (m != selmon):
    unfocus(selmon.sel, true)
    selmon = m
    focus(nil)
  if e.window == selmon.barwin:
    if e.x.cuint < TEXTW(getlayoutname(m)):
      click = ClkLtSymbol
    elif e.x.cuint < TEXTW(stext.split(";")[0].replace("\xf0", " ").replace("\xf1").replace("\xf2")):
      click = ClkStatusTextL
    elif e.x.cuint > m.ww.cuint - getsystraywidth():
      click = ClkSystray
    elif e.x.cuint > m.ww.cuint - getsystraywidth() - TEXTW(stext.split(";")[1].replace("\xf0", " ").replace("\xf1").replace("\xf2")):
      click = ClkStatusTextR
    else:
      click = ClkWinTitle
  else:
    c = wintoclient(e.window)
    if c != nil:
      click = ClkClientWin
      focus(c)
      restack(selmon)
      discard XAllowEvents(dpy, ReplayPointer, CurrentTime)
  for b in buttons:
    if (b.theType == click) and (b.mods.cuint == e.state) and (b.button.cuint == e.button):
      b.call.p(b.args)
  updatestext(m, true)

proc center(A: Arg) =
  center(selmon.sel)

proc center(c: PClient) =
  if c == nil:
    return
  var x = (c.mon.ww - c.w) / 2
  var y = (c.mon.wh - c.h) / 2
  resize(c, c.mon.wx + x.cint, c.mon.wy + y.cint, c.w, c.h, false)

proc checkotherwm(dpy: PDisplay) =
  oldxerror = XSetErrorHandler(xerrorstart)
  discard dpy.XSelectInput(DefaultRootWindow(dpy), SubstructureRedirectMask)
  discard XSync(dpy, 0)
  discard XSetErrorHandler(xerror)
  discard XSync(dpy, 0)

proc clickbarl(a: Arg) =
  var ev: TXEvent
  if (XGrabPointer(dpy, root, false.TBool, MOUSEMASK, GrabModeAsync, GrabModeAsync,
    None, cursor[CurNormal].cursor, CurrentTime) != GrabSuccess):
    return
  dowhile ev.theType != ButtonRelease:
    discard XMaskEvent(dpy, MOUSEMASK or ExposureMask or SubstructureRedirectMask, addr ev)
    case ev.theType
    of ConfigureRequest,
       Expose,
       MapRequest:
      if ev.theType in evhandler:
         evhandler[ev.theType].p(ev)
    else:
      discard
  discard XUngrabPointer(dpy, CurrentTime)
  var w = selmon.wx.cuint
  var x = ev.xbutton.x
  var module = -1
  var text = stext.split(";")[0].split("\xf0")
  for i in text:
    if i != text[0]:
      w += TEXTW(" ")
    w += TEXTW(i[1..^1])
    if x < w.cint:
      spawn(Arg(v: @[status[0][module].command, $a.i]))
      return
    module += 1

proc clickbarr(a: Arg) =
  var ev: TXEvent
  if (XGrabPointer(dpy, root, false.TBool, MOUSEMASK, GrabModeAsync, GrabModeAsync,
    None, cursor[CurNormal].cursor, CurrentTime) != GrabSuccess):
    return
  dowhile ev.theType != ButtonRelease:
    discard XMaskEvent(dpy, MOUSEMASK or ExposureMask or SubstructureRedirectMask, addr ev)
    case ev.theType
    of ConfigureRequest,
       Expose,
       MapRequest:
      if ev.theType in evhandler:
         evhandler[ev.theType].p(ev)
    else:
      discard
  discard XUngrabPointer(dpy, CurrentTime)
  var w = (selmon.ww + selmon.wx).cint - getsystraywidth().cint
  var x = ev.xbutton.x
  var module = 0
  var text = stext.split(";")[1].split("\xf0")
  text.reverse()
  for i in text:
    w -= TEXTW(i[1..^1]).cint
    if x > w.cint:
      spawn(Arg(v: @[status[1][high(text) - module].command, $a.i]))
      return
    module += 1

proc clientmessage(ev: TXEvent) =
  var wa: TXWindowAttributes
  var swa: TXSetWindowAttributes
  var cme = ev.xclient
  var c = wintoclient(cme.window)

  if showsystray == 1 and cme.window == systray.win and cme.message_type == netatom[NetSystemTrayOP]:
    # add systray icons
    if (cme.data.l[1] == 0):
      c = cast[PClient](alloc(sizeof(Client)))
      if c == nil:
        die("coud not create systray alloc")
      c.win = cme.data.l[2].uint
      if c.win == 0:
        return
      c.mon = systraytomon(selmon)
      systray.icons = c & systray.icons
      if 0 != XGetWindowAttributes(dpy, c.win, addr wa):
        wa.width = bh
        wa.height = bh
        wa.border_width = 0
      c.x = 0
      c.oldx = 0
      c.y = 0
      c.oldy = 0
      c.w = wa.width
      c.oldw = wa.width
      c.h = wa.height
      c.oldh = wa.height
      c.bw = 0
      c.isfloating = true
      c.mapped = true
      updatesystrayicongeom(c, wa.width, wa.height)
      discard XAddToSaveSet(dpy, c.win)
      discard XSelectInput(dpy, c.win, StructureNotifyMask or PropertyChangeMask or ResizeRedirectMask)
      discard XReparentWindow(dpy, c.win, systray.win, 0, 0)
      swa.background_pixel  = scheme[SchemeNorm][ColBg].pixel
      discard XChangeWindowAttributes(dpy, c.win, CWBackPixel, addr swa)
      discard sendevent(c.win, vxatom[Xembed], StructureNotifyMask, CurrentTime, 0, 0 , systray.win, 0)
      discard sendevent(c.win, vxatom[Xembed], StructureNotifyMask, CurrentTime, 4, 0 , systray.win, 0)
      discard sendevent(c.win, vxatom[Xembed], StructureNotifyMask, CurrentTime, 1, 0 , systray.win, 0)
      discard sendevent(c.win, vxatom[Xembed], StructureNotifyMask, CurrentTime,10, 0 , systray.win, 0)
      discard XSync(dpy, false.TBool)
      resizebarwin(selmon)
      updatesystray()
      setclientstate(c, NormalState)
    return
  if c == nil:
    return
  if cme.message_type == netatom[NetWMState]:
    if (cme.data.l[1] == cast[int](netatom[NetWMFullscreen]) or cme.data.l[2] == cast[int](netatom[NetWMFullscreen])):
      setfullscreen(c, (cme.data.l[0] == 1 or
        ((cme.data.l[0] == 2) and (not c.isfullscreen))))
    elif (cme.message_type == netatom[NetActiveWindow]):
      if ((c != selmon.sel) and (not c.isurgent)):
        discard

proc configure(c: PClient) =
  var ce: TXConfigureEvent
  ce.theType = ConfigureNotify
  ce.display = dpy
  ce.event = c.win
  ce.window = c.win
  #if c.swallowing != nil:
  #  ce.window = c.swallowing.win
  ce.x = c.x + c.bw
  ce.y = c.y + c.bw
  ce.width = c.w
  ce.height = c.h
  if ((c.con == nil or c.con.isframe or c.isfloating) and not c.isfullscreen):
    ce.height = c.h - bh
    ce.y += bh
    #ce.height = c.h
  ce.border_width = c.bw
  ce.above = None
  ce.override_redirect = false.TBool
  #if c.swallowing != nil:
  #  discard XSendEvent(dpy, c.swallowing.win, false.TBool, StructureNotifyMask, cast[PXEvent](addr ce))
  #else:
  discard XSendEvent(dpy, c.win, false.TBool, StructureNotifyMask, cast[PXEvent](addr ce))
  drawframe(c)

proc configurerequest(ev: TXEvent) =
  var c: PClient
  var m: PMonitor
  var e = ev.xconfigurerequest
  var wc: TXWindowChanges

  c = wintoclient(e.window)

  if c != nil:
    if (e.value_mask and CWBorderWidth) != 0:
      c.bw = e.border_width
    elif c.isfloating:
      m = c.mon
      if (e.value_mask and CWX) != 0:
        c.oldx = c.x
        c.x = m.mx + e.x
      if (e.value_mask and CWY) != 0:
        c.oldy = c.y
        c.y = m.mx + e.y
      if (e.value_mask and CWWidth) != 0:
        c.oldw = c.w
        c.w = e.width
      if (e.value_mask and CWHeight) != 0:
        c.oldh = c.h
        c.h = e.height
      if ((c.x + c.w) > m.mx + m.mw and c.isfloating):
        c.x = m.mx + (m.mw / 2 - WIDTH(c) / 2).cint
      if ((c.y + c.h) > m.my + m.mh and c.isfloating):
        c.y = m.my + (m.mh / 2 - HEIGHT(c) / 2).cint
      if (((e.value_mask and (CWX or CWY)) != 0) and not((e.value_mask and (CWWidth or CWHeight)) != 0)):
        configure(c)
      discard XMoveResizeWindow(dpy, c.framewin, c.x, c.y, c.w.cuint, c.h.cuint);
    else:
      configure(c)
  else:
    wc.x = e.x
    wc.y = e.y
    wc.width = e.width
    wc.height = e.height
    wc.border_width = e.border_width
    discard XConfigureWindow(dpy, e.window, e.value_mask.cuint, addr wc)
  discard XSync(dpy, false.TBool)

proc configurenotify(ev: TXEvent) =
  var e = ev.xconfigure
  var dirty: bool

  if e.window == root:
    dirty = (sw.cint != e.width) or (sh.cint != e.height)
    sw = e.width.cuint
    sh = e.height.cuint
    if updategeom() or dirty:
      drw_resize(drw, sw, sh)
      updatebars()
      for m in mons:
        for c in m.clients:
          if c.isfullscreen:
            resizeclient(c, m.mx, m.my, m.mw, m.mh)
        discard XMoveResizeWindow(dpy, m.barwin, m.wx, m.by, m.ww.cuint, bh.cuint)
        resizebarwin(m)
    focus(nil)
    arrange(nil)

proc createmon(): PMonitor =
  var m = cast[PMonitor](alloc(sizeof(Monitor)))
  m.igappsena = false
  m.igapps = DEFIGAPS.cint
  m.ogappsena = false
  m.ogapps = DEFOGAPS.cint
  for i in 0..3:
    m.containers[i] = cast[PContainer](alloc(sizeof(Container)))
    m.containers[i].num = i
    m.containers[i].isframe = true
    m.containers[i].clients = @[]
  updatebarpos(m)
  updatecons(m)
  return m

proc cyclefocus(a: Arg) =
  if a.i == 0 or selmon.sel == nil or selmon.sel.con == nil:
    return
  var cur = 0
  if selmon.sel.isfloating:
    for c in selmon.clients:
      if c == selmon.sel:
        break
      inc(cur)
    cur += a.i
    while not selmon.clients[cur mod len(selmon.clients)].isfloating:
      while cur < 0:
        cur += len(selmon.clients)
      cur += a.i
    while cur < 0:
      cur += len(selmon.clients)
    cur = cur mod len(selmon.sel.con.clients)
    focus(selmon.clients[cur])
    restack(selmon)
  else:
    for c in selmon.sel.con.clients:
      if c == selmon.sel:
        break
      inc(cur)
    cur += a.i
    while selmon.sel.con.clients[cur mod len(selmon.sel.con.clients)].isfloating:
      while cur < 0:
        cur += len(selmon.sel.con.clients)
      cur += a.i
    while cur < 0:
      cur += len(selmon.sel.con.clients)
    cur = cur mod len(selmon.sel.con.clients)
    focus(selmon.sel.con.clients[cur])
    restack(selmon)

proc drawbar(m: PMonitor) =
  var stw = 0.uint
  if(showsystray != 0 and m == systraytomon(m)):
    stw = getsystraywidth()
  updatestext(mons[0], false)
  if len(stext.split(";")) != 3:
    return
  resizebarwin(m)
  var l = stext.split(";")[0].split("\xf0")
  var r = stext.split(";")[1].split("\xf0")
  var c = stext.split(";")[2].split("\xf0")
  r.reverse()
  var cw, w: cuint = 0
  var lx: cint = 0
  var cx: cint = 0
  var rx: cint = m.ww - stw.cint
  drw_setscheme(drw, scheme[SchemeSel])
  drw_rect(drw, 0, 0, m.ww.cuint - stw.cuint, bh.cuint, true, false, false)
  for i in l:
    if i[0] == '\xf2':
      drw_setscheme(drw, scheme[SchemeNorm])
    if i != l[0]:
      discard drw_text(drw, lx.cint, 0, TEXTW(" "), bh.cuint, 0, " ", false)
      lx += TEXTW(" ").cint
    if i[0] == '\xf1':
      drw_setscheme(drw, scheme[SchemeSel])
    w = TEXTW(i[1..^1]).cuint
    discard drw_text(drw, lx.cint, 0, w, bh.cuint, 0, i[1..^1], false)
    lx += w.cint
  w = 0
  for i in r:
    if i[0] == '\xf1':
      drw_setscheme(drw, scheme[SchemeSel])
    if i != r[0]:
      rx -= TEXTW(" ").cint
      discard drw_text(drw, rx.cint, 0, TEXTW(" "), bh.cuint, 0, " ", false)
    if i[0] == '\xf2':
      drw_setscheme(drw, scheme[SchemeNorm])
    w = TEXTW(i[1..^1]).cuint
    rx -= w.cint
    discard drw_text(drw, rx.cint, 0, w, bh.cuint, 0, i[1..^1], false)
  for i in c:
    cw += TEXTW(i[1..^1]).cuint
    cw += TEXTW(" ")
  cw += TEXTW(" ").cuint
  cx = ((m.ww - cw.cint).int / 2).cint - lx.cint
  w = 2 * TEXTW(" ")
  var ccx = 0.cint
  var p = 0.cint
  for i in c:
    if i[0] == '\xf1':
      drw_setscheme(drw, scheme[SchemeSel])
      p = TEXTW(" ").cint
    if i[0] == '\xf2':
      drw_setscheme(drw, scheme[SchemeNorm])
      p = 0
    w = TEXTW(i[1..^1]).cuint
    discard drw_text(drw, ccx + lx + cx.cint, 0, w, bh.cuint, 0, i[1..^1], false)
    ccx += w.cint + p.cint
    w = TEXTW(" ")
  drw_map(drw, m.barwin, 0, 0, m.ww.cuint, bh.cuint)

proc drawframe(c: PClient) =
  if c == nil:
    return
  if ((c.con == nil or c.con.isframe or c.isfloating) and not c.isfullscreen):
    var frametabs = @[c]
    if DRAWFRAMETABS and c.con != nil:
      frametabs = @[]
      for c in c.con.clients:
        if c.isfloating:
          continue
        if ((c.con == nil or c.con.isframe) and not c.isfullscreen):
          frametabs &= c
    if c.isfloating:
      frametabs = @[c]
    var w = (c.w / len(frametabs)).int
    for ci in 0..high(frametabs):
      var c = frametabs[ci]
      var icon = c.icon
      drw_setscheme(drw, scheme[SchemeNorm])
      if (selmon.sel == c):
        drw_setscheme(drw, scheme[SchemeSel])
      drw_rect(drw, (ci * w).cint, 0, (w + 2 * c.bw).cuint, bh.cuint + c.bw.cuint, true, false, false)
      discard drw_text(drw, (ci * w).cint + TEXTW(" ").cint, 0, TEXTW(c.name), bh.cuint, 0, c.name, false)
      if (frameicons):
        discard drw_text(drw, ((ci + 1) * w).cint - TEXTW(icon).cint - TEXTW(" ").cint, 0, TEXTW(icon), bh.cuint - c.bw.cuint, 0, icon, false)
      drw_rect(drw, (ci * w).cint, bh - c.bw, (w + 2 * c.bw).cuint, c.bw.cuint, true, false, true)
    if high(frametabs) == 0:
      drw_setscheme(drw, scheme[SchemeNorm])
      if (selmon.sel == c):
        drw_setscheme(drw, scheme[SchemeSel])
      drw_rect(drw, 0, 0, (c.w + 2 * c.bw).cuint, bh.cuint + c.bw.cuint, true, false, false)
      discard drw_text(drw, TEXTW(" ").cint, 0, TEXTW(c.name), bh.cuint, 0, c.name, false)
      if (frameicons):
        discard drw_text(drw, c.w.cint - TEXTW(c.icon).cint - TEXTW(" ").cint, 0, TEXTW(c.icon), bh.cuint - c.bw.cuint, 0, c.icon, false)
      drw_rect(drw, 0, bh - c.bw, c.w.cuint, c.bw.cuint, true, false, true)
    drw_map(drw, c.framewin, 0, 0, (c.w + 2 * c.bw).cuint, bh.cuint)

proc destroynotify(ev: TXEvent) =
  var c: PClient
  var e = ev.xdestroywindow
  c = wintoclient(e.window)
  if c != nil:
    unmanage(c, true)
  else:
    c = swallowingclient(e.window)
    if c != nil:
      unmanage(c.swallowing, true)
    else:
      c = wintosystrayicon(e.window)
      if c != nil:
        removesystrayicon(c)
        resizebarwin(selmon)
        updatesystray()

proc die(msg: cstring) =
  stderr.write(msg)
  quit EXIT_FAILURE

proc enternotify(ev: TXEvent) =
  var c: PClient
  var m: PMonitor
  var e: TXCrossingEvent

  e = ev.xcrossing
  if ((e.mode != NotifyNormal) or (e.detail == NotifyInferior)) and (e.window != root):
    return
  c = wintoclient(e.window)
  if c != nil:
    m = c.mon
  else:
    m = wintomon(e.window)
  if m != selmon:
    unfocus(selmon.sel, true)
    selmon = m
  elif ((c == nil) or (c == selmon.sel)):
    return
  focus(c)

proc expose(ev: TXEvent) =
  var m: PMonitor
  var e = ev.xexpose
  m = wintomon(e.window)
  if e.count == 0 and m != nil:
    drawbar(m)
    if m == selmon:
      updatesystray()

proc focus(a: Arg) =
  var c = wintoclient(a.i.TWindow)
  var m: PMonitor
  if c != nil:
    m = c.mon
  else:
    m = wintomon(a.i.TWindow)
  if m != selmon:
    unfocus(selmon.sel, true)
    selmon = m
  elif ((c == nil) or (c == selmon.sel)):
    return
  focus(c)
  restack(selmon)

proc focus(cli: PClient) =
  var d, c: PClient = cli
  if (c == nil) and (len(selmon.clients) != 0):
    c = selmon.clients[^1]
  if ((selmon.sel != nil) and (selmon.sel != c)):
    unfocus(selmon.sel, false)
  if c != nil:
    if c.mon != selmon:
      selmon = c.mon
    grabbuttons(c, true)
    discard XSetWindowBorder(dpy, c.framewin, scheme[SchemeSel][ColBorder].pixel);
    setfocus(c)
    d = selmon.sel
  else:
    discard XSetInputFocus(dpy, root, RevertToPointerRoot, CurrentTime)
    discard XDeleteProperty(dpy, root, netatom[NetActiveWindow])
  selmon.sel = c
  if d != nil:
    drawframe(d)
  if c != nil:
    drawframe(c)
  updatestext(selmon, false)
  drawbar(selmon)
  restack(selmon)

proc focusin(ev: TXEvent) =
  if ((selmon.sel != nil) and (ev.xfocus.window != selmon.sel.win)):
    setfocus(selmon.sel)

proc frame(c: PClient) =
  c.framewin = XCreateSimpleWindow(dpy, root, c.x, c.y, c.w.cuint, c.h.cuint, c.bw.cuint, scheme[SchemeNorm][ColBorder].pixel, scheme[SchemeNorm][ColBorder].pixel)
  discard XSelectInput(dpy, c.framewin, EnterWindowMask or SubstructureRedirectMask or SubstructureNotifyMask)
  discard XAddToSaveSet(dpy, c.win)
  discard XReparentWindow(dpy, c.win, c.framewin, 0, bh)
  discard XMapWindow(dpy, c.framewin)
  #wa.override_redirect = true.TBool
  #discard XChangeWindowAttributes(dpy, c.win, CWOverrideRedirect, addr wa)

proc getatomprop(c: PClient, prop: TAtom): TAtom =
  if c == nil:
    return
  var di: cint
  var dl: culong
  var p: cstring
  var da, atom: TAtom

  var req = XA_ATOM
  if prop == vxatom[XembedInfo]:
    req = vxatom[XembedInfo]

  if (XGetWindowProperty(dpy, c.win, prop, 0, sizeof atom, false.TBool, req,
    addr da, addr di, addr dl, addr dl, cast[PPcuchar](addr p)) == Success):
    atom = cast[ptr TAtom](p)[]
    if da == vxatom[XembedInfo] and dl == 2:
      {.emit: ["atom = ((", TAtom, " *)p)[1];"].}
    discard XFree(p)
  return atom

proc getlayoutname(m: PMonitor): string =
  if m.ogappsena:
    result = " ["
  else:
    result = " -"
  if m.igappsena:
    result &= "+"
  else:
    result &= "⬜"
  if m.ogappsena:
    result &= "]"
  else:
    result &= "-"

proc getparentprocess(p: cint): cint =
  var v: cint = 0
  {.emit: ["""
  FILE *f;
  char buf[256];
  snprintf(buf, sizeof(buf) - 1, "/proc/%u/stat", (unsigned)p);

  if (!(f = fopen(buf, "r")))
    return (pid_t)0;

  if (fscanf(f, "%*u %*s %*c %u", (unsigned *)&v) != 1)
    """, v, """ = (pid_t)0;
  fclose(f);
  """].}
  echo "finished gpp"
  return v

proc getstatus(): string =
  var left, right = ""
  for b in status[0]:
    var output: string
    if not b.icon:
      output = execProcess(b.command).replace("\n")
    else:
      output = execProcess(b.command & " icon").replace("\n")
    if output == "":
      continue
    if not(output[0] in "\xf1\xf2"):
      output = "\xf1" & output
    left &= output & "\xf0"
  for b in status[1]:
    var output: string
    if b.icon:
      output = execProcess(b.command).replace("\n")
    else:
      output = execProcess(b.command & " icon").replace("\n")
    if output == "":
      continue
    if not(output[0] in "\xf1\xf2"):
      output = "\xf1" & output
    right &= output & "\xf0"
  return left[0..^2] & ";" & right[0..^2] & " "

proc gettitle(m: PMonitor): string =
  if not advancedtitle:
    result = DESKTOPTEXT
    if selmon.sel != nil:
      result = strutils.strip(selmon.sel.name)
  else:
    if selmon.sel == nil:
      if DESKTOPTEXT == "":
        result = "Root" & "\xf0\xf2w:\xf0\xf1" & $selmon.ww & "\xf0\xf2h:\xf0\xf1" & $selmon.wh
      else:
        result = DESKTOPTEXT & "\xf0\xf2w:\xf0\xf1" & $selmon.ww & "\xf0\xf2h:\xf0\xf1" & $selmon.wh
    else:
      var c = selmon.sel
      var ch: TXClassHint
      discard XGetClassHint(dpy, c.win, addr ch);
      var class = ch.res_class
      var instance = ch.res_name
      result = $c.pid & " : " & $class & " - " & $instance & "\xf0\xf2x:\xf0\xf1" & $c.x & "\xf0\xf2y:\xf0\xf1" & $c.y & "\xf0\xf2w:\xf0\xf1" & $c.w & "\xf0\xf2h:\xf0\xf1" & $c.h

proc gettextprop(w: TWindow, atom: TAtom): string =
  var list: ptr cstring
  var n: cint
  var name: TXTextProperty

  var ntext = ""
  if (0 == XGetTextProperty(dpy, w, addr name, atom) or 0 == name.nitems):
    return ""
  if (name.encoding == XA_STRING):
    ntext = $cast[cstring](name.value)
  else:
    if (XmbTextPropertyToTextList(dpy, addr name, addr list, addr n) >= Success and n > 0 ):
      ntext = $($list[])
  discard XFree(name.value)
  return ntext

proc getsystraywidth(): uint =
  var w: cuint = 0
  if showsystray != 0:
    for i in systray.icons:
      w += (i.w + systrayspacing).cuint
  if w == 0:
    return 1
  return w

proc getrootptr(x, y: Pcint): bool =
  var di: cint
  var dui: cuint
  var dummy: TWindow
  return XQueryPointer(dpy, root, addr dummy, addr dummy, x, y, addr di, addr di, addr dui).bool

proc grabbuttons(c: PClient, focused: bool) =
  updatenumlockmask()
  discard XUngrabButton(dpy, AnyButton, AnyModifier, c.framewin)
  if not focused:
    discard XGrabButton(dpy, AnyButton, AnyModifier, c.framewin, false.Tbool,
      BUTTONMASK, GrabModeSync, GrabModeSync, None, None);
  var modifiers = [0, LockMask, numlockmask, numlockmask or LockMask]
  for b in buttons:
    if b.theType == ClkClientWin:
      for m in modifiers:
        discard XGrabButton(dpy, b.button.cuint, b.mods.cuint or m.cuint, c.win, false.TBool,
          BUTTONMASK, GrabModeSync, GrabModeSync, None, None)
        discard XGrabButton(dpy, b.button.cuint, b.mods.cuint or m.cuint, c.framewin, false.TBool,
          BUTTONMASK, GrabModeSync, GrabModeSync, None, None)

proc grabkeys() =
  if keys == []:
    return
  updatenumlockmask()
  var modifiers = [0, LockMask, numlockmask, numlockmask or LockMask]
  for k in keys:
    for m in modifiers:
      discard dpy.XGrabKey(dpy.XKeysymToKeycode(k.key).cint, k.mods.cuint, root, 1, GrabModeAsync, GrabModeAsync)

proc isdescprocess(p, c: cint): cint =
  var nc = c
  while (p != nc and nc != 0):
    nc = getparentprocess(nc)
    echo "nc: ", $nc
  if nc != 0:
    echo "parent: ", $p, ", child: ", $nc
  return nc

proc isuniquegeom(unique: PXineramaScreenInfo, n: cuint, info: PXineramaScreenInfo): bool =
  var res: cint = 1
  {.emit: ["""while (n--)
    if (unique[n].x_org == info->x_org && unique[n].y_org == info->y_org
    && unique[n].width == info->width && unique[n].height == info->height) res = 0;"""].}
  return res == 1

proc keypress(ev: TXEvent) =
  if keys == []:
    return
  for k in keys:
    if (cast[cuint](k.mods) == ev.xkey.state) and (dpy.XKeysymToKeycode(k.key).cuint == ev.xkey.keycode):
      k.call.p(k.args)

proc killclient(a: Arg) =
  if selmon.sel == nil:
    return
  if not (sendevent(selmon.sel.win, wmatom[WMDelete], NoEventMask, wmatom[WMDelete], CurrentTime, 0 , 0, 0)):
    discard XGrabServer(dpy)
    discard XSetCloseDownMode(dpy, DestroyAll)
    discard XKillClient(dpy, selmon.sel.win)
    discard XSync(dpy, false.TBool)
    discard XUngrabServer(dpy)

proc killwm(a: Arg) =
  quit()

proc loadxrdb() =
  var display: PDisplay
  var resm: cstring
  var xrdb: TXrmDatabase
  var t: cstring
  var value: TXrmValue

  display = XOpenDisplay(nil)

  if (display != nil):
    resm = XResourceManagerString(display)

    if (resm != nil):
      xrdb = XrmGetStringDatabase(resm)

      if (xrdb != nil):
        XRDB_LOAD_COLOR("budwm.normbordercolor", addr colors[SchemeNorm][ColBorder])
        XRDB_LOAD_COLOR("budwm.normbgcolor", addr colors[SchemeNorm][ColBg])
        XRDB_LOAD_COLOR("budwm.normfgcolor", addr colors[SchemeNorm][ColFg])
        XRDB_LOAD_COLOR("budwm.selbordercolor", addr colors[SchemeSel][ColBorder])
        XRDB_LOAD_COLOR("budwm.selbgcolor", addr colors[SchemeSel][ColBg])
        XRDB_LOAD_COLOR("budwm.selfgcolor", addr colors[SchemeSel][ColFg])
  discard XCloseDisplay(display)

proc main() =
  setup()
  var frame = 0
  while true:
    drawbar(mons[0])

proc manage(w: TWindow, wa: TXWindowAttributes) =
  var c: PClient = cast[PClient](alloc(sizeof(Client)))
  var term: PClient

  c.mon = selmon
  c.win = w
  c.pid = winpid(w)
  c.x = wa.x
  c.oldx = wa.x
  c.y = wa.y
  c.oldy = wa.y
  c.w = wa.width
  c.oldw = wa.width
  c.h = wa.height
  c.oldh = wa.height
  c.oldbw = wa.border_width
  updatetitle(c)
  applyrules(c)
  term = termforwin(c)
  frame(c)
  configure(c)
  discard XSelectInput(dpy, c.win, EnterWindowMask or FocusChangeMask or PropertyChangeMask or StructureNotifyMask)
  grabbuttons(c, false)
  selmon.clients.add(c)
  discard XChangeProperty(dpy, root, netatom[NetClientList], XA_WINDOW, 32, PropModeAppend,
    cast[ptr cuchar](addr c.win), 1)
  setclientstate(c, NormalState)
  if (c.mon == selmon):
    unfocus(selmon.sel, false)
  c.mon.sel = c
  arrange(c.mon)
  discard dpy.XMapWindow(c.win)
  updatesizehints(c)
  resize(c, c.x, c.y, c.w, c.h, false)
  drawframe(c)
  if term != nil:
    swallow(term, c)
  focus(nil)

proc mappingnotify(ev: TXEvent) =
  var e = ev.xmapping

  discard XRefreshKeyboardMapping(addr e)
  if e.request == MappingKeyboard:
    grabkeys()

proc maprequest(ev: TXEvent) =
  var wa: TXWindowAttributes
  var e = ev.xmaprequest
  var i: PClient

  i = wintosystrayicon(e.window)
  if i != nil:
    discard sendevent(i.win, vxatom[Xembed], StructureNotifyMask, CurrentTime, 1, 0, systray.win, 0)
    resizebarwin(selmon)
    updatesystray()
  if XGetWindowAttributes(dpy, e.window, addr wa) == 0:
    return
  if wa.override_redirect.bool:
    return
  if wintoclient(e.window) == nil:
    manage(e.window, wa)

proc motionnotify(ev: TXEvent) =
  var m: PMonitor
  var e = ev.xmotion

  if e.window != root:
    return
  m = recttomon(e.x_root, e.y_root, 1, 1)
  if m != selmon:
    var d = selmon.sel
    unfocus(selmon.sel, true)
    selmon = m
    focus(nil)
    drawframe(d)

proc movemouse(a: Arg) =
  var x, y, ocx, ocy, nx, ny: cint
  var c: PClient
  var m: PMonitor
  var ev: TXEvent

  var lasttime: TTime = 0
  if selmon.sel == nil:
    return
  c = selmon.sel
  if c.isfullscreen:
    return
  restack(selmon)
  ocx = c.x
  ocy = c.y
  if XGrabPointer(dpy, root, false.TBool, MOUSEMASK, GrabModeAsync, GrabModeAsync,
                  None, cursor[CurMove].cursor, CurrentTime) != GrabSuccess:
    return
  if not getrootptr(addr x, addr y):
    discard XUngrabPointer(dpy, CurrentTime)
    return
  dowhile ev.theType != ButtonRelease:
    discard XMaskEvent(dpy, MOUSEMASK or ExposureMask or SubstructureRedirectMask, addr ev)
    case ev.theType
    of ConfigureRequest,
       Expose,
       MapRequest:
      if ev.theType in evhandler:
         evhandler[ev.theType].p(ev)
    of MotionNotify:
      if ((ev.xmotion.time - lasttime) > (1000 / 60).uint):
        lasttime = ev.xmotion.time
      nx = ocx + (ev.xmotion.x - x)
      ny = ocy + (ev.xmotion.y - y)
      if (not c.isfloating):
        togglefloating(c)
      resize(c, nx, ny, c.w, c.h, true)
    else:
      discard
  discard XUngrabPointer(dpy, CurrentTime)
  m = recttomon(c.x, c.y, c.w, c.h)
  if (m != selmon):
    sendmon(c, m)
    selmon = m
    focus(nil)
  drawframe(c)

proc movesplith(a: Arg) =
  if selmon.sel == nil:
    return
  if selmon.sel.con.num == 1 or selmon.sel.con.num == 3:
    bdsplit += a.i.cint
  else:
    acsplit += a.i.cint
  updatecons(selmon)
  arrange(selmon)

proc movesplitv(a: Arg) =
  if selmon.sel == nil:
    return
  absplit += a.i.cint
  updatecons(selmon)
  arrange(selmon)

proc movetocon(a: Arg) =
  if selmon.sel == nil or a.i == 0:
    return
  if (selmon.sel.isfloating):
    togglefloating(selmon.sel)
  for con in selmon.containers:
    for ci in 0..high(con.clients):
      if con.clients[ci] == selmon.sel:
        con.clients.delete(ci)
        break
  selmon.containers[a.i - 1].clients &= selmon.sel
  selmon.sel.con = selmon.containers[a.i - 1]
  arrange(selmon)

proc movetocon(c: PClient, connum: int) =
  if c == nil:
    return
  for con in c.mon.containers:
    for ci in 0..high(con.clients):
      if con.clients[ci] == c:
        con.clients.delete(ci)
        break
  c.mon.containers[connum - 1].clients &= c
  c.con = c.mon.containers[connum - 1]
  c.isfloating = false
  updatecons(c.mon)
  arrange(c.mon)

proc propertynotify(ev: TXEvent) =
  var e = ev.xproperty
  var c = wintosystrayicon(e.window)
  var trans: TWindow
  drawbar(mons[0])
  if (c != nil):
    if (e.atom == XA_WM_NORMAL_HINTS):
      updatesizehints(c)
      updatesystrayicongeom(c, c.w, c.h)
    else:
      updatesystrayiconstate(c, addr e)
    resizebarwin(selmon)
    updatesystray()
  if (e.state == PropertyDelete):
    return
  c = wintoclient(e.window)
  if c != nil:
    case e.atom
      of XA_WM_TRANSIENT_FOR:
        c.isfloating = (wintoclient(trans)) != nil
        if (not c.isfloating and (XGetTransientForHint(dpy, c.win, addr trans) != 0) and
          (c.isfloating)):
          arrange(c.mon);
      of XA_WM_NORMAL_HINTS:
        updatesizehints(c)
      of XA_WM_HINTS:
        updatewmhints(c)
        if onebar:
          drawbar(mons[0])
        else:
          for m in mons: drawbar(m)
      else:
        discard
    if (e.atom == XA_WM_NAME or e.atom == netatom[NetWMName]):
      updatetitle(c)
    if (c == c.mon.sel):
      drawbar(c.mon)

proc recttomon(x, y, w, h: cint): PMonitor =
  var r = selmon
  var a, area: cint
  for m in mons:
    INTERSECT(a, x, y, w, h, m)
    if a > area:
      area = a
      r = m
  return r

proc removesystrayicon(i: PClient) =
  if showsystray == 0 or i == nil:
    return

  for ii in 0..high systray.icons:
    if systray.icons[ii] == i:
      systray.icons.delete(ii)
      break

proc resize(c: PClient, x, y, w, h: cint, move: bool = false) =
  var nx, ny, nw, nh: cint
  nx = x
  ny = y
  nw = w
  nh = h
  if c.isfloating:
    if applysizehints(c, addr nx, addr ny, addr nw, addr nh, move):
      resizeclient(c, nx, ny, nw, nh)
  else:
    resizeclient(c, nx, ny, nw, nh)
  configure(c)

proc resizebarwin(m: PMonitor) =
  var w: cuint = m.ww.cuint
  if (showsystray != 0 and m == systraytomon(m)):
    w -= getsystraywidth().cuint
  discard XMoveResizeWindow(dpy, m.barwin, m.wx, m.by, w, bh.cuint);

proc resizeclient(c: PClient, x, y, w, h: cint) =
  var wc: TXWindowChanges
  var trg = c
  #if c.swallowing != nil:
  #  trg = c.swallowing
  c.oldx = c.x
  c.x = x
  wc.x = x
  c.oldy = c.y
  c.y = y
  wc.y = y
  c.oldw = c.w
  c.w = w
  wc.width = w
  c.oldh = c.h
  c.h = h
  wc.height = h
  wc.border_width = c.bw
  discard XMoveResizeWindow(dpy, c.framewin, c.x, c.y, c.w.cuint, c.h.cuint)
  if ((c.con == nil or c.con.isframe or c.isfloating) and not c.isfullscreen):
    discard XMoveResizeWindow(dpy, trg.win, 0, bh, w.cuint, (c.h - bh).cuint)
  else:
    discard XMoveResizeWindow(dpy, trg.win, 0, 0, w.cuint, h.cuint)
  discard XSetWindowBorderWidth(dpy, c.framewin, c.bw.cuint)
  configure(c)
  discard XSync(dpy, false.TBool)

proc resizemouse(a: Arg) =
  var ocx, ocy, nw, nh: cint
  var c: PClient
  var m: PMonitor
  var ev: TXEvent

  var lasttime: TTime = 0
  if selmon.sel == nil:
    return
  c = selmon.sel
  if c.isfullscreen:
    return
  restack(selmon)
  ocx = c.x
  ocy = c.y
  if XGrabPointer(dpy, root, false.TBool, MOUSEMASK, GrabModeAsync, GrabModeAsync,
                  None, cursor[CurResize].cursor, CurrentTime) != GrabSuccess:
    return
  discard XWarpPointer(dpy, None, c.framewin, 0, 0, 0, 0, c.w + c.bw - 1, c.h + c.bw - 1)
  dowhile ev.theType != ButtonRelease:
    discard XMaskEvent(dpy, MOUSEMASK or ExposureMask or SubstructureRedirectMask, addr ev)
    case ev.theType
    of ConfigureRequest,
       Expose,
       MapRequest:
      if ev.theType in evhandler:
         evhandler[ev.theType].p(ev)
    of MotionNotify:
      if (ev.xmotion.time - lasttime) > (1000 / 60).uint:
        lasttime = ev.xmotion.time

        nw = max(ev.xmotion.x - ocx - 2 * c.bw + 1, 4)
        nh = max(ev.xmotion.y - ocy - 2 * c.bw + 1, 4+bh)
        if (c.mon.wx + nw >= selmon.wx) and (c.mon.wx + nw <= selmon.wx + selmon.ww
            ) and (c.mon.wy + nh >= selmon.wy) and (c.mon.wy + nh <= selmon.wy + selmon.wh):
          if (not c.isfloating):
            togglefloating(c)
          resize(c, c.x, c.y, nw, nh)
    else:
      discard
  discard XWarpPointer(dpy, None, c.framewin, 0, 0, 0, 0, c.w + c.bw - 1, c.h + c.bw - 1)
  discard XUngrabPointer(dpy, CurrentTime)
  while true:
    if XCheckMaskEvent(dpy, EnterWindowMask, addr ev) == 0:
      break
  m = recttomon(c.x, c.y, c.w, c.h)
  if (m != selmon):
    sendmon(c, m)
    selmon = m
    focus(nil)
  drawframe(c)

proc resizerequest(ev: TXevent) =
  var e = ev.xresizerequest
  var i: PClient

  i = wintosystrayicon(e.window)
  if i != nil:
    updatesystrayicongeom(i, e.width, e.height)
    resizebarwin(selmon)
    updatesystray()

proc restack(m: PMonitor) =
  #var c: Client
  #var ev: TXEvent
  #var wc: TXWindowChanges

  #drawbar(m)
  #if m.sel == nil:
  #  return
  #if m.sel.isfloating:
  #  discard XRaiseWindow(dpy, m.sel.framewin)
  #wc.stack_mode = Below
  #wc.sibling = m.barwin
  #for con in m.containers:
  #  for c in con.clients:
  #    if not c.isfloating:
  #      discard XConfigureWindow(dpy, c.framewin, CWSibling or CWStackMode, addr wc);
  #      wc.sibling = c.framewin
  if m == nil:
    for m in mons:
      arrange(m)
  else:
    if m.sel == nil:
      return
    discard XRaiseWindow(dpy, m.sel.framewin)
    for c in m.clients:
      if c.isfloating:
        discard XRaiseWindow(dpy, c.framewin)
      drawframe(c)
  discard Xsync(dpy, false.TBool)
  while XCheckMaskEvent(dpy, EnterWindowMask, addr ev).bool: discard

proc sendevent(w: TWindow, proto: TAtom, mask: cint, d0, d1, d2, d3, d4: TAtom): bool =
  var n: cint
  var protocols: PAtom
  var mt: TAtom
  var exists: cint = 0
  var ev: TXEvent

  if (proto == wmatom[WMTakeFocus]) or (proto == wmatom[WMDelete]):
    mt = wmatom[WMProtocols]
    var l = XGetWMProtocols(dpy, w, addr protocols, addr n)
    if (l != 0):
      {.emit: ["while (!exists && n--) exists = protocols[n] == proto;"].}
      discard XFree(protocols)
  else:
    exists = 1
    mt = proto
  if exists == 1:
    ev.theType = ClientMessage
    ev.xclient.window = w
    ev.xclient.message_type = mt
    ev.xclient.format = 32
    ev.xclient.data.l[0] = cast[int](d0)
    ev.xclient.data.l[1] = cast[int](d1)
    ev.xclient.data.l[2] = cast[int](d2)
    ev.xclient.data.l[3] = cast[int](d3)
    ev.xclient.data.l[4] = cast[int](d4)
    discard XSendEvent(dpy, w, false.TBool, mask, addr ev)
  return exists == 1

proc sendmon(c: PClient, m: PMonitor) =
  if (c.mon == m):
    return
  unfocus(c, true)
  for ci in 0..high(c.mon.clients):
    if c == c.mon.clients[ci]:
      c.mon.clients.delete(ci)
      break
  if c.con != nil:
    for ci in 0..high(c.con.clients):
      if c == c.con.clients[ci]:
        c.con.clients.delete(ci)
        break
  c.mon = m
  c.con = nil
  c.mon.clients.add(c)
  updatecons(c.mon)
  arrange(c.mon)
  focus(nil)
  arrange(c.mon)


proc setclientstate(c: PClient, state: clong) =
  var data: seq[clong] = @[state, 0]
  discard XChangeProperty(dpy, c.win, wmatom[WMState], wmatom[WMState], 32,
                          PropModeReplace, cast[Pcuchar](addr data), 2)

proc setdefault(a: Arg) =
  absplit = DEFABSPLIT
  acsplit = DEFACSPLIT
  bdsplit = DEFBDSPLIT
  updatecons(selmon)
  arrange(selmon)


proc setfocus(c: PClient) =
  if not c.neverfocus:
    discard XSetInputFocus(dpy, c.win, RevertToPointerRoot, CurrentTime)
    discard XChangeProperty(dpy, root, netatom[NetActiveWindow],
                            XA_WINDOW, 32, PropModeReplace,
                            cast[Pcuchar](addr c.win), 1)

proc setfullscreen(c: PClient, fullscreen: bool) =
  if fullscreen and (not c.isfullscreen):
    discard XChangeProperty(dpy, c.win, netatom[NetWMState], XA_ATOM, 32,
                            PropModeReplace, cast[Pcuchar](addr netatom[NetWMFullscreen]), 1)
    c.isfullscreen = true
    c.oldstate = c.isfloating
    c.oldbw = c.bw
    c.bw = 0
    c.isfloating = true
    resizeclient(c, c.mon.mx, c.mon.my, c.mon.mw, c.mon.mh)
    configure(c)
    discard XRaiseWindow(dpy, c.framewin)
  elif (not fullscreen and  c.isfullscreen):
    discard XChangeProperty(dpy, c.win, netatom[NetWMState], XA_ATOM, 32,
      PropModeReplace, "", 0)
    c.isfullscreen = false
    c.isfloating = c.oldstate
    c.bw = c.oldbw.cint
    c.x = c.oldx.cint
    c.y = c.oldy.cint
    c.w = c.oldw.cint
    c.h = c.oldh.cint
    resizeclient(c, c.x, c.y, c.w, c.h)
    configure(c)
    arrange(c.mon)

proc setup() =
 
  if dpy == nil:
    die("mnml: error opening X display")

  screen = DefaultScreen(dpy)
  sw = DisplayWidth(dpy, screen).cuint
  sh = DisplayHeight(dpy, screen).cuint
  root = RootWindow(dpy, screen)
  drw = drw_create(dpy, screen, root, sw, sh)
  if drw_fontset_create(drw, fonts) == @[]:
    die("no fonts created\n")
  bh = (drw.fonts[0].h + 2 * DEFBORDER.uint).cint
  discard updategeom()
  xcon = XGetXCBConnection(dpy)

  wmatom[WMProtocols] = XInternAtom(dpy, "WM_PROTOCOLS", false.TBool)
  wmatom[WMDelete] = XInternAtom(dpy, "WM_DELETE_WINDOW", false.TBool)
  wmatom[WMState] = XInternAtom(dpy, "WM_STATE", false.TBool)
  wmatom[WMTakeFocus] = XInternAtom(dpy, "WM_TAKE_FOCUS", false.TBool)
  netatom[NetActiveWindow] = XInternAtom(dpy, "_NET_ACTIVE_WINDOW", false.TBool)
  netatom[NetSupported] = XInternAtom(dpy, "_NET_SUPPORTED", false.TBool)
  netatom[NetSystemTray] = XInternAtom(dpy, "_NET_SYSTEM_TRAY_S0", false.TBool)
  netatom[NetSystemTrayOP] = XInternAtom(dpy, "_NET_SYSTEM_TRAY_OPCODE", false.TBool)
  netatom[NetSystemTrayOrientation] = XInternAtom(dpy, "_NET_SYSTEM_TRAY_ORIENTATION", false.TBool)
  netatom[NetSystemTrayOrientationHorz] = XInternAtom(dpy, "_NET_SYSTEM_TRAY_ORIENTATION_HORZ", false.TBool)
  netatom[NetWMName] = XInternAtom(dpy, "_NET_WM_NAME", false.TBool)
  netatom[NetWMState] = XInternAtom(dpy, "_NET_WM_STATE", false.TBool)
  netatom[NetWMCheck] = XInternAtom(dpy, "_NET_SUPPORTING_WM_CHECK", false.TBool)
  netatom[NetWMFullscreen] = XInternAtom(dpy, "_NET_WM_STATE_FULLSCREEN", false.TBool)
  netatom[NetWMWindowType] = XInternAtom(dpy, "_NET_WM_WINDOW_TYPE", false.TBool)
  netatom[NetWMWindowTypeDialog] = XInternAtom(dpy, "_NET_WM_WINDOW_TYPE_DIALOG", false.TBool)
  netatom[NetClientList] = XInternAtom(dpy, "_NET_CLIENT_LIST", false.TBool)
  netatom[NetDesktopViewport] = XInternAtom(dpy, "_NET_DESKTOP_VIEWPORT", false.TBool)
  netatom[NetNumberOfDesktops] = XInternAtom(dpy, "_NET_NUMBER_OF_DESKTOPS", false.TBool)
  netatom[NetCurrentDesktop] = XInternAtom(dpy, "_NET_CURRENT_DESKTOP", false.TBool)
  netatom[NetDesktopNames] = XInternAtom(dpy, "_NET_DESKTOP_NAMES", false.TBool)
  vxatom[Manager] = XInternAtom(dpy, "MANAGER", false.TBool)
  vxatom[Xembed] = XInternAtom(dpy, "_XEMBED", false.TBool)
  vxatom[XembedInfo] = XInternAtom(dpy, "_XEMBED_INFO", false.TBool)

  cursor[CurNormal] = drw_cur_create(drw, XC_left_ptr)
  cursor[CurResize] = drw_cur_create(drw, XC_sizing)
  cursor[CurMove] = drw_cur_create(drw, XC_fleur)
  # init colors
  for i in 0..<len(colors):
    scheme[i] = drw_scm_create(drw, colors[i])

  #updateipc()
  updatesystray()
  updatebars()
  xrdb(Arg())
  for m in mons:
    resizebarwin(m)

  for m in mons:
    echo $m[]


proc spawn(a: Arg) =
  var pid: cint
  pid = fork()
  if pid == 0:
    discard execCmd(a.v.join(" ") & " &")
    quit()
  if pid < 0:
    die("mnml: error in forking")

proc swallow(p, c: PClient) =
  if (c.noswallow > 0) or c.isterm:
    return
  if (c.noswallow < 0) and not(swallowfloating) and c.isfloating:
    return
  echo "swallow", $p[], $c[]

  if c.con != nil:
    for ci in 0..c.con.clients.high:
      if c == c.con.clients[ci]:
        c.con.clients.delete(ci)
        break
  for ci in 0..c.mon.clients.high:
    if c == c.mon.clients[ci]:
      c.mon.clients.delete(ci)
      break
  if p.con != nil:
    for ci in 0..p.con.clients.high:
      if p == p.con.clients[ci]:
        p.con.clients.delete(ci)
        break
  for ci in 0..p.mon.clients.high:
    if p == p.mon.clients[ci]:
      p.mon.clients.delete(ci)
      break
  #unframe(c)

  setclientstate(c, WithdrawnState)
  discard XUnmapWindow(dpy, p.framewin)
  #discard XRemoveFromSaveSet(dpy, p.win)
  #discard XReparentWindow(dpy, c.win, p.framewin, 0, 0)

  p.swallowing = c
  c.mon = p.mon
  c.con = p.con
  p.name = c.name

  var w = p.win
  p.win = p.swallowing.win
  p.swallowing.win = w
  w = p.framewin
  p.framewin = p.swallowing.framewin
  p.swallowing.framewin = w

  discard XChangeProperty(dpy, c.win, netatom[NetClientList], XA_WINDOW, 32, PropModeReplace,
                  cast[ptr cuchar](addr p.win), 1)
  p.mon.clients.add(p)
  p.con.clients.add(p)
  #discard dpy.XMapWindow(c.win)

  #setclientstate(p, NormalState)
  updatetitle(p)
  #discard XMoveResizeWindow(dpy, p.win, 0, 0, p.w.cuint, p.h.cuint)
  arrange(p.mon)
  configure(p)
  updateclientlist()
  echo "swallowed", $p[]

proc swallowingclient(w: TWindow): PClient =
  for m in mons:
    for c in m.clients:
      if c.swallowing != nil:
        if c.swallowing.win == w:
          return c
  return nil


proc systraytomon(m: PMonitor): PMonitor =
  for m in mons:
    if m.showbar:
      return m
  return m

proc termforwin(w: PClient): PClient =
  if (w.pid == 0) or w.isterm:
    return nil

  for m in mons:
    for c in m.clients:
      if c.isterm and c.swallowing == nil and (c.pid != 0) and isdescprocess(c.pid, w.pid) != 0:
        return c
      else:
        echo c.isterm , c.swallowing == nil, (c.pid != 0), isdescprocess(c.pid, w.pid) != 0
  return nil

proc toggleadvancedtitle(arg: Arg) =
  advancedtitle = not advancedtitle

proc togglebar(arg: Arg) =
  var m = selmon
  m.showbar = not m.showbar
  if onebar:
    m = mons[0]
  updatebarpos(m)
  resizebarwin(m)
  if (showsystray != 0):
    var wc: TXWindowChanges
    if (not selmon.showbar):
      wc.y = -bh
    else:
      wc.y = 0
    #discard XConfigureWindow(dpy, systray.win, CWY, addr wc);
  if m.showbar:
    acsplit -= bh
    bdsplit -= bh
  else:
    acsplit += bh
    bdsplit += bh
  updatecons(m)
  arrange(m)

proc togglefloating(arg: Arg) =
  if selmon.sel == nil:
    return
  togglefloating(selmon.sel)

proc togglefloating(c: PClient) =
  if c == nil:
    return
  if c.con == nil and c.isfloating:
    return
  c.isfloating = not c.isfloating
  updatecons(c.mon)
  arrange(c.mon)

proc togglefullscreen(arg: Arg) =
  if selmon.sel == nil:
    return
  setfullscreen(selmon.sel, not selmon.sel.isfullscreen)

proc toggleigapps(arg: Arg) =
  if selmon == nil:
    return
  selmon.igappsena = not selmon.igappsena
  arrange(selmon)
  updatestext(selmon, true)
  drawbar(selmon)

proc toggleiconl(arg: Arg) =
  var ev: TXEvent
  if (XGrabPointer(dpy, root, false.TBool, MOUSEMASK, GrabModeAsync, GrabModeAsync,
    None, cursor[CurNormal].cursor, CurrentTime) != GrabSuccess):
    return
  dowhile ev.theType != ButtonRelease:
    discard XMaskEvent(dpy, MOUSEMASK or ExposureMask or SubstructureRedirectMask, addr ev)
    case ev.theType
    of ConfigureRequest,
       Expose,
       MapRequest:
      if ev.theType in evhandler:
         evhandler[ev.theType].p(ev)
    else:
      discard
  discard XUngrabPointer(dpy, CurrentTime)
  var w = selmon.wx.cuint
  var x = ev.xbutton.x
  var module = -1
  var text = stext.split(";")[0].split("\xf0")
  for i in text:
    if i != text[0]:
      w += TEXTW(" ")
    w += TEXTW(i[1..^1])
    if x < w.cint:
      status[0][module].icon = not status[0][module].icon
      return
    module += 1

proc toggleiconr(arg: Arg) =
  var ev: TXEvent
  if (XGrabPointer(dpy, root, false.TBool, MOUSEMASK, GrabModeAsync, GrabModeAsync,
    None, cursor[CurNormal].cursor, CurrentTime) != GrabSuccess):
    return
  dowhile ev.theType != ButtonRelease:
    discard XMaskEvent(dpy, MOUSEMASK or ExposureMask or SubstructureRedirectMask, addr ev)
    case ev.theType
    of ConfigureRequest,
       Expose,
       MapRequest:
      if ev.theType in evhandler:
         evhandler[ev.theType].p(ev)
    else:
      discard
  discard XUngrabPointer(dpy, CurrentTime)
  var w = (selmon.ww + selmon.wx).cint - getsystraywidth().cint
  var x = ev.xbutton.x
  var module = 0
  var text = stext.split(";")[1].split("\xf0")
  text.reverse()
  for i in text:
    w -= TEXTW(i[1..^1]).cint
    if x > w.cint:
      status[1][high(text) - module].icon = not status[1][high(text) - module].icon
      return
    module += 1

proc toggleogapps(arg: Arg) =
  if selmon == nil:
    return
  selmon.ogappsena = not selmon.ogappsena
  updatecons(selmon)
  arrange(selmon)
  updatestext(selmon, true)
  drawbar(selmon)

proc unfocus(c: PClient, setfocus: bool) =
  if c == nil:
    return
  grabbuttons(c, false)
  discard XSetWindowBorder(dpy, c.framewin, scheme[SchemeNorm][ColBorder].pixel);
  if (setfocus):
    discard XSetInputFocus(dpy, root, RevertToPointerRoot, CurrentTime)
    discard XDeleteProperty(dpy, root, netatom[NetActiveWindow])


proc unframe(c: PClient) =
  discard XReparentWindow(dpy, c.win, root, 0, 0)
  discard XUnmapWindow(dpy, c.framewin)
  discard XRemoveFromSaveSet(dpy, c.win)
  discard XDestroyWindow(dpy, c.framewin)
  for ci in 0..high(c.mon.clients):
    if c.mon.clients[ci] == c:
      c.mon.clients.delete(ci)
      break

proc unmanage(c: PClient, destroyed: bool) =
  var m = c.mon

  if c.swallowing != nil:
    unswallow(c)
    return

  var s: PClient = swallowingclient(c.win)
  if s != nil:
    s.swallowing = nil
    arrange(m)
    focus(nil)
    return

  for m in mons:
    for ci in 0..high(m.clients):
      if m.clients[ci] == c:
        m.clients.delete(ci)
        break
    for con in m.containers:
      for ci in 0..high(con.clients):
        if con.clients[ci] == c:
          con.clients.delete(ci)
          break
  if not destroyed:
    unframe(c)
    discard XGrabServer(dpy)
    discard XUngrabButton(dpy, AnyButton, AnyModifier, c.win)
    setclientstate(c, WithdrawnState)
    discard XSync(dpy, false.TBool)
    discard XUngrabServer(dpy)
  if s == nil:
    arrange(m)
    focus(nil)
    updateclientlist()

proc unmapnotify(ev: TXevent) =
  var c: PClient
  var e = ev.xunmap
  c = wintoclient(e.window)
  if c != nil:
    if (e.send_event.bool):
      setclientstate(c, WithdrawnState)
    else:
      unmanage(c, false)
  else:
    c = wintosystrayicon(e.window)
    if c != nil:
      discard XMapRaised(dpy, c.win)
      updatesystray()

proc updatebars() =
  var w: uint
  var wa: TXSetWindowAttributes
  wa.override_redirect = true.TBool
  wa.background_pixmap = ParentRelative
  wa.event_mask = ButtonPressMask or ExposureMask
  var ch: TXClassHint
  ch.res_name = "budimal"
  ch.res_class = "budimal"
  for m in mons:
    if m.barwin != 0:
      if (onebar):
        break
      continue
    w = m.ww.cuint
    if (showsystray != 0) and ( m == systraytomon(m)):
      w -= getsystraywidth()
    m.barwin = XCreateWindow(dpy, root, m.wx, m.by, w.cuint, bh.cuint, 0, DefaultDepth(dpy, screen),
        CopyFromParent, DefaultVisual(dpy, screen),
        CWOverrideRedirect or CWBackPixmap or CWEventMask, addr wa)
    discard XDefineCursor(dpy, m.barwin, cursor[CurNormal].cursor)
    if (showsystray != 0) and (m == systraytomon(m)):
      discard XMapRaised(dpy, systray.win)
    discard XMapRaised(dpy, m.barwin)
    discard XSetClassHint(dpy, m.barwin, addr ch)
    updatestext(m, false)
    if (onebar):
      break
  if onebar:
    mons[0].showbar = true
    updatebarpos(mons[0])

proc unswallow(c: PClient) =
  unframe(c)
  c.win = c.swallowing.win
  c.framewin = c.swallowing.framewin
  c.swallowing = nil

  c.mon.clients.add(c)
  discard XDeleteProperty(dpy, c.win, netatom[NetClientList])

  setfullscreen(c, false)
  updatetitle(c)
  arrange(c.mon)
  discard XMapWindow(dpy, c.framewin)
  resize(c, c.x, c.y, c.w, c.h, false)
  setclientstate(c, NormalState)
  configure(c)
  focus(nil)
  arrange(c.mon)

proc updatebarpos(m: PMonitor) =
  m.wy = m.my
  m.wh = m.mh
  if (m.showbar):
    m.wh -= bh
    m.by = m.wy
    m.wy += bh
  else:
    m.by = -bh

proc updateclientlist() =
  discard XDeleteProperty(dpy, root, netatom[NetClientList])
  for m in mons:
    for c in m.clients:
      discard XChangeProperty(dpy, root, netatom[NetClientList],
                              XA_WINDOW, 32, PropModeAppend,
                              cast[Pcuchar](addr c.win), 1)
  updatecons(selmon)
  arrange(selmon)


proc updatecons(m: PMonitor) =
  if m == nil:
    return
  var taken: seq[bool]
  for i in 0..<len(m.containers):
    taken &= false
  for c in m.clients:
    if c.con != nil and not c.isfloating:
      taken[c.con.num] = true
  for i in 0..<len(m.containers):
    if m.containers[i] == nil:
      m.containers[i] = cast[PContainer](alloc(sizeof(Container)))
      m.containers[i].clients = @[]
    m.containers[i].cx = 0
    m.containers[i].cy = 0
    m.containers[i].cw = m.ww
    m.containers[i].ch = m.wh
    m.containers[i].isframe = true
    if m.ogappsena:
      m.containers[i].cx = m.ogapps
      m.containers[i].cy = m.ogapps
      m.containers[i].cw -= 2 * m.ogapps
      m.containers[i].ch -= 2 * m.ogapps
    case i:
    of 0:
      if taken[2]: m.containers[i].ch = acsplit
      if taken[1] or taken[3]: m.containers[i].cw += absplit
      if m.showbar: m.containers[i].isframe = false
      if m.ogappsena or m.igappsena: m.containers[i].isframe = true
      #if not taken[3] and m.ogappsena: m.containers[i].ch -= m.ogapps
      #if m.ogappsena: m.containers[i].cw -= m.ogapps
    of 1:
      if (taken[0] or taken[2]):
        m.containers[i].cx += absplit
        if m.ogappsena: m.containers[i].cx -= 2 * m.ogapps
      if (taken[0] or taken[2]): m.containers[i].cw = -absplit
      #if m.ogappsena: m.containers[i].cw -= m.ogapps
      if taken[3]: m.containers[i].ch = bdsplit
      #elif m.ogappsena: m.containers[i].ch -= m.ogapps
      if m.showbar: m.containers[i].isframe = false
      if m.ogappsena or m.igappsena: m.containers[i].isframe = true
    of 2:
      if (taken[1] or taken[3]): m.containers[i].cw += absplit
      #if m.ogappsena: m.containers[i].cw -= m.ogapps
      if (taken[0]): m.containers[i].ch -= acsplit
      #if m.ogappsena: m.containers[i].ch -= m.ogapps
      if (taken[0]): m.containers[i].cy += acsplit
      if m.showbar and not taken[0]: m.containers[i].isframe = false
      if m.ogappsena or m.igappsena: m.containers[i].isframe = true
    of 3:
      if (taken[0] or taken[2]):
        m.containers[i].cx += absplit
        if m.ogappsena: m.containers[i].cx -= 2 * m.ogapps
      if (taken[0] or taken[2]): m.containers[i].cw = -absplit
      #if m.ogappsena: m.containers[i].cw -= m.ogapps
      if (taken[1]): m.containers[i].ch -= bdsplit
      #if m.ogappsena: m.containers[i].ch -= m.ogapps
      if (taken[1]): m.containers[i].cy += bdsplit
      if m.showbar and not taken[1]: m.containers[i].isframe = false
      if m.ogappsena or m.igappsena: m.containers[i].isframe = true
    else:
      m.containers[i].cx = 0
      m.containers[i].cy = 0
      m.containers[i].cw = 0
      m.containers[i].ch = 0
      m.containers[i].isframe = false
    if mons != @[]:
      if m != mons[0] and onebar: m.containers[i].isframe = false

proc `&+`(a: string, b: string): string =
  result = a & ";" & b

proc updateipc() =
  var got = shm_read("client")
  if got == "":
    var data = ""
    if selmon == nil:
      return
    var c = selmon.sel
    if c != nil:
      var con = "F"
      if c.con != nil:
        con = $('A'.byte + c.con.num.byte).char
      data &= "ActiveClient" &+ c.name &+ c.realname &+ c.icon &+ con &+ $c.isfloating &+ $c.win & "\n"
    else:
      data &= "ActiveClient;none\n"
    for m in mons:
      data &= "Monitor" &+ $m.num &+ $m.mw &+ $m.mh & "\n"
      for c in m.clients:
        var con = "F"
        if c.con != nil:
          con = $('A'.byte + c.con.num.byte).char
        data &= "  Client" &+ c.name &+ c.realname &+ c.icon &+ con &+ $c.isfloating &+ $c.win & "\n"
    shm_write("wm", data)
    return

  var args: Arg
  var cmd: string
  if not(" " in got):
    cmd = got
    args = Arg()
  else:
    cmd = got.split(" ")[0]
    args = Arg(v: got.split(" ")[1..^1])
    try:
      args.i = args.v[0].parseInt()
    except ValueError:
      discard
  if cmd in ipccommands:
    shm_remove("client")
    ipccommands[cmd].p(args)
  else:
    echo "unknown cmd: ", got

proc updatenumlockmask() =
  var modmap: PXModifierKeymap

  modmap = XGetModifierMapping(dpy)
  for i in 0..<8:
    for j in 0..<modmap.max_keypermod:
      {.emit: ["""if (modmap->modifiermap[i * modmap->max_keypermod + j]
              == """, XKeysymToKeycode, "(", dpy, ", ", XK_Num_Lock, """))
                      """, numlockmask, """ = (1 << i);"""].}
  discard XFreeModifiermap(modmap)

proc updatesizehints(c: PClient) =
  var msize: clong
  var size: TXSizeHints

  if (0 == XGetWMNormalHints(dpy, c.win, addr size, addr msize)):
    size.flags = PSize
  if (0 != (size.flags and PBaseSize)):
    c.basew = size.base_width
    c.baseh = size.base_height + bh
  elif (0 != (size.flags and PMinSize)):
    c.incw = size.width_inc
    c.inch = size.height_inc
  else:
    c.basew = 0
    c.baseh = 0
  if (0 != (size.flags and PReSizeInc)):
    c.incw = size.width_inc
    c.inch = size.height_inc
  else:
    c.incw = 0
    c.inch = 0
  if (0 != (size.flags and PMaxSize)):
    c.maxw = size.max_width
    c.maxh = size.max_height + bh
  else:
    c.maxw = 0
    c.maxh = 0
  if (0 != (size.flags and PMinSize)):
    c.minw = size.min_width
    c.minh = size.min_height + bh
  else:
    c.minw = 0
    c.minh = 0
  if (0 != (size.flags and PAspect)):
    c.mina = (float)size.min_aspect.y / size.min_aspect.x
    c.maxa = (float)size.max_aspect.x / size.max_aspect.y
  else:
    c.mina = 0
    c.maxa = 0
  c.isfixed = (c.maxw != 0 and c.maxh != 0 and c.maxw == c.minw and c.maxh == c.minh)


proc updatestext(m: PMonitor, force: bool) =
  var parts = stext.split(";")
  var update = (abs(epochTime() - lastbar) > BARUPDATESECONDS) or (len(parts) != 3)
  if update or force:
    lastbar = epochTime()
    stext = "\xf2" & getlayoutname(m) & "\xf0" & getstatus() & ";\xf1" & gettitle(m)
  else:
    stext = parts[0..1].join(";") & ";\xf1" & gettitle(m)
  updatesystray()

proc updatesystrayicongeom(i: PClient, w, h: cint) =
  if i != nil:
    i.h = bh;
    if (w == h):
      i.w = bh
    elif (h == bh):
      i.w = w
    else:
      i.w = (bh.float * (w / h)).cint
    discard applysizehints(i, addr (i.x), addr (i.y), addr (i.w), addr (i.h), false)
    if (i.h > bh):
      if (i.w == i.h):
        i.w = bh
      else:
        i.w = (bh.float * (i.w / i.h)).cint
      i.h = bh

proc updatesystrayiconstate(i: PClient, ev: PXPropertyEvent) =
  var flags: clong
  var code = 0

  flags = getatomprop(i, vxatom[XembedInfo]).clong
  #if showsystray == 0 or i == nil or ev.atom != vxatom[XembedInfo] or flags == 0:
  #  echo showsystray == 0, i == nil, ev.atom != vxatom[XembedInfo], flags == 0
  #  return
  if showsystray == 0 or i == nil or flags == 0:
    return

  if (flags and 1) != 0:
    i.mapped = true
    code = 1
    discard XMapRaised(dpy, i.win)
    setclientstate(i, NormalState)
  elif (flags and 1) == 0:
    i.mapped = false
    code = 2
    discard XUnmapWindow(dpy, i.win)
    setclientstate(i, WithdrawnState)
  else:
    return
  discard sendevent(i.win, vxatom[Xembed], StructureNotifyMask, CurrentTime, code.TAtom, 0,
                    systray.win, 0)

proc updatesystray() =
  var wa: TXSetWindowAttributes
  var wc: TXWindowChanges
  var m: PMonitor = systraytomon(selmon)
  var x = (m.mx + m.mw).cuint
  var w = 1.cuint
  if (showsystray == 0):
    return
  if systray == nil:
    systray = cast[PSystray](alloc(sizeof(Systray)))
    if systray == nil:
      die("could not alloc systray")
    systray.win = XCreateSimpleWindow(dpy, root, x.cint, m.by, w, bh.cuint, 0, 0, scheme[SchemeSel][ColBg].pixel)
    wa.event_mask = ButtonPressMask or ExposureMask
    wa.override_redirect = true.TBool
    wa.background_pixel  = scheme[SchemeNorm][ColBg].pixel
    discard XSelectInput(dpy, systray.win, SubstructureNotifyMask)
    discard XChangeProperty(dpy, systray.win, netatom[NetSystemTrayOrientation], XA_CARDINAL, 32,
                    PropModeReplace, cast[ptr cuchar](addr netatom[NetSystemTrayOrientationHorz]), 1)
    discard XChangeWindowAttributes(dpy, systray.win, CWEventMask or CWOverrideRedirect or CWBackPixel, addr wa)
    discard XMapRaised(dpy, systray.win)
    discard XSetSelectionOwner(dpy, netatom[NetSystemTray], systray.win, CurrentTime)
    if (XGetSelectionOwner(dpy, netatom[NetSystemTray]) == systray.win):
      discard sendevent(root, vxatom[Manager], StructureNotifyMask, CurrentTime, netatom[NetSystemTray], systray.win, 0, 0)
      discard XSync(dpy, false.TBool)
    else:
      echo "conman: unable to obtain system tray.\n"
      systray = nil
      return
  w = 0
  for i in systray.icons:
    wa.background_pixel = scheme[SchemeNorm][ColBg].pixel
    discard XChangeWindowAttributes(dpy, i.win, CWBackPixel, addr wa)
    discard XMapRaised(dpy, i.win)
    w += systrayspacing.cuint
    i.x = w.cint
    discard XMoveResizeWindow(dpy, i.win, i.x, 0, i.w.cuint, i.h.cuint)
    w += i.w.cuint
    if (i.mon != m):
      i.mon = m
  if w == 0:
    w = 1
  x -= w
  discard XMoveResizeWindow(dpy, systray.win, x.cint, m.by.cint, w.cuint, bh.cuint)
  wc.x = x.cint
  wc.y = m.by
  wc.width = w.cint
  wc.height = bh
  wc.stack_mode = Above
  wc.sibling = m.barwin
  #discard XConfigureWindow(dpy, systray.win, CWX or CWY or CWWidth or CWHeight or CWSibling or CWStackMode, addr wc)
  discard XMapWindow(dpy, systray.win)
  discard XMapSubwindows(dpy, systray.win)
  discard XSetForeground(dpy, drw.gc, scheme[SchemeNorm][ColBg].pixel)
  discard XFillRectangle(dpy, systray.win, drw.gc, 0, 0, w, bh.cuint)
  discard XSync(dpy, false.TBool)

proc updatetitle(c: PClient) =
  if (c.lockname):
    discard
    c.realname = gettextprop(c.win, netatom[NetWMName])
    if ("" == c.realname):
      c.realname = gettextprop(c.win, XA_WM_NAME)
    if (c.realname == ""):
      c.name = BROKENTEXT
  else:
    c.name = gettextprop(c.win, netatom[NetWMName])
    if ("" == c.name):
      c.name = gettextprop(c.win, XA_WM_NAME)
    if (c.name == ""):
      c.name = BROKENTEXT
    drawbar(c.mon)
  if c.name != "":
    c.icon = $c.name[0]


proc ucallocm(a: cint, b: cint): ptr TXineramaScreenInfo {.importc: "calloc", header: "<stdlib.h>".}
proc updategeom(): bool =
  var dirty: cint = 0

  if (XineramaIsActive(dpy).bool):
    var j, n, nn: cint
    var m: PMonitor
    var info = XineramaQueryScreens(dpy, addr nn)
    var unique: PXineramaScreenInfo = nil
    n = 0
    if len(mons) != 0:
      m = mons[^1]
    n = cast[cint](len(mons))
    j = 0
    unique = ucallocm(nn, sizeof(TXineramaScreenInfo).cint)
    for i in 0..<nn:
      if (isuniquegeom(unique, j.cuint, info)):
        {.emit: ["memcpy(&unique[", j, "++], &info[", i, "], ", sizeof(TXineramaScreenInfo), ");"].}
    discard XFree(info)
    nn = j
    if (n <= nn):
      for i in 0..<(nn - n):
        mons.add(createmon())
      for i in 0..<nn:
        m = mons[i]
        updatebarpos(m)
        {.emit: ["""
          if (""", i, """ >= n
          || unique[""", i, """].x_org != m->mx || unique[""", i, """].y_org != m->my
          || unique[""", i, """].width != m->mw || unique[""", i, """].height != m->mh)
          {
            dirty = 1;
            m->num = """, i, """;
            m->mx = m->wx = unique[""", i, """].x_org;
            m->my = m->wy = unique[""", i, """].y_org;
            m->mw = m->ww = unique[""", i, """].width;
            m->mh = m->wh = unique[""", i, """].height;
          }"""]
        .}
    else:
      for i in nn..<n:
        m = mons[^1]
        for c in 0..len(m.clients):
          dirty = 1
          m.clients.delete(c)
          m.clients[c].mon = mons[0]
          # attach(c)
        if m == selmon:
          selmon = mons[0]
        # resizerequest  else:
    if (len(mons) == 0):
      mons.add(createmon())
    if dirty == 1:
      selmon = mons[0]
      selmon = wintomon(root)
  if selmon == nil:
    selmon = mons[0]
  for m in mons:
    updatecons(m)
  return dirty == 1

proc updatewmhints(c: PClient) =
  var wmh: PXWMHints

  wmh = XGetWMHints(dpy, c.win)
  if wmh != nil:
    if (c == selmon.sel and 0 != (wmh.flags and XUrgencyHint)):
      wmh.flags = wmh.flags and not XUrgencyHint
      discard XSetWMHints(dpy, c.win, wmh)
      discard XSetWMHints(dpy, c.framewin, wmh)
    if (wmh.flags and InputHint) != 0:
      c.neverfocus = (wmh.input == 0)
    else:
      c.neverfocus = false
    discard XFree(wmh)

proc winpid(w: TWindow): cint =
  result = 0

  var spec = xcb_res_client_id_spec_t()
  spec.client = w
  spec.mask = 2

  var e: ptr xcb_generic_error_t = nil;
  var c = xcb_res_query_client_ids(xcon, 1, addr spec)
  var r = xcb_res_query_client_ids_reply(xcon, c, e)

  if r == nil:
    return 0

  var i = xcb_res_query_client_ids_ids_iterator(r)
  while i.rem != 0:
    spec = i.data.spec
    if (spec.mask and 2 ) != 0:
      var t = xcb_res_client_id_value_value(i.data)
      result = t[].cint
      break
    xcb_res_client_id_value_next(addr i)
  if result == -1:
    result = 0
  return result



proc wintoclient(w: TWindow): PClient =
  for m in mons:
    if m == nil:
      continue
    for c in m.clients:
      if c.win == w:
        return c
      if c.framewin == w:
        return c
  return nil

proc wintosystrayicon(w: TWindow): PClient =
  var i: PClient = nil

  if showsystray == 0 or w == 0:
    return i

  for i in systray.icons:
    if i.win == w:
      return i

proc wintomon(w: TWindow): PMonitor =
  var x, y: cint
  var c: PClient

  if (w == root) and getrootptr(addr x, addr y):
    return recttomon(x, y, 1, 1)
  c = wintoclient(w)
  if c != nil:
    return c.mon
  return selmon


proc xerror(dpy: PDisplay, ee: PXErrorEvent): cint {.cdecl.} =
  if ee.error_code.cint == BadWindow:
    #stderr.write("conman: error code and request code: ", ee.error_code.cuint, " " , ee.request_code.cuint, "\n")
    return 0
  return 0

proc xerrorstart(dpy: PDisplay, ee: PXErrorEvent): cint {.cdecl.} =
  die("conman: another window manager is already running\n")
  return -1

proc xrdb(a: Arg) =
  loadxrdb()
  for i in 0..<len(colors):
    scheme[i] = drw_scm_create(drw, colors[i])
  for m in mons:
    drawbar(m)
    for c in m.clients:
      drawframe(c)
      discard XSetWindowBorder(dpy, c.framewin, scheme[SchemeNorm][ColBorder].pixel);
  focus(nil)
  drw_setscheme(drw, scheme[SchemeNorm])
  drw_rect(drw, 0, 0, getsystraywidth().cuint, bh.cuint, true, false, false)
  drw_map(drw, systray.win, 0, 0, getsystraywidth().cuint, bh.cuint)
  updatesystray()

evhandler = @[
  (ButtonPress, Pe(p: buttonpress)),
  (ClientMessage, Pe(p: clientmessage)),
  (ConfigureRequest, Pe(p: configurerequest)),
  (ConfigureNotify, Pe(p: configurenotify)),
  (DestroyNotify, Pe(p: destroynotify)),
  (EnterNotify, Pe(p: enternotify)),
  (Expose, Pe(p: expose)),
  (FocusIn, Pe(p: focusin)),
  (KeyPress, Pe(p: keypress)),
  (MappingNotify, Pe(p: mappingnotify)),
  (MapRequest, Pe(p: maprequest)),
  (MotionNotify, Pe(p: motionnotify)),
  (PropertyNotify, Pe(p: propertynotify)),
  (ResizeRequest, Pe(p: resizerequest)),
  (UnmapNotify, Pe(p: unmapnotify)),
  ].toTable()

main()
