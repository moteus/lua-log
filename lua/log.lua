local date = require "date"

local destroy_list = {}
local loggers_list = setmetatable({},{__mode = 'k'})
local emptyfn = function() end

local LOG_LVL = {
  FOTAL   = 1;
  ERROR   = 2;
  WARNING = 3;
  NOTICE  = 4;
  INFO    = 5;
  DEBUG   = 6;
}
local LOG_LVL_NAMES = {}
for k,v in pairs(LOG_LVL) do LOG_LVL_NAMES[v] = k end

local function default_formatter(now, lvl, msg)
  return now:fmt("%F %T") .. ' [' .. LOG_LVL_NAMES[lvl] .. '] ' .. msg
end

local M = {}
M.LVL = LOG_LVL
M.LVL_NAMES = LOG_LVL_NAMES

function M.new(max_lvl, writer, formatter)
  if max_lvl and type(max_lvl) ~= 'number' then
    max_lvl, writer, formatter = nil, max_lvl, writer
  end

  max_lvl = max_lvl or LOG_LVL.DEBUG
  assert(LOG_LVL_NAMES[max_lvl])
  formatter = formatter or default_formatter

  local write = function (lvl, ... )
    assert(LOG_LVL_NAMES[lvl])
    if lvl <= max_lvl then
      local now = date()
      writer( formatter(now, lvl, ...), lvl, now )
    end
  end;

  local logger = {
    fotal   = function (...) write(LOG_LVL.FOTAL  , ...) end;
    error   = function (...) write(LOG_LVL.ERROR  , ...) end;
    warning = function (...) write(LOG_LVL.WARNING, ...) end;
    info    = function (...) write(LOG_LVL.INFO   , ...) end;
    notice  = function (...) write(LOG_LVL.NOTICE , ...) end;
    debug   = function (...) write(LOG_LVL.DEBUG  , ...) end;
  }
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
