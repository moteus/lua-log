local function prequire(...) 
  local ok, mod = pcall(require, ...)
  return ok and mod, mod or nil
end

local Log = require "log"

local zmq, zthreads, zstrerror, zassert, zrecv, ETERM

zmq = prequire "lzmq"
if zmq then
  zthreads  = prequire "lzmq.threads"
  ETERM     = zmq.errors.ETERM
  zstrerror = zmq.strerror
  zassert   = zmq.assert
  zrecv     = function(skt)
    local r, err = skt:recv_all()
    return r and r[1], err
  end
else
  zmq       = require "zmq"
  zthreads  = prequire "zmq.threads"
  ETERM     = 'closed'
  zstrerror = function(err) return err end
  zassert   = assert
  zrecv     = function(skt)
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

local zassert = zmq.assert or assert

local log_ctx

local function context(ctx)
  -- we have to use same context for all writers
  if ctx and log_ctx then assert(ctx == log_ctx) end

  if log_ctx then return log_ctx end

  log_ctx = ctx or (zthreads and zthreads.get_parent_ctx()) or zassert(zmq.init(1))

  return log_ctx
end

local function socket(ctx, stype, is_srv, addr, timeout)
  local stypes = {
    PUSH = zmq.PUSH;
    PUB  = zmq.PUB;
  }
  stype = assert(stypes[stype], 'Unsupported socket type')

  if ctx and type(ctx) ~= 'userdata' then
    ctx, addr, timeout = nil, ctx, addr
  end
  timeout = timeout or 100
  ctx = context(ctx)

  local skt = ctx:socket(stype)
  if ctx.autoclose then ctx:autoclose(skt) end
  skt:set_sndtimeo(timeout)
  skt:set_linger(timeout)
  if is_srv then zassert(skt:bind(addr)) 
  else zassert(skt:connect(addr)) end
  if not ctx.autoclose then
    Log.add_cleanup(function() skt:close() end)
  end
  return skt
end

local function init(stype, is_srv)
  local M = {}

  function M.new(ctx, addr, timeout) 
    local skt = socket(ctx, stype, is_srv, addr, timeout)
    return function(fmt, ...) skt:send((fmt(...))) end
  end

  return M
end

return {
  zmq       = zmq;
  zthreads  = zthreads;
  zstrerror = zstrerror;
  zassert   = zassert;
  zrecv     = zrecv;
  ETERM     = ETERM;
  init      = init;
  context   = context;
}