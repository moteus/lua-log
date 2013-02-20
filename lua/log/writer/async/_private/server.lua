local function prequire(...) 
  local ok, mod = pcall(require, ...)
  return ok and mod, mod or nil
end


local runstring
local llthreads = prequire "llthreads.ex"
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

local Worker = [=[
(function(server, maker, logformat, ...)
  local logformat = require(logformat).new()

  local loadstring = loadstring or load
  local writer = assert(loadstring(maker))()

  require(server).run(writer, logformat, ...)
end)(...)
]=]

local function run_server(server, maker, logformat, ...)
  assert(type(server)    == 'string')
  assert(type(maker)     == 'string')
  assert(type(logformat) == 'string')

  local child_thread = assert(runstring(Worker, server, maker, logformat, ...))
  child_thread:start(true)
  socket.sleep(0.5)
  return
end

local Private
local function run_zserver(server, maker, logformat, ctx, ...)
  assert(type(server)    == 'string')
  assert(type(maker)     == 'string')
  assert(type(logformat) == 'string')
  assert(type(ctx)       == 'userdata')

  Private = Private or require "log.writer.net.zmq._private"
  local zthreads  = assert(Private.zthreads)
  local ok, err = zthreads.runstring(ctx, Worker, server, maker, logformat, ...)
  local child_thread = assert(zthreads.runstring(ctx, Worker, server, maker, logformat, ...))
  child_thread:start(true)
  return
end

local M = {}

M.run  = run_server
M.zrun = run_zserver

return M