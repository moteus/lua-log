local socket = require("socket")
local cmsgpack = require "cmsgpack.safe"

local function create_socket(host, port)
  local skt = assert(socket.udp())
  assert(skt:settimeout(0.1))
  assert(skt:setpeername(host, port))
  return skt
end

local M = {}

function M.new(host, port) 
  local skt = create_socket(host, port)
  return function(msg, lvl, now)
    local m = cmsgpack.pack(msg, lvl, now:fmt("%F %T"))
    skt:send(m)
  end
end

return M