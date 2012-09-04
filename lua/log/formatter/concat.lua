local Log = require "log"

local M = {}

local sformat = string.format
local function date_fmt(now)
  local Y, M, D = now:getdate()
  return sformat("%.4d-%.2d-%.2d %.2d:%.2d:%.2d", Y, M, D, now:gettime())
end

function M.new(sep)
  sep = sep or ' '
  local LOG_LVL_NAMES = Log.LVL_NAMES

  return function (now, lvl, ...)
    local argc,argv = select('#', ...), {...}
    for i = 1, argc do argv[i] = tostring(argv[i]) end
    return date_fmt(now) .. ' [' .. LOG_LVL_NAMES[lvl] .. '] ' .. table.concat(argv, sep)
  end
end

return M

