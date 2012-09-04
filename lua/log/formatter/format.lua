local Log = require "log"

local M = {}

local sformat = string.format
local function date_fmt(now)
  local Y, M, D = now:getdate()
  return sformat("%.4d-%.2d-%.2d %.2d:%.2d:%.2d", Y, M, D, now:gettime())
end

function M.new()
  sep = sep or ' '
  local LOG_LVL_NAMES = Log.LVL_NAMES
  local fmt = string.format

  return function (now, lvl, ...)
    return date_fmt(now) .. ' [' .. LOG_LVL_NAMES[lvl] .. '] ' .. (fmt(...))
  end
end

return M
