local ztimer = require "lzmq.timer"

local writer = require "log.writer.async.zmq".new('inproc://async.logger',
  string.dump(function()
    local Log = require "log"
    Log.add_cleanup(function()
      require "lzmq.timer".sleep(5000)
      print "Done!"
      os.exit(0)
    end)
    return require"log.writer.stdout".new()
  end)
)

local LOG = require"log".new(writer)

LOG.fatal("can not allocate memory")

do return -1 end