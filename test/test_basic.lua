local HAS_RUNNER = not not lunit
local lunit      = require "lunit"
local TEST_CASE  = assert(lunit.TEST_CASE)
local skip       = lunit.skip or function() end
local path       = require "path"
local utils      = require "utils"

local LUA, ARGS = utils.lua_args(arg)
local PATH = path.fullpath(".")

local DATE_PAT = "%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d"

local function exec_file(file)
  assert(path.isfile(file))
  return utils.exec(PATH, LUA, '%s %s', ARGS, path.quote(file))
end

local function exec_code(src)
  local tmpfile = path.tmpname()
  local f = assert(utils.write_file(tmpfile, src))
  local a, b, c = exec_file(tmpfile)
  path.remove(tmpfile)
  return a, b, c
end

local _ENV = TEST_CASE'basic' do

function test()
  local ok, status, msg = exec_code[[
    local LOG = require"log".new('trace',
      require "log.writer.stdout".new()
    )

    LOG.emerg("can not allocate memory")
    LOG.alert("can not allocate memory")
    LOG.fatal("can not allocate memory")
    LOG.error("file not found")
    LOG.warning("cache server is not started")
    LOG.notice("message has 2 file")
    LOG.info("new message is received")
    LOG.debug("message has 2 file")
    LOG.trace("message has 2 file")
  ]]
  assert_true(ok, msg)

  assert_match(DATE_PAT .. " %[EMERG%] can not allocate memory",       msg)
  assert_match(DATE_PAT .. " %[ALERT%] can not allocate memory",       msg)
  assert_match(DATE_PAT .. " %[FATAL%] can not allocate memory",       msg)
  assert_match(DATE_PAT .. " %[ERROR%] file not found",                msg)
  assert_match(DATE_PAT .. " %[WARNING%] cache server is not started", msg)
  assert_match(DATE_PAT .. " %[NOTICE%] message has 2 file",           msg)
  assert_match(DATE_PAT .. " %[INFO%] new message is received",        msg)
  assert_match(DATE_PAT .. " %[DEBUG%] message has 2 file",            msg)
  assert_match(DATE_PAT .. " %[TRACE%] message has 2 file",            msg)
end

function test_level()
  local ok, status, msg = exec_code[[
    local LOG = require"log".new('notice',
      require "log.writer.stdout".new()
    )

    LOG.emerg("can not allocate memory")
    LOG.alert("can not allocate memory")
    LOG.fatal("can not allocate memory")
    LOG.error("file not found")
    LOG.warning("cache server is not started")
    LOG.notice("message has 2 file")
    LOG.info("new message is received")
    LOG.debug("message has 2 file")
    LOG.trace("message has 2 file")
  ]]
  assert_true(ok, msg)

  assert_match(DATE_PAT .. " %[EMERG%] can not allocate memory",       msg)
  assert_match(DATE_PAT .. " %[ALERT%] can not allocate memory",       msg)
  assert_match(DATE_PAT .. " %[FATAL%] can not allocate memory",       msg)
  assert_match(DATE_PAT .. " %[ERROR%] file not found",                msg)
  assert_match(DATE_PAT .. " %[WARNING%] cache server is not started", msg)
  assert_match(DATE_PAT .. " %[NOTICE%] message has 2 file",           msg)
  assert_not_match(DATE_PAT .. " %[INFO%] new message is received",        msg)
  assert_not_match(DATE_PAT .. " %[DEBUG%] message has 2 file",            msg)
  assert_not_match(DATE_PAT .. " %[TRACE%] message has 2 file",            msg)

end

function test_formatter()
  local ok, status, msg = exec_code[[
    local writer = require "log.writer.stdout".new()
    local LOG = require"log".new(writer,
      require "log.formatter.concat".new(':')
    )
    local LOG_FMT = require"log".new(writer,
      require "log.formatter.format".new()
    )
    LOG.info('new', 'message', 'is', 'received')
    LOG_FMT.notice("message has %d %s", 2, 'file')
  ]]
  assert_true(ok, msg)

  assert_match('new:message:is:received',  msg)
  assert_match('message has 2 file',       msg)
end

