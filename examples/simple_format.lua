local writer = require "log.writer.console.color".new()

local LOG = require"log".new(writer,
  require "log.formatter.concat".new(' ')
)

local LOG_FMT = require"log".new(writer,
  require "log.formatter.format".new()
)

LOG.info('new', 'message', 'is', 'received')

LOG_FMT.notice("message has %d %s", 2, 'file')

print("Press enter ...")io.flush()
io.read()