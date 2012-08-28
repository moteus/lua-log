local Log = require "log"

local M = {}

function M.new()
  sep = sep or ' '
  local LOG_LVL_NAMES = Log.LVL_NAMES
  local fmt = string.format

  return function (now, lvl, ...)
    return now:fmt("%F %T") .. ' [' .. LOG_LVL_NAMES[lvl] .. '] ' .. (fmt(...))
  end
end

return M
