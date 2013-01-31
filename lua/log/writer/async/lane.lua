---
-- !!! experimental implementation !!!
-- LuaLanes >= 3.5.0
-- 
-- Current implementation use one linda for all lane
-- so we can create multiple lanes and distribute messages messages in between
-- 
-- cons.
-- We can not create writer from other lanes. we must post linda for new logger directly
-- We can not create writer for some type of messages. 
--   for example create one lanes only for error log messages and second for other types of messages

local on_lane_create = function()
  -- print("on_lane_create ")
  local loadstring = loadstring or load
  local lua_init = os.getenv("lua_init")
  if lua_init and #lua_init > 0 then
    if lua_init:sub(1,1) == '@' then dofile(lua_init:sub(2))
    else assert(loadstring(lua_init))() end
  end
end

local lanes = require "lanes".configure{
  with_timers = false, 
  on_state_create = on_lane_create,
}
local LOG   = require "log"
local pack  = require "log.logformat.proxy.pack".pack

local queue -- lanes.linda()

local function log_thread_fn(maker)
  -- print("log_thread_fn")
  local log_packer = require "log.logformat.proxy.pack"
  local logformat  = require "log.logformat.default".new()
  local unpack     = log_packer.unpack

  local loadstring = loadstring or load
  local writer = assert(assert(loadstring(maker))())

  while(true)do
    local key, val = queue:receive(1.0, 'log')
    if not (key and val) then key, val = nil, 'timeout' end
    if key then 
      local msg, lvl, now = unpack(val)
      if msg and lvl and now then writer(logformat, msg, lvl, now) end
    else
      if val ~= 'timeout' then
        io.stderror:write('lane_logger: ', err)
      end
    end
  end

end

local function start_log_thread(maker)
  return lanes.gen("*", log_thread_fn)(maker)
end

local function create_writer(maker)
  if not queue then queue = lanes.linda() end

  if maker then
    local child_thread = start_log_thread(maker)
    LOG.add_cleanup(function() child_thread:cancel(60) end)
  end

  return function(fmt, ...)
    local msg = pack(...)
    queue:send('log', msg)
  end
end

local M = {}

M.new = create_writer

return M