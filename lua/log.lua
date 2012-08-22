require "date"

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

local function argv2str(...)
  local argc,argv = select('#', ...), {...}
  for i = 1, argc do argv[i] = tostring(argv[i]) end
  return table.concat(argv)
end

local function default_formatter(now, lvl, ...)
  return now:fmt("%F %T") .. ' [' .. LOG_LVL_NAMES[lvl] .. '] ' .. argv2str(...)
end

local M = {}
M.LVL = LOG_LVL

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
    fotal   = function (msg) write(LOG_LVL.FOTAL  , msg) end;
    error   = function (msg) write(LOG_LVL.ERROR  , msg) end;
    warning = function (msg) write(LOG_LVL.WARNING, msg) end;
    info    = function (msg) write(LOG_LVL.INFO   , msg) end;
    notice  = function (msg) write(LOG_LVL.NOTICE , msg) end;
    debug   = function (msg) write(LOG_LVL.DEBUG  , msg) end;
  }
end

return M