function test_formatter()
  local ok, status, msg = exec_code[[
    local writer = require "log.writer.stdout".new()
    local LOG = require"log".new(writer,
      require "log.formatter.concat".new(':')
    )
    local LOG_FMT = require"log".new(writer,
      require "log.formatter.format".new()
    )
    LOG.info('new', 'message', 'is', 'received')
    LOG_FMT.notice("message has %d %s", 2, 'file')
  ]]
  assert_true(ok, msg)

  assert_match('new:message:is:received',  msg)
  assert_match('message has 2 file',       msg)
end

function test_async_zmq()
  local ok, status, msg = exec_code[[
    local writer = require "log.writer.async.zmq".new('inproc://async.logger',
      "return require 'log.writer.stdout'.new()"
    )

    local LOG = require"log".new(writer)

    LOG.fatal("can not allocate memory")

    require 'lzmq.timer'.sleep(1000)
  ]]
  assert_true(ok, msg)

  assert_match('can not allocate memory',  msg)
end

function test_async_udp()
  local ok, status, msg = exec_code[[
    local writer = require "log.writer.async.udp".new('127.0.0.1', 5555,
      "return require 'log.writer.stdout'.new()"
    )

    local LOG = require"log".new(writer)

    LOG.fatal("can not allocate memory")

    require 'lzmq.timer'.sleep(1000)
  ]]
  assert_true(ok, msg)

  assert_match('can not allocate memory',  msg)
end

function test_async_lane()
  local ok, status, msg = exec_code[[
    local writer = require "log.writer.async.lane".new('lane.logger',
      "return require 'log.writer.stdout'.new()"
    )

    local LOG = require"log".new(writer)

    LOG.fatal("can not allocate memory")

    require 'lzmq.timer'.sleep(1000)
  ]]
  assert_true(ok, msg)

  assert_match('can not allocate memory',  msg)
end

function test_async_proxy()
  local ok, status, msg = exec_code[[
    local zthreads = require "lzmq.threads"
    local ztimer   = require 'lzmq.timer'

    -- create log thread
    local LOG = require"log".new(
      require "log.writer.async.zmq".new('inproc://async.logger',
        "return require 'log.writer.stdout'.new()"
      )
    )
    ztimer.sleep(100)

    -- log from separate thread via proxy
    local Thread = function()
      local LOG = require"log".new(
        require "log.writer.async.zmq".new('inproc://async.logger')
      )

      LOG.error("(Thread) file not found")
    end

    local child_thread = zthreads.xrun(Thread):start()
    ztimer.sleep(100)

    LOG.fatal("can not allocate memory")

    child_thread:join()

    ztimer.sleep(500)
  ]]
  assert_true(ok, msg)

  assert_match('can not allocate memory',  msg)
  assert_match('%(Thread%) file not found',  msg)
end

function test_async_filter_le()
  local ok, status, msg = exec_code[[
    local writer = require 'log.writer.stdout'.new()
    local Filter = require "log.writer.filter"

    local LOG = require"log".new(
      Filter.new('warning', writer)
    )

    LOG.fatal("can not allocate memory")
    LOG.warning("cache server is not started")
    LOG.info("new message is received")

    require 'lzmq.timer'.sleep(1000)
  ]]
  assert_true(ok, msg)

  assert_match('can not allocate memory',      msg)
  assert_match('cache server is not started',  msg)
  assert_not_match('new message is received',  msg)
end

function test_async_filter_eq()
  local ok, status, msg = exec_code[[
    local writer = require 'log.writer.stdout'.new()
    local Filter = require "log.writer.filter.lvl.eq"

    local LOG = require"log".new(
      Filter.new('warning', writer)
    )

    LOG.fatal("can not allocate memory")
    LOG.warning("cache server is not started")
    LOG.info("new message is received")

    require 'lzmq.timer'.sleep(1000)
  ]]
  assert_true(ok, msg)

  assert_not_match('can not allocate memory',  msg)
  assert_match('cache server is not started',  msg)
  assert_not_match('new message is received',  msg)
end

end

print("-------------------------------")
print(select(3, utils.exec(".", LUA, "-v")))
print("-------------------------------")

if not HAS_RUNNER then lunit.run() end
