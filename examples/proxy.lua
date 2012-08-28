local LOG = require"log".new(
  require "log.writer.list".new(
    require "log.writer.async.zmq".new('tcp://127.0.0.1:514'),
    require "log.writer.async.udp".new('127.0.0.1', 514)
  )
)
local zmq = require "lzmq"
zmq.utils.sleep(1) -- zmq connect

LOG.fotal("can not allocate memory")
LOG.error("file not found")
LOG.warning("cache server is not started")
LOG.info("new message is received")
LOG.notice("message has 2 file")

