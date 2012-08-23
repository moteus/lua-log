local zmq      = require "lzmq"
local zthreads = require "lzmq.threads"

local ctx = zmq.init(1)

-- create log thread
local writer = require "log.writer.async".new(ctx, 'inproc://async.logger', [[
  local ok, console = pcall(require, 'log.writer.console.color')
  if not ok then console = require, 'log.writer.console' end
  return require'log.writer.list'.new(
    console.new(),
    require 'log.writer.file.by_day'.new('./logs', 'events.log', 5000)
  )
]])
local LOG = require"log".new(writer)

-- log from separate thread via proxy
local Thread = [[
  local zthreads = require 'lzmq.threads'
  local ctx = zthreads.get_parent_ctx()
  local LOG = require"log".new(
    require "log.writer.async.proxy.zmq".new(ctx, 'inproc://async.logger')
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
print("Press enter ...")io.flush()
io.read()