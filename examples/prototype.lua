local prototype = {}

local prototype_mt = {
  __call = function(self, ...)
    local result
    
    local bi = self.proto.beforeInstance
    if bi then result = bi(self, ...) end
    
    if type(result) == "nil" then
      result = self.proto._new(table.unpack(self.args))
      local ri = result.instanced; if ri then ri(result, ...) end
    end
    
    return result
  end,
  __tostring = function(self)
    return "prototype of " .. tostring(self.proto)
  end
}

local function prototype_new(class, ...)
  if class.prototyped then class:prototyped(...) end
  return setmetatable({ proto = class, args = {class, ...} }, prototype_mt)
end

function prototype.prepare(class)
  assert(type(class.static._new) == "nil")
  class.static._new = class.static.new
  class.static.new  = prototype_new
end

function prototype.copy(other, args)
  if not args then
    args = {}; for i, v in ipairs(other.args) do args[i] = v end
  end
  return setmetatable({ proto = other.proto, args = args }, prototype_mt)
end

function prototype.isPrototype(v)
  return getmetatable(v) == prototype_mt
end

return prototype
