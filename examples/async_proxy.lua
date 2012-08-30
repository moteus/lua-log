local ok, zmq, zthreads
ok, zmq = pcall(require, "lzmq")
if ok then
  ok, zthreads = pcall (require, "lzmq.threads")
  if not ok then zthreads = nil end
else
  zmq      = require "zmq"
  ok, zthreads = pcall (require, "zmq.threads")
  if not ok then zthreads = nil end
end

local ctx = zmq.init(1)

-- create log thread
local writer = require "log.writer.async.zmq".new(ctx, 'inproc://async.logger', [[
  return require'log.writer.list'.new(
    require 'log.writer.console.color'.new(),
    require 'log.writer.file.by_day'.new('./logs', 'events.log', 5000)
  )
]])
local LOG = require"log".new(writer)

-- log from separate thread via proxy
local Thread = [[
  local LOG = require"log".new(
    require "log.writer.async.zmq".new('inproc://async.logger')
  )

  LOG.fotal("(Thread) can not allocate memory")
  LOG.error("(Thread) file not found")
  LOG.warning("(Thread) cache server is not started")
  LOG.info("(Thread) new message is received")
  LOG.notice("(Thread) message has 2 file")
]]

local child_thread = zthreads.runstring(ctx, Thread)
child_thread:start()

LOG.fotal("can not allocate memory")
LOG.error("file not found")
LOG.warning("cache server is not started")
LOG.info("new message is received")
LOG.notice("message has 2 file")
child_thread:join()

print("Press enter ...") io.flush() io.read()
