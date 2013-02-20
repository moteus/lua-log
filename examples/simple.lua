print(require "ansicolors")
local LOG = require"log".new('trace',
  require "log.writer.console.color".new()
)

LOG.emerg("can not allocate memory")
LOG.alert("can not allocate memory")
LOG.fatal("can not allocate memory")
LOG.error("file not found")
LOG.warning("cache server is not started")
LOG.notice("message has 2 file")
LOG.info("new message is received")
LOG.debug("message has 2 file")
LOG.trace("message has 2 file")

print("Press enter ...")io.flush()
io.read()