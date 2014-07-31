local writer = require "log.writer.list".new(
  -- write to console from main thread 
  require "log.writer.console.color".new(), 
  -- write to file from separate thread
  require "log.writer.async.lane".new('channel.log',
    "return require 'log.writer.file.by_day'.new('./logs', 'events.log', 5000)"
  )
)

local LOG = require"log".new(writer)
LOG.fatal("can not allocate memory")
LOG.error("file not found")
LOG.warning("cache server is not started")
LOG.info("new message is received")
LOG.notice("message has 2 file")
print("Press enter ...") io.flush() io.read()
