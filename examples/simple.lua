local LOG = require"log".new(
  require "log.writer.console".new()
)

LOG.fatal("can not allocate memory")
LOG.error("file not found")
LOG.warning("cache server is not started")
LOG.notice("message has 2 file")
LOG.info("new message is received")

print("Press enter ...")io.flush()
io.read()