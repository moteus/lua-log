local Private = require "log.writer.net.zmq._private"
local server  = require "log.writer.async._private.server"

local zmq, ETERM, zstrerror, zassert, zrecv = 
  Private.zmq, Private.ETERM, Private.zstrerror, Private.zassert, Private.zrecv  

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

local function create_server(ctx, addr, maker, logformat)
  if ctx and type(ctx) ~= 'userdata' then
    ctx, addr, maker, logformat = nil, ctx, addr, maker
  end
  logformat = logformat or "log.logformat.default"

  ctx = Private.context(ctx)

  if maker then
    local addr_sync = 'inproc://' .. rand_str(15)
    local skt_sync = zassert(ctx:socket(zmq.PAIR))
    zassert(skt_sync:bind(addr_sync))
    server.zrun(
      "log.writer.net.server.zmq", maker, logformat, ctx, 
      false, 'PULL', addr, addr_sync
    )
    zassert(skt_sync:recv())
    skt_sync:close()
  end
end

local M = {}

M.run = create_server

M.context = Private.context

return M