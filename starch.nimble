# Package

version       = "0.0.0"
author        = "redisnotblue"
description   = "An interpreter for the STARCH programming language, written in Nim."
license       = "Apache-2.0"
srcDir        = "src"
bin           = @["starch"]

# Dependencies

requires "nim >= 2.2.10"
requires "unittest2"
