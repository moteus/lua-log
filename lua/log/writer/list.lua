local M = {}

function M.new(...)
  local writers = {...}
  return function(...)
    for i, writer in ipairs(writers) do
      writer(...)
    end
  end
end

return M

