#!/usr/bin/lua

package.path = 'argparse/src/?.lua;templates/lib/resty/?.lua;' .. package.path

argparse = require 'argparse'
helpers = require 'helpers'
templates = require 'template'

local parser = argparse("luacc", "Lua Code Combine tool")
parser:argument("main", "Main file of project")
parser:argument("modules", "Secondary files of project"):args("*")
parser:option("-o --output", "Output file"):count(1)
parser:option("-i --include", "Include directory path"):count('*')
parser:option("-p --position", "Amount of main file lines that should be left before generated code block")
local args = parser:parse()

local data_loader_temp =
[[
---------------------------------------------------------
----------------Auto generated code block----------------
---------------------------------------------------------

do
    local origin_loader = package.loaders[2]
    package.loaders[2] = function(path)
        local files =
        {
------------------------
-- Modules part begin --
------------------------
{% for _, file in ipairs(files) do %}

["{*file.filename*}"] = function()
--------------------
-- Module: '{*file.filename*}'
--------------------
{*file.filedata*}
end,
{% end %}

----------------------
-- Modules part end --
----------------------
        }
        if files[path] then
            return files[path]
        else
            return origin_loader(path)
        end
    end
end
---------------------------------------------------------
----------------Auto generated code block----------------
---------------------------------------------------------

]]

local head_of_main = ''
local tail_of_main = helpers.read_file(helpers.find_in_includes(args.include, args.main))

local length_of_head = 0
if args.left_lines then
    length_of_head = tonumber(args.position)
    if not length_of_head then
        error("invalid value of 'position': number expected")
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
            error("invalid value of 'position': number of lines less than value of paramenter")
        end
    end
    head_of_main = string.sub(tail_of_main, 1, prev)
    tail_of_main = string.sub(tail_of_main, prev + 1)
end

local files_table = { files = {} }
for _, filename in ipairs(args.modules) do
    local path = helpers.find_in_includes(args.include, filename)
    local data = helpers.read_file(path)
    table.insert(
        files_table.files,
        {
            filename = filename,
            filedata = data
        }
    )
end

local render_res = ""
templates.print = function(res)
    render_res = res
end

if templates.render(data_loader_temp, files_table) then
    print("Code generation error")
    os.exit(1)
end

local result_data = head_of_main .. render_res .. tail_of_main
helpers.write_file(args.output, result_data)
