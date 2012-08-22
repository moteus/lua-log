local zmq = require "lzmq"

local log_ctx

local function create_socket(ctx, addr)
  log_ctx = log_ctx or ctx or zmq.assert(zmq.init(1))
  local skt = log_ctx:socket(zmq.PUB)
  skt:set_sndtimeo(100)
  skt:set_linger(100)
  zmq.assert(skt:connect(addr))
  return skt
end

local M = {}

function M.new(ctx, addr, local_name) 
  if ctx and type(ctx) ~= 'userdata' then
    ctx, addr, local_name = nil, ctx, addr
  end

  local skt = create_socket(ctx, addr)
  return function(msg) 
    skt:send(local_name, zmq.SNDMORE)
    skt:send(msg)
  end
end

return M