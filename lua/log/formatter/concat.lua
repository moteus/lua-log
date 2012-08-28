local Log = require "log"

local M = {}

function M.new(sep)
  sep = sep or ' '
  local LOG_LVL_NAMES = Log.LVL_NAMES

  return function (now, lvl, ...)
    local argc,argv = select('#', ...), {...}
    for i = 1, argc do argv[i] = tostring(argv[i]) end
    return now:fmt("%F %T") .. ' [' .. LOG_LVL_NAMES[lvl] .. '] ' .. table.concat(argv, sep)
  end
end

return M

