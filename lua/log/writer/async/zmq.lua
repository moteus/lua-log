local Log = require"log"

local ok, zmq, zthreads
ok, zmq = pcall(require, "lzmq")
if ok then zthreads = require "lzmq.threads"
else
  zmq      = require "zmq"
  zthreads = require "zmq.threads"
end
local zassert = zmq.assert or assert

local function rand_str(n)
  math.randomseed(os.time())
  local str = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
  local res = ''
  for i = 1,n do
    local n = math.random(1, #str)
    res = res .. str:sub(n,n)
  end
  return res
end

local Worker
local log_ctx

local function create_writer(ctx, addr, maker)
  if ctx and type(ctx) ~= 'userdata' then
    ctx, addr, maker = nil, ctx, addr
  end

  log_ctx = log_ctx or ctx or zthreads.get_parent_ctx() or zassert(zmq.init(1))

  local skt_sync
  if maker then
    skt_sync = zassert(log_ctx:socket(zmq.PAIR))
    local addr_sync = 'inproc://' .. rand_str(15)
    zassert(skt_sync:bind(addr_sync))

    local child_thread = zthreads.runstring(log_ctx, Worker, addr_sync, addr, maker)
    child_thread:start(true)
    zassert(skt_sync:recv())
    skt_sync:close()
    skt_sync = nil
  end

  return require "log.writer.format".new(
    require "log.logformat.proxy".new(),
    require "log.writer.net.zmq.push".new(log_ctx, addr)
  )
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
local log_packer = require "log.logformat.proxy.pack"
local logformat  = require "log.logformat.default".new()

local unpack = log_packer.unpack

local addr_sync, address, maker  = ...

local writer = assert(loadstring(maker))()

local ctx = zthreads.get_parent_ctx()

local skt = zassert(ctx:socket(zmq.PULL))
zassert(skt:bind(address))
do
local skt_sync = zassert(ctx:socket(zmq.PAIR))
zassert(skt_sync:connect(addr_sync))
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
    if msg and lvl and now then writer(logformat, msg, lvl, now) end
  end
end

skt:close()
Log.close()
ctx:term()
]=]

local M = {}

M.new = create_writer

return M