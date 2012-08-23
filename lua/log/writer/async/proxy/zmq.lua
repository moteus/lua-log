local zmq      = require "lzmq"
local cmsgpack = require "cmsgpack.safe"

local log_ctx

local function create(ctx, addr)
  if ctx and type(ctx) ~= 'userdata' then
    ctx, addr, maker = nil, ctx, addr
  end

  log_ctx = log_ctx or ctx or zmq.assert(zmq.init(1))

  local skt = zmq.assert(log_ctx:socket(zmq.PUSH))
  skt:set_sndtimeo(500)
  skt:set_linger(1000)
  zmq.assert(skt:connect(addr))
  
  return function(msg, lvl, now)
    local m = cmsgpack.pack(msg, lvl, now:fmt("%F %T"))
    skt:send(m)
  end
end

local M = {}

M.new = create

return M