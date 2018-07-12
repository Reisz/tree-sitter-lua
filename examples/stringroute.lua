local _ops, _args = {
  l = "t", r = "t",
  f = "m", b = "m", u = "m", d = "m"
}, {
  l = false, r = true, 
  f = 3, b = 2, u = 1, d = 0
}

local function stringroute(text)
  local route = {}
  
  for op, cnt in string.gmatch(text, "([lrtfbud])([1-9]?%d*)") do
    if op == "t" then
      table.insert(route, { "t", true, 2 })
    else
      table.insert(route, {_ops[op], _args[op], cnt and tonumber(cnt)})
    end
  end
  
  return route
end

local function complexity(route)
  local c = 0
  for _,v in ipairs(route) do c = c + (v[3] or 1) end
  return c
end

local _revtbl = {
  [0] = 1, 0, 3, 2,
  [true] = false, [false] = true
}
local function reverse(route)
  local result = {}
  for i = #route, 1, -1 do
    local v = route[i]
    table.insert(result, { v[1], _revtbl[v[2]], v[3] })
  end
  return result
end

local _location_mt = {
  __index = function(self, key)
    local min, nhop = math.huge
    self[key] = { nhop, min }
    
    for i,v in pairs(self) do
      if i ~= "_" and type(v[1]) == "table" then
        local cost = self._[i][key][2]
        if cost < min then nhop = i; min = cost end
      end
    end
    
    local result = { nhop, min + self[nhop][2] }
    self[key] = result
    return result
  end
}
local _network_mt = {
  __index = function(self, key)
    local tbl = setmetatable({ _ = self }, _location_mt); self[key] = tbl
    return tbl
  end
}
local function fillNetwork(routes)
  local network = setmetatable({}, _network_mt)
  
  for _,v in ipairs(routes) do
    local route = v[3]
    if type(route) == "string" then route = stringroute(route) end
    local comp = complexity(route)
    network[v[1]][v[2]] = { route, comp }
    network[v[2]][v[1]] = { reverse(route), comp }
  end
  
  return network
end