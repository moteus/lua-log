local ok, llthreads = pcall( require, "llthreads.ex" )
local runstring
if ok then
  runstring = llthreads.runstring
else
  llthreads = require "llthreads"
  runstring = function(code, ...)
    code = [[
    local lua_init = os.getenv("lua_init")
    if lua_init and #lua_init > 0 then
      if lua_init:sub(1,1) == '@' then dofile(lua_init:sub(2))
      else assert(loadstring(lua_init))() end
    end
    ]] .. code 
    return llthreads.new(code, ...)
  end
end

local cmsgpack = require "cmsgpack.safe"
local socket   = require "socket"

local Worker

local function create_socket(host, port, maker)
  local skt = assert(socket.udp())
  assert(skt:settimeout(0.1))
  assert(skt:setpeername(host, port))

  local child_thread = runstring(Worker, host, port, maker)
  child_thread:start(true)

  socket.sleep(0.5)

  return skt
end

Worker = [=[
local socket   = require "socket"
local cmsgpack = require"cmsgpack.safe"
local date     = require"date"

local host, port, maker = ...

local writer = assert(loadstring(maker))()

local uskt = assert(socket.udp())
assert(uskt:setsockname(host, port))
while(true)do
  local msg, err = uskt:receivefrom()
  if msg then 
    local msg, lvl, now = cmsgpack.unpack(msg)
    now = date(now)
    writer(msg, lvl, now)
  else
    if err ~= 'timeout' then
      io.stderror:write('async_logger: ', zmq.strerror(err))
    end
  end
end

]=]


local M = {}

function M.new(host, port, maker) 
  local skt = create_socket(host, port, maker)
  return function(msg, lvl, now)
    local m = cmsgpack.pack(msg, lvl, now:fmt("%F %T"))
    skt:send(m)
  end
end

return M

