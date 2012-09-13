local date = require "date"

local destroy_list = {}
local loggers_list = setmetatable({},{__mode = 'k'})
local emptyfn = function() end

local LOG_LVL = {
  EMERG     = 1;
  ALERT     = 2;
  FATAL     = 3;
  ERROR     = 4;
  WARNING   = 5;
  NOTICE    = 6;
  INFO      = 7;
  DEBUG     = 8;
  TRACE     = 9;
}

local writer_names = {}
local LOG_LVL_NAMES = {}
for k,v in pairs(LOG_LVL) do
  LOG_LVL_NAMES[v] = k 
  writer_names[v]  = k:lower()
end

local LOG_LVL_COUNT = #LOG_LVL_NAMES

local function lvl2number(lvl)
  if type(lvl) == 'number' then return lvl end
  if type(lvl) == 'string' then
    lvl = lvl:upper()
    local n
    if lvl == 'NONE' then n = 0 else n = LOG_LVL[ lvl ] end
    if not n then return nil, "unknown log level: '" .. lvl .. "'" end
    return n
  end

  return nil, 'unsupported log leve type: ' .. type(lvl)
end

local sformat = string.format
local function date_fmt(now)
  local Y, M, D = now:getdate()
  return sformat("%.4d-%.2d-%.2d %.2d:%.2d:%.2d", Y, M, D, now:gettime())
end

local function default_formatter(now, lvl, msg)
  return date_fmt(now) .. ' [' .. LOG_LVL_NAMES[lvl] .. '] ' .. msg
end

local M = {}
M.LVL = LOG_LVL
M.LVL_NAMES = LOG_LVL_NAMES

M.lvl2number = lvl2number

function M.new(max_lvl, writer, formatter)
  if max_lvl and type(max_lvl) ~= 'number' and type(max_lvl) ~= 'string' then
    max_lvl, writer, formatter = nil, max_lvl, writer
  end

  max_lvl = assert(lvl2number ( max_lvl or LOG_LVL.INFO ) )

  formatter = formatter or default_formatter
  local write = function (lvl, ... )
    local now = date()
    writer( formatter(now, lvl, ...), lvl, now )
  end;

  local dump  = function(lvl, fn, ...)
    local now = date()
    writer( date_fmt(now) .. ' [' .. LOG_LVL_NAMES[lvl] .. '] ' .. (fn(...) or ''), lvl, now )
  end

  local logger = {}

  function logger.set_lvl(lvl)
    local err lvl, err = lvl2number(lvl)
    if not lvl then return nil, err end 
    max_lvl = lvl
    for i = 1, max_lvl do logger[ writer_names[i]           ] = function(...) write(i, ...) end end
    for i = 1, max_lvl do logger[ writer_names[i] .. '_dump'] = function(...) dump(i, ...)  end end
    for i = max_lvl+1, LOG_LVL_COUNT  do logger[ writer_names[i]           ] = emptyfn end
    for i = max_lvl+1, LOG_LVL_COUNT  do logger[ writer_names[i] .. '_dump'] = emptyfn end
    return true
  end

  function logger.lvl() return max_lvl end

  assert(logger.set_lvl(max_lvl))

  loggers_list[logger] = true;

  return logger
end

function M.add_cleanup(fn)
  assert(type(fn)=='function')
  for k,v in ipairs(destroy_list) do
    if v == fn then return end
  end
  table.insert(destroy_list, 1, fn)
  return fn
end

function M.remove_cleanup(fn)
  for k,v in ipairs(destroy_list) do
    if v == fn then 
      table.remove(destroy_list, k)
      break
    end
  end
end

function M.close()
  for k,fn in ipairs(destroy_list) do pcall(fn) end
  for logger in pairs(loggers_list) do
    logger.fotal   = emptyfn;
    logger.error   = emptyfn;
    logger.warning = emptyfn;
    logger.info    = emptyfn;
    logger.notice  = emptyfn;
    logger.debug   = emptyfn;
    logger.closed  = true;
    loggers_list[logger] =  nil
  end
  destroy_list = {}
end

return M
