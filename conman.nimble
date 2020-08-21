# Package

version       = "0.1.0"
author        = "bob16795"
description   = "A window manager written in nim"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["conman", "conmanmsg", "conmanbar"]

# Version Dependency
requires "nim >= 0.20.0"

# Library Dependencies
requires "x11"

# -----------------------------------------------------#
# Task Definitions ------------------------------------#
# -----------------------------------------------------#
task build, "Run a simple build":
    exec "nim c -r src/minimal.nim"

task release, "Build a release":
    exec "nim c -d:release --opt:speed src/minimal.nim"

