-- configure application to be able load logger
local config  = require "myapp.config"
config.multithread = true
config.main_thread = true
----------------------------------------------

-- here we already can use logger
local log      = require "myapp.log"
local zthreads = require "lzmq.threads"

-- this function requires to configure child thread
local function init_thread(...)
  require "myapp.config".multithread = true
  return ...
end

local function create_thread(fn, ...)
  return zthreads.xrun({fn, prelude = init_thread}, ...)
end

-- Real worker thread function. It can be just separate Lua file
local function worker(id)
  local config = require "myapp.config"
  local log    = require "myapp.log"

  local is_child_thread = config.multithread and not config.main_thread

  if is_child_thread then
    log.info('run worker #%d in child thread', id)
  else
    log.info('run worker #%d in main thread', id)
  end

  for i = 1, 10 do
    log.notice('Hello from worker #%d', id)
  end
end

log.info('application running')

local thread = create_thread(worker, 2):start()

worker(1)

thread:join()
