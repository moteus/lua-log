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

local log_packer = require "log.writer.async.pack"
local socket   = require "socket"

local Worker

local function create_socket(host, port, maker)
  local skt = assert(socket.udp())
  assert(skt:settimeout(0.1))
  assert(skt:setpeername(host, port))

  if maker then
    local child_thread = runstring(Worker, host, port, maker)
    child_thread:start(true)
  end

  socket.sleep(0.5)

  return skt
end

Worker = [=[
local socket   = require "socket"
local log_packer = require "log.writer.async.pack"
local date     = require"date"

local host, port, maker = ...

local writer = assert(loadstring(maker))()

local uskt = assert(socket.udp())
assert(uskt:setsockname(host, port))
while(true)do
  local msg, err = uskt:receivefrom()
  if msg then 
    local msg, lvl, now = log_packer.unpack(msg)
    if msg and lvl and now then
      now = date(now)
      writer(msg, lvl, now)
    end
  else
    if err ~= 'timeout' then
      io.stderror:write('async_logger: ', err)
    end
  end
end
]=]


local M = {}

function M.new(host, port, maker) 
  local skt = create_socket(host, port, maker)
  return function(msg, lvl, now)
    skt:send(log_packer.pack(msg, lvl, now))
  end
end

return M

