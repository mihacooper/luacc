#!/usr/bin/lua

stringex = require 'stringex'
argparse = require 'argparse.src.argparse'
filesys = require 'filesys'

--[[
print = function(...)
    for _, v in pairs(...) do
        if type(v) == type({}) then
            io.write('{ ')
            for key, val in pairs(v) do
                io.write(key, ' = ')
                print(val)
            end
            io.write(' }')
        else
            io.write(v)
        end
        io.write('\t')
    end
    io.write('\n')
end
]]

local parser = argparse("luacc", "Lua Code Combine tool")
parser:argument("main", "Main file of project")
parser:argument("modules", "Secondary files of project"):args("*")
parser:option("-o --output", "Output file"):count(1)
parser:option("-i --include", "Include directory path"):count('*')
parser:option("--left-lines", "Amount of main file lines that should be left before generated code block")
local args = parser:parse()

local data_loader_temp =
[[
---------------------------------------------------------
----------------Auto generated code block----------------
---------------------------------------------------------

(
    function()
        local origin_loader = package.loaders[2]
        package.loaders[2] = function(path)
            local files =
            {
                <|files|>    ["{{filename}}"] = "{{filedata}}",
                <|files|>
            }
            if files[path] then
                local loader, err = loadstring(files[path])
                return loader or '\n\tUnable to load compiled module: ' .. err
            else
                origin_loader(path)
            end
        end
    end
)()

---------------------------------------------------------
----------------Auto generated code block----------------
---------------------------------------------------------

]]

local head_of_main = ''
local tail_of_main = filesys.read_file(filesys.find_in_includes(args.include, args.main))

local length_of_head = 0
if args.left_lines then
    length_of_head = tonumber(args.left_lines)
    if not length_of_head then
        error("invalid value of 'left-lines': number expected")
    end
else
    if string.sub(tail_of_main, 1, 1) == '#' then
        length_of_head = 1
    end
end

if length_of_head then
    prev = 0
    for i = 1, length_of_head do
        prev, _ = string.find(tail_of_main, '\n', prev + 1)
        if not prev then
            error("invalid value of 'left-lines': number of lines less than value of paramenter")
        end
    end
    head_of_main = string.sub(tail_of_main, 1, prev)
    tail_of_main = string.sub(tail_of_main, prev + 1)
end

local files_table = { files = {} }
for _, filename in ipairs(args.modules) do
    local path = filesys.find_in_includes(args.include, filename)
    table.insert(
        files_table.files,
        {
            filename = filename,
            filedata = stringex.escape_slashes(filesys.read_file(path))
        }
    )
end

local result_data = head_of_main .. stringex.instance_pattern(data_loader_temp, files_table) .. tail_of_main
filesys.write_file(args.output, result_data)