local class = require "middleclass"

local array = require "array"
local prototype = require "Component.prototype"


local  _clear_value, _property_marker, _signal_marker = {}, {}, {}
local function _apply_clear_value(v)
  if v == _clear_value then return nil else return v end
end
local function _is_property(v)
  return type(v) == "table" and v[_property_marker]
end
local function _is_signal(v)
  return type(v) == "table" and v[_signal_marker]
end
local function _default_matcher() return true end
local function _new_property(value, data)
  return {
    value, read_only = data and data.read_only,
    matcher = data and data.matcher or _default_matcher
  }
end
local _signal_mt = { __mode = "k" }
local function _new_signal() return setmetatable({}, _signal_mt) end
local function _add_property(self, name, property, value)
  local p = _new_property(property[1], property)

  -- add to component
  self.properties[name] = p
  self.signals[name .. "Changed"] = _new_signal()

  -- get instance if prototype was assigned
  if type(p[1]) == "table" then p[1] = p[1]() end

  -- set to assigned value
  if type(value) ~= "nil" then
    self:set(name, _apply_clear_value(value))
  end
end
local function _notify_change(self, name, value)
  self:notify(name .. "Changed", value, name)
end
local function _signal_assignment_name(name)
  return "on" .. string.upper(string.sub(name, 1, 1)) .. string.sub(name, 2)
end


local Component = class("Component")

-- provide the ability to have static properties and signals
Component.static.static_properties = {}
Component.static.static_signals    = { "completed" }
function Component.static:subclassed(other)
  other.static.static_properties =
    setmetatable({}, { __index = self.static.static_properties })
  other.static.static_signals    =
    setmetatable({}, { __index = self.static.static_signals })
end

function Component.static:staticProperty(name, value, data)
  assert(type(name) == "string")
  assert(type(self.static.static_properties[name]) == "nil")
  self.static.static_properties[name] = _new_property(value, data)
end

function Component.static:staticSignal(name)
  assert(type(name) == "string")
  table.insert(self.static.static_signals, name)
end

-- provide the ability to add properties and signals and set nil on creation
Component.static.clearValue = _clear_value
function Component.static.property(value, data)
  local p = _new_property(value, data)
  p[_property_marker] = true
  return p
end
function Component.static.signal(name)
  return { name = name, [_signal_marker] = true }
end

prototype.prepare(Component)
function Component.static:prototyped(tbl)
  -- TODO check contents
end

function Component.static.beforeInstance(proto, tbl)
  if tbl then
    local oldTbl = proto.args[2]
    -- TODO join oldTbl into tbl
    return prototype.copy(proto, { p.args[1], tbl})
  end
end

function Component.static.isValidDefault() return false end
function Component.addDefault(--[[self, value]]) end

function Component:initialize(tbl)
  rawset(self, "properties", {})
  rawset(self, "signals", {})

  -- initialize and assign static properties and signals
  local klass = self.class
  repeat
    for i, v in pairs(klass.static_properties) do
      _add_property(self, i, v, tbl[i]); tbl[i] = nil
    end
    for _, v in ipairs(klass.static_signals) do
      self.signals[v] = _new_signal()
    end
    klass = klass.super
  until not klass

  -- setup dynamic properties and signals and default values
  for i,v in pairs(tbl) do
    if _is_property(v) then
      _add_property(self, i, v)
    elseif _is_signal(v) then
      self.signals[v.name] = _new_signal()
    elseif type(i) == "number" then
      self:addDefault(v)
    end
  end

  -- initialize signal assignments
  for i, v in pairs(self.signals) do
    local name = _signal_assignment_name(i)
    local callback = tbl[name]
    if callback then table.insert(v, callback) end
  end

  -- tbl should be empty now if check was correct
  self:notify("completed")
end

-- (signal : string, callback : function)
-- (signal : string, receiver : object, callback : string)
function Component:connect(signal, receiver, callback)
  local s = self.signals[signal]; assert(s)

  if not callback then
    table.insert(s, receiver)
  else
    s[receiver] = callback
  end
end

-- (signal : string, callback : function)
-- (signal : string, receiver : object)
function Component:disconnect(signal, receiver)
  local s = self.signals[signal]; assert(s)

  if type(receiver) ~= "table" then
    array.filter(s, function(v) if v ~= receiver then return v end end)
  else
    s[receiver] = nil
  end
end

function Component:notify(signal, ...)
  for i,v in pairs(self.signals[signal]) do
    if type(i) == "table" then i[v](i, ...) else v(...) end
  end
end


function Component:get(name)
  local p = self.properties[name]
  local v = p and p[1]
  return type(v) == "table" and v:get() or v
end
Component.__index = Component.get

function Component:set(name, value)
  local p = self.properties[name]
  assert(p and not p.read_only)

  -- if value type is complex, try assigning directly
  local v = p[1]
  if type(v) == "table" then
    if v:set(value) then return end
  end

  -- if value type is basic or would change: check matcher
  assert(p.matcher(value))

  p[1] = value
  _notify_change(self, name, value)
end

function Component:__newindex(name, value)
  local a, b = string.match(name, "^on(%u)(.*)$")
  if a then
    self:connect(string.lower(a) .. b, value)
  else
    self:set(name, value)
  end
end

local type_mixin = {
  changed = function(self)
    _notify_change(self._parent, self._name, self:get())
  end,
  instanced = function(self, parent, name)
    assert(type(self._parent) == "nil" and type(self._name) == "nil")
    self._parent, self._name = parent, name
  end
}
function Component.static.declareType(t)
  prototype.prepare(t)
  t:include(type_mixin)

  assert(type(t.get) == "function")
  assert(type(t.set) == "function")

  return t
end

return Component
