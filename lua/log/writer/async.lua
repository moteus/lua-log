local zmq      = require "lzmq"
local zthreads = require "lzmq.threads"
local cmsgpack = require "cmsgpack.safe"

local Worker
local log_ctx

local function create(ctx, addr, maker)
  if ctx and type(ctx) ~= 'userdata' then
    ctx, addr, maker = nil, ctx, addr
  end

  log_ctx = log_ctx or ctx or zmq.assert(zmq.init(1))

  local skt = zmq.assert(log_ctx:socket(zmq.PUSH))
  skt:set_sndtimeo(500)
  skt:set_linger(1000)
  zmq.assert(skt:bind(addr))

  local child_thread = zthreads.runstring(log_ctx, Worker, addr, maker)
  child_thread:start(true)


  return function(msg, lvl, now)
    local m = cmsgpack.pack(msg, lvl, now:fmt("%F %T"))
    skt:send(m)
  end
end

Worker = [=[
local zmq      = require"lzmq"
local zthreads = require"lzmq.threads"
local cmsgpack = require"cmsgpack.safe"
local date     = require"date"
local zassert  = zmq.assert
local address, maker  = ...

local writer = assert(loadstring(maker))()

local ctx = zthreads.get_parent_ctx()

local skt = zassert(ctx:socket(zmq.PULL))
zassert(skt:connect(address))
while(true)do
  local msg, err = skt:recv_all()
  if not msg then 
    if err == zmq.errors.ETERM then break end
    io.stderror:write('async_logger: ', zmq.strerror(err))
  else
    local msg, lvl, now = cmsgpack.unpack(msg[1])
    now = date(now)
    writer(msg, lvl, now)
  end
end

skt:close()
ctx:destroy()
]=]


local M = {}

M.new = create

return M