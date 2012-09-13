local M = {}

function M.new() 
  return function (msg) io.stderr:write(msg,'\n') end
end

return M