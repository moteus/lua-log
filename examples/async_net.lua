local zmq = require "lzmq"
local ctx = zmq.init(1)

local host = arg[1] or '127.0.0.1'
local port = arg[2] or 514

local InitWriter = [[
  local zthreads = require 'lzmq.threads'
  local ctx = zthreads.get_parent_ctx()
  if not ctx then ctx = require "lzmq" .init(1) end

  return require 'log.writer.list'.new(
     require 'log.writer.console'.new()
    ,require 'log.writer.net.udp'.new('%{udp_cnn_host}', %{udp_cnn_port})
    ,require 'log.writer.net.zmq'.new(ctx, '%{zmq_cnn_host}', 'app from some host')
  )
]]

local writer = require "log.writer.async.zmq".new(ctx, 'inproc://async.logger', 
  InitWriter:gsub('%%{(.-)}', {
    zmq_cnn_host = 'tcp://' .. host .. ':' .. port;
    udp_cnn_host = host;
    udp_cnn_port = port;
  })
)

local LOG = require"log".new(nil, writer)

zmq.utils.sleep(1)

LOG.fotal("can not allocate memory")
LOG.error("file not found")
LOG.warning("cache server is not started")
LOG.info("new message is received")
LOG.notice("message has 2 file")

zmq.utils.sleep(2)
print("Press enter ...")io.flush()
io.read()