import os

const FILE = "/tmp/conman.ipc"

proc shm_read*(process: string): string =
  if not existsFile(FILE):
    var mm = open(FILE, mode = fmWrite)
    mm.write("")
    mm.close()
    return
  var mm = open(FILE, mode = fmRead)
  var line = false
  for l in mm.lines:
    if l == "":
      continue
    if l != "[" & process & "]" and l[0] == '[' and l[^1] == ']':
      line = false
    elif l == "[" & process & "]" and l[0] == '[' and l[^1] == ']':
      line = true
    if line:
      if not(l[0] == '[' and l[^1] == ']'):
        result &= l & "\n"
  mm.close()
  if result != "":
    result = result[0..^2]

proc shm_write*(process, text: string) =
  if not existsFile(FILE):
    var mm = open(FILE, mode = fmWrite)
    mm.write("")
    mm.close()
  var mm = open(FILE, mode = fmRead)
  var line = false
  var file = ""
  for l in mm.lines:
    if l != "[" & process & "]" and l[0] == '[' and l[^1] == ']':
      line = false
    elif l == "[" & process & "]" and l[0] == '[' and l[^1] == ']':
      line = true
    if not line:
      file &= l & "\n"
  mm.close()
  mm = open(FILE, mode = fmWrite)
  mm.write(file)
  if text != "":
    mm.write("[" & process & "]\n")
    mm.write(text)
  mm.close()

proc shm_remove*(process: string) =
  shm_write(process, "")

