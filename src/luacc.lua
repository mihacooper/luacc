#!/usr/bin/env lua

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
    local searchers = package.searchers or package.loaders
    local origin_seacher = searchers[2]
    searchers[2] = function(path)
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
            return origin_seacher(path)
        end
    end
end
---------------------------------------------------------
----------------Auto generated code block----------------
---------------------------------------------------------
]]

local main_file_body = {}
for line in io.lines(helpers.find_in_includes(args.include, args.main)) do
    table.insert(main_file_body, line)
end

local length_of_head = 0
if not args.position then
    if string.sub(main_file_body[1], 1, 2) == '#!' then
        length_of_head = 1
    end
elseif tonumber(args.position) then
    length_of_head = tonumber(args.position)
    if length_of_head > #main_file_body then
        error("invalid value of 'position': number of lines less than value of paramenter")
    end
else
    local pattern = '--' .. args.position
    for n, line in ipairs(main_file_body) do
        if line == pattern then
            length_of_head = n
        end
    end
    if length_of_head == 0 then
            error("invalid value of 'position': unable to find pattern " .. "'" .. pattern .. "'")
    end
    table.remove(main_file_body, length_of_head)
    length_of_head = length_of_head - 1
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
templates.render(data_loader_temp, files_table)

local result_data = table.concat(main_file_body, "\n", 1, length_of_head) .. "\n"
        .. render_res .. table.concat(main_file_body, "\n", length_of_head + 1)
helpers.write_file(args.output, result_data)
