local socket     = require "socket"
local log_packer = require "log.logformat.proxy.pack"

local _M = {}

function _M.run(writer, logformat, host, port)
  local uskt = assert(socket.udp())
  assert(uskt:setsockname(host, port))
  local unpack = log_packer.unpack

  while true do
    local msg, err = uskt:receivefrom()
    if msg then 
      local msg, lvl, now = unpack(msg)
      if msg and lvl and now then writer(logformat, msg, lvl, now) end
    else
      if err ~= 'timeout' then
        io.stderror:write('log.writer.net.udp.server: ', err)
      end
    end
  end
end

return _M