local date = require "date"

local LOG_LVL = {
  FOTAL   = 1;
  ERROR   = 2;
  WARNING = 3;
  INFO    = 4;
  NOTICE  = 5;
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
  if max_lvl and type(max_lvl) ~= number then
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

  return {
    fotal   = function (...) write(LOG_LVL.FOTAL  , ...) end;
    error   = function (...) write(LOG_LVL.ERROR  , ...) end;
    warning = function (...) write(LOG_LVL.WARNING, ...) end;
    info    = function (...) write(LOG_LVL.INFO   , ...) end;
    notice  = function (...) write(LOG_LVL.NOTICE , ...) end;
    debug   = function (...) write(LOG_LVL.DEBUG  , ...) end;
  }
end

return M
