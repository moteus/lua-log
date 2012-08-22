local socket = require("socket")

local function create_socket(host, port)
  local skt = assert(socket.udp())
  assert(skt:settimeout(0.1))
  assert(skt:setpeername(host, port))
  return skt
end

local M = {}

function M.new(host, port) 
  local skt = create_socket(host, port)
  return function(msg) skt:send(msg) end
end

return M