local Log = require"log"

local ok, zmq, zthreads
ok, zmq = pcall(require, "lzmq")
if ok then zthreads = require "lzmq.threads"
else
  zmq      = require "zmq"
  zthreads = require "zmq.threads"
end
local zassert = zmq.assert or assert

local log_packer = require "log.writer.async.pack"

local Worker
local log_ctx

local function create(ctx, addr, maker)
  if ctx and type(ctx) ~= 'userdata' then
    ctx, addr, maker = nil, ctx, addr
  end

  log_ctx = log_ctx or ctx or zthreads.get_parent_ctx() or zassert(zmq.init(1))

  local skt_sync
  if maker then
    skt_sync = zassert(log_ctx:socket(zmq.PAIR))
    zassert(skt_sync:bind(addr .. '.sync'))

    local child_thread = zthreads.runstring(log_ctx, Worker, addr, maker)
    child_thread:start(true)

  end

  local skt = zassert(log_ctx:socket(zmq.PUSH))
  if log_ctx.autoclose then log_ctx:autoclose(skt) end
  skt:set_sndtimeo(500)
  skt:set_linger(1000)

  if skt_sync then zassert(skt_sync:recv()) skt_sync:close() skt_sync = nil end
  zassert(skt:connect(addr))

  if not log_ctx.autoclose  then
    Log.add_cleanup(function() skt:close() end)
  end

  local pack = log_packer.pack
  return function(msg, lvl, now)
    skt:send(pack(msg, lvl, now))
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


local Log = require "log"
local log_packer = require "log.writer.async.pack"
local unpack = log_packer.unpack

local address, maker  = ...

local writer = assert(loadstring(maker))()

local ctx = zthreads.get_parent_ctx()

local skt = zassert(ctx:socket(zmq.PULL))
zassert(skt:bind(address))
do
local skt_sync = zassert(ctx:socket(zmq.PAIR))
zassert(skt_sync:connect(address .. '.sync'))
skt_sync:send("")
skt_sync:close()
end

while(true)do
  local msg, err = zrecv(skt)
  if not msg then 
    if err == ETERM then break end
    io.stderr:write('async_logger: ', err, zstrerror(err))
  else
    local msg, lvl, now = unpack(msg)
    if msg and lvl and now then writer(msg, lvl, now) end
  end
end

skt:close()
Log.close()
ctx:term()
]=]

local M = {}

M.new = create

return M