const 
  DEFABSPLIT = 916
  DEFACSPLIT = 170
  DEFBDSPLIT = 300
  DEFBORDER  = 2
  DEFIGAPS   = 15
  DEFOGAPS   = 5
  BARUPDATESECONDS = 1
  DRAWFRAMETABS = true
  BROKENTEXT = "broken"
  DESKTOPTEXT = "Desktop"

  systrayspacing = 2
  showsystray = 1
  swallowfloating = false

frameicons = true

keys = @[
#    (MODKEY,                XK_d,      Pk(p: spawn),         Arg(v: @["dmenu_run"])),
#    (MODKEY,                XK_a,      Pk(p: spawn),         Arg(v: @["pavucontrol"])),
#    (MODKEY or ShiftMask,   XK_d,      Pk(p: spawn),         Arg(v: @["jgmenu_run"])),
#    (MODKEY,                XK_v,      Pk(p: spawn),         TERMCMD("cava", "cava")),
#    (MODKEY,                XK_Return, Pk(p: spawn),         TERMCMD("stA", "/usr/bin/zsh")),
#    (MODKEY or ShiftMask,   XK_Return, Pk(p: spawn),         TERMCMD("stB", "/usr/bin/zsh")),
#    (MODKEY,                XK_Tab,    Pk(p: cyclefocus),    Arg(i: 1)),
#    (MODKEY or ShiftMask,   XK_Tab,    Pk(p: cyclefocus),    Arg(i: -1)),
#    (MODKEY or ShiftMask,   XK_c,      Pk(p: spawn),         TERMCMD("stC", "/usr/bin/zsh")),
#    (MODKEY,                XK_i,      Pk(p: spawn),         TERMCMD("htop", "htop")),
#    (MODKEY,                XK_e,      Pk(p: spawn),         TERMCMD("neomutt", "/usr/bin/neomutt")),
#    (MODKEY,                XK_t,      Pk(p: spawn),         Arg(v: @["mondocontrol", "menu"])),
#    (MODKEY,                XK_m,      Pk(p: spawn),         TERMCMD("ncmpcpp", "ncmpcpp")),
#    (MODKEY,                XK_b,      Pk(p: togglebar),     Arg()),
#    (MODKEY or ShiftMask,   XK_w,      Pk(p: spawn),         Arg(v: @["bwpcontrol", "menu"])),
#    (MODKEY,                XK_w,      Pk(p: spawn),         Arg(v: @["qutebrowser"])),
#    (MODKEY,                XK_c,      Pk(p: spawn),         Arg(v: @["sublaunch", "-p", "dox"])),
#    (MODKEY,                XK_q,      Pk(p: killclient),    Arg()),
#    (MODKEY or ShiftMask,   XK_1,      Pk(p: movetocon),     Arg(i: 1)),
#    (MODKEY or ShiftMask,   XK_2,      Pk(p: movetocon),     Arg(i: 2)),
#    (MODKEY or ShiftMask,   XK_3,      Pk(p: movetocon),     Arg(i: 3)),
#    (MODKEY or ShiftMask,   XK_4,      Pk(p: movetocon),     Arg(i: 4)),
#    (MODKEY or ShiftMask,   XK_Escape, Pk(p: killwm),        Arg()),
#    (MODKEY or ShiftMask,   XK_r,      Pk(p: spawn),         TERMCMD("FilesD", "ranger")),
#    (MODKEY,                XK_r,      Pk(p: spawn),         TERMCMD("FilesB", "ranger")),
#    (MODKEY,                XK_l,      Pk(p: spawn),         Arg(v: @["linklord", "-x", "'gurl \"%u\"'"])),
#    (MODKEY,                XK_Space,  Pk(p: togglefloating),Arg()),
#    (MODKEY or ShiftMask,   XK_t,      Pk(p: spawn),         Arg(v: @["sublaunch", "-p", "todo"])),
#    (MODKEY,                XK_f,      Pk(p: togglefullscreen), Arg()),
#    (MODKEY or ShiftMask,   XK_i,      Pk(p: toggleigapps),  Arg()),
#    (MODKEY or ShiftMask,   XK_o,      Pk(p: toggleogapps),  Arg()),
#    (MODKEY or ShiftMask,   XK_e,      Pk(p: center),  Arg()),
#    (MODKEY,                XK_F2,     Pk(p: xrdb),          Arg()),
#    (0,                     0x1008FF12.TKeySym,PK(p: spawn),         Arg(v: @["pamixer", "-t"])),
#    (0,                     0x1008FFB2.TKeySym,PK(p: spawn),         Arg(v: @["pamixer", "-default-source", "-t"])),
#    (0,                     0x1008FF11.TKeySym,PK(p: spawn),         Arg(v: @["pamixer", "-d", "5"])),
#    (0,                     0x1008FF13.TKeySym,PK(p: spawn),         Arg(v: @["pamixer", "-i", "5"])),
#    (0,                     0x1008ff31.TKeySym,Pk(p: spawn),         Arg(v: @["mediacontrol", "playpause"])),
#    (0,                     0x1008ff14.TKeySym,Pk(p: spawn),         Arg(v: @["mediacontrol", "playpause"])),
#    (0,                     0x1008ff17.TKeySym,Pk(p: spawn),         Arg(v: @["mediacontrol", "next"])),
#    (0,                     0x1008ff16.TKeySym,Pk(p: spawn),         Arg(v: @["mediacontrol", "prev"])),
  ]

