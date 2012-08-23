local ok, zmq, zthreads
ok, zmq = pcall(require, "lzmq")
if ok then zthreads = require "lzmq.threads"
else
  zmq      = require "zmq"
  zthreads = require "zmq.threads"
end
local zassert = zmq.assert or assert

local cmsgpack = require "cmsgpack.safe"

local Worker
local log_ctx

local function create(ctx, addr, maker)
  if ctx and type(ctx) ~= 'userdata' then
    ctx, addr, maker = nil, ctx, addr
  end

  log_ctx = log_ctx or ctx or zassert(zmq.init(1))

  local skt = zassert(log_ctx:socket(zmq.PUSH))
  local skt_sync = zassert(log_ctx:socket(zmq.PAIR))

  skt:set_sndtimeo(500)
  skt:set_linger(1000)
  zassert(skt_sync:bind(addr .. '.sync'))

  local child_thread = zthreads.runstring(log_ctx, Worker, addr, maker)
  child_thread:start(true)

  zassert(skt_sync:recv())
  skt_sync:close()

  zassert(skt:connect(addr))
  
  return function(msg, lvl, now)
    local m = cmsgpack.pack(msg, lvl, now:fmt("%F %T"))
    skt:send(m)
  end
end

Worker = [=[
local ok, zmq, zthreads
local ETERM, zstrerror, zassert, zrecv
ok, zmq = pcall(require, "lzmq")
if ok then zthreads = require "lzmq.threads"
  ETERM = zmq.errors.ETERM
  zstrerror = zmq.strerror
  zassert = zmq.assert
  zrecv = function(skt)
    local r, err = skt:recv_all()
    return r and r[1], err
  end
else
  zmq      = require "zmq"
  zthreads = require "zmq.threads"
  ETERM = 'closed'
  zstrerror = function(err) return err end
  zassert = assert
  zrecv = function(skt)
    local r, err = skt:recv()
    if not r then return nil, err end
    while skt:rcvmore() == 1 do
      ok, err = skt:recv()
      if not ok then
        return nil, err
      end
    end 
    return r
  end
end


local cmsgpack = require"cmsgpack.safe"
local date     = require"date"
local address, maker  = ...

local writer = assert(loadstring(maker))()

local ctx = zthreads.get_parent_ctx()

local skt = zassert(ctx:socket(zmq.PULL))
zassert(skt:bind(address))
local skt_sync = zassert(ctx:socket(zmq.PAIR))
zassert(skt_sync:connect(address .. '.sync'))
skt_sync:send("")
skt_sync:close()

while(true)do
  local msg, err = zrecv(skt)
  if not msg then 
    if err == ETERM then break end
    io.stderr:write('async_logger: ', err, zstrerror(err))
  else
    local msg, lvl, now = cmsgpack.unpack(msg)
    now = date(now)
    writer(msg, lvl, now)
  end
end

skt:close()
ctx:term()
]=]


local M = {}

M.new = create

return M