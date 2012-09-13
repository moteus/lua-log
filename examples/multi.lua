local LOG = require"log".new(
  require "log.writer.list".new(
    require "log.writer.console".new(),
    require "log.writer.file.by_day".new('./logs', 'events.log', 5000)
  )
)

LOG.fatal("can not allocate memory")
LOG.error("file not found")
LOG.warning("cache server is not started")
LOG.info("new message is received")
LOG.notice("message has 2 file")

print("Press enter ...")io.flush()
io.read()