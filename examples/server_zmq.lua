
require "log.writer.async.server.zmq".run("inproc://main.logger1",
  "return require 'log.writer.file.by_day'.new('./logs', 'events1.log', 6000)"
)

require "log.writer.async.server.zmq".run("inproc://main.logger2",
  "return require 'log.writer.file.by_day'.new('./logs', 'events2.log', 6000)"
)

local LOG = require"log".new(
  require "log.writer.async.zmq".new{
    "inproc://main.logger1",
    "inproc://main.logger2",
  }
)

for i = 1, 10000 do
  LOG.info(i)
end


print("Press enter ...") io.flush() io.read()