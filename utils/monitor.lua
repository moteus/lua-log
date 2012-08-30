local function write(who, msg) print(who .. ' : ' ..  msg) end
-----------------------------------------------------------------------

local socket = require"socket"
local ok, zmq, zpoller = pcall(require, "lzmq")
if ok then zpoller  = require"lzmq.poller"
else
  zmq      = require"zmq"
  zpoller  = require"zmq.poller"
end
local zassert = zmq.assert or assert

local host = arg[1] or '127.0.0.1'
local port = arg[2] or 514

local zmq_bind_host = 'tcp://' .. host .. ':' .. port
local udp_bind_host = host
local udp_bind_port = port

local uskt = assert(socket.udp())
if uskt.getfd then assert(uskt:setsockname(udp_bind_host, udp_bind_port))
else 
  print("UDP do not support!")
  uskt:close()
end

local ctx = zmq.init(1)
local zskt = ctx:socket(zmq.SUB)
zassert((zskt.set_subscribe or zskt.subscribe)(zskt, ''))
zassert(zskt:bind(zmq_bind_host))
local zrecv_all
if zskt.recv_all then
  zrecv_all = zskt.recv_all 
else
  zrecv_all = function(skt)
    local t = {}
    local r, err = skt:recv()
    if not r then return nil, err end
    table.insert(t,r)
    while skt:rcvmore() == 1 do
      r, err = skt:recv()
      if not r then return nil, err, t end
      table.insert(t,r)
    end 
    return t
  end
end

local loop = zpoller.new(2)

loop:add(zskt, zmq.POLLIN, function()
  local msg = zrecv_all(zskt)
  if msg[2] then write(tostring(msg[1]), tostring(msg[2]))
  else write('zmq://unknown', tostring(msg[1])) end
end)

if uskt then
  loop:add(uskt:getfd(), zmq.POLLIN, function()
    local msg, ip, port = uskt:receivefrom()
    local name = 'udp://' .. ip .. ":" .. port
    write(name, msg)
  end)
end

loop:start()
