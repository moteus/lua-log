local Log = require"log"

local ok, zmq, zthreads
ok, zmq = pcall(require, "lzmq")
if ok then
  ok, zthreads = pcall (require, "lzmq.threads")
  if not ok then zthreads = nil end
else
  zmq      = require "zmq"
  ok, zthreads = pcall (require, "zmq.threads")
  if not ok then zthreads = nil end
end
local zassert = zmq.assert or assert

local log_ctx

local function init(stype, is_srv)
  local stypes = {
    PUSH = zmq.PUSH;
    PUB  = zmq.PUB;
  }
  stype = assert(stypes[stype], 'Unsupported socket type')

  local function create_socket(ctx, addr, timeout)
    if ctx and type(ctx) ~= 'userdata' then
      ctx, addr, timeout = nil, ctx, addr
    end
    timeout = timeout or 100
    log_ctx = log_ctx or ctx or (zthreads and zthreads.get_parent_ctx()) or zassert(zmq.init(1))
    local skt = log_ctx:socket(stype)
    if log_ctx.autoclose then log_ctx:autoclose(skt) end
    skt:set_sndtimeo(timeout)
    skt:set_linger(timeout)
    if is_srv then zassert(skt:bind(addr)) 
    else zassert(skt:connect(addr)) end
    if not log_ctx.autoclose then
      Log.add_cleanup(function() skt:close() end)
    end
    return skt
  end

  local M = {}

  M.create_socket = create_socket

  function M.new(ctx, addr, timeout) 
    local skt = create_socket(ctx, addr, timeout)
    return function(fmt, ...) skt:send((fmt(...))) end
  end

  return M
end

return {init = init}