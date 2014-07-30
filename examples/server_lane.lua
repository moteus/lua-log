-- Run two writers in separate threads 
-- and spread log messages between them

local Server = require "log.writer.async.server.lane"

Server.run("inproc://main.logger",
  "return require 'log.writer.file.by_day'.new('./logs', 'events1.log', 6000)"
)

Server.run("inproc://main.logger",
  "return require 'log.writer.file.by_day'.new('./logs', 'events2.log', 6000)"
)

local LOG = require"log".new(
  require "log.writer.async.lane".new(
    "inproc://main.logger"
  )
)

for i = 1, 10000 do
  LOG.info(i)
end


print("Press enter ...") io.flush() io.read()