local helpers = {}

function helpers.read_file(filename)
    local file, err = io.open(filename, "r")
    if file then
        local data = file:read("*a")
        file:close()
        return data
    else
        error(err)
    end
end

function helpers.write_file(filename, data)
    local file, err = io.open(filename, "w")
    if file then
        file:write(data)
    else
        error(err)
    end
end

function helpers.find_in_includes(includes, modulename)
    local function check_path(p)
        local f = io.open(p)
        if f then
            f:close()
            return true
        end
        return false
    end
    local path = string.gsub(modulename, "%.", '/')
    table.insert(includes, 1, '.')
    for _, include in pairs(includes) do
        local abs_path = include .. '/' .. path .. '.lua'
        if check_path(abs_path) then
            return abs_path
        end
    end
    error("Unable to find file: " .. '"' .. modulename .. '"')
end

return helpers