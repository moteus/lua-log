local io     = require "io"
local os     = require "os"
local string = require "string"
local date   = require "date"
local lfs    = require "lfs"

local DIR_SEP = package.config:sub(1,1)
local IS_WINDOWS = DIR_SEP == '\\'

local function remove_dir_end(str)
  return (string.gsub(str, '[\\/]+$', ''))
end

local function ensure_dir_end(str)
  return remove_dir_end(str) .. DIR_SEP 
end

local function path_normolize_sep(P)
  return (string.gsub(P, '\\', DIR_SEP):gsub('/', DIR_SEP))
end

local function path_fullpath(P)
  P = path_normolize_sep(P)
  local ch1, ch2 = P:sub(1,1), P:sub(2,2)
  if IS_WINDOWS then
    if ch1 == DIR_SEP then         -- \temp => c:\temp
      local cwd = lfs.currentdir()
      local disk = cwd:sub(1,2)
      P = disk .. P
    elseif ch1 == '~' then         -- ~\temp
      local base = os.getenv('USERPROFILE') or (os.getenv('HOMEDRIVE') .. os.getenv('HOMEPATH'))
      P = ((ch2 == DIR_SEP) and remove_dir_end(base) or ensure_dir_end(base)) .. string.sub(P,2)
    elseif ch2 ~= ':' then
      P = ensure_dir_end(lfs.currentdir()) .. P
    end
  else
    if ch1 == '~' then         -- ~/temp
      local base = os.getenv('HOME')
      P = ((ch2 == DIR_SEP) and remove_dir_end(base) or ensure_dir_end(base)) .. string.sub(P,2)
    else 
      P = ensure_dir_end(lfs.currentdir()) .. P
    end
  end

  P = string.gsub(P, DIR_SEP .. '%.' .. DIR_SEP, DIR_SEP):gsub(DIR_SEP .. DIR_SEP, DIR_SEP)
  while true do
    local first, last = string.find(P, DIR_SEP .. "[^".. DIR_SEP .. "]+" .. DIR_SEP .. '%.%.' .. DIR_SEP)
    if not first then break end
    P = string.sub(P, 1, first) .. string.sub(P, last+1)
  end

  return P
end

local function attrib(P, ...)
  if IS_WINDOWS then
    if #P < 4 and P:sub(2,2) == ':' then 
      P = ensure_dir_end(P) -- c: => c:\
    else
      P = remove_dir_end(P) -- c:\temp\ => c:\temp
    end
  end
  return lfs.attributes(P, ...)
end

local function path_exists(P)
  return attrib(P,'mode') ~= nil and P
end

local function path_isdir(P)
  return attrib(P,'mode') == 'directory' and P
end

local function path_mkdir(P)
  local P = path_fullpath(P)
  local p = ''

  for str in string.gmatch(ensure_dir_end(P), '.-' .. DIR_SEP) do 
    p = p .. str
    if path_exists(p) then
      if not path_isdir(p) then
        return nil, 'can not create ' .. p
      end
    else
      local ok, err = lfs.mkdir(remove_dir_end(p))
      if not ok then return nil, err .. ' ' .. p end
    end
  end

  return true
end

local function path_getctime(P)
  return attrib(P,'change')
end

local function path_getmtime(P)
  return attrib(P,'modification')
end

local function path_getatime(P)
  return attrib(P,'access')
end

local function path_getsize(P)
  return attrib(P, 'size')
end

local function path_remove(P)
  return os.remove(P)
end

local function path_rename(from,to)
  path_remove(to)
  return os.rename(from, to)
end

local function reset_out(FileName, isbin)
  local FILE_APPEND  = 'a+' .. (isbin and 'b' or '')
  local FILE_REWRITE = 'w+'
  local END_OF_LINE  = '\n'
  local f, err = io.open(FileName , FILE_REWRITE);
  if not f then return nil, err end
  f:close();

  return function (msg)
    local f, err = io.open(FileName , FILE_APPEND)
    if not f then return nil, err end
    f:write(msg, END_OF_LINE)
    f:close()
  end
end

local function reset_out2(FileName, isbin)
  local FILE_APPEND  = 'a+' .. (isbin and 'b' or '')
  local FILE_REWRITE = 'w+'
  local END_OF_LINE  = '\n'
  local f, err = io.open(FileName , FILE_REWRITE);
  if not f then return nil, err end

  return function (msg)
    f:write(msg, END_OF_LINE)
  end, function() f:close() end
end

local function split_ext(fname)
  local s1, s2 = string.match(fname, '([^\\/]*)([.][^.\\/]*)$')
  if s1 then return s1, s2 end
  s1 = string.match(fname, '([^\\/]+)$')
  if s1 then return s1, '' end
end

local function assert_2(f1, f2, v1, v2)
  assert(f1 == v1, string.format( "Expected '%s' got '%s'", tostring(f1), tostring(v1)))
  assert(f2 == v2, string.format( "Expected '%s' got '%s'", tostring(f2), tostring(v2)))
end

assert_2("events", ".log", split_ext("events.log"))
assert_2("events", '',     split_ext("events"))
assert_2(nil,      nil,    split_ext("events\\"))
assert_2('',       '.log', split_ext("events\\.log"))
assert_2('log',    '',     split_ext("events\\log"))

local file_logger = {}

local FILE_LOG_DATE_FMT = "%Y%m%d"
local EOL_SIZE = IS_WINDOWS and 2 or 1

local function get_file_date(fname)
  local mdate = path_getmtime(fname)
  if mdate then 
    mdate = date(mdate):tolocal()
  else 
    mdate = date() 
  end
  return mdate:fmt(FILE_LOG_DATE_FMT)
end

function file_logger:close()
  if self.private_.logger and self.private_.logger_close then
    self.private_.logger_close()
  end
  self.private_.logger = nil
  self.private_.logger_close = nil
end

function file_logger:open()
  local full_name = self.private_.log_dir .. self.private_.log_name
  local logger, err = self.private_.reset_out(full_name)
  if not logger then 
    return nil, string.format("can not create logger for file '%s':", full_name, err)
  end

  self.private_.logger       = logger
  self.private_.logger_close = err
  self.private_.log_date     = os.date(FILE_LOG_DATE_FMT)
  self.private_.log_rows     = 0
  self.private_.log_size     = 0
  return true
end

function file_logger:reset_log_by_roll()
  self:close()

  local full_name  = self.private_.log_dir .. self.private_.log_name
  local first_name = self.private_.log_dir .. string.format("%s.%.5d.log", self.private_.arc_pfx, 1)

  -- we must "free" space for current file
  if path_exists(first_name) then
    for i = self.private_.roll_count - 1, 1, -1 do
      local fname1 = self.private_.log_dir .. string.format("%s.%.5d.log", self.private_.arc_pfx, i)
      local fname2 = self.private_.log_dir .. string.format("%s.%.5d.log", self.private_.arc_pfx, i + 1)
      path_rename(fname1, fname2)
    end
  end

  if path_exists(full_name) then
    local ok, err = path_rename(full_name, first_name)
    if not ok then 
      return nil, string.format("can not rename '%s' to '%s' : %s", full_name, first_name, err or '')
    end
  end

  return self:open()
end

function file_logger:next_name(log_date)
  local id      = self.private_.id
  local log_dir = self.private_.log_dir
  local arc_pfx = self.private_.arc_pfx

  local fname = string.format("%s.%s.%.5d.log", arc_pfx, log_date, id)
  while(path_exists(log_dir .. fname))do
    id = id + 1
    fname = string.format("%s.%s.%.5d.log", arc_pfx, log_date, id)
  end
  self.private_.id = id
  return fname
end

function file_logger:reset_log_by_date(log_date)
  self:close()

  local full_name = self.private_.log_dir .. self.private_.log_name
  if path_exists(full_name) then -- previews file
    log_date = log_date or get_file_date(full_name)
    local fname = self:next_name(log_date)
    local ok, err = path_rename(full_name, self.private_.log_dir .. fname)
    if not ok then 
      return nil, string.format("can not rename '%s' to '%s' : ", fname1, fname2, err or '')
    end
  end

  return self:open()
end

function file_logger:reset_log(...)
  if self.private_.roll_count then
    return self:reset_log_by_roll(...)
  end
  return self:reset_log_by_date(...)
end

function file_logger:check()
  if self.private_.by_day then
    local now = os.date(FILE_LOG_DATE_FMT)
    if self.private_.log_date ~= now then
      local ok, err = self:reset_log_by_date(self.private_.log_date)
      self.private_.id       = 1
      return ok, err
    end
  end

  if self.private_.max_rows and (self.private_.log_rows >= self.private_.max_rows) then
    return self:reset_log(log_date)
  end

  if self.private_.max_size and (self.private_.log_size >= self.private_.max_size) then
    return self:reset_log(log_date)
  end

  return true
end

function file_logger:write(msg)
  local ok, err = self:check()
  if not ok then
    io.stderr:write("logger error: ", err, '\n')
    return
  end

  self.private_.logger(msg)
  self.private_.log_rows = self.private_.log_rows + 1
  self.private_.log_size = self.private_.log_size + #msg + EOL_SIZE
end

function file_logger:init(opt)

  if(opt.by_day or opt.roll_count)then
    assert(not(opt.by_day and opt.roll_count),
      "Can not set 'by_day' and 'roll_count' fields at the same time!"
    )
  end
  assert(opt.log_name, 'field log_name is required')

  local log_dir = path_fullpath(opt.log_dir or '.')

  if path_exists(log_dir) then assert(path_isdir(log_dir))
  else assert(path_mkdir(log_dir)) end

  local log_name, log_ext = string.match(opt.log_name, '([^\\/]+)([.][^.\\/]+)$')
  assert(log_name and log_ext)

  log_dir = ensure_dir_end( log_dir )
  local full_name = log_dir .. log_name .. log_ext
  if(0 == path_getsize(full_name))then 
    -- prevent rename zero size logfile
    path_remove(full_name)
  end

  self.private_ = {
    -- options
    log_dir    = log_dir;
    log_name   = log_name .. log_ext;
    max_rows   = opt.max_rows or 2 * 1024 * 1024 * 1024;
    max_size   = opt.max_size or 2 * 1024 * 1024 * 1024;
    reset_out  = opt.close_file and reset_out or reset_out2;
    arc_pfx    = opt.archive_prefix or log_name;
    roll_count = opt.roll_count and assert(tonumber(opt.roll_count), 'roll_count must be a number');
    by_day     = not not opt.by_day;

    -- state
    -- log_date = ;  -- date when current log file was create
    -- log_rows = 0; -- how many lines in current log file
    -- log_size = 0;
    id       = 1;  -- number file in current log_date
  }
  if self.private_.roll_count then
    assert(self.private_.roll_count > 0)
  end

  assert(self:reset_log())

  return self
end

function file_logger:new(...)
  return setmetatable({}, {__index = self}):init(...)
end

local function do_profile()
  require "profiler".start()

  local logger = file_logger:new{
    log_dir    = './logs';
    log_name   = "events.log";
    -- max_rows   = 10;
    max_size   = 70;
    -- roll_count = 11;
    by_day     = true;
    close_file = true;
  }

  for i = 1, 10000 do 
    local msg = string.format("%5d", i)
    logger:write(msg)
  end

  logger:close()
end

return file_logger