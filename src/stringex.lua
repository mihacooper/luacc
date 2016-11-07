local stringex = {}

local function str_replace(str, args)
    local result = str
    for name, value in pairs(args) do
        local pattern = '{{' .. name .. '}}'
        result = string.gsub(result, pattern, value)
    end
    return result
end

function stringex.instance_pattern(str, args)
    local result = str
    for repKey, cases in pairs(args) do
        if type(cases) == type({}) then
            local pattern = string.format("<|%s|>(.-)<|%s|>", repKey, repKey)
            for instance in string.gmatch(result, pattern) do
                for _, case in pairs(cases) do
                    local substr = stringex.instance_pattern(instance, case)
                    result = string.gsub(result, pattern, string.format("%s<|%s|>%s<|%s|>", substr, repKey, '%1', repKey), 1)
                end
                result = string.gsub(result, pattern, '', 1)
            end
        else
            result = str_replace(result, { [repKey] = cases})
        end
    end
    return result
end

function stringex.escape_slashes(str)
    local res = str
    res = string.gsub(res, '\\', '\\\\')
    res = string.gsub(res, '"', '\\"')
    return string.gsub(res, '\n', '\\n')
end

return stringex