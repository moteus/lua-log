package.path = './spec/?.lua;../lua/?.lua;'..package.path

local path       = require "path"
local utils      = require "utils"

local LUA, ARGS = utils.lua_args(arg)
local PATH = path.fullpath(".")

local DATE_PAT = "%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d"
local TESTDIR  = ".test_log"

local function exec_file(file)
  assert(path.isfile(file))
  return utils.exec(PATH, LUA, '%s', path.quote(file))
end

local function exec_code(src)
  local tmpfile = assert(path.tmpname())
  local f = assert(utils.write_file(tmpfile, src))
  local a, b, c = exec_file(tmpfile)
  path.remove(tmpfile)
  return a, b, c
end

do local s = require("say")

local function is_match(state, arguments)
  local pat, str = arguments[1], arguments[2]

  if type(pat) ~= "string" and type(str) ~= "string" then
    return false
  end

  return (not not string.match(str, pat))
end

s:set("assertion.match.positive", "String `%s` expected match to \n`%s`")
s:set("assertion.match.negative", "String\n`%s` not expected match to \n`%s`")
assert:register("assertion", "match", is_match, "assertion.match.positive", "assertion.match.negative")

end

describe("writers", function()

  it('basic format', function()
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
    assert.True(ok, msg)

    assert.match(DATE_PAT .. " %[EMERG%] can not allocate memory",       msg)
    assert.match(DATE_PAT .. " %[ALERT%] can not allocate memory",       msg)
    assert.match(DATE_PAT .. " %[FATAL%] can not allocate memory",       msg)
    assert.match(DATE_PAT .. " %[ERROR%] file not found",                msg)
    assert.match(DATE_PAT .. " %[WARNING%] cache server is not started", msg)
    assert.match(DATE_PAT .. " %[NOTICE%] message has 2 file",           msg)
    assert.match(DATE_PAT .. " %[INFO%] new message is received",        msg)
    assert.match(DATE_PAT .. " %[DEBUG%] message has 2 file",            msg)
    assert.match(DATE_PAT .. " %[TRACE%] message has 2 file",            msg)
  end)

  it('level', function()
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
    assert.True(ok, msg)

    assert.match    (DATE_PAT .. " %[EMERG%] can not allocate memory",       msg)
    assert.match    (DATE_PAT .. " %[ALERT%] can not allocate memory",       msg)
    assert.match    (DATE_PAT .. " %[FATAL%] can not allocate memory",       msg)
    assert.match    (DATE_PAT .. " %[ERROR%] file not found",                msg)
    assert.match    (DATE_PAT .. " %[WARNING%] cache server is not started", msg)
    assert.match    (DATE_PAT .. " %[NOTICE%] message has 2 file",           msg)
    assert.not_match(DATE_PAT .. " %[INFO%] new message is received",        msg)
    assert.not_match(DATE_PAT .. " %[DEBUG%] message has 2 file",            msg)
    assert.not_match(DATE_PAT .. " %[TRACE%] message has 2 file",            msg)
  end)

  it('formatter', function()
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
    assert.True(ok, msg)

    assert.match('new:message:is:received',  msg)
    assert.match('message has 2 file',       msg)
  end)

  it('async_zmq', function()
    local ok, status, msg = exec_code[[
      local ztimer = require "lzmq.timer"

      local writer = require "log.writer.async.zmq".new('inproc://async.logger',
        "return require 'log.writer.stdout'.new()"
      )
      ztimer.sleep(500)

      local LOG = require"log".new(writer)
      ztimer.sleep(500)

      LOG.fatal("can not allocate memory")

      ztimer.sleep(5000)

      require "lzmq.threads".context():destroy()
      ztimer.sleep(5000)
    ]]
    assert.True(ok, msg)

    assert.match('can not allocate memory',  msg)
  end)

  it('async_udp', function()
    local ok, status, msg = exec_code[[
      local writer = require "log.writer.async.udp".new('127.0.0.1', 5555,
        "return require 'log.writer.stdout'.new()"
      )

      local LOG = require"log".new(writer)

      LOG.fatal("can not allocate memory")

      require 'lzmq.timer'.sleep(1000)
    ]]
    assert.True(ok, msg)

    assert.match('can not allocate memory',  msg)
  end)

  if _G.jit then pending"FIXME: makes LuaLane work with LuaJIT"
  else it('async_lane', function()
    local ok, status, msg = exec_code[[
      local writer = require "log.writer.async.lane".new('lane.logger',
        "return require 'log.writer.stdout'.new()"
      )

      local LOG = require"log".new(writer)

      LOG.fatal("can not allocate memory")

      require 'lzmq.timer'.sleep(1000)
    ]]
    assert.True(ok, msg)

    assert.match('can not allocate memory',  msg)
  end) end

  it('async_proxy', function()
    local ok, status, msg = exec_code[[
      local zthreads = require "lzmq.threads"
      local ztimer   = require 'lzmq.timer'

      -- create log thread
      local LOG = require"log".new(
        require "log.writer.async.zmq".new('inproc://async.logger',
          "return require 'log.writer.stdout'.new()"
        )
      )
      ztimer.sleep(500)

      -- log from separate thread via proxy
      local Thread = function()
        local LOG = require"log".new(
          require "log.writer.async.zmq".new('inproc://async.logger')
        )

        LOG.error("(Thread) file not found")
      end

      local child_thread = zthreads.xrun(Thread):start()
      ztimer.sleep(500)

      LOG.fatal("can not allocate memory")

      child_thread:join()

      ztimer.sleep(5000)

      zthreads.context():destroy()

      ztimer.sleep(1500)
    ]]
    assert.True(ok, msg)

    assert.match('can not allocate memory',  msg)
    assert.match('%(Thread%) file not found',  msg)
  end)

  it('async_filter_le', function()
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
    assert.True(ok, msg)

    assert.match('can not allocate memory',      msg)
    assert.match('cache server is not started',  msg)
    assert.not_match('new message is received',  msg)
  end)

  it('async_filter_eq', function()
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
    assert.True(ok, msg)

    assert.not_match('can not allocate memory',  msg)
    assert.match('cache server is not started',  msg)
    assert.not_match('new message is received',  msg)
  end)

  it('formatter_mix', function()
    local ok, status, msg = exec_code[[
      local LOG = require"log".new('trace',
        require "log.writer.stdout".new(),
        require "log.formatter.mix".new()
      )

      LOG.emerg("can not allocate memory")
      LOG.alert(function(str) return str end, "can not allocate memory")
      LOG.fatal("can not allocate %s", "memory")
    ]]
    assert.True(ok, msg)

    assert.match(DATE_PAT .. " %[EMERG%] can not allocate memory",       msg)
    assert.match(DATE_PAT .. " %[ALERT%] can not allocate memory",       msg)
    assert.match(DATE_PAT .. " %[FATAL%] can not allocate memory",       msg)
  end)

end)