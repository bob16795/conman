import ipc, strutils, tables, os

proc send_cmd(cmd: string) =
  shm_write("client", cmd)

if paramCount() != 0:
  var cmd = ""
  for p in 1..paramCount():
    cmd &= " " & paramStr(p)
  send_cmd(cmd[1..^1])
else:
  echo shm_read("wm")