buttons = @[
  (ClkRootWin,           0,                Button3,        Pk(p: spawn),               Arg(v: @["jgmenu_run"]) ),
  (ClkClientWin,         Mod4Mask,         Button3,        Pk(p: resizemouse),         Arg() ),
  (ClkClientWin,         Mod4Mask,         Button1,        Pk(p: movemouse),           Arg() ),
  (ClkLtSymbol,          0,                Button1,        Pk(p: toggleogapps),        Arg() ),
  (ClkLtSymbol,          0,                Button3,        Pk(p: toggleigapps),        Arg() ),
  (ClkWinTitle,          0,                Button1,        Pk(p: toggleadvancedtitle), Arg() ),
  (ClkStatusTextL,       0,                Button1,        Pk(p: clickbarl),           Arg(i: 1) ),
  (ClkStatusTextR,       0,                Button1,        Pk(p: clickbarr),           Arg(i: 1) ),
  (ClkStatusTextL,       0,                Button2,        Pk(p: clickbarl),           Arg(i: 2) ),
  (ClkStatusTextR,       0,                Button2,        Pk(p: clickbarr),           Arg(i: 2) ),
  (ClkStatusTextL,       0,                Button3,        Pk(p: clickbarl),           Arg(i: 3) ),
  (ClkStatusTextR,       0,                Button3,        Pk(p: clickbarr),           Arg(i: 3) ),
  (ClkStatusTextL,       ShiftMask,        Button1,        Pk(p: toggleiconl),         Arg() ),
  (ClkStatusTextR,       ShiftMask,        Button1,        Pk(p: toggleiconr),         Arg() ),
  ]

colors = [
  (SchemeNorm, [ "#4c5664", "#434C5E", "#D8DEE9"]),
  (SchemeSel,  [ "#4c5664", "#3B4252", "#F9F5D7"]),
].toTable()

ipccommands = [
  ("reload",          Pk(p: xrdb)),
  ("sendcon",         Pk(p: movetocon)),
  ("togglebar",       Pk(p: togglebar)),
  ("togglefloating",  Pk(p: togglefloating)),
  ("togglefullscreen",Pk(p: togglefullscreen)),
  ("quit",            Pk(p: killwm)),
  ("close",           Pk(p: killclient)),
  ("center",          Pk(p: center)),
  ("focus",           Pk(p: focus)),
  ("cyclefocus",      Pk(p: cyclefocus)),
  ("igaps",           Pk(p: toggleigapps)),
  ("ogaps",           Pk(p: toggleogapps)),
  ("hsplit",          Pk(p: movesplith)),
  ("vsplit",          Pk(p: movesplitv)),
  ("resetsplit",      Pk(p: setdefault)),
].toTable()

fonts = @["CaskaydiaCove Nerd Font Mono:size=10".cstring]

onebar = true

rules = @[
  Rule(noswallow: 0),
  Rule(class: "stA", container: 1,           icon: "", settitle: "Term", isterm: true),
  Rule(class: "stB", container: 2,           icon: "", settitle: "Term", isterm: true),
  Rule(class: "stC", container: 3,           icon: "", settitle: "Term", isterm: true),
  Rule(class: "neomutt", container: 3,       icon: "✉", settitle: "Mail"),
  Rule(class: "htop", container: 1,          icon: "", settitle: "Tsk"),
  Rule(class: "Sxiv", container: 2,          icon: "P", settitle: "Pix"),
  Rule(class: "mpv", container: 2,           icon: "", settitle: "Vid"),
  Rule(class: "cava", container: 2,          icon: "C", settitle: "Vis"),
  Rule(class: "Spotify", container: 3,       icon: "M", settitle: "Mus"),
  Rule(class: "ncmpcpp", container: 2,       icon: "M", settitle: "Mus"),
  Rule(class: "Subl", container: 3,          icon: "", settitle: "Code"),
  Rule(class: "qutebrowser", container: 3,   icon: "", settitle: "Web"),
  Rule(class: "Surf", container: 3,          icon: "", settitle: "Web"),
  Rule(class: "FilesB", container: 2,        icon: "", settitle: "Files", isterm: true),
  Rule(class: "FilesD", container: 4,        icon: "", settitle: "Files", isterm: true),
  Rule(class: "Lutris", container: 2,        icon: "", settitle: "Gam"),
  Rule(class: "Zathura", container: 3,       icon: "", settitle: "PDF"),
  Rule(class: "PavuControl", container: 2,   icon: "", settitle: "Vol"),
  Rule(class: "XEyes", container: 2,         icon: "I", settitle: "EYES"),
  Rule(class: "Vivaldi-stable", container: 3,icon: "", settitle: "Web"),
  Rule(class: "Pavucontrol", container: 2,   icon: "", settitle: "Vol"),
  Rule(class: "Steam", container: 2,         icon: "", settitle: "Gam"),
  Rule(instance: "libreoffice", container: 3,icon: "", settitle: "wrd"),
]

# left, right status
status = [
    @[
      StatusBlock(command: "clock"),
      StatusBlock(command: "volume"),
      StatusBlock(command: "volume-mic"),
      StatusBlock(command: "disk /home "),
      StatusBlock(command: "battery"),
      StatusBlock(command: "cpu"),
      StatusBlock(command: "mailbox"),
      StatusBlock(command: "bwp-status"  , icon: true),
      StatusBlock(command: "mondo-status", icon: true),
    ],
    @[
      Statusblock(command: "music"),
      StatusBlock(command: "nameinfo"),
    ]
  ]
