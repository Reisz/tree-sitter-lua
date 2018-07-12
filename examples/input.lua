local input = {
  options = {
    filename = "keymap.conf",
    save_on_change = true
  },
}

local mapping_default = require "input_default"
local modes = {}; for i,v in ipairs (require "input_modes") do
    for j = 1, #v do
        modes[v[j]] = i
    end
end

local strings = {
    invalid_file = "Keymap configuration file format invalid.",
    invalid_entry = "Keymap configuration for action \"%s\" contains invalid data.\nWill be replaced by default mapping.",
    invalid_key = "The KeyConstant \"%s\" assigned to \"%s\" is invalid or unavailable in your system.",
    invalid_key_single = "Will be replaced by default mapping.",
    invalid_key_multi = "Will be ignored in favor of other mappings.",
    invalid_key_all = "No valid KeyConstant remaining for action \"%s\".\nWill be replaced by default mapping.",
}

local input = {
    mapping = {}
}

local function save_input()
    -- revert back to action indexed for saving
    local revmap = {}
    local result = {}

end

local function load_input(filename)
    input.filename = filename

    -- look for keymap configuration and load if present
    local isFile, valid, mapping = love.filesystem.isFile(filename), true
    if isFile then
        local chunk = { "return {", love.filesystem.read(filename), "}" }
        chunk = loadstring(table.concat(chunk))
        if type(chunk) == "function" then
            mapping = setfenv(chunk, {})()
        end
    end

    -- print warning if keymap cfg contents are invalid
    if isFile and type(mapping) ~= "table" then
        print(strings.invalid_file)
        valid, mapping = false, mapping_default
    end

    -- store data in a KeyConstant indexed table
    local im, v, t = input.mapping

    -- replace current mapping with default
    local function remap()
        v, valid = mapping_default[i], false; t = type(v)
    end

    -- check, if k is valid KeyConstant
    local function isKey(k, i)
        if love.keyboard.getScancodeFromKey(v[j]) == "unknown" then
            print(string.format(strings.invalid_key, k, i))
            return false
        end
        return true
    end

    for i in pairs(mapping_default) do
        v = mapping[i]; t = type(v)

        -- warn if keymap file contains wrong data type or check KeyConstants
        if t ~= "string" and t ~= "table" and t ~= "nil" then
            print(string.format(strings.invalid_entry, i))
            remap()
        elseif t == "nil" then
            v = mapping_default[i]; t = type(v)
        elseif t == "string" then
            if isKey(v, i) then
                print(strings.invalid_key_single)
                remap()
            end
        else -- t == "table"
            -- replace all invalid KeyConstants with "", count ocurrences to find empty actions
            local count = 0
            for j = 1, #v do
                if isKey(v[j], i) then
                    print(strings.invalid_key_multi)
                    v[j], count, valid = "", count + 1, false
                end
            end

            -- use default mapping when alls KeyConstants invalid
            if count == #v then
                print(string.format(strings.invalid_key_all, i))
                remap()
            end
        end

        -- actually store data
        if t == "string" then
            im[v] = i
        elseif t == "table" then
            for j = 1, #v do im[v[j]] = i end
        end
    end

    -- remove placeholder assignments for invalid mappings
    im[""] = nil

    if not valid then save_input() end
    return input
end

return function(tbl)
  return input
end