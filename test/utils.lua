
local function prequire(...)
   local ok, mod = pcall(require, ...)
   if not ok then return nil, mod end
   return mod, ...
end

local function vrequire(...)
   local errors = {}
   for i, n in ipairs{...} do
      local mod, err = prequire(n)
      if mod then return mod, err end
      errors[#errors + 1] = err
   end
   error(table.concat(errors, "\n\n"))
end

local path = require "path"

local function read_file(n)
  local f, e = io.open(n, "r")
  if not f then return nil, e end
  local d, e = f:read("*all")
  f:close()
  return d, e
end

local function write_file(n, src)
  local f, e = io.open(n, "w+")
  if not f then return nil, e end
  local d, e = f:write(src)
  f:close()
  return d, e
end

local path = require "path"

-----------------------------------------------------------
local exec do

local lua_version_t
local function lua_version()
  if not lua_version_t then 
    local version = rawget(_G,"_VERSION")
    local maj,min = version:match("^Lua (%d+)%.(%d+)$")
    if maj then                         lua_version_t = {tonumber(maj),tonumber(min)}
    elseif not math.mod then            lua_version_t = {5,2}
    elseif table.pack and not pack then lua_version_t = {5,2}
    else                                lua_version_t = {5,2} end
  end
  return lua_version_t[1], lua_version_t[2]
end

local LUA_MAJOR, LUA_MINOR = lua_version()
local LUA_VERSION = LUA_MAJOR * 100 + LUA_MINOR
local LUA_52 = 502

local function read_file(n)
  local f, e = io.open(n, "r")
  if not f then return nil, e end
  local d, e = f:read("*all")
  f:close()
  return d, e
end

exec = function(cwd, cmd, ...)
  local tmpfile = path.tmpname()

  cmd = path.quote(cmd)
  if ... then cmd = path.quote(cmd .. ' ' .. string.format(...) .. ' ') end
  cmd = cmd .. ' >' .. path.quote(tmpfile) .. ' 2>&1'

  local p
  if cwd and (cwd ~= "") and (cwd ~= ".") then
    p = path.currentdir()
    path.chdir(cwd)
  end

  local res1,res2,res2 = os.execute(cmd)
  if p then path.chdir(p) end

  local data = read_file(tmpfile)
  path.remove(tmpfile)

  if LUA_VERSION < LUA_52 then
    return res1==0, res1, data
  end

  return res1, res2, data
end

end
-----------------------------------------------------------

local function lua_args(arg)
  local args = {}

  for i = -1000, -1 do
    if arg[i] then args[#args + 1] = arg[i] end
  end

  local lua = table.remove(args, 1)
  args = table.concat(args, ' ')
  return lua, args
end

return {
  exec       = exec;
  read_file  = read_file;
  write_file = write_file;
  lua_args   = lua_args;
}
