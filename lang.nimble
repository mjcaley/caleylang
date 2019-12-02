# Package

version       = "0.1.0"
author        = "Michael Caley"
description   = "Lang compiler and interpreter"
license       = "MIT"
srcDir        = "src"
bin           = @["lang"]

backend       = "cpp"

# Dependencies

requires "nim >= 1.0.4"
