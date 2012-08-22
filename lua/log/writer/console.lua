local function console_writer(msg)
  io.write(msg,'\n')
end

local M = {}

function M.new() return console_writer end

return M