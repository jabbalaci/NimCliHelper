switch("boundChecks", "on")

switch("define", "ssl")

switch("passL", "-s")    # strip -s
# begin Nimble config (version 2)
when withDir(thisDir(), system.fileExists("nimble.paths")):
  include "nimble.paths"
# end Nimble config
