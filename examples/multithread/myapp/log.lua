local config  = require "myapp.config"


-- config.multithread - indicate that we run application as multithreades
--    so we have to run one backgroud thread and run our writer there.
--
-- config.main_thread - indicate either it main thread in multithreaded application
--    we need run background thread only once. so we should do this from main thread
--    when it load this library at first time. main thread have to load this module
--    before it crate any child threads.

--
-- Note about async writers. If you whant use zmq inproc transport to communicate with
-- backgroud thread you have to share same zmq context among all threads. If you use 
-- lzmq.threads module to run your threads it done automatically.
-- If you want use any other thread library easy way just use `ipc` or `tcp` transport
-- Windows system does not support `ipc` transport
local async_writer_type = 'log.writer.async.zmq'
local async_endpoint    = 'inproc://async.logger'

-- if you do not use lzmq.threads/zmq.threads library use this transport
-- local async_endpoint    = 'tcp://127.0.0.1:5555'

-- this function build writer. It can be called from work thread
-- so we can not use any upvalue there.
local function build_writer()
  local config  = require "myapp.config"

  -- we can use `config` to build writer here.
  -- but for example we make just stdout writer.

  local writer = require "log.writer.list".new(
    require 'log.writer.stdout'.new()
  )

  return writer
end

-- configure log writer
local log_writer
if config.multithread then
  -- in multithreaded application we use backgroud log writer thread
  -- and communicate with this thread via zmq.

  if config.main_thread then
    -- create writer and start background thread
    log_writer = require(async_writer_type).new(async_endpoint, build_writer)
  else
    -- create writer and attach it to existed writer thread
    log_writer = require(async_writer_type).new(async_endpoint)
  end
else
  -- this is just single threaded application so we can use writer directly
  log_writer = build_writer()
end


-- build logger object.
local log = require "log".new(log_writer, require "log.formatter.mix".new())

return log