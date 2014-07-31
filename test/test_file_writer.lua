local HAS_RUNNER = not not lunit
local lunit      = require "lunit"
local TEST_CASE  = assert(lunit.TEST_CASE)
local skip       = lunit.skip or function() end
local path       = require "path"
local utils      = require "utils"

local TESTDIR   = ".test_log"

local mkfile, read_file, remove_dir, count_logs = 
  utils.mkfile, utils.read_file, utils.remove_dir, utils.count_logs

local _ENV = TEST_CASE "test_log.writer.file" do

local file_logger = require "log.writer.file.private.impl"
local logger

local function write_logs(N)
  for i = 1, N do
    logger:write(
      string.format("%5d", i)
    )
  end
end

function setup()
  remove_dir(TESTDIR)
  path.mkdir(TESTDIR)
  assert(path.isdir(TESTDIR))
end

function teardown()
  if logger then logger:close() end
  remove_dir(TESTDIR)
end

function test_create_dir()
  local p = path.join(TESTDIR, "some", "inner", "path")
  logger = file_logger:new{ log_dir = p; log_name = "events.log"; }
  assert(path.isdir(p))
end

function test_rows()
  logger = file_logger:new{
    log_dir = TESTDIR; log_name = "events.log"; max_rows = 10;
  }

  write_logs(100)

  assert_equal(10, count_logs(TESTDIR))
end

function test_reuse_rows()
  logger = file_logger:new{
    log_dir = TESTDIR; log_name = "events.log"; max_rows = 100;
  }

  write_logs(50)

  assert_equal(1, count_logs(TESTDIR))

  logger:close()
  
  logger = file_logger:new{
    log_dir = TESTDIR; log_name = "events.log"; max_rows = 100;
    reuse = true;
  }

  write_logs(50)

  assert_equal(1, count_logs(TESTDIR))
end

function test_reset_rows()
  logger = file_logger:new{
    log_dir = TESTDIR; log_name = "events.log"; max_rows = 100;
  }

  write_logs(50)

  assert_equal(1, count_logs(TESTDIR))

  logger:close()
  
  logger = file_logger:new{
    log_dir = TESTDIR; log_name = "events.log"; max_rows = 100;
  }

  write_logs(1)

  assert_equal(2, count_logs(TESTDIR))
end

function test_roll_count()
  logger = file_logger:new{
    log_dir = TESTDIR; log_name = "events.log";
    max_rows = 10; roll_count = 5;
  }

  write_logs(100)

  -- active log + archive logs
  assert_equal(6, count_logs(TESTDIR))
end

end

if not HAS_RUNNER then lunit.run() end
