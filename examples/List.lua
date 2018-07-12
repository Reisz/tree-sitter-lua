local class = require "middleclass"
local array = require "array"

local Component = require "Component"

local List = class("List")

function List:initialize(...)
  self.array = {}
  if type(init) == "table" then
    array.join(self.array, ...)
  else
    self.array[1] = init
  end
end

function List:get()
  return self
end

function List:set(value)
  if type(value) ~= "table" then return false end
  self.array = array.join({}, value)
  self:changed()
  return true
end

function List:at(i) return rawget(self.array, i) end
List.__index = List.at
function List:size() return rawlen(self.array) end
List.__len = List.size
function List:__ipairs() return ipairs(self) end
List.__pairs = List.__ipairs

function List:__newindex(i, v)
  assert(i <= #self.array + 1)
  if self.array[i] ~= v then
    self.array[i] = v
    self:changed()
  end
end

function List:append(...)
  array.append(self.array, ...)
  self:changed()
  return self
end

function List:join(...)
  array.join(self.array, ...)
  self:changed()
  return self
end

function List:__shl(v)
  table.insert(self.array, v)
  self:changed()
  return self
end

function List:__add(other)
  return List(self.array, other)()
end

return Component.declareType(List)