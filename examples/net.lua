local host = arg[1] or '127.0.0.1'
local port = arg[2] or 514

local zmq_cnn_host = 'tcp://' .. host .. ':' .. port
local udp_cnn_host = host
local udp_cnn_port = port


local LOG = require"log".new(
  require "log.writer.list".new(
    require "log.writer.console".new()
    ,require "log.writer.net.udp".new(udp_cnn_host, udp_cnn_port)
    ,require "log.writer.net.zmq".new(zmq_cnn_host)
  )
)

require"socket".sleep(1) -- zmq need time for connect

LOG.fotal("can not allocate memory")
LOG.error("file not found")
LOG.warning("cache server is not started")
LOG.info("new message is received")
LOG.notice("message has 2 file")

print("Press enter ...")io.flush()
io.read()