local M = {}

function M.new() 
  return function (msg) io.stdout:write(msg,'\n') end
end

return M