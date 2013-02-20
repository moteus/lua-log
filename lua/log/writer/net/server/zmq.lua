local Private = require "log.writer.net.zmq._private"

local zmq, ETERM, zstrerror, zassert, zrecv = 
  Private.zmq, Private.ETERM, Private.zstrerror, Private.zassert, Private.zrecv  

local log_packer = require "log.logformat.proxy.pack"

local _M = {}

function _M.run(writer, logformat, ctx, stype, address, addr_sync)
  -- print(writer, logformat, ctx, stype, address, addr_sync)
  local stypes = {
    SUB  = zmq.SUB;
    PULL = zmq.PULL;
  }
  stype = assert(stypes[stype], 'Unsupported socket type')

  ctx = Private.context(ctx)

  local skt = zassert(ctx:socket(stype))
  zassert(skt:bind(address))

  if addr_sync then
    local skt_sync = zassert(ctx:socket(zmq.PAIR))
    zassert(skt_sync:connect(addr_sync))
    skt_sync:send("")
    skt_sync:close()
  end

  local unpack = log_packer.unpack

  while(true)do
    local msg, err = zrecv(skt)
    if msg then 
      local msg, lvl, now = unpack(msg)
      if msg and lvl and now then writer(logformat, msg, lvl, now) end
    else
      if err == ETERM then break end
      io.stderr:write('log.writer.net.zmq.server: ', err, zstrerror(err))
    end
  end

  skt:close()
end

return _M