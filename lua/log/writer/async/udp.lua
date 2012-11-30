local ok, llthreads = pcall( require, "llthreads.ex" )
local runstring
if ok then
  runstring = llthreads.runstring
else
  llthreads = require "llthreads"
  runstring = function(code, ...)
    code = [[
    local loadstring = loadstring or load
    local lua_init = os.getenv("lua_init")
    if lua_init and #lua_init > 0 then
      if lua_init:sub(1,1) == '@' then dofile(lua_init:sub(2))
      else assert(loadstring(lua_init))() end
    end
    ]] .. code 
    return llthreads.new(code, ...)
  end
end

local socket   = require "socket"

local Worker

local function create_writer(host, port, maker)
  local writer = require "log.writer.format".new(
    require "log.logformat.proxy".new(),
    require "log.writer.net.udp".new(host, port)
  )

  if maker then
    local child_thread = runstring(Worker, host, port, maker)
    child_thread:start(true)
  end

  socket.sleep(0.5)

  return writer
end

Worker = [=[
local socket   = require "socket"
local log_packer = require "log.logformat.proxy.pack"
local logformat  = require "log.logformat.default".new()
local unpack = log_packer.unpack

local host, port, maker = ...

local loadstring = loadstring or load
local writer = assert(loadstring(maker))()

local uskt = assert(socket.udp())
assert(uskt:setsockname(host, port))
while(true)do
  local msg, err = uskt:receivefrom()
  if msg then 
    local msg, lvl, now = unpack(msg)
    if msg and lvl and now then writer(logformat, msg, lvl, now) end
  else
    if err ~= 'timeout' then
      io.stderror:write('async_logger: ', err)
    end
  end
end
]=]

local M = {}

M.new = create_writer

return M