local date = require "date"
local lfs  = require "lfs"

local DIR_SEP = package.config:sub(1,1)

local function remove_dir_end(str)
  while(str ~= '')do
    local ch = str:sub(-1)
    if ch == '\\' or ch == '/' then 
      str = str:sub(1,-2)
    else break end
  end
  return str
end

local function ensure_dir_end(str)
  return remove_dir_end(str) .. DIR_SEP 
end

local attrib = lfs.attributes

local function path_exists(P)
  return attrib(remove_dir_end(P),'mode') ~= nil and P
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

local file_logger = {}

local FILE_LOG_DATE_FMT = "%Y%m%d"

function file_logger:next_name(log_date)
  local id      = self.private_.id
  local log_dir = self.private_.log_dir
  local fname = string.format("%s.%.5d.log", log_date, id)
  while(path_exists(log_dir .. fname))do
    id = id + 1
    fname = string.format("%s.%.5d.log", log_date, id)
  end
  self.private_.id = id
  return fname
end

function file_logger:reset_log()
  local full_name = self.private_.log_dir .. self.private_.log_name
  if path_exists(full_name) then
    local mdate = path_getmtime(full_name)
    if mdate then mdate = date(mdate):tolocal()
    else mdate = date() end
    mdate = mdate:fmt(FILE_LOG_DATE_FMT)
    local fname = self:next_name(mdate)
    os.rename(full_name, self.private_.log_dir .. fname)
  end
  local logger, err       = reset_out(full_name)
  if not logger then 
    print('can not create logger:', err)
    return nil, err
  end
  self.private_.logger    = logger
  self.private_.log_rows  = 0
  return true
end

function file_logger:write(now, msg)
  local now = now:fmt(FILE_LOG_DATE_FMT)
  local log_date = self.private_.log_date

  if now ~= log_date then
    self:reset_log()
    self.private_.log_date = now
    self.private_.id       = 1
  elseif self.private_.log_rows > self.private_.max_rows then
    self:reset_log()
  end

  if self.private_.logger then
    self.private_.logger(msg)
    self.private_.log_rows = self.private_.log_rows + 1
  end
end

function file_logger:init(log_dir, log_name, max_rows)
  self.private_ = {
    log_dir  = ensure_dir_end( log_dir );
    log_name = log_name;
    max_rows = max_rows;
    log_date = date():fmt(FILE_LOG_DATE_FMT);
    log_rows = 0;
    id       = 1;
  }
  local ok, err = self:reset_log()
  if not self.private_.logger then
    return nil, 'can not create logger:' .. (err or '');
  end
  return self
end

function file_logger:new(...)
  return setmetatable({}, {__index = self}):init(...)
end

local M = {}

function M.new(log_dir, log_name, max_rows)
  assert(path_exists(log_dir))

  local logger = file_logger:new(log_dir, log_name, max_rows)

  return function(msg, lvl, now)
    logger:write(now, msg)
  end
end

return M

